--[[----------------------------------------------------------------------------

SyncWithJson.lua

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
local LrPathUtils = import 'LrPathUtils'

local catalog = LrApplication.activeCatalog()

require 'SSUtil'

--============================================================================--

SWSSMenuItem = {}

function SWSSMenuItem.setMatch( photo, fields )
    -- Format from C# code
    -- char delim = '\t';
    -- 1 writer.Write(this.id); writer.Write(delim);
    -- 2 writer.Write(this.status); writer.Write(delim);
    -- 3 writer.Write(this.category1); writer.Write(delim);
    -- 4 writer.Write(this.category2); writer.Write(delim);
    -- 5 writer.Write(this.description); writer.Write(delim);
    -- 6 writer.Write(this.isEditorial); writer.Write(delim);
    -- 7 writer.Write(this.keywords); writer.Write(delim);
    -- 8 writer.Write(this.filename); writer.Write(delim);
    -- 9 writer.Write(this.uploadDate); writer.Write(delim);
    -- 10 writer.Write(this.thumbnailURL); writer.Write(delim);
    -- 11 writer.Write(this.thumbnailURL480); writer.Write(delim);
    -- writer.Write("\r\n");

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockId', fields[1] ) 
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockEditorial', fields[6] ) 
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockUploadDate', fields[9] ) 
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockThumbUrl', fields[10] ) 
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockThumbUrl480', fields[11] ) 
    end )

    local url = SSUtil.getEditImageUrl( fields[1] )
    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockUrl', url ) 
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'CloseUrl', nil ) 
    end )

    -- photo.catalog:withPrivateWriteAccessDo( function() 
    --     photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockStatus', fields[2] ) 
    -- end )

    photo.catalog:withPrivateWriteAccessDo( function()
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockAudit', 'JSON Filename match' )
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockLast', os.date('%c') )
    end )
end

function SWSSMenuItem.selectedPhotoListByCatalogID()
    local photos = catalog.targetPhotos
    local list = {}
    for _, photo in ipairs( photos ) do
        local id = photo.localIdentifier
        list[id] = photo
    end

    return list
end

function SWSSMenuItem.findInCatalogByFilename( filename )
    local cleanFilename = LrPathUtils.removeExtension( filename )
    local photos = catalog:findPhotos { 
        searchDesc = { 
            criteria = "all", 
            operation = "any", 
            value = cleanFilename, 
        }, 
    }

    if photos == nil then
        return {}
    end

    local results = {}
    local i = 1
    for _, photo in ipairs( photos ) do
        local f = photo:getFormattedMetadata( 'fileName' )
        local photoCleanFilename = LrPathUtils.removeExtension( f )
        if photoCleanFilename == cleanFilename then
            results[i] = photo
            i = i + 1
        end
    end

    return results
end

function SWSSMenuItem.syncOneRow( catPhotos, row )
    -- Format from C# code
    -- char delim = '\t';
    -- 1 writer.Write(this.id); writer.Write(delim);
    -- 2 writer.Write(this.status); writer.Write(delim);
    -- 3 writer.Write(this.category1); writer.Write(delim);
    -- 4 writer.Write(this.category2); writer.Write(delim);
    -- 5 writer.Write(this.description); writer.Write(delim);
    -- 6 writer.Write(this.isEditorial); writer.Write(delim);
    -- 7 writer.Write(this.keywords); writer.Write(delim);
    -- 8 writer.Write(this.filename); writer.Write(delim);
    -- 9 writer.Write(this.uploadDate); writer.Write(delim);
    -- 10 writer.Write(this.thumbnailURL); writer.Write(delim);
    -- 11 writer.Write(this.thumbnailURL480); writer.Write(delim);
    -- writer.Write("\r\n");

    local fields = SSUtil.split( row, "\t" )
    local photos = SWSSMenuItem.findInCatalogByFilename( fields[8] )
    for _, photo in pairs(photos) do
        local lrID = photo.localIdentifier
        local photoMatch = catPhotos[ lrID ]
        if photoMatch ~= nil then
            SWSSMenuItem.setMatch( photo, fields )
            return
        end
    end
end

function SWSSMenuItem.readFileToRows()
    local file = io.open("C:\\Photos\\Shutterstock\\catalog.tsv", "r")
    io.input( file )

    local rows = {}
    local index = 1

    while true do
        local row = io.read()
        if row == nil then 
            break 
        end

        rows[index] = row
        index = index + 1
    end

    io.close( file )
    return rows
end

function SWSSMenuItem.startSyncWithJson( )
    local catPhotos = SWSSMenuItem.selectedPhotoListByCatalogID( )
    local catPhotosLen = SSUtil.tableLength( catPhotos )
    local msg = "Reading catalog..."
    pscope = LrProgressScope( { title = msg } )

    LrFunctionContext.callWithContext( "SyncWithJson", function(context)
        context:addCleanupHandler( function()
                pscope:cancel()
            end) 

        local rows = SWSSMenuItem.readFileToRows()
        local complete = 0
        local rowCount = SSUtil.tableLength( rows )
        pscope:setCancelable( true )
        pscope:attachToFunctionContext( context )
        pscope:setPortionComplete( complete, rowCount )

        for _, row in pairs( rows ) do
            complete = complete + 1
            pscope:setCaption( complete .. ' of ' .. rowCount .. ' processed' )
            pscope:setPortionComplete( complete, rowCount )

            SWSSMenuItem.syncOneRow( catPhotos, row )
        end

        pscope:done()
    end )
end

import 'LrTasks'.startAsyncTask( SWSSMenuItem.startSyncWithJson )
