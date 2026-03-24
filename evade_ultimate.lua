-- EVADE ULTIMATE - Оптимизированная версия
print("🎮 Загрузка Evade Ultimate...")

-- Защита от повторного запуска
pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("EvadeUltimate") then
        game:GetService("CoreGui"):FindFirstChild("EvadeUltimate"):Destroy()
    end
end)

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Настройки
local Settings = {
    Speed = false,
    SpeedValue = 25,
    Jump = false,
    JumpValue = 60,
    Bhop = false,
    ESP = false,
    Fullbright = false,
    NoFog = false,
    AutoSelfRevive = false,
    AutoReviveOthers = false,
    AutoCollectCoins = false,
    Noclip = false,
    BotIgnore = false,
    GhostMode = false,
    NoBots = false,
}

local AFKSettings = {
    Enabled = false,
    SafeZone = Vector3.new(0, 100, 0),
    ReviveRadius = 100,
    CoinRadius = 150,
    BotDangerDistance = 25,
    AutoHealThreshold = 50,
}

local revivedPlayers = {}
local lastSelfRevive = 0

-- Базовые функции
local function GetChar()
    return LP.Character and LP.Character.Parent and LP.Character or nil
end

local function GetHum()
    local char = GetChar()
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

local function GetRoot()
    local char = GetChar()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")) or nil
end

local function TeleportTo(position)
    local root = GetRoot()
    if root then
        root.CFrame = CFrame.new(position)
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
        if v:IsA("BasePart") and (v.Name:lower():find("coin") or v.Name:lower():find("collectible")) then
            table.insert(coins, v)
        end
    end
    return coins
end

-- Функции воскрешения (упрощенные)
local function SelfRevive()
    pcall(function()
        local char = GetChar()
        local hum = GetHum()
        
        if char and hum and hum.Health <= 0 then
            local currentTime = tick()
            
            if currentTime - lastSelfRevive > 3 then
                lastSelfRevive = currentTime
                
                for _, obj in pairs(char:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and obj.Name:lower():find("revive") then
                        fireproximityprompt(obj)
                        break
                    end
                end
            end
        end
    end)
end

local function ReviveOthers()
    pcall(function()
        local myRoot = GetRoot()
        if not myRoot then return end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                local theirChar = player.Character
                local theirHum = theirChar:FindFirstChildOfClass("Humanoid")
                local theirRoot = theirChar:FindFirstChild("HumanoidRootPart")
                
                if theirHum and theirRoot and theirHum.Health <= 0 then
                    local distance = (myRoot.Position - theirRoot.Position).Magnitude
                    
                    if distance < AFKSettings.ReviveRadius then
                        if not revivedPlayers[player.UserId] or tick() - revivedPlayers[player.UserId] > 30 then
                            local originalPos = myRoot.CFrame
                            
                            TeleportTo(theirRoot.Position + Vector3.new(0, 0, 3))
                            wait(0.5)
                            
                            for _, obj in pairs(theirChar:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") and obj.Name:lower():find("revive") then
                                    fireproximityprompt(obj)
                                    revivedPlayers[player.UserId] = tick()
                                    break
                                end
                            end
                            
                            wait(1)
                            TeleportTo(originalPos.Position)
                            return
                        end
                    end
                else
                    revivedPlayers[player.UserId] = nil
                end
            end
        end
    end)
end

-- AFK Farm Mode
local function AFKFarmMode()
    pcall(function()
        local root = GetRoot()
        local hum = GetHum()
        
        if not root or not hum then return end
        
        -- 1. Проверка здоровья
        if hum.Health <= 0 then
            SelfRevive()
            wait(2)
            return
        end
        
        -- 2. Лечение
        if hum.Health < AFKSettings.AutoHealThreshold then
            hum.Health = hum.MaxHealth
        end
        
        -- 3. Проверка ботов
        local nearestBot = GetNearestBot()
        if nearestBot then
            local botRoot = nearestBot:FindFirstChild("HumanoidRootPart")
            if botRoot then
                local distance = (root.Position - botRoot.Position).Magnitude
                
                if distance < AFKSettings.BotDangerDistance then
                    TeleportTo(AFKSettings.SafeZone)
                    wait(3)
                    return
                end
            end
        end
        
        -- 4. Воскрешение игроков
        ReviveOthers()
        
        -- 5. Сбор монет
        for _, coin in pairs(GetCoins()) do
            local distance = (coin.Position - root.Position).Magnitude
            
            if distance < AFKSettings.CoinRadius then
                firetouchinterest(root, coin, 0)
                wait(0.05)
                firetouchinterest(root, coin, 1)
            end
        end
    end)
end

-- Игровые циклы (оптимизированные)
spawn(function()
    while wait(0.1) do
        pcall(function()
            local hum = GetHum()
            local root = GetRoot()
            
            if Settings.Speed and hum and root then
                hum.WalkSpeed = Settings.SpeedValue
            end
            
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

spawn(function()
    while wait(0.05) do
        if Settings.Bhop then
            pcall(function()
                local hum = GetHum()
                if hum and UIS:IsKeyDown(Enum.KeyCode.Space) then
                    local state = hum:GetState()
                    if state ~= Enum.HumanoidStateType.Freefall then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        end
    end
end)

spawn(function()
    while wait(0.1) do
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

spawn(function()
    while wait(1) do
        if Settings.AutoSelfRevive then
            SelfRevive()
        end
    end
end)

spawn(function()
    while wait(2) do
        if Settings.AutoReviveOthers then
            ReviveOthers()
        end
    end
end)

spawn(function()
    while wait(0.5) do
        if Settings.AutoCollectCoins then
            pcall(function()
                local root = GetRoot()
                if root then
                    for _, coin in pairs(GetCoins()) do
                        if (coin.Position - root.Position).Magnitude < 100 then
                            firetouchinterest(root, coin, 0)
                            wait()
                            firetouchinterest(root, coin, 1)
                        end
                    end
                end
            end)
        end
    end
end)

spawn(function()
    while wait(2) do
        if Settings.ESP then
            pcall(function()
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LP and player.Character then
                        if not player.Character:FindFirstChild("ESP_Highlight") then
                            local highlight = Instance.new("Highlight")
                            highlight.Name = "ESP_Highlight"
                            highlight.FillColor = Color3.fromRGB(255, 255, 255)
                            highlight.FillTransparency = 0.5
                            highlight.Parent = player.Character
                        end
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

spawn(function()
    while wait(0.2) do
        if Settings.BotIgnore then
            pcall(function()
                local root = GetRoot()
                if root then
                    for _, bot in pairs(GetBots()) do
                        local botRoot = bot:FindFirstChild("HumanoidRootPart")
                        if botRoot then
                            local distance = (botRoot.Position - root.Position).Magnitude
                            if distance < 50 then
                                local direction = (botRoot.Position - root.Position).Unit
                                botRoot.CFrame = CFrame.new(root.Position + direction * 100)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

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
                    
                    for _, bot in pairs(GetBots()) do
                        local botRoot = bot:FindFirstChild("HumanoidRootPart")
                        if botRoot then
                            local distance = (botRoot.Position - root.Position).Magnitude
                            if distance < 30 then
                                local direction = (botRoot.Position - root.Position).Unit
                                botRoot.CFrame = CFrame.new(root.Position + direction * 50)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

spawn(function()
    while wait(1) do
        if Settings.NoBots then
            pcall(function()
                for _, bot in pairs(GetBots()) do
                    bot:Destroy()
                end
            end)
        end
    end
end)

spawn(function()
    while wait(1) do
        if Settings.Fullbright then
            pcall(function()
                local lighting = game:GetService("Lighting")
                lighting.Brightness = 2
                lighting.ClockTime = 14
                lighting.GlobalShadows = false
            end)
        end
    end
end)

spawn(function()
    while wait(1) do
        if Settings.NoFog then
            pcall(function()
                game:GetService("Lighting").FogEnd = 100000
            end)
        end
    end
end)

spawn(function()
    while wait(0.5) do
        if AFKSettings.Enabled then
            AFKFarmMode()
        end
    end
end)

-- Публичные функции
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
    
    print("✅ AFK Farm ВКЛЮЧЕН!")
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "AFK Farm";
        Text = "Включен! Можете отойти";
        Duration = 5;
    })
end

function StopAFKFarm()
    AFKSettings.Enabled = false
    print("❌ AFK Farm ВЫКЛЮЧЕН!")
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "AFK Farm";
        Text = "Выключен";
        Duration = 3;
    })
end

function SetCurrentPositionAsSafeZone()
    local root = GetRoot()
    if root then
        AFKSettings.SafeZone = root.Position
        print("✅ Безопасная зона установлена:", root.Position)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Safe Zone";
            Text = "Позиция сохранена!";
            Duration = 3;
        })
    end
end

function TeleportToSafeZone()
    TeleportTo(AFKSettings.SafeZone)
end

function RemoveAllBots()
    local count = 0
    for _, bot in pairs(GetBots()) do
        bot:Destroy()
        count = count + 1
    end
    return count
end

-- GUI (упрощенный и оптимизированный)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EvadeUltimate"
ScreenGui.ResetOnSpawn = false

pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)

if not ScreenGui.Parent then
    ScreenGui.Parent = LP:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 450)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 70)
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Title.BorderSizePixel = 0
Title.Text = "Evade Ultimate"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -32, 0, 2.5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Title

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -10, 1, -45)
ContentFrame.Position = UDim2.new(0, 5, 0, 40)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.ScrollBarThickness = 4
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.Parent = ContentFrame

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
end)

local function CreateButton(text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 30)
    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 13
    Button.Font = Enum.Font.Gotham
    Button.BorderSizePixel = 0
    Button.Parent = ContentFrame
    
    Button.MouseButton1Click:Connect(callback)
    return Button
end

local function CreateToggle(text, setting)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 30)
    Frame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    Frame.BorderSizePixel = 0
    Frame.Parent = ContentFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -40, 1, 0)
    Label.Position = UDim2.new(0, 5, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 35, 0, 20)
    Toggle.Position = UDim2.new(1, -38, 0.5, -10)
    Toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
    Toggle.Text = Settings[setting] and "ON" or "OFF"
    Toggle.TextColor3 = Settings[setting] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
    Toggle.TextSize = 11
    Toggle.Font = Enum.Font.GothamBold
    Toggle.BorderSizePixel = 0
    Toggle.Parent = Frame
    
    Toggle.MouseButton1Click:Connect(function()
        Settings[setting] = not Settings[setting]
        Toggle.Text = Settings[setting] and "ON" or "OFF"
        Toggle.TextColor3 = Settings[setting] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
    end)
    
    return Frame
end

-- Создание элементов GUI
CreateButton("🤖 START AFK FARM", function()
    SetCurrentPositionAsSafeZone()
    StartAFKFarm()
end)

CreateButton("❌ STOP AFK FARM", function()
    StopAFKFarm()
end)

CreateButton("📍 Set Safe Zone", function()
    SetCurrentPositionAsSafeZone()
end)

CreateToggle("⚡ Speed", "Speed")
CreateToggle("🦘 Jump", "Jump")
CreateToggle("🔄 Bhop", "Bhop")
CreateToggle("👁️ ESP", "ESP")
CreateToggle("💡 Fullbright", "Fullbright")
CreateToggle("🌫️ No Fog", "NoFog")
CreateToggle("💚 Auto Self Revive", "AutoSelfRevive")
CreateToggle("💚 Auto Revive Others", "AutoReviveOthers")
CreateToggle("💰 Auto Collect Coins", "AutoCollectCoins")
CreateToggle("👻 Noclip", "Noclip")
CreateToggle("🤖 Bot Ignore", "BotIgnore")
CreateToggle("👻 Ghost Mode", "GhostMode")
CreateToggle("🚫 No Bots", "NoBots")

CreateButton("🚀 Teleport to Safe Zone", function()
    TeleportToSafeZone()
end)

CreateButton("🤖 Remove All Bots", function()
    local count = RemoveAllBots()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Bots";
        Text = "Удалено: " .. count;
        Duration = 2;
    })
end)

-- Dragging
local dragging = false
local dragInput, mousePos, framePos

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        local delta = input.Position - mousePos
        MainFrame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)

-- Открытие/закрытие
UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

print("✅ Evade Ultimate загружен!")
print("📋 Нажмите Right Shift чтобы открыть GUI")

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Evade Ultimate";
    Text = "Загружен! Right Shift = GUI";
    Duration = 5;
})
