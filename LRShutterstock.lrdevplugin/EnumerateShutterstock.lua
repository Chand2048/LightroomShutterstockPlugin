--[[----------------------------------------------------------------------------

EnumerateShutterstock.lua

--------------------------------------------------------------------------------

 Copyright 2018 Chris Anderson
 All Rights Reserved.

------------------------------------------------------------------------------]]

local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrHttp = import 'LrHttp'
local LrProgressScope = import 'LrProgressScope'
local LrFunctionContext = import 'LrFunctionContext'

local catalog = LrApplication.activeCatalog()
require 'SSUtil'

ESMenuItem = {}

function ESMenuItem.collectSSIDs()
    local pageNum = 1
    local ssIDs = {}
    local count = 0

    while true do
        local url = "https://www.shutterstock.com/g/chris%20w%20anderson?search_source=base_gallery&page=" .. pageNum
        local response, hdrs = LrHttp.get( url )

        if not response then
            LrDialogs.showError( "Failed to get response from " .. searchUrl )
            return {}
        end

        --LrDialogs.message( "checking page " .. pageNum )
        --SSUtil.showUser( response, nil )
        
        -- Find all of the IDs.
        local foundNewID = false
        local i = 0
        while true do
            -- sample <img src="https://image.shutterstock.com/image-photo/beautiful-costumes-san-francisco-2018-260nw-1103879468.jpg" alt="Beautiful costumes from the San Francisco 2018 Carnival">
            local prefix = '<img src="https://image.shutterstock.com/image-photo/'
            local mid = '.jpg" alt="'
            i = string.find( response, prefix, i, true )
            if i ~= nil then
                i = i + string.len( prefix )
                local j = string.find( response, mid, i + 1, true )
                local temp = string.sub( response, i, j - 1 )
                local ssID = SSUtil.getIdFromEndOfUrl( temp )
 
                i = j + string.len( mid )
                j = string.find( response, '">', i, true )
                local title = string.sub( response, i, j - 1 )

                if ssIDs[ssID] == nil then
                    ssIDs[ssID] = title
                    foundNewID = true
                    count = count + 1
                end
            else   
                break
            end
        end

        if foundNewID == false then
            break
        end
        
        pageNum = pageNum + 1
    end

    return ssIDs, count
end

function ESMenuItem.enumShutterstock()
    pscope = LrProgressScope( { title = 'Enumerating shutterstock catalog' } )
    pscope:setCancelable( true )

    LrFunctionContext.callWithContext( "EnumerateShutterstock", function(context)
        context:addCleanupHandler( function()
                pscope:cancel()
            end) 

        pscope:setCancelable( true )
        pscope:attachToFunctionContext( context )
        pscope:setCaption( 'Collecting (ID, title) pairs from shutterstock' )

        local ssIDs, totalCount = ESMenuItem.collectSSIDs()
        local complete = 0
        local completeInc = 1

        local n = 0
        local dupeID = 0
        local dupeTitle = 0
        local matched = 0
        local verified = 0
        local notInCatalog = 0

        for ssID, title in pairs( ssIDs ) do
            if pscope:isCanceled() then
                return
            end

            n = n + 1
            pscope:setCaption( "" .. n .. " of " .. totalCount .. " matched=" .. matched .. " dupeID=" .. dupeID .. " dupeTitle=" .. dupeTitle )
            pscope:setPortionComplete(complete, totalCount)
            complete = complete + completeInc
            
            local photos = SSUtil.findInCatalogBySSId( catalog, ssID )
            --LrDialogs.message( 'found ' .. SSUtil.tableLength( photos ) .. ' by id' )
            if SSUtil.tableLength( photos ) > 1 then
                --catalog:setSelectedPhotos( photos[1], photos ) 
                dupeID = dupeID + 1
                for _, photo in pairs(photos) do
                    if pscope:isCanceled() then
                        return
                    end
                    SSUtil.setError( photo, nil, 'Duplicate shutterstockID')
                end
            else
                if SSUtil.tableLength( photos ) == 1 then
                    --catalog:setSelectedPhotos( photos[1], photos ) 
                    verified = verified + 1
                else
                    -- SSUtil.tableLength( photos ) == 0
                    photos = SSUtil.findInCatalogByTitle( catalog, title )
                    --LrDialogs.message( 'found ' .. SSUtil.tableLength( photos ) .. ' by title' )
                    if SSUtil.tableLength( photos ) > 1 then
                        --catalog:setSelectedPhotos( photos[1], photos ) 
                        dupeTitle = dupeTitle + 1
                        for _, photo in pairs(photos) do
                            if pscope:isCanceled() then
                                return
                            end
                            SSUtil.setError( photo, nil, 'Duplicate titles')
                        end
                    else
                        if SSUtil.tableLength( photos ) == 1 then
                            catalog:setSelectedPhotos( photos[1], photos ) 
                            SSUtil.setFound( photos[1], ssID )
                            matched = matched + 1
                        else
                            notInCatalog = notInCatalog + 1
                        end
                    end
                end
            end
        end

        pscope:done()
    end )
end

import 'LrTasks'.startAsyncTask( ESMenuItem.enumShutterstock )
