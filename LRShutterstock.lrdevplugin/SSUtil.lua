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

SSUtil = {}

--============================================================================--

function SSUtil.showInShutterstock( photo ) 
    local ssID = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockId' )
    if ssID then
        local url = string.format( "https://submit.shutterstock.com/catalog_manager/images/%s", ssID )
        LrHttp.openUrlInBrowser( url )
        return true
    end

    return false
end

function SSUtil.showInShutterstockByID( ssID ) 
    if ssID then
        local url = string.format( "https://submit.shutterstock.com/catalog_manager/images/%s", ssID )
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
