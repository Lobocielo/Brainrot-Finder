-- Librerías
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

-- CONFIGURA TU WEBHOOK
local WEBHOOK = "https://discord.com/api/webhooks/1395188329598681330/2c5dZncIV-4rNouI7XDUVXb4yCFNIYNM3wbv3op2IPyGBcIlnZ9SG5RfBv-RBM9MNor-"

-- UI
local Window = Library.CreateLib("Finder de RemoteEvents", "BloodTheme")
local tabEventos = Window:NewTab("RemoteEvents")
local secEventos = tabEventos:NewSection("Listar y Enviar")

local tabExtras = Window:NewTab("Extras")
local secExtras = tabExtras:NewSection("Utilidades")

-- 🧠 Buscar todos los RemoteEvents desde una instancia dada
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
    local eventos = {}
    local success, err = pcall(function()
        eventos = obtenerRemoteEventsDesde(game.ReplicatedStorage, "ReplicatedStorage")
    end)

    if not success then
        warn("❌ Error buscando RemoteEvents:", err)
        return
    end

    if #eventos == 0 then
        warn("⚠️ No se encontraron RemoteEvents.")
        return
    end

    local contenido = table.concat(eventos, "\n")
    local data = {
        username = "RemoteEvent Finder",
        content = "📡 Lista de RemoteEvents:\n```lua\n" .. contenido .. "\n```"
    }

    local jsonData = HttpService:JSONEncode(data)

    local enviado, errorPost = pcall(function()
        HttpService:PostAsync(WEBHOOK, jsonData, Enum.HttpContentType.ApplicationJson)
    end)

    if enviado then
        print("✅ RemoteEvents enviados al webhook.")
    else
        warn("❌ Error enviando al webhook:", errorPost)
    end
end

-- 🔘 Botón para enviar eventos
secEventos:NewButton("📤 Enviar RemoteEvents", "Busca todos los RemoteEvents y los manda al Webhook", function()
    enviarRemoteEvents()
end)

-- 🔄 Botón para server hop (azul)
secExtras:NewButton("🔄 TP a otro servidor", "Server hop seguro", function()
    local gameId = game.PlaceId

    local success, response = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. gameId .. "/servers/Public?sortOrder=Asc&limit=100")
    end)

    if not success then
        warn("❌ Error obteniendo servidores:", response)
        return
    end

    local data = HttpService:JSONDecode(response)
    local servidores = {}

    for _, server in ipairs(data.data or {}) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            table.insert(servidores, server.id)
        end
    end

    if #servidores > 0 then
        TeleportService:TeleportToPlaceInstance(gameId, servidores[1], Players.LocalPlayer)
    else
        warn("⚠️ No hay otros servidores disponibles.")
    end
end)
