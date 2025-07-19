-- 📌 ZENIHT FINDER SCRIPT v1.1
local WEBHOOK = "https://discord.com/api/webhooks/1395188329598681330/2c5dZncIV-4rNouI7XDUVXb4yCFNIYNM3wbv3op2IPyGBcIlnZ9SG5RfBv-RBM9MNor-"  -- reemplazá con tu webhook

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Compatibilidad para envío HTTP
local sendRequest = syn and syn.request or http_request or request or HttpService.PostAsync

-- Cargar UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("ZENIHT FINDER", Color3.fromRGB(0,162,255))  -- tema azul personalizado

-- Separación en pestañas
local tabPlayers = Window:NewTab("Jugadores")
local secPlayers = tabPlayers:NewSection("Top Jugadores")
local tabRemotes = Window:NewTab("RemoteEvents")
local secRemotes = tabRemotes:NewSection("Remotes detectados")
local tabExtras = Window:NewTab("Extras")
local secExtras = tabExtras:NewSection("Utilidades")

-- 🧮 Obtener y ordenar los top 5 por Cash
local function GetTopPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local stats = p:FindFirstChild("leaderstats")
        local cash = stats and stats:FindFirstChild("Cash")
        if cash then
            table.insert(list, {Name = p.Name, Display = p.DisplayName, Cash = cash.Value, ID = p.UserId})
        end
    end
    table.sort(list, function(a,b) return a.Cash > b.Cash end)
    return list
end

-- 📤 Enviar top 5 al webhook
local function SendTopWebhook()
    local top = GetTopPlayers()
    if #top == 0 then return end

    local lines = {"📊 ZENIHT FINDER | Jugadores más ricos detectados", "💰 Top 5 Jugadores con más Cash"}
    for i=1, math.min(5,#top) do
        local p = top[i]
        table.insert(lines, string.format("%d. %s (%s) | 💰 %d | 🆔 %d", i, p.Display, p.Name, p.Cash, p.ID))
    end
    table.insert(lines, string.format("JobId: %s | PlaceId: %d", game.JobId, game.PlaceId))
    local msg = table.concat(lines, "\n")

    local ok, err = pcall(function()
        sendRequest({
            Url = WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({content = msg})
        })
    end)
    if not ok then warn("Webhook error", err) end
end

-- ✅ Botón de UI para enviar top players
secPlayers:NewButton("📤 Enviar Top 5", "Envía top 5 Jugadores", SendTopWebhook)

-- 🔘 Server Hop (cambio de servidor)
secExtras:NewButton("🔁 Server Hop", "Cambia a otro servidor", function()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            string.format("https://games.roblox.com/v1/games/%d/servers/Public?limit=50", game.PlaceId)))
    end)
    if not ok or not res then warn("No se obtuvieron servidores") return end

    for _, s in ipairs(res.data or {}) do
        if s.id ~= game.JobId and s.playing < s.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, Players.LocalPlayer)
            return
        end
    end
    warn("No hay servers libres")
end)

-- 📡 Dump y botones por cada RemoteEvent
local function CreateRemoteButtons()
    secRemotes:Clear()  -- limpia botones anteriores

    local function recurse(folder, prefix)
        for _, child in ipairs(folder:GetChildren()) do
            local path = prefix .. "." .. child.Name
            if child:IsA("RemoteEvent") then
                secRemotes:NewButton(path, "Enviar info del RemoteEvent", function()
                    local ok,_ = pcall(function()
                        sendRequest({
                            Url = WEBHOOK,
                            Method = "POST",
                            Headers = {["Content-Type"] = "application/json"},
                            Body = HttpService:JSONEncode({
                                content = "📦 RemoteEvent: " .. path
                            })
                        })
                    end)
                    if not ok then warn("No se envió RemoteEvent") end
                end)
            end
            recurse(child, path)
        end
    end

    recurse(ReplicatedStorage, "ReplicatedStorage")
end

-- Botón para refrescar listado de Remotes
secRemotes:NewButton("🔄 Refrescar Remotes", "Detectar RemoteEvents en ReplicatedStorage", CreateRemoteButtons)
CreateRemoteButtons()  -- carga inicial

-- 📦 Auto-envío al iniciar
task.defer(SendTopWebhook)
