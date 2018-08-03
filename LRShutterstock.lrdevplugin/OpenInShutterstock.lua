--[[----------------------------------------------------------------------------

OpenInShutterstock.lua

--------------------------------------------------------------------------------

 Copyright 2018 Chris Anderson
 All Rights Reserved.

------------------------------------------------------------------------------]]

local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local catalog = LrApplication.activeCatalog()
require 'SSUtil'

OISSMenuItem = {}

function OISSMenuItem.openInShutterstock()
	local photo = catalog.targetPhoto
    if not SSUtil.showInShutterstock( photo ) then
        LrDialogs.showError( "Photo does not have a valid Shutterstock ID." ) 
    end
end

import 'LrTasks'.startAsyncTask( OISSMenuItem.openInShutterstock )
