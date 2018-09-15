--[[----------------------------------------------------------------------------

FindInShutterstock.lua

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

--============================================================================--

SWSSMenuItem = {}

function SWSSMenuItem.startFind( )
    local catPhotos = catalog.targetPhotos
    local catPhotosLen = SSUtil.tableLength( catPhotos )
    local msg = string.format( "Searching Shutterstock for %s photos", catPhotosLen )
    pscope = LrProgressScope( { title = msg } )

    LrFunctionContext.callWithContext( "TryToSyncShutterstock", function(context)
        context:addCleanupHandler( function()
                pscope:cancel()
            end) 

        local complete = 0
        local completeInc = 100 / catPhotosLen

        pscope:setCancelable( true )
        pscope:attachToFunctionContext( context )
        pscope:setPortionComplete(complete, 100)

        for _, photo in ipairs( catPhotos ) do
            pscope:setCaption( string.format( "%s : Verifying with shutterstock metadata", photo:getFormattedMetadata( 'fileName' ) ) )
            
            local url = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockUrl' )
            if not SWSSMenuItem.verifyByUrl( photo, url ) then
                
                local closeUrl = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'CloseUrl' )
                if SWSSMenuItem.verifyByUrl( photo, closeUrl ) then
                    local ssID = SSUtil.getIdFromEndOfUrl( closeUrl )
                    SSUtil.setFound( photo, ssID )
                else
                    SWSSMenuItem.findByTitle( photo, pscope, complete, completeInc )
                end
            end

            complete = complete + completeInc
        end 

        pscope:done()
    end )
end

-- TODO: remove and use ssUtil version
function SWSSMenuItem.verifyByUrl( photo, url )
    if url then
        local response, hdrs = LrHttp.get( url )

        if response then
            -- Check username
            if string.find( response, SSUtil.getUserName(), 1, true ) == nil then
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
            SSPhoto.data.contributor_id == SSUtil.contributorID and
            SSPhoto.data.original_filename == fileNameJpg and 
            SSPhoto.data.sizes.huge_jpg.width == photo:getFormattedMetadata( 'maxAvailWidth' ) and
            SSPhoto.data.sizes.huge_jpg.height == photo:getFormattedMetadata( 'maxAvailHeight' )
    end
end
--]]

function SWSSMenuItem.collectUrlsFromSearch( searchStr )
    local searchUrl = string.format( "https://www.shutterstock.com/g/%s?searchterm=%s&search_source=base_gallery&language=en&sort=popular&image_type=photo&measurement=px&safe=false", SSUtil.getUserNameSafe(), searchStr )
    local response, hdrs = LrHttp.get( searchUrl )

    if not response then
        LrDialogs.showError( "Failed to get response from " .. searchUrl )
        return {}
    end

    -- Find all of the IDs.
    local urls = {}
    local index = 1
    local i = 0
    while true do
        -- sample <a href="/image-photo/water-buffalo-looks-one-piece-grass-1037674936?src=YdtO8xuXlNbJKHFw7ximoA-1-0" class="js_related-item a" data-current-order-index=""  data-track="click.searchResultsContributorProfileImages.image-1-1037674936" >
        -- turn into https://www.shutterstock.com/image-photo/water-buffalo-looks-one-piece-grass-1037674936
        local prefix = '<a href="/image-photo/'
        i = string.find( response, prefix, i, true )
        if i ~= nil then
            i = i + string.len( prefix )
            local j = string.find( response, '?', i + 1, true )
            local url = SSUtil.getSsScrapeImagePrefix() .. string.sub( response, i, j - 1 )
            urls[index] = url
            index = index + 1
        else   
            break
        end
    end

    return urls
end

function SWSSMenuItem.findByTitle( photo, pscope, complete, completeInc )
    -- Use search to find the photo by title.
    -- Keep removing words until we find only one photo
    local title = photo:getFormattedMetadata( 'title' )
    local titleWords = {}
    local index = 1
    for w in string.gmatch(title, "%a+") do
        if w then
            titleWords[index] = w
            index = index + 1
        end
    end

    local checkedUrl = {}
    local titleWordsLen = SSUtil.tableLength( titleWords )
    local myCompleteInc = completeInc / titleWordsLen
    local bestUrl = nil

    while titleWordsLen ~= 0 do
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

        pscope:setCaption( string.format( "%s : %s", photo:getFormattedMetadata( 'fileName' ), titleCleaned ) )
        pscope:setPortionComplete(complete, 100)
        complete = complete + myCompleteInc

        local urls = SWSSMenuItem.collectUrlsFromSearch( titleCleaned )
        local urlsLen = SSUtil.tableLength( urls )

        -- Open everything if we find more than one
        if urlsLen >= 1 then
            for i, url in pairs(urls) do
                if checkedUrl[url] == nil then
                    pscope:setCaption( string.format( "%s : Checking %s of %s", photo:getFormattedMetadata( 'fileName' ), i, urlsLen ) )
                    local fullMatch, partialMatch = SWSSMenuItem.verifyByUrl( photo, url )
                    if fullMatch then
                        local ssID = SSUtil.getIdFromEndOfUrl( url )
                        SSUtil.setFound( photo, ssID )
                        return true
                    end

                    checkedUrl[checkedUrl] = false
                    
                    if partialMatch then
                        bestUrl = url
                    end
                end
            end 
        end

        -- remove the shortest word and try again
        local shortestIndex = nil
        local shortestLen = 1000
        for i, word in pairs(titleWords) do
            local l = string.len( titleWords[i] )
            if l < shortestLen then
                shortestIndex = i
                shortestLen = l
            end
        end

        if shortestIndex ~= nil then
            titleWords[shortestIndex] = nil
            titleWordsLen = titleWordsLen - 1
        end
    end 

    SSUtil.setError( photo, bestUrl, 'Failed to find matches' )
    return false
end

import 'LrTasks'.startAsyncTask( SWSSMenuItem.startFind )
