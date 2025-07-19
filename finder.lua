-- Carga Kavo UI con tema azul (Ocean)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("ZENIHT FINDER", "Ocean") -- Ocean es tema azul
local Tab = Window:NewTab("Main")
local Section = Tab:NewSection("Funciones")

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local WEBHOOK = "https://discord.com/api/webhooks/1395923548044005406/XtdiHIMtc5_BLFHBkKnTRt1GiAxPUqR_v8B-_CB13cffQ4Kgheg_Q74SXXHWu8zRUsJl" -- Pone tu webhook aquí

local sendRequest = syn and syn.request or http_request or request

if not sendRequest then
    warn("[ZENIHT] Error: sendRequest no está definido. ¿Estás usando un executor compatible?")
end

local function GetTopPlayers()
    print("[ZENIHT] Obteniendo lista de jugadores con cash...")
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local stats = p:FindFirstChild("leaderstats")
        local cash = stats and stats:FindFirstChild("Cash")
        if cash then
            table.insert(list, {Name = p.Name, Display = p.DisplayName, Cash = cash.Value, ID = p.UserId})
            print(string.format("[ZENIHT] Jugador: %s, Cash: %d", p.Name, cash.Value))
        else
            print(string.format("[ZENIHT] Jugador %s no tiene Cash", p.Name))
        end
    end
    table.sort(list, function(a, b) return a.Cash > b.Cash end)
    return list
end

local function SendTopWebhook()
    print("[ZENIHT] Preparando para enviar webhook...")
    local top = GetTopPlayers()
    if #top == 0 then
        warn("[ZENIHT] No hay jugadores con cash para enviar al webhook.")
        return
    end

    local fields = {}
    for i = 1, math.min(5, #top) do
        local p = top[i]
        table.insert(fields, {
            name = string.format("%d. %s (%s)", i, p.Display, p.Name),
            value = string.format("💰 Cash: %d\n🆔 ID: %d", p.Cash, p.ID),
            inline = false
        })
    end

    local embed = {
        title = "📊 ZENIHT FINDER | Jugadores más ricos detectados",
        color = 0x1E90FF,
        fields = fields,
        footer = {
            text = string.format("JobId: %s | PlaceId: %d", tostring(game.JobId), game.PlaceId)
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    local data = {embeds = {embed}}

    local success, err = pcall(function()
        sendRequest({
            Url = WEBHOOK,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["User-Agent"] = "ZENIHT-BOT-" .. tostring(math.random(1000, 9999))
            },
            Body = HttpService:JSONEncode(data)
        })
    end)

    if success then
        print("[ZENIHT] Webhook con embed enviado correctamente.")
    else
        warn("[ZENIHT] Error al enviar webhook:", err)
    end
end

local function TeleportToAnotherServer()
    print("[ZENIHT] Buscando servidores alternativos para teleportar...")
    local placeId = game.PlaceId
    local servers = {}
    local pageCursor = nil

    local function getServers(cursor)
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId)
        if cursor then
            url = url .. "&cursor=" .. cursor
        end
        local responseFunc = syn and syn.request or http_request or request
        local success, result = pcall(function()
            return responseFunc({
                Url = url,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "ZENIHT-SERVERHOP"
                }
            })
        end)

        if success and result and result.StatusCode == 200 then
            return HttpService:JSONDecode(result.Body)
        else
            warn("[ZENIHT] Error obteniendo servidores:", result and result.StatusCode or "No response")
            return nil
        end
    end

    repeat
        local data = getServers(pageCursor)
        if not data then break end

        for _, server in ipairs(data.data) do
            if server.playing > 0 and server.id ~= game.JobId then
                table.insert(servers, server.id)
                print("[ZENIHT] Servidor encontrado: " .. server.id .. " con jugadores: " .. server.playing)
            end
        end

        pageCursor = data.nextPageCursor
    until not pageCursor or #servers >= 500

    if #servers == 0 then
        warn("[ZENIHT] No se encontraron servidores alternativos para teleportar.")
        return
    end

    local randomServer = servers[math.random(1, #servers)]
    print("[ZENIHT] Teleportando a servidor: " .. randomServer)

    if not Players.LocalPlayer then
        warn("[ZENIHT] Error: Players.LocalPlayer es nil. Asegurate que esto corra en un LocalScript.")
        return
    end

    TeleportService:TeleportToPlaceInstance(placeId, randomServer, Players.LocalPlayer)
end

Section:NewButton("Enviar Top 5 al Webhook", "Envía los jugadores más ricos detectados al webhook", function()
    SendTopWebhook()
end)

Section:NewButton("Server Hop (Teleport a otro servidor)", "Teletransportarse a otro servidor aleatorio", function()
    TeleportToAnotherServer()
end)
