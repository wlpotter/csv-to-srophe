xquery version "3.0";

(:
: Module Name: Syriaca.org Taxonomy Index Generator
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This main module transforms creates an xml file
:                  representing the taxonomy index for use in the
:                  Srophe Application.
:)

(:~ 
: Based on the configuration in config.xml and config-taxonomy.xml, this 
: main driver script takes a series of TEI XML records representing keywords
: and returns an XML file representing a taxonomy outline of keywords,
: based upon the broader relationships selected in config-taxonomy.xml and
: expressed in the TEI data. Note that the transform.xq main driver performs
: the same function when "subjects" is the selected entity-type. This main
: driver is useful when the goal is simply to (re-)generate the taxonomh index.
: This file should not require any modification beyond updating the config.xml
: and config-taxonomy.xml files to suit the needs of the person running the script.
:
: @author William L. Potter
: @version 1.0
:)

import module namespace functx="http://www.functx.com";
import module namespace config="http://wlpotter.github.io/ns/config" at "modules/config.xqm";
import module namespace csv2srophe="http://wlpotter.github.io/ns/csv2srophe" at "modules/csv2srophe.xqm";
import module namespace csv2subjects="http://wlpotter.github.io/ns/csv2subjects" at "modules/csv2subjects.xqm";

declare option output:omit-xml-declaration "no";
declare option file:omit-xml-declaration "no";

(:
- variables to add to config-taxonomy
  - include existing taxonomy as xs:boolean
  - path to existing taxonomy as xs:string
  - the actual collection based on the URI (handle errors if not exist)
- add to the main transform script to include the existing taxonomy if true and files exist (raise error if true and files don't exist; ignore if false)
- this script
:)
let $nothing := if($config:file-or-console = "file") then file:create-dir($config:taxonomy-index-output-directory)
let $index := csv2subjects:create-taxonomy-index($config:taxonomy-config, $config:existing-taxonomy)
return if($config:file-or-console = "file")
  then file:write($config:taxonomy-index-output-document-uri, $index, map {'method': 'xml', 'omit-xml-declaration': 'no'})
  else $index