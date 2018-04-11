#!/bin/bash
# https://github.com/subhh/HOS-MetadataTransformations

# run as root? if not, exit
if [ "$EUID" -ne 0 ]
  then echo "Please run installation as root"
  exit
fi

# get user name
user="$(who | head -n1 | awk '{print $1;}')"

# declare download URLs
openrefine_server_URL="https://github.com/OpenRefine/OpenRefine/releases/download/2.8/openrefine-linux-2.8.tar.gz"
openrefine_client_URL="https://github.com/opencultureconsulting/openrefine-client/releases/download/v0.3.4/openrefine-client_0-3-4_linux-64bit"
metha_URL="https://github.com/miku/metha/releases/download/v0.1.24/metha_0.1.24_amd64.deb"
solr_URL="http://archive.apache.org/dist/lucene/solr/7.1.0/solr-7.1.0.tgz"

# create directories
sudo -u $(who | awk '{print $1}') mkdir -p data
sudo -u $(who | awk '{print $1}') mkdir -p data/01_oai
sudo -u $(who | awk '{print $1}') mkdir -p data/02_transformed
sudo -u $(who | awk '{print $1}') mkdir -p data/solr
sudo -u $(who | awk '{print $1}') mkdir -p log
sudo -u $(who | awk '{print $1}') mkdir -p opt

# install JRE
JAVA="$(which java 2> /dev/null)"
if [ -z "$JAVA" ] ; then
    apt-get -qq update && apt-get -qq --yes install default-jre
fi

# install curl
curl="$(which curl 2> /dev/null)"
if [ -z "$curl" ] ; then
    apt-get -qq update && apt-get -qq --yes install curl
fi

# install metha
metha="$(which metha-sync 2> /dev/null)"
if [ -z "$metha" ] ; then
    wget $metha_URL
    apt-get install ./$(basename $metha_URL)
    rm $(basename $metha_URL)
fi

# install OpenRefine
if [ ! -d "opt/openrefine" ]; then
    echo "Download OpenRefine..."
    mkdir -p opt/openrefine
    wget $openrefine_server_URL
    echo "Install OpenRefine in subdirectory openrefine..."
    tar -xzf "$(basename $openrefine_server_URL)" -C opt/openrefine --strip 1 --totals
    rm "$(basename $openrefine_server_URL)"
    sed -i '$ a JAVA_OPTIONS=-Drefine.headless=true' opt/openrefine/refine.ini
    sed -i 's/#REFINE_AUTOSAVE_PERIOD=60/REFINE_AUTOSAVE_PERIOD=1440/' opt/openrefine/refine.ini
    sed -i 's/-Xms$REFINE_MIN_MEMORY/-Xms$REFINE_MEMORY/' opt/openrefine/refine
    echo ""
fi

# install OpenRefine service
if [ ! -f "/etc/systemd/system/openrefine.service" ]; then
  path_openrefine=$(readlink -f opt/openrefine)
  echo "[Unit]
User=${user}
Group=${user}
Description=OpenRefine
[Service]
ExecStart=${path_openrefine}/refine -i 0.0.0.0
[Install]
WantedBy=default.target
" > /etc/systemd/system/openrefine.service
  systemctl daemon-reload
  systemctl enable openrefine.service
  systemctl start openrefine.service
fi

# install OpenRefine client
if [ ! -f "opt/openrefine-client" ]; then
    echo "Download OpenRefine client..."
    wget -O opt/openrefine-client $openrefine_client_URL
    chmod +x opt/openrefine-client
    echo ""
fi

# install Solr service
if [ ! -d "opt/solr" ]; then
  path_opt=$(readlink -f opt)
  path_data=$(readlink -f data)
  wget $solr_URL
  tar xzf $(basename $solr_URL) $(basename -s .tgz $solr_URL)/bin/install_solr_service.sh --strip-components=2
  ./install_solr_service.sh $(basename $solr_URL) -i ${path_opt} -d ${path_data}/solr -n
  rm $(basename $solr_URL)
  rm install_solr_service.sh
  echo "add ${user} to group solr..."
  adduser ${user} solr
  echo "start Solr service..."
  sudo service solr start
  echo "create Solr core hos..."
  sudo -u solr opt/solr/bin/solr create -c hos
fi
