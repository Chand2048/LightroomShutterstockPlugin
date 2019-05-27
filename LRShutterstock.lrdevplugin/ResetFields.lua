--[[----------------------------------------------------------------------------

ManualSSId.lua

--------------------------------------------------------------------------------

 Copyright 2018 Chris Anderson
 All Rights Reserved.

------------------------------------------------------------------------------]]

-- Lightroom API
local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'

local catalog = LrApplication.activeCatalog()

require 'SSUtil'

SWSSMenuItem = {}

--============================================================================--

function SWSSMenuItem.showResetFields()
    local photo = catalog.targetPhoto
    local result = LrDialogs.confirm( 
        'Reset Shutterstock Fields', 
        'Are you sure you want to do this? Clearing this will reset all IDs and status related to your Shutterstock catalog.', 
        'Reset' )
    
    if result == 'ok' then
        SSUtil.setError( photo, nil, 'Manual Reset' )
    end
end

import 'LrTasks'.startAsyncTask( SWSSMenuItem.showResetFields )
