--[[----------------------------------------------------------------------------

SyncWithShutterstock.lua

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

local catalog = LrApplication.activeCatalog()

require 'SSUtil'

local userName = 'Chris W Anderson'
local userNameSafe = 'Chris%20W%20Anderson'

--============================================================================--

SWSSMenuItem = {}

function SWSSMenuItem.startSync( )
    local catPhotos = catalog.targetPhotos
    local msg = string.format( "Searching Shutterstock for %s photos", #catPhotos )
    pscope = LrProgressScope( { title = msg } )
    pscope:setCancelable( true )

    LrFunctionContext.callWithContext( "TryToSyncShutterstock", function(context)
        context:addCleanupHandler( function()
                pscope:cancel()
            end) 

        local complete = 0
        local completeInc = 100 / (#catPhotos * 2)
        pscope:setPortionComplete(complete, 100)

        for _, photo in ipairs( catPhotos ) do
            if not SWSSMenuItem.verifyBySSID( photo, pscope, complete, completeInc ) then
                complete = complete + completeInc
                pscope:setPortionComplete( complete, 100 )

                if not SWSSMenuItem.findByTitle( photo, pscope, complete, completeInc ) then
                    complete = complete + completeInc
                    pscope:setPortionComplete(complete, 100)
                    SSUtil.showInShutterstock( photo )
                end
            end
        end 
    end )

    pscope:done()
end

function SWSSMenuItem.verifyBySSID( photo, pscope, complete, completeInc )
    pscope:setCaption( string.format( "%s : Checking SSID", photo:getFormattedMetadata( 'fileName' ) ) )
    local ssID = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockId' )

    if ssID then
        local url = string.format( "https://www.shutterstock.com/image-photo/%s", ssID )
        local response, hdrs = LrHttp.get( url )
        
        if response then
            -- TODO check more than just username
            return string.find( response, userName, 1, true ) ~= nil
        end
    end

    return false
end

function SWSSMenuItem.findByTitle( photo, pscope, complete, completeInc )
    -- Use search to find the photo by title.
    -- Keep removing words until we find only one photo
    local title = photo:getFormattedMetadata( 'title' )
    local titleWords = {}
    for w in string.gmatch(title, "%a+") do
        if w then
            titleWords[#titleWords + 1] = w
        end
    end

    local myCompleteInc = completeInc / #titleWords

    while #titleWords ~= 0 do
        pscope:setCaption( string.format( "%s : Checking title with %s words...", photo:getFormattedMetadata( 'fileName' ), #titleWords ) )
        pscope:setPortionComplete(complete, 100)
        complete = complete + myCompleteInc

        local titleCleaned = nil
        for i, w in pairs(titleWords) do
            if w then
                if titleCleaned == nil then
                    titleCleaned = w
                else
                    titleCleaned = string.format( "%s+%s", titleCleaned, w )
                end
            end
        end

        local url = string.format( "https://www.shutterstock.com/g/%s?searchterm=%s&search_source=base_gallery&language=en&sort=popular&image_type=photo&measurement=px&safe=false", userNameSafe, titleCleaned )
        local response, hdrs = LrHttp.get( url )

        -- Find all of the IDs.
        local ssID = {}
        local i = 0
        while true do
            local prefix = '<button data-href="/search/similar/'
            i = string.find( response, prefix, i, true )
            if i ~= nil then
                i = i + string.len( prefix )
                local j = string.find( response, '"', i + 1, true )
                ssID[#ssID + 1] = string.sub( response, i, j - 1 )
            else   
                break
            end
        end

        -- Open everything if we find more than one
        if #ssID > 1 then
            for i, id in pairs(ssID) do
                SSUtil.showInShutterstockByID( id )
            end

            return false
        else 
            if #ssID == 1 then
                photo.catalog:withPrivateWriteAccessDo( function() 
                    photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockId', ssID[1] ) 
                end )

                return true
            end
        end

        -- remove the last word in the title and try again
        titleWords[#titleWords] = nil
    end 

    return false
end

import 'LrTasks'.startAsyncTask( SWSSMenuItem.startSync )
