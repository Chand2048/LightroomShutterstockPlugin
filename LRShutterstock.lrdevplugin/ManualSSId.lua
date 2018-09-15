--[[----------------------------------------------------------------------------

ManualSSId.lua

--------------------------------------------------------------------------------

 Copyright 2018 Chris Anderson
 All Rights Reserved.

------------------------------------------------------------------------------]]

-- Lightroom API
local LrHttp = import 'LrHttp'
local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrProgressScope = import 'LrProgressScope'
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrView = import 'LrView'

local catalog = LrApplication.activeCatalog()

require 'SSUtil'

SWSSMenuItem = {}

--============================================================================--

function SWSSMenuItem.showManualSSId()

	LrFunctionContext.callWithContext( "showManualSSId", function( context )
	
		-- Create a bindable table.  Whenever a field in this table changes then notifications
		-- will be sent.  Note that we do NOT bind this to the UI.
		
        local photo = catalog.targetPhoto
        local ssId = SSUtil.getSSIdFromPhoto( photo )
		local f = LrView.osFactory()
        local props = LrBinding.makePropertyTable( context )
		props.ssId = ssId
				
		-- Create the UI components like this so we can access the values as vars.
		
		local ssIdEditText = f:edit_field {
			immediate = true,
			value = props.ssId,
		}

		local function openInShutterstock()
            local ssId = ssIdEditText.value
            SSUtil.showInShutterstockByID( ssId )
		end

		-- Create the contents for the dialog.
		
		local c = f:column {
			spacing = f:dialog_spacing(),
			f:row {
				f:static_text {
					alignment = "right",
					width = LrView.share "label_width",
					title = "Shutterstock ID: "
				},
				ssIdEditText,
				f:push_button {
					title = "Open In Shutterstock",
					action = openInShutterstock
				},
			}, -- end row
		} -- end column

		local returnVal = LrDialogs.presentModalDialog {
			title = "Manual link to shutterstock",
			contents = c
		}

		--[[
		-- retrieve the content of a URL
        ssId = ssIdEditText.value
		local http = require("socket.http")
		local thumbUrl = 'https://thumb9.shutterstock.com/thumb_large/3780074/' .. ssId .. '/' .. ssId .. '.jpg'
		local body, code = http.request( thumbUrl )
		if not body then 
			LrDialogs.message( code )
		end 

		-- save the content to a file
		local f = assert(io.open('test.jpg', 'wb')) -- open in "binary" mode
		f:write(body)
		f:close()
		--]]

		if returnVal == 'ok' then
            ssId = ssIdEditText.value
			SSUtil.setFound( photo, ssId, 'Manual bind to shutterstock' )
		end
	end) -- end main function
end

-- Now display the dialogs.

import 'LrTasks'.startAsyncTask( SWSSMenuItem.showManualSSId )
