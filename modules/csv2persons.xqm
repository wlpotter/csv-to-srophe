xquery version "3.0";

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
  let $text := 
  <text xmlns="http://www.tei-c.org/ns/1.0">
    <body>
      <listPerson>
        {csv2persons:build-person-node-from-row($row, $headerMap, $indices)}
      </listPerson>
    </body>
  </text>
  (: listRelation will go below the listPerson, but not currently developed as not currently needed. Likely a csv2srophe.xqm function call as it's shared among places, etc. :)
  
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
  let $sourcesIndex := $indices/self::source
  let $sources := csv2srophe:create-sources-index-for-row($sourcesIndex, $row)
  
  (: build descendant nodes of the tei:person :)
  
  let $headwords := csv2srophe:build-element-sequence($row, $headwordIndex, $sources, "persName", 0)
  let $numHeadwords := count($headwords)
  (: add anonymous-description elements. also need to test that this doesn't break when there **aren't** anon descs :)
  let $persNames := csv2srophe:build-element-sequence($row, $namesIndex, $sources, "persName", $numHeadwords)
  let $idnos := csv2srophe:create-idno-sequence-for-row($row, $config:uri-base)
  
  let $abstracts := csv2srophe:build-element-sequence($row, $abstractIndex, $sources, "note", 0)
  
  (: do any of these need indices?? :)
  let $trait := csv2persons:create-trait($row)
  let $sex := csv2persons:create-sex-element($row, $sources)
  let $dates := csv2srophe:create-dates($row, $sources) (: still pending :)
  
  (: pending: 
  - @ana attribute on tei:person for saint, author, etc.
  :)
  
  let $bibls := csv2srophe:create-bibl-sequence($row, $sources)
  
  (: compose tei:place element and return it :)
  
  return 
  <person xmlns="http://www.tei-c.org/ns/1.0" xml:id="person-{$uriLocalName}">
    {$headwords, $persNames, $idnos, $trait, $sex, $dates, $abstracts, $bibls}
  </person>
};

(: currently hard-coded as this function will likely change considerably :)
declare function csv2persons:create-trait($row as element())
as element()?
{
  let $traitText := functx:trim($row/*[name() = "trait.en"]/text())
  let $label := element {QName("http://www.tei-c.org/ns/1.0", "label")} {$traitText}
  return if($traitText != "") then element {QName("http://www.tei-c.org/ns/1.0", "trait")} {attribute {"xml:lang"} {"en"}, $label}
};

declare function csv2persons:create-sex-element($row, $sources)
{
  
};