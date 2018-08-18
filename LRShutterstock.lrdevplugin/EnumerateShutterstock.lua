--[[----------------------------------------------------------------------------

EnumerateShutterstock.lua

--------------------------------------------------------------------------------

 Copyright 2018 Chris Anderson
 All Rights Reserved.

------------------------------------------------------------------------------]]

local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local catalog = LrApplication.activeCatalog()
require 'SSUtil'

ESMenuItem = {}

function ESMenuItem.findInCatalogBySSId( ssID ) 
    local photos = catalog:findPhotos { 
        searchDesc = { 
            criteria = "allPluginMetadata", 
            operation = "all", 
            value = ssID, 
        }, 
    }

    if photos == nil then
        return nil
    end

    -- double check the SSID to make sure we have the proper match
    results = {}
    for _, photo in ipairs( photos ) do
        local id = photo:getPropertyForPlugin( 'com.shutterstock.lightroom.manager', 'ShutterstockId' )
        if t == title then
            results[#results + 1] = photo
        end
    end

    if #results == 0 then
        return nil
    else
        return results
    end
end

function ESMenuItem.findInCatalogByTitle( title ) 
    local photos = catalog:findPhotos { 
        searchDesc = { 
            criteria = "title", 
            operation = "all", 
            value = title, 
        }, 
    }

    if photos == nil then
        return nil
    end

    results = {}
    for _, photo in ipairs( photos ) do
        local t = photo:getFormattedMetadata( 'title' )
        if t == title then
            results[#results + 1] = photo
        end
    end

    if #results == 0 then
        return nil
    else
        return results
    end
end

function ESMenuItem.enumShutterstock()
    --local photos = ESMenuItem.findInCatalogBySSId( "1011265699" )
    local photos = ESMenuItem.findInCatalogByTitle( "Beautiful costumes from the San Francisco 2018 Carnival" )
    catalog:setSelectedPhotos( photos[1], photos ) 
end

import 'LrTasks'.startAsyncTask( ESMenuItem.enumShutterstock )
