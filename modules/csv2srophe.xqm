xquery version "3.0";

(:
: Module Name: Syriaca.org Data Pipeline CSV Transformations
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This module transforms a CSV file into one or more partial
:                  XML records of entities for use on the Srophe App. These
:                  "skeleton" records are then merged with entity templates
:                  to create TEI-compliant Srophe records.
:)

(:~ 
: This module provides the functions that transform rows of csv data
: into XML snippets that can be merged with entity templates to create
: TEI-compliant Srophe records.
: This module makes use of BaseX's CSV parsing module. It is otherwise
: implementation independent.
: The CSV headers should be formatted as described in the documentation
: @see !!!MISSING LINK TO DOCUMENTATION OF CSV FORMAT
:
: @author William L. Potter
: @version 1.0
:)
module namespace csv2srophe="http://wlpotter.github.io/ns/csv2srophe";


import module namespace config="http://wlpotter.github.io/ns/config" at "config.xqm";

(: note that it makes use of Basex's CSV module. Note also that you should declare output options. :)

(:~ 
: loads a CSV file and returns an xml document
: The returned element is a sequence of XML nodes with the following pattern:
: <record>
:   <firstColumnHeader>cellValue</firstColumnHeader>
:   <secondColumnHeader>cellValue</secondColumnHeader>
: </record>,
: <record>
:   <firstColumnHeader>cellValue</firstColumnHeader>
:   <secondColumnHeader>cellValue</secondColumnHeader>
: </record>
:
:)
declare function csv2srophe:load-csv($url as xs:string,
                                     $delimeter as xs:string,
                                     $header as xs:boolean)
as element()*
{
  let $recordSeq :=  if (starts-with($url, "http")) then
                    csv2srophe:load-csv-remote($url, $delimeter, $header)
                  else
                    csv2srophe:load-csv-local($url, $delimeter, $header)
  return $recordSeq
};

(:~ 
: @see https://github.com/HeardLibrary/digital-scholarship/tree/master/code/file
:)
declare function csv2srophe:load-csv-remote($uri as xs:string,
                                            $delimiter as xs:string,
                                            $header as xs:boolean)
as element()*
{
  let $request := <http:request method='get' href='{$uri}'/>
  let $csvDoc := http:send-request($request)[2] (: ignore initial response element :)
  let $xmlDoc := csv:parse($csvDoc,
                            map { 'header' : $header,'separator' : $delimiter })

  return $xmlDoc/csv/record
};
(:~ 
: Returns a sequence of XML elements representing CSV input data stored at $url
: Returned data looks like:
: <record>
:   <firstColumnHeader>cellValue</firstColumnHeader>
:   <secondColumnHeader>cellValue</secondColumnHeader>
: </record>,
: <record>
:   <firstColumnHeader>cellValue</firstColumnHeader>
:   <secondColumnHeader>cellValue</secondColumnHeader>
: </record>
: @param $url the absolute path to a csv file on the local machine
: :)
declare function csv2srophe:load-csv-local($url as xs:string,
                                           $delimiter as xs:string,
                                            $header as xs:boolean)
as element()*
{
  (: For Windows paths, change "\" to "/" :)
  let $url := fn:replace($url, "\\", "/")
  let $xmlDoc := csv:doc($url,
                         map { 'header' : $header,'separator' : $delimiter })
  return $xmlDoc/csv/record
};
(:
Functions for this module
- get csv data (creates a sequence of rows)
- get csv headers (used in header map creation?)
- create header map

row-specific functions
- create names index
- create abstract index
- create headword index
- get-uri-from-row
- create publication stmt idno?? (or leave for templating)
- creating title from headwords can wait for templating
- creator and respStmts
- revisionDesc creation
- create bibl seq, remove redundant, make bibl elements
- create idno list
- shared note types?
- create skeleton function (and associated building functions)
:)

(: Elements needed from this module

header
- editor[@role="creator"]
-respStmt for creation
- revisionDesc

body
- place/@type (created by a collection-specific extension e.g. csv2places.xqm)
- headwords
- names (specifically placeName, persName, etc. depending)
- abstract
- places need nested locations (csv2places.xqm)
- uri for record as an idno
- other idno list
- notes (incerta, disambiguation, perhaps other shared note types; otherwise farm out to collection-specific functions)
- bibl list

NOTE: The actual placing of the body elements will depend on the entity type

:)