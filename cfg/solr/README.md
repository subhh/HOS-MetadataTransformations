# SOLR-scheme

## notes
* tsv-files (exported from OpenRefine) are used as sources for indexing
* the tsv files contain a special character (utf8 unit separator symbol U+241F) to separate multivalued fields. SOLR splits the input into multivalued fields during indexing
* some multivalued fields describe others. E.g. otherTitle / otherTitleLang. Since SOLR retains the order of multivalued fields, otherTitleLang[3] describes otherTitle[3] etc. In the tsv source, empty fields are filled with the field separator utf8 symbol
* all fields are stored and indexed per default

## Tabular overview of the scheme

Please consider that this is work in progress.

The column "DataCite Field" describes the corresponding DataCite Metadata Scheme 4.1 fields for metadata conversion. If no field is specified, the field name corresponds to the field name of the DataCite field.

| Field | Type | Indexed | Multivalued | Sorting | DataCite Field | Description |
| ------|------|---------|-------------|---------|----------------|-------------|
| abstract | text_general | x | x | 08.01 | description with descriptionType abstract | |
| alternateIdentifier | string | x | x | 11.03 | | |
| alternateIdentifierType | string | x | x | 11.04 | | |
| alternativeTitle | text_general | x | x | 02.07 | | |
| alternativeTitleLang | string | x | x | | 02.08 | |
| collection | string | x | - | 15.01 | - | describes the source of the metadata |
| contributorName | string | x | x | 03.01 | | |
| contributorType | string | x | x | 03.02 | | |
| creatorName | string | x | x | 01.01 | | |
| date | string | x | x | 06.02 | | |
| dateType | string | x | x | 06.03 | | |
| format | string | x | - | 12.01 | | |
| geoLocationPoint | string | x | - | 09.04 | geoLocationPoint with longitude/latitude subfields | e.g. 53.590312,9.978455 |
| id | string | x | - | 00.01 | - | copy of identifier (without slashes) |
| identifier | string | x | - | 11.01 | | |
| identifierType | string | x | - | 11.02 | | |
| institute | string | x | x | 09.03 | | |
| language | string | x | - | 04.01 | | |
| methods | text_general | x | - | 08.02 | description with descriptionType methods | |
| otherDescription | text_general | x | x | 08.03 | description with descriptionType "Other"| |
| otherTitle | text_general | x | x | 02.09 | | |
| otherTitleLang | string | x | x | 02.10 | | |
| publicationYear | string | x | - | 06.01 | | |
| publisher | string | x | - | 09.01 | | |
| resourceType | string | x | - | 05.01 | | |
| resourceTypeGeneral | string | x | - | 05.02 | | |
| rights | text_general | x | - | 13.01 | | single valued despite DataCite Scheme |
| rightsURI | string | x | - | 13.02 | | single valued despite DataCite Scheme |
| seriesInformation | text_general | x | x | 10.01 | description with type "SeriesInformation" | |
| source | string | - | - | 15.02 | - | code name of the technical source of the metadata |
| subject | string | x | x | 07.01 | | |
| subject_acm | string | x | x | 07.04 | subject with subjectScheme "ACM" | ACM classifiation |
| subject_bk | string | x | x | 07.03 | subject with subjectScheme "BK" and subjectURI pointing to the classification | Basisklassification (a german classification )|
| subject_ddc | string | x | x | 07.02 | subject with subjectScheme "DDC" and subjectURI pointing to the classification | Dewey |
| subtitle | text_general | x | x | 02.03 | | |
| subtitleLang | string | x | x | 02.04 | | |
| tableOfContents | text_general | x | - | 08.04 | description with type "TableOfContents" | |
| technicalInfo | text_general | x | x | 08.05 | description with type "TechnicalInfo" | |
| title | text_general | x | - | 02.01 | | |
| titleLang | string | x | - | 02.02 | | |
| translatedTitle | text_general | x | x | 02.05 | | |
| translatedTitleLang | string | x | x | 02.06 | | |
| university | string | x | - | 09.02 | - | |
| url | string | x | x | 14.01 | | |
