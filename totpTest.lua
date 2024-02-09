package.path = package.path .. ";lib/?.lua;lib/?/init.lua"

local totp = require("totp")
local qrenc = require("qrencode")
local qrdisp = require("qrdisplay")

local mon = peripheral.wrap("top")
mon.setTextScale(0.5)

local secret_key = totp.generateSecret(20)
local uri = totp.generateUri("testLogin", secret_key, "overkillSecurity")
print(uri)

_, tab = qrenc.qrcode(uri)
qrdisp.display(tab, mon)

print("current totp:")
while true do
    local totp = totp.calc(secret_key)
    print(totp)
    sleep(10)
end