--// 📊 ZENIHT FINDER SCRIPT v1.0
--// Requiere: Kavo UI, Webhook activo, permisos para GetPlayers/GetChildren

-- Variables de configuración local
local WebhookURL = "https://discord.com/api/webhooks/1395188329598681330/2c5dZncIV-4rNouI7XDUVXb4yCFNIYNM3wbv3op2IPyGBcIlnZ9SG5RfBv-RBM9MNor-"
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Cargar la librería Kavo UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("ZENIHT FINDER", "Serpent")
local Main = Window:NewTab("Jugadores")
local RemoteTab = Window:NewTab("RemoteEvents")

local InfoSection = Main:NewSection("Top Jugadores")
local TpSection = Main:NewSection("TP Server Hop")
local RemoteSection = RemoteTab:NewSection("Detectados")

-- Función para obtener los top 5 jugadores por cash
local function GetTopPlayers()
    local cashData = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local stats = player:FindFirstChild("leaderstats")
        if stats and stats:FindFirstChild("Cash") then
            table.insert(cashData, {
                Name = player.Name,
                DisplayName = player.DisplayName,
                Cash = stats.Cash.Value,
                UserId = player.UserId
            })
        end
    end
    table.sort(cashData, function(a, b) return a.Cash > b.Cash end)
    return cashData
end

-- Enviar al Webhook los top 5
local function SendTopToWebhook()
    local top = GetTopPlayers()
    local content = "📊 ZENIHT FINDER | Jugadores más ricos detectados\n💰 Top 5 Jugadores con más Cash"
    for i = 1, math.min(5, #top) do
        local p = top[i]
        content = content .. string.format("\n%d. %s (%s) | 💰 %s | 🆔 %d", i, p.DisplayName, p.Name, tostring(p.Cash), p.UserId)
    end
    content = content .. string.format("\nJobId: %s | PlaceId: %d", game.JobId, game.PlaceId)

    HttpService:PostAsync(WebhookURL, HttpService:JSONEncode({content = content}), Enum.HttpContentType.ApplicationJson)
end

InfoSection:NewButton("📤 Enviar TOP al Webhook", "Top 5 más ricos", SendTopToWebhook)

-- Botón azul para server hop
TpSection:NewButton("🔁 Server Hop", "Teleporta a otro servidor", function()
    local servers = HttpService:JSONDecode(game:HttpGet(
        string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)))
    for _, server in ipairs(servers.data) do
        if server.id ~= game.JobId and server.playing < server.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
            break
        end
    end
end)

-- Buscar RemoteEvents y enviarlos al webhook
local function FindAndSendRemotes()
    local found = {}
    local function scan(folder, path)
        for _, obj in ipairs(folder:GetChildren()) do
            local currentPath = path .. "/" .. obj.Name
            if obj:IsA("RemoteEvent") then
                table.insert(found, "[ReplicatedStorage] " .. currentPath)
                RemoteSection:NewLabel(currentPath)
            end
            if #obj:GetChildren() > 0 then
                scan(obj, currentPath)
            end
        end
    end
    scan(ReplicatedStorage, "ReplicatedStorage")

    -- Enviar a webhook
    local payload = {content = "📦 RemoteEvents encontrados:\n```" .. table.concat(found, "\n") .. "```"}
    HttpService:PostAsync(WebhookURL, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
end

RemoteSection:NewButton("📦 Detectar RemoteEvents", "Escanear ReplicatedStorage", FindAndSendRemotes)

-- Detectar jugadores al entrar y mostrar info
Players.PlayerAdded:Connect(function(p)
    print("🔍 Jugador detectado:", p.Name)
end)

-- Ejecutar auto al iniciar
task.wait(2)
SendTopToWebhook()
FindAndSendRemotes()
