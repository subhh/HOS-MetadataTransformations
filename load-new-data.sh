#!/bin/bash
# https://github.com/subhh/HOS-MetadataTransformations

# change directory to location of shell script
cd $(dirname $0)

# pathnames
metha_sync="$(which metha-sync)"
metha_cat="$(which metha-cat)"
recordpath=(Records Record) # metha-cat default xml path to harvested records
openrefine_client="$(readlink -f opt/openrefine-client)"
data_dir="$(readlink -f data)"

# help screen
function usage () {
    cat <<EOF
Usage: ./load-new-data.sh [-c CODENAME] [-i OAIURL] [-s OAISET] [-f OAIFORMAT] [-r RECORDPATH] [-d OPENREFINEURL]

== options ==
    -c CODENAME      code name of the new data source
    -i OAIURL        url to the oai endpoint of the new data source
    -s OAISET        setSpec of the oai endpoint
    -f OAIFORMAT     metadataFormat of the oai endpoint
    -r RECORDPATH    filter data by additional xml node(s), e.g. "-r metadata" selects /Records/Record/metadata (ignoring /Records/Record/header)
    -d OPENREFINEURL ingest data to external OpenRefine service (default: http://localhost:3333)

== examples ==
./load-new-data.sh -c ediss -i http://ediss.sub.uni-hamburg.de/oai2/oai2.php -d http://localhost:3333
./load-new-data.sh -c tubdok -i http://tubdok.tub.tuhh.de/oai/request -r metadata -d http://localhost:3333
./load-new-data.sh -c zenodo-tuhh -i https://zenodo.org/oai2d -s user-tuhh -f datacite -r metadata -r resource -d http://localhost:3333
EOF
   exit 1
}

# defaults
openrefine_url="http://localhost:3333"

# check input
NUMARGS=$#
if [ "$NUMARGS" -eq 0 ]; then
  usage
fi

# get user input
options="c:i:s:f:r:d:h"
while getopts $options opt; do
   case $opt in
   c )  codename=${OPTARG} ;;
   i )  oai_url=${OPTARG} ;;
   s )  oai_set=${OPTARG} ;;
   f )  oai_format=${OPTARG} ;;
   r )  recordpath+=("${OPTARG}") ;;
   d )  openrefine_url=${OPTARG} ;;
   h )  usage ;;
   \? ) echo 1>&2 "Unknown option: -$OPTARG"; usage; exit 1;;
   :  ) echo 1>&2 "Missing option argument for -$OPTARG"; usage; exit 1;;
   *  ) echo 1>&2 "Unimplemented option: -$OPTARG"; usage; exit 1;;
   esac
done
shift $((OPTIND - 1))

# check for mandatory options
if [ -z "$codename" ]; then
    echo 1>&2 "please provide a name for the new data source"
    echo 1>&2 "example: ./load-new-data.sh -c ediss-test -i http://ediss.sub.uni-hamburg.de/oai2/oai2.php"
    exit 1
fi
if [ -z "$oai_url" ]; then
    echo 1>&2 "please provide the url to the oai endpoint of the new data source"
    echo 1>&2 "example: ./load-new-data.sh -c ediss-test -i http://ediss.sub.uni-hamburg.de/oai2/oai2.php"
    exit 1
fi

# declare additional variables
date=$(date +%Y%m%d_%H%M%S)
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Start process"
external=${openrefine_url##*/}
external_host=${external%:*}
external_port=${external##*:}

# print variables
echo "Code name:               $codename"
echo "OAI server:              $oai_url"
echo "OAI set:                 $oai_set"
echo "OAI metadata format:     $oai_format"
echo "Record path:             $(for i in ${recordpath[@]}; do echo -n "/$i"; done)"
echo "OpenRefine service URL:  $openrefine_url"
echo ""

# Download data via OAI with metha
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Download via OAI with metha"
echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
echo ""
echo "starting time: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
echo ""
$metha_sync $(if [ -n "$oai_set" ]; then echo "-set $oai_set"; fi) $(if [ -n "$oai_format" ]; then echo "-format $oai_format"; fi) "$oai_url"
$metha_cat $(if [ -n "$oai_set" ]; then echo "-set $oai_set"; fi) $(if [ -n "$oai_format" ]; then echo "-format $oai_format"; fi) "$oai_url" > "${data_dir}/01_oai/${codename}_${date}.xml"
records_metha=$(grep -c '<Record>' "${data_dir}/01_oai/${codename}_${date}.xml")
echo "saved $records_metha records in ${data_dir}/01_oai/${codename}_${date}.xml"
echo ""

# Ingest data into OpenRefine
if [ -n "$openrefine_url" ]; then
  checkpoints=${#checkpointdate[@]}
  checkpointdate[$((checkpoints + 1))]=$(date +%s)
  checkpointname[$((checkpoints + 1))]="Ingest data into OpenRefine"
  echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
  echo ""
  echo "starting time: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
  echo ""
  ${openrefine_client} -H ${external_host} -P ${external_port} --delete "${codename}_new" &>/dev/null
  ${openrefine_client} -H ${external_host} -P ${external_port} --create "${data_dir}/01_oai/${codename}_${date}.xml" $(for i in ${recordpath[@]}; do echo "--recordPath=$i "; done) --projectName=${codename}_new
  echo ""
fi

# calculate and print checkpoints
echo "=== Statistics ==="
echo ""
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="End process"
echo "starting time and run time of each step:"
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
for i in $(seq 1 $checkpoints); do
    diffsec="$((${checkpointdate[$((i + 1))]} - ${checkpointdate[$i]}))"
    printf "%35s $(date --date=@${checkpointdate[$i]}) ($(date -d@${diffsec} -u +%H:%M:%S))\n" "${checkpointname[$i]}"
done
echo ""
diffsec="$((checkpointdate[$checkpoints] - checkpointdate[1]))"
echo "$records_metha records"
echo "total run time: $(date -d@${diffsec} -u +%H:%M:%S) (hh:mm:ss)"
