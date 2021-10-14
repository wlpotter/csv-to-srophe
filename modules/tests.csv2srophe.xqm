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
  
declare variable $csv2srophe-test:header-map-node-to-compare :=
<map>
  <string>New place/add data</string>
  <name>New_place_add_data</name>
</map>;

declare variable $csv2srophe-test:header-map-from-local-csv :=
  csv2srophe:create-header-map($csv2srophe-test:local-csv-uri, "	");
  
declare variable $csv2srophe-test:names-index-node-to-compare :=
<name>
  <langCode>syr</langCode>
  <textNodeColumnElementName>name3.syr</textNodeColumnElementName>
  <sourceUriElementName>sourceURI.name3</sourceUriElementName>
  <pagesElementName>pages.name3</pagesElementName>
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
  <pagesElementName>pages.abstract.en</pagesElementName>
</abstract>;

declare variable $csv2srophe-test:data-row-to-compare :=
  csv2srophe:get-data($csv2srophe-test:local-csv-uri, "	")[3];
 
declare variable $csv2srophe-test:sources-index-node-to-compare :=
<source>
  <uri>http://syriaca.org/bibl/667</uri>
  <pg>318</pg>
</source>;

declare variable $csv2srophe-test:bibl-node-to-compare :=
<bibl xmlns="http://www.tei-c.org/ns/1.0" xml:id="bib3059-2">
  <ptr target="http://syriaca.org/bibl/667"/>
  <citedRange unit="p">318</citedRange>
</bibl>;

declare variable $csv2srophe-test:idno-node-to-compare :=
<idno xmlns="http://www.tei-c.org/ns/1.0" type="URI">https://pleiades.stoa.org/places/test</idno>;

declare variable $csv2srophe-test:self-idno-node-to-compare :=
<idno xmlns="http://www.tei-c.org/ns/1.0" type="URI">http://syriaca.org/place/3059</idno>;

declare variable $csv2srophe-test:revisionDesc-from-config :=
<revisionDesc xmlns="http://www.tei-c.org/ns/1.0" status="draft">
  {$config:change-log}
</revisionDesc>;


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
  unit:assert-equals(csv2srophe:create-sources-index-for-row($csv2srophe-test:data-row-to-compare,
                                    $csv2srophe-test:header-map-from-local-csv)[2],
                     $csv2srophe-test:sources-index-node-to-compare)
};

declare %unit:test function csv2srophe-test:create-bibl-sequence-for-row-from-local-csv()
{
  unit:assert-equals(csv2srophe:create-bibl-sequence($csv2srophe-test:data-row-to-compare,
                                    $csv2srophe-test:header-map-from-local-csv)[2],
                    $csv2srophe-test:bibl-node-to-compare)
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
  <desc xmlns="http://www.tei-c.org/ns/1.0" type="abstract" xml:id="abstract3059-1" xml:lang="en" source="#bib3059-3">Lorem ipsum</desc>)
};

declare %unit:test function csv2srophe-test:build-abstract-element-as-note-with-no-source()
{
  unit:assert-equals(csv2srophe:build-abstract-element("Lorem ipsum", "note", "3059", "en", "", 1),
  <note xmlns="http://www.tei-c.org/ns/1.0" type="abstract" xml:id="abstract3059-1" xml:lang="en" resp="http://syriaca.org">Lorem ipsum</note>)
};