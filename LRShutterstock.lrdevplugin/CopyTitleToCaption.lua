--[[----------------------------------------------------------------------------

CopyTitleToCaption.lua

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

function SWSSMenuItem.startCopy( )
    local catPhotos = catalog.targetPhotos
    local catPhotosLen = SSUtil.tableLength( catPhotos )
    local msg = string.format( "Copying title to caption %s photos", catPhotosLen )
    pscope = LrProgressScope( { title = msg } )

    LrFunctionContext.callWithContext( "CopyTitleToCaption", function(context)
        context:addCleanupHandler( function()
                pscope:cancel()
            end) 

        local complete = 0
        local completeInc = 100 / catPhotosLen
        pscope:setCancelable( true )
        pscope:attachToFunctionContext( context )
        pscope:setPortionComplete(complete, 100)

        for _, photo in ipairs( catPhotos ) do
            pscope:setCaption( photo:getFormattedMetadata( 'fileName' ) )
            pscope:setPortionComplete(complete, 100)
            
            local caption = SSUtil.trim( photo:getFormattedMetadata( 'caption' ) )
            if caption == nil then
                local title = SSUtil.trim( photo:getFormattedMetadata( 'title' ) )
                if title ~= nil then
                    photo.catalog:withWriteAccessDo( 'update caption', function() 
                        photo:setRawMetadata( 'caption', title )
                    end )

                    photo.catalog:withPrivateWriteAccessDo( function() 
                        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockAudit', 'copied title to caption' )
                    end )

                    photo.catalog:withPrivateWriteAccessDo( function() 
                        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockLast', os.date('%c') )
                    end )
                end
            end

            complete = complete + completeInc
        end 

        pscope:done()
    end )
end

import 'LrTasks'.startAsyncTask( SWSSMenuItem.startCopy )
