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
 
(: add variable for test output of the resultant skeleton record :)


declare %unit:ignore %unit:test function  csv2places-test:build-place-node-from-row(){
  
};

declare %unit:test function csv2places-test:get-place-type-from-row-using-local-csv() {
  unit:assert-equals(csv2places:get-place-type-from-row($csv2places-test:data-row-to-compare), "monastery")
};

