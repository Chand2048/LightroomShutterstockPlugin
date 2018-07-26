--[[----------------------------------------------------------------------------

SSFtpUploadExportDialogSections.lua
ShutterstockMetadataDefinitionFile.lrplugin

--------------------------------------------------------------------------------

 Copyright 2018 Chris Anderson
 All Rights Reserved.

------------------------------------------------------------------------------]]

-- Lightroom SDK
local LrView = import 'LrView'
local LrFtp = import 'LrFtp'

--============================================================================--

SSFtpUploadExportDialogSections = {}

-------------------------------------------------------------------------------

local function updateExportStatus( propertyTable )
	
	local message = nil
	
	repeat
		-- Use a repeat loop to allow easy way to "break" out.
		-- (It only goes through once.)
		
		if propertyTable.ftpPreset == nil then
			message = LOC "$$$/SSFtpUpload/ExportDialog/Messages/SelectPreset=Select or Create an FTP preset"
			break
		end
		
		if propertyTable.putInSubfolder and ( propertyTable.path == "" or propertyTable.path == nil ) then
			message = LOC "$$$/SSFtpUpload/ExportDialog/Messages/EnterSubPath=Enter a destination path"
			break
		end
		
		local fullPath = propertyTable.ftpPreset.path or ""
		
		if propertyTable.putInSubfolder then
			fullPath = LrFtp.appendFtpPaths( fullPath, propertyTable.path )
		end
		
		propertyTable.fullPath = fullPath
		
	until true
	
	if message then
		propertyTable.message = message
		propertyTable.hasError = true
		propertyTable.hasNoError = false
		propertyTable.LR_cantExportBecause = message
	else
		propertyTable.message = nil
		propertyTable.hasError = false
		propertyTable.hasNoError = true
		propertyTable.LR_cantExportBecause = nil
	end
	
end

-------------------------------------------------------------------------------

function SSFtpUploadExportDialogSections.startDialog( propertyTable )
	
	propertyTable:addObserver( 'items', updateExportStatus )
	propertyTable:addObserver( 'path', updateExportStatus )
	propertyTable:addObserver( 'putInSubfolder', updateExportStatus )
	propertyTable:addObserver( 'ftpPreset', updateExportStatus )

	updateExportStatus( propertyTable )
	
end

-------------------------------------------------------------------------------

function SSFtpUploadExportDialogSections.sectionsForBottomOfDialog( _, propertyTable )

	local f = LrView.osFactory()
	local bind = LrView.bind
	local share = LrView.share
	local LrFtp = import 'LrFtp'

	local result = {
	
		{
			title = LOC "$$$/SSFtpUpload/ExportDialog/FtpSettings=FTP Server",
			
			synopsis = bind { key = 'fullPath', object = propertyTable },
			
			f:row {
				f:static_text {
					title = LOC "$$$/SSFtpUpload/ExportDialog/Destination=Destination:",
					alignment = 'right',
					width = share 'labelWidth'
				},
	
				LrFtp.makeFtpPresetPopup {
					factory = f,
					properties = propertyTable,
					valueBinding = 'ftpPreset',
					itemsBinding = 'items',
					fill_horizontal = 1,
				},
			},

			f:row {
				f:spacer {
					width = share 'labelWidth'
				},
	
				f:checkbox {
					title = LOC "$$$/SSFtpUpload/ExportDialog/PutInSubfolder=Put in Subfolder:",
					value = bind 'putInSubfolder',
				},

				f:edit_field {
					value = bind 'path',
					enabled = bind 'putInSubfolder',
					validate = LrFtp.ftpPathValidator,
					truncation = 'middle',
					immediate = true,
					fill_horizontal = 1,
				},
			},
			
			f:column {
				place = 'overlapping',
				fill_horizontal = 1,
				
				f:row {
					f:static_text {
						title = LOC "$$$/SSFtpUpload/ExportDialog/FullPath=Full Path:",
						alignment = 'right',
						width = share 'labelWidth',
						visible = bind 'hasNoError',
					},
					
					f:static_text {
						fill_horizontal = 1,
						width_in_chars = 20,
						title = bind 'fullPath',
						visible = bind 'hasNoError',
					},
				},
				
				f:row {
					f:static_text {
						fill_horizontal = 1,
						title = bind 'message',
						visible = bind 'hasError',
					},
				},
			},
		},
	}
	
	return result
	
end
