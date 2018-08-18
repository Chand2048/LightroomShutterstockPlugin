--[[----------------------------------------------------------------------------

Info.lua
ShutterstockMetadata.lrplugin

--------------------------------------------------------------------------------

 Copyright 2018 Chris Anderson
 All Rights Reserved.

------------------------------------------------------------------------------]]

return {
	LrSdkVersion = 5.0,

	LrToolkitIdentifier = 'com.shutterstock.lightroom.manager',
	LrPluginName = "Shutterstock",
	
	LrMetadataProvider = 'ShutterstockMetadataDefinitionFile.lua',
	LrMetadataTagsetFactory = { 'ShutterstockMetadataTagset.lua' },

	LrLibraryMenuItems = {
	    {
		    title = "Open in Shutterstock",
		    file = "OpenInShutterstock.lua",
		},
	    {
		    title = "Enumerate Shutterstock Catalog",
		    file = "EnumerateShutterstock.lua",
		},
	    {
		    title = "Find In Shutterstock",
		    file = "FindInShutterstock.lua",
		},
	    {
		    title = "Replace keywords from Shutterstock",
		    file = "ReplaceKeywords.lua",
		},
	    {
		    title = "Manually link to Shutterstock",
		    file = "ManualSSId.lua",
		},
	},

	LrExportServiceProvider = {
		title = "Shutterstock FTP Upload",
		file = 'SSFtpUploadServiceProvider.lua',
	},
}
