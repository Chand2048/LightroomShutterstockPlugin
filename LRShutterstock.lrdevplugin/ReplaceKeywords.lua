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
            local url = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockUrl' )
            if url ~= nil then
                pscope:setCaption( string.format( "%s : Scraping keywords", photo:getFormattedMetadata( 'fileName' ) ) )
                local ssKeywords = SWSSMenuItem.collectKeywords( url )
                if ssKeywords ~= nil then
                    SWSSMenuItem.removeAllKeywords( photo )
                    SWSSMenuItem.addKeywordsFromStrings( photo, ssKeywords )

                    photo.catalog:withPrivateWriteAccessDo( function() 
                        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockAudit', 'Copied keywords from Shutterstock' )
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

function SWSSMenuItem.addKeywordsFromStrings( photo, keywords )
    for _, name in ipairs( keywords ) do
        local lrKw = nil
        
        photo.catalog:withWriteAccessDo( 'create keyword', function() 
            lrKw = catalog:createKeyword( name, nil, true, nil, true )
        end )
        
        photo.catalog:withWriteAccessDo( 'add keyword', function() 
            photo:addKeyword( lrKw )
        end )
    end
end

function SWSSMenuItem.removeAllKeywords( photo )
    local existingKeywords = photo:getRawMetadata( 'keywords' )
    for _, kw in ipairs( existingKeywords ) do
        photo.catalog:withWriteAccessDo( 'remove keyword', function() 
            photo:removeKeyword( kw ) 
        end )
    end
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
                return SSUtil.split( keywordStr, ',' )
            end
        end
    end

    return {}
end

import 'LrTasks'.startAsyncTask( SWSSMenuItem.startReplace )
