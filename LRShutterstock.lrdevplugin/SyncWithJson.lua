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
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'

local catalog = LrApplication.activeCatalog()

require 'SSUtil'

--============================================================================--

local fitler = nil
--local filter = "398A0281.jpg"
--local filter = "IMG_0488.jpg"
--local filter = "IMG_3833_4_5Enhancer_stitch.jpg"
--local filter = "398A8350.jpg"

SWSSMenuItem = {}

-- Build list by ID of all photos that are not verified
function SWSSMenuItem.selectedPhotoListByCatalogID()
    local photos = catalog.targetPhotos
    local list = {}
    for _, photo in ipairs( photos ) do
        local verified = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockVerified' )
        if verified ~= "yes" then
            local id = photo.localIdentifier
            if list[id] ~= nil then
                LrDialogs.message( "Duplicate ID!!! " .. id )
                SSUtil.updatePlugProp( photo, 'ShutterstockAudit', 'Duplicate shutterstock ID' )
                SSUtil.updatePlugProp( list[id], 'ShutterstockAudit', 'Duplicate shutterstock ID' )
            end

            list[id] = photo
        end 
    end

    return list
end

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

function SWSSMenuItem.compFilename( photo, cleanFilename )
    local f = photo:getFormattedMetadata( 'fileName' )
    local photoCleanFilename = LrPathUtils.removeExtension( f )
    if photoCleanFilename == cleanFilename then
        return true
    else
        return false
    end
end

function SWSSMenuItem.findInCatalogByFilename( filename, caption )
    local cleanFilename = LrPathUtils.removeExtension( filename )
    local photos = catalog:findPhotos { 
        searchDesc = { 
            criteria = "filename", 
            operation = "beginsWith", 
            value = cleanFilename, 
        }, 
    }

    if photos == nil then
        return {}
    end

    -- Verify the filename is correct because extension has changed
    local results = {}
    local i = 1
    for _, photo in ipairs( photos ) do
        if SWSSMenuItem.compFilename( photo, cleanFilename ) then
            results[i] = photo
            i = i + 1
        end
    end

    if filter ~= nul then
        LrDialogs.message( cleanFilename .. ' matched #: ' .. SSUtil.tableLength( results ) .. caption )
    end
    
    return results
end

function SWSSMenuItem.cropDistance( a, b )
    local axy = SSUtil.split( a, ' x ' )
    local bxy = SSUtil.split( b, ' x ' )
    
    local distanceX = math.abs((axy[1] + 0) - (bxy[1] + 0))
    local distanceY = math.abs((axy[2] + 0) - (bxy[2] + 0))

    if filter ~= nul then
        LrDialogs.message( "comparing " .. a .. " with " .. b .. "\n" .. "distance x=" .. distanceX .. "  distancy y=" .. distanceY )
    end

    return distanceX + distanceY
end

function SWSSMenuItem.syncOneRow( catPhotos, fields )
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
    -- 12 writer.Write(string.Format("{0} x {1}", this.width, this.height)); writer.Write(delim);
    -- writer.Write("\r\n");

    local photos = SWSSMenuItem.findInCatalogByFilename( fields[8], fields[5] )
    local matched = {}
    local i = 1

    -- First filter by localIdentifier (currently selected)
    for _, photo in pairs(photos) do
        local lrID = photo.localIdentifier
        local photoMatch = catPhotos[ lrID ]
        if photoMatch ~= nil then
            matched[i] = photo
            i = i + 1
        end
    end

    -- Filter by cropDistance
    local cropMatch = {}
    local closeMatch = {}
    local j = 1
    i = 1
    
    -- Put all crop matches into an exact match and a close match tables
    if SSUtil.tableLength( matched ) > 1 then
        for _, photo in pairs( matched ) do
            local crop = photo:getFormattedMetadata( 'croppedDimensions' )
            local cropDistance = SWSSMenuItem.cropDistance( fields[12], crop )

            if cropDistance == 0 then
                if filter ~= nil then
                    LrDialogs.message( "exact crop match: " .. fields[12] .. "\n" .. fields[5] )
                end
                
                cropMatch[i] = photo
                i = i + 1
            else
                if cropDistance <= 2 then
                    if filter ~= nul then
                        LrDialogs.message( "close crop match: " .. fields[12] .. " with " .. crop .. "\n" .. fields[5] )
                    end
                    
                    closeMatch[j] = photo
                    j = j + 1
                end
            end
        end

        -- Use the crop match if there was anything in the table
        if SSUtil.tableLength( cropMatch ) >= 1 then
            if filter ~= nil then
                LrDialogs.message( SSUtil.tableLength( cropMatch ) .. " crop matches" .. "\n" .. fields[5])
            end
            matched = cropMatch
        else
            -- Fall back to a close crop match if the exact match was empty
            if SSUtil.tableLength( closeMatch ) > 0 then
                if filter ~= nil then
                    LrDialogs.message( SSUtil.tableLength( closeMatch ) .. " close matches" .. "\n" .. fields[5])
                end
                matched = closeMatch
            end
        end
    end

    -- Use the matched table if ther is only one in there
    local changed = false
    for _, photo in pairs( matched ) do
        if SSUtil.verifyPhoto( photo, fields ) == true then
            if filter ~= nil then
                LrDialogs.message( "Setting match for " .. fields[8] .. "\n" .. fields[5] )
            end

            local lrID = photo.localIdentifier
            catPhotos[ lrID ] = nil 
    
            changed = SSUtil.setMatch( photo, fields, 'JSON Filename match' )
            break
        end
    end

    return false, changed
end

function SWSSMenuItem.startSyncWithJson( )
    local verifiedPhotos = SWSSMenuItem.selectedPhotoListBySSID( )
    local catPhotos = SWSSMenuItem.selectedPhotoListByCatalogID( )
    local catPhotosLen = SSUtil.tableLength( catPhotos )
    local msg = "Matching to JSON catalog..."
    pscope = LrProgressScope( { title = msg } )

    LrFunctionContext.callWithContext( "SyncWithJson", function(context)
        context:addCleanupHandler( function()
                pscope:cancel()
            end) 

        local rows = SSUtil.getCatalogAsRows( verifiedPhotos )
        local rowsByFilename = {}
        local complete = 0
        local rowCount = SSUtil.tableLength( rows )
        local matched = 0
        local changed = 0
        pscope:setCancelable( true )
        pscope:attachToFunctionContext( context )
        pscope:setPortionComplete( complete, rowCount )

        for _, fields in pairs( rows ) do
            pscope:setCaption( complete .. ' of ' .. rowCount .. ' matched:' .. matched .. ' updated:' .. changed .. " " .. fields[8] )
            pscope:setPortionComplete( complete, rowCount )

            local ssID = fields[1]
            if verifiedPhotos[ssID] == nil then
                local m, c = SWSSMenuItem.syncOneRow( catPhotos, fields )
                if m then
                    matched = matched + 1
                end
                if c then 
                    changed = changed + 1
                end
            end

            -- Add the fields to a collection indexed by filename
            local cleanFilename = LrPathUtils.removeExtension( fields[8] )
            if rowsByFilename[ cleanFilename ] == nil then
                local set = {}
                set[1] = fields
                rowsByFilename[ cleanFilename ] = set
            else
                local set = rowsByFilename[ cleanFilename ]
                local len = SSUtil.tableLength( set )
                set[ len + 1 ] = fields
            end

            complete = complete + 1
        end

        LrDialogs.message( "Sync completed \n  Processed: " .. rowCount ..
                            "\n  matched: " .. matched ..
                            "\n  changed: " .. changed)

        catPhotosLen = SSUtil.tableLength( catPhotos )
        for _, photo in pairs( catPhotos ) do
            local f = photo:getFormattedMetadata( 'fileName' )
            local photoCleanFilename = LrPathUtils.removeExtension( f )
            
            local fileset = rowsByFilename[ photoCleanFilename ]
            if fileset ~= nil then
                for _, fields in pairs( fileset ) do
                    if SSUtil.verifyPhoto( photo, fields ) == true then
                        if filter ~= nil then
                            LrDialogs.message( "Setting match for " .. fields[8] .. "\n" .. fields[5] )
                        end

                        local lrID = photo.localIdentifier
                        catPhotos[ lrID ] = nil 
                
                        changed = SSUtil.setMatch( photo, fields, 'JSON Filename match' )
                    end
                end
            end
        end

        pscope:done()

    end )
end

import 'LrTasks'.startAsyncTask( SWSSMenuItem.startSyncWithJson )
