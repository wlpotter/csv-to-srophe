xquery version "3.0";

(:
: Module Name: Syriaca.org CSV to Places Transformation
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This module extends csv2srophe.xqm to provide place-specific
:                  functions, such as handling location data. Also provides
:                  functions for building the skeleton place records from csv
:                  data.
:)

(:~ 
: This module provides the functions that transform rows of csv data
: into XML snippets of Syriaca place records. These snippets can be
: merged with place-template.xqm via the places.xqm module to create
: full, TEI-compliant Syriaca place records.
:
: @author William L. Potter
: @version 1.0
:)
module namespace csv2places="http://wlpotter.github.io/ns/csv2places";


import module namespace functx="http://www.functx.com";
import module namespace config="http://wlpotter.github.io/ns/config" at "config.xqm";
import module namespace csv2srophe="http://wlpotter.github.io/ns/csv2srophe" at "csv2srophe.xqm";

(: Note that you should declare output options. :)



declare function csv2places:create-place-from-row($row as element(),
                                                  $headerMap as element()+,
                                                  $indices as element()*)
as document-node()
{
  (: the xml skeleton record does not have processing-instructions. These are added by the templating functions:)
  (: Build header. Only creator information is needed for the skeleton; all other data added by templating functions :)
  let $titleStmt := 
  <titleStmt xmlns="http://www.tei-c.org/ns/1.0">
    {csv2srophe:build-editor-node($config:creator-uri,
                                  $config:creator-name-string,
                                  "creator"),
     csv2srophe:build-respStmt-node($config:creator-uri,
                                    $config:creator-name-string,
                                    $config:creator-resp-description)
   }
  </titleStmt>
  let $fileDesc := <fileDesc xmlns="http://www.tei-c.org/ns/1.0">{$titleStmt}</fileDesc>
  let $revisionDesc := csv2srophe:build-revisionDesc($config:change-log, "draft")
  let $teiHeader := <teiHeader xmlns="http://www.tei-c.org/ns/1.0">{$fileDesc, $revisionDesc}</teiHeader>
  
  (: Build text node :)
  let $text := 
  <text xmlns="http://www.tei-c.org/ns/1.0">
    <body>
      <listPlace>
        {csv2places:build-place-node-from-row($row, $headerMap, $indices)}
      </listPlace>
    </body>
  </text>
  (: listRelation will go below the listPlace, but not currently developed as not currently needed. Likely a csv2srophe.xqm function call as it's shared among places, etc. :)
  
  let $tei := 
  <TEI xmlns="http://www.tei-c.org/ns/1.0" xmlns:svg="http://www.w3.org/2000/svg" xmlns:srophe="https://srophe.app" xmlns:syriaca="http://syriaca.org" xml:lang="{$config:base-language}">
    {$teiHeader, $text}
  </TEI>
  return document {$tei}
  (:   
  Start adding tests and then split this big function into smaller pieces.
  Then write functions for skeleton gen from the csv row :)
};

(:~ 
: Builds a tei:place element from a row of csv data. Relies upon various
: indices of CSV columns to build certain nodes (E.g., names-index, headword-
: index, etc.). These indices are built in csv2srophe.xqm.
: 
:)
declare function csv2places:build-place-node-from-row($row as element(),
                                                      $headerMap as element()+,
                                                      $indices as element()*)
as node()
{
  (: set up references for building elements :)
  let $headwordIndex := $indices/self::headword
  let $namesIndex := $indices/self::name
  let $abstractIndex := $indices/self::abstract
  let $sources := csv2srophe:create-sources-index-for-row($row, $headerMap)
  
  (: build descendant nodes of the tei:place :)
  let $placeType := csv2places:get-place-type-from-row($row)
  
  let $headwords := csv2places:create-headwords($row, $headwordIndex)
  let $numHeadwords := count($headwords)
  let $placeNames := csv2places:create-placeNames($row, $namesIndex, $sources, $numHeadwords)
  let $abstracts := csv2places:create-abstracts($row, $abstractIndex, $sources)
  
  (: currently not handling gps locations or relative locations :)
  let $nestedLocations := csv2places:create-nested-locations($row, $sources)
  
  let $idnos := csv2srophe:create-idno-sequence-for-row($row, $config:uri-base)
  
  (:currently not handling note creation as not needed for this data :)
  
  let $bibls := csv2srophe:create-bibl-sequence($row, $headerMap)
  let $listBibl := 
    <listBibl xmlns="http://www.tei-c.org/ns/1.0">
      {$bibls}
    </listBibl>
  
  (: compose tei:place element and return it :)
  
  return 
  <place xmlns="http://www.tei-c.org/ns/1.0" type="{$placeType}">
    {$headwords, $placeNames, $abstracts, $nestedLocations, $idnos, $listBibl}
  </place>
};


declare function csv2places:get-place-type-from-row($row as element())
as xs:string
{
  let $placeType := $row/placeType/text()
  return functx:trim($placeType)
};

declare function csv2places:create-headwords($row as element(),
                                             $headwordIndex as element()*)
as element()+
{
  let $uriLocalName := csv2srophe:get-uri-from-row($row, "")
  (: get the column information for this row's non-empty headwords :)
  let $nonEmptyHeadwordIndex := csv2srophe:get-non-empty-index-from-row($row, $headwordIndex)

  return
    for $headword at $number in $nonEmptyHeadwordIndex
    let $text := functx:trim($row/*[name() = $headword/textNodeColumnElementName/text()]/text()) (: look up the headword for that language :)
    where $text != '' (: skip the headword columns that are empty :)
    let $langAttrib := functx:trim($headword/langCode/text())
    return csv2srophe:build-name-element($text, "placeName", $uriLocalName, $langAttrib, "", true (), $number)

};

declare function csv2places:create-placeNames($row as element(),
                                             $namesIndex as element()*,
                                             $sourcesIndex as element()*,
                                             $enumerationOffset as xs:integer)
as element()
{
  let $uriLocalName := csv2srophe:get-uri-from-row($row, "")
  
  (: get the column information for this row's non-empty names :)
  let $nonEmptyNamesIndex := csv2srophe:get-non-empty-index-from-row($row, $namesIndex)
  
  return
    for $name at $number in $nonEmptyNamesIndex     (: loop through each of the names in various languages :)
    let $text := functx:trim($row/*[name() = $name/textNodeColumnElementName/text()]/text()) (: look up the name for that column :)
    let $nameSourceUri := functx:trim($row/*[name() = $name/sourceUriElementName/text()]/text())  (: look up the URI that goes with the name column :)
    let $nameSourcePg := functx:trim($row/*[name() = $name/pagesElementName/text()]/text())  (: look up the page that goes with the name column :)
    let $sourceAttr := 
        for $src at $srcNumber in $sourcesIndex  (: step through the source index :)
        where  $nameSourceUri = $src/uri/text() and $nameSourcePg = $src/pg/text()  (: URI and page from columns must match with iterated item in the source index :)
        return "bib" || $uriLocalName||'-'||$srcNumber    (: create the last part of the source attribute :)
    let $langAttr := functx:trim($name/langCode/text())
    return csv2srophe:build-name-element($text, "placeName", $uriLocalName, $langAttr, $sourceAttr, false (), $number + $enumerationOffset)
};

declare function csv2places:create-abstracts($row as element(),
                                             $abstractIndex as element()*,
                                             $sourcesIndex as element()*)
as element()*
{
  let $uriLocalName := csv2srophe:get-uri-from-row($row, "")
  
  (: get the column information for this row's non-empty abstracts :)
  let $nonEmptyAbstractIndex := csv2srophe:get-non-empty-index-from-row($row, $abstractIndex)
  
  return
    for $abstract at $number in $abstractIndex
    let $text := functx:trim($row/*[name() = $abstract/textNodeColumnElementName/text()]/text()) (: look up the abstract from that column :)
    where $text != ''   (: skip the abstract columns that are empty :)
    let $abstractSourceUri := functx:trim($row/*[name() = $abstract/sourceUriElementName/text()]/text())  (: look up the URI that goes with the abstract column :)
    let $abstractSourcePg := functx:trim($row/*[name() = $abstract/pagesElementName/text()]/text())  (: look up the page that goes with the name column :)
    let $languageAttr := functx:trim($abstract/*:langCode/text()) (: look up the language code for the current abstract :)
    let $sourceAttr := 
        if ($abstractSourceUri != '')
        then
            for $src at $srcNumber in $sourcesIndex  (: step through the source index :)
            where  $abstractSourceUri = $src/uri/text() and $abstractSourcePg = $src/pg/text()  (: URI and page from columns must match with iterated item in the source index :)
            return 'bib'||$uriLocalName||'-'||$srcNumber    (: create the last part of the source attribute :)
        else ()
    return csv2srophe:build-abstract-element($text, "desc", $uriLocalName, $languageAttr, $sourceAttr, $number)
  
};

(: somewhat hacked-together. Generalize with a look up based on sub-elements (e.g., nestedName.$$$ for settlement, region, etc. :)
declare function csv2places:create-nested-locations($row as element(), $sourcesIndex as element()*)
as element()*
{
  let $uriLocalName := csv2srophe:get-uri-from-row($row, "")
  (: here's the settlement child element and it's associated source attribute :)
let $settlementElement := 
    let $setName := functx:trim($row/*[name() = 'nestedName.settlement']/text())  (: this is a hack that just pulls the text from the sourcURI column.  Use the lookup method if it gets more complicated :)
    let $setUri := functx:trim($row/*[name() = 'nestedURI.settlement']/text())
    let $setRefAttr := if ($setUri != "") then attribute {"ref"} {$setUri}
    return
      element {QName("http://www.tei-c.org/ns/1.0", "settlement")} {$setRefAttr, $setName}
let $settlementSourceAttribute :=
    let $setSrc := functx:trim($row/*[name() = 'sourceURI.nested.settlement']/text())    
    let $setPg := functx:trim($row/*[name() = 'pages.nested.settlement']/text())
    return
        if ($setSrc != '')
        then
            for $src at $srcNumber in $sourcesIndex  (: step through the source index :)
            where  $setSrc = $src/uri/text() and $setPg = $src/pg/text()  (: URI and page from columns must match with iterated item in the source index :)
            return '#bib'||$uriLocalName||'-'||$srcNumber    (: create the last part of the source attribute :)
        else ''

(: here's the region child element and it's associated source attribute :)
let $regionElement :=
    let $regName := functx:trim($row/*[name() = 'nestedName.region']/text())  (: this is a hack that just pulls the text from the sourcURI column.  Use the lookup method if it gets more complicated :)
    let $regUri := functx:trim($row/*[name() = 'nestedURI.region']/text())
    let $regRefAttr := if ($regUri != "") then attribute {"ref"} {$regUri}
     return
       element {QName("http://www.tei-c.org/ns/1.0", "region")} {$regRefAttr, $regName}
let $regionSourceAttribute :=
    let $regSrc := functx:trim($row/*[name() = 'sourceURI.nested.region']/text())    
    let $regPg := functx:trim($row/*[name() = 'pages.nested.region']/text())
    return
        if ($regSrc != '')
        then
            for $src at $srcNumber in $sourcesIndex  (: step through the source index :)
            where  $regSrc = $src/uri/text() and $regPg = $src/pg/text()  (: URI and page from columns must match with iterated item in the source index :)
            return '#bib'||$uriLocalName||'-'||$srcNumber    (: create the last part of the source attribute :)
        else ''

(: now we need to build the source attribute from one or more of the sources representing the child elements :)

let $separator :=   (: the separator needs to be the empty string if only one of the child elements has a source.  If they both do, the separator needs to be a single space :)
    if ($settlementSourceAttribute != '' and $regionSourceAttribute != '')
    then ' '
    else ''
let $locationAttribute := $settlementSourceAttribute||$separator||$regionSourceAttribute

(: we have all the pieces to build the nested location element now.  If the $locationAttribute isn't an empty string, there is a ref for one or the other nested type, so use that as the test :)

    return
    if ($locationAttribute != '')
    then 
        <location xmlns="http://www.tei-c.org/ns/1.0" type="nested" source="{$locationAttribute}">{
            $settlementElement,
            $regionElement
      }</location>
    else ()
};