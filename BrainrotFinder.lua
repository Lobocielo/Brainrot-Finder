-- Carga la UI de Kavo con tema azul
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("💠 Brainrot Finder PRO", "Ocean")

-- Servicios
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Webhook de Discord
local WEBHOOK = "https://discord.com/api/webhooks/1395923560916193301/Q2gD4P3Xy6HMRLFczAlo7FEgT5FkmstXI_U_wOCQeObuJgI6VmDMFMHKFHc97O4MBgPL" -- Reemplazá esto con tu webhook

-- Anti-TP Forzado
local originalPosition = nil
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if originalPosition then
        char:WaitForChild("HumanoidRootPart").CFrame = originalPosition
    end
end)

-- ESP de jugadores con protección mejorada
local ESPEnabled = false
local function ClearESP()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("ESP") then
            obj:FindFirstChild("ESP"):Destroy()
        end
    end
end

function ToggleESP()
    ESPEnabled = not ESPEnabled
    ClearESP()
    if ESPEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local espBox = Instance.new("BoxHandleAdornment")
                espBox.Name = "ESP"
                espBox.Adornee = player.Character.HumanoidRootPart
                espBox.AlwaysOnTop = true
                espBox.ZIndex = 5
                espBox.Size = Vector3.new(4, 6, 4)
                espBox.Transparency = 0.4
                espBox.Color3 = Color3.fromRGB(0, 170, 255)
                espBox.Parent = player.Character
            end
        end
    end
end

-- Fly con protección mejorada
local flying = false
local keysPressed = {}
local flyConnection = nil

function ToggleFly()
    flying = not flying
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if flying then
        char:WaitForChild("Humanoid").PlatformStand = true

        local bodyGyro = Instance.new("BodyGyro")
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.P = 9e4
        bodyGyro.CFrame = Workspace.CurrentCamera.CFrame
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.Parent = hrp
        bodyVelocity.Parent = hrp

        flyConnection = RunService:BindToRenderStep("Fly", Enum.RenderPriority.Character.Value, function()
            if flying then
                local direction = Vector3.zero
                if keysPressed[Enum.KeyCode.W] then
                    direction += Workspace.CurrentCamera.CFrame.LookVector
                end
                if keysPressed[Enum.KeyCode.S] then
                    direction -= Workspace.CurrentCamera.CFrame.LookVector
                end
                if keysPressed[Enum.KeyCode.A] then
                    direction -= Workspace.CurrentCamera.CFrame.RightVector
                end
                if keysPressed[Enum.KeyCode.D] then
                    direction += Workspace.CurrentCamera.CFrame.RightVector
                end
                bodyGyro.CFrame = Workspace.CurrentCamera.CFrame
                bodyVelocity.Velocity = direction.Unit * 100
            end
        end)

        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed then
                keysPressed[input.KeyCode] = true
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            keysPressed[input.KeyCode] = nil
        end)

    else
        if flyConnection then RunService:UnbindFromRenderStep("Fly") end
        if char:FindFirstChild("Humanoid") then
            char.Humanoid.PlatformStand = false
        end
        if hrp:FindFirstChild("BodyGyro") then hrp.BodyGyro:Destroy() end
        if hrp:FindFirstChild("BodyVelocity") then hrp.BodyVelocity:Destroy() end
    end
end

-- Teleport a jugador
function TeleportToPlayer(playerName)
    local target = Players:FindFirstChild(playerName)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        originalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
        LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
    end
end

-- Server Hop con análisis previo
function ServerHop()
    local servers = {}
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100", game.PlaceId)
    local response = HttpService:JSONDecode(game:HttpGet(url))
    local bestServer = nil
    local bestAvgMoney = 0

    for _, server in pairs(response.data) do
        if server.playing < server.maxPlayers then
            local moneyTotal = 0
            for _, p in pairs(server.playerTokens or {}) do
                moneyTotal += p.money or 0
            end
            local avgMoney = moneyTotal / #server.playerTokens
            if avgMoney > bestAvgMoney then
                bestAvgMoney = avgMoney
                bestServer = server
            end
        end
    end

    if bestServer then
        print("Teleportando al servidor con mejor promedio de dinero:", bestAvgMoney)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, bestServer.id, LocalPlayer)
    else
        warn("No se encontraron servidores óptimos para cambiar.")
    end
end

-- UI
local MainTab = Window:NewTab("🚀 Funciones Avanzadas")
local Sec = MainTab:NewSection("🔧 Opciones Generales")

Sec:NewButton("👁️ Activar ESP Jugadores", "Ver jugadores con protección", function()
    ToggleESP()
end)

Sec:NewButton("🛡️ Activar Anti-TP Forzado", "Regresa a tu posición si te teletransportan", function()
    originalPosition = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.CFrame
end)

Sec:NewKeybind("✈️ Activar Fly (F)", "Vuela con protección", Enum.KeyCode.F, function()
    ToggleFly()
end)

Sec:NewButton("🔁 Server Hop Inteligente", "Cambia a servidor con mejor promedio de dinero", function()
    ServerHop()
end)

local playerNames = {}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        table.insert(playerNames, p.Name)
    end
end

Sec:NewDropdown("🚀 Teleport a Jugador", "Selecciona jugador para ir", playerNames, function(selected)
