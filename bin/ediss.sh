#!/bin/bash
# ediss.sh, Felix Lohmeier, v0.1, 2018-03-20
# Script zum Download via OAI, Transformation mit OpenRefine und Indexierung in Solr

# Programmpfade
openrefine_server="/home/hos/openrefine-2.8/refine"
openrefine_client="/home/hos/openrefine-client_0-3-4_linux-64bit"
metha_sync="/usr/sbin/metha-sync"
metha_cat="/usr/sbin/metha-cat"

# Konfiguration
source="ediss"
oai_url="http://ediss.sub.uni-hamburg.de/oai2/oai2.php"
openrefine_json="ediss.json"
ram="2048M"
port="3333"
solr_url="http://localhost:8983/solr/hos/"

# Weitere Variablen
date=$(date +%Y%m%d_%H%M%S)
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Start"
memoryload=()

# Verzeichnisse
cd $(dirname $0)
mkdir -p input workdir output log
workdir=$(readlink -f workdir)

# Einfaches Logging
exec &> >(tee -a "log/${date}.log")
echo "Quelle:  ${source}"
echo "URL:     ${oai_url}"
echo ""

# Download via OAI mit metha
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Download via OAI mit metha"
echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
echo ""
echo "Startzeitpunkt: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
echo ""
$metha_sync "$oai_url"
$metha_cat "$oai_url" > "input/${source}_${date}.xml"
echo ""

# OpenRefine Server starten
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="OpenRefine Server starten"
echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
echo ""
echo "Startzeitpunkt: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
echo ""
$openrefine_server -p ${port} -d "${workdir}" -m ${ram} &
pid=$!
until wget -q -O - http://localhost:${port} | cat | grep -q -o "OpenRefine" ; do sleep 1; done
echo ""

# Daten in OpenRefine laden
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Daten in OpenRefine laden"
echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
echo ""
echo "Startzeitpunkt: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
echo ""
$openrefine_client -P ${port} --create "input/${source}_${date}.xml" --recordPath=Records --recordPath=Record
echo ""
ps -o start,etime,%mem,%cpu,rss -p ${pid} --sort=start
memoryload+=($(ps --no-headers -o rss -p ${pid}))
echo ""

# Transformation in OpenRefine
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Transformation in OpenRefine"
echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
echo ""
echo "Startzeitpunkt: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
echo ""
$openrefine_client -P ${port} --apply "${openrefine_json}" "${source}_${date}"
echo ""
ps -o start,etime,%mem,%cpu,rss -p ${pid} --sort=start
memoryload+=($(ps --no-headers -o rss -p ${pid}))
echo ""

# Export aus OpenRefine
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Export aus OpenRefine"
echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
echo ""
echo "Startzeitpunkt: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
echo ""
$openrefine_client -P ${port} --export --output="output/${source}_${date}.tsv" "${source}_${date}"
echo ""
ps -o start,etime,%mem,%cpu,rss -p ${pid} --sort=start
memoryload+=($(ps --no-headers -o rss -p ${pid}))
echo ""

# OpenRefine Server beenden
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="OpenRefine Server beenden"
echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
echo ""
echo "Startzeitpunkt: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
echo ""
kill $pid
wait
echo ""

# Daten in Solr indexieren
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Daten in Solr indexieren"
echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
echo ""
echo "Startzeitpunkt: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
echo ""
curl --silent "http://localhost:8983/solr/hos/update?commit=true&optimize=true" -H "Content-Type: text/xml" --data-binary "<delete><query>source:${source}</query></delete>" 1>/dev/null
curl "${solr_url}update/csv?commit=true&separator=%09&split=true&f.subject.separator=%E2%90%9F&f.subject.separator=%E2%90%9F&f.identifier.separator=%E2%90%9F&f.identifierType.separator=%E2%90%9F&f.title.separator=%E2%90%9F&f.creatorName.separator=%E2%90%9F&f.origin.separator=%E2%90%9F" --data-binary @- -H 'Content-type:text/plain; charset=utf-8' < output/${source}_${date}.tsv 1>/dev/null
echo ""

# Daten in OpenRefine Demo einspielen
# ...

# Statistik
echo "=== Statistik ==="
echo ""
checkpoints=${#checkpointdate[@]}
checkpointdate[$(($checkpoints + 1))]=$(date +%s)
checkpointname[$(($checkpoints + 1))]="Ende"
echo "Beginn und Laufzeiten der einzelnen Schritte:"
checkpoints=${#checkpointdate[@]}
checkpointdate[$(($checkpoints + 1))]=$(date +%s)
for i in $(seq 1 $checkpoints); do
    diffsec="$((${checkpointdate[$((i + 1))]} - ${checkpointdate[$i]}))"
    printf "%35s $(date --date=@${checkpointdate[$i]}) ($(date -d@${diffsec} -u +%H:%M:%S))\n" "${checkpointname[$i]}"
done
echo ""
diffsec="$((checkpointdate[$checkpoints] - checkpointdate[1]))"
echo "Gesamtlaufzeit: $(date -d@${diffsec} -u +%H:%M:%S) (hh:mm:ss)"
max=${memoryload[0]}
for n in "${memoryload[@]}" ; do
    ((n > max)) && max=$n
done
echo "Max. Arbeitsspeicher OpenRefine: $((max / 1024)) MB"

# Alle Prozesse beenden
pkill -P $$
wait
exit 0
