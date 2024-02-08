--RedNet Secure implimentation
--used to tranmit rednet data with encryption

local aes = require("aes")

local rns = {}

function rns.daemon()
    local sockets = {}
    print("started RNS daemon")

    while true do
        local senderID, message = rednet.receive("RNS")
        if sockets[tostring(senderID)] == nil then
            sockets[tostring(senderID)] = {}
            local key = ""
            for i = 1, 16 do
                key = key .. string.byte(math.random(0, 255))
            end
            sockets[tostring(senderID)] = aes:new(nil, key)
            local msgCrypt = sockets[tostring(senderID)]:encrypt(message)
            rednet.send(senderID, msgCrypt, "RNS")
        else
            local msgDecrypt = sockets[tostring(senderID)]:decrypt(message)
            sockets[tostring(senderID)] = nil
            os.queueEvent("rns_receive", senderID, msgDecrypt)
        end
    end
end

function rns.send(receiverID, msg, timeout)
    timeout = timeout or 30
    local key = ""
    for i = 1, 16 do
        key = key .. string.byte(math.random(0, 255))
    end
    local cipher = aes:new(nil, key)
    local msgCryptA = cipher:encrypt(msg)
    rednet.send(tonumber(receiverID), msgCryptA, "RNS")
    local senderID, msgCryptB
    while true do
        senderID, msgCryptB = rednet.receive("RNS", timeout)
        if senderID == nil then
            return false
        end
        if senderID == tonumber(receiverID) then
            break
        end
    end
    local msgCryptC = cipher:decrypt(msgCryptB)
    rednet.send(tonumber(receiverID), msgCryptC, "RNS")
    return true
end

function rns.receive(timeout)
    if timeout then
        local timer = os.startTimer(timeout)
    end

    while true do
        local event, senderID, msg = os.pullEvent()
        if (event == "timer") then
            if (senderID == timer) then
                return nil
            end
        end
        if (event == "rns_receive") then
            return senderID, msg
        end
    end
end

return rns