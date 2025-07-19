local WEBHOOK = "https://discord.com/api/webhooks/1395923548044005406/XtdiHIMtc5_BLFHBkKnTRt1GiAxPUqR_v8B-_CB13cffQ4Kgheg_Q74SXXHWu8zRUsJl" -- Tu nuevo webhook

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

-- Función para enviar request (compatible con Synapse y otros exploits)
local sendRequest = syn and syn.request or http_request or request

-- Obtener top jugadores con más cash
local function GetTopPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local stats = p:FindFirstChild("leaderstats")
        local cash = stats and stats:FindFirstChild("Cash")
        if cash then
            table.insert(list, {Name = p.Name, Display = p.DisplayName, Cash = cash.Value, ID = p.UserId})
        end
    end
    table.sort(list, function(a, b) return a.Cash > b.Cash end)
    return list
end

-- Enviar mensaje al webhook con top 5 jugadores
local function SendTopWebhook()
    local top = GetTopPlayers()
    if #top == 0 then return end

    local lines = {
        "📊 ZENIHT FINDER | Jugadores más ricos detectados",
        "💰 Top 5 Jugadores con más Cash"
    }
    for i = 1, math.min(5, #top) do
        local p = top[i]
        table.insert(lines, string.format("%d. %s (%s) | 💰 %d | 🆔 %d", i, p.Display, p.Name, p.Cash, p.ID))
    end
    table.insert(lines, string.format("JobId: %s | PlaceId: %d", tostring(game.JobId), game.PlaceId))

    local success, err = pcall(function()
        sendRequest({
            Url = WEBHOOK,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["User-Agent"] = "ZENIHT-BOT-" .. tostring(math.random(1000, 9999))
            },
            Body = HttpService:JSONEncode({
                content = table.concat(lines, "\n")
            })
        })
    end)

    if not success then
        warn("🚫 Webhook bloqueado o falló: ", err)
    end
end

-- Función para teletransportar a otro servidor aleatorio (server hop)
local function TeleportToAnotherServer()
    local placeId = game.PlaceId
    local servers = {}
    local pageCursor = nil

    local function getServers(cursor)
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId)
        if cursor then
            url = url .. "&cursor=" .. cursor
        end
        local response = syn and syn.request or http_request or request
        local success, result = pcall(function()
            return response({
                Url = url,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "ZENIHT-SERVERHOP"
                }
            })
        end)

        if success and result and result.StatusCode == 200 then
            local data = HttpService:JSONDecode(result.Body)
            return data
        end
        return nil
    end

    -- Obtener servidores públicos (hasta 500)
    repeat
        local data = getServers(pageCursor)
        if not data then break end

        for _, server in ipairs(data.data) do
            if server.playing > 0 and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end

        pageCursor = data.nextPageCursor
    until not pageCursor or #servers >= 500

    if #servers == 0 then
        warn("No se encontraron servidores alternativos.")
        return
    end

    -- Elegir un servidor random y teletransportar
    local randomServer = servers[math.random(1, #servers)]
    print("Teleportando a servidor: " .. randomServer)
    TeleportService:TeleportToPlaceInstance(placeId, randomServer, Players.LocalPlayer)
end

-- Espera que carguen los jugadores para enviar el webhook
task.spawn(function()
    repeat wait(1) until #Players:GetPlayers() > 0
    wait(5)  -- espera extra para que carguen datos
    SendTopWebhook()
end)

-- Ejemplo de uso: llamar a TeleportToAnotherServer() para hacer server hop
-- Descomenta esta línea para teletransportarte automáticamente a otro servidor
-- TeleportToAnotherServer()
