local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local player = Players.LocalPlayer

if _G.LootAttackCleanup then pcall(_G.LootAttackCleanup) end

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "布洛克斯",
    Icon = "crosshair",
    Author = "索尼", 
    Folder = "LootAttack",
    Size = UDim2.fromOffset(480, 400),
    Transparent = true,
    Theme = "Dark",
    NewElements = true,
})

local dialogClosed = false
Window:Dialog({
    Title = "优化更新",
    Content = "1. 彻底修复关闭后依然疯狂传送的问题\n2. 重新设计中心锁定准星（红色方框）\n3. 锁定目标后死磕到底",
    Buttons = { { Title = "确定", Callback = function() dialogClosed = true end } }
})
repeat task.wait(0.1) until dialogClosed

local TabCombat = Window:Tab({ Title = "战斗", Icon = "shield" })
local TabVisual = Window:Tab({ Title = "透视", Icon = "eye" })
local TabAssist = Window:Tab({ Title = "辅助", Icon = "star" })

local nearestEnabled = false
local aoeEnabled = false
local espEnabled = false
local autoInteractEnabled = false
local originalFOV = Camera.FieldOfView
local attackThread = nil
local interactThread = nil
local spinSpeed = 150
local attackDelay = 0.03
local aoeRange = 40
local currentTarget = nil

-- ================== 中心红色锁定准星（代替彩虹圈） ==================
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local lockBox = Instance.new("Frame", gui)
lockBox.Size = UDim2.fromOffset(100, 100) -- 锁定方框大小
lockBox.AnchorPoint = Vector2.new(0.5, 0.5)
lockBox.Position = UDim2.new(0.5, 0, 0.5, 0)
lockBox.BackgroundTransparency = 1
lockBox.Visible = false

local boxStroke = Instance.new("UIStroke", lockBox)
boxStroke.Thickness = 2
boxStroke.Color = Color3.fromRGB(255, 0, 0) -- 红色准星

-- 准星中心点
local dot = Instance.new("Frame", lockBox)
dot.Size = UDim2.fromOffset(4, 4)
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.new(0.5, 0, 0.5, 0)
dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

-- 核心战斗（修复了关闭后发疯的Bug）
local function StartAttackThread()
    if attackThread then
        pcall(function() task.cancel(attackThread) end)
        attackThread = nil
    end
    
    lockBox.Visible = true
    Camera.FieldOfView = 100
    
    attackThread = task.spawn(function()
        while nearestEnabled or aoeEnabled do
            pcall(function()
                local enemiesFolder = Workspace:FindFirstChild("Runtime") and Workspace.Runtime:FindFirstChild("Enemies")
                local actorsFolder = ReplicatedStorage:FindFirstChild("Runtime") and ReplicatedStorage.Runtime:FindFirstChild("Actors")
                local character = player.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                local tool = character and character:FindFirstChildWhichIsA("Tool")
                
                if enemiesFolder and actorsFolder and hrp and tool then
                    local actorId = tool:FindFirstChild("ActorId")
                    local actor = actorId and actorsFolder:FindFirstChild(actorId.Value)
                    local remoteFunction = actor and actor:FindFirstChild("Functions") and actor.Functions:FindFirstChild("Attack")
                    
                    local allEnemies = {}
                    for _, model in ipairs(enemiesFolder:GetChildren()) do
                        local humanoid = model:FindFirstChildOfClass("Humanoid")
                        local rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart")
                        if humanoid and humanoid.Health > 0 and rootPart then
                            table.insert(allEnemies, {model = model, root = rootPart, hum = humanoid, dist = (rootPart.Position - hrp.Position).Magnitude})
                        end
                    end
                    
                    table.sort(allEnemies, function(a, b) return a.dist < b.dist end)

                    if nearestEnabled then
                        -- 锁定死磕机制
                        if not currentTarget or currentTarget.hum.Health <= 0 or not currentTarget.root.Parent then
                            currentTarget = allEnemies[1]
                        end
                        
                        if currentTarget and currentTarget.hum.Health > 0 then
                            local targetRoot = currentTarget.root
                            local dest = targetRoot.Position - (targetRoot.CFrame.LookVector * 1.5)
                            hrp.CFrame = CFrame.new(dest, targetRoot.Position) * CFrame.Angles(0, math.rad(tick() * spinSpeed), 0)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            Camera.CFrame = CFrame.lookAt(hrp.Position + Vector3.new(0, 6, 0) - targetRoot.CFrame.LookVector * 5, targetRoot.Position)
                            
                            if remoteFunction then 
                                task.spawn(function() pcall(function() remoteFunction:InvokeServer() end) end)
                            end
                        end
                    elseif aoeEnabled then
                        local aoeTargets = {}
                        for _, enemy in ipairs(allEnemies) do
                            if enemy.dist <= aoeRange then table.insert(aoeTargets, enemy) end
                        end
                        
                        for _, enemy in ipairs(aoeTargets) do
                            local targetRoot = enemy.root
                            local dest = targetRoot.Position - (targetRoot.CFrame.LookVector * 1.5)
                            hrp.CFrame = CFrame.new(dest, targetRoot.Position) * CFrame.Angles(0, math.rad(tick() * spinSpeed), 0)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            Camera.CFrame = CFrame.lookAt(hrp.Position + Vector3.new(0, 6, 0) - targetRoot.CFrame.LookVector * 5, targetRoot.Position)
                            
                            if remoteFunction then pcall(function() remoteFunction:InvokeServer() end) end
                            task.wait(attackDelay)
                        end
                    end
                end
            end)
            RunService.Heartbeat:Wait()
        end
        lockBox.Visible = false
        Camera.FieldOfView = originalFOV
        attackThread = nil
    end)
end

TabCombat:Toggle({ Title = "贴身死磕 (锁定最近)", Default = false, Callback = function(state) 
    nearestEnabled = state 
    currentTarget = nil 
    if state then StartAttackThread() else 
        if not aoeEnabled then
            if attackThread then pcall(function() task.cancel(attackThread) end) attackThread = nil end
            lockBox.Visible = false
            Camera.FieldOfView = originalFOV
        end
    end 
end })

TabCombat:Toggle({ Title = "范围群伤 (AOE)", Default = false, Callback = function(state) 
    aoeEnabled = state 
    if state then StartAttackThread() else 
        if not nearestEnabled then
            if attackThread then pcall(function() task.cancel(attackThread) end) attackThread = nil end
            lockBox.Visible = false
            Camera.FieldOfView = originalFOV
        end
    end 
end })

TabCombat:Slider({ Title = "自转速度", Value = { Min = 10, Max = 500, Default = 150 }, Increment = 10, Callback = function(value) spinSpeed = value end })
TabCombat:Slider({ Title = "AOE攻击间隔", Value = { Min = 0.01, Max = 0.2, Default = 0.03 }, Increment = 0.01, Callback = function(value) attackDelay = value end })
TabCombat:Slider({ Title = "AOE范围", Value = { Min = 10, Max = 150, Default = 40 }, Increment = 5, Callback = function(value) aoeRange = value end })-- ================== 视觉透视模块 ==================
local espObjects = {}
local function ClearESP()
    for _, object in pairs(espObjects) do
        if object and object.Parent then object:Destroy() end
    end
    espObjects = {}
end

local function CreateESP(targetCharacter)
    if not targetCharacter then return end
    local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    local rootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    local head = targetCharacter:FindFirstChild("Head")
    if not humanoid or not rootPart or not head or humanoid.Health <= 0 then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BoxESP"
    billboard.Adornee = rootPart
    billboard.Size = UDim2.new(4, 0, 6, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = targetCharacter
    
    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    local uiStroke = Instance.new("UIStroke", frame)
    uiStroke.Color = Color3.fromRGB(0, 255, 0)
    uiStroke.Thickness = 1.5

    local ray = Instance.new("Frame", billboard)
    ray.Size = UDim2.new(0, 1, 0, 80)
    ray.Position = UDim2.new(0.5, 0, 0, -80)
    ray.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    ray.BorderSizePixel = 0

    local textGui = Instance.new("BillboardGui")
    textGui.Name = "TextESP"
    textGui.Adornee = head
    textGui.Size = UDim2.new(0, 200, 0, 50)
    textGui.StudsOffset = Vector3.new(0, 3.5, 0)
    textGui.AlwaysOnTop = true
    textGui.Parent = targetCharacter

    local nameTag = Instance.new("TextLabel", textGui)
    nameTag.Size = UDim2.new(1, 0, 1, 0)
    nameTag.BackgroundTransparency = 1
    nameTag.TextColor3 = Color3.fromRGB(0, 255, 0)
    nameTag.TextStrokeTransparency = 0.5
    nameTag.TextSize = 14
    nameTag.Font = Enum.Font.GothamBold
    nameTag.RichText = true

    table.insert(espObjects, billboard)
    table.insert(espObjects, textGui)
end

TabVisual:Toggle({
    Title = "开启 2D 天线透视",
    Default = false,
    Callback = function(state)
        espEnabled = state
        if state then
            task.spawn(function()
                while espEnabled do
                    for _, otherPlayer in ipairs(Players:GetPlayers()) do
                        if otherPlayer ~= player and otherPlayer.Character then
                            local hasESP = false
                            for _, obj in pairs(espObjects) do
                                if obj.Parent == otherPlayer.Character then hasESP = true break end
                            end
                            if not hasESP then CreateESP(otherPlayer.Character) end
                        end
                    end
                    
                    for _, obj in pairs(espObjects) do
                        pcall(function()
                            if obj.Name == "TextESP" then
                                local char = obj.Adornee and obj.Adornee.Parent
                                local hum = char and char:FindFirstChildOfClass("Humanoid")
                                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                                local charRoot = char and char:FindFirstChild("HumanoidRootPart")
                                
                                if hum and hrp and charRoot then
                                    local dist = math.floor((hrp.Position - charRoot.Position).Magnitude)
                                    local hp = math.floor(hum.Health)
                                    local label = obj:FindFirstChildOfClass("TextLabel")
                                    if label then
                                        label.Text = string.format("[%d m] %s [%d HP]", dist, char.Name, hp)
                                    end
                                end
                            end
                        end)
                    end
                    task.wait(0.5)
                end
            end)
        else
            ClearESP()
        end
    end
})

-- ================== 自动互动 ==================
TabAssist:Toggle({
    Title = "自动互动",
    Default = false,
    Callback = function(state)
        autoInteractEnabled = state
        if state and not interactThread then
            interactThread = task.spawn(function()
                while autoInteractEnabled do
                    pcall(function()
                        local playerGui = player:FindFirstChild("PlayerGui")
                        if playerGui then
                            for _, object in ipairs(playerGui:GetDescendants()) do
                                if object:IsA("TextButton") or object:IsA("ImageButton") then
                                    local buttonText = ""
                                    if object:IsA("TextButton") then buttonText = object.Text end
                                    if string.find(buttonText, "拾取") or string.find(buttonText, "互动") or string.find(buttonText, "打开") or string.find(buttonText, "调查") then
                                        if object.Visible and object.Active then
                                            object:Click()
                                            task.wait(0.2)
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.3)
                end
            end)
        elseif not state and interactThread then
            task.cancel(interactThread)
            interactThread = nil
        end
    end
})

-- ================== 清理函数 ==================
_G.LootAttackCleanup = function()
    nearestEnabled = false
    aoeEnabled = false
    espEnabled = false
    autoInteractEnabled = false
    
    if attackThread then pcall(function() task.cancel(attackThread) end) attackThread = nil end
    if interactThread then pcall(function() task.cancel(interactThread) end) interactThread = nil end
    
    ClearESP()
    Camera.FieldOfView = originalFOV
    if gui then gui:Destroy() end
    if Window then pcall(function() Window:Destroy() end) end
    _G.LootAttackCleanup = nil
end
