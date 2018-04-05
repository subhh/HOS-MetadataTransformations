# SOLR-scheme

## notes
* a tsv-file (exported from Openrefine) ist used as a source
* the tsv uses the utf8 unit separator symbol U+241F to separate multivalued fields. SOLR splits the input into multivalued fields during indexing
* some multivalued fields describe others. E.g. otherTitle / otherTitleLang. Since SOLR retains the order of multivalued fields, otherTitleLang[3] describes otherTitle[3] etc. In  the tsv source, empty fields are filled with the field separator utf8 symbol


## Tabular overview of the scheme

Please consider that this is work in progress.

The column "DataCite Field" describes the corresponding DataCite Metadata Scheme 4.1 fields for metadata conversion.

| Field          | Type           | Multivalued  | DataCite Field | Description |
| -------------------- |:-------------:|:-----:|:--------------------|:----------------------------------------|
| abstract | text_general      | - [ ] | description with type abstract | |
| alternativeTitle | text_general      | [x] | | |
| alternativeTitleLang | text_general      | [x] | | |
| collection | string      | [x] | - |  describes the source of the metadata |
| creatorName | text_general      | [x] | | |
| date | string      | [x] | | |
| dateType | string      | [x] | | |
| format | string      | [ ] | | |
| geoLocationPoint | string      | [ ] | geoLocationPoint with longitude/latitude subfields | e.g. 53.590312,9.978455 |
| id | string      | [ ] | - | copy of identifier (done by SOLR) |
| identifier | text_general      | [ ] | identifier | |
| identifierType | text_general      | [x] | identifierType | |
| institute | text_general      | [x] | | |
| language | text_general      | [x] | language | |
| methods | text_general      | [ ] | description with type methods | |
| otherTitle | text_general      | [x] | | |
| otherTitleLang | text_general      | [x] | | |
| publicationYear | text_general      | [x] | | |
| publisher | text_general      | [x] | | |
| resourceType | text_general      | [x] | | |
| resourceTypeGeneral | text_general      | [x] | | |
| rights | text_general      | [ ] | | single valued despite DataCite Scheme |
| rightsURI | text_general      | [ ] | | single valued despite DataCite Scheme |
| seriesInformation | text_general      | [x] | description with type seriesInformation | |
| subject | text_general      | [x] | | |
| subject_acm | text_general      | [x] | | ACM classifiation |
| subject_bk | text_general      | [x] | | Basisklassification (a german classification )|
| subject_ddc | text_general      | [x] | | |
| subtitle | text_general      | [x] | | |
| subtitleLang | text_general      | [x] | | |
| tableOfContents | text_general      | [x] | | |
| technicalInfo | text_general      | [x] | description with type technicalInfo | |
| title | text_general      | [x] | | |
| titleLang | text_general      | [x] | | |
| translatedTitle | text_general      | [x] | | |
| translatedTitleLang | text_general      | [x] | | |
| university | text_general      | [x] | - | |
| url | string      | [x] | | |

