-- Brainrot Finder completo v4
-- Busca servidor privado automáticamente, manda info webhook y teleporta
-- UI celeste, ESP, Fly, Server Hop público y privado, teleport techo
-- LocalScript para Roblox

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- CONFIGURA TU WEBHOOK
local WEBHOOK_URL = "https://discord.com/api/webhooks/1395923560916193301/Q2gD4P3Xy6HMRLFczAlo7FEgT5FkmstXI_U_wOCQeObuJgI6VmDMFMHKFHc97O4MBgPL"

-- FUNCIONES HTTP COMPATIBLES EXPLOITS

local function httpPost(url, data)
    local jsonData = HttpService:JSONEncode(data)

    if syn and syn.request then
        local response = syn.request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
        return response.StatusCode == 204 or response.StatusCode == 200
    elseif http_request then
        local response = http_request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
        return response.StatusCode == 204 or response.StatusCode == 200
    elseif http and http.request then
        local response = http.request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
        return response.StatusCode == 204 or response.StatusCode == 200
    else
        local success, err = pcall(function()
            HttpService:PostAsync(url, jsonData, Enum.HttpContentType.ApplicationJson)
        end)
        return success
    end
end

local function sendWebhook(content, embed)
    local data = {
        content = content or "",
        username = "Brainrot Finder",
        avatar_url = "https://i.imgur.com/4D7pOzs.png"
    }
    if embed then data.embeds = {embed} end
    local ok = httpPost(WEBHOOK_URL, data)
    if not ok then
        warn("[Brainrot Finder] Error enviando webhook")
    end
end

-- INFO JUGADOR LOCAL

local function getPlayerInfo(player)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local health, maxHealth = 0, 0
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            health = humanoid.Health
            maxHealth = humanoid.MaxHealth
        end
    end
    local pos = hrp and hrp.Position or Vector3.new(0,0,0)
    return {
        Name = player.Name,
        UserId = player.UserId,
        Health = health,
        MaxHealth = maxHealth,
        Position = pos,
        Team = player.Team and player.Team.Name or "N/A",
    }
end

local function sendPlayerData()
    local info = getPlayerInfo(LocalPlayer)
    local embed = {
        title = "📊 Información del Jugador",
        color = 7506394,
        fields = {
            {name = "Nombre", value = info.Name, inline = true},
            {name = "UserId", value = tostring(info.UserId), inline = true},
            {name = "Salud", value = string.format("%.0f / %.0f", info.Health, info.MaxHealth), inline = true},
            {name = "Posición", value = string.format("X: %.2f Y: %.2f Z: %.2f", info.Position.X, info.Position.Y, info.Position.Z), inline = false},
            {name = "Equipo", value = info.Team, inline = true},
            {name = "JobId", value = tostring(game.JobId), inline = true},
            {name = "PlaceId", value = tostring(game.PlaceId), inline = true},
        },
        footer = {text = os.date("%c")},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    sendWebhook("", embed)
end

-- BUSCAR SERVIDOR PRIVADO AUTOMATICAMENTE

local function findPrivateServer()
    local placeId = game.PlaceId
    local url = ("https://games.roblox.com/v1/games/%d/servers/Private?limit=100"):format(placeId)
    local success, res = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if not success then
        warn("[Brainrot Finder] Error obteniendo servidores privados:", res)
        return nil
    end
    local data = HttpService:JSONDecode(res)
    if not data or not data.data then return nil end

    for _, server in pairs(data.data) do
        if server.playing < server.maxPlayers then
            return server
        end
    end
    return nil
end

local function sendAndTeleportPrivateServer()
    local server = findPrivateServer()
    if not server then
        warn("[Brainrot Finder] No se encontró servidor privado disponible.")
        return
    end

    local embed = {
        title = "🔐 Servidor Privado Encontrado",
        color = 16711680,
        fields = {
            {name = "JobId", value = server.id, inline = true},
            {name = "Jugadores", value = tostring(server.playing), inline = true},
            {name = "Max Jugadores", value = tostring(server.maxPlayers), inline = true},
            {name = "Activo", value = tostring(server.active), inline = true},
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    sendWebhook("", embed)
    wait(1)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
end

-- ESP

local ESPEnabled = false
local ESPFolder = Instance.new("Folder", game.CoreGui)
ESPFolder.Name = "BrainrotESP"
local ESPBoxes = {}

local function createBox(part)
    if not part then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = part
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Transparency = 0.5
    box.Color3 = Color3.fromRGB(85, 170, 255)
    box.Size = part.Size
    box.Parent = ESPFolder
    return box
end

local function enableESP()
    if ESPEnabled then return end
    ESPEnabled = true
    RunService.RenderStepped:Connect(function()
        if not ESPEnabled then return end
        for _, box in pairs(ESPBoxes) do box:Destroy() end
        ESPBoxes = {}
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local box = createBox(player.Character.HumanoidRootPart)
                if box then table.insert(ESPBoxes, box) end
            end
        end
        for _, model in pairs(Workspace:GetChildren()) do
            if model:IsA("Model") and model.Name:lower():find("brainrot") then
                local part = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                if part then
                    local box = createBox(part)
                    if box then table.insert(ESPBoxes, box) end
                end
            end
        end
    end)
end

local function disableESP()
    ESPEnabled = false
    for _, box in pairs(ESPBoxes) do box:Destroy() end
    ESPBoxes = {}
end

-- FLY

local FlyEnabled = false
local speed = 50
local bodyGyro, bodyVelocity
local flyConnection

local function enableFly()
    if FlyEnabled then return end
    FlyEnabled = true

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.PlatformStand = true end

    bodyGyro = Instance.new("BodyGyro", hrp)
    bodyGyro.P = 9e4
    bodyGyro.maxTorque = Vector3.new(9e9,9e9,9e9)
    bodyGyro.cframe = hrp.CFrame

    bodyVelocity = Instance.new("BodyVelocity", hrp)
    bodyVelocity.maxForce = Vector3.new(9e9,9e9,9e9)
    bodyVelocity.velocity = Vector3.new(0,0,0)

    flyConnection = RunService.Heartbeat:Connect(function()
        if not FlyEnabled then return end
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0,1,0) end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit * speed
        end

        bodyVelocity.velocity = moveDir
        bodyGyro.cframe = cam.CFrame
    end)
end

local function disableFly()
    if not FlyEnabled then return end
    FlyEnabled = false
    if bodyGyro then bodyGyro:Destroy() end
    if bodyVelocity then bodyVelocity:Destroy() end
    if flyConnection then flyConnection:Disconnect() end

    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.PlatformStand = false end
end

-- SERVER HOP PUBLICO

local function serverHopPublic()
    local placeId = game.PlaceId
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
    local success, res = pcall(function() return HttpService:GetAsync(url) end)
    if not success then warn("[Brainrot Finder] Error obteniendo servidores públicos") return end

    local data = HttpService:JSONDecode(res)
    if not data or not data.data then return end

    for _, server in pairs(data.data) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
            return
        end
    end
    warn("[Brainrot Finder] No se encontró servidor público disponible")
end

-- TELEPORT AL TECHO

local function teleportRoof()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local roofHeight = 200
    local pos = hrp.Position
    hrp.CFrame = CFrame.new(pos.X, roofHeight, pos.Z)
end

-- UI KAVO

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Brainrot Finder", "BloodTheme")

local TabInfo = Window:NewTab("Información")
local TabSecurity = Window:NewTab("Seguridad")
local TabServer = Window:NewTab("Servidor")

local SectionInfo = TabInfo:NewSection("Jugador & Webhook")
local SectionSecurity = TabSecurity:NewSection("ESP y Fly")
local SectionServer = TabServer:NewSection("Server Hop & Techo")

SectionInfo:NewButton("Enviar info al Webhook", sendPlayerData)
SectionSecurity:NewToggle("Activar ESP", function(value)
    if value then enableESP() else disableESP() end
end)
SectionSecurity:NewToggle("Activar Fly", function(value)
    if value then enableFly() else disableFly() end
end)
SectionServer:NewButton("Cambiar a Servidor Público", serverHopPublic)
SectionServer:NewButton("Cambiar a Servidor Privado (buscar + enviar info + teleport)", sendAndTeleportPrivateServer)
SectionServer:NewButton("Teleport al Techo", teleportRoof)

print("[Brainrot Finder] Script cargado, UI lista.")
