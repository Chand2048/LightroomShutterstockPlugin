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
		    title = "Open all unverifiied photos",
		    file = "openPhotosNotInLightroom.lua",
		},
	    {
		    title = "Copy title to caption",
		    file = "CopyTitleToCaption.lua",
		},
	    {
		    title = "Replace keywords from Shutterstock",
		    file = "ReplaceKeywords.lua",
		},
	    {
		    title = "Reset Shutterstock Fields",
		    file = "ResetFields.lua",
		},
	    {
		    title = "Find in Shutterstock",
		    file = "FindInShutterstock.lua",
		},
	    {
		    title = "Sync with JSON Catalog",
		    file = "SyncWithJson.lua",
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
