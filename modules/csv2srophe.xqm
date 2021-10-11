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

(: note that it makes use of Basex's CSV module. Note also that you should declare output options. :)


(: ----------------------------------------- :)
(: functions for processing a full CSV document :)
(: ----------------------------------------- :)

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
:   <pagesElementName>pages.name2</pagesElementName>
: </name>
: <name>
:   <langCode>syr</langCode>
:   <textNodeColumnElementName>name3.syr</textNodeColumnElementName>
:   <sourceUriElementName>sourceURI.name3</sourceUriElementName>
:   <pagesElementName>pages.name3</pagesElementName>
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
      return if ($uriColumn/string/string() = 'sourceURI.'||$leftOfDot)
             then <sourceUriElementName>{$uriColumn/name/string()}</sourceUriElementName>
             else (),
      for $pagesColumn in $headerMap   (: find the element name of the sourceURI column :)
      return if ($pagesColumn/string/string() = 'pages.'||$leftOfDot)
             then <pagesElementName>{$pagesColumn/name/string()}</pagesElementName>
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
      </textNodeColumnElementName>
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
      return if ($uriColumn/string/string() = 'sourceURI.'||$leftOfDot||'.'||$langCode)
             then <sourceUriElementName>{$uriColumn/name/string()}</sourceUriElementName>
             else (),
      for $pagesColumn in $headerMap   (: find the element name of the sourceURI column :)
      return if ($pagesColumn/string/string() = 'pages.'||$leftOfDot||'.'||$langCode)
             then <pagesElementName>{$pagesColumn/name/string()}</pagesElementName>
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
: Returns the URI 
: @param $row a single row of data, as produced by the get-data function.
: @see get-data()
: @param $entityUriBase is the entity-specific portion of the record's URI, e.g.
: 'https://syriaca.org/place/'. This is stored in the config.xml
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
:   <pg></pg>
: </source>
: <source>
:   <uri></uri>
:   <pg></pg>
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
    where substring($source/string/text(),1,9) = 'sourceURI' and $sourceUri != '' (: screen for right header string and skip over empty elements :)
    let $lastPartColString := substring($source/string/text(),10)  (: find the last part of the sourceUri column header label :)
    let $sourcePgColumnString := 'pages'||$lastPartColString  (: construct the column label for the page source :)
    let $sourcePgColumnName :=
        for $sourcePage in $headerMap    (: find the column string that matches the constructed on :)
        where $sourcePgColumnString = $sourcePage/string/text()
        return $sourcePage/name/text()     (: return the XML tag name for the matching column string :)
    let $sourcePage := functx:trim($row/*[name() = $sourcePgColumnName]/text())
    return (<source><uri>{$sourceUri}</uri><pg>{$sourcePage}</pg></source>)
    
     (: remove redundant sources :)
    return functx:distinct-deep($sources)
};

(:~ 
: Returns a sequence of tei:bibl elements of the following form:
: <bibl xmlns="" xml:id="bib78-1">
:   <ptr target="http://syriaca.org/bibl/1"
:   <citedRange unit="p">8</citedRange>
: </bibl>
:)
declare function csv2srophe:create-bibl-sequence($row as element(),
                                                         $headerMap as element()+)
as element()*
{
  let $sources := csv2srophe:create-sources-index-for-row($row, $headerMap)
  let $uriLocalName := csv2srophe:get-uri-from-row($row, "")
  for $source at $number in $sources
    let $sourceUri := $source/uri/text()
    let $sourcePageRange := $source/*:pg/text()
    return
    <bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="bib{$uriLocalName}-{$number}">
        <ptr target="{$sourceUri}"/>
        <citedRange unit="p">{$sourcePageRange}</citedRange>
    </bibl>
}; (:refactor: handle multiple @unit values in citedRange ("p" can be the default) :)

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
(:
- creator editor and respStmts (for now from config; consider a pull from a column?)
- revisionDesc creation
:)

(: ----------------------------------------- :)
(: constructing the skeleton (Most of this takes place in the extensions of this module) :)
(: ----------------------------------------- :)



(: Elements needed from this module

header
- editor[@role="creator"]
-respStmt for creation
- revisionDesc

body
- place/@type (created by a collection-specific extension e.g. csv2places.xqm)
- headwords
- names (specifically placeName, persName, etc. depending)
- abstract
- places need nested locations (csv2places.xqm)
- uri for record as an idno
- other idno list
- notes (incerta, disambiguation, perhaps other shared note types; otherwise farm out to collection-specific functions)
- bibl list

NOTE: The actual placing of the body elements will depend on the entity type

:)