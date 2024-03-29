xquery version "3.0";

(:
: Module Name: Unit Tests for csv2srophe.xqm
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: Unit tests for functionality in the csv2srophe.xqm module
:)

(:~ 
: This module provides unit testing for the csv2srophe.xqm module
: @see https://raw.githubusercontent.com/wlpotter/csv-to-srophe/main/modules/csv2srophe.xqm?token=AKQNYWV3AWGARSYQ2P33IOLBMCCQE
: NOTE: only need token while private repository.
:
: @author William L. Potter
: @version 1.0
:)
module namespace csv2srophe-test="http://wlpotter.github.io/ns/csv2srophe-test";


import module namespace csv2srophe="http://wlpotter.github.io/ns/csv2srophe" at "csv2srophe.xqm";
import module namespace config="http://wlpotter.github.io/ns/config" at "config.xqm";


declare namespace srophe="https://srophe.app";

(: a tab-separated CSV file :)
declare variable $csv2srophe-test:local-csv-uri :=
  $config:nav-base || "in/test/test.csv";
  
declare variable $csv2srophe-test:local-csv-uri-persons :=
  $config:nav-base || "in/test/persons_test.csv";
  
declare variable $csv2srophe-test:header-map-node-to-compare :=
<map>
  <string>New place/add data</string>
  <name>New_place_add_data</name>
</map>;

declare variable $csv2srophe-test:header-map-from-local-csv :=
  csv2srophe:create-header-map($csv2srophe-test:local-csv-uri, "	");
  
declare variable $csv2srophe-test:header-map-from-local-csv-persons :=
  csv2srophe:create-header-map($csv2srophe-test:local-csv-uri-persons, "	");

declare variable $csv2srophe-test:names-index-node-to-compare :=
<name>
  <langCode>syr</langCode>
  <textNodeColumnElementName>name3.syr</textNodeColumnElementName>
  <sourceUriElementName>sourceURI.name3</sourceUriElementName>
  <citedRangeElementName>citedRange.name3</citedRangeElementName>
</name>;

declare variable $csv2srophe-test:headword-index-node-to-compare :=
<headword>
  <langCode>syr</langCode>
  <textNodeColumnElementName>headword.syr</textNodeColumnElementName>
</headword>;

declare variable $csv2srophe-test:abstract-index-node-to-compare :=
<abstract>
  <langCode>en</langCode>
  <textNodeColumnElementName>abstract.en</textNodeColumnElementName>
  <sourceUriElementName>sourceURI.abstract.en</sourceUriElementName>
  <citedRangeElementName>citedRange.abstract.en</citedRangeElementName>
</abstract>;

declare variable $csv2srophe-test:anonymousDesc-index-node-to-compare :=
<anonymousDesc>
  <langCode>en</langCode>
  <textNodeColumnElementName>anonymousDesc.en</textNodeColumnElementName>
</anonymousDesc>;

declare variable $csv2srophe-test:sex-index-node-to-compare :=
<sex>
  <textNodeColumnElementName>sex1</textNodeColumnElementName>
  <sourceUriElementName>sourceUri.sex1</sourceUriElementName>
  <citedRangeElementName>citedRange.sex1</citedRangeElementName>
  <citationUnitElementName>citationUnit.sex1</citationUnitElementName>
</sex>;

declare variable $csv2srophe-test:dates-index-node-to-compare :=
<date>
  <textNodeColumnElementName>date1</textNodeColumnElementName>
  <sourceUriElementName>sourceUri.date1</sourceUriElementName>
  <citedRangeElementName>citedRange.date1</citedRangeElementName>
  <citationUnitElementName>citationUnit.date1</citationUnitElementName>
  <whenElementName>when.date1</whenElementName>
  <notBeforeElementName>notBefore.date1</notBeforeElementName>
  <notAfterElementName>notAfter.date1</notAfterElementName>
  <typeElementName>type.date1</typeElementName>
</date>;
          
declare variable $csv2srophe-test:relations-index-node-to-compare-persons :=
<relation>
  <type>possiblyIdentical</type>
  <textNodeColumnElementName>relation1.possiblyIdentical</textNodeColumnElementName>
</relation>;

declare variable $csv2srophe-test:data-row-to-compare :=
  csv2srophe:get-data($csv2srophe-test:local-csv-uri, "	")[3];
  
declare variable $csv2srophe-test:data-row-to-compare-persons :=
  csv2srophe:get-data($csv2srophe-test:local-csv-uri-persons, "	")[138];
 
declare variable $csv2srophe-test:sources-index-node-to-compare-single :=
<source>
  <sourceUri>http://syriaca.org/bibl/669</sourceUri>
  <citedRange>283</citedRange>
</source>;

declare variable $csv2srophe-test:sources-index-node-to-compare-multiple-cited-range :=
<source>
  <sourceUri>http://syriaca.org/bibl/669</sourceUri>
  <citedRange>283#Test</citedRange>
  <citationUnit>p#entry</citationUnit>
</source>;

declare variable $csv2srophe-test:bibl-node-to-compare-single :=
<bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="bib3059-1">
  <ptr target="http://syriaca.org/bibl/669"/>
  <citedRange unit="p">283</citedRange>
</bibl>;

declare variable $csv2srophe-test:idno-node-to-compare :=
<idno xmlns="http://www.tei-c.org/ns/1.0" type="URI">https://pleiades.stoa.org/places/test</idno>;

declare variable $csv2srophe-test:self-idno-node-to-compare :=
<idno xmlns="http://www.tei-c.org/ns/1.0" type="URI">http://syriaca.org/place/3059</idno>;

declare variable $csv2srophe-test:revisionDesc-from-config :=
<revisionDesc xmlns="http://www.tei-c.org/ns/1.0" status="draft">
  {$config:change-log}
</revisionDesc>;

declare variable $csv2srophe-test:populated-names-index-to-compare :=
<name>
  <langCode>syr</langCode>
  <textNode>ܕܝܪܐ ܕܒܛܐܓܐܝܣ</textNode>
  <sourceUri>http://syriaca.org/bibl/667</sourceUri>
  <citedRange>318</citedRange>
</name>;

declare variable $csv2srophe-test:sources-index-node-to-compare :=
<source>
  <sourceUriElementName>sourceURI.abstract.en</sourceUriElementName>
  <citedRangeElementName>citedRange.abstract.en</citedRangeElementName>
</source>;

declare variable $csv2srophe-test:listRelation-node-to-compare-possibly-identical-persons :=
<listRelation xmlns="http://www.tei-c.org/ns/1.0">
  <relation name="possibly-identical" mutual="http://syriaca.org/person/3774 http://syriaca.org/person58 http://syriaca.org/person/2476 http://syriaca.org/person/2717 http://syriaca.org/person/2718" resp="http://syriaca.org">
    <desc xml:lang="en">This person is possibly identical with the person represented in another record</desc>
  </relation>
</listRelation>;

declare %unit:test function csv2srophe-test:load-csv-with-a-local-file()
{
  (: tests that the text node of the uri of the first data row is 3058 :)
  unit:assert-equals(string(csv2srophe:load-csv($csv2srophe-test:local-csv-uri,
                                         "	",
                                         true ())[1]/uri/text()),
                     "3058")
};

declare %unit:test function csv2srophe-test:get-column-headers-from-local-file()
{
  (: tests that the third column header is the string "Possible URI":)
  unit:assert-equals(string(csv2srophe:get-csv-column-headers($csv2srophe-test:local-csv-uri,
                                         "	")[3]),
                     "Possible URI")
};

declare %unit:test function csv2srophe-test:get-data-from-local-file()
{
  (: tests that the first record's name2.en was correctly constructed :)
  unit:assert-equals(csv2srophe:get-data($csv2srophe-test:local-csv-uri,
                                         "	")[1]/name2.en,
                     <name2.en>Trabzon</name2.en>)
};

declare %unit:test function csv2srophe-test:create-header-map-from-local-file()
{
  (: tests correct construction of header map node(s) :)
  unit:assert-equals(csv2srophe:create-header-map($csv2srophe-test:local-csv-uri,
                                         "	")[1],
                     $csv2srophe-test:header-map-node-to-compare)
};
(:  test load from remote :)
(: test that load from remote and load locally of the same file produce equiv results :)

declare %unit:test function csv2srophe-test:create-names-index-from-local-place-file()
{
  (: tests correct construction of names index node(s) :)
  unit:assert-equals(csv2srophe:create-names-index($csv2srophe-test:header-map-from-local-csv)[3],
                      $csv2srophe-test:names-index-node-to-compare)
};

declare %unit:test function csv2srophe-test:create-headword-index-from-local-place-file()
{
  (: tests correct construction of headword index node(s) :)
  unit:assert-equals(csv2srophe:create-headword-index($csv2srophe-test:header-map-from-local-csv)[2],
                      $csv2srophe-test:headword-index-node-to-compare)
};

declare %unit:test function csv2srophe-test:create-abstract-index-from-local-place-file()
{
  (: tests correct construction of abstract index node(s) :)
  unit:assert-equals(csv2srophe:create-abstract-index($csv2srophe-test:header-map-from-local-csv)[1],
                      $csv2srophe-test:abstract-index-node-to-compare)
};

declare  %unit:test function csv2srophe-test:get-uri-from-row-with-uri-base()
{
  unit:assert-equals(csv2srophe:get-uri-from-row($csv2srophe-test:data-row-to-compare,
                                                 "http://syriaca.org/place/"),
                     "http://syriaca.org/place/3059")
};

declare  %unit:test function csv2srophe-test:get-uri-from-row-no-uri-base()
{
  unit:assert-equals(csv2srophe:get-uri-from-row($csv2srophe-test:data-row-to-compare,
                                                 ""),
                     "3059")
};

declare  %unit:test function csv2srophe-test:create-sources-index-for-row-from-local-csv()
{
  unit:assert-equals(csv2srophe:create-sources-index-for-row($csv2srophe-test:sources-index-node-to-compare,
                                    $csv2srophe-test:data-row-to-compare)[1],
                     $csv2srophe-test:sources-index-node-to-compare-single)
};

declare %unit:test function csv2srophe-test:create-bibl-sequence-for-row-from-local-csv()
{
  unit:assert-equals(csv2srophe:create-bibl-sequence($csv2srophe-test:data-row-to-compare,
                                    $csv2srophe-test:sources-index-node-to-compare-single)[1],
                    $csv2srophe-test:bibl-node-to-compare-single)
};

declare %unit:test function csv2srophe-test:create-idno-sequence-for-row-check-self-idno()
{ (: tests that the idno element for the entity record was created correctly :)
  unit:assert-equals(csv2srophe:create-idno-sequence-for-row($csv2srophe-test:data-row-to-compare,
                                                             "http://syriaca.org/place/")[1],
                     $csv2srophe-test:self-idno-node-to-compare)
};

declare %unit:test function csv2srophe-test:create-idno-sequence-for-row-check-other-idno()
{ (: tests that the other idno elements were created correctly :)
  unit:assert-equals(csv2srophe:create-idno-sequence-for-row($csv2srophe-test:data-row-to-compare,
                                                              "http://syriaca.org/place/")[2],
                     $csv2srophe-test:idno-node-to-compare)
};

declare %unit:test function csv2srophe-test:build-editor-node() 
{
  unit:assert-equals(csv2srophe:build-editor-node("http://syriaca.org/documentation/editors.xml#wpotter", "William L. Potter", "creator"),
                     <editor xmlns="http://www.tei-c.org/ns/1.0" role="creator" ref="http://syriaca.org/documentation/editors.xml#wpotter">William L. Potter</editor>)
};

declare %unit:test function csv2srophe-test:build-respStmt() 
{
  unit:assert-equals(csv2srophe:build-respStmt-node("http://syriaca.org/documentation/editors.xml#wpotter", "William L. Potter", "URI minted and initial data collected by"),
  <respStmt xmlns="http://www.tei-c.org/ns/1.0"><resp>URI minted and initial data collected by</resp><name ref="http://syriaca.org/documentation/editors.xml#wpotter">William L. Potter</name></respStmt>)
};

declare %unit:test function csv2srophe-test:build-revisionDesc-from-config()
{
  unit:assert-equals(csv2srophe:build-revisionDesc($config:change-log, "draft"), 
                     $csv2srophe-test:revisionDesc-from-config)
};

declare %unit:test function csv2srophe-test:build-name-element-placeName-headword-english() 
{
  unit:assert-equals(csv2srophe:build-name-element("Edessa", "placeName", "78", "en", "", true (), 1),
  <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en" xml:id="name78-1" srophe:tags="#syriaca-headword" resp="http://syriaca.org">Edessa</placeName>)
};

declare %unit:test function csv2srophe-test:build-name-element-placeName-english() 
{
  unit:assert-equals(csv2srophe:build-name-element("Edessa", "placeName", "78", "en", "bib78-3", false (), 4),
  <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en" xml:id="name78-4" source="#bib78-3">Edessa</placeName>)
};

declare %unit:test function csv2srophe-test:build-name-element-taxonomy-headword-english() 
{
  unit:assert-equals(csv2srophe:build-name-element("Afterlife", "term", "afterlife", "en", "", true (), 1),
  <term xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en" xml:id="name-afterlife-en" srophe:tags="#syriaca-headword" resp="http://syriaca.org">Afterlife</term>)
};

declare %unit:test function csv2srophe-test:build-name-element-taxonomy-regular-name-english() 
{
  unit:assert-equals(csv2srophe:build-name-element("Afterlife", "gloss", "afterlife", "en", "", false (), 3),
  <gloss xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en" resp="http://syriaca.org">Afterlife</gloss>)
};

declare %unit:test function csv2srophe-test:build-abstract-element-as-desc-with-source()
{
  unit:assert-equals(csv2srophe:build-abstract-element("Lorem ipsum", "desc", "3059", "en", "bib3059-3", 1),
  <desc xmlns="http://www.tei-c.org/ns/1.0" type="abstract" xml:id="abstract3059-1" xml:lang="en"><quote source="#bib3059-3">Lorem ipsum</quote></desc>)
};

declare %unit:test function csv2srophe-test:build-abstract-element-as-note-with-no-source()
{
  unit:assert-equals(csv2srophe:build-abstract-element("Lorem ipsum", "note", "3059", "en", "", 1),
  <note xmlns="http://www.tei-c.org/ns/1.0" type="abstract" xml:id="abstract3059-1" xml:lang="en" resp="http://syriaca.org">Lorem ipsum</note>)
};

declare %unit:test function csv2srophe-test:populate-index-from-row-using-names-index() 
{
  unit:assert-equals(csv2srophe:populate-index-from-row($csv2srophe-test:names-index-node-to-compare, $csv2srophe-test:data-row-to-compare), $csv2srophe-test:populated-names-index-to-compare)
};

declare %unit:test function csv2srophe-test:create-sources-index-from-local-csv()
{
  unit:assert-equals(csv2srophe:create-sources-index(($csv2srophe-test:names-index-node-to-compare, $csv2srophe-test:abstract-index-node-to-compare))[2], $csv2srophe-test:sources-index-node-to-compare)
};

declare %unit:test function csv2srophe-test:populate-index-from-row-using-sources-index()
{
  unit:assert-equals(csv2srophe:populate-index-from-row($csv2srophe-test:sources-index-node-to-compare, $csv2srophe-test:data-row-to-compare), $csv2srophe-test:sources-index-node-to-compare-single)
};

declare %unit:test function csv2srophe-test:create-sex-index-from-local-csv()
{
  unit:assert-equals(csv2srophe:create-sex-index($csv2srophe-test:header-map-from-local-csv-persons), $csv2srophe-test:sex-index-node-to-compare)(: add variable for persons-input; add variable for :)
};

declare %unit:test function csv2srophe-test:create-dates-index-from-local-csv()
{
  unit:assert-equals(csv2srophe:create-dates-index($csv2srophe-test:header-map-from-local-csv-persons), $csv2srophe-test:dates-index-node-to-compare)
};

declare %unit:test function csv2srophe-test:create-date-element-from-local-csv()
{
  unit:assert-equals(csv2srophe:build-element-sequence($csv2srophe-test:data-row-to-compare-persons, $csv2srophe-test:dates-index-node-to-compare, $csv2srophe-test:sources-index-node-to-compare-single, "date", 0), <floruit xmlns="http://www.tei-c.org/ns/1.0" resp="http://syriaca.org" notBefore="500" notAfter="550">early 6th century</floruit>)
};

declare %unit:test function csv2srophe-test:create-citedRange-element-from-stub()
{
  unit:assert-equals(csv2srophe:create-citedRange-element("228#Test", "p#entry")[2], <citedRange xmlns="http://www.tei-c.org/ns/1.0" unit="entry">Test</citedRange>)
};

declare %unit:test function csv2srophe-test:create-bibl-sequence-with-multiple-citation-units()
{
  unit:assert-equals(csv2srophe:create-bibl-sequence($csv2srophe-test:data-row-to-compare-persons, $csv2srophe-test:sources-index-node-to-compare-multiple-cited-range),
  <bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="bib3774-1">
            <ptr target="http://syriaca.org/bibl/669"/>
            <citedRange unit="p">283</citedRange>
            <citedRange unit="entry">Test</citedRange>
          </bibl>)
};

declare %unit:test function csv2srophe-test:create-anonymousDesc-index-from-local-csv()
{
  unit:assert-equals(csv2srophe:create-anonymousDesc-index($csv2srophe-test:header-map-from-local-csv-persons), $csv2srophe-test:anonymousDesc-index-node-to-compare)
};

declare %unit:test function csv2srophe-test:build-relationsIndex-from-local-csv()
{
  unit:assert-equals(csv2srophe:create-relations-index($csv2srophe-test:header-map-from-local-csv-persons), $csv2srophe-test:relations-index-node-to-compare-persons)
};

declare %unit:test function csv2srophe-test:build-listRelation-element-no-relations()
(: should return empty :)
{
  unit:assert-equals(csv2srophe:build-listRelation-element($csv2srophe-test:data-row-to-compare, $csv2srophe-test:relations-index-node-to-compare-persons, $csv2srophe-test:sources-index-node-to-compare-multiple-cited-range), ())
};

declare %unit:test function csv2srophe-test:build-listRelation-element-has-relations()

{
  unit:assert-equals(csv2srophe:build-listRelation-element($csv2srophe-test:data-row-to-compare-persons, $csv2srophe-test:relations-index-node-to-compare-persons, $csv2srophe-test:sources-index-node-to-compare-multiple-cited-range), $csv2srophe-test:listRelation-node-to-compare-possibly-identical-persons)
};