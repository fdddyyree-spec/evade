-- EVADE ULTIMATE - Рабочая версия с автовоскрешением
print("🎮 Загрузка Evade Ultimate...")

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Настройки
local Settings = {
    Speed = false,
    SpeedValue = 25,
    AutoRevive = false,
    ReviveRadius = 100,
    GodMode = false,
    ESP = false,
    Fullbright = false,
}

local AFKMode = {
    Enabled = false,
    SafeZone = Vector3.new(0, 100, 0),
}

local revivedPlayers = {}

-- Базовые функции
local function GetChar()
    return LP.Character
end

local function GetHum()
    local char = GetChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetRoot()
    local char = GetChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Функция нажатия E
local function PressE()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

-- Функция телепортации
local function TeleportTo(position)
    local root = GetRoot()
    if root then
        root.CFrame = CFrame.new(position)
    end
end

-- Функция получения ботов
local function GetBots()
    local bots = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name:lower():find("bot") or v.Name:lower():find("nextbot") then
            if v:FindFirstChild("HumanoidRootPart") then
                table.insert(bots, v)
            end
        end
    end
    return bots
end

-- Функция проверки мертвого игрока (улучшенная)
local function IsPlayerDead(player)
    if not player.Character then return false end
    
    local char = player.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if not hum then return false end
    
    -- Проверяем все возможные состояния смерти
    if hum.Health <= 0 then return true end
    if hum.Health < hum.MaxHealth * 0.1 then return true end -- Почти мертв
    if char:FindFirstChild("Downed") then return true end
    if char:FindFirstChild("Ragdoll") then return true end
    if char:FindFirstChild("Dead") then return true end
    
    -- Проверяем состояние Humanoid
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Dead then return true end
    if state == Enum.HumanoidStateType.Physics then return true end
    
    -- Проверяем есть ли ProximityPrompt для воскрешения
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local name = obj.Name:lower()
            if name:find("revive") or name:find("help") or name:find("heal") then
                return true
            end
        end
    end
    
    return false
end

-- ГЛАВНАЯ ФУНКЦИЯ ВОСКРЕШЕНИЯ (по всей карте)
local function AutoRevive()
    local myRoot = GetRoot()
    if not myRoot then return end
    
    -- Ищем ВСЕХ мертвых игроков (без ограничения по расстоянию)
    local deadPlayers = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            if IsPlayerDead(player) then
                local theirRoot = player.Character:FindFirstChild("HumanoidRootPart")
                if theirRoot then
                    local distance = (myRoot.Position - theirRoot.Position).Magnitude
                    table.insert(deadPlayers, {player = player, distance = distance, root = theirRoot})
                end
            else
                revivedPlayers[player.UserId] = nil
            end
        end
    end
    
    if #deadPlayers > 0 then
        print(string.format("🔍 Найдено мертвых игроков: %d", #deadPlayers))
    end
    
    -- Сортируем по расстоянию (ближайший первый)
    table.sort(deadPlayers, function(a, b) return a.distance < b.distance end)
    
    -- Воскрешаем ближайшего
    for _, data in ipairs(deadPlayers) do
        local player = data.player
        local theirRoot = data.root
        
        -- Проверяем не воскрешали ли недавно
        if not revivedPlayers[player.UserId] or tick() - revivedPlayers[player.UserId] > 20 then
            print(string.format("💚 Воскрешаем: %s (Distance: %d studs)", player.Name, math.floor(data.distance)))
            
            -- Сохраняем позицию
            local originalPos = myRoot.CFrame
            
            -- Телепортируемся ПРЯМО к игроку
            for i = 1, 3 do
                TeleportTo(theirRoot.Position + Vector3.new(0, 1, 1))
                wait(0.2)
            end
            
            -- Жмем E много раз
            print("🔧 Жмем E для воскрешения...")
            for i = 1, 10 do
                PressE()
                wait(0.15)
            end
            
            revivedPlayers[player.UserId] = tick()
            
            -- Возвращаемся
            wait(0.3)
            TeleportTo(originalPos.Position)
            
            print("✅ Воскрешение завершено, возвращаемся")
            
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Revive";
                Text = "Воскресили: " .. player.Name;
                Duration = 2;
            })
            
            return -- Воскрешаем по одному за раз
        end
    end
end

-- ЗАЩИТА ОТ БОТОВ (улучшенная)
local function ProtectFromBots()
    local root = GetRoot()
    local char = GetChar()
    if not root or not char then return end
    
    -- Делаем персонажа невидимым для ботов
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Делаем части прозрачными для ботов
            part.CanCollide = false
            
            -- Добавляем тег Ghost
            if not char:FindFirstChild("GhostMode") then
                local ghost = Instance.new("BoolValue")
                ghost.Name = "GhostMode"
                ghost.Parent = char
            end
        end
    end
    
    -- Отталкиваем ботов
    for _, bot in pairs(GetBots()) do
        local botRoot = bot:FindFirstChild("HumanoidRootPart")
        if botRoot then
            local distance = (botRoot.Position - root.Position).Magnitude
            
            -- Если бот близко - отталкиваем его ДАЛЕКО
            if distance < 40 then
                local direction = (botRoot.Position - root.Position).Unit
                botRoot.CFrame = CFrame.new(root.Position + direction * 200)
                
                -- Удаляем бота если слишком близко
                if distance < 15 then
                    bot:Destroy()
                end
            end
        end
    end
end

-- AFK РЕЖИМ
local function AFKLoop()
    local root = GetRoot()
    local hum = GetHum()
    
    if not root or not hum then return end
    
    -- 1. Проверка здоровья
    if hum.Health <= 0 then
        print("💀 Мы мертвы, ждем...")
        wait(5)
        return
    end
    
    -- 2. Защита от ботов
    local nearestBot = nil
    local shortestDistance = math.huge
    
    for _, bot in pairs(GetBots()) do
        local botRoot = bot:FindFirstChild("HumanoidRootPart")
        if botRoot then
            local distance = (botRoot.Position - root.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestBot = bot
            end
        end
    end
    
    -- Если бот близко - убегаем
    if nearestBot and shortestDistance < 25 then
        print("⚠️ БОТ БЛИЗКО! Убегаем в безопасную зону...")
        TeleportTo(AFKMode.SafeZone)
        wait(3)
        return
    end
    
    -- 3. Воскрешаем игроков
    AutoRevive()
end

-- ИГРОВЫЕ ЦИКЛЫ
spawn(function()
    while wait(0.1) do
        if Settings.Speed then
            local hum = GetHum()
            if hum then
                hum.WalkSpeed = Settings.SpeedValue
            end
        end
    end
end)

spawn(function()
    while wait(0.5) do
        if Settings.AutoRevive then
            pcall(AutoRevive)
        end
    end
end)

spawn(function()
    while wait(0.1) do
        if Settings.GodMode then
            pcall(ProtectFromBots)
        end
    end
end)

spawn(function()
    while wait(2) do
        if Settings.ESP then
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
        else
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character then
                    local esp = player.Character:FindFirstChild("ESP_Highlight")
                    if esp then esp:Destroy() end
                end
            end
        end
    end
end)

spawn(function()
    while wait(1) do
        if Settings.Fullbright then
            local lighting = game:GetService("Lighting")
            lighting.Brightness = 2
            lighting.ClockTime = 14
            lighting.FogEnd = 100000
        end
    end
end)

spawn(function()
    while wait(0.5) do
        if AFKMode.Enabled then
            pcall(AFKLoop)
        end
    end
end)

-- ПУБЛИЧНЫЕ ФУНКЦИИ
function StartAFK()
    AFKMode.Enabled = true
    Settings.AutoRevive = true
    Settings.GodMode = true
    Settings.Speed = true
    Settings.SpeedValue = 30
    Settings.ESP = true
    Settings.Fullbright = true
    
    print("✅ AFK режим ВКЛЮЧЕН!")
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "AFK Mode";
        Text = "Включен! Можете отойти";
        Duration = 5;
    })
end

function StopAFK()
    AFKMode.Enabled = false
    print("❌ AFK режим ВЫКЛЮЧЕН!")
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "AFK Mode";
        Text = "Выключен";
        Duration = 3;
    })
end

function SetSafeZone()
    local root = GetRoot()
    if root then
        AFKMode.SafeZone = root.Position
        print("✅ Безопасная зона:", root.Position)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Safe Zone";
            Text = "Позиция сохранена!";
            Duration = 3;
        })
    end
end

function GoToSafeZone()
    TeleportTo(AFKMode.SafeZone)
end

-- GUI
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
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 70)
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Title.BorderSizePixel = 0
Title.Text = "Evade Ultimate - Global Revive"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
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
    Button.Size = UDim2.new(1, -10, 0, 35)
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
    Frame.Size = UDim2.new(1, -10, 0, 35)
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

-- Создание элементов
CreateButton("🤖 START AFK MODE", function()
    SetSafeZone()
    StartAFK()
end)

CreateButton("❌ STOP AFK MODE", function()
    StopAFK()
end)

CreateButton("📍 Set Safe Zone", function()
    SetSafeZone()
end)

CreateButton("🚀 Go to Safe Zone", function()
    GoToSafeZone()
end)

CreateButton("💚 Revive NOW (Manual)", function()
    print("🔧 Ручное воскрешение...")
    AutoRevive()
end)

CreateToggle("💚 Auto Revive", "AutoRevive")
CreateToggle("🛡️ God Mode (Bot Protection)", "GodMode")
CreateToggle("⚡ Speed", "Speed")
CreateToggle("👁️ ESP", "ESP")
CreateToggle("💡 Fullbright", "Fullbright")

CreateButton("🔍 Test Revive", function()
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🔍 ТЕСТ СИСТЕМЫ")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    print("\n👥 Проверка игроков:")
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local isDead = IsPlayerDead(player)
            local theirRoot = player.Character:FindFirstChild("HumanoidRootPart")
            
            if theirRoot then
                local myRoot = GetRoot()
                local distance = myRoot and (myRoot.Position - theirRoot.Position).Magnitude or 999
                
                print(string.format("  👤 %s - Dead: %s, Distance: %.1f", 
                    player.Name, 
                    tostring(isDead), 
                    distance
                ))
            end
        end
    end
    
    print("\n🤖 Проверка ботов:")
    local bots = GetBots()
    print("  Найдено ботов: " .. #bots)
    
    if #bots > 0 then
        local myRoot = GetRoot()
        if myRoot then
            for _, bot in pairs(bots) do
                local botRoot = bot:FindFirstChild("HumanoidRootPart")
                if botRoot then
                    local distance = (myRoot.Position - botRoot.Position).Magnitude
                    print(string.format("  🤖 %s - Distance: %.1f", bot.Name, distance))
                end
            end
        end
    end
    
    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Test";
        Text = "Проверьте консоль (F9)";
        Duration = 3;
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

UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

print("✅ Evade Ultimate загружен!")
print("📋 Right Shift = открыть GUI")
print("💚 Нажмите START AFK MODE для автовоскрешения")

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Evade Ultimate";
    Text = "Загружен! Right Shift = GUI";
    Duration = 5;
})
