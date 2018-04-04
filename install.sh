#!/bin/bash
# install.sh, Felix Lohmeier, v0.2, 2018-04-04
# https://github.com/subhh/HOS-MetadataTransformations

# declare download URLs
openrefine_server_URL="https://github.com/OpenRefine/OpenRefine/releases/download/2.8/openrefine-linux-2.8.tar.gz"
openrefine_client_URL="https://github.com/opencultureconsulting/openrefine-client/releases/download/v0.3.4/openrefine-client_0-3-4_linux-64bit"
metha_URL="https://github.com/miku/metha/releases/download/v0.1.24/metha_0.1.24_amd64.deb"

# create directories
mkdir -p data
mkdir -p data/01_oai
mkdir -p data/02_transformed
mkdir -p log
mkdir -p opt

# install JAVA JRE
JAVA="$(which java 2> /dev/null)"
if [ -z "$JAVA" ] ; then
    apt-get -qq update && apt-get -qq --yes install default-jre
fi

# install metha
metha="$(which metha-sync 2> /dev/null)"
if [ -z "$metha" ] ; then
    wget -q $metha_URL
    apt-get install ./$(basename $metha_URL)
    rm $(basename $metha_URL)
fi

# install OpenRefine
if [ ! -d "opt/openrefine" ]; then
    echo "Download OpenRefine..."
    mkdir -p opt/openrefine
    wget -q $openrefine_server_URL
    echo "Install OpenRefine in subdirectory openrefine..."
    tar -xzf "$(basename $openrefine_server_URL)" -C opt/openrefine --strip 1 --totals
    rm -f "$(basename $openrefine_server_URL)"
    sed -i '$ a JAVA_OPTIONS=-Drefine.headless=true' opt/openrefine/refine.ini
    sed -i 's/#REFINE_AUTOSAVE_PERIOD=60/REFINE_AUTOSAVE_PERIOD=1440/' opt/openrefine/refine.ini
    sed -i 's/-Xms$REFINE_MIN_MEMORY/-Xms$REFINE_MEMORY/' opt/openrefine/refine
    echo ""
fi

# install OpenRefine client
if [ ! -f "opt/openrefine-client" ]; then
    echo "Download OpenRefine client..."
    wget -q -O opt/openrefine-client $openrefine_client_URL
    chmod +x opt/openrefine-client
    echo ""
fi
