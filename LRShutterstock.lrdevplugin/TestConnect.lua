local https = require("socket.http")
local resp = {}
local r, c, h, s = https.request{
    url = "https://contributor-accounts.shutterstock.com/login",
    --url = "https://submit.shutterstock.com/catalog_manager/images/1037710735",
    sink = ltn12.sink.table(resp)
}

for k, v in pairs(resp) do
    print( k .. ' ' .. v .. '\n' )
end

--[[
local https = require("ssl.https")
local one, code, headers, status = https.request{
       url = "https://www.google.com",
       key = "/root/client.key",
       certificate="/root/client.crt",
       cafile="/root/ca.crt"
}
--]]