xquery version "3.0";

(:
: Module Name: Syriaca.org Taxonomy Util
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This module contains utility functions for working with the
:                  Syriaca.org taxonomy. In particular, it contains the functions
:                  used to build the hierarichal taxonomy index.
:)

(:~ 
: This module provides functions for processing and manipulating the Syriaca.org
: taxonomy records, including building the taxonomy index.
:
: @author William L. Potter
: @version 1.0
:)
module namespace taxonomy="http://wlpotter.github.io/ns/taxonomy";


import module namespace functx="http://www.functx.com";
import module namespace config="http://wlpotter.github.io/ns/config" at "config.xqm";
import module namespace csv2srophe="http://wlpotter.github.io/ns/csv2srophe" at "csv2srophe.xqm";
import module namespace csv2subjects="http://wlpotter.github.io/ns/csv2subjects" at "csv2subjects.xqm";


(:
- variable for the list of URIs that become listUri/@ref (store this list in config.xml)
- variable pointing to the Syriaca.org servers (or a cloned github repo of app-data?)
    - I think ideally we would use a local clone of the github repo
    - next ideal would be an interaction with the remote Github repo
    - last resort would be the srophe app server for Syriaca.org (do we have a robust API?)
- variable pointing to the taxonomy index that exists on the server (maybe have a fallback function that builds from the data we already have?)
    - this should already be in the config file
- pass the existing taxonomy and newly created records
- loop through each uri in the $listUriSet
    - for each doc in the union of existing and new taxonomy records
    - if has a relation with an @passive = the current uri in the set, then return <uri>$doc-uri</uri> (waiting on decision about mutual, directed in issue #35)
- after hierarchy created, loop create an updated index of all taxonomy
    - either create it just for the new ones and add to the existing index from the server or, if that fails for some reason, create it for both existing and new.
    - in either case, remove duplicates (or should this flag an error for some reason?) and sort alphabetically.
    return this under a listUri[@type="taxonomyAllUris"]
:)