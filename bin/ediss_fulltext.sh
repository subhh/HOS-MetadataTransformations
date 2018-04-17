#!/bin/bash
# https://github.com/subhh/HOS-MetadataTransformations

# change directory to location of shell script
cd $(dirname $0)

# pathnames
metadata_dir="$(readlink -f ../data/03_fulltext/ediss)"
tempdoc_dir="$(readlink -f ../data/03_fulltext/ediss/tempdoc)"
fulltext_dir="$(readlink -f ../data/03_fulltext/ediss/fulltext)"
opt_dir="$(readlink -f ../opt)"
#log_dir="$(readlink -f ../log)"

# filenames
targets_file="$metadata_dir/ediss_fulltextlinks.tsv"


# executables
tica_jar="$opt_dir/tika-app-1.17.jar"


# check for environment
if [ ! -f "$tica_jar" ]; then
    >&2 echo "tica not found!"
    exit 1
fi

if [ ! -d "$tempdoc_dir" ]; then
    mkdir -p "$tempdoc_dir" 
fi

if [ ! -d "$fulltext_dir" ]; then
    mkdir -p "$fulltext_dir" 
fi



# start metha TODO

# start Openrefine TODO

# fetch documents based on tsv

if [ ! -f "$targets_file" ]; then
    >&2 echo "$targets_file not found!"
    exit 1
fi

{
  read
  IFS_OLD=$IFS
  IFS='{	}'
  while read first second; do
    echo $first
    echo $second
    if [ ! -f "$fulltext_dir/$first" ]; then
        curl -s "$second" > $tempdoc_dir/$first.pdf
    fi 
  done 
} < "$targets_file" 
IFS=$IFS_OLD

# now batch process apache tika

java -jar "$tica_jar" --text --inputDir "$tempdoc_dir" --outputDir "$fulltext_dir" 

# remove file suffixes

rename s/\.pdf\.txt//i $fulltext_dir/*

# clean the pdf documents
rm $tempdoc_dir/*.pdf
