# SOLR schema

Please consider that this is work in progress.

## Notes

* tsv-files (exported from OpenRefine) are used as sources for indexing
* the tsv files contain a special character (utf8 unit separator symbol `U+241F`) to separate multivalued fields. SOLR splits the input into multivalued fields during indexing
* some multivalued fields describe others. E.g. `otherTitle` / `otherTitleLang`. Since SOLR retains the order of multivalued fields, `otherTitleLang[3]` describes `otherTitle[3]` etc. In the tsv source, empty fields are filled with the record separator utf8 symbol `U+241E`.
* all fields are stored and indexed per default (except `source`)

## Tabular overview

The column "DataCite Field" describes the corresponding DataCite Metadata Scheme 4.1 fields for metadata conversion. If no field is specified, the field name corresponds to the field name of the DataCite field.

[schema.csv](schema.csv)
