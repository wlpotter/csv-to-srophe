xquery version "3.1";

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
import module namespace csv2subjects="http://wlpotter.github.io/ns/csv2subjects" at "modules/csv2subjects.xqm";
import module namespace template="http://wlpotter.github.io/ns/template" at "modules/template.xqm";


declare default element namespace "http://www.tei-c.org/ns/1.0";

declare option output:omit-xml-declaration "no";
declare option file:omit-xml-declaration "no";

let $inputCollection :=
  if($config:input-type = "csv") then csv2srophe:process-csv($config:input-path, $config:csv-input-separator) (: the process-csv function will return a collection of xml documents :)
  else if ($config:input-type = "xml") then collection($config:input-path)
  else  "error: invalid input type selected in config.xml at XPath '/meta/config/io/inputPath/@type'. Should be 'csv' for processing a csv table or 'xml' for processing xml snippet records."

let $nothing := if($config:file-or-console = "file") then file:create-dir($config:output-path) else () (: if writing to file and the output directory doesn't exist, create it :)
let $nothing := if($config:file-or-console = "file" and $config:collection-type = "subjects") then file:create-dir($config:taxonomy-index-output-directory) else () (: if the entity type is 'subjects', create a directory for the taxonomy index output :)
            
return (if(not($config:index-of-existing-uris[1] instance of xs:string)) then $config:index-of-existing-uris else (),
        if($config:collection-type = "subjects") then 
          let $taxonomyIndex := csv2subjects:create-taxonomy-index($config:taxonomy-config, $inputCollection)
          return if($config:file-or-console = "file") then 
            file:write($config:taxonomy-index-output-document-uri, $taxonomyIndex, map {'method': 'xml', 'omit-xml-declaration': 'no'})
            else $taxonomyIndex
        else (),
        if(functx:atomic-type($inputCollection) = "xs:string") 
          then $inputCollection (: returns the error string if $config:input-type was assigned wrong :)
       else
         for $inDoc in $inputCollection
         (: search for an idno element in the tei:text node() that matches the base-uri of the entity as specified in config.xml 
         :  This base-uri is determined by the /meta/config/collections/collection/@record-URI-base of the collection whose @name matches /meta/config/collectionType/text():)
         let $inDocUri := $inDoc//text//idno[@type="URI" and starts-with(text(), $config:uri-base)]/text()
         
         (: if the mark the URI if it exists; only check if the index creation did not raise an error. successful index creation results in a sequence of strings:)
         let $uriExists := if($config:index-of-existing-uris[1] instance of xs:string) then functx:is-value-in-sequence($inDocUri, $config:index-of-existing-uris) else false ()
         let $outDoc := if($inDoc/descendant-or-self::*:failure) then $inDoc else template:merge-record-into-template($inDoc, $config:record-template, $inDocUri)
         
         (: write to the output folder or return to console. Variable controlled by config.xml/meta/config/io/fileOrConsole :)
         return if($config:file-or-console = "file" and not($uriExists) and not($inDoc/descendant-or-self::*:failure)) then
                 let $docFileName := substring-after($inDocUri, $config:uri-base) || ".xml"
                 let $outputTarget := $config:output-path || $docFileName
                 return file:write($outputTarget, $outDoc, map {'method': 'xml', 'omit-xml-declaration': 'no', 'indent': 'yes'})
                else
                  if($uriExists) then <error type="error"><desc>This record already exists in data</desc><recordUri>{$inDocUri}</recordUri></error> else $outDoc
        )