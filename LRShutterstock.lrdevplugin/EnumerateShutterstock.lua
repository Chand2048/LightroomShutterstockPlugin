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


function ESMenuItem.enumShutterstock()
    --local photos = SSUtil.findInCatalogBySSId( catalog, "1011265699" )
    local photos = SSUtil.findInCatalogByTitle( catalog, "Beautiful costumes from the San Francisco 2018 Carnival" )
    catalog:setSelectedPhotos( photos[1], photos ) 
end

import 'LrTasks'.startAsyncTask( ESMenuItem.enumShutterstock )
