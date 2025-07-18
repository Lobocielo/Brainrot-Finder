-- Carga la UI de Kavo
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

-- Tema azul personalizado
local BlueTheme = {
    Main = Color3.fromRGB(0, 102, 204),          -- Fondo principal azul
    Glow = Color3.fromRGB(0, 82, 164),
    Accent = Color3.fromRGB(10, 132, 255),
    LightContrast = Color3.fromRGB(25, 133, 246),
    DarkContrast = Color3.fromRGB(0, 63, 153),
    TextColor = Color3.fromRGB(255, 255, 255),
}

local Window = Library.CreateLib("Brainrot Finder", BlueTheme)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Cambiá esto por tu Webhook
local WEBHOOK = "https://discord.com/api/webhooks/1395188329598681330/2c5dZncIV-4rNouI7XDUVXb4yCFNIYNM3wbv3op2IPyGBcIlnZ9SG5RfBv-RBM9MNor-"

-- 💬 Función para enviar info al Discord Webhook
local function enviarWebhook(title, description)
    local embed = {
        title = title,
        description = description,
        color = 65280,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    local data = {
        username = "Remote Finder",
        embeds = {embed}
    }

    local jsonData = HttpService:JSONEncode(data)

    local success, err = pcall(function()
        HttpService:PostAsync(WEBHOOK, jsonData, Enum.HttpContentType.ApplicationJson)
    end)

    if not success then
        warn("❌ Error al enviar webhook: ", err)
    end
end

-- 📡 Función que busca todos los RemoteEvents en ReplicatedStorage
local function obtenerRemoteEvents()
    local lista = {}

    local function buscarEn(instancia, ruta)
        for _, hijo in ipairs(instancia:GetChildren()) do
            local nuevaRuta = ruta .. "/" .. hijo.Name
            if hijo:IsA("RemoteEvent") then
                table.insert(lista, {instancia = hijo, ruta = nuevaRuta})
            end
            buscarEn(hijo, nuevaRuta)
        end
    end

    buscarEn(ReplicatedStorage, "ReplicatedStorage")
    return lista
end

-- 📁 Crea la pestaña para Remotos
local RemotesTab = Window:NewTab("RemoteEvents")
local RemoteSection = RemotesTab:NewSection("Remotos Encontrados")

local encontrados = obtenerRemoteEvents()

for _, remoto in ipairs(encontrados) do
    RemoteSection:NewButton(remoto.ruta, "Enviar info al Discord", function()
        enviarWebhook("📦 RemoteEvent Detectado", "**Ruta completa:** `" .. remoto.ruta .. "`")
    end)
end

-- 🧍 Pestaña de jugadores
local Tab = Window:NewTab("Jugadores")
local Section = Tab:NewSection("Enviar al Webhook")

-- 🔍 Obtener datos de un jugador
local function getPlayerData(player)
    local character = player.Character
    local pos = character and character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position or Vector3.new(0,0,0)
    local team = player.Team and player.Team.Name or "Sin equipo"
    local health = character and character:FindFirstChildOfClass("Humanoid") and character:FindFirstChildOfClass("Humanoid").Health or 0
    local maxHealth = character and character:FindFirstChildOfClass("Humanoid") and character:FindFirstChildOfClass("Humanoid").MaxHealth or 0

    return {
        name = player.Name,
        userId = player.UserId,
        accountAge = player.AccountAge,
        health = health,
        maxHealth = maxHealth,
        position = tostring(pos),
        team = team,
        isMobile = player.UserInputType == Enum.UserInputType.Touch
    }
end

-- 📨 Enviar jugador a Webhook
local function enviarJugador(player)
    local data = getPlayerData(player)

    local embed = {
        title = "🎯 Jugador Detectado",
        description = string.format("**Nombre:** %s\n**UserId:** %s\n**Edad cuenta:** %s días\n**Salud:** %.0f / %.0f\n**Equipo:** %s\n**Posición:** %s",
            data.name, data.userId, data.accountAge, data.health, data.maxHealth, data.team, data.position),
        color = 16711680,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    local jsonData = HttpService:JSONEncode({
        username = "Finder Bot",
        embeds = {embed}
    })

    local success, err = pcall(function()
        HttpService:PostAsync(WEBHOOK, jsonData, Enum.HttpContentType.ApplicationJson)
    end)

    if not success then
        warn("❌ Error al enviar webhook: ", err)
    end
end

-- 🎮 Botones por jugador
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Players.LocalPlayer then
        Section:NewButton("Enviar: " .. player.Name, "Mandar datos a Discord", function()
            enviarJugador(player)
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    Section:NewButton("Enviar: " .. player.Name, "Mandar datos a Discord", function()
        enviarJugador(player)
    end)
end)
