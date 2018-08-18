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
        local props = LrBinding.makePropertyTable( context )
		props.ssId = ssId
		
		local f = LrView.osFactory()
				
		-- Create the UI components like this so we can access the values as vars.
		
		local ssIdEditText = f:edit_text {
			immediate = true,
			value = props.ssId,
		}
				
		-- This is the function that will run when the value props.myString is changed.
		
		local function openInShutterstock()
            local ssId = ssIdEditText.value
            SSUtil.showInShutterstockByID( ssId )
		end
		
		-- Add an observer to the property table.  We pass in the key and the function
		-- we want called when the value for the key changes.
		-- Note:  Only when the value changes will there be a notification sent which
		-- causes the function to be invoked.
		
		--props:addObserver( "myObservedString", myCalledFunction )
				
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
					
					-- When the 'Update' button is clicked.
					
					action = openInShutterstock
				},
			}, -- end row
			f:row {
				f:push_button {
					title = "Validate",
					
					-- When the 'Update' button is clicked.
					
					action = openInShutterstock
				},
			}, -- end row
		} -- end column
		
		LrDialogs.presentModalDialog {
				title = "Manual link to shutterstock",
				contents = c
			}

	end) -- end main function


end

-- Now display the dialogs.

import 'LrTasks'.startAsyncTask( SWSSMenuItem.showManualSSId )
