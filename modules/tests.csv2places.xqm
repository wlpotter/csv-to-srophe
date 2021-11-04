xquery version "3.0";

(:
: Module Name: Unit Tests for csv2places.xqm
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: Unit tests for functionality in the csv2places.xqm module
:)

(:~ 
: This module provides unit testing for the csv2places.xqm module
: @see https://raw.githubusercontent.com/wlpotter/csv-to-srophe/main/modules/csv2places.xqm?token=AKQNYWVTOP6GWJVEWZHALYTBMWB4K
: NOTE: only need token while private repository.
:
: @author William L. Potter
: @version 1.0
:)
module namespace csv2places-test="http://wlpotter.github.io/ns/csv2places-test";


import module namespace csv2srophe="http://wlpotter.github.io/ns/csv2srophe" at "csv2srophe.xqm";
import module namespace csv2places="http://wlpotter.github.io/ns/csv2places" at "csv2places.xqm";
import module namespace config="http://wlpotter.github.io/ns/config" at "config.xqm";


declare namespace srophe="https://srophe.app";
declare namespace tei="http://www.tei-c.org/ns/1.0";
(:
trying to test the overall function will require setting up the indices and headermap.
And a fake data row.
:)

(: a tab-separated CSV file :)
declare variable $csv2places-test:local-csv-uri :=
  $config:nav-base || "in/test/test.csv";

declare variable $csv2places-test:header-map-stub :=
  csv2srophe:create-header-map($csv2places-test:local-csv-uri, "	");

declare variable $csv2places-test:names-index-stub :=
  csv2srophe:create-names-index($csv2places-test:header-map-stub);

declare variable $csv2places-test:headword-index-stub :=
  csv2srophe:create-headword-index($csv2places-test:header-map-stub);

declare variable $csv2places-test:abstract-index-stub :=
  csv2srophe:create-abstract-index($csv2places-test:header-map-stub);
  
declare variable $csv2places-test:data-row-to-compare :=
  csv2srophe:get-data($csv2places-test:local-csv-uri, "	")[3];
 
declare variable $csv2places-test:sources-index-for-sample-row :=
  csv2srophe:create-sources-index-for-row($csv2places-test:data-row-to-compare, $csv2places-test:header-map-stub);
(: add variable for test output of the resultant skeleton record :)

declare variable $csv2places-test:skeleton-record-to-compare-output :=
  let $pathToDoc := $config:nav-base || "out/test/place3059-skeleton_test.xml"
  return doc($pathToDoc);

declare %unit:test function csv2places-test:create-place-from-row-using-test-row() {
  (: won't pass because the change/@when element uses fn:current-date() so compare value falls behind if not updated. Need to rewrite test (not tagging %unit:ignore to remind self to update. :)
  unit:assert-equals(csv2places:create-place-from-row($csv2places-test:data-row-to-compare, $csv2places-test:header-map-stub, ($csv2places-test:names-index-stub, $csv2places-test:headword-index-stub, $csv2places-test:abstract-index-stub)),
                    $csv2places-test:skeleton-record-to-compare-output)
};

declare %unit:test function  csv2places-test:build-place-node-from-row(){
  (: won't pass because the function outputs xmlns:srophe="https://srophe.app" on the tei:placeNames with srophe:tags="#syriaca-headword". This does not appear on the expected value. Perhaps add it? Need to rewrite test (not tagging %unit:ignore to remind self to update). :)
    unit:assert-equals(csv2places:build-place-node-from-row($csv2places-test:data-row-to-compare, $csv2places-test:header-map-stub, ($csv2places-test:names-index-stub, $csv2places-test:headword-index-stub, $csv2places-test:abstract-index-stub)),
                       $csv2places-test:skeleton-record-to-compare-output//tei:place)
};

declare %unit:test function csv2places-test:get-place-type-from-row-using-local-csv() {
  unit:assert-equals(csv2places:get-place-type-from-row($csv2places-test:data-row-to-compare), "monastery")
};

declare %unit:test function csv2places-test:create-headwords-from-local-csv-data() {
  unit:assert-equals(csv2srophe:build-name-element-sequence($csv2places-test:data-row-to-compare, $csv2places-test:headword-index-stub, $csv2places-test:sources-index-for-sample-row, "placeName", true (), 0)[2], 
                    <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:lang="syr" xml:id="name3059-2" srophe:tags="#syriaca-headword" resp="http://syriaca.org">ܕܝܪܐ ܕܒܛܐܓܐܝܣ</placeName>)
};

declare %unit:test function csv2places-test:create-names-from-local-csv-data() {
  unit:assert-equals(csv2srophe:build-name-element-sequence($csv2places-test:data-row-to-compare, $csv2places-test:names-index-stub, $csv2places-test:sources-index-for-sample-row, "placeName", false (), 2)[1], 
  <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:lang="syr" xml:id="name3059-3" source="#bib3059-2">ܕܝܪܐ ܕܒܛܐܓܐܝܣ</placeName>)
};

declare %unit:test function csv2places-test:create-abstracts-from-local-csv-data() {
  unit:assert-equals(csv2places:create-abstracts($csv2places-test:data-row-to-compare, $csv2places-test:abstract-index-stub, $csv2places-test:sources-index-for-sample-row)[1], 
  <desc xmlns="http://www.tei-c.org/ns/1.0" type="abstract" xml:id="abstract3059-1" xml:lang="en" source="#bib3059-1">A monastery at Tagais</desc>)
};

declare %unit:test function csv2places-test:create-nested-locations-from-local-csv-data() {
  unit:assert-equals(csv2places:create-nested-locations($csv2places-test:data-row-to-compare, $csv2places-test:sources-index-for-sample-row)[1], 
  <location xmlns="http://www.tei-c.org/ns/1.0" type="nested" source="#bib3059-1">
    <settlement ref="http://syriaca.org/place/1475"/>
  </location>)
};
