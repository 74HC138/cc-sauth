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

function totp.calc(secret, tx, t0)
    tx = tx or 30
    t0 = t0 or 0
    local t = os.epoch("utc") / 1000
    local ct = math.floor((t - t0) / tx)
    local ct_str = ""
    for i = 8, 1, -1 do
        ct_str = ct_str .. string.char(bit.band(bit.brshift(ct, 8 * (i - 1)), 0xFF))
    end

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