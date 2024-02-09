local sha1 = require("sha1")
local basexx = require("basexx")

local totp = {}

local function truncateHash(hash)
    local offset = tonumber(hash:sub(-1), 16) + 1
    local subset = hash:sub(offset * 2 - 1, offset * 2 + 7)
    local intValue = tonumber(subset, 16)
    local truncated = intValue % (10 ^ 6)
    return string.format("%06d", truncated)
end

local function rshift(x, n)
    return math.floor(x / 2^n)
end

function totp.calc(secret, tx, t0)
    tx = tx or 30
    t0 = t0 or 0
    local t = os.epoch("utc") / 1000
    local ct = math.floor((t - t0) / tx)
    
    -- Convert ct to big-endian format
    local ct_str = string.char(
        bit.band(rshift(ct, 56), 0xFF),
        bit.band(rshift(ct, 48), 0xFF),
        bit.band(rshift(ct, 40), 0xFF),
        bit.band(rshift(ct, 32), 0xFF),
        bit.band(rshift(ct, 24), 0xFF),
        bit.band(rshift(ct, 16), 0xFF),
        bit.band(rshift(ct, 8), 0xFF),
        bit.band(ct, 0xFF)
    )

    print("ct: " .. ct)
    
    local hmacHash = sha1.hmac(secret, ct_str)

    print("hmacHash: " .. hmacHash)

    local otp = truncateHash(hmacHash)

    print("otp: " .. otp)

    return otp
end


function totp.generateUri(name, key, issuer)
    local key_base32 = basexx.to_base32(key)
    local uri = "otpauth://totp/"
    uri = uri .. name .. "?secret=" .. key_base32
    if (issuer) then
        uri = uri .. "&issuer=" .. issuer
    end
    return uri
end

function totp.generateSecret(length)
    local key = ""
    for _ = 1, length do
        local index = math.random(0, 255)
        key = key .. string.char(index)
    end
    return key
end

return totp