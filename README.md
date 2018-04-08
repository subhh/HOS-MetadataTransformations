# HOS-MetadataTransformations

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/6d9c8171289f424b903d22682663bb6d)](https://www.codacy.com/app/felixlohmeier/HOS-MetadataTransformations?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=subhh/HOS-MetadataTransformations&amp;utm_campaign=Badge_Grade)

Automated workflow for harvesting, transforming and indexing of bibliographic metadata using [metha](https://github.com/miku/metha), [OpenRefine](http://openrefine.org/) and [Solr](http://lucene.apache.org/solr/). Part of the [Hamburg Open Science](http://www.hamburg.de/openscience) "Schaufenster" software stack.

## Use case

1. Harvest bibliographic metadata in different standards (dublin core, datacite, ...) from multiple [OAI-PMH](https://www.openarchives.org/pmh/) endpoints
2. Transform harvested data with specific rules for each source to produce normalized and enriched data
3. Load transformed data into a Solr search index (which serves as a backend for a discovery system, e.g. [HOS-TYPO3-find](https://github.com/subhh/HOS-TYPO3-find))

## Data Flow

[![mermaid flowchart](flowchart.png)](https://github.com/subhh/HOS-MetadataTransformations/raw/master/flowchart.png)

Source: [flowchart.mmd](flowchart.mmd) (try [mermaid live editor](https://mermaidjs.github.io/mermaid-live-editor/))

## Features

* Simple automated cronjob-ready workflow: [one bash script for each data source](bin) and [an additional script to run all scripts in parallel](run.sh)
* Cache for incremental OAI harvesting (via [metha](https://github.com/miku/metha))
* Graphical user interface ([OpenRefine](http://openrefine.org/)) for exploring the data,  [creating the transformation rules](http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html) and checking the results; it is accessible in the local network via a web browser; data will be updated automatically
* Results are made available in preinstalled local or in external Solr core. You can set (and reset) the [Solr schema](cfg/solr) via [bash script](init-solr-schema.sh).
* Data is stored in the filesystem in common formats (xml, tsv) so you can extend the workflow with [command line tools](http://jorol.de/2016-ELAG-Bootcamp/slides/) to further manipulate the data.

## Installation

tested with [Ubuntu 16.04 LTS](https://www.ubuntu.com/download/desktop)

install git:

```
sudo apt install git
```

clone this git repository:

```
git clone https://github.com/subhh/HOS-MetadataTransformations.git
cd HOS-MetadataTransformations
```

install [default-jre](https://packages.ubuntu.com/de/xenial/default-jre), [curl](https://curl.haxx.se/), [metha](https://github.com/miku/metha), [OpenRefine](http://openrefine.org/), [openrefine-client](https://github.com/opencultureconsulting/openrefine-client) and [Solr](http://lucene.apache.org/solr/):

```
sudo ./install.sh
```

Configure [Solr schema](cfg/solr):

```
./init-solr-schema.sh
```

## Usage

Data will be available after first run at:

* Solr admin: <http://localhost:8983/solr/#/hos>
* Solr browse: <http://localhost:8983/solr/hos/browse>
* OpenRefine: <http://localhost:3333>

Run workflow with data source "ediss" and load data into local Solr and local OpenRefine service

```
bin/ediss.sh
```

Run workflow with all data sources in parallel and load data into local Solr and local OpenRefine service:

```
./run.sh
```

Run workflow with all data sources and load data into external Solr core

```
./run.sh -s "http://hosdev.sub.uni-hamburg.de:8983/solr/HOS_MASTER"

```

## Add a data source

* Step 1: Harvest new oai endpoint and load data into OpenRefine (this has to be done manually, a script will be provided shortly)

* Step 2: Explore the data in OpenRefine at <http://localhost:3333> and create transformations until data looks fine

* Step 3: [Extract the OpenRefine project history in json format](http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html) and save it in `cfg/yourdatasource/transformation.json`

* Step 4: Copy an existing bash shell script (e.g. [bin/ediss.sh](bin/ediss.sh) to `bin/yourdatasource.sh` and edit lines 8 (name of the source), 9 (url to oai endpoint) and 10 (RAM for OpenRefine container)

```
cp -a bin/ediss.sh bin/yourdatasource.sh
gedit bin/yourdatasource.sh
```

* Step 5: Run your shell script (or full workflow)

```
bin/yourdatasource.sh
```

* Step 6: Check results in OpenRefine at <http://localhost:3333> (project `yourdatasource_live`) and Solr (query: [collection:yourdatasource](http://localhost:8983/solr/hos/browse?q=collection%3Ayourdatasource))
