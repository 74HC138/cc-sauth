package.path = package.path .. ";lib/?.lua;lib/?/init.lua"

local INTERVAL		= 30;
local DIGITS		= 6;
local DIGEST 		= "SHA1";

local OTP  = require("otp")
local TOTP = require("totp")
local UTIL = require("util")
local qrenc = require("qrencode")
local qrdisp = require("qrdisplay")
local mon = peripheral.wrap("top")
mon.setTextScale(0.5)

function getUtc()
    return math.floor(os.epoch("utc") / 1000)
end

local BASE32_SECRET = UTIL.random_base32(16, OTP.util.default_chars)

OTP.type = "totp"
local tdata = OTP.new(BASE32_SECRET, DIGITS, DIGEST, 30) -- TODO: needs hmac algo, fix differentiation

local uri = OTP.util.build_uri(tdata.secret, "test", nil, "test", DIGEST, DIGITS, INTERVAL)
print("uri: " .. uri)

local _, qr = qrenc.qrcode(uri)
qrdisp.display(qr, mon)

while (true) do
    local otp = TOTP.now(tdata, getUtc())
    print("otp: " .. otp)
    sleep(2)
end

