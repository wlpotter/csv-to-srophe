xquery version "3.0";

(:
: Module Name: Unit Tests for csv2subjects.xqm
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: Unit tests for functionality in the csv2subjects.xqm module
:)

(:~ 
: This module provides unit testing for the csv2subjects.xqm module
: @see https://raw.githubusercontent.com/wlpotter/csv-to-srophe/main/modules/csv2subjects.xqm
:
: @author William L. Potter
: @version 1.0
:)
module namespace csv2subjects-test="http://wlpotter.github.io/ns/csv2subjects-test";

import module namespace csv2subjects="http://wlpotter.github.io/ns/csv2subjects" at "csv2subjects.xqm";
import module namespace csv2srophe="http://wlpotter.github.io/ns/csv2srophe" at "csv2srophe.xqm";
import module namespace config="http://wlpotter.github.io/ns/config" at "config.xqm";


declare namespace srophe="https://srophe.app";
declare namespace tei="http://www.tei-c.org/ns/1.0";
(:
trying to test the overall function will require setting up the indices and headermap.
And a fake data row.
:)

(: a tab-separated CSV file :)
declare variable $csv2subjects-test:local-csv-uri :=
  $config:nav-base || "in/test/taxonomy_test.csv";

declare variable $csv2subjects-test:header-map-stub :=
  csv2srophe:create-header-map($csv2subjects-test:local-csv-uri, "	");

declare variable $csv2subjects-test:names-index-stub :=
  csv2srophe:create-names-index($csv2subjects-test:header-map-stub);

declare variable $csv2subjects-test:headword-index-stub :=
  csv2srophe:create-headword-index($csv2subjects-test:header-map-stub);

declare variable $csv2subjects-test:abstract-index-stub :=
  csv2srophe:create-abstract-index($csv2subjects-test:header-map-stub);

declare variable $csv2subjects-test:relations-index-stub :=
  csv2srophe:create-relations-index($csv2subjects-test:header-map-stub);
        
declare variable $csv2subjects-test:sources-index-stub :=
  csv2srophe:create-sources-index(($csv2subjects-test:names-index-stub, $csv2subjects-test:headword-index-stub, $csv2subjects-test:abstract-index-stub, $csv2subjects-test:relations-index-stub));
  
declare variable $csv2subjects-test:data-row-to-compare :=
  csv2srophe:get-data($csv2subjects-test:local-csv-uri, "	")[14];

 
declare variable $csv2subjects-test:sources-index-for-sample-row :=
  csv2srophe:create-sources-index-for-row($csv2subjects-test:sources-index-stub, $csv2subjects-test:data-row-to-compare);

declare variable $csv2subjects-test:skeleton-record-to-compare-output :=
  let $pathToDoc := $config:nav-base || "out/test/subjectsAfterlife-skeleton_test.xml"
  return doc($pathToDoc);
  

declare %unit:test function csv2subjects-test:create-person-using-anonymi-row() {
  (: won't pass because the change/@when attribute uses fn:current-date() so compare value falls behind if not updated. Need to rewrite test (not tagging %unit:ignore to remind self to update. :)
  unit:assert-equals(csv2subjects:create-subject-from-row($csv2subjects-test:data-row-to-compare, $csv2subjects-test:header-map-stub, ($csv2subjects-test:names-index-stub, $csv2subjects-test:headword-index-stub, $csv2subjects-test:abstract-index-stub, $csv2subjects-test:relations-index-stub, $csv2subjects-test:sources-index-stub)),
                    $csv2subjects-test:skeleton-record-to-compare-output)
};

declare %unit:test function csv2subjects-test:create-headword-term-elements() {
  unit:assert-equals(csv2srophe:build-element-sequence($csv2subjects-test:data-row-to-compare, $csv2subjects-test:headword-index-stub, $csv2subjects-test:sources-index-for-sample-row, "term", 0)[1], <term xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en" xml:id="name-afterlife-en" srophe:tags="#syriaca-headword">Afterlife</term>)
};

declare %unit:test function csv2subjects-test:create-name-gloss-elements() {
  unit:assert-equals(csv2srophe:build-element-sequence($csv2subjects-test:data-row-to-compare, $csv2subjects-test:names-index-stub, $csv2subjects-test:sources-index-for-sample-row, "gloss", 2)[1], $csv2subjects-test:skeleton-record-to-compare-output//tei:entryFree/tei:gloss[3])
};

declare %unit:test function csv2subjects-test:create-abstracts-note-elements() {
  unit:assert-equals(csv2srophe:build-element-sequence($csv2subjects-test:data-row-to-compare, $csv2subjects-test:abstract-index-stub, $csv2subjects-test:sources-index-for-sample-row, "note", 0)[1], $csv2subjects-test:skeleton-record-to-compare-output//tei:entryFree/tei:note[1])
};

(:
Other needed tests

- deleting unneeded @resp attributes?
- proper creation of non-URI idno elements
- proper creation of skos:broadMatch relation elements


:)
