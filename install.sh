#!/bin/bash
# https://github.com/subhh/HOS-MetadataTransformations

# run as root? if not, exit
if [ "$EUID" -ne 0 ]
  then echo 1>&2 "Please run installation as root"
  exit 2
fi

# get user name
user="$(who | head -n1 | awk '{print $1;}')"

# declare download URLs
openrefine_server_URL="https://github.com/OpenRefine/OpenRefine/releases/download/3.2/openrefine-linux-3.2.tar.gz"
openrefine_client_URL="https://github.com/opencultureconsulting/openrefine-client/releases/download/v0.3.4/openrefine-client_0-3-4_linux-64bit"
metha_URL="https://github.com/miku/metha/releases/download/v0.1.29/metha_0.1.29_amd64.deb"
solr_URL="https://archive.apache.org/dist/lucene/solr/7.3.1/solr-7.3.1.tgz"

# create directories
sudo -u $(who | awk '{print $1}') mkdir -p data
sudo -u $(who | awk '{print $1}') mkdir -p data/01_oai
sudo -u $(who | awk '{print $1}') mkdir -p data/02_transformed
sudo -u $(who | awk '{print $1}') mkdir -p data/03_combined
sudo -u $(who | awk '{print $1}') mkdir -p data/solr
sudo -u $(who | awk '{print $1}') mkdir -p log
sudo -u $(who | awk '{print $1}') mkdir -p opt

# install JRE
JAVA="$(which java 2> /dev/null)"
if [ -z "$JAVA" ] ; then
    add-apt-repository -y universe && apt-get -qq update && apt-get -qq --yes install openjdk-8-jre-headless
fi

# install zip
zip="$(which zip 2> /dev/null)"
if [ -z "$zip" ] ; then
    apt-get -qq update && apt-get -qq --yes install zip
fi

# install curl
curl="$(which curl 2> /dev/null)"
if [ -z "$curl" ] ; then
    apt-get -qq update && apt-get -qq --yes install curl
fi

# install jq
jq="$(which jq 2> /dev/null)"
if [ -z "$jq" ] ; then
    apt-get -qq update && apt-get -qq --yes install jq
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
    sed -i 's/#REFINE_AUTOSAVE_PERIOD=60/REFINE_AUTOSAVE_PERIOD=1500/' opt/openrefine/refine.ini
    sed -i 's/-Xms$REFINE_MIN_MEMORY/-Xms$REFINE_MEMORY/' opt/openrefine/refine
    echo ""
fi

# install OpenRefine service
if [ ! -f "/etc/systemd/system/openrefine.service" ]; then
  path_openrefine=$(readlink -f opt/openrefine)
  echo "[Unit]
Description=OpenRefine
[Service]
User=${user}
ExecStart=${path_openrefine}/refine -i 0.0.0.0 -m 2048M
TimeoutStopSec=3600s
Restart=always
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
if [ ! -f "/etc/init.d/solr" ]; then
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
fi

# show Solr status
sudo /etc/init.d/solr status

# create Solr core
echo "create Solr core hos..."
sudo -u solr $(grep SOLR_INSTALL_DIR= /etc/init.d/solr | sed 's/\"//g' | sed 's/SOLR_INSTALL_DIR=//')/bin/solr create -c hos

# check UTF-8 environment
if ! (locale | grep -e 'utf8' -e 'UTF-8') >/dev/null 2>&1; then
  echo 1>&2 "WARNING:"
  echo 1>&2 "# we need an UTF-8 environment for data processing"
  echo 1>&2 "# please update your locale to UTF-8"
  echo 1>&2 "sudo dpkg-reconfigure locales"
  echo 1>&2 ". /etc/default/locale"
  exit 2
fi
