xquery version "3.0";

(:
: Module Name: Unit Tests for csv2persons.xqm
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: Unit tests for functionality in the csv2persons.xqm module
:)

(:~ 
: This module provides unit testing for the csv2persons.xqm module
: @see https://raw.githubusercontent.com/wlpotter/csv-to-srophe/main/modules/csv2persons.xqm
:
: @author William L. Potter
: @version 1.0
:)
module namespace csv2persons-test="http://wlpotter.github.io/ns/csv2persons-test";

import module namespace csv2persons="http://wlpotter.github.io/ns/csv2persons" at "csv2persons.xqm";
import module namespace csv2srophe="http://wlpotter.github.io/ns/csv2srophe" at "csv2srophe.xqm";
import module namespace config="http://wlpotter.github.io/ns/config" at "config.xqm";


declare namespace srophe="https://srophe.app";
declare namespace tei="http://www.tei-c.org/ns/1.0";
(:
trying to test the overall function will require setting up the indices and headermap.
And a fake data row.
:)

(: a tab-separated CSV file :)
declare variable $csv2persons-test:local-csv-uri :=
  $config:nav-base || "in/test/persons_test.csv";

declare variable $csv2persons-test:header-map-stub :=
  csv2srophe:create-header-map($csv2persons-test:local-csv-uri, "	");

declare variable $csv2persons-test:names-index-stub :=
  csv2srophe:create-names-index($csv2persons-test:header-map-stub);

declare variable $csv2persons-test:headword-index-stub :=
  csv2srophe:create-headword-index($csv2persons-test:header-map-stub);

declare variable $csv2persons-test:abstract-index-stub :=
  csv2srophe:create-abstract-index($csv2persons-test:header-map-stub);
  
declare variable $csv2persons-test:sources-index-stub :=
  csv2srophe:create-sources-index(($csv2persons-test:names-index-stub, $csv2persons-test:headword-index-stub, $csv2persons-test:abstract-index-stub));
  
declare variable $csv2persons-test:data-row-to-compare-named :=
  csv2srophe:get-data($csv2persons-test:local-csv-uri, "	")[43];

declare variable $csv2persons-test:data-row-to-compare-anonymi :=
  csv2srophe:get-data($csv2persons-test:local-csv-uri, "	")[138];
 
declare variable $csv2persons-test:sources-index-for-sample-row-named :=
  csv2srophe:create-sources-index-for-row($csv2persons-test:sources-index-stub, $csv2persons-test:data-row-to-compare-named);

declare variable $csv2persons-test:skeleton-record-to-compare-output-named :=
  let $pathToDoc := $config:nav-base || "out/test/person3229-skeleton_test.xml"
  return doc($pathToDoc);
  
declare variable $csv2persons-test:sources-index-for-sample-row-anonymi :=
  csv2srophe:create-sources-index-for-row($csv2persons-test:sources-index-stub, $csv2persons-test:data-row-to-compare-anonymi);


declare variable $csv2persons-test:skeleton-record-to-compare-output-anonymi :=
  let $pathToDoc := $config:nav-base || "out/test/person3774-skeleton_test.xml"
  return doc($pathToDoc);

declare %unit:test function csv2persons-test:is-source-index-named-correct() {
  unit:assert-equals($csv2persons-test:sources-index-for-sample-row-named, "")
};

declare %unit:test function csv2persons-test:is-headword-index-correct() {
  unit:assert-equals(<el>{$csv2persons-test:headword-index-stub}</el>, "")
};

declare %unit:test %unit:ignore function csv2persons-test:create-person-using-anonymi-row() {
  (: won't pass because the change/@when attribute uses fn:current-date() so compare value falls behind if not updated. Need to rewrite test (not tagging %unit:ignore to remind self to update. :)
  unit:assert-equals(csv2persons:create-person-from-row($csv2persons-test:data-row-to-compare-anonymi, $csv2persons-test:header-map-stub, ($csv2persons-test:names-index-stub, $csv2persons-test:headword-index-stub, $csv2persons-test:abstract-index-stub)),
                    $csv2persons-test:skeleton-record-to-compare-output-anonymi)
};

declare %unit:test function csv2persons-test:create-person-using-named-row() {
  (: won't pass because the change/@when element uses fn:current-date() so compare value falls behind if not updated. Need to rewrite test (not tagging %unit:ignore to remind self to update. :)
  unit:assert-equals(csv2persons:create-person-from-row($csv2persons-test:data-row-to-compare-named, $csv2persons-test:header-map-stub, ($csv2persons-test:names-index-stub, $csv2persons-test:headword-index-stub, $csv2persons-test:abstract-index-stub, $csv2persons-test:sources-index-stub)),
                    $csv2persons-test:skeleton-record-to-compare-output-named)
};

declare %unit:test function csv2persons-test:create-unsourced-headword-using-anonymi-row() {
  unit:assert-equals(csv2srophe:build-element-sequence($csv2persons-test:data-row-to-compare-anonymi, $csv2persons-test:headword-index-stub, $csv2persons-test:sources-index-for-sample-row-anonymi, "persName", 0)[1], <persName xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en" xml:id="name3774-1" srophe:tags="#syriaca-headword" resp="http://syriaca.org">Anonymous 3774</persName>)
};

declare %unit:test function csv2persons-test:create-unsourced-headword-using-named-row() {
  (: failing because it is sourced, which is not currently handled by csv2persons:create-headwords. Waiting on https://github.com/wlpotter/csv-to-srophe/issues/19 :)
  unit:assert-equals(csv2srophe:build-element-sequence($csv2persons-test:data-row-to-compare-named, $csv2persons-test:headword-index-stub, $csv2persons-test:sources-index-for-sample-row-named, "persName", 0)[1], <persName xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en" xml:id="name3229-1" srophe:tags="#syriaca-headword" resp="http://syriaca.org">Justin II</persName>)
};

declare %unit:test function csv2persons-test:create-sourced-headword-using-named-row() {
  (: failing because it is sourced, which is not currently handled by csv2persons:create-headwords. Waiting on https://github.com/wlpotter/csv-to-srophe/issues/19 :)
  unit:assert-equals(csv2srophe:build-element-sequence($csv2persons-test:data-row-to-compare-named, $csv2persons-test:headword-index-stub, $csv2persons-test:sources-index-for-sample-row-named, "persName", 0)[2], <persName xmlns="http://www.tei-c.org/ns/1.0" xml:lang="syr" source="#bib3229-1" xml:id="name3229-2" srophe:tags="#syriaca-headword">ܝܘܣܛܝܢܐ</persName>)
};

declare %unit:test function csv2persons-test:create-names-using-named-row() {
  unit:assert-equals(csv2srophe:build-element-sequence($csv2persons-test:data-row-to-compare-named, $csv2persons-test:names-index-stub, $csv2persons-test:sources-index-for-sample-row-named, "persName", 2)[1], 
  <persName xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en" source="#bib3229-3" xml:id="name3229-3">Iustinus</persName>)
};

declare %unit:test function csv2persons-test:create-abstracts-using-named-row() {
  (: see https://github.com/wlpotter/csv-to-srophe/issues/18 :)
  unit:assert-equals(csv2srophe:build-element-sequence($csv2persons-test:data-row-to-compare-named, $csv2persons-test:abstract-index-stub, $csv2persons-test:sources-index-for-sample-row-named, "note", 0)[1], 
<note xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en" type="abstract" xml:id="abstract-en-3229">
<quote source="#bib3229-2">Roman Emperor, successor of Justinian and his sister&apos;s son</quote>.
                    </note>)
};

declare %unit:test function csv2persons-test:create-trait-using-anonymous-row() {
  unit:assert-equals(csv2persons:create-trait($csv2persons-test:data-row-to-compare-anonymi), 
                    <trait xml:lang="en">
                        <label>anonymous</label>
                    </trait>)
};

declare %unit:test function csv2persons-test:create-trait-using-named-row() {
  unit:assert-equals(csv2persons:create-trait($csv2persons-test:data-row-to-compare-named), ())
};