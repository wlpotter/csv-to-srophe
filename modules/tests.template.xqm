xquery version "3.0";

(:
: Module Name: Unit Tests for template.xqm
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: Unit tests for functionality in the template.xqm module
:)

(:~ 
: This module provides unit testing for the csv2srophe.xqm module
: @see 
: NOTE: only need token while private repository.
:
: @author William L. Potter
: @version 1.0
:)
module namespace template-test="http://wlpotter.github.io/ns/template-test";


import module namespace template="http://wlpotter.github.io/ns/template" at "template.xqm";
import module namespace config="http://wlpotter.github.io/ns/config" at "config.xqm";


declare namespace srophe="https://srophe.app";


declare variable $template-test:record-to-merge :=
  let $pathToDoc := $config:nav-base || "out/test/place3059-skeleton_test.xml"
  return doc($pathToDoc);

declare variable $template-test:output-record-to-compare :=
  let $pathToDoc := $config:nav-base || "out/test/place3059-full_test.xml"
  return doc($pathToDoc);

declare variable $template-test:template-to-compare :=
  let $pathToDoc := $config:nav-base || "templates/places-template.xml"
  return doc($pathToDoc);
  
declare %unit:test function template-test:create-record-title-from-headwords-one-base-one-foreign()
{
  unit:assert-equals(template:create-record-title-from-headwords((<el xml:lang="en">test</el>, <el xml:lang="syr">test</el>), "en"), 
  <title xmlns="http://www.tei-c.org/ns/1.0" level="a" xml:lang="en">test - <foreign xml:lang="syr">test</foreign>
          </title>)
};

declare %unit:test function template-test:create-record-title-from-headwords-two-base-one-foreign()
{
  unit:assert-equals(template:create-record-title-from-headwords((<el xml:lang="en">test</el>, <el xml:lang="en">also test</el>, <el xml:lang="syr">test</el>), "en"), 
  <title xmlns="http://www.tei-c.org/ns/1.0" level="a" xml:lang="en">test - also test - <foreign xml:lang="syr">test</foreign>
          </title>)
};

declare %unit:test function template-test:create-record-title-from-headwords-one-base-two-foreign()
{
  unit:assert-equals(template:create-record-title-from-headwords((<el xml:lang="en">test</el>, <el xml:lang="syr">also test</el>, <el xml:lang="syr">test</el>), "en"), 
  <title xmlns="http://www.tei-c.org/ns/1.0" level="a" xml:lang="en">test - <foreign xml:lang="syr">also test</foreign> - <foreign xml:lang="syr">test</foreign>
          </title>)
};

declare %unit:test function template-test:create-record-title-from-headwords-in-test-record()
{
  unit:assert-equals(template:create-record-title-from-headwords($template-test:record-to-merge//*[@srophe:tags="#syriaca-headword"], "en"), 
  <title xmlns="http://www.tei-c.org/ns/1.0" level="a" xml:lang="en">Monastery at Tagais - <foreign xml:lang="syr">ܕܝܪܐ ܕܒܛܐܓܐܝܣ</foreign>
          </title>)
};

declare %unit:test function template-test:merge-record-into-template-from-stub()
{ (: this should be working, maybe just whitespace?:)
  unit:assert-equals(template:merge-record-into-template($template-test:record-to-merge, $template-test:template-to-compare, "http://syriaca.org/place/3059"),
                                                         $template-test:output-record-to-compare)
};