xquery version "3.0";

(:
: Module Name: Syriaca.org Data Pipeline Config
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This module contains variables and functions used by other
:                  modules to access application context, io paths, etc.
:)

(:
ADD XQDOC COMMENTS HERE (SEE STYLE GUIDE P 14)
:)
module namespace config="http://wlpotter.github.io/ns/config";


(: creates and stores the xml config document. NOTE: assumes proper cloning of repo. perhaps use try-catch and fall back on github remote? Think about how to test these cases :)
declare variable $config:config-file := doc("../parameters/config.xml");

declare variable $config:nav-base := 
  let $pathToLocalRepo := 
    $config:config-file/meta/config/io/localRepositoryUrl/text()
  let $pathToRemoteRepo := 
    $config:config-file/meta/config/io/remoteRepositoryUrl/text()
  return if (file:is-dir($pathToLocalRepo)) then  (: note-to-self: need to indicate that this relies on basex's file module? :)
            $pathToLocalRepo
         else
            $pathToRemoteRepo;
            
  (: currently assuming an absolute remote path or a relative path (either remote or local depending on $config:nav-base); will implement other options later :)
declare variable $config:input-path :=
  let $rawPath := $config:config-file/meta/config/io/inputPath/text()
  return if (starts-with($rawPath, "http")) then
            $rawPath
         else
            $config:nav-base || $rawPath;

declare variable $config:input-type :=
  string($config:config-file/meta/config/io/inputPath/@type);
  
declare variable $config:input-file-separator :=
  string($config:config-file/meta/config/io/inputPath/@separator); (: add switch case to turn into the needed options map :)
  
  (: currently assuming a relative path. Will implement other options later. :)
declare variable $config:outputPath :=
  $config:nav-base || $config:config-file/meta/config/io/outputPath/text();
  
declare variable $config:file-or-console :=
  $config:config-file/meta/config/io/fileOrConsole/text();
  
declare variable $config:collection-type :=
  $config:config-file/meta/config/collectionType/text();
  
(: add responsibility info here :)

declare variable $config:creator-uri :=
  $config:editor-uri-base || "#" || 
          $config:config-file//meta/config/responsibility/creatorId/text();

declare variable $config:creator-name-string :=
  $config:config-file//meta/config/responsibility/creatorNameString/text();
  
declare variable $config:creator-resp-description :=
  $config:config-file//meta/config/responsibility/respDescription/text();

declare variable $config:change-log :=
  let $changeMessage := 
    $config:config-file/meta/config/responsibility/changeLog/*[name() = $config:collection-node/@name]/text() 
    (: get the text node of the changeLog matching the collection's name attribute :)
  return
    <change xmlns="http://www.tei-c.org/ns/1.0" when="fn:current-date()" who="{$config:creator-uri}">
      {$changeMessage}
    </change>;
  
  
  

declare variable $config:collection-node := (: candidate for try-catch to ensure that a proper collection type is selected :)
  for $collection in $config:config-file/meta/config/collections/collection
  where string($collection/@name) = $config:collection-type
  return $collection;
  
declare variable $config:uri-base := 
  string($config:collection-node/@record-URI-base);
  
declare variable $config:record-template :=
  let $pathToTemplate := $config:nav-base || 
                         string($config:collection-node/@template)
  return if (doc-available($pathToTemplate)) then
            doc($pathToTemplate);
            (: otherwise should probably raise an error? :)
            
declare variable $config:editor-uri-base :=
  $config:config-file/meta/config/syriacaMetadata/editorUriBase/text();

declare variable $config:base-language :=
  $config:config-file/meta/config/syriacaMetadata/baseLanguage/text();