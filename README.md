# HOS-MetadataTransformations

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/6d9c8171289f424b903d22682663bb6d)](https://www.codacy.com/app/felixlohmeier/HOS-MetadataTransformations?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=subhh/HOS-MetadataTransformations&amp;utm_campaign=Badge_Grade)

Automated workflow for harvesting, transforming and indexing of metadata using [metha](https://github.com/miku/metha), [OpenRefine](http://openrefine.org/) and [Solr](http://lucene.apache.org/solr/). Part of the [Hamburg Open Science](http://www.hamburg.de/openscience) "Schaufenster" software stack.

## Use case

1. Harvest metadata in different standards (dublin core, datacite, ...) from multiple [OAI-PMH](https://www.openarchives.org/pmh/) endpoints
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

tested with [Ubuntu 16.04 LTS](http://releases.ubuntu.com/16.04/) and [Ubuntu 18.04 LTS](http://releases.ubuntu.com/18.04/)

install git:

```
sudo apt install git
```

clone this git repository:

```
git clone https://github.com/subhh/HOS-MetadataTransformations.git
cd HOS-MetadataTransformations
```

install [openjdk-8-jre-headless](https://packages.ubuntu.com/search?keywords=openjdk-8-jre-headless), [zip](https://packages.ubuntu.com/search?keywords=zip), [curl](https://curl.haxx.se/), [jq](https://stedolan.github.io/jq/), [metha 1.29](https://github.com/miku/metha), [OpenRefine 2.8](http://openrefine.org/), [openrefine-client 0.3.4](https://github.com/opencultureconsulting/openrefine-client) and [Solr 7.3.1](http://lucene.apache.org/solr/):

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

Run workflow with data source "ediss" and load data into local Solr (-s) and local OpenRefine service (-d)

```
bin/ediss.sh -s http://localhost:8983/solr/hos -d http://localhost:3333
```

Run workflow with all data sources in parallel and load data into local Solr (-s) and local OpenRefine service (-d):

```
./run.sh -s http://localhost:8983/solr/hos -d http://localhost:3333
```

Run workflow with all data sources and load data into two external Solr cores (-s) and external OpenRefine service (-d)

```
./run.sh -s https://hosdev.sub.uni-hamburg.de/solrAdmin/HOS -s https://openscience.hamburg.de/solrAdmin/HOS -d http://openrefine.sub.uni-hamburg.de:80
```

### Solr authentication

If your external Solr is secured with username/password (Basic Authentication Plugin), you may provide the credentials by copying [cfg/solr/credentials.example](cfg/solr/credentials.example) to `cfg/solr/credentials` and fill in username and password.

```
cp cfg/solr/credentials.example cfg/solr/credentials
nano cfg/solr/credentials
chmod 400 cfg/solr/credentials
```

### Cronjobs

Example for daily cronjob at 00:05 AM to restart local OpenRefine service (to free up memory)

```
command="systemctl restart openrefine"
job="5 0 * * * $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -
```

Example for daily cronjob at 00:35 AM to run workflow with all data sources, load data into external Solr core (-s) and external OpenRefine service (-d) and delete files older than 7 days (-x)

```
command="$(readlink -f run.sh) -s https://hosdev.sub.uni-hamburg.de/solrAdmin/HOS -d http://openrefine.sub.uni-hamburg.de:80 -x 7"
job="5 0 * * * $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -
```

## Add a data source

* Step 1: Harvest new OAI-PMH endpoint and load data into OpenRefine. Example for a new data source called `yourdatasource` with OAI-PMH endpoint `http://ediss.sub.uni-hamburg.de/oai2/oai2.php`:

```
./load-new-data.sh -c yourdatasource -i http://ediss.sub.uni-hamburg.de/oai2/oai2.php
```

* Step 2: Explore the data in OpenRefine at <http://localhost:3333> (project `yourdatasource_new`) and create transformations until data looks fine and suits the [Solr schema](cfg/solr).

* Step 3: [Extract the OpenRefine project history in json format](http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html) and save it in a subdirectory of cfg/, e.g. `cfg/yourdatasource/transformation.json`.

* Step 4: Copy an existing bash shell script (e.g. [bin/ediss.sh](bin/ediss.sh) to `bin/yourdatasource.sh` and edit line 17 (codename of the source, e.g. `yourdatasource`) and line 18 (url to OAI-PMH endpoint, e.g. `http://ediss.sub.uni-hamburg.de/oai2/oai2.php`). If you load a big dataset you may need to allocate more memory to OpenRefine (line 19).

```
cp -a bin/ediss.sh bin/yourdatasource.sh
gedit bin/yourdatasource.sh
```

* Step 5: Run your shell script (or full workflow)

```
bin/yourdatasource.sh -s http://localhost:8983/solr/hos -d http://localhost:3333
```

* Step 6: Check results in OpenRefine at <http://localhost:3333> (project `yourdatasource_live`) and Solr (query: [collectionId:yourdatasource](http://localhost:8983/solr/hos/browse?q=collectionId%3Ayourdatasource))
