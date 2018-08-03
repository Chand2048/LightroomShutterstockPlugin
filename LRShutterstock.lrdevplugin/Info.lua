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
		    title = "Syncronize with Shutterstock",
		    file = "SyncWithShutterstock.lua",
		},
	},

	LrExportServiceProvider = {
		title = "Shutterstock FTP Upload",
		file = 'SSFtpUploadServiceProvider.lua',
	},
}
