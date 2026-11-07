local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local player = Players.LocalPlayer

if _G.LootAttackCleanup then pcall(_G.LootAttackCleanup) end

-- ================== 加载 WindUI ==================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- UI 名字直接精简为“布洛克斯”和“索尼”
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

-- ================== 强制更新公告 ==================
local dialogClosed = false
Window:Dialog({
    Title = "更新公告",
    Content = "【更新内容】\n1. AOE 范围全屏打怪\n2. 贴身模式：杀一只换一只\n3. 2D 方框透视（带血量）\n4. 自动互动UI",
    Buttons = {
        {
            Title = "确定",
            Callback = function()
                dialogClosed = true
            end
        }
    }
})

-- 阻塞线程，必须点确定才能往下走
repeat task.wait(0.1) until dialogClosed

-- ================== 标签页 ==================
local TabCombat = Window:Tab({ Title = "战斗", Icon = "shield" })
local TabVisual = Window:Tab({ Title = "透视", Icon = "eye" })
local TabAssist = Window:Tab({ Title = "辅助", Icon = "star" })

-- 状态变量
local nearestEnabled = false
local aoeEnabled = false
local espEnabled = false
local autoInteractEnabled = false
local originalFOV = Camera.FieldOfView
local attackThread = nil
local interactThread = nil
local spinSpeed = 100
local attackDelay = 0.05 
local aoeRange = 40

-- 屏幕中心彩框
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui
local circle = Instance.new("Frame", gui)
circle.Size = UDim2.fromOffset(200, 200)
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.new(0.5, 0, 0.5, 0)
circle.BackgroundTransparency = 1
circle.Visible = false
Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke", circle)
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(255, 0, 0)

task.spawn(function()
    local hue = 0
    while gui.Parent do
        if circle.Visible then
            hue = (hue + 0.02) % 1
            stroke.Color = Color3.fromHSV(hue, 1, 1)
        end
        task.wait()
    end
end)

-- ================== 核心战斗线程 ==================
local function StartAttackThread()
    if attackThread then return end
    circle.Visible = true
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
                    
                    if remoteFunction then
                        local targets = {}
                        for _, model in ipairs(enemiesFolder:GetChildren()) do
                            local humanoid = model:FindFirstChildOfClass("Humanoid")
                            local rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart")
                            if humanoid and humanoid.Health > 0 and rootPart then
                                local distance = (rootPart.Position - hrp.Position).Magnitude
                                if nearestEnabled or (aoeEnabled and distance <= aoeRange) then
                                    table.insert(targets, rootPart)
                                end
                            end
                        end
                        
                        if nearestEnabled and #targets > 0 then
                            table.sort(targets, function(a, b)
                                return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
                            end)
                        end

                        for _, targetRoot in ipairs(targets) do
                            if not nearestEnabled and not aoeEnabled then break end
                            local targetModel = targetRoot.Parent
                            local targetHum = targetModel and targetModel:FindFirstChildOfClass("Humanoid")
                            if targetHum and targetHum.Health > 0 then
                                local destination = targetRoot.Position - targetRoot.CFrame.LookVector * 1.5
                                hrp.CFrame = CFrame.new(destination) * CFrame.Angles(0, math.rad(tick() * spinSpeed), 0)
                                local cameraPos = hrp.Position + Vector3.new(0, 6, 0) - targetRoot.CFrame.LookVector * 5
                                Camera.CFrame = CFrame.lookAt(cameraPos, targetRoot.Position)
                                hrp.AssemblyLinearVelocity = Vector3.zero
                                hrp.AssemblyAngularVelocity = Vector3.zero
                                pcall(function() remoteFunction:InvokeServer() end)
                                task.wait(attackDelay)
                            end
                        end
                    end
                end
            end)
            task.wait(0.01)
        end
        circle.Visible = false
        Camera.FieldOfView = originalFOV
        attackThread = nil
    end)
end

TabCombat:Toggle({
    Title = "贴身打怪",
    Default = false,
    Callback = function(state)
        nearestEnabled = state
        if state then StartAttackThread() end
    end
})

TabCombat:Toggle({
    Title = "范围AOE",
    Default = false,
    Callback = function(state)
        aoeEnabled = state
        if state then StartAttackThread() end
    end
})

TabCombat:Slider({ Title = "转速", Value = { Min = 10, Max = 200, Default = 100 }, Increment = 5, Callback = function(value) spinSpeed = value end })
TabCombat:Slider({ Title = "攻击间隔", Value = { Min = 0.01, Max = 0.2, Default = 0.05 }, Increment = 0.01, Callback = function(value) attackDelay = value end })
TabCombat:Slider({ Title = "AOE范围", Value = { Min = 10, Max = 150, Default = 40 }, Increment = 5, Callback = function(value) aoeRange = value end })-- ================== 2D 纯方框透视模块 ==================
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
    if not humanoid or not rootPart or humanoid.Health <= 0 then return end
    
    local color = Color3.fromRGB(255, 50, 50)

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
    uiStroke.Color = color
    uiStroke.Thickness = 1.5

    local nameTag = Instance.new("TextLabel", billboard)
    nameTag.Size = UDim2.new(1, 0, 0, 20)
    nameTag.Position = UDim2.new(0, 0, 1, 5)
    nameTag.BackgroundTransparency = 1
    nameTag.Text = targetCharacter.Name .. " [" .. math.floor(humanoid.Health) .. " HP]"
    nameTag.TextColor3 = color
    nameTag.TextStrokeTransparency = 0.5
    nameTag.TextSize = 12
    nameTag.Font = Enum.Font.GothamBold

    table.insert(espObjects, billboard)
end

TabVisual:Toggle({
    Title = "2D透视",
    Default = false,
    Callback = function(state)
        espEnabled = state
        if state then
            task.spawn(function()
                while espEnabled do
                    for _, otherPlayer in ipairs(Players:GetPlayers()) do
                        if otherPlayer ~= player and otherPlayer.Character then
                            local hasESP = false
                            for _, object in pairs(espObjects) do
                                if object.Adornee == otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                    hasESP = true
                                    break
                                end
                            end
                            if not hasESP then CreateESP(otherPlayer.Character) end
                        end
                    end
                    for _, object in pairs(espObjects) do
                        pcall(function()
                            local char = object.Adornee and object.Adornee.Parent
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            if hum then
                                local nameTag = object:FindFirstChildOfClass("TextLabel")
                                if nameTag then nameTag.Text = char.Name .. " [" .. math.floor(hum.Health) .. " HP]" end
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

-- ================== 自动互动 UI 模块 ==================
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
                                    if string.find(buttonText, "拾取") or string.find(buttonText, "互动") or string.find(buttonText, "打开") or string.find(buttonText, "调查") or string.find(buttonText, "开启") then
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
