--[[----------------------------------------------------------------------------

ReplaceKeywords.lua

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

function SWSSMenuItem.startReplace( )
    local catPhotos = catalog.targetPhotos
    local msg = string.format( "Replacing keywords from Shutterstock for %s photos", #catPhotos )
    pscope = LrProgressScope( { title = msg } )
    pscope:setCancelable( true )

    LrFunctionContext.callWithContext( "ReplaceKeywords", function(context)
        context:addCleanupHandler( function()
                pscope:cancel()
            end) 

        local complete = 0
        local completeInc = 100 / #catPhotos
        pscope:setPortionComplete(complete, 100)

        for _, photo in ipairs( catPhotos ) do
            local ssID = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockId' )
            local url = SSUtil.getSsScrapeImagePrefix() .. ssID
            pscope:setCaption( string.format( "%s : Scraping keywords", photo:getFormattedMetadata( 'fileName' ) ) )
            pscope:setPortionComplete(complete, 100)

            if url ~= nil then
                local ssKeywords = SWSSMenuItem.collectKeywords( url )
                if ssKeywords ~= nil then
                    local removeCount, addCount = SWSSMenuItem.reconcileKeywords( photo, ssKeywords )
                    local msg = "Keywords:"
                    if removeCount == 0 and addCount == 0 then
                        msg = msg .. " no changes"
                    end
                    if removeCount > 0 then
                        msg = msg .. " removed " .. removeCount
                    end
                    if addCount > 0 then
                        msg = msg .. " added " .. addCount
                    end

                    photo.catalog:withPrivateWriteAccessDo( function() 
                        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockAudit', msg )
                    end )

                    photo.catalog:withPrivateWriteAccessDo( function() 
                        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockLast', os.date('%c') )
                    end )
                else
                    LrDialogs.showError( "Failed to find keywords in shutterstock" )
                end
            end

            complete = complete + completeInc
        end 

        pscope:setPortionComplete( complete, 100 )
    end )

    pscope:done()
end

function SWSSMenuItem.buildKeywordMapFromPhoto( photo )
    local existingKeywords = photo:getRawMetadata( 'keywords' )
    local outTable = {}
    
    for _, kw in pairs(existingKeywords) do
        local name = string.lower( kw:getName() )
        outTable[ name ] = kw
    end

    return outTable
end

function SWSSMenuItem.reconcileKeywords( photo, ssKeywords )
    local photoKeywords = SWSSMenuItem.buildKeywordMapFromPhoto( photo )

    -- First remove keywords from photo that are not in shutterstock
    local removeCount = 0
    for kwName, lrKw in pairs( photoKeywords ) do
        if ssKeywords[ kwName ] == nil then
            photo.catalog:withWriteAccessDo( 'remove keyword', function() 
                photo:removeKeyword( lrKw ) 
            end )

            removeCount = removeCount + 1
        end
    end

    -- Now add any keywords that are not already there
    local addCount = 0
    for kwName, _ in pairs( ssKeywords ) do
        if photoKeywords[ kwName ] == nil then
            local lrKw = nil
            
            photo.catalog:withWriteAccessDo( 'create keyword', function() 
                lrKw = catalog:createKeyword( kwName, nil, true, nil, true )
            end )
            
            photo.catalog:withWriteAccessDo( 'add keyword', function() 
                photo:addKeyword( lrKw )
            end )

            addCount = addCount + 1
        end
    end

    return removeCount, addCount
end

function SWSSMenuItem.collectKeywords( url )
    if url then
        local response, hdrs = LrHttp.get( url )

        if response then
            local prefix = ',"keywords":"'
            local i = string.find( response, prefix, 1, true )
            if i ~= nil then
                i = i + string.len( prefix )
                local j = string.find( response, '"', i + 1, true )
                local keywordStr = string.sub( response, i, j - 1 )
                keywordStr = string.lower( keywordStr )
                local k = SSUtil.split( keywordStr, ',' )
                return SSUtil.flipKeyValue( k )
            end
        end
    end

    return {}
end

import 'LrTasks'.startAsyncTask( SWSSMenuItem.startReplace )
