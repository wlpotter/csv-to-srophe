xquery version "3.1";

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
  
  let $listRelation := csv2srophe:build-listRelation-element($row, $relationsIndex, $sources)
  
  let $relationshipTypeNote := if(functx:trim($row/*:relType/text()) != "") then <note type="relationshipType" subtype="{functx:trim($row/*:relType/text())}"/> else ()
  
  let $idnos := csv2srophe:create-idno-sequence-for-row($row, $config:uri-base)
  let $langCodeIdno := if(functx:trim($row/*:iso.langCode/text()) != "") then <idno xmlns="http://www.tei-c.org/ns/1.0">{functx:trim($row/*:iso.langCode/text())}</idno> else ()
  let $abstracts := csv2srophe:build-element-sequence($row, $abstractIndex, $sources, "desc", 0)
  
  (: create subtype attribute if one exists :)
  let $subType := if(functx:trim($row/*:subjectSubType/text()) != "") then attribute {"subtype"} {functx:trim($row/*:subjectSubType/text())} else ()
  (: compose tei:entryFree element and return it :)
  return element 
    {QName("http://www.tei-c.org/ns/1.0", "entryFree")} 
    {attribute {"xml:id"} {"keyword-" || $uriLocalName},
     attribute {"type"} {"http://www.w3.org/2004/02/skos/core#Concept"},
     $subType,
     $headwords, $glosses, $listRelation, $relationshipTypeNote, $idnos, $langCodeIdno, $abstracts}
};

declare function csv2subjects:create-taxonomy-index($taxonomyOutline as node(), $subjectRecords as node()+)
as node()
{
  <taxonomy>
    {csv2subjects:get-broad-matches($taxonomyOutline//taxonomy/listURI, $subjectRecords)}
     <listURI type="taxonomyAllURIs">{for $rec in $subjectRecords return <uri>{$rec//*:entryFree/*:idno[@type="URI"][contains(./text(), $config:uri-base)]/text()}</uri>}</listURI>     
  </taxonomy>
};

declare function csv2subjects:get-broad-matches($broaderConceptsList as node()+, $allSubjectRecords as node()+)
as node()+
{
  for $listUri in $broaderConceptsList
  let $listType := $listUri/@type/string()
  let $broaderUri := $config:uri-base||$listType
  
  let $matches := 
    if($listType = "relationships") then
    for $broader in $listUri/broader
    let $uri := $broader/text()
    let $selfRelationshipType := if($listUri/@includeRelationshipType/string() = "true") then 
      $allSubjectRecords//*:entryFree[*:idno[@type="URI"]/text() = $uri]/*:note[@type="relationshipType"]/@subtype/string()
      else ()
    let $selfRelationshipType := if($selfRelationshipType != "") then attribute {"ana"} {$selfRelationshipType} else ()
    let $self := if($broader/@includeSelf = "true") then element {"uri"} {$selfRelationshipType, $uri} else ()
    let $matchedUris :=
      for $subject in $allSubjectRecords
      (: where there is a skos:broader connection between the current concept and a given record :)
      where $subject//*:entryFree/*:listRelation/*:relation[@ref="http://www.w3.org/2004/02/skos/core#broader"][@passive = $uri]
      let $relation := $subject//*:entryFree/*:listRelation/*:relation[@ref="http://www.w3.org/2004/02/skos/core#broader"][@passive = $uri]
      let $relationshipType := if($listUri/@includeRelationshipType/string() = "true") then $subject//*:entryFree/*:note[@type="relationshipType"]/@subtype/string() else ()
      let $relationshipType := if($relationshipType != "") then attribute {"ana"} {$relationshipType} else ()
      return element {"uri"} {$relationshipType, $relation/@active/string()}
    return ($self, $matchedUris)

    else
      for $subject in $allSubjectRecords
      (: where there is a skos:broader connection between the current concept and a given record :)
      where $subject//*:entryFree/*:listRelation/*:relation[@ref="http://www.w3.org/2004/02/skos/core#broader"][@passive = $broaderUri]
      let $relation := $subject//*:entryFree/*:listRelation/*:relation[@ref="http://www.w3.org/2004/02/skos/core#broader"][@passive = $broaderUri]
      let $relationshipType := if($listUri/@includeRelationshipType/string() = "true") then $subject//*:entryFree/*:note[@type="relationshipType"]/@subtype/string() else ()
      let $relationshipType := if($relationshipType != "") then attribute {"ana"} {$relationshipType} else ()
      return element {"uri"} {$relationshipType, $relation/@active/string()}
  let $matches := for $match in $matches order by $match/text() return $match
  let $matches := functx:distinct-deep($matches)
  return element {"listURI"} {attribute {"type"} {$listType}, $matches}
};