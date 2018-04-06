#!/bin/bash
# https://github.com/subhh/HOS-MetadataTransformations

# change directory to location of shell script
cd $(dirname $0)

# help screen
function usage () {
    cat <<EOF
Usage: ./run.sh [-s SOLRURL] [-d OPENREFINEURL]

== options ==
    -s SOLRURL       ingest data to specified Solr core (default: http://localhost:8983/solr/hos)
    -d OPENREFINEURL ingest data to external OpenRefine service (default: http://localhost:3333)

== example ==
./run.sh -s http://localhost:8983/solr/hos -d http://localhost:3333
EOF
   exit 1
}

# defaults
port="3334"
solr_url="http://localhost:8983/solr/hos"
openrefine_url="http://localhost:3333"

# get user input
options="s:d:h"
while getopts $options opt; do
   case $opt in
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
pid=()
path_bin=$(readlink -f bin)
path_log=$(readlink -f log)
date=$(date +%Y%m%d_%H%M)

# safe cleanup handler
cleanup()
{
  echo "cleanup..."
  for i in ${pid[@]}; do
    kill $i &
  done
  wait
}
trap "cleanup;exit" SIGHUP SIGINT SIGQUIT SIGTERM

# print variables
echo "Solr core URL:           $solr_url"
echo "OpenRefine service URL:  $openrefine_url"
echo ""

# run jobs
echo "run scripts in parallel..."
for f in "${path_bin}"/*.sh; do
  "${f}" -p $port -s "${solr_url}" -d "${openrefine_url}" > /dev/null &
  pid+=("$!")
  echo -en "$(basename ${f}) ($!)   "
  port=$((port + 1))
done
echo ""
echo ""

# watch stats
echo "wait until all jobs are done..."
count="1"
until [[ "$count" -eq "0" ]]; do
  stats=$(ps --no-headers -o %mem,%cpu ax | awk '{mem += $1; cpu += $2} END {print "%MEM: " mem, "  %CPU: " cpu}')
  count=$(ps --no-headers -p ${pid[@]} | wc -l)
  echo -en "\r $stats   Jobs: $count   Elapsed: $SECONDS     "
  sleep 5
done
echo ""
echo ""

# print logs
echo "print stats from logs..."
for f in "${path_bin}"/*.sh; do
  stats=$(tail -n 2 "${path_log}/$(basename -s .sh ${f})_${date}"*.log |  sed 's/total run time://' | sed 's/highest memory load://')
  echo $(basename ${f}): $stats
done
