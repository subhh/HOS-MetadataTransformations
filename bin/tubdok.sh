#!/bin/bash
# https://github.com/subhh/HOS-MetadataTransformations

# change directory to location of shell script
cd $(dirname $0)

# pathnames
metha_sync="$(which metha-sync)"
metha_cat="$(which metha-cat)"
recordpath=(Records Record) # metha-cat default xml path to harvested records
openrefine_server="$(readlink -f ../opt/openrefine/refine)"
openrefine_client="$(readlink -f ../opt/openrefine-client)"
data_dir="$(readlink -f ../data)"
log_dir="$(readlink -f ../log)"

# config
source="tubdok" # name of OpenRefine project and value for Solr field "collection"
oai_url="http://tubdok.tub.tuhh.de/oai/request" # base url of OAI-PMH endpoint
ram="2048M" # highest OpenRefine memory load is below 2048M
recordpath+=(metadata) # select /Records/Record/metadata (ignoring /Records/Record/header)
separator="%E2%90%9F" # multiple values are separated by unicode character unit separator (U+241F)
config_dir="$(readlink -f ../cfg/${source})" # location of OpenRefine transformation rules in json format

# help screen
function usage () {
    cat <<EOF
Usage: ./${source}.sh [-p PORT] [-s SOLRURL] [-d OPENREFINEURL]

== options ==
    -p PORT          PORT on which OpenRefine should run (default: 3334)
    -s SOLRURL       ingest data to specified Solr core (default: http://localhost:8983/solr/hos)
    -d OPENREFINEURL ingest data to external OpenRefine service (default: http://localhost:3333)

== example ==
./${source}.sh -p 3334 -s http://localhost:8983/solr/hos -d http://localhost:3333
EOF
   exit 1
}

# defaults
port="3334"
solr_url="http://localhost:8983/solr/hos"
openrefine_url="http://localhost:3333"

# get user input
options="p:s:d:h"
while getopts $options opt; do
   case $opt in
   p )  port=${OPTARG} ;;
   s )  solr_url=${OPTARG} ;;
   d )  openrefine_url=${OPTARG} ;;
   h )  usage ;;
   \? ) echo 1>&2 "Unknown option: -$OPTARG"; usage; exit 1;;
   :  ) echo 1>&2 "Missing option argument for -$OPTARG"; usage; exit 1;;
   *  ) echo 1>&2 "Unimplemented option: -$OPTARG"; usage; exit 1;;
   esac
done
shift $((OPTIND - 1))

# declare additional variables
date=$(date +%Y%m%d_%H%M%S)
openrefine_tmp="/tmp/openrefine_${date}"
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Start process"
memoryload=()
multivalue_config=()
external=${openrefine_url##*/}
external_host=${external%:*}
external_port=${external##*:}
if [ -n "${config_dir// }" ] ; then jsonfiles=($(find -L "${config_dir}"/* -type f -printf "%f\n" 2>/dev/null))

# safe cleanup handler
cleanup()
{
  echo "cleanup..."
  kill -9 ${pid}
  rm -rf /tmp/openrefine_${date}
  wait
}
trap "cleanup;exit" SIGHUP SIGINT SIGQUIT SIGTERM

# Simple Logging
exec &> >(tee -a "${log_dir}/${source}_${date}.log")

# print variables
echo "Source name:             $source"
echo "Source OAI Server:       $oai_url"
echo "Transformation rules:    ${jsonfiles[*]}"
echo "OpenRefine heap space:   $ram"
echo "OpenRefine port:         $port"
echo "Solr core URL:           $solr_url"
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
$metha_sync "$oai_url"
$metha_cat "$oai_url" > "${data_dir}/01_oai/${source}_${date}.xml"
records_metha=$(grep -c '<Record>' "${data_dir}/01_oai/${source}_${date}.xml")
echo "saved $records_metha records in ${data_dir}/01_oai/${source}_${date}.xml"
echo ""

# Launch OpenRefine server
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Launch OpenRefine server"
echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
echo ""
echo "starting time: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
echo ""
$openrefine_server -p ${port} -d "$openrefine_tmp" -m ${ram} &
pid=$!
until wget -q -O - http://localhost:${port} | cat | grep -q -o "OpenRefine" ; do sleep 1; done
echo ""

# Load data
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Load data"
echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
echo ""
echo "starting time: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
echo ""
$openrefine_client -P ${port} --create "${data_dir}/01_oai/${source}_${date}.xml" $(for i in ${recordpath[@]}; do echo "--recordPath=$i "; done)
echo ""
ps -o start,etime,%mem,%cpu,rss -p ${pid} --sort=start
memoryload+=($(ps --no-headers -o rss -p ${pid}))
echo ""

# Transform data
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Transform data"
echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
echo ""
echo "starting time: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
echo ""
for f in "${jsonfiles[@]}" ; do
    echo "transform ${f}..."
    $openrefine_client -P ${port} --apply "${config_dir}/${f}" "${source}_${date}"
    ps -o start,etime,%mem,%cpu,rss -p ${pid} --sort=start
    memoryload+=($(ps --no-headers -o rss -p ${pid}))
    echo ""
done
echo ""

# Export data
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Export data"
echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
echo ""
echo "starting time: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
echo ""
$openrefine_client -P ${port} --export --output="${data_dir}/02_transformed/${source}_${date}.tsv" "${source}_${date}"
echo ""
ps -o start,etime,%mem,%cpu,rss -p ${pid} --sort=start
memoryload+=($(ps --no-headers -o rss -p ${pid}))
echo ""

# Stop OpenRefine server
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Stop OpenRefine server"
echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
echo ""
echo "starting time: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
echo ""
cleanup
echo ""

# Ingest data into Solr
if [ -n "$solr_url" ]; then
  checkpoints=${#checkpointdate[@]}
  checkpointdate[$((checkpoints + 1))]=$(date +%s)
  checkpointname[$((checkpoints + 1))]="Ingest data into Solr"
  echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
  echo ""
  echo "starting time: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
  echo ""
  # read header from tsv
  readarray multivalue_fields < <(head -n 1 "${data_dir}/02_transformed/${source}_${date}.tsv" | sed 's/\t/\n/g')
  for i in ${multivalue_fields[@]}; do
      multivalue_config+=(\&f.$i.separator=$separator)
  done
  multivalue_config=$(printf %s "${multivalue_config[@]}")
  # delete existing data
  curl --silent "${solr_url}/update?commit=true" -H "Content-Type: text/xml" --data-binary "<delete><query>collection:${source}</query></delete>" 1>/dev/null
  # load new data
  curl "${solr_url}/update/csv?commit=true&optimize=true&separator=%09&literal.collection=${source}&split=true${multivalue_config}" --data-binary @- -H 'Content-type:text/plain; charset=utf-8' < ${data_dir}/02_transformed/${source}_${date}.tsv 1>/dev/null
  echo ""
fi

# Ingest data into OpenRefine
if [ -n "$openrefine_url" ]; then
  checkpoints=${#checkpointdate[@]}
  checkpointdate[$((checkpoints + 1))]=$(date +%s)
  checkpointname[$((checkpoints + 1))]="Ingest data into OpenRefine"
  echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
  echo ""
  echo "starting time: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
  echo ""
  ${openrefine_client} -H ${external_host} -P ${external_port} --delete "${source}_live" &>/dev/null
  ${openrefine_client} -H ${external_host} -P ${external_port} --create "${data_dir}/02_transformed/${source}_${date}.tsv" --encoding=UTF-8 --projectName=${source}_live
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

# calculate and print memory load
max=${memoryload[0]}
for n in "${memoryload[@]}" ; do
    ((n > max)) && max=$n
done
echo "highest memory load: $((max / 1024)) MB of $ram"
