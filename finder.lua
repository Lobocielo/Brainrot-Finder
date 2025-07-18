-- Carga la UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Brainrot Finder", "BloodTheme")
local Tab = Window:NewTab("Jugadores")
local Section = Tab:NewSection("Enviar al Webhook")

-- Configurá tu Webhook
local WEBHOOK = "https://discord.com/api/webhooks/1395188329598681330/2c5dZncIV-4rNouI7XDUVXb4yCFNIYNM3wbv3op2IPyGBcIlnZ9SG5RfBv-RBM9MNor-"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Función: Obtiene más datos del jugador
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

-- Enviar a Discord
local function enviarWebhook(player)
    local data = getPlayerData(player)

    local embed = {
        title = "🎯 Jugador Detectado",
        description = string.format("**Nombre:** %s\n**UserId:** %s\n**Edad de cuenta:** %s días\n**Salud:** %.0f / %.0f\n**Equipo:** %s\n**Posición:** %s",
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

-- Botones para cada jugador
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Players.LocalPlayer then
        Section:NewButton("Enviar: " .. player.Name, "Mandar datos a Discord", function()
            enviarWebhook(player)
        end)
    end
end

-- Nuevo jugador entra
Players.PlayerAdded:Connect(function(player)
    Section:NewButton("Enviar: " .. player.Name, "Mandar datos a Discord", function()
        enviarWebhook(player)
    end)
end)
