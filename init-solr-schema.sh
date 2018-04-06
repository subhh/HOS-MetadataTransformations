#!/bin/bash
# https://github.com/subhh/HOS-MetadataTransformations

# help screen
function usage () {
    cat <<EOF
Usage: ./init-solr-schema.sh [-s SOLRURL]

== options ==
    -s SOLRURL       URL to Solr core (default: http://localhost:8983/solr/hos)

== example ==
./init-solr-schema.sh -s http://localhost:8983/solr/hos
EOF
   exit 1
}

# defaults
solr_url="http://localhost:8983/solr/hos"

# get user input
options="s:h"
while getopts $options opt; do
   case $opt in
   s )  solr_url=${OPTARG} ;;
   h )  usage ;;
   \? ) echo 1>&2 "Unknown option: -$OPTARG"; usage; exit 1;;
   :  ) echo 1>&2 "Missing option argument for -$OPTARG"; usage; exit 1;;
   *  ) echo 1>&2 "Unimplemented option: -$OPTARG"; usage; exit 1;;
   esac
done
shift $((OPTIND - 1))

# declare additional variables
path_config=$(readlink -f cfg/solr)

# delete existing data
echo "delete existing data..."
curl --silent "${solr_url}/update?commit=true" -H "Content-Type: text/xml" --data-binary "<delete><query>*:*</query></delete>" 1>/dev/null

# delete fields
echo "delete existing fields..."
curl -X POST -H 'Content-type:application/json' --data-binary "{ \"delete-field\" : [ $(curl --silent "http://localhost:8983/solr/hos/schema/fields" | grep name | grep -v "_root_\|_text_\|_version_\|\"id\"" | sed 's/,/}/g' | sed 's/\"name\"/{\"name\"/' | sed 's/$/,/' | sed '$ s/,//') ] }" ${solr_url}/schema

# add fields
echo "add fields..."
curl -X POST -H 'Content-type:application/json' --data-binary "{ \"add-field\" : $(< ${path_config}/fields.json) }" ${solr_url}/schema

# delete fields
echo "delete existing copy fields..."
curl -X POST -H 'Content-type:application/json' --data-binary "{ \"delete-copy-field\" : [ $(curl --silent "http://localhost:8983/solr/hos/schema/copyfields" | grep name | grep -v "_root_\|_text_\|_version_\|\"id\"" | sed 's/,/}/g' | sed 's/\"name\"/{\"name\"/' | sed 's/$/,/' | sed '$ s/,//') ] }" ${solr_url}/schema

# add copy fields
echo "add copy fields..."
curl -X POST -H 'Content-type:application/json' --data-binary "{ \"add-copy-field\" : $(< ${path_config}/copyfields.json) }" ${solr_url}/schema
