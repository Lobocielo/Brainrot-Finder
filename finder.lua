-- Carga la UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Brainrot Finder", "BloodTheme")
local Tab = Window:NewTab("Jugadores")
local Section = Tab:NewSection("Enviar al Webhook")
local LoopSection = Tab:NewSection("AutoScan Cercanos")

-- Webhook de Discord (reemplaza con el tuyo si querés)
local WEBHOOK = "https://discord.com/api/webhooks/1395188329598681330/2c5dZncIV-4rNouI7XDUVXb4yCFNIYNM3wbv3op2IPyGBcIlnZ9SG5RfBv-RBM9MNor-"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local activeLoop = false

-- Función para obtener datos del jugador
local function getPlayerData(player)
    local character = player.Character
    local pos = character and character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position or Vector3.zero
    local team = player.Team and player.Team.Name or "Sin equipo"
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local health = humanoid and humanoid.Health or 0
    local maxHealth = humanoid and humanoid.MaxHealth or 0

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

-- Enviar a Webhook
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

-- Agrega botón para un jugador específico
local function addPlayerButton(player)
    if player ~= LocalPlayer then
        Section:NewButton("Enviar: " .. player.Name, "Mandar datos a Discord", function()
            enviarWebhook(player)
        end)
    end
end

-- Loop para enviar automáticamente cercanos
task.spawn(function()
    while true do
        if activeLoop then
            pcall(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and LocalPlayer.Character then
                        local hrp1 = player.Character:FindFirstChild("HumanoidRootPart")
                        local hrp2 = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp1 and hrp2 then
                            local dist = (hrp1.Position - hrp2.Position).Magnitude
                            if dist <= 80 then -- Distancia de escaneo
                                enviarWebhook(player)
                                task.wait(0.5) -- Evita spam excesivo
                            end
                        end
                    end
                end
            end)
        end
        task.wait(3)
    end
end)

-- Toggle para activar o desactivar loop
LoopSection:NewToggle("AutoEnviar Cercanos", "Escanea y manda cada 3s a jugadores a 80 studs", function(state)
    activeLoop = state
end)

-- Botones para jugadores actuales
for _, player in ipairs(Players:GetPlayers()) do
    addPlayerButton(player)
end

-- Agrega botón si alguien entra nuevo
Players.PlayerAdded:Connect(function(player)
    addPlayerButton(player)
end)
