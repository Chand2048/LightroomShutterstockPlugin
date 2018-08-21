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

--JSON = require 'JSON.lua'

------------------------------------------------------------------------------]]

SSUtil = {}

--============================================================================--

function SSUtil.getUserName()
    return 'Chris W Anderson'
end

function SSUtil.getUserNameSafe()
    return 'Chris%20W%20Anderson'
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
   
    if last_end <= #pString then
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
    for _, photo in ipairs( photos ) do
        local id = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockId' )
        if t == title then
            results[#results + 1] = photo
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
    for _, photo in ipairs( photos ) do
        local t = photo:getFormattedMetadata( 'title' )
        if t == title then
            results[#results + 1] = photo
        end
    end

    return results
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

function SSUtil.setFound( photo, ssID )
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
        photo:setPropertyForPlugin( _PLUGIN, 'ShutterstockAudit', 'Found in Shutterstosck' )
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
end

function SSUtil.tableLength( t )
    local c = 0
    for _, _ in pairs( t ) do
        c = c + 1
    end

    return c
end