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

--JSON = assert(loadfile './JSON.lua')() -- one-time load of the routines

require 'SSUtil'
JSON = require 'JSON.lua'

--JSON = OBJDEF:new()

local userName = 'Chris W Anderson'
local userNameSafe = 'Chris%20W%20Anderson'
local contributorID = 3780074

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
        local completeInc = 100 / #catPhotos
        pscope:setPortionComplete(complete, 100)

        for _, photo in ipairs( catPhotos ) do
            pscope:setCaption( string.format( "%s : Verifying with shutterstock metadata", photo:getFormattedMetadata( 'fileName' ) ) )
            local url = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockUrl' )

            if not SWSSMenuItem.verifyByUrl( photo, url ) then
                if not SWSSMenuItem.findByTitle( photo, pscope, complete, completeInc ) then
                    SSUtil.showInShutterstock( photo )
                end
            end

            complete = complete + completeInc
            pscope:setPortionComplete( complete, 100 )
        end 
    end )

    pscope:done()
end

function SWSSMenuItem.verifyByUrl( photo, url )
    if url then
        -- local url = string.format( "https://www.shutterstock.com/image-photo/%s", ssID )
        local response, hdrs = LrHttp.get( url )

        if response then
            -- Check username
            if string.find( response, userName, 1, true ) == nil then
                return false, false
            end

            --[[ This only shows up when logged in to a valid account.
            -- Page will have something like <strong>Large</strong> &nbsp;|&nbsp; 5616 px x 3744 px &nbsp;
            local dimensions = photo:getRawMetadata( 'croppedDimensions' )
            local lookFor = string.format( '%s px x %s px', dimensions.width, dimensions.height )
            SSUtil.showUser( lookFor, response )
            
            if string.find( response, lookFor, 1, true ) == nil then
                LrDialogs.showError( "failed to find " .. lookFor )
                return false
            end
            --]]

            local title = photo:getFormattedMetadata( 'title' )
            if string.find( response, title, 1, true ) == nil then
                return false, true
            end

            return true, true
        end
    end

    return false, false
end

--[[ Does not work because need proper security cookies to call this api 
function SWSSMenuItem.verifyByssID( photo, ssID )
    if ssID then
    local url2 = "https://submit.shutterstock.com/api/content_editor/media/P" .. ssID
    local response2, hdrs2 = LrHttp.get( url2 )
    
    if response2 then
        local SSPhoto = JSON:decode( response2 )

        -- Check filename matches
        local fileName = SSUtil.cleanFilename( photo )
        local fileNameJpg = filename .. '.jpg'

        return 
            SSPhoto.data.media_type == 'image' and
            SSPhoto.data.status == 'approved' and
            SSPhoto.data.is_adult == false and
            SSPhoto.data.contributor_id == contributorID and
            SSPhoto.data.original_filename == fileNameJpg and 
            SSPhoto.data.sizes.huge_jpg.width == photo:getFormattedMetadata( 'maxAvailWidth' ) and
            SSPhoto.data.sizes.huge_jpg.height == photo:getFormattedMetadata( 'maxAvailHeight' )
    end
end
--]]

function SWSSMenuItem.collectUrlsFromSearch( searchStr )
    local searchUrl = string.format( "https://www.shutterstock.com/g/%s?searchterm=%s&search_source=base_gallery&language=en&sort=popular&image_type=photo&measurement=px&safe=false", userNameSafe, searchStr )
    --LrHttp.openUrlInBrowser( url )
    local response, hdrs = LrHttp.get( searchUrl )

    if not response then
        LrDialogs.showError( "Failed to get response from " .. searchUrl )
        return {}
    end

    -- Find all of the IDs.
    local urls = {}
    local i = 0
    while true do
        -- sample <a href="/image-photo/water-buffalo-looks-one-piece-grass-1037674936?src=YdtO8xuXlNbJKHFw7ximoA-1-0" class="js_related-item a" data-current-order-index=""  data-track="click.searchResultsContributorProfileImages.image-1-1037674936" >
        -- turn into https://www.shutterstock.com/image-photo/water-buffalo-looks-one-piece-grass-1037674936
        local prefix = '<a href="/image-photo/'
        i = string.find( response, prefix, i, true )
        if i ~= nil then
            i = i + string.len( prefix )
            local j = string.find( response, '?', i + 1, true )
            local url = 'https://www.shutterstock.com/image-photo/' .. string.sub( response, i, j - 1 )
            urls[#urls + 1] = url
        else   
            break
        end
    end

    return urls
end

function SWSSMenuItem.getIdFromUrl( url )
    -- https://www.shutterstock.com/image-photo/water-buffalo-looks-one-piece-grass-1037674936
    local temp = string.reverse( url )
    local i = string.find( temp, '-' )
    if i ~= nil then
        return string.reverse( string.sub( temp, 1, i - 1 ) )
    end

    return nil
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
    local bestUrl = nil

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

        local urls = SWSSMenuItem.collectUrlsFromSearch( titleCleaned )
        
        -- Open everything if we find more than one
        if #urls >= 1 and #urls <= 3 then
            for i, url in pairs(urls) do
                local fullMatch, partialMatch = SWSSMenuItem.verifyByUrl( photo, url )
                if fullMatch then
                    local ssID = SWSSMenuItem.getIdFromUrl( url )

                    photo.catalog:withPrivateWriteAccessDo( function() 
                        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockId', ssID ) 
                    end )

                    photo.catalog:withPrivateWriteAccessDo( function() 
                        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockUrl', url ) 
                    end )

                    photo.catalog:withPrivateWriteAccessDo( function() 
                        photo:setPropertyForPlugin( _PLUGIN, 'CloseUrl', nil ) 
                    end )

                    photo.catalog:withPrivateWriteAccessDo( function() 
                        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockStatus', 'Accepted' ) 
                    end )

                    photo.catalog:withPrivateWriteAccessDo( function() 
                        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockAudit', 'Found in Shutterstosck' )
                    end )

                    photo.catalog:withPrivateWriteAccessDo( function() 
                        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockLast', os.date('%c') )
                    end )

                    return true
                end

                if partialMatch then
                    bestUrl = url
                end
            end 
        end

        -- remove the last word in the title and try again
        titleWords[#titleWords] = nil
    end 

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockStatus', 'Error' )
    end )
    
    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'CloseUrl', bestUrl ) 
    end )
    
    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockAudit', 'Failed to find matches' ) 
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockLast', os.date('%c') )
    end )
    
    return false
end

import 'LrTasks'.startAsyncTask( SWSSMenuItem.startSync )
