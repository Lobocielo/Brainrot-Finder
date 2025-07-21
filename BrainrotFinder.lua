--// Cargar UI (Kavo - Celeste)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Brainrot Finder", "Ocean")

--// Servicios
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

--// Webhook
local WEBHOOK = "https://discord.com/api/webhooks/1395923560916193301/Q2gD4P3Xy6HMRLFczAlo7FEgT5FkmstXI_U_wOCQeObuJgI6VmDMFMHKFHc97O4MBgPL"

local function sendWebhook(title, content)
    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = content,
            ["color"] = 3447003
        }}
    }
    syn.request({
        Url = WEBHOOK,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(data)
    })
end

--// Enviar Info del Jugador
local function sendPlayerInfo()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChild("Humanoid")
    local pos = hrp and hrp.Position or Vector3.new()

    local info = string.format("👤 Nombre: %s\n🩸 Salud: %d\n💵 Dinero: %s\n🏳️ Equipo: %s\n🆔 ID: %s\n📍 Posición: %s\n🌐 JobId: %s\n🏠 PlaceId: %d",
        LocalPlayer.Name,
        humanoid and math.floor(humanoid.Health) or 0,
        LocalPlayer:FindFirstChild("Cash") and LocalPlayer.Cash.Value or "N/A",
        LocalPlayer.Team and LocalPlayer.Team.Name or "N/A",
        LocalPlayer.UserId,
        tostring(pos),
        game.JobId,
        game.PlaceId
    )
    sendWebhook("📡 Datos del Jugador", info)
end

--// UI
local tabInfo = Window:NewTab("Servidor")
local tabSeguridad = Window:NewTab("Seguridad")
local tabWebhook = Window:NewTab("Webhook")
local tabExtra = Window:NewTab("Herramientas")

local secInfo = tabInfo:NewSection("Estado del Servidor")
local secESP = tabSeguridad:NewSection("Visuales ESP")
local secFly = tabSeguridad:NewSection("Vuelo")
local secWeb = tabWebhook:NewSection("Enviar Datos")
local secExtra = tabExtra:NewSection("Utilidades")

--// ESP ON/OFF
local espActiva = false
local function toggleESP()
    espActiva = not espActiva
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            if espActiva then
                if not head:FindFirstChild("ESPBillboard") then
                    local b = Instance.new("BillboardGui", head)
                    b.Name = "ESPBillboard"
                    b.Size = UDim2.new(0,100,0,40)
                    b.AlwaysOnTop = true
                    local t = Instance.new("TextLabel", b)
                    t.Text = p.Name
                    t.Size = UDim2.new(1,0,1,0)
                    t.BackgroundTransparency = 1
                    t.TextColor3 = Color3.fromRGB(0,200,255)
                end
            else
                if head:FindFirstChild("ESPBillboard") then
                    head.ESPBillboard:Destroy()
                end
            end
        end
    end
end
secESP:NewButton("Toggle ESP", "Activa/desactiva Wallhack celeste", toggleESP)

--// FLY con Protección
local flying = false
local function flyToggle()
    flying = not flying
    local hrp = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    local bv = Instance.new("BodyVelocity", hrp)
    local bg = Instance.new("BodyGyro", hrp)
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.P = 1e5
    while flying do
        task.wait()
        bv.Velocity = Workspace.CurrentCamera.CFrame.LookVector * 80
        bg.CFrame = Workspace.CurrentCamera.CFrame
    end
    bv:Destroy()
    bg:Destroy()
end
secFly:NewButton("Toggle Fly", "Vuela con bypass anticheat", flyToggle)

--// Enviar datos al webhook
secWeb:NewButton("Enviar Datos del Jugador", "Manda la info actual al Webhook", sendPlayerInfo)

--// Server Hop Público
secExtra:NewButton("Cambiar Servidor Público", "Busca otro servidor disponible", function()
    local servers = {}
    local result = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100")
    for _,v in pairs(HttpService:JSONDecode(result).data) do
        if v.playing < v.maxPlayers then table.insert(servers, v.id) end
    end
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
    else
        sendWebhook("❌ Server Hop Fallido", "No se encontraron servidores disponibles.")
    end
end)

--// Server Hop Privado (detecta automáticamente)
secExtra:NewButton("Entrar a Servidor Privado", "Busca y entra a servidor privado activo", function()
    local response = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/private-servers")
    local vipList = HttpService:JSONDecode(response)
    if vipList and vipList.data and #vipList.data > 0 then
        for _, server in pairs(vipList.data) do
            if server and server.activeServerId then
                local msg = string.format("🔒 Servidor Privado Detectado\n👤 Nombre: %s\n🆔 Server ID: %s\n📍 JobId: %s",
                    server.name or "N/A", server.id, server.activeServerId)
                sendWebhook("🔐 VIP Server Detectado", msg)
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.activeServerId, LocalPlayer)
                return
            end
        end
        sendWebhook("❌ Ningún VIP Activo", "No hay servidores privados con JobId activo.")
    else
        sendWebhook("⚠️ Error", "No se pudo obtener la lista de VIPs.")
    end
end)

--// Teleport al Techo
secExtra:NewButton("Teleport al Techo", "Sube arriba del mapa", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(0, 500, 0)
    end
end)

--// Buscar Brainrots ocultos y mandar al Webhook
local function buscarBrainrotsSecretos()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("brainrot") and obj:FindFirstChild("HumanoidRootPart") then
            local pos = obj.HumanoidRootPart.Position
            local msg = string.format("🧠 Brainrot Detectado!\n📍 Posición: %s\n🔎 Nombre: %s", tostring(pos), obj.Name)
            sendWebhook("🧠 Brainrot Secreto", msg)
        end
    end
end
secExtra:NewButton("Buscar Brainrots", "Escanea y reporta brainrots ocultos", buscarBrainrotsSecretos)
