local sha1 = require("sha1")

local totp = {}

local function truncateHash(hash)
    local offset = tonumber(hash:sub(-1), 16)
    local subset = hash:sub(offset + 1, offset + 8)
    local intValue = tonumber(subset, 16)
    local truncated = intValue % 1000000
    return string.format("%06d", truncated)
end

function totp.calc(secret, tx, t0)
    tx = tx or 30
    t0 = t0 or 0
    local t = os.epoch("utc") / 1000
    local ct = math.floor((t - t0) / tx)
    local ct_hex = string.format("%x", ct)

    print("ct: " .. ct)
    print("ct_hex: " .. ct_hex)
    
    local hmacHash = sha1.hmac(secret, ct_hex)

    print("hmacHash: " .. hmacHash)

    local otp = truncateHash(hmacHash)

    print("otp: " .. otp)

    return otp
end

function totp.generateUri(name, key, issuer)
    local uri = "otpauth://totp/"
    if issuer then
        uri = uri .. issuer .. ":"
    end
    uri = uri .. name .. "?secret=" .. key .. "&issuer=" .. (issuer or "")
    return uri
end

