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

import module namespace csv2persons="http://wlpotter.github.io/ns/csv2places" at "csv2persons.xqm";
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
  
declare variable $csv2persons-test:data-row-to-compare-named :=
  csv2srophe:get-data($csv2persons-test:local-csv-uri, "	")[44];

declare variable $csv2persons-test:data-row-to-compare-anonymi :=
  csv2srophe:get-data($csv2persons-test:local-csv-uri, "	")[139];
 
declare variable $csv2persons-test:sources-index-for-sample-row-named :=
  csv2srophe:create-sources-index-for-row($csv2persons-test:data-row-to-compare-named, $csv2persons-test:header-map-stub);

declare variable $csv2persons-test:skeleton-record-to-compare-output-named :=
  let $pathToDoc := $config:nav-base || "out/test/person3229-skeleton_test.xml"
  return doc($pathToDoc);
  
declare variable $csv2persons-test:sources-index-for-sample-row-anonymi :=
  csv2srophe:create-sources-index-for-row($csv2persons-test:data-row-to-compare-anonymi, $csv2persons-test:header-map-stub);


declare variable $csv2persons-test:skeleton-record-to-compare-output-anonymi :=
  let $pathToDoc := $config:nav-base || "out/test/person3774-skeleton_test.xml"
  return doc($pathToDoc);
  
