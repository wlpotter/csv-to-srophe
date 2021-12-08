xquery version "3.0";

(:
: Module Name: Syriaca.org CSV to Subjects Transformation
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This module extends csv2srophe.xqm to provide keyword-specific
:                  functions. Also provides
:                  functions for building the skeleton keywords records from csv
:                  data.
:)

(:~ 
: This module provides the functions that transform rows of csv data
: into XML snippets of Syriaca keyword records. These snippets can be
: merged with keyword-template.xml via the template.xqm module to create
: full, TEI-compliant Syriaca keyword records.
:
: @author William L. Potter
: @version 1.0
:)
module namespace csv2subjects="http://wlpotter.github.io/ns/csv2subjects";


import module namespace functx="http://www.functx.com";
import module namespace config="http://wlpotter.github.io/ns/config" at "config.xqm";
import module namespace csv2srophe="http://wlpotter.github.io/ns/csv2srophe" at "csv2srophe.xqm";

(: Note that you should declare output options. :)


(:
Changes to output format
- non-headword names hsould be <gloss xml:lang="en, etc."><term>x</term></gloss>
- idno list
    - may get more complicated because not all are URIs...Spear column is idno[@type="SPEAR"] and ISO codes don't have a type... (Simplest solve: if they have an idno.type, use the .type (which must be the **exact** @type value and is case sensitive). If none given, use "URI". For ISO codes this won't work...maybe have an idno. that is no type? or idno.NoType/None/etc. ? Or rewrite the column headers to require idno.URI on them. But that's somewhat tedious)
    - it gets more complicated...
    - if the idno is @type="SPEAR", it looks like the column G (relType) controls an @ana attribute on the idno (see alliance-with as an example)
    - note that column B (***type) does not seem to do anything
:)
declare function csv2subjects:create-subject-from-row($row as element(),
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
      {csv2subjects:build-subject-node-from-row($row, $headerMap, $indices)}
    </body>
  </text>
  
  let $text := functx:remove-attributes-deep($text, "resp") (: remove unneeded @resp attribute :)
  
  let $tei := 
  element {QName("http://www.tei-c.org/ns/1.0", "TEI")} {$config:active-namespaces, attribute {"xml:lang"} {$config:base-language}, $teiHeader, $text}
  (: <TEI xmlns="http://www.tei-c.org/ns/1.0" xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:srophe="https://srophe.app" xmlns:syriaca="http://syriaca.org" xml:lang="{$config:base-language}">
    {$teiHeader, $text}
  </TEI> :)
  return document {$tei}
};

(:~ 
: Builds a tei:entryFree element representing a Syriaca
: subject entity from a row of csv data. Relies upon various
: indices of CSV columns to build certain nodes (E.g., names-index, headword-
: index, etc.). These indices are built in csv2srophe.xqm.
: 
:)
declare function csv2subjects:build-subject-node-from-row($row as element(),
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
  let $relationsIndex := $indices/self::relation
  
  (: FIX: do we need sources for subjects?? :)
  let $sourcesIndex := $indices/self::source
  let $sources := csv2srophe:create-sources-index-for-row($sourcesIndex, $row)
  
  (: build descendant nodes of the tei:entryFree :)
  
  let $headwords := csv2srophe:build-element-sequence($row, $headwordIndex, $sources, "term", 0)
  let $numHeadwords := count($headwords)
  let $glosses := csv2srophe:build-element-sequence($row, $namesIndex, $sources, "gloss", $numHeadwords)
  
  let $listRelation := csv2srophe:build-listRelation-element($row, $relationsIndex, $sources) (: FIX: need to build a relation for skos:broadMatch:)
  
  let $idnos := csv2srophe:create-idno-sequence-for-row($row, $config:uri-base)
  let $langCodeIdno := if(functx:trim($row/*:iso.langCode/text()) != "") then <idno xmlns="http://www.tei-c.org/ns/1.0">{functx:trim($row/*:iso.langCode/text())}</idno>
  let $abstracts := csv2srophe:build-element-sequence($row, $abstractIndex, $sources, "note", 0)
  
  (: remove unused attributes from abstracts :)
  let $abstracts := for $abs in $abstracts
    return functx:remove-attributes(functx:remove-attributes($abs, "xml:id"), "type")
  
  (: create subtype attribute if one exists :)
  let $subType := if(functx:trim($row/*:subjectSubType/text()) != "") then attribute {"subtype"} {functx:trim($row/*:subjectSubType/text())}
  (: compose tei:entryFree element and return it :)
  return element 
    {QName("http://www.tei-c.org/ns/1.0", "entryFree")} 
    {attribute {"xml:id"} {"keyword-" || $uriLocalName},
     attribute {"type"} {"skos:Concept"} (: hard-coding the entryFree/@type as "skos:Concept". Will this ever change? :),
     $subType,
     $headwords, $glosses, $listRelation, $idnos, $langCodeIdno, $abstracts}
};

(:
Possibly need:

- function stripping out unnecessary @resp attributes
- 
:)