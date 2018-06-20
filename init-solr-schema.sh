#!/bin/bash
# https://github.com/subhh/HOS-MetadataTransformations

# help screen
function usage () {
    cat <<EOF
Usage: ./init-solr-schema.sh [-s SOLRURL]

== options ==
    -s SOLR       URL to Solr core (default: http://localhost:8983/solr/hos)

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

# get sysenv
if [ -n "$HOSSOLRUSER" ]; then solr_credentials="-u $HOSSOLRUSER:$HOSSOLRPASS"; fi

# declare additional variables
path_config=$(readlink -f cfg/solr)
solr_base=${solr_url%/*}
solr_core=${solr_url##*/}

# delete existing data
echo "delete existing data..."
curl $solr_credentials -sS "${solr_base}/${solr_core}/update?commit=true" -H "Content-Type: text/xml" --data-binary "<delete><query>*:*</query></delete>" 1>/dev/null

# delete fields and copy fields
echo "delete fields and copy fields..."
curl $solr_credentials -sS -X POST -H 'Content-type:application/json' --data-binary "{ \"delete-copy-field\" : $(curl $solr_credentials --silent "${solr_base}/${solr_core}/schema/copyfields" | jq '[.copyFields[] | {source: .source, dest: .dest}]') }" ${solr_base}/${solr_core}/schema
curl $solr_credentials -sS "${solr_base}/admin/cores?action=RELOAD&core=${solr_core}" 1>/dev/null
curl $solr_credentials -sS -X POST -H 'Content-type:application/json' --data-binary "{ \"delete-field\" : $(curl $solr_credentials --silent "${solr_base}/${solr_core}/schema/fields" | jq '[ .fields[] | {name: .name } ]') }" ${solr_base}/${solr_core}/schema

# add fields and copy fields
echo "add fields and copy fields..."
curl $solr_credentials -sS -X POST -H 'Content-type:application/json' --data-binary "{ \"add-field\" : $(< ${path_config}/fields.json) }" ${solr_base}/${solr_core}/schema
curl $solr_credentials -sS -X POST -H 'Content-type:application/json' --data-binary "{ \"add-copy-field\" : $(< ${path_config}/copyfields.json) }" ${solr_base}/${solr_core}/schema
