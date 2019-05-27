--[[----------------------------------------------------------------------------

SSUtil.lua

--------------------------------------------------------------------------------

 Copyright 2018 Chris Anderson
 All Rights Reserved.

------------------------------------------------------------------------------]]

local LrHttp = import 'LrHttp'
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'
local LrPathUtils = import 'LrPathUtils'
local LrPhotoPictureView = import 'LrPhotoPictureView'

--JSON = require 'JSON.lua'

------------------------------------------------------------------------------]]

SSUtil = {}

--============================================================================--

-- Notes
-- Download catalog info in blocks of 500
--    https://submit.shutterstock.com/api/catalog_manager/media_types/all/items?filter_type=keywords&filter_value=&page_number=1&per_page=500&sort=popular
-- Metadata for one image
--    https://submit.shutterstock.com/api/content_editor/media/P1327424384

function SSUtil.getUserName()
    return 'Chris W Anderson'
end

function SSUtil.getUserNameSafe()
    return 'Chris%20W%20Anderson'
end

function SSUtil.getCatalogFilename()
    return "C:\\Photos\\Shutterstock\\catalog.tsv"
end

function SSUtil.getSsScrapeImagePrefix()
    -- Example https://www.shutterstock.com/image-photo/water-buffalo-looks-one-piece-grass-1037674936
    -- If title words are not included it will re-direct to title version
    return "https://www.shutterstock.com/image-photo/"
end

function SSUtil.getEditImageUrl( ssID )
    -- Example: https://submit.shutterstock.com/catalog_manager/images/1037710735
    -- Does not include title
    if ssID then
        return "https://submit.shutterstock.com/catalog_manager/images/" .. ssID
    else
        return nil
    end
end

function SSUtil.getSSIdFromPhoto( photo )
    if photo == nil then
        return nil
    end
    
    local ssID = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockId' )
    if ssID then
        return ssID
    end

    local shutterstockUrl = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockUrl' )
    if shutterstockUrl then
        return SSUtil.getIdFromEndOfUrl( shutterstockUrl )
    end

    local closeUrl = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'CloseUrl' )
    if closeUrl then
        return SSUtil.getIdFromEndOfUrl( closeUrl )
    end

    return nil
end

function SSUtil.showInShutterstock( photo ) 
    local ssID = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockId' )
    local closeUrl = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'CloseUrl' )
    local shutterstockUrl = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockUrl' )
    
    if shutterstockUrl then
        LrHttp.openUrlInBrowser( shutterstockUrl )
        return true
    end

    if ssID then
        SSUtil.showInShutterstockByID( ssID )
    end

    if closeUrl then
        ssID = SSUtil.getIdFromEndOfUrl( closeUrl )
        
        if ssID then
            SSUtil.showInShutterstockByID( ssID )
        else
            LrHttp.openUrlInBrowser( closeUrl )
        end

        return true
    end

    return false
end

function SSUtil.getIdFromEndOfUrl( url )
    if url then
        -- Example: https://www.shutterstock.com/image-photo/water-buffalo-looks-one-piece-grass-1037674936
        local temp = string.reverse( url )
        local i = string.find( temp, '-' )
        if i ~= nil then
            return string.reverse( string.sub( temp, 1, i - 1 ) )
        end
    end

    return nil
end

function SSUtil.showInShutterstockByID( ssID ) 
    if ssID then
        local url = SSUtil.getEditImageUrl( ssID )
        LrHttp.openUrlInBrowser( url )
        return true
    end

    return false
end

function SSUtil.showScrapeUrlInShutterstock( ssID )
    if ssID then
        local url = SSUtil.getSsScrapeImagePrefix() .. ssID
        LrHttp.openUrlInBrowser( url )
        return true
    end

    return false
end

function SSUtil.cleanFilename( photo )
    local f = photo:getFormattedMetadata( 'fileName' )
    if f == nil then
        LrDialogs.showError( "file name cannot be nil" )
        return nil
    end

    f = LrPathUtils.removeExtension( f )
    return f 
end 

function SSUtil.createFtpConnection()
    local ftpParams = {}
    ftpParams.passive = 'normal'
    ftpParams.password = 'CIvmogUnOaslyd5'
    ftpParams.path = '/submit'
    ftpParams.port = 21
    ftpParams.protocol = 'ftp'
    ftpParams.server = 'ftp.shutterstock.com'
    ftpParams.username = 'Chand2048@hotmail.com'
    local connection = LrFtp.create( ftpParams, 2 )
    if connection.connected then
        LrDialogs.showError( "connected to ftp!" )
    else
        LrDialogs.showError( "failed to connect to ftp" )
    end

    return connection
end

-- Ask user to verify if the photo matches the thumbnails
function SSUtil.verifyPhoto( photo, fields )
    local lrThumb = LrPhotoPictureView.makePhotoPictureView{
        width = 128, height = 128, photo = photo,
    }
    
    local photoTitle = photo:getFormattedMetadata( 'title' )
    local ssTitle = fields[5]
    local ssID = fields[1]
    local ssThumb = "C:\\Photos\\shutterstock\\" .. ssID .. ".jpg"
    local dialogResult = nil
    
    LrFunctionContext.callWithContext( "showCustomDialog", function( context )
	    local f = LrView.osFactory()
        local props = LrBinding.makePropertyTable( context )
	    local c = f:row {
            bind_to_object = props,
            f:column {
                f:static_text { title = "Lightroom", },
                lrThumb, 
                f:static_text { title = photoTitle, width = 200, height = 200 },
            },
            f:column {
                f:static_text { title = "Shutterstock", },
                f:static_text { title = "", },
                f:picture { value = ssThumb, },
                f:static_text { title = "", },
                f:static_text { title = ssTitle, width = 200, height = 200, },
            },
        }
        
        dialogResult = LrDialogs.presentModalDialog {
            title = "Verify this is the same image...",
            contents = c,
        }
    end)

    return dialogResult == "ok"
end

function SSUtil.showUser( m1, m2 )
	LrFunctionContext.callWithContext( "showCustomDialog", function( context )
	    local f = LrView.osFactory()
	    local props = LrBinding.makePropertyTable( context )
	    local c = f:row {
		    bind_to_object = props,
		    f:edit_field {
			    value = m1,
			    enabled = true,
		    },
		    f:edit_field {
			    value = m2,
			    enabled = true,
		    }
	    }
	    LrDialogs.presentModalDialog {
			    title = "Custom Dialog",
                contents = c,
		    }
	end)
end

function SSUtil.flipKeyValue( table )
    local outTable = {}
    for key, val in pairs(table) do
        outTable[val] = key
    end

    return outTable
end

function SSUtil.split( pString, pPattern )
    local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
    local fpat = "(.-)" .. pPattern
    local last_end = 1
    local s, e, cap = pString:find(fpat, 1)
    
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(Table,cap)
        end
    
        last_end = e+1
        s, e, cap = pString:find(fpat, last_end)
    end
   
    if last_end <= string.len(pString) then
        cap = pString:sub(last_end)
        table.insert(Table, cap)
    end
    
    return Table
end

function SSUtil.findInCatalogBySSId( catalog, ssID ) 
    local photos = catalog:findPhotos { 
        searchDesc = { 
            criteria = "allPluginMetadata", 
            operation = "all", 
            value = ssID, 
        }, 
    }

    if photos == nil then
        return {}
    end

    -- double check the SSID to make sure we have the proper match
    results = {}
    local i = 1
    for _, photo in ipairs( photos ) do
        local id = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockId' )
        if t == title then
            results[i] = photo
            i = i + 1
        end
    end

    return results
end

function SSUtil.findInCatalogByTitle( catalog, title ) 
    local photos = catalog:findPhotos { 
        searchDesc = { 
            criteria = "title", 
            operation = "all", 
            value = title, 
        }, 
    }

    if photos == nil then
        return {}
    end

    results = {}
    local i = 1
    for _, photo in ipairs( photos ) do
        local t = photo:getFormattedMetadata( 'title' )
        if t == title then
            results[i] = photo
            i = i + 1
        end
    end

    return results
end

function SSUtil.updatePlugProp( photo, propName, value )
    if photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', propName ) ~= value then
        photo.catalog:withPrivateWriteAccessDo( function() 
            photo:setPropertyForPlugin( _PLUGIN, propName, value ) 
        end )

        return true
    end

    return false
end

function SSUtil.setMatch( photo, fields, matchDescription )
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

    local c = false
    c = SSUtil.updatePlugProp( photo, 'ShutterstockId', fields[1] ) or c
    c = SSUtil.updatePlugProp( photo, 'ShutterstockVerified', "yes" ) or c
    c = SSUtil.updatePlugProp( photo, 'ShutterstockStatus', "Accepted" ) or c
    c = SSUtil.updatePlugProp( photo, 'ShutterstockEditorial', fields[6] ) or c
    c = SSUtil.updatePlugProp( photo, 'ShutterstockUploadDate', fields[9] ) or c
    c = SSUtil.updatePlugProp( photo, 'ShutterstockThumbUrl', fields[10] ) or c
    c = SSUtil.updatePlugProp( photo, 'ShutterstockThumbUrl480', fields[11] ) or c
    c = SSUtil.updatePlugProp( photo, 'ShutterstockUrl', SSUtil.getEditImageUrl( fields[1] ) ) or c
    c = SSUtil.updatePlugProp( photo, 'CloseUrl', nil ) or c
    c = SSUtil.updatePlugProp( photo, 'ShutterstockAudit', matchDescription ) or c

    if c then
        photo.catalog:withPrivateWriteAccessDo( function() 
            photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockLast', os.date('%c') )
        end )
    end

    return c
end

function SSUtil.updateTitle( photo, title )
    photo.catalog:withWriteAccessDo( 'update title', function() 
        photo:setRawMetadata( 'title', title )
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockAudit', 'Title updated from shutterstock' )
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockLast', os.date('%c') )
    end )
end

function SSUtil.setFound( photo, ssID, msg )
    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockId', ssID ) 
    end )

    local url = SSUtil.getEditImageUrl( ssID )
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
        if msg == nil then
            msg = 'Found in Shutterstock'
        end  
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockAudit', msg )
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockLast', os.date('%c') )
    end )
end

function SSUtil.setError( photo, closeUrl, msg )
    local status = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockStatus' )
    local audit = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockAudit' )

    if status == 'Error' and msg == audit then
        return
    end

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockId', nil ) 
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockVerified', nil ) 
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockUrl', nil ) 
    end )

    local ssID = SSUtil.getIdFromEndOfUrl( closeUrl )
    local url = SSUtil.getEditImageUrl( ssID )
    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'CloseUrl', url ) 
    end )
    
    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockStatus', 'Error' )
    end )
    
    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockAudit', msg ) 
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockLast', os.date('%c') )
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockUploadDate', nil )
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockEditorial', nil )
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockThumbUrl', nil )
    end )

    photo.catalog:withPrivateWriteAccessDo( function() 
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockThumbUrl480', nil )
    end )
end

function SSUtil.tableLength( t )
    local c = 0
    if t ~= nil then
        for k, v in pairs( t ) do
            c = c + 1
        end
    end

    return c
end

function SSUtil.verifyBySSId( photo, ssID )
    return SSUtil.verifyByUrl( photo, SSUtil.getSsScrapeImagePrefix() .. ssID )
end

function SSUtil.verifyByUrl( photo, url )
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

function SSUtil.trim( s )
    if s == nil then
        return nil
    end

    local temp = s:gsub("^%s*(.-)%s*$", "%1")
    if temp == nil then
        return nil
    end

    if string.len( temp ) == 0 then
        return nil
    end

    return temp
end

function SSUtil.readCatalogToRows( filenameFilter )
    local file = io.open(SSUtil.getCatalogFilename(), "r")
    io.input( file )

    local rows = {}
    local index = 1

    while true do
        local row = io.read()
        if row == nil then 
            break 
        end

        local fields = SSUtil.split( row, "\t" )
        local ssID = fields[1]

        if filenameFilter ~= nil then
            if fields[8] == filenameFilter then
                rows[index] = fields
                index = index + 1
            end
        else
            rows[index] = fields
            index = index + 1
        end
    end
    
    io.close( file )

    if filenameFilter ~= nil then
        LrDialogs.message( 'processing ' .. index - 1 .. ' files' )
    end

    return rows
end

-- Cache the TSV file
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
local catalogTSV = nil

-- Read the entire TSV and break into rows/columns
function SSUtil.getCatalogAsRows( photosToSkip, filenameFilter )
    if catalogTSV == nil then
        catalogTSV = SSUtil.readCatalogToRows( filenameFilter )
    end

    if photosToSkip ~= nil then
        local filtered = {}
        local i = 1
        
        for _, fields in pairs( catalogTSV ) do
            local ssID = fields[1]
            if photosToSkip[ ssID ] == nil then
                filtered[ i ] = fields
                i = i + 1
            end
        end

        return filtered
    else
        return catalogTSV
    end
end

function SSUtil.findInCatalogBySSID( ssID )
    local cat = SSUtil.getCatalogAsRows()
    for _, fields in pairs( catalogTSV ) do
        if fields[ 1 ] == ssID then
            return fields
        end
    end

    return nil
end