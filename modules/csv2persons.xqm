xquery version "3.1";

(:
: Module Name: Syriaca.org CSV to Persons Transformation
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This module extends csv2srophe.xqm to provide person-specific
:                  functions, such as handling floruit dates data. Also provides
:                  functions for building the skeleton person records from csv
:                  data.
:)

(:~ 
: This module provides the functions that transform rows of csv data
: into XML snippets of Syriaca person records. These snippets can be
: merged with person-template.xml via the template.xqm module to create
: full, TEI-compliant Syriaca place records.
:
: @author William L. Potter
: @version 1.0
:)
module namespace csv2persons="http://wlpotter.github.io/ns/csv2persons";


import module namespace functx="http://www.functx.com";
import module namespace config="http://wlpotter.github.io/ns/config" at "config.xqm";
import module namespace csv2srophe="http://wlpotter.github.io/ns/csv2srophe" at "csv2srophe.xqm";

(: Note that you should declare output options. :)



declare function csv2persons:create-person-from-row($row as element(),
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
  let $relationsIndex := $indices/self::relation
  let $sourcesIndex := $indices/self::source
  let $sources := csv2srophe:create-sources-index-for-row($sourcesIndex, $row)
  
  let $text := 
  <text xmlns="http://www.tei-c.org/ns/1.0">
    <body>
      <listPerson>
        {csv2persons:build-person-node-from-row($row, $headerMap, $indices)},
        {csv2srophe:build-listRelation-element($row, $relationsIndex, $sources)}
      </listPerson>
    </body>
  </text>
  
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
: Builds a tei:person element from a row of csv data. Relies upon various
: indices of CSV columns to build certain nodes (E.g., names-index, headword-
: index, etc.). These indices are built in csv2srophe.xqm.
: 
:)
declare function csv2persons:build-person-node-from-row($row as element(),
                                                      $headerMap as element()+,
                                                      $indices as element()*)
as node()
{
  (: get just the numerical portion of the URI :)
  let $uriLocalName := csv2srophe:get-uri-from-row($row, "")
  
  (: set up references for building elements :)
  let $headwordIndex := $indices/self::headword
  let $namesIndex := $indices/self::name
  let $abstractIndex := $indices/self::abstract
  let $anonymousDescIndex := $indices/self::anonymousDesc
  let $sexIndex := $indices/self::sex
  let $genderIndex := $indices/self::gender
  let $datesIndex := $indices/self::date
  let $sourcesIndex := $indices/self::source
  let $sources := csv2srophe:create-sources-index-for-row($sourcesIndex, $row)
  
  (: build descendant nodes of the tei:person :)
  
  (: HARD-CODED pending batch changes will affect this functionality :)
  let $anaAttr := if(functx:trim($row/*[name() = "state.en"]/text()) => lower-case() = "anonymous") then attribute {"ana"} {"#syriaca-anonymous"} else ()
  
  let $headwords := csv2srophe:build-element-sequence($row, $headwordIndex, $sources, "persName", 0)
  let $numHeadwords := count($headwords)
  let $anonymousDesc := csv2srophe:build-element-sequence($row, $anonymousDescIndex, $sources, "persName", $numHeadwords)
  let $numAnonymousDesc := count($anonymousDesc)
  let $persNames := csv2srophe:build-element-sequence($row, $namesIndex, $sources, "persName", $numHeadwords + $numAnonymousDesc)
  let $idnos := csv2srophe:create-idno-sequence-for-row($row, $config:uri-base)
  
  let $abstracts := csv2srophe:build-element-sequence($row, $abstractIndex, $sources, "note", 0)
  
  
  let $state := csv2persons:create-state($row)
  let $sex := csv2srophe:build-element-sequence($row, $sexIndex, $sources, "sex", 0)
  let $gender := csv2srophe:build-element-sequence($row, $genderIndex, $sources, "gender", 0)
  let $dates := csv2srophe:build-element-sequence($row, $datesIndex, $sources, "date", 0)
  (: order for dates should be floruit, birth, death :)
  let $dates := ($dates/self::*[name() = "floruit"], $dates/self::*[name() = "birth"], $dates/self::*[name() = "death"])
  
  (: pending: 
  - @ana attribute on tei:person for saint, author, etc.
  :)
  
  let $bibls := csv2srophe:create-bibl-sequence($row, $sources)
  
  (: compose tei:person element and return it :)
  
  return 
  <person xmlns="http://www.tei-c.org/ns/1.0">
    {$anaAttr, $headwords, $anonymousDesc, $persNames, $idnos, $abstracts, $dates, $gender, $sex, $state, $bibls}
  </person>
};

(: DEPRECATED, please use csv2persons:create-state instead. :)
declare function csv2persons:create-trait($row as element())
as element()?
{
  let $traitText := functx:trim($row/*[name() = "trait.en"]/text())
  let $label := element {QName("http://www.tei-c.org/ns/1.0", "label")} {$traitText}
  return if($traitText != "") then element {QName("http://www.tei-c.org/ns/1.0", "trait")} {attribute {"xml:lang"} {"en"}, $label} else ()
};

(: temporary fix for anonymous state, should become a more complex csv2srophe function with columns for @ref, desc, etc. :)
declare function csv2persons:create-state($row as element())
as element()?
{
  let $stateText := functx:trim($row/*[name() = "state.en"]/text()) => lower-case()
  return switch ($stateText)
    case "anonymous" return 
      element {QName("http://www.tei-c.org/ns/1.0", "state")} 
        {attribute {"type"} {"status"},
         attribute {"resp"} {"http://syriaca.org"},
         attribute {"ref"} {"http://syriaca.org/keyword/anonymous"},
         element {QName("http://www.tei-c.org/ns/1.0", "label")} {
           attribute {"xml:lang"} {"en"},
           "Anonymous"
         }
       }
    default return ()
};