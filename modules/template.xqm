xquery version "3.0";

(:
: Module Name: Syriaca.org Record Template Merging
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This module merges XML snippets of place records into full,
:                  schema-compliant Syriaca Place records.
:)

(:~ 
: This module merges XML snippets into full, schema-compliant
: Syriaca records. Its functions primarily handle the merging of 
: these XML snippets, either generated from a CSV transform (see csv2srohpe.xqm 
: and its extensions for more on CSV transformations) or hand-coded as an XML-
: snippet. The result of this module will be a schema-compliant Syriaca entity
: record.
: The template into which XML snippets are merged is specified at run-time and
: is based on the collection designated in config.xml
:
: @author William L. Potter
: @version 1.0
:)
module namespace template="http://wlpotter.github.io/ns/template";

import module namespace config="http://wlpotter.github.io/ns/config" at "config.xqm";
import module namespace functx="http://www.functx.com";
  

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace srophe="https://srophe.app";

(:~ 
: @param $recordUri is the full URI of the document, including the URI-base, e.g. "http://syriaca.org/place/78".
: Although this URI is included in a tei:idno element within the $record, its location is not reliable entity-type
: to entity-type. Thus, rather than risking an inaccurate XPath, this value is passed to the function. :)
declare function template:merge-record-into-template($record as node(),
                                                     $template as node(),
                                                     $recordUri as xs:string)
as node()
{
  (: merge titleStmt from record into template :)
  let $headwords := $record//*[@srophe:tags="#syriaca-headword"]
  let $recordTitle := template:create-record-title-from-headwords($headwords, "en")
  let $titleStmt := 
  <titleStmt>
    {
      $recordTitle,
      $template//titleStmt/*[not(name() = "respStmt")],
      $record//titleStmt/editor[@role="creator"],
      $record//titleStmt/respStmt,
      $template//titleStmt/respStmt
    }
  </titleStmt>
  
  (: editionStmt comes from the template :)
  let $editionStmt := $template//editionStmt
  
  (: build publicationStmt based on record's URI :)
  (: as the document's idno may change depending on its entity, this value is passed to the function :)
  let $pubStmtIdno := <idno type="URI">{$recordUri || "/tei"}</idno>
  let $publicationStmt := (: careful here as there could be variance in the publicationStmt. I don't think there is but might need to revisit this. :)
  <publicationStmt>
    {
      $template//publicationStmt/authority,
      $pubStmtIdno,
      $template//publicationStmt/availability,
      <date>{fn:current-date()}</date>
    }
  </publicationStmt>
  
  (: build the seriesStmt from tepmlate :)
  let $seriesStmt := if($config:collection-type = "persons")
    (: for persons, the seriesStmt depends on if the person is an author and/or saint :)
    then template:build-persons-seriesStmt($template, string($record//text/body/listPerson/person/@ana))
    else $template//seriesStmt
  
  (: build sourceDesc from template :)
  let $sourceDesc := $template//sourceDesc
  
  (: build fileDesc from component parts :)
  let $fileDesc :=
  <fileDesc>
    {
      $titleStmt,
      $editionStmt,
      $publicationStmt,
      $seriesStmt,
      $sourceDesc
    }
  </fileDesc>
  
  (: build the encodingDesc which comes from the template :)
  let $encodingDesc := $template//encodingDesc
  
  (: build the profileDesc which comes from the template :)
  let $profileDesc := $template//profileDesc
  
  (: build the revisionDesc which comes from the record :)
  (: NOTE: potentially add a revisionDesc change for template merging? :)
  let $revisionDesc := $record//revisionDesc
  
  (: build teiHeader from component parts :)
  let $teiHeader := 
  <teiHeader>
  {
    $fileDesc,
    $encodingDesc,
    $profileDesc,
    $revisionDesc
  }
  </teiHeader>

  (: the text node comes entirely from the $record :)
  let $text := $record//text
  
  (: now the TEI node can be constructed; the xml:lang attribute comes from the record :)
  let $baseLanguage := string($record/TEI/@xml:lang)
  let $teiNode :=
  (: NOTE: as there is not a way to select and copy the xmlns declarations from the template, this is somewhat of a hack based on places. 
  : If needed, add more :)
  <TEI xmlns:svg="http://www.w3.org/2000/svg" xmlns:syriaca="http://syriaca.org" xmlns:srophe="https://srophe.app" xml:lang="{$baseLanguage}">
    {
      $teiHeader,
      $text
    }
  </TEI>
  
  (: build list of processing instructions based on template. This should be the various schema associations and any other CSS, etc. associations :)
  let $processingInstructions := $template/processing-instruction()
  return document {$processingInstructions, $teiNode}
};

(:~ 
: takes input of some sequence of headword elements.
: returns a tei:title element of the form:
: <title level="a" xml:lang="{$baseLanguage}">Base-Language Headword - <foreign xml:lang="{non-base-language}">Non-Base-Language-Headword</foreign></title> 
: 
:)
declare function template:create-record-title-from-headwords($headwords as element()+,
                                                             $baseLanguage as xs:string)
as element()
{
  let $baseLanguageHeadwords := $headwords[@xml:lang = $baseLanguage]
  let $foreignHeadwords := $headwords[@xml:lang != $baseLanguage]
  return 
  <title level="a" xml:lang="{$baseLanguage}">
    {
      fn:string-join($baseLanguageHeadwords/text(), " - ") (: combine all base-language headword's text nodes, separated by " - ":),
      for $headword at $i in $foreignHeadwords
        let $joiner := if($i > 1) then " - " else "- " (: avoid adding an extra space between base and foreign headwords:)
        return ($joiner, <foreign xml:lang="{string($headword/@xml:lang)}">{$headword/text()}</foreign>)
    }
  </title>
  
};

declare function template:build-persons-seriesStmt($template as node(), $personType as xs:string?)
as element()+
{
  (: include the main Syriac Biographical Dictionary seriesStmt, with the corresponding biblScopes for each entity-type:)
  let $sbdSeriesStmt := $template//seriesStmt[idno[@type="URI"]/text() = "http://syriaca.org/persons"]
  let $qadisheBiblScope := if(contains($personType, "#syriaca-saint")) then $sbdSeriesStmt/biblScope[@from="1"]
  let $authorsBiblScope := if(contains($personType, "#syriaca-author")) then $sbdSeriesStmt/biblScope[@from="2"]
  let $otherBiblScope := $sbdSeriesStmt/biblScope[text() = "3"]
  
  (: include volumes 1 and/or 2 if the person is a saint and/or author:)
  let $sbdSeriesStmt := 
    if(contains($personType, "#syriaca-saint") or contains($personType, "#syriaca-author")) then
    element {node-name($sbdSeriesStmt)} {$sbdSeriesStmt/*[not(name() = "biblScope")], $qadisheBiblScope, $authorsBiblScope}
    else element{node-name($sbdSeriesStmt)} {$sbdSeriesStmt/*[not(name() = "biblScope")], $otherBiblScope}
  
  (: include seriesStmt for Gateway to the Syriac Saints if the person is a saint :)
  let $saintsSeriesStmt := if(contains($personType, "#syriaca-saint")) then
    $template//seriesStmt[idno[@type="URI"]/text() = "http://syriaca.org/saints"]
  
  return ($sbdSeriesStmt, $saintsSeriesStmt)
};