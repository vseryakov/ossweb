/*
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is from Handle/DOI Protocol Handler 1.0.1,
 * by Mark Donoghue, released on December 12, 2005
 *
 * Author Vlad Seryakov vlad@crystalballinc.com
 *
 */

const nsIMStream 		        = Components.ID("{c2e6b7ab-8141-45e9-8c84-e32a825bb104}");
const MSTREAMPROT_HANDLER_CID 	        = "@mozilla.org/network/protocol;1?name=mstream";

const NS_URI_CID 			= "@mozilla.org/network/simple-uri;1";
const NS_PREFS_CID                      = "@mozilla.org/preferences-service;1";
const NS_PROCESS_CID                    = "@mozilla.org/process/util;1";
const NS_IOSERVICE_CID                  = "@mozilla.org/network/io-service;1";
const NS_LOCALFILE_CID                  = "@mozilla.org/file/local;1";

const nsIURI                            = Components.interfaces.nsIURI;
const nsIChannel                        = Components.interfaces.nsIChannel;
const nsIProcess                        = Components.interfaces.nsIProcess;
const nsISupports                       = Components.interfaces.nsISupports;
const nsIIOService                      = Components.interfaces.nsIIOService;
const nsILocalFile                      = Components.interfaces.nsILocalFile;
const nsIPrefService                    = Components.interfaces.nsIPrefService;
const nsIWindowWatcher                  = Components.interfaces.nsIWindowWatcher;
const nsIProtocolHandler                = Components.interfaces.nsIProtocolHandler;

function MStreamProtocolHandler(scheme)
{
    this.scheme = scheme;
}

MStreamProtocolHandler.prototype.defaultPort = -1;
MStreamProtocolHandler.prototype.protocolFlags = nsIProtocolHandler.URI_NORELATIVE;

MStreamProtocolHandler.prototype.allowPort = function(aPort, aScheme)
{
    return false;
}

MStreamProtocolHandler.prototype.newURI = function(aSpec, aCharset, aBaseURI)
{
    var uri = Components.classes[NS_URI_CID].createInstance(nsIURI);
    uri.spec = aSpec;
    return uri;
}

MStreamProtocolHandler.prototype.newChannel = function(aURI)
{
    var prefService = Components.classes[NS_PREFS_CID].getService(nsIPrefService);
    var prefBranch = prefService.getBranch(null);
    var path = prefBranch.getPrefType("network.mstream.path") & 32 ? prefBranch.getCharPref("network.mstream.path") : null;
    if(path && path != "") {
      var file = Components.classes[NS_LOCALFILE_CID].createInstance(nsILocalFile);
      var proc = Components.classes[NS_PROCESS_CID].createInstance(nsIProcess);
      var args = new Array();
      args.push("http"+aURI.spec.substr(7));
      file.initWithPath(path);
      if(file.exists()) {
        proc.init(file);
        proc.run(false,args,args.length);
      }
    }
    var ios = Components.classes[NS_IOSERVICE_CID].getService(nsIIOService);
    return ios.newChannel("javascript:;",null,null);
}

function MStreamProtocolHandlerFactory(scheme)
{
    this.scheme = scheme;
}

MStreamProtocolHandlerFactory.prototype.createInstance = function(outer, iid)
{
    if(outer != null) throw Components.results.NS_ERROR_NO_AGGREGATION;

    if(!iid.equals(nsIProtocolHandler) && !iid.equals(nsISupports))
        throw Components.results.NS_ERROR_INVALID_ARG;

    return new MStreamProtocolHandler(this.scheme);
}

var factory_mstream = new MStreamProtocolHandlerFactory("mstream");

var MStreamModule = new Object();

MStreamModule.registerSelf = function(compMgr, fileSpec, location, type)
{
    compMgr = compMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar);

    compMgr.registerFactoryLocation(nsIMStream, "MStream protocol handler", MSTREAMPROT_HANDLER_CID, fileSpec, location, type);
}

MStreamModule.unregisterSelf = function(compMgr, fileSpec, location)
{
    compMgr = compMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar);

    compMgr.unregisterFactoryLocation(MSTREAMPROT_HANDLER_CID, fileSpec);
}

MStreamModule.getClassObject = function(compMgr, cid, iid)
{
    if(!iid.equals(Components.interfaces.nsIFactory))
        throw Components.results.NS_ERROR_NOT_IMPLEMENTED;

    if(cid.equals(nsIMStream)) return factory_mstream;
    throw Components.results.NS_ERROR_NO_INTERFACE;
}

MStreamModule.canUnload = function(compMgr)
{
    return true;
}

function NSGetModule(compMgr, fileSpec)
{
    return MStreamModule;
}
