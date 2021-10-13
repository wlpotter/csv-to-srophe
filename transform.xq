xquery version "3.0";

(:
: Module Name: Syriaca.org Pipeline Driver
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This main module transforms either XML snippets or CSV data
:                  into schema-compliant, TEI XML records for Syriaca entities.
:                  The script's configuration is controlled by the config.xml
:                  file, found in the repository's /parameters directory.
:)

(:~ 
: Based on the configuration in config.xml, this main driver script converts
: either a collection of XML snippets or a CSV table into a collection of
: fully-built, schema-compliant TEI records. It relies on the csv2srophe.xqm module, its
: extensions such as csv2places.xqm, and the template.xqm module.
: This file should not require any modification beyond updating the config.xml
: file to suit the needs of the person running the script.
:
: @author William L. Potter
: @version 1.0
:)

import module namespace functx="http://www.functx.com";
import module namespace config="http://wlpotter.github.io/ns/config" at "modules/config.xqm";
import module namespace csv2srophe="http://wlpotter.github.io/ns/csv2srophe" at "modules/csv2srophe.xqm";
import module namespace csv2places="http://wlpotter.github.io/ns/csv2places" at "modules/csv2places.xqm";
import module namespace template="http://wlpotter.github.io/ns/template" at "modules/template.xqm";


declare default element namespace "http://www.tei-c.org/ns/1.0";

declare option output:omit-xml-declaration "no";
declare option file:omit-xml-declaration "no";

let $inputCollection :=
  if($config:input-type = "csv") then csv2srophe:process-csv($config:input-path, $config:csv-input-separator) (: the process-csv function will return a collection of xml documents :)
  else if ($config:input-type = "xml") then collection($config:input-path)
  else  "error: invalid input type selected in config.xml at XPath '/meta/config/io/inputPath/@type'. Should be 'csv' for processing a csv table or 'xml' for processing xml snippet records."

let $nothing := if($config:file-or-console = "file") then file:create-dir($config:output-path) (: if writing to file and the output directory doesn't exist, create it :)


            
return if(functx:atomic-type($inputCollection) = "xs:string") 
          then $inputCollection (: returns the error string if $config:input-type was assigned wrong :)
       else
         for $inDoc in $inputCollection
         (: search for an idno element in the tei:text node() that matches the base-uri of the entity as specified in config.xml 
         :  This base-uri is determined by the /meta/config/collections/collection/@record-URI-base of the collection whose @name matches /meta/config/collectionType/text():)
         let $inDocUri := $inDoc//text//idno[@type="URI" and starts-with(text(), $config:uri-base)]/text()
         
         let $outDoc := template:merge-record-into-template($inDoc, $config:record-template, $inDocUri)
         
         (: write to the output folder or return to console. Variable controlled by config.xml/meta/config/io/fileOrConsole :)
         return if($config:file-or-console = "file") then
                 let $docFileName := substring-after($inDocUri, $config:uri-base) || ".xml"
                 let $outputTarget := $config:output-path || $docFileName
                 return file:write($outputTarget, $outDoc, map {'method': 'xml', 'omit-xml-declaration': 'no'})
                else
                  $outDoc