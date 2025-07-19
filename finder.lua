local WEBHOOK = "https://discord.com/api/webhooks/1395923548044005406/XtdiHIMtc5_BLFHBkKnTRt1GiAxPUqR_v8B-_CB13cffQ4Kgheg_Q74SXXHWu8zRUsJl" -- PONÉ TU NUEVO WEBHOOK

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local sendRequest = syn and syn.request or http_request or request

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

local function SendTopWebhook()
    local top = GetTopPlayers()
    if #top == 0 then return end

    local lines = {"📊 ZENIHT FINDER | Jugadores más ricos detectados", "💰 Top 5 Jugadores con más Cash"}
    for i=1, math.min(5,#top) do
        local p = top[i]
        table.insert(lines, string.format("%d. %s (%s) | 💰 %d | 🆔 %d", i, p.Display, p.Name, p.Cash, p.ID))
    end
    table.insert(lines, string.format("JobId: %s | PlaceId: %d", game.JobId, game.PlaceId))

    local success, err = pcall(function()
        sendRequest({
            Url = WEBHOOK,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["User-Agent"] = "ZENIHT-BOT-" .. tostring(math.random(1000,9999))
            },
            Body = HttpService:JSONEncode({
                content = table.concat(lines, "\n")
            })
        })
    end)

    if not success then
        warn("🚫 Webhook bloqueado o falló: ", err)
    end
end

-- Espera hasta que todos los jugadores tengan Cash
task.spawn(function()
    repeat wait(1) until #Players:GetPlayers() > 0
    wait(5)  -- esperar un poco para que los datos carguen
    SendTopWebhook()
end)
