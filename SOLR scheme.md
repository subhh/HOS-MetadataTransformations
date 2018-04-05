# SOLR-scheme

## notes
* a tsv-file (exported from Openrefine) ist used as a source
* the tsv uses the utf8 unit separator symbol U+241F to separate multivalued fields. SOLR splits the input into multivalued fields during indexing
* some multivalued fields describe others. E.g. otherTitle / otherTitleLang. Since SOLR retains the order of multivalued fields, otherTitleLang[3] describes otherTitle[3] etc. In  the tsv source, empty fields are filled with the field separator utf8 symbol


## Tabular overview of the scheme

Please consider that this is work in progress.

The column "DataCite Field" describes the corresponding DataCite Metadata Scheme 4.1 fields for metadata conversion.

| Feld          | Typ           | Multivalued  | DataCite Field | Beschreibung |
| -------------------- |:-------------:|:-----:|:--------------------|:----------------------------------------|
| abstract | text_general      | [ ] | | |
| alternativeTitle | text_general      | [x] | | |
| alternativeTitleLang | text_general      | [x] | | |
| collection | string      | [x] | | |
| creatorName | text_general      | [x] | | |
| date | string      | [x] | | |
| dateType | string      | [x] | | |
| format | string      | [ ] | | |
| geoLocationPoint | string      | [ ] | | |
| id | string      | [ ] | copy of identifier (done by SOLR) | |
| identifier | text_general      | [ ] | | |
| identifierType | text_general      | [x] | | |
| institute | text_general      | [x] | | |
| language | text_general      | [x] | | |
|  | text_general      | [x] | | |
