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

(: a tab-separated CSV file :)
declare variable $csv2srophe-test:local-csv-uri :=
  $config:nav-base || "in/test/test.csv";
  
declare variable $csv2srophe-test:header-map-node-to-compare :=
<map>
  <string>New place/add data</string>
  <name>New_place_add_data</name>
</map>;
  
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

