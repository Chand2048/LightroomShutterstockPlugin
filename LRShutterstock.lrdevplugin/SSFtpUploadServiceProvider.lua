--[[----------------------------------------------------------------------------

SSFtpUploadExportServiceProvider.lua
ShutterstockMetadataDefinitionFile.lrplugin

--------------------------------------------------------------------------------

 Copyright 2018 Chris Anderson
 All Rights Reserved.

------------------------------------------------------------------------------]]

-- SSFtpUpload plug-in
require "SSFtpUploadExportDialogSections"
require "SSFtpUploadTask"


--============================================================================--

return {
	
	hideSections = { 'exportLocation' },

	allowFileFormats = { 'JPEG' },
	allowColorSpaces = { 'RGB' },
	hideSections = { 'video' },
	hideSections = { 'watermarking' },	

	exportPresetFields = {
		{ key = 'putInSubfolder', default = false },
		{ key = 'path', default = 'photos' },
		{ key = "ftpPreset", default = nil },
		{ key = "fullPath", default = nil },
	},

	startDialog = SSFtpUploadExportDialogSections.startDialog,
	sectionsForBottomOfDialog = SSFtpUploadExportDialogSections.sectionsForBottomOfDialog,
	
	processRenderedPhotos = SSFtpUploadTask.processRenderedPhotos,
	
}
