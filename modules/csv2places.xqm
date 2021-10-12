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
                                                  $headerMap as element(),
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
      (: listRelation will go here, but not currently developed as not currently needed. Likely a csv2srophe.xqm function call as it's shared among places, etc. :)
    </body>
  </text>
  
  let $tei := 
  <TEI xmlns="http://www.tei-c.org/ns/1.0" xml:lang="{$config:base-language}">
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
  let $placeNames := csv2places:create-placeNames($row, $namesIndex, $sources)
  let $abstracts := csv2places:create-abstracts($row, $abstractIndex, $sources)
  
  (: currently not handling gps locations or relative locations :)
  let $nestedLocations := csv2places:create-nested-locations($row)
  
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
as element()
{
  
};

declare function csv2places:create-placeNames($row as element(),
                                             $namesIndex as element()*,
                                             $sourcesIndex as element()*)
as element()
{
  
};

declare function csv2places:create-abstracts($row as element(),
                                             $abstract as element()*,
                                             $sourcesIndex as element()*)
as element()
{
  
};

declare function csv2places:create-nested-locations($row as element())
as element()
{
  
};