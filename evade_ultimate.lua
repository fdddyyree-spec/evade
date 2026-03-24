-- ============================================
-- 🎮 EVADE ULTIMATE SCRIPT
-- Полнофункциональный скрипт для Roblox Evade
-- С AFK Farm Mode и всеми функциями
-- ============================================

print("🎮 Загрузка Evade Ultimate Script...")

-- Защита от повторного запуска
pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("EvadeUltimate") then
        game:GetService("CoreGui"):FindFirstChild("EvadeUltimate"):Destroy()
    end
end)

-- ============================================
-- СЕРВИСЫ И ИНИЦИАЛИЗАЦИЯ
-- ============================================

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Получаем RemoteEvent'ы из игры
local Events = ReplicatedStorage:FindFirstChild("Events")

-- Character Events
local SpeedBoostEvent = Events and Events.Character and Events.Character:FindFirstChild("SpeedBoost")
local TeleportEvent = Events and Events.Character and Events.Character:FindFirstChild("Teleport")
local RigImpulseEvent = Events and Events.Character and Events.Character:FindFirstChild("RigImpulse")

-- Player Events
local ChangeSettingEvent = Events and Events.Player and Events.Player:FindFirstChild("ChangeSetting")

-- Map Events
local UseInteractableEvent = Events and Events.Map and Events.Map:FindFirstChild("UseInteractable")
local BreakDoorEvent = Events and Events.Map and Events.Map:FindFirstChild("BreakDoor")

-- ============================================
-- НАСТРОЙКИ
-- ============================================

local Settings = {
    Speed = false,
    SpeedValue = 25,
    Jump = false,
    JumpValue = 60,
    Bhop = false,
    ESP = false,
    Fullbright = false,
    NoFog = false,
    AutoRevive = false,
    AutoReviveOthers = false,
    AutoSelfRevive = false,
    AutoCollectCoins = false,
    Noclip = false,
    BotIgnore = false,
    GhostMode = false,
    PrankStick = false,
    NoBots = false,
}

-- AFK Farm настройки
local AFKSettings = {
    Enabled = false,
    SafeZone = Vector3.new(0, 100, 0),
    ReviveRadius = 100,
    CoinRadius = 150,
    BotDangerDistance = 25,
    AutoHealThreshold = 50,
}

-- ============================================
-- ПЕРЕМЕННЫЕ
-- ============================================

local noclipConnection
local revivedPlayers = {}
local lastSelfRevive = 0
local originalTeam = nil
local prankCooldown = {}
local lastPrankClick = 0

-- ============================================
-- БАЗОВЫЕ ФУНКЦИИ
-- ============================================

local function GetChar()
    return LP.Character and LP.Character.Parent and LP.Character or nil
end

local function GetHum()
    local char = GetChar()
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

local function GetRoot()
    local char = GetChar()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")) or nil
end

local function TeleportTo(position)
    local root = GetRoot()
    if root then
        if TeleportEvent then
            TeleportEvent:FireServer(CFrame.new(position))
        else
            root.CFrame = CFrame.new(position)
        end
    end
end

local function GetBots()
    local bots = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if not Players:GetPlayerFromCharacter(v) then
                table.insert(bots, v)
            end
        end
    end
    return bots
end

local function GetNearestBot()
    local root = GetRoot()
    if not root then return nil end
    
    local nearestBot = nil
    local shortestDistance = math.huge
    
    for _, bot in pairs(GetBots()) do
        local botRoot = bot:FindFirstChild("HumanoidRootPart")
        if botRoot then
            local distance = (root.Position - botRoot.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestBot = bot
            end
        end
    end
    
    return nearestBot
end

local function GetCoins()
    local coins = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name:lower():find("coin") or v.Name:lower():find("collectible") or v.Name:lower():find("pickup")) then
            table.insert(coins, v)
        end
    end
    return coins
end

local function CollectCoins()
    local root = GetRoot()
    if not root then return end
    
    for _, coin in pairs(GetCoins()) do
        if (coin.Position - root.Position).Magnitude < 100 then
            local collectEvent = Events.Collectibles:FindFirstChild("Impulse")
            if collectEvent then
                collectEvent:FireServer(coin)
            end
            
            firetouchinterest(root, coin, 0)
            wait()
            firetouchinterest(root, coin, 1)
        end
    end
end

local function CreateESP(object, color)
    if not object:FindFirstChild("ESP_Highlight") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = color or Color3.fromRGB(255, 255, 255)
        highlight.OutlineColor = Color3.fromRGB(200, 200, 200)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent = object
    end
end

local function IsAlive()
    local char = GetChar()
    if not char then return false end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function GetDistanceTo(object)
    local root = GetRoot()
    if not root or not object then return math.huge end
    
    local objectPos = object:IsA("Model") and object:FindFirstChild("HumanoidRootPart") or object
    if not objectPos then return math.huge end
    
    return (root.Position - objectPos.Position).Magnitude
end

-- ============================================
-- ФУНКЦИИ ВОСКРЕШЕНИЯ
-- ============================================

local function SelfRevive()
    local char = GetChar()
    local hum = GetHum()
    
    if char and hum then
        if hum.Health == 0 or hum:GetState() == Enum.HumanoidStateType.Dead then
            local currentTime = tick()
            
            if currentTime - lastSelfRevive > 3 then
                lastSelfRevive = currentTime
                
                local verifyEvent = Events.Character:FindFirstChild("VerifyRange")
                if verifyEvent then
                    verifyEvent:InvokeServer("SelfRevive")
                end
                
                for _, obj in pairs(char:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and (obj.Name:lower():find("revive") or obj.Name:lower():find("heal")) then
                        fireproximityprompt(obj)
                        break
                    end
                end
            end
        end
    end
end

local function ReviveOthers()
    local myChar = GetChar()
    local myRoot = GetRoot()
    
    if not myChar or not myRoot then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local theirChar = player.Character
            local theirHum = theirChar:FindFirstChildOfClass("Humanoid")
            local theirRoot = theirChar:FindFirstChild("HumanoidRootPart")
            
            if theirHum and theirRoot and (theirHum.Health == 0 or theirHum:GetState() == Enum.HumanoidStateType.Dead) then
                if not revivedPlayers[player.UserId] or tick() - revivedPlayers[player.UserId] > 30 then
                    local originalPos = myRoot.CFrame
                    
                    TeleportTo(theirRoot.Position + Vector3.new(0, 0, 3))
                    wait(0.5)
                    
                    local verifyEvent = Events.Character:FindFirstChild("VerifyRange")
                    if verifyEvent then
                        verifyEvent:InvokeServer("Revive", player)
                    end
                    
                    for _, obj in pairs(theirChar:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") and (obj.Name:lower():find("revive") or obj.Name:lower():find("heal")) then
                            fireproximityprompt(obj)
                            revivedPlayers[player.UserId] = tick()
                            break
                        end
                    end
                    
                    wait(1)
                    TeleportTo(originalPos.Position)
                end
            else
                revivedPlayers[player.UserId] = nil
            end
        end
    end
end

-- ============================================
-- ФУНКЦИИ ДЛЯ КАРТЫ
-- ============================================

local function BreakAllDoors()
    local count = 0
    
    for _, door in pairs(workspace:GetDescendants()) do
        if door:IsA("Model") and door.Name:lower():find("door") then
            if BreakDoorEvent then
                BreakDoorEvent:FireServer(door)
            else
                door:Destroy()
            end
            count = count + 1
        end
    end
    
    return count
end

local function UseAllInteractables()
    local root = GetRoot()
    if not root then return 0 end
    
    local count = 0
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") or (obj:IsA("Part") and obj:FindFirstChild("ProximityPrompt")) then
            local distance = (obj.Position - root.Position).Magnitude
            
            if distance < 200 then
                if UseInteractableEvent then
                    UseInteractableEvent:FireServer(obj)
                else
                    if obj:IsA("ProximityPrompt") then
                        fireproximityprompt(obj)
                    end
                end
                count = count + 1
            end
        end
    end
    
    return count
end

local function RemoveAllBots()
    local count = 0
    local aiDialogEvent = Events.AI and Events.AI:FindFirstChild("Dialog")
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and (v.Name:lower():find("bot") or v.Name:lower():find("nextbot") or v:FindFirstChild("IsBot") or v:FindFirstChild("AI")) then
            if aiDialogEvent then
                aiDialogEvent:FireServer(v, "remove")
            end
            
            v:Destroy()
            count = count + 1
        end
    end
    
    return count
end

-- ============================================
-- ФУНКЦИИ ДЕЙСТВИЙ
-- ============================================

local function SetBoomboxMusic(musicId)
    local boomboxEvent = Events.Player and Events.Player:FindFirstChild("SetBoombox")
    if boomboxEvent then
        boomboxEvent:FireServer(musicId)
        return true
    end
    return false
end

local function Emote(emoteName)
    local emoteEvent = Events.Character and Events.Character:FindFirstChild("Emote")
    if emoteEvent then
        emoteEvent:FireServer(emoteName or "Dance")
        return true
    end
    return false
end

local function UsePerk()
    local usePerkEvent = Events.Character and Events.Character:FindFirstChild("UsePerk")
    if usePerkEvent then
        usePerkEvent:FireServer()
        return true
    end
    return false
end

local function Whistle()
    local whistleEvent = Events.Character and Events.Character:FindFirstChild("Whistle")
    if whistleEvent then
        whistleEvent:FireServer()
        return true
    end
    return false
end

-- ============================================
-- AFK FARM MODE
-- ============================================

local function AFKFarmMode()
    local root = GetRoot()
    local hum = GetHum()
    local char = GetChar()
    
    if not root or not hum or not char then return end
    
    -- 1. ПРИОРИТЕТ: Проверка здоровья и воскрешение себя
    if hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then
        SelfRevive()
        wait(2)
        return
    end
    
    -- 2. Лечение если HP низкое
    if hum.Health < AFKSettings.AutoHealThreshold then
        pcall(function()
            local passHUDEvent = Events.Character and Events.Character:FindFirstChild("PassHUDInfo")
            if passHUDEvent then
                passHUDEvent:FireServer("Heal", hum.MaxHealth)
            end
            hum.Health = hum.MaxHealth
        end)
    end
    
    -- 3. Проверка ботов рядом - УБЕГАЕМ В БЕЗОПАСНУЮ ЗОНУ
    local nearestBot = GetNearestBot()
    if nearestBot then
        local botRoot = nearestBot:FindFirstChild("HumanoidRootPart")
        if botRoot then
            local distance = (root.Position - botRoot.Position).Magnitude
            
            if distance < AFKSettings.BotDangerDistance then
                print("⚠️ Бот близко! Убегаем в безопасную зону...")
                TeleportTo(AFKSettings.SafeZone)
                wait(3)
                return
            end
        end
    end
    
    -- 4. Воскрешение упавших игроков (ПРИОРИТЕТ)
    local revivedSomeone = false
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local theirChar = player.Character
            local theirHum = theirChar:FindFirstChildOfClass("Humanoid")
            local theirRoot = theirChar:FindFirstChild("HumanoidRootPart")
            
            if theirHum and theirRoot and (theirHum.Health == 0 or theirHum:GetState() == Enum.HumanoidStateType.Dead) then
                local distance = (root.Position - theirRoot.Position).Magnitude
                
                if distance < AFKSettings.ReviveRadius then
                    if not revivedPlayers[player.UserId] or tick() - revivedPlayers[player.UserId] > 30 then
                        print("💚 Воскрешаем игрока:", player.Name)
                        
                        local originalPos = root.CFrame
                        
                        TeleportTo(theirRoot.Position + Vector3.new(0, 0, 3))
                        wait(0.5)
                        
                        local verifyEvent = Events.Character and Events.Character:FindFirstChild("VerifyRange")
                        if verifyEvent then
                            verifyEvent:InvokeServer("Revive", player)
                        end
                        
                        for _, obj in pairs(theirChar:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") and (obj.Name:lower():find("revive") or obj.Name:lower():find("heal")) then
                                fireproximityprompt(obj)
                                revivedPlayers[player.UserId] = tick()
                                revivedSomeone = true
                                break
                            end
                        end
                        
                        wait(1)
                        TeleportTo(originalPos.Position)
                        wait(1)
                        
                        if revivedSomeone then
                            return
                        end
                    end
                end
            else
                revivedPlayers[player.UserId] = nil
            end
        end
    end
    
    -- 5. Сбор монет (если безопасно)
    local coins = GetCoins()
    for _, coin in pairs(coins) do
        local distance = (coin.Position - root.Position).Magnitude
        
        if distance < AFKSettings.CoinRadius then
            local nearBot = GetNearestBot()
            if nearBot then
                local botRoot = nearBot:FindFirstChild("HumanoidRootPart")
                if botRoot and (root.Position - botRoot.Position).Magnitude < AFKSettings.BotDangerDistance then
                    break
                end
            end
            
            local collectEvent = Events.Collectibles and Events.Collectibles:FindFirstChild("Impulse")
            if collectEvent then
                collectEvent:FireServer(coin)
            end
            
            firetouchinterest(root, coin, 0)
            wait(0.05)
            firetouchinterest(root, coin, 1)
        end
    end
end

-- ============================================
-- ИГРОВЫЕ ЦИКЛЫ
-- ============================================

-- Speed Boost
spawn(function()
    while wait() do
        pcall(function()
            local hum = GetHum()
            local root = GetRoot()
            
            if Settings.Speed and hum and root then
                hum.WalkSpeed = Settings.SpeedValue
                
                if SpeedBoostEvent then
                    SpeedBoostEvent:FireServer(Settings.SpeedValue / 16)
                end
                
                if UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.A) or 
                   UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.D) then
                    local moveDirection = hum.MoveDirection
                    if moveDirection.Magnitude > 0 then
                        root.CFrame = root.CFrame + moveDirection * (Settings.SpeedValue / 100)
                    end
                end
            end
        end)
    end
end)

-- Jump Boost
spawn(function()
    while wait() do
        pcall(function()
            local hum = GetHum()
            
            if Settings.Jump and hum then
                if hum.UseJumpPower then
                    hum.JumpPower = Settings.JumpValue
                else
                    hum.JumpHeight = Settings.JumpValue / 4
                end
            end
        end)
    end
end)

-- Bhop
spawn(function()
    while wait() do
        if Settings.Bhop then
            pcall(function()
                local hum = GetHum()
                if hum and UIS:IsKeyDown(Enum.KeyCode.Space) then
                    local state = hum:GetState()
                    if state ~= Enum.HumanoidStateType.Freefall and state ~= Enum.HumanoidStateType.Flying then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        end
    end
end)

-- Noclip
spawn(function()
    while wait() do
        if Settings.Noclip then
            pcall(function()
                local char = GetChar()
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Self Revive
spawn(function()
    while wait(1) do
        if Settings.AutoSelfRevive then
            pcall(function()
                SelfRevive()
            end)
        end
    end
end)

-- Auto Revive Others
spawn(function()
    while wait(2) do
        if Settings.AutoReviveOthers then
            pcall(function()
                ReviveOthers()
            end)
        end
    end
end)

-- Auto Collect Coins
spawn(function()
    while wait(0.3) do
        if Settings.AutoCollectCoins then
            pcall(function()
                CollectCoins()
            end)
        end
    end
end)

-- ESP
spawn(function()
    while wait(2) do
        if Settings.ESP then
            pcall(function()
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LP and player.Character then
                        CreateESP(player.Character, Color3.fromRGB(255, 255, 255))
                    end
                end
            end)
        else
            pcall(function()
                for _, player in pairs(Players:GetPlayers()) do
                    if player.Character then
                        local esp = player.Character:FindFirstChild("ESP_Highlight")
                        if esp then esp:Destroy() end
                    end
                end
            end)
        end
    end
end)

-- Bot Ignore
spawn(function()
    while wait(0.1) do
        if Settings.BotIgnore then
            pcall(function()
                local root = GetRoot()
                if root then
                    for _, bot in pairs(workspace:GetDescendants()) do
                        if bot.Name == "Nextbot" or bot.Name == "Bot" or bot:FindFirstChild("IsBot") or bot:FindFirstChild("AI") then
                            if bot:IsA("Model") and bot:FindFirstChild("HumanoidRootPart") then
                                local botRoot = bot:FindFirstChild("HumanoidRootPart")
                                local distance = (botRoot.Position - root.Position).Magnitude
                                
                                if distance < 50 then
                                    local direction = (botRoot.Position - root.Position).Unit
                                    botRoot.CFrame = CFrame.new(root.Position + direction * 100)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Ghost Mode
spawn(function()
    while wait(0.3) do
        if Settings.GhostMode then
            pcall(function()
                local char = GetChar()
                local root = GetRoot()
                
                if char and root then
                    if not char:FindFirstChild("Ghost") then
                        local ghostTag = Instance.new("BoolValue")
                        ghostTag.Name = "Ghost"
                        ghostTag.Value = true
                        ghostTag.Parent = char
                    end
                    
                    if not char:FindFirstChild("IgnoreByBots") then
                        local ignoreTag = Instance.new("BoolValue")
                        ignoreTag.Name = "IgnoreByBots"
                        ignoreTag.Value = true
                        ignoreTag.Parent = char
                    end
                    
                    for _, bot in pairs(workspace:GetDescendants()) do
                        if bot:IsA("Model") and (bot.Name:lower():find("bot") or bot.Name:lower():find("nextbot") or bot:FindFirstChild("IsBot") or bot:FindFirstChild("AI")) then
                            local botRoot = bot:FindFirstChild("HumanoidRootPart") or bot:FindFirstChild("Torso")
                            if botRoot then
                                local distance = (botRoot.Position - root.Position).Magnitude
                                if distance < 30 then
                                    local direction = (botRoot.Position - root.Position).Unit
                                    botRoot.CFrame = CFrame.new(root.Position + direction * 50)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- No Bots Mode
spawn(function()
    while wait(1) do
        if Settings.NoBots then
            pcall(function()
                for _, bot in pairs(workspace:GetDescendants()) do
                    if bot:IsA("Model") and (bot.Name:lower():find("bot") or bot.Name:lower():find("nextbot") or bot:FindFirstChild("IsBot") or bot:FindFirstChild("AI")) then
                        bot:Destroy()
                    end
                end
                
                for _, spawner in pairs(workspace:GetDescendants()) do
                    if spawner.Name:lower():find("spawn") and spawner:IsA("Part") then
                        spawner.Transparency = 1
                        spawner.CanCollide = false
                    end
                end
            end)
        end
    end
end)

-- Fullbright
spawn(function()
    while wait(1) do
        if Settings.Fullbright then
            pcall(function()
                game:GetService("Lighting").Brightness = 2
                game:GetService("Lighting").ClockTime = 14
                game:GetService("Lighting").GlobalShadows = false
                game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            end)
        end
    end
end)

-- No Fog
spawn(function()
    while wait(1) do
        if Settings.NoFog then
            pcall(function()
                game:GetService("Lighting").FogEnd = 100000
            end)
        end
    end
end)

-- Prank Stick
UIS.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and Settings.PrankStick then
        local currentTime = tick()
        
        if currentTime - lastPrankClick < 1 then
            return
        end
        
        lastPrankClick = currentTime
        
        spawn(function()
            pcall(function()
                local myChar = GetChar()
                local myRoot = GetRoot()
                
                if myChar and myRoot then
                    local mouse = LP:GetMouse()
                    local target = mouse.Target
                    
                    if target and target.Parent then
                        local targetChar = target.Parent
                        local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
                        
                        if targetPlayer and targetPlayer ~= LP then
                            local theirRoot = targetChar:FindFirstChild("HumanoidRootPart")
                            if theirRoot then
                                local distance = (myRoot.Position - theirRoot.Position).Magnitude
                                
                                if distance < 30 then
                                    local theirHum = targetChar:FindFirstChildOfClass("Humanoid")
                                    if theirHum and theirHum.Health > 0 then
                                        if RigImpulseEvent then
                                            RigImpulseEvent:FireServer(targetPlayer, Vector3.new(0, -100, 0))
                                        end
                                        
                                        theirHum.Health = 0
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end)
    end
end)

-- AFK Farm Loop
spawn(function()
    while wait(0.5) do
        if AFKSettings.Enabled then
            pcall(function()
                AFKFarmMode()
            end)
        end
    end
end)

-- ============================================
-- ПУБЛИЧНЫЕ ФУНКЦИИ ДЛЯ УПРАВЛЕНИЯ
-- ============================================

-- AFK Farm функции
function StartAFKFarm()
    AFKSettings.Enabled = true
    
    Settings.Speed = true
    Settings.SpeedValue = 30
    Settings.Jump = true
    Settings.JumpValue = 70
    Settings.AutoSelfRevive = true
    Settings.GhostMode = true
    Settings.BotIgnore = true
    Settings.ESP = true
    Settings.Fullbright = true
    Settings.NoFog = true
    
    print("✅ AFK Farm Mode ВКЛЮЧЕН!")
    print("🤖 Автоматизация:")
    print("  • Автовоскрешение себя")
    print("  • Автовоскрешение других игроков")
    print("  • Автосбор монет")
    print("  • Автоуклонение от ботов")
    print("  • Автолечение при низком HP")
    print("")
    print("⚠️ Можете отойти от компьютера!")
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "AFK Farm Mode";
        Text = "Включен! Можете отойти от ПК";
        Duration = 5;
    })
end

function StopAFKFarm()
    AFKSettings.Enabled = false
    
    print("❌ AFK Farm Mode ВЫКЛЮЧЕН!")
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "AFK Farm Mode";
        Text = "Выключен";
        Duration = 3;
    })
end

function SetSafeZone(position)
    AFKSettings.SafeZone = position
    print("✅ Безопасная зона установлена:", position)
end

function SetCurrentPositionAsSafeZone()
    local root = GetRoot()
    if root then
        AFKSettings.SafeZone = root.Position
        print("✅ Текущая позиция установлена как безопасная зона:", root.Position)
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Safe Zone";
            Text = "Текущая позиция сохранена!";
            Duration = 3;
        })
    end
end

-- Дополнительные функции
function EnableSpeed(value)
    Settings.Speed = true
    Settings.SpeedValue = value or 25
    print("✅ Speed включен:", Settings.SpeedValue)
end

function DisableSpeed()
    Settings.Speed = false
    local hum = GetHum()
    if hum then hum.WalkSpeed = 16 end
    print("❌ Speed выключен")
end

function EnableJump(value)
    Settings.Jump = true
    Settings.JumpValue = value or 60
    print("✅ Jump включен:", Settings.JumpValue)
end

function DisableJump()
    Settings.Jump = false
    local hum = GetHum()
    if hum then
        if hum.UseJumpPower then
            hum.JumpPower = 50
        else
            hum.JumpHeight = 7.2
        end
    end
    print("❌ Jump выключен")
end

function EnableESP()
    Settings.ESP = true
    print("✅ ESP включен")
end

function DisableESP()
    Settings.ESP = false
    print("❌ ESP выключен")
end

function EnableGhostMode()
    Settings.GhostMode = true
    print("✅ Ghost Mode включен")
end

function DisableGhostMode()
    Settings.GhostMode = false
    print("❌ Ghost Mode выключен")
end

function EnableNoclip()
    Settings.Noclip = true
    print("✅ Noclip включен")
end

function DisableNoclip()
    Settings.Noclip = false
    print("❌ Noclip выключен")
end

function TeleportToSafeZone()
    TeleportTo(AFKSettings.SafeZone)
    print("✅ Телепортация в безопасную зону")
end

function CollectAllCoins()
    CollectCoins()
    print("✅ Собираем все монеты")
end

function ReviveAllPlayers()
    ReviveOthers()
    print("✅ Воскрешаем всех игроков")
end

function RemoveBots()
    local count = RemoveAllBots()
    print("✅ Удалено ботов:", count)
end

function BreakDoors()
    local count = BreakAllDoors()
    print("✅ Сломано дверей:", count)
end

function UseInteractables()
    local count = UseAllInteractables()
    print("✅ Использовано объектов:", count)
end

-- ============================================
-- ИНФОРМАЦИЯ О СКРИПТЕ
-- ============================================

print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🎮 EVADE ULTIMATE SCRIPT")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")
print("✅ Скрипт загружен успешно!")
print("")
print("📋 ОСНОВНЫЕ ФУНКЦИИ:")
print("")
print("🏃 Движение:")
print("  • Speed Boost - Увеличение скорости")
print("  • Jump Boost - Увеличение прыжка")
print("  • Bhop - Автоматический прыжок")
print("  • Noclip - Прохождение сквозь стены")
print("")
print("👁️ Визуальные:")
print("  • ESP - Подсветка игроков")
print("  • Fullbright - Полная яркость")
print("  • No Fog - Убрать туман")
print("")
print("🔄 Автоматизация:")
print("  • Auto Self Revive - Автовоскрешение себя")
print("  • Auto Revive Others - Автовоскрешение других")
print("  • Auto Collect Coins - Автосбор монет")
print("")
print("🤖 Защита от ботов:")
print("  • Bot Ignore - Боты игнорируют")
print("  • Ghost Mode - Режим призрака")
print("  • No Bots - Удаление ботов")
print("")
print("🎮 Дополнительно:")
print("  • Prank Stick - Палка для сбивания")
print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🤖 AFK FARM MODE")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")
print("📋 КОМАНДЫ:")
print("")
print("StartAFKFarm() - Включить AFK режим")
print("StopAFKFarm() - Выключить AFK режим")
print("SetCurrentPositionAsSafeZone() - Установить безопасную зону")
print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("⚙️ БЫСТРЫЕ КОМАНДЫ")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")
print("EnableSpeed(25) - Включить скорость")
print("DisableSpeed() - Выключить скорость")
print("EnableJump(60) - Включить прыжок")
print("DisableJump() - Выключить прыжок")
print("EnableESP() - Включить ESP")
print("DisableESP() - Выключить ESP")
print("EnableGhostMode() - Включить Ghost Mode")
print("DisableGhostMode() - Выключить Ghost Mode")
print("EnableNoclip() - Включить Noclip")
print("DisableNoclip() - Выключить Noclip")
print("")
print("TeleportToSafeZone() - Телепорт в безопасную зону")
print("CollectAllCoins() - Собрать все монеты")
print("ReviveAllPlayers() - Воскресить всех")
print("RemoveBots() - Удалить всех ботов")
print("BreakDoors() - Сломать все двери")
print("UseInteractables() - Использовать все объекты")
print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("⚙️ НАСТРОЙКИ")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")
print("Settings.Speed = true/false")
print("Settings.SpeedValue = 25")
print("Settings.Jump = true/false")
print("Settings.JumpValue = 60")
print("Settings.Bhop = true/false")
print("Settings.ESP = true/false")
print("Settings.Fullbright = true/false")
print("Settings.NoFog = true/false")
print("Settings.AutoSelfRevive = true/false")
print("Settings.AutoReviveOthers = true/false")
print("Settings.AutoCollectCoins = true/false")
print("Settings.Noclip = true/false")
print("Settings.BotIgnore = true/false")
print("Settings.GhostMode = true/false")
print("Settings.PrankStick = true/false")
print("Settings.NoBots = true/false")
print("")
print("AFKSettings.ReviveRadius = 100")
print("AFKSettings.CoinRadius = 150")
print("AFKSettings.BotDangerDistance = 25")
print("AFKSettings.AutoHealThreshold = 50")
print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")
print("🎯 БЫСТРЫЙ СТАРТ AFK РЕЖИМА:")
print("")
print("1. SetCurrentPositionAsSafeZone()")
print("2. StartAFKFarm()")
print("3. Отойдите от компьютера! ☕")
print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Evade Ultimate";
    Text = "Скрипт загружен! Проверьте консоль (F9)";
    Duration = 5;
})
