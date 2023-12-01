xquery version "3.0";

(:
: Module Name: Syriaca.org Data Pipeline CSV Transformations
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This module transforms a CSV file into one or more partial
:                  XML records of entities for use on the Srophe App. These
:                  "skeleton" records are then merged with entity templates
:                  to create TEI-compliant Srophe records.
:)

(:~ 
: This module provides the functions that transform rows of csv data
: into XML snippets that can be merged with entity templates to create
: TEI-compliant Srophe records.
: This module makes use of BaseX's CSV parsing module. It is otherwise
: implementation independent.
: The CSV headers should be formatted as described in the documentation
: @see !!!MISSING LINK TO DOCUMENTATION OF CSV FORMAT
:
: @author William L. Potter
: @version 1.0
:)
module namespace csv2srophe="http://wlpotter.github.io/ns/csv2srophe";


import module namespace functx="http://www.functx.com";
import module namespace config="http://wlpotter.github.io/ns/config" at "config.xqm";
import module namespace csv2places="http://wlpotter.github.io/ns/csv2places" at "csv2places.xqm";
import module namespace csv2persons="http://wlpotter.github.io/ns/csv2persons" at "csv2persons.xqm";
import module namespace csv2subjects="http://wlpotter.github.io/ns/csv2subjects" at "csv2subjects.xqm";

declare namespace srophe="https://srophe.app";
(: note that it makes use of Basex's CSV module. Note also that you should declare output options. :)


(: ----------------------------------------- :)
(: functions for processing a full CSV document :)
(: ----------------------------------------- :)

declare function csv2srophe:process-csv($csvFilePath as xs:string,
                                        $separator as xs:string)
as document-node()*
{
  let $data := csv2srophe:get-data($csvFilePath, $separator)
  let $headerMap := csv2srophe:create-header-map($csvFilePath, $separator)
  
  let $headwordIndex := csv2srophe:create-headword-index($headerMap)
  let $namesIndex := csv2srophe:create-names-index($headerMap)
  let $abstractIndex := csv2srophe:create-abstract-index($headerMap)
  let $anonymousDescIndex := csv2srophe:create-anonymousDesc-index($headerMap)
  let $sexIndex := csv2srophe:create-sex-index($headerMap)
  let $genderIndex := csv2srophe:create-gender-index($headerMap)
  let $datesIndex := csv2srophe:create-dates-index($headerMap)
  let $relationsIndex := csv2srophe:create-relations-index($headerMap)
  
  let $indices := ($headwordIndex, $namesIndex, $abstractIndex, $anonymousDescIndex, $sexIndex, $genderIndex, $datesIndex, $relationsIndex)
  let $sourcesIndex := csv2srophe:create-sources-index($indices)
  let $indices := ($indices, $sourcesIndex)
  
  for $row in $data
    return switch($config:collection-type) (: perhaps switch collection type to be a parameter? Then call with the config variable (this might help with testing purposes?):)
      case "places" return csv2places:create-place-from-row($row, $headerMap, $indices)
      case "persons" return csv2persons:create-person-from-row($row, $headerMap, $indices)
      case "subjects" return csv2subjects:create-subject-from-row($row, $headerMap, $indices)
      default return ""
};
                                        
(:~ 
: loads a CSV file and returns an xml document
: The returned element is a sequence of XML nodes with the following pattern:
: <record>
:   <firstColumnHeader>cellValue</firstColumnHeader>
:   <secondColumnHeader>cellValue</secondColumnHeader>
: </record>,
: <record>
:   <firstColumnHeader>cellValue</firstColumnHeader>
:   <secondColumnHeader>cellValue</secondColumnHeader>
: </record>
:
:)
declare function csv2srophe:load-csv($url as xs:string,
                                     $delimeter as xs:string,
                                     $header as xs:boolean)
as element()*
{
  let $recordSeq :=  if (starts-with($url, "http")) then
                    csv2srophe:load-csv-remote($url, $delimeter, $header)
                  else
                    csv2srophe:load-csv-local($url, $delimeter, $header)
  return $recordSeq
}; (: NOTE: potential refactor: have -remote and -local return xmlDocs and return the sequence only from the load-csv function :)

(:~ 
: @see https://github.com/HeardLibrary/digital-scholarship/tree/master/code/file
:)
declare function csv2srophe:load-csv-remote($uri as xs:string,
                                            $delimiter as xs:string,
                                            $header as xs:boolean)
as element()*
{
  let $request := <http:request method='get' href='{$uri}'/>
  let $csvDoc := http:send-request($request)[2] (: ignore initial response element :)
  let $xmlDoc := csv:parse($csvDoc,
                            map { 'header' : $header,'separator' : $delimiter })

  return $xmlDoc/csv/record
};
(:~ 
: Returns a sequence of XML elements representing CSV input data stored at $url
: Returned data looks like:
: <record>
:   <firstColumnHeader>cellValue</firstColumnHeader>
:   <secondColumnHeader>cellValue</secondColumnHeader>
: </record>,
: <record>
:   <firstColumnHeader>cellValue</firstColumnHeader>
:   <secondColumnHeader>cellValue</secondColumnHeader>
: </record>
: @param $url the absolute path to a csv file on the local machine
: :)
declare function csv2srophe:load-csv-local($url as xs:string,
                                           $delimiter as xs:string,
                                            $header as xs:boolean)
as element()*
{
  (: For Windows paths, change "\" to "/" :)
  let $url := fn:replace($url, "\\", "/")
  let $doc := file:read-text($url)
  let $xmlDoc := csv:parse($doc,
                         map { 'header' : $header,'separator' : $delimiter })
  return $xmlDoc/csv/record
};

(:~ 
: Given the url of a csv file, returns a sequence of strings corresponding
: to the column headers of the CSV file.
: 
:)
declare function csv2srophe:get-csv-column-headers($url as xs:string,
                                                   $delimiter as xs:string)
as xs:string*
{
  let $xmlDoc := csv2srophe:load-csv($url, $delimiter, false ())
  let $headers := $xmlDoc[1]
  return $headers//text()
};

declare function csv2srophe:get-data($url as xs:string,
                                     $delimiter as xs:string)
as element()*
{
  let $data :=  csv2srophe:load-csv($url, $delimiter, true ())
  return $data
};

(:~
: Returns a sequence that looks like the following. It relates the strings
: used in the CSV column headers to the XML tag names in the data
: <map>
:   <string>New place/add data</string>
:   <name>New_place_add_data</name>
: </map>
: <map>
:   <string>uri</string>
:   <name>uri</name>
: </map>
: <map>
:   <string>Possible URI</string>
:   <name>Possible_URI</name>
: </map>
: ...
:
: @author Steve Baskauf
: @author William L. Potter
:)
declare function csv2srophe:create-header-map($url as xs:string,
                                              $delimiter as xs:string)
as element()*
{
  let $headers := csv2srophe:get-csv-column-headers($url, $delimiter)
  let $firstDataRow := csv2srophe:get-data($url, $delimiter)[1]
  let $headerElementNames := $firstDataRow/*/name()
  let $headerMap := 
    for $header at $pos in $headers
    return (<map>
             {
              <string>{$header}</string>,
              <name>{$headerElementNames[$pos]}</name>
             }
            </map>)
 return $headerMap
};

(:~ 
: Returns a sequence of elements containing the column names of 
: data associated with a specific data type. Used to create specific
: header indices, such as the names index and headwords index.
: 
: @param $columnName controls which columns are returned
: @headerMap is the sequence of elements created by 
: csv2srophe:create-header-map
: 
: @author William L. Potter
: @version 1.0
:)
declare function csv2srophe:create-column-index($columnName as xs:string, 
                                                $headerMap as element()+,
                                                $rightOfDotLabel as xs:string)
as element()*
{
  for $column in $headerMap
  let $columnString := $column/string/string()
  let $leftOfDot := tokenize($columnString,'\.')[1]
  let $rightOfDot := functx:trim(tokenize($columnString,'\.')[2])
  
  
  return if (substring(tokenize($columnString,'\.')[1],1,string-length($columnName)) = $columnName) then
  element {$columnName} 
  {
    if ($rightOfDotLabel != "") then element {$rightOfDotLabel} {$rightOfDot} else (),
    element {"textNodeColumnElementName"} {$column/name/string()},
    csv2srophe:associate-source-data-columns($leftOfDot, $headerMap, $rightOfDot)
   }
  else () 
};

declare function csv2srophe:associate-source-data-columns($parentColumnName as xs:string,
                                                          $headerMap as element()+,
                                                          $parentNameExtension as xs:string?)
as element()*
{
  (: loop through each column in the header map and find the uri, cited range, and citation unit columns associated with the $parentColumnName :)
  for $column in $headerMap
  let $sourceUriElement := 
    (: the or-operator allows for cases, like abstract.en, where the left-of-dot is not sufficient to identify the associated data column :)
    if (lower-case($column/string/string()) = 'sourceuri.'||$parentColumnName or lower-case($column/string/string()) = 'sourceuri.'||$parentColumnName||"."||$parentNameExtension)
           then <sourceUriElementName>{$column/name/string()}</sourceUriElementName>
         else ()
  let $citedRangeUriElement := 
    if ($column/string/string() = 'citedRange.'||$parentColumnName or $column/string/string() = 'citedRange.'||$parentColumnName||"."||$parentNameExtension)
      then <citedRangeElementName>{$column/name/string()}</citedRangeElementName>
    else ()
  let $citationUnitElement := 
    if ($column/string/string() = 'citationUnit.'||$parentColumnName or $column/string/string() = 'citationUnit.'||$parentColumnName||"."||$parentNameExtension)
      then <citationUnitElementName>{$column/name/string()}</citationUnitElementName>
    else ()
  return ($sourceUriElement, $citedRangeUriElement, $citationUnitElement)
};

(:~ 
: Returns a sequence that looks like this:
: 
: <name>
:   <langCode>en</langCode>
:   <textNodeColumnElementName>name2.en</textNodeColumnElementName>
:   <sourceUriElementName>sourceURI.name2</sourceUriElementName>
:   <citedRangeElementName>citedRange.name2</citedRangeElementName>
:   <citationUnitElementName>citationUnit.name2</citationUnitElementName>
: </name>
: <name>
:   <langCode>syr</langCode>
:   <textNodeColumnElementName>name3.syr</textNodeColumnElementName>
:   <sourceUriElementName>sourceURI.name3</sourceUriElementName>
:   <citedRangeElementName>citedRange.name3</citedRangeElementName>
:   <citationUnitElementName>citationUnit.name3</citationUnitElementName>
: </name>
: 
: The names index stores a sequence of columns where entity names are kept.
: It is used, for each row of data, to create a list of entity name elements,
: depending on the entity type (e.g. <placeName/>)
: 
: @author Steve Baskauf
: @author William L. Potter
:)
declare function csv2srophe:create-names-index($headerMap as element()+)
as element()*
{
  let $namesIndex := csv2srophe:create-column-index("name", $headerMap, "langCode")
  return $namesIndex
};

(:~
: Returns a sequence looks like this:
:
: <headword>
:   <langCode>en</langCode>
:   <textNodeColumnElementName>headword.en</textNodeColumnElementName>
: </headword>
: <headword>
:   <langCode>syr</langCode>
:   <textNodeColumnElementName>headword.syr</textNodeColumnElementName>
: </headword>
: 
: The headword index stores a sequence of columns where entity headwords
: are kept. It is used, for each row of data, to create a list of entity
: headwords which are tagged with @srophe:tags="#syriaca-headword". These
: headwords are also used to construct the tei:titleStmt/tei:title[@level="a"].
: 
: @author Steve Baskauf
: @author William L. Potter
:)
declare function csv2srophe:create-headword-index($headerMap as element()+)
as element()*
{
  let $headwordsIndex := csv2srophe:create-column-index("headword", $headerMap, "langCode")
  return $headwordsIndex
};

(:~
: returns a sequence that looks like this:
:
: <abstract>
:   <langCode>en</langCode>
:   <textNodeColumnElementName>abstract.en</textNodeColumnElementName>
:   <sourceUriElementName>sourceURI.abstract.en</sourceUriElementName>
:   <pagesElementName>pages.abstract.en</pagesElementName>
: </abstract>
:
: The abstract index stores a sequence of columns where entity abstracts
: are kept. It is used, for each row of data, to create a list of entity
: abstracts which contain a short description of the entity.
: Although at present Syriaca entities only contain English language abstracts,
: abstracts in multiple languages are handled by this module.
: 
: @author Steve Baskauf
: @author William L. Potter
:
:)

declare function csv2srophe:create-abstract-index($headerMap as element()+)
as element()*
{
  let $abstractIndex := csv2srophe:create-column-index("abstract", $headerMap, "langCode")
  return $abstractIndex
};

declare function csv2srophe:create-anonymousDesc-index($headerMap as element()+)
as element()*
{
  let $anonymousDescIndex := csv2srophe:create-column-index("anonymousDesc", $headerMap, "langCode")
  return $anonymousDescIndex
};

(:~
: returns a sequence that looks like this:
:
: <sex>
:   <langCode>en</langCode>
:   <textNodeColumnElementName>sex1.en</textNodeColumnElementName>
:   <sourceUriElementName>sourceURI.sex1</sourceUriElementName>
:   <citedRangeElementName>citedRange.sex1</citedRangeElementName>
:   <citationUnitElementName>citationUnit.sex1</citationUnitElementName>
: </sex>
:
: The sex index stores a sequence of columns where entity sex information
: is kept. It is solely used for persons entities. It is used, for each row 
: of data, to create the element(s) encoding the sex/gender information for 
: the entity.
: 
: @author William L. Potter
:
:)

declare function csv2srophe:create-sex-index($headerMap as element()+)
as element()*
{
  let $sexIndex := csv2srophe:create-column-index("sex", $headerMap, "")
  return $sexIndex
};

(:~
: returns a sequence that looks like this:
:
: <gender>
:   <langCode>en</langCode>
:   <textNodeColumnElementName>gender1.en</textNodeColumnElementName>
:   <sourceUriElementName>sourceURI.gender1</sourceUriElementName>
:   <citedRangeElementName>citedRange.gender1</citedRangeElementName>
:   <citationUnitElementName>citationUnit.gender1</citationUnitElementName>
: </gender>
:
: The gender index stores a sequence of columns where entity gender information
: is kept. It is solely used for persons entities. It is used, for each row 
: of data, to create the element(s) encoding the gender information for 
: the entity.
: 
: @author William L. Potter
:
:)

declare function csv2srophe:create-gender-index($headerMap as element()+)
as element()*
{
  let $genderIndex := csv2srophe:create-column-index("gender", $headerMap, "")
  return $genderIndex
};
(:~ 
: returns a sequence looks like:
: 
: <relation>
:  <type>possiblyIdentical</type>
:  <textNodeColumnElementName>relation1.possiblyIdentical</textNodeColumnElementName>
:  <sourceUriElementName>sourceUri.relation1</sourceUriElementName>
:  ... (etc. with citedRange and citationUnit)
: </relation> 
: ...
:
: These columns store information for to tei:relation elements.
:)
declare function csv2srophe:create-relations-index($headerMap as element()+)
as element()*
{
  let $relationsIndex := csv2srophe:create-column-index("relation", $headerMap, "type")
  return $relationsIndex
};

declare function csv2srophe:create-dates-index($headerMap as element()+)
as element()*
{
  let $datesIndex := csv2srophe:create-column-index("date", $headerMap, "")
  
  (: collate additional date information, such as associated attribute columns :)
  for $date in $datesIndex
  let $rightOfDot := functx:trim($date/*:textNodeColumnElementName/text())
  let $dateAttrColumns :=  
    for $column in $headerMap
    let $columnName := functx:trim($column/*:name/text())
    where substring-after($columnName, ".") = $rightOfDot (: screen for associated date columns :)
    let $leftOfDot := substring-before($columnName, ".")
    return element {$leftOfDot || "ElementName"} {$columnName}
  let $dateChildren := functx:distinct-deep(($date/*, $dateAttrColumns))
  return <date>{$dateChildren}</date>
};

(:~ 
: returns a sequence looks like this:
:
: <source>
:  <sourceUriElementName>sourceURI.name2</sourceUriElementName>
:  <citedRangeElementName>citedRange.name2</citedRangeElementName>
:  <citationUnitElementName>citationUnit.name2</citationUnitElementName>
: </source>
: <source>
:  <sourceUriElementName>sourceURI.abstract.en</sourceUriElementName>
:  <citedRangeElementName>citedRange.abstract.en</citedRangeElementName>
:  <citationUnitElementName>citationUnit.abstract.en</citationUnitElementName>
: </source>
: ...
:
: @author William L. Potter
: @version 1.0
: 
:)
declare function csv2srophe:create-sources-index($indices as element()+)
as element()*
{
  (: loop through the passed indices and pull out the sourceUri, citedRange, and citationUnit column data:)
  for $item in $indices
  let $sourceData := $item/*[name() = "sourceUriElementName" or name() = "citedRangeElementName" or name() = "citationUnitElementName"]
  return <source>{$sourceData}</source>
  
};

(: ----------------------------------------- :)
(: functions for processing individual data rows into skeleton tei records :)
(: ----------------------------------------- :)

(: Note: the majority of elements are constructed by entity-specific modules,
:  e.g. csv2places.xqm. In this module are functions that create elements
:  shared across the majority of entity types.
:)

(:~ 
: Returns a sequence of elements with the row-specific data pulled from the 
: column names specified in the $index parameter.
:
: @param $index an index of column names that group associated information such
: as name, name language, and source information for the name
: @param $row is a row of data from a CSV file created with the csv2srophe:get-csv-data function
: 
: This function is used as an intermediary to create entity-specific elements
: such as persName or placeName, etc.
:
: @author William L. Potter
: @version 1.0
:  :)
declare function csv2srophe:populate-index-from-row($index as element()*,
                                                    $row as element())
as element()*
{
  
  for $item in $index
  let $data := 
    for $column in $item/*
    let $matchedDataField := $row/*[name() = $column/text()]
    
    (: remove the "ElementName" or "ColumnElementName" portion of the element name:)
    let $nodeName := functx:substring-before-if-contains($column/name(), "ElementName")
    let $nodeName := functx:substring-before-if-contains($nodeName, "Column")
    
    return if ($column/name() = "langCode" or $column/name() = "type") then element {$nodeName} {$column/text()} (: the langCode data is stored in the index, not in the row :)
           else element {$nodeName} {$matchedDataField/text()} (: for any other data, use the text node of the row data field that matches the column name :)
  return element {node-name($item)} {$data}
};
(:~
: Returns a subset of the $index that only includes columns that are not empty
: in the given $row.
: NEEDS TESTS
:)

declare function csv2srophe:get-non-empty-index-from-row($row as element(),
                                                         $index as element()*)
as element()*
{
    let $nonEmptyIndex := for $val in $index
    let $element := functx:trim($row/*[name() = $val/textNodeColumnElementName/text()]/text())
    return if ($element != '')
            then $val
            else ()
    return $nonEmptyIndex
};

(:~ 
: Returns the URI 
: @param $row a single row of data, as produced by the get-data function.
: @see get-data()
: @param $entityUriBase is the entity-specific portion of the record's URI, e.g.
: 'http://syriaca.org/place/'. This is stored in the config.xml
: @see https://raw.githubusercontent.com/wlpotter/csv-to-srophe/main/parameters/config.xml?token=AKQNYWRGCSE5YEEJDKDHJJTBMRIIO;/meta/config/collections/collection/@record-URI-base
NOTE: the token can be removed once the module is public. :)
declare function csv2srophe:get-uri-from-row($row as element(), 
                                             $entityUriBase as xs:string*)
as xs:string
{
  let $uri := functx:trim($row/uri/text())
  return $entityUriBase || $uri
};
                             
(:~ 
: Returns a sequence that looks like this:
: <source>
:   <uri></uri>
:   <citedRange></citedRange>
:   <citationUnit></citationUnit>
: </source>
: <source>
:   <uri></uri>
:   <citedRange></citedRange>
:   <citationUnit></citationUnit>
: </source>
:
: Creates a sequence of all the unique sources based on source URI and cited range.
: At present expects citations as pages, though this will be fixed.
: The source sequence is used to create the bibl elements and to properly create
: @ref attributes for various entity data, such as entity names.
:
: @author Steve Baskauf
: @author William L. Potter
:
:)

declare function csv2srophe:create-sources-index-for-row($sourcesIndex as element()+,
                                                         $row as element())
as element()*
{
  let $sources := csv2srophe:populate-index-from-row($sourcesIndex, $row)
  
  (: remove sources that don't have a URI :)
  let $sources := $sources[sourceUri/text() != ""]
  
  (: normalize citation units for pages to be "p" and ensure all bibls have a citationUnit (which is "p" by default) :)
  let $sources := 
    for $source in $sources
    let $normalizedPageCitationUnit := <citationUnit>p</citationUnit>
    return 
    (: if the source lacks a citation unit (either no element or an empty element) or it has "pp" instead of "p", use the normalized page unit of "p" :)
      if(not($source/citationUnit/text()) or functx:trim($source/citationUnit/text()) = "pp") then <source>{$source/*[not(name() = "citationUnit")], $normalizedPageCitationUnit}</source>
      else $source
    
  (: remove redundant sources :)
  return functx:distinct-deep($sources)
};

(:~ 
: Returns a sequence of tei:bibl elements of the following form:
: <bibl xmlns="" xml:id="bib78-1">
:   <ptr target="http://syriaca.org/bibl/1"
:   <citedRange unit="p">8</citedRange>
: </bibl>
: Each bibl can have multiple citedRange elements depending on the number of units.
: In the csv, these citedRanges and citationUnits should be separated by the "#" character
:)
declare function csv2srophe:create-bibl-sequence($row as element(),
                                                         $sourcesIndexForRow as element()+)
as element()*
{
  
  let $uriLocalName := csv2srophe:get-uri-from-row($row, "")
  for $source at $number in $sourcesIndexForRow
    let $sourceUri := $source/sourceUri/text()
    where $sourceUri != ""
    (: add the bibl uri-base if not already there :)
    let $sourceUri := if(starts-with($sourceUri, "http")
                         and $sourceUri != "")
                      then $sourceUri 
                      else $config:default-bibl-uri-base || $sourceUri
    let $sourceCitedRange := $source/*:citedRange/text()
    let $sourceCitationUnit := $source/*:citationUnit/text()
    let $citedRangeElement := if ($sourceCitedRange != "") then csv2srophe:create-citedRange-element($sourceCitedRange, $sourceCitationUnit) else ()
    return
    <bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="bib{$uriLocalName}-{$number}">
        <ptr target="{$sourceUri}"/>
        {$citedRangeElement}
    </bibl>
}; 

(:~ 
: returns a sequence of tei:citedRange elements based on the parameters. If the
: cited range and citation unit are character-separated with the "#" character,
: it will return multiple tei:citedRange elements for each pair in the sequence.
:
: @author William L. Potter
: @version 1.0
:  
:  :)
declare function csv2srophe:create-citedRange-element($citedRange as xs:string, 
                                                      $citationUnit as xs:string)
as element()+
{
  (: tokenize the range and unit strings. Currently hard-coded separator, but perhaps make this a :)
  let $citedRangeSeq := tokenize($citedRange, "#")
  let $citationUnitSeq := tokenize($citationUnit, "#")
  
  for $range at $i in $citedRangeSeq
  return element {QName("http://www.tei-c.org/ns/1.0", "citedRange")} {attribute {"unit"} {$citationUnitSeq[$i]}, $range}
};

declare function csv2srophe:create-idno-sequence-for-row($row as element(), $uriBase as xs:string?)
as element()*
{
  let $selfUri := csv2srophe:get-uri-from-row($row, $uriBase)
  let $selfIdno := <idno xmlns="http://www.tei-c.org/ns/1.0" type="URI">
        {$selfUri}
      </idno>
  let $otherIdnos := 
    for $idno in $row/idno
    where functx:trim($idno/text()) != ''
    return
      <idno xmlns="http://www.tei-c.org/ns/1.0" type="URI">
        {functx:trim($idno/text())}
      </idno>
  return ($selfIdno, $otherIdnos)
};

(:~ 
: Returns a sequence of TEI elements for Srophe entities. Based on the $elementName,
: this function can return names, abstracts, etc.
: 
: @param $row is the data input row
: @param $columnIndex is the index of columns to match, e.g. headword, name, etc.
: @param $sourcesIndex is the index of sources for the row which is used to create
: the @source attributes for the element.
: @param $elementName controls what element is created by this script
:
: @author William L. Potter
: @version 1.0
:
:)
declare function csv2srophe:build-element-sequence($row as element(), 
                                                        $columnIndex as element()*, 
                                                        $sourcesIndexForRow as element()*, 
                                                        $elementName as xs:string,
                                                        $enumerationOffset as xs:integer)
as element()*
{
  let $uriLocalName := csv2srophe:get-uri-from-row($row, "")
  
  (: get the column information for this row's non-empty names :)
  let $nonEmptyColumnIndex := csv2srophe:get-non-empty-index-from-row($row, $columnIndex)
  let $rowData := csv2srophe:populate-index-from-row($nonEmptyColumnIndex, $row) (: replace index of column names with index of data :)
  return
    for $item at $number in $rowData     (: loop through each of the names in various languages :)
    let $text := functx:trim($item/textNode/text())
    let $itemSourceUri := functx:trim($item/sourceUri/text())
    let $itemSourceCitedRange := functx:trim($item/citedRange/text())
    let $itemSourceCitationUnit := functx:trim($item/citationUnit/text())
    
    (: get the @source attribute value by matching the uri, cited range, and citation unit values :)
    let $sourceAttr := csv2srophe:create-source-attribute-for-element($item, $sourcesIndexForRow, $uriLocalName)
    let $langAttr := functx:trim($item/langCode/text())
    return 
    switch($item/name())
    case "name" return csv2srophe:build-name-element($text, $elementName, $uriLocalName, $langAttr, $sourceAttr, false (), $number + $enumerationOffset)
    case "headword" return csv2srophe:build-name-element($text, $elementName, $uriLocalName, $langAttr, $sourceAttr, true (), $number + $enumerationOffset)
    case "abstract" return csv2srophe:build-abstract-element($text, $elementName,$uriLocalName, $langAttr, $sourceAttr, $number + $enumerationOffset)
    case "anonymousDesc" return csv2srophe:build-anonymousDesc-element($text, $elementName, $uriLocalName, $langAttr, $sourceAttr, false (), $number + $enumerationOffset)
    case "sex" return csv2srophe:build-sex-element($text, $sourceAttr)
    case "gender" return csv2srophe:build-gender-element($text, $sourceAttr)
    case "date" return csv2srophe:build-date-element($text, $sourceAttr, $item)
    case "relation" return csv2srophe:build-relation-element($item, $sourceAttr, $uriLocalName, "#") (: FIX: separator should not be hard-coded :)
    (: add other cases, e.g., "anonymous descs", etc. :)
    default return () (: maybe have an error? :)
};

(:~ 
: returns an xs:string of the form "bib\1-\2" where \1 is the uri local name, and
: \2 is the position in sequence of the corresponding bibl element.
: 
: @param $itemData is a node containing source information about a given element,
: such as a name. It follows the form:
: <name>
:  <langCode></langCode>
:  <textNode></textNode>
:  <sourceUri></sourceUri>
:  <citedRange></citedRange>
:  <citationUnit></citationUnit>
: </name>
: @param $sourcesIndexForRow contains a sequence of unique sources for a given
: data row. 
: @param $uriLocalName is the URI of the data row without the entity-uri base.
:
: @author William L. Potter
: @version 1.0
: :)
declare function csv2srophe:create-source-attribute-for-element($itemData as element(),
                                                                $sourcesIndexForRow as element()*,
                                                                $uriLocalName as xs:string)
as xs:string*
{
  for $src at $srcNumber in $sourcesIndexForRow  (: step through the source index :)
  (: normalize citation unit if it is a page-reference to be "p" :)
  let $itemCitationUnit := if(not($itemData/*:citationUnit/text()) or string($itemData/*:citationUnit/text()) = "pp") then "p" else string($itemData/*:citationUnit/text())
  
  where  $itemData/*:sourceUri/text() = $src/*:sourceUri/text() 
     and $itemData/*:citedRange/text() = $src/*:citedRange/text() 
     and $itemCitationUnit = string($src/*:citationUnit/text())  (: URI and page from columns must match with iterated item in the source index :)
  return if($itemData/*:sourceUri/text() != "") then "bib" || $uriLocalName||'-'||$srcNumber    (: create the last part of the source attribute :) else ()
};

declare function csv2srophe:build-name-element($textNode as xs:string,
                                               $elementName as xs:string,
                                               $entityUri as xs:string,
                                               $language as xs:string,
                                               $source as xs:string?,
                                               $isHeadword as xs:boolean,
                                               $namePositionInSequence as xs:integer)
as element()
{
  let $headwordAttr := if($isHeadword) then
    attribute {QName("https://srophe.app", "srophe:tags")} {"#syriaca-headword"}
    else ()
  let $id := if($elementName != "gloss") then (: glosses are 'alternate names' for taxonomy entities and don't have xml:ids. :)
                 if($elementName = "term") then (: taxonomy headwords are tei:term elements with the xml:id pattern of 'name-$entityUri-$language' :)
                   "name-" || $entityUri || "-" || $language (: in this case $entityUri should be the lower-case value of $textNode :)
                 else
                   "name" || $entityUri || "-" || $namePositionInSequence (: all other entities have the xml:id pattern of "name$entityUri-$namePositionInSequence":)
             else ()
  let $xmlId := if($id != "") then attribute {"xml:id"} {$id} else ()
  let $xmlLang := attribute {"xml:lang"} {$language}
  let $sourceAttr := if($source != "") then
                       attribute {"source"} {"#" || $source}
                     else
                       attribute {"resp"} {$config:default-resp-statement}
  let $textNode := if($elementName = "gloss") then element {QName("http://www.tei-c.org/ns/1.0", "term")} {$textNode} else $textNode (: nest a term in a gloss :)
  return
    element {QName("http://www.tei-c.org/ns/1.0", $elementName)} 
            {$xmlLang, $xmlId, $headwordAttr, $sourceAttr, $textNode}
  
  
};

(:~
: Returns an abstract element based on input options.
: Note: $elementName required as persons, places, etc. construct abstracts differently
: This is due to the way TEI allows and disallows certain element nesting. E.g.,
: tei:desc can appear in a tei:place but not a tei:person, so a tei:note[@type="abstract"]
: is used in the latter case.
:)
declare function csv2srophe:build-abstract-element($textNode as xs:string,
                                                   $elementName as xs:string,
                                                   $entityUri as xs:string,
                                                   $language as xs:string,
                                                   $source as xs:string?,
                                                   $abstractPositionInSequence as xs:integer)
as element()
{
  let $type := attribute {"type"} {"abstract"}
  let $xmlLang := attribute {"xml:lang"} {$language}
  let $sourceAttr := if($source != "") then
                        attribute {"source"} {"#" || $source}
                     else
                        attribute {"resp"} {$config:default-resp-statement}
  let $quote := if($source != "") then element {QName("http://www.tei-c.org/ns/1.0", "quote")} {$sourceAttr, $textNode} else $textNode
  return element {QName("http://www.tei-c.org/ns/1.0", $elementName)}
                  {$type, $xmlLang, if($source = "") then $sourceAttr else (), $quote}

};

(:~ 
: returns an anonymous description nested in an @param $elementName
:)
declare function csv2srophe:build-anonymousDesc-element($textNode as xs:string,
                                               $elementName as xs:string,
                                               $entityUri as xs:string,
                                               $language as xs:string,
                                               $source as xs:string?,
                                               $isHeadword as xs:boolean,
                                               $namePositionInSequence as xs:integer)
as element()
{
  (: create the anonymous description as if it were a non-headword entity name :)
  let $anonymousDesc := csv2srophe:build-name-element($textNode, $elementName, $entityUri, $language, $source, $isHeadword, $namePositionInSequence)
  let $anonymousDescAttr := attribute {"srophe:tags"} {"#anonymous-description"}
  return element {node-name($anonymousDesc)} {$anonymousDesc/@*, $anonymousDescAttr, $anonymousDesc/child::node()}
};
(:~ 
: returns a tei:sex element for use in persons entities.
 :)
declare function csv2srophe:build-sex-element($value as xs:string, $source as xs:string?)
as element()
{
  let $textNode := if($value = "M") then "male" else if($value = "F") then "female" else ()
  let $sourceAttr := if($source != "") then attribute {"source"} {"#" || $source}
    else attribute {"resp"} {$config:default-resp-statement}
  let $valueAttr := attribute {"value"} {$value}
  return element {QName("http://www.tei-c.org/ns/1.0", "sex")} {$sourceAttr, $valueAttr, $textNode}
};

(:~ 
: returns a tei:gender element for use in persons entities.
: @param $value should be a Syriaca keyword URI with a skos:broader of syriaca:gender
 :)
declare function csv2srophe:build-gender-element($value as xs:string, $source as xs:string?)
as element()
{
  (: $value should be a Syriaca keyword URI, otherwise return the full string :)
  let $textNode := if(contains($value, "/")) then functx:substring-after-last($value, "/") else $value
  let $sourceAttr := if($source != "") then attribute {"source"} {"#" || $source}
    else attribute {"resp"} {$config:default-resp-statement}
  let $anaAttr := attribute {"ana"} {$value}
  return element {QName("http://www.tei-c.org/ns/1.0", "gender")} {$sourceAttr, $anaAttr, $textNode}
};

(: possibly a csv2srophe function if you use it for existence dates, etc.? 
cases which this could handle

persons:
- floruit
- birth
- death
- ??

places:
- state[@type="existence"]
- state[@type="confession"] (though these can be undated, so possibly this will be separate?)
  - or a confession can optionally call this function to create it?
- event[@type="other"]
- event[@type="attestation"] should likely be handled like confession states as, while they can be dated, the primary purposes is to create the link between work and name
:)
declare function csv2srophe:build-date-element($textNode as xs:string, $source as xs:string?, $associatedData as element())
as element()
{
  let $sourceAttr := if($source != "") then attribute {"source"} {"#" || $source} else attribute {"resp"} {$config:default-resp-statement}
  let $elementName := functx:trim($associatedData/*:type/text())
  let $dateAttrs :=
    for $item in $associatedData/*
    where $item/text() != "" and ($item/name() = "when" or $item/name() = "notBefore" or $item/name() = "notAfter")
    let $dateAttrValue := functx:trim($item/text())
    let $dateAttrValue := csv2srophe:enforce-iso-date-format($dateAttrValue) (: ensure date attribute is in proper ISO format :)
    return attribute {$item/name()} {$dateAttrValue}
  return element {QName("http://www.tei-c.org/ns/1.0", $elementName)} {$sourceAttr, $dateAttrs, $textNode}
};

declare function csv2srophe:enforce-iso-date-format($date)
as xs:string
{
  let $dateComponents := tokenize($date, "-")
  let $year := format-number(xs:integer($dateComponents[1]), "9999")
  let $month := if($dateComponents[2] != "") then format-number(xs:integer($dateComponents[2]), "99") else()
  let $day := if($dateComponents[3] != "") then format-number(xs:integer($dateComponents[3]), "99") else ()
  return string-join(($year, $month, $day), "-")
};

declare function csv2srophe:build-relation-element($relationData as element(), 
                                                   $source as xs:string?,
                                                   $uriLocalName as xs:string,
                                                   $separator as xs:string)
as element()
{
  let $selfUri := $config:uri-base || $uriLocalName (: it is assumed but not enforced that this function receives only the numerical portion of the URI :)
  
  let $otherUris := functx:trim($relationData/textNode/text())
  let $otherUris := tokenize($otherUris, $separator)
  (: if the other uris are of the same entity type (e.g., persons in a person row), they will not have the URI-base :)
  let $otherUris := for $uri in $otherUris return if(starts-with($uri, "http") or starts-with($uri, "ISO") or starts-with($uri, "snap:")) then $uri else $config:uri-base || $uri
  let $otherUris := string-join($otherUris, " ")
  
  let $sourceAttr := if($source != "") then attribute {"source"} {$source} else attribute {"resp"} {$config:default-resp-statement}
  
  let $relationType := functx:trim($relationData/type/text())
  
  return switch($relationType)
  case "possiblyIdentical" return 
    let $name := attribute {"name"} {"possibly-identical"}
    let $mutual := attribute {"mutual"} {$selfUri||" "||$otherUris}
    let $desc := element {QName("http://www.tei-c.org/ns/1.0", "desc")} {attribute {"xml:lang"} {"en"}, "This person is possibly identical with the person represented in another record"}
    return element {QName("http://www.tei-c.org/ns/1.0", "relation")} {$name, $mutual, $sourceAttr, $desc}
  case "skosBroadMatch" return
    let $name := attribute {"name"} {"skos:broadMatch"}
    let $ref := attribute {"ref"} {"http://www.w3.org/2004/02/skos/core#broadMatch"}
    let $active := attribute {"active"} {$selfUri}
    let $passive := attribute {"passive"} {$otherUris}
    return element {QName("http://www.tei-c.org/ns/1.0", "relation")} {$name, $ref, $active, $passive}
  case "skosCloseMatch" return
    let $name := attribute {"name"} {"skos:closeMatch"}
    let $ref := attribute {"ref"} {"http://www.w3.org/2004/02/skos/core#closeMatch"}
    let $active := attribute {"active"} {$selfUri}
    let $passive := attribute {"passive"} {$otherUris}
    return element {QName("http://www.tei-c.org/ns/1.0", "relation")} {$name, $ref, $active, $passive}
  case "skosBroader" return
    let $name := attribute {"name"} {"skos:broader"}
    let $ref := attribute {"ref"} {"http://www.w3.org/2004/02/skos/core#broader"}
    let $active := attribute {"active"} {$selfUri}
    let $passive := attribute {"passive"} {$otherUris}
    return element {QName("http://www.tei-c.org/ns/1.0", "relation")} {$name, $ref, $active, $passive}
  default return 
    let $name := attribute {"name"} {"see-also"}
    let $mutual := attribute {"mutual"} {$selfUri||" "||$otherUris}
    return element {QName("http://www.tei-c.org/ns/1.0", "relation")} {$name, $mutual, $sourceAttr}
};

declare function csv2srophe:build-listRelation-element($row as element(), 
                                                        $relationsIndex as element()*, 
                                                        $sourcesIndexForRow as element()*)
as element()?
{
  let $relations := csv2srophe:build-element-sequence($row, 
                                                      $relationsIndex, 
                                                      $sourcesIndexForRow, 
                                                      "relation", 0)
  return if(not(empty($relations))) then 
    element {QName("http://www.tei-c.org/ns/1.0", "listRelation")} {$relations}
  else ()
};
(: I'm not sure these final functions should be in this module. They are more
: generic than just csv transform. Perhaps separate out into some util library? :)

declare function csv2srophe:build-editor-node($editorUri as xs:string,
                                              $editorNameString as xs:string,
                                              $role as xs:string)
as element()
{
  let $editorNode := 
  <editor xmlns="http://www.tei-c.org/ns/1.0" role="{$role}" ref="{$editorUri}">
    {$editorNameString}
  </editor>
  return $editorNode
};

declare function csv2srophe:build-respStmt-node($personUri as xs:string,
                                              $personNameString as xs:string,
                                              $resp as xs:string)
as element()
{
  let $respNode := <resp xmlns="http://www.tei-c.org/ns/1.0">{$resp}</resp>
  let $name := <name xmlns="http://www.tei-c.org/ns/1.0" ref="{$personUri}">{$personNameString}</name>
  return <respStmt xmlns="http://www.tei-c.org/ns/1.0">{$respNode, $name}</respStmt>
};

declare function csv2srophe:build-revisionDesc($change-log as element()*, 
                                                $status as xs:string)
as element()
{
  let $revisionDesc :=
  <revisionDesc xmlns="http://www.tei-c.org/ns/1.0" status="{$status}">
  {$change-log}
  </revisionDesc>
  return $revisionDesc
};

(: ----------------------------------------- :)
(: LATER DEVELOPMENT :)
(: ----------------------------------------- :)

(:
: The below functions area copied from Steve Baskauf's original transform.
: They are somewhat patched together and hard-coded. I believe further
: development would benefit from writing functions in this module that create
: note lists (incerta, disambiguation, etc.). These could require a change
: in the csv so the headers are like: note1.incerta.en; note2.disambiguation.en; etc.
: This would allow uris, etc. to be treated as sourceUri.note1 and pages.note1,
: so the sources could be simplified.
: This would also allow multiple languages and separate the index generation from
: the encoding of the elements -- i.e., different entity modules could handle
: where top put the various notes (this is how names, headwords, etc. are handled)
: However, given that our current needs do not require transform of notes, I am
: delaying development of these functions until they are needed.
: - William L. Potter, 2021-10-11
:)
(: create the disambiguation element. It's a bit unclear whether there can be multiple values or multiple languages, or if source is required. :)
(: let $disambiguation := 
    for $dis in $headerMap 
    let $text := local:trim($document/*[name() = $dis/name/text()]/text()) (: look up the text in that column
    where $dis/string/text() = 'note.disambiguation' and $text != '' screen for correct column and skip over empty elements
    let $disUri := local:trim($document/*[name() = 'sourceURI.note.disambiguation']/text())  this is a hack that just pulls the text from the sourcURI column.  Use the lookup method if it gets more complicated
    let $disPg := local:trim($document/*[name() = 'pages.note.disambiguation']/text())  this is a hack that just pulls the text from the pages column.  Use the lookup method if it gets more complicated
    let $sourceAttribute := 
        if ($disUri != '')
        then
            for $src at $srcNumber in $sources  step through the source index
            where  $disUri = $src/uri/text() and $disPg = $src/pg/text()  URI and page from columns must match with iterated item in the source index
            return '#bib'||$uriLocalName||'-'||$srcNumber    create the last part of the source attribute
        else ()
    return  this is also a hack and can't handle disambiguations in other languages
        if ($disUri = '')
        then <note xmlns = "http://www.tei-c.org/ns/1.0" type="disabmiguation" xml:lang="en">{$text}</note>
        else <note xmlns = "http://www.tei-c.org/ns/1.0" type="disabmiguation" xml:lang="en" source="{$sourceAttribute}">{$text}</note> :)

(: create the incerta element. All the same issues with the disambituation element are here.  This is basically a cut and paste of disambiguation :)
(: let $incerta := 
    for $inc in $headerMap 
    let $text := local:trim($document/*[name() = $inc/name/text()]/text()) look up the text in that column
    where $inc/string/text() = 'note.incerta' and $text != '' screen for correct column and skip over empty elements
    let $incUri := local:trim($document/*[name() = 'sourceURI.note.incerta']/text())  this is a hack that just pulls the text from the sourcURI column.  Use the lookup method if it gets more complicated
    let $incPg := local:trim($document/*[name() = 'pages.note.incerta']/text())  this is a hack that just pulls the text from the pages column.  Use the lookup method if it gets more complicated
    let $sourceAttribute := 
        if ($incUri != '')
        then
            for $src at $srcNumber in $sources  step through the source index
            where  $incUri = $src/uri/text() and $incPg = $src/pg/text()  URI and page from columns must match with iterated item in the source index
            return '#bib'||$uriLocalName||'-'||$srcNumber    create the last part of the source attribute
        else ''
    return  this is also a hack and can't handle disambiguations in other languages
        if ($incUri = '')
        then <note xmlns = "http://www.tei-c.org/ns/1.0" type="incerta" xml:lang="en">{$text}</note>
        else <note xmlns = "http://www.tei-c.org/ns/1.0" type="incerta" xml:lang="en" source="{$sourceAttribute}">{$text}</note>
:):)