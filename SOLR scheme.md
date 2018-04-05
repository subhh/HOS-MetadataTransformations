# SOLR-scheme

## notes
* a tsv-file (exported from Openrefine) ist used as a source
* the tsv uses the utf8 unit separator symbol U+241F to separate multivalued fields. SOLR splits the input into multivalued fields during indexing
* some multivalued fields describe others. E.g. otherTitle / otherTitleLang. Since SOLR retains the order of multivalued fields, otherTitleLang[3] describes otherTitle[3] etc. In  the tsv source, empty fields are filled with the field separator utf8 symbol
* per default, all fields are stored and indexed


## Tabular overview of the scheme

Please consider that this is work in progress.

The column "DataCite Field" describes the corresponding DataCite Metadata Scheme 4.1 fields for metadata conversion. If no field is specified, the field name corresponds to the field name of the DataCite field.

| Field          | Type           | Multivalued  | DataCite Field | Description |
| -------------------- |:-------------:|:-----:|:--------------------|:----------------------------------------|
| abstract | text_general      | | description with descriptionType abstract | |
| alternateIdentifier | string | x | | |
| alternateIdentifierType | string | x | | |
| alternativeTitle | text_general      | x | | |
| alternativeTitleLang | string | x | | |
| collection | string | x | - |  describes the source of the metadata |
| creatorName | text_general | x | | |
| date | string | x | | |
| dateType | string | x | | |
| format | string | | | |
| geoLocationPoint | string      |  | geoLocationPoint with longitude/latitude subfields | e.g. 53.590312,9.978455 |
| id | string |  | - | copy of identifier (done by SOLR) |
| identifier | string |  |  | |
| identifierType | string |  |  | |
| institute | string | x | | |
| language | string |  |  | |
| methods | text_general |  | description with descriptionType methods | |
| otherDescription | text_general | x | description with descriptionType "Other"| |
| otherTitle | text_general | x | | |
| otherTitleLang | string | x | | |
| publicationYear | string |  | | |
| publisher | text_general |  | | |
| resourceType | string |  | | |
| resourceTypeGeneral | string | | | |
| rights | text_general | | | single valued despite DataCite Scheme |
| rightsURI | string | | | single valued despite DataCite Scheme |
| seriesInformation | text_general | | description with type seriesInformation | |
| subject | text_general | x | | |
| subject_acm | string | x | | ACM classifiation |
| subject_bk | string | x | | Basisklassification (a german classification )|
| subject_ddc | string | x | | |
| subtitle | text_general | x | | |
| subtitleLang | string | x | | |
| tableOfContents | text_general | | description with type tableOfContents | |
| technicalInfo | text_general | x | description with type technicalInfo | |
| title | text_general | | | |
| titleLang | string | | | |
| translatedTitle | text_general | x | | |
| translatedTitleLang | string | x | | |
| university | text_general | | - | |
| url | string | x | | |
