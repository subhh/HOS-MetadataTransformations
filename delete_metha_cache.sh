#!/bin/bash
# https://github.com/subhh/HOS-MetadataTransformations

# change directory to location of shell script
cd $(dirname $0)

# help screen
function usage () {
    cat <<EOF
Usage: ./delete-metha-cache.sh [-c CODENAME] [-i OAIURL] [-s OAISET] [-f OAIFORMAT] [-r RECORDPATH] [-d OPENREFINEURL]

== options ==
    -i metha-dir     Absolute path to the metha data directory. Default: /home/etl/.metha
    -r backup file   Absolute path/name of the backup file. Warning: Old file will be deleted / overwritten. Default: /home/etl/metha_cache.tar.gz

== examples ==
./delete-metha-cache.sh
./delete-metha-cache.sh -i /home/refine/.metha -r /opt/backups/metha.tar.gz
EOF
   exit 1
}

# defaults
metha_dir="/home/etl/.metha"
backup_file="/home/etl/metha_cache.tar.gz"

# get user input
options="i:r:h"
while getopts $options opt; do
   case $opt in
   i )  metha_dir=${OPTARG} ;;
   r )  backup_file=${OPTARG} ;;
   h )  usage ;;
   \? ) echo 1>&2 "Unknown option: -$OPTARG"; usage; exit 1;;
   :  ) echo 1>&2 "Missing option argument for -$OPTARG"; usage; exit 1;;
   *  ) echo 1>&2 "Unimplemented option: -$OPTARG"; usage; exit 1;;
   esac
done
shift $((OPTIND - 1))

# move data to tmp
## Moving is necessary to accelerate process
mkdir -p /tmp/.metha
mv "${metha_dir}"/* /tmp/.metha/

# backup old data 
rm "${backup_file}"
tar cvzf "${backup_file}" /tmp/.metha
