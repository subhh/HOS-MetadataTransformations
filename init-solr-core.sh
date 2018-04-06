#!/bin/bash
# https://github.com/subhh/HOS-MetadataTransformations

# help screen
function usage () {
    cat <<EOF
Usage: ./init-solr-core.sh [-s SOLRURL] [-c CORE]

== options ==
    -s SOLRURL       URL to Solr service (default: http://localhost:8983/solr)
    -c CORE          name for Solr core (default: hos)

== example ==
./init-solr-core.sh -s http://localhost:8983/solr -c hos
EOF
   exit 1
}

# defaults
solr_url="http://localhost:8983/solr"
solr_core="hos"

# get user input
options="s:c:h"
while getopts $options opt; do
   case $opt in
   s )  solr_url=${OPTARG} ;;
   c )  solr_core=${OPTARG} ;;
   h )  usage ;;
   \? ) echo 1>&2 "Unknown option: -$OPTARG"; usage; exit 1;;
   :  ) echo 1>&2 "Missing option argument for -$OPTARG"; usage; exit 1;;
   *  ) echo 1>&2 "Unimplemented option: -$OPTARG"; usage; exit 1;;
   esac
done
shift $((OPTIND - 1))

# add fields
# curl -X POST -H 'Content-type:application/json' --data-binary '{"add-field" : ... }' http://localhost:8983/solr/hos/schema

# add copy fields
# curl -X POST -H 'Content-type:application/json' --data-binary '{"add-copy-field" : ... }' http://localhost:8983/solr/hos/schema
