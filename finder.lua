-- Carga Kavo UI con tema azul (Ocean)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("ZENIHT FINDER PARA POBRES", "Ocean") -- Tema azul
local Tab = Window:NewTab("Main")
local Section = Tab:NewSection("Funciones")

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")

local WEBHOOK = "https://discord.com/api/webhooks/1395923548044005406/XtdiHIMtc5_BLFHBkKnTRt1GiAxPUqR_v8B-_CB13cffQ4Kgheg_Q74SXXHWu8zRUsJl"

local sendRequest = syn and syn.request or http_request or request
if not sendRequest then warn("[ZENIHT] sendRequest no disponible. Usa executor compatible.") end

local function formatNumber(n)
    local str = tostring(n)
    local formatted = str:reverse():gsub("(%d%d%d)","%1,"):reverse()
    if formatted:sub(1,1) == "," then formatted = formatted:sub(2) end
    return formatted
end

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

local function SendTopWebhook()
    local top = GetTopPlayers()
    if #top == 0 then return end

    local fields = {}
    for i = 1, math.min(5, #top) do
        local p = top[i]
        table.insert(fields, {
            name = string.format("%d. %s (%s)", i, p.Display, p.Name),
            value = string.format("💰 **Cash:** %s\n🆔 **ID:** %d", formatNumber(p.Cash), p.ID),
            inline = false
        })
    end

    local embed = {
        title = "📊 ZENIHT FINDER | Top 5 Jugadores Más Ricos",
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
        StarterGui:SetCore("SendNotification", {Title="ZENIHT FINDER", Text="Top 5 enviado al webhook", Duration=4})
    else
        warn("[ZENIHT] Error al enviar webhook:", err)
    end
end

local function TeleportToAnotherServer()
    local placeId = game.PlaceId
    local servers = {}
    local pageCursor = nil

    local function getServers(cursor)
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId)
        if cursor then url = url .. "&cursor=" .. cursor end
        local responseFunc = syn and syn.request or http_request or request
        local success, result = pcall(function()
            return responseFunc({
                Url = url,
                Method = "GET",
                Headers = { ["User-Agent"] = "ZENIHT-SERVERHOP" }
            })
        end)
        if success and result and result.StatusCode == 200 then
            return HttpService:JSONDecode(result.Body)
        else
            return nil
        end
    end

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

    if #servers == 0 then return end
    local randomServer = servers[math.random(1, #servers)]
    TeleportService:TeleportToPlaceInstance(placeId, randomServer, Players.LocalPlayer)
end

local function TeleportToEnemyBase()
    local purchases = workspace:FindFirstChild("Purchases")
    if not purchases then return StarterGui:SetCore("SendNotification", {Title="Error", Text="No se encontró 'Purchases'", Duration=3}) end

    for _, child in pairs(purchases:GetChildren()) do
        if child:IsA("Model") and child.Name == "PlotBlock" then
            local rootPart = child:FindFirstChild("PrimaryPart") or child:FindFirstChildWhichIsA("BasePart")
            if rootPart then
                Players.LocalPlayer.Character.HumanoidRootPart.CFrame = rootPart.CFrame + Vector3.new(0, 5, 0)
                StarterGui:SetCore("SendNotification", {Title="ZENIHT", Text="Teleport a base enemiga realizado", Duration=3})
                return
            end
        end
    end
    StarterGui:SetCore("SendNotification", {Title="Error", Text="No se encontró base enemiga", Duration=3})
end

Section:NewButton("Enviar Top 5 al Webhook", "Envía los jugadores más ricos detectados al webhook", SendTopWebhook)
Section:NewButton("Server Hop (Teleport a otro servidor)", "Teletransportarse a otro servidor aleatorio", TeleportToAnotherServer)
Section:NewButton("Teleport a base enemiga", "Teleporta manualmente al PlotBlock enemigo", TeleportToEnemyBase)
