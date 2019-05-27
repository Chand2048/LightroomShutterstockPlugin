--[[----------------------------------------------------------------------------

openPhotosNotInLightroom.lua

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

-- Build list by ssID of only verified photos
function SWSSMenuItem.selectedPhotoListBySSID()
    local photos = catalog.targetPhotos
    local list = {}
    for _, photo in ipairs( photos ) do
        local ssID = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockId' )
        local verified = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockVerified' )
        if ssID ~= nil and verified == "yes" then
            if list[ssID] ~= nil then
                LrDialogs.message( "Duplicate ShutterstockID!!! " .. ssID )
            end

            list[ssID] = photo
        end
    end

    return list
end

function SWSSMenuItem.openPhotosNotInLightroom()
    local catalog = SSUtil.getCatalogAsRows()
    local photos = SWSSMenuItem.selectedPhotoListBySSID()

    for _, fields in ipairs( catalog ) do
        local ssID = fields[ 1 ]
        if photos[ ssID ] == nil then
            SSUtil.showInShutterstockByID( ssID )
        end
    end
end

import 'LrTasks'.startAsyncTask( SWSSMenuItem.openPhotosNotInLightroom )
