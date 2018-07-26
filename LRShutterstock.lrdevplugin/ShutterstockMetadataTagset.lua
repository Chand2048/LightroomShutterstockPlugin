--[[----------------------------------------------------------------------------

ShutterstockMetadataTagset.lua
ShutterstockMetadataDefinitionFile.lrplugin

--------------------------------------------------------------------------------

 Copyright 2018 Chris Anderson
 All Rights Reserved.

------------------------------------------------------------------------------]]

return {

	title = "Shutterstock",
	id = 'ShutterstockTagset',
	
	items = {
		'com.adobe.filename',
		'com.adobe.folder',
		'com.adobe.title', 
		
		'com.adobe.separator',
		
		'com.shutterstock.lightroom.manager.*',
	},

}
