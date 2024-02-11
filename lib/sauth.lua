--Secure Authentication service

local sha = require("sha")
local rns = require("rns")
local basexx = require("basexx")
local base64Table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local config = {}
config["binds"] = {}
config["accounts"] = {}
local tokens = {}

local sauth = {}

local function writeConfig()

end
local function log(msg, level)
    level = level or 0
    os.queueEvent("log", level, msg)
end

local function command_bind(request, senderId)
    os.queueEvent("sauth_bindRequest", senderId, request["id"])
    local timeout = os.startTimer(30)
    local accept = false
    while true do
        local event, param = os.pullEvent()
        if (event == "timer") then
            if (param == timeout) then
                accept = false
                break
            end
        end
        if (event == "sauth_bindAccept") then
            accept = true
            break
        end
        if (event == "sauth_bindReject") then
            accept = false
            break
        end
    end
    if (accept) then
        local bindToken
        while true do
            bindToken = ""
            for i = 1, 10 do
                bindToken = bindToken .. base64Table[math.random(1, 64)]
            end
            if (config["binds"][bindToken] == nil) then
                break
            end
        end
        config["binds"][bindToken] = {}
        config["binds"][bindToken]["phys_id"] = senderId
        config["binds"][bindToken]["id"] = request["id"]
        config["binds"][bindToken]["time"] = os.time()
        config["binds"][bindToken]["day"] = os.day()
        rns.send(receiverId, "sauth" .. textutils.serialise({type = "response", code = 200, rsp = "bind accepted", AuthToken = bindToken}))
        writeConfig()
    else
        rns.send(receiverId, "sauth" .. textutils.serialise({type = "response", code = 500, rsp = "bind failed"}))
    end
end
local function command_authtokentest(request, senderId)
    if (request["AuthToken"]) then
        if (config["binds"][request["AuthToken"]]) then
            rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 200, rsp = "AuthToken valid"}))
        else
            rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 500, rsp = "AuthToken invalid"}))
        end
    else
        rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 400, rsp = "no AuthToken"}))
    end
end
local function command_login(request, senderId, type)
    if (request["AuthToken"] and request["name"] and request["pwd"]) then
        if (config["binds"][request["AuthToken"]]) then
            local nameHash = basexx.from_base64(request["name"])
            local pwdHash = basexx.from_base64(request["pwd"])
            local loggedIn = false
            local loggedUser
            for _, user in pairs(config["accounts"]) do
                if (user["name_hash"] == nameHash and user["pwd_hash"] == pwdHash) then
                    loggedIn = true
                    loggedUser = user
                    break
                end
            end
            if (loggedIn) then
                loggedUser["last_logtime"] = os.time()
                loggedUser["last_logdate"] = os.date()
                log("Terminal \"" .. config["binds"][request["AuthToken"]]["id"] .. "\" logged in " .. (loggedUser["name"] or loggedUser["name_hash"]), 1)
                local otToken
                while true do
                    otToken = ""
                    for i = 1, 16 do
                        otToken = otToken .. string.byte(base64Table[math.random(1, 64)])
                    end
                    if (tokens[otToken] == nil) then
                        break
                    end
                end
                tokens[otToken] = {}
                tokens[otToken]["type"] = type
                tokens[otToken]["age"] = 0
                rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 200, rsp = "logged in", otToken = otToken}))
            else
                log("Terminal \"" .. config["binds"][request["AuthToken"]]["id"] .. "\" tried to login as " .. nameHash, 1)
                rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 500, rsp = "login failed"}))
            end
        else
            rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 401, rsp = "bad AuthToken"}))
        end
    else
        rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 400, rsp = "missing fields"}))
    end
end
function command_logout(request, senderId)
    if (request["AuthToken"] and request["UserToken"]) then
        if (config["binds"][request["AuthToken"]]) then
            if (tokens[request["UserToken"]]) then
                tokens[request["UserToken"]] = nil
                rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 200, rsp = "logged out"}))
            else
                rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 500, rsp = "bad UserToken"}))
            end
        else
            rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 401, rsp = "bad AuthToken"}))
        end
    else
        rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 400, rsp = "missing fields"}))
    end
end
local function command_usertokentest(request, senderId)
    if (request["AuthToken"] and request["UserToken"]) then
        if (config["binds"][request["AuthToken"]]) then
            if (tokens[request["UserToken"]]) then
                tokens[request["UserToken"]]["age"] = 0 --refreshen user token
                if (tokens[request["UserToken"]]["type"] == "ot") then
                    tokens[request["UserToken"]] = nil --delete one time token after use
                end
                rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 200, rsp = "token valid"}))
            else
                rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 500, rsp = "bad UserToken"}))
            end
        else
            rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 401, rsp = "bad AuthToken"}))
        end
    else
        rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 400, rsp = "missing fields"}))
    end
end

function sauth.daemon()
    print("started SAuth daemon")

    while true do
        local _, senderId, msg = os.pullEvent("rns_receive")
        local headerStart, headerEnd = string.find(msg, "sauth*{")
        if (headerStart == 1) then
            local requestString = string.sub(msg, headerEnd)
            local request = textutils.unserialise(requestString)
            if (request) then
                --got a decodable request
                if (request["type"]) then
                    --got a valid request
                    if (request["type"] == "command") then
                        if (request["cmd"]) then
                            --valid command
                            if (request["cmd"] == "bind") then
                                --bind request
                                command_bind(request, senderId)
                            elseif (request["cmd"] == "authtokentest") then
                                --AuthToken test
                                command_authtokentest(request, senderId)
                            elseif (request["cmd"] == "otlogin") then
                                --get one time user login
                                command_login(request, senderId, "ot")
                            elseif (request["cmd"] == "login") then
                                --get permanent user login
                                command_login(request, senderId, "permanent")
                            elseif (request["cmd"] == "logout") then
                                --logout user
                                command_logout(request, senderId)
                            elseif (request["cmd"] == "usertokentest") then
                                --UserToken test
                                command_usertokentest(request, senderId)
                            else
                                rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 105, rsp = "bad command"}))
                            end
                        else
                            rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 104, rsp = "invalid command format"}))
                        end
                    else
                        rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 103, rsp = "bad request"}))
                    end
                else
                    --no type header, throw a 402
                    rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 102, rsp = "bad request field"}))
                end
            else
                rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 101, rsp = "bad request format"}))
            end
        else
            rns.send(senderId, "sauth" .. textutils.serialise({type = "response", code = 100, rsp = "bad request header"}))
        end
    end
end