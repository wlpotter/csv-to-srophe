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
  
  let $indices := ($headwordIndex, $namesIndex, $abstractIndex)
  
  for $row in $data
    return switch($config:collection-type)
      case "places" return csv2places:create-place-from-row($row, $headerMap, $indices)
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
  let $xmlDoc := csv:doc($url,
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
  for $nameColumn in $headerMap
  let $columnString := $nameColumn/string/string()
  let $leftOfDot := tokenize($columnString,'\.')[1]
  let $langCode := tokenize($columnString,'\.')[2]
  return if (substring(tokenize($columnString,'\.')[1],1,4) = 'name') then
  <name>{
      <langCode>{$langCode}</langCode>,
      <textNodeColumnElementName>
        {$nameColumn/name/string()}
      </textNodeColumnElementName>,
      
      for $uriColumn in $headerMap   (: find the element name of the sourceURI column :)
      return if (lower-case($uriColumn/string/string()) = 'sourceuri.'||$leftOfDot)
             then <sourceUriElementName>{$uriColumn/name/string()}</sourceUriElementName>
             else (),
      for $citedRangeColumn in $headerMap   (: find the element name of the sourceURI column :)
      return if ($citedRangeColumn/string/string() = 'citedRange.'||$leftOfDot)
             then <citedRangeElementName>{$citedRangeColumn/name/string()}</citedRangeElementName>
             else (),
      for $citationUnitColumn in $headerMap   (: find the element name of the sourceURI column :)
      return if ($citationUnitColumn/string/string() = 'citationUnit.'||$leftOfDot)
             then <citationUnitElementName>{$citationUnitColumn/name/string()}</citationUnitElementName>
             else ()
    }</name>
  else 
   ()
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
  for $nameColumn in $headerMap
  let $columnString := $nameColumn/string/string()
  let $leftOfDot := tokenize($columnString,'\.')[1]
  let $langCode := tokenize($columnString,'\.')[2]
  return if (substring(tokenize($columnString,'\.')[1],1,8) = 'headword') then
    <headword>{
      <langCode>{$langCode}</langCode>,
      <textNodeColumnElementName>
        {$nameColumn/name/string()}
      </textNodeColumnElementName>,
      
      for $uriColumn in $headerMap   (: find the element name of the sourceURI column :)
      return if (lower-case($uriColumn/string/string()) = 'sourceuri.'||$leftOfDot||"."||$langCode)
             then <sourceUriElementName>{$uriColumn/name/string()}</sourceUriElementName>
             else (),
      for $citedRangeColumn in $headerMap   (: find the element name of the sourceURI column :)
      return if ($citedRangeColumn/string/string() = 'citedRange.'||$leftOfDot||"."||$langCode)
             then <citedRangeElementName>{$citedRangeColumn/name/string()}</citedRangeElementName>
             else (),
      for $citationUnitColumn in $headerMap   (: find the element name of the sourceURI column :)
      return if ($citationUnitColumn/string/string() = 'citationUnit.'||$leftOfDot||"."||$langCode)
             then <citationUnitElementName>{$citationUnitColumn/name/string()}</citationUnitElementName>
             else ()
    }</headword>
  else 
   ()
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
  for $nameColumn in $headerMap
  let $columnString := $nameColumn/string/string()
  let $leftOfDot := tokenize($columnString,'\.')[1]
  let $langCode := tokenize($columnString,'\.')[2]
  return if (substring(tokenize($columnString,'\.')[1],1,8) = 'abstract') then
    <abstract>{
      <langCode>{$langCode}</langCode>,
      <textNodeColumnElementName>
        {$nameColumn/name/string()}
      </textNodeColumnElementName>,
      
      for $uriColumn in $headerMap   (: find the element name of the sourceURI column :)
      return if (lower-case($uriColumn/string/string()) = 'sourceuri.'||$leftOfDot)
             then <sourceUriElementName>{$uriColumn/name/string()}</sourceUriElementName>
             else (),
      for $citedRangeColumn in $headerMap   (: find the element name of the sourceURI column :)
      return if ($citedRangeColumn/string/string() = 'citedRange.'||$leftOfDot)
             then <citedRangeElementName>{$citedRangeColumn/name/string()}</citedRangeElementName>
             else (),
      for $citationUnitColumn in $headerMap   (: find the element name of the sourceURI column :)
      return if ($citationUnitColumn/string/string() = 'citationUnit.'||$leftOfDot)
             then <citationUnitElementName>{$citationUnitColumn/name/string()}</citationUnitElementName>
             else ()
    }</abstract>
  else 
   ()
};

(: ----------------------------------------- :)
(: functions for processing individual data rows into skeleton tei records :)
(: ----------------------------------------- :)

(: Note: the majority of elements are constructed by entity-specific modules,
:  e.g. csv2places.xqm. In this module are functions that create elements
:  shared across the majority of entity types.
:)

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
(: NOTE: should refactor to handle non-page references? :)
declare function csv2srophe:create-sources-index-for-row($row as element(),
                                                         $headerMap as element()+)
as element()*
{
  (: Find every possible reference in the row and add it to a sequence :)
  let $sources :=
    for $source in $headerMap  (: loop through each item in the header map sequence :)
    let $sourceUriColumnName := $source/name/text()  (: get the XML element name :)
    let $sourceUri := functx:trim($row/*[name() = $sourceUriColumnName]/text())  (: find the value for that column :)
    where lower-case(substring($source/string/text(),1,9)) = 'sourceuri' and $sourceUri != '' (: screen for right header string and skip over empty elements :)
    let $sourceUriElement := <uri>{$sourceUri}</uri>
    
    let $lastPartColString := substring($source/string/text(),10)  (: find the last part of the sourceUri column header label :)
    let $citedRangeColumnString := 'citedRange'||$lastPartColString  (: construct the column label for the cited range of the source :)
    let $citedRangeColumnName :=
        for $citedRange in $headerMap    (: find the column string that matches the constructed on :)
        where $citedRangeColumnString = $citedRange/string/text()
        return $citedRange/name/text()     (: return the XML tag name for the matching column string :)
    let $sourceCitedRange := functx:trim($row/*[name() = $citedRangeColumnName]/text())
    let $sourceCitedRangeElement := <citedRange>{$sourceCitedRange}</citedRange>
    
    let $citationUnitColumnString := 'citationUnit'||$lastPartColString  (: construct the column label for the citation unit :)
    let $citationUnitColumnName :=
        for $citationUnit in $headerMap    (: find the column string that matches the constructed one :)
        where $citationUnitColumnString = $citationUnit/string/text()
        return $citationUnit/name/text()     (: return the XML tag name for the matching column string :)
    let $sourceCitationUnit := functx:trim($row/*[name() = $citationUnitColumnName]/text())
    let $sourceCitationUnitElement := if ($sourceCitationUnit != "") then <citationUnit>{$sourceCitationUnit}</citationUnit>
    return (<source>{$sourceUriElement, $sourceCitedRangeElement, $sourceCitationUnitElement}</source>)
    
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
                                                         $headerMap as element()+)
as element()*
{
  let $sources := csv2srophe:create-sources-index-for-row($row, $headerMap)
  let $uriLocalName := csv2srophe:get-uri-from-row($row, "")
  for $source at $number in $sources
    let $sourceUri := $source/uri/text()
    
    (: add the bibl uri-base if not already there :)
    let $sourceUri := if(starts-with($sourceUri, "http://syriaca.org/bibl/")
                         and $sourceUri != "")
                      then $sourceUri 
                      else "http://syriaca.org/bibl/" || $sourceUri
    let $sourceCitedRange := $source/*:citedRange/text()
    let $sourceCitationUnit := if ($source/*:citationUnit/text() != "") then $source/*:citationUnit/text() else "p"
    return
    <bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="bib{$uriLocalName}-{$number}">
        <ptr target="{$sourceUri}"/>
        <citedRange unit="{$sourceCitationUnit}">{$sourceCitedRange}</citedRange>
    </bibl>
    (: refactor: handle multiple "#"-separated citedRange and citationUnits from the csv :)
}; (:refactor: handle multiple @unit values in citedRange ("p" can be the default) 

Refactor: add a function that matches source values and returns the correct bibl source attribute based on input data
csv2srophe:get-source-attribute-for-node($matchUri, $matchPages) -- once you make the more complex @unit handling, this can become $matchRangeType, $matchRangeValue or something similar
:)

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
: Returns a sequence of elements that represent entity names of Syriaca entities.
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
declare function csv2srophe:build-name-element-sequence($row as element(), 
                                                        $columnIndex as element()*, 
                                                        $sourcesIndex as element()*, 
                                                        $elementName as xs:string,
                                                        $isHeadword as xs:boolean,
                                                        $enumerationOffset as xs:integer)
as element()*
{
  let $uriLocalName := csv2srophe:get-uri-from-row($row, "")
  
  (: get the column information for this row's non-empty names :)
  let $nonEmptyColumnIndex := csv2srophe:get-non-empty-index-from-row($row, $columnIndex)
  
  return
    for $item at $number in $nonEmptyColumnIndex     (: loop through each of the names in various languages :)
    let $text := functx:trim($row/*[name() = $item/textNodeColumnElementName/text()]/text()) (: look up the name for that column :)
    let $itemSourceUri := functx:trim($row/*[name() = $item/sourceUriElementName/text()]/text())  (: look up the URI that goes with the name column :)
    let $itemSourceCitedRange := functx:trim($row/*[name() = $item/citedRangeElementName/text()]/text())  (: look up the citedRange that goes with the name column :)
    let $itemSourceCitationUnit := functx:trim($row/*[name() = $item/citationUnitElementName/text()]/text())  (: look up the citation unit that goes with the name column :)
    
    (: get the @source attribute value by matching the uri, cited range, and citation unit values :)
    let $sourceAttr := 
        for $src at $srcNumber in $sourcesIndex  (: step through the source index :)
        where  $itemSourceUri = $src/*:uri/text() and $itemSourceCitedRange = $src/*:citedRange/text() and string($itemSourceCitationUnit) = string($src/*:citationUnit/text())  (: URI and page from columns must match with iterated item in the source index :)
        return "bib" || $uriLocalName||'-'||$srcNumber    (: create the last part of the source attribute :)
    let $langAttr := functx:trim($item/langCode/text())
    return csv2srophe:build-name-element($text, $elementName, $uriLocalName, $langAttr, $sourceAttr, $isHeadword, $number + $enumerationOffset)
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
  let $id := if($elementName != "gloss") then (: glosses are 'alternate names' for taxonomy entities and don't have xml:ids. :)
                 if($elementName = "term") then (: taxonomy headwords are tei:term elements with the xml:id pattern of 'name-$entityUri-$language' :)
                   "name-" || $entityUri || "-" || $language (: in this case $entityUri should be the lower-case value of $textNode :)
                 else
                   "name" || $entityUri || "-" || $namePositionInSequence (: all other entities have the xml:id pattern of "name$entityUri-$namePositionInSequence":)
  let $xmlId := if($id != "") then attribute {"xml:id"} {$id}
  let $xmlLang := attribute {"xml:lang"} {$language}
  let $sourceAttr := if($source != "") then
                       attribute {"source"} {"#" || $source}
                     else
                       attribute {"resp"} {"http://syriaca.org"}
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
  let $id := if($entityUri != "") then 
              attribute {"xml:id"} {"abstract" || $entityUri || "-" || $abstractPositionInSequence}
  let $type := attribute {"type"} {"abstract"}
  let $xmlLang := attribute {"xml:lang"} {$language}
  let $sourceAttr := if($source != "") then
                        attribute {"source"} {"#" || $source}
                     else
                        attribute {"resp"} {"http://syriaca.org"}
  return element {QName("http://www.tei-c.org/ns/1.0", $elementName)}
                  {$type, $id, $xmlLang, $sourceAttr, $textNode}

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
(: pending. This should take a data row, probably a date-index (which this module should create) and an index of sources. Based on the date type (type.daten), various elements can be constructed (see the list above). First implement for floruit, death, and birth in persons. Then can add later to handle existence and events and such:)
declare function csv2srophe:create-dates($row, $sources)
{
  
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