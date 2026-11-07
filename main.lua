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
    Title = "更新公告",
    Content = "【卓越级优化更新】\n1. 透视新增：头顶引线（天线）与实时距离\n2. 修复了瞬移导致模型消失的 Bug\n3. 增加武器物理锁定，绝不掉刀\n4. 优化 AOE 假伤判定",
    Buttons = {
        { Title = "确定", Callback = function() dialogClosed = true end }
    }
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
local attackDelay = 0.02
local aoeRange = 40

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
            hue = (hue + 0.05) % 1
            stroke.Color = Color3.fromHSV(hue, 1, 1)
        end
        task.wait()
    end
end)

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
                
                if character and not tool then
                    local backpack = player:FindFirstChild("Backpack")
                    if backpack then
                        local newTool = backpack:FindFirstChildWhichIsA("Tool")
                        if newTool then
                            newTool.Parent = character
                            tool = newTool
                        end
                    end
                end

                if enemiesFolder and actorsFolder and hrp and tool then
                    local actorId = tool:FindFirstChild("ActorId")
                    local actor = actorId and actorsFolder:FindFirstChild(actorId.Value)
                    local remoteFunction = actor and actor:FindFirstChild("Functions") and actor.Functions:FindFirstChild("Attack")
                    
                    local handle = tool:FindFirstChild("Handle")
                    if handle and handle:IsA("BasePart") then
                        handle.CanCollide = false
                        handle.Massless = true
                    end

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
                            local targetHum = targetRoot.Parent and targetRoot.Parent:FindFirstChildOfClass("Humanoid")
                            if targetHum and targetHum.Health > 0 then
                                local dest = targetRoot.Position - (targetRoot.CFrame.LookVector * 1.5)
                                local spinAngle = math.rad(tick() * spinSpeed)
                                
                                hrp.CFrame = CFrame.new(dest, targetRoot.Position) * CFrame.Angles(0, spinAngle, 0)
                                hrp.AssemblyLinearVelocity = Vector3.zero
                                hrp.AssemblyAngularVelocity = Vector3.zero
                                
                                if handle then
                                    handle.AssemblyLinearVelocity = Vector3.zero
                                    handle.AssemblyAngularVelocity = Vector3.zero
                                end
                                
                                Camera.CFrame = CFrame.lookAt(hrp.Position + Vector3.new(0, 6, 0) - targetRoot.CFrame.LookVector * 5, targetRoot.Position)
                                
                                pcall(function() remoteFunction:InvokeServer() end)
                                task.wait(attackDelay)
                            end
                        end
                    end
                end
            end)
            RunService.Heartbeat:Wait()
        end
        circle.Visible = false
        Camera.FieldOfView = originalFOV
        attackThread = nil
    end)
end

TabCombat:Toggle({ Title = "贴身打怪", Default = false, Callback = function(state) nearestEnabled = state if state then StartAttackThread() end end })
TabCombat:Toggle({ Title = "范围AOE", Default = false, Callback = function(state) aoeEnabled = state if state then StartAttackThread() end end })
TabCombat:Slider({ Title = "转速", Value = { Min = 10, Max = 500, Default = 150 }, Increment = 10, Callback = function(value) spinSpeed = value end })
TabCombat:Slider({ Title = "攻击间隔", Value = { Min = 0.01, Max = 0.2, Default = 0.02 }, Increment = 0.01, Callback = function(value) attackDelay = value end })
TabCombat:Slider({ Title = "AOE范围", Value = { Min = 10, Max = 150, Default = 40 }, Increment = 5, Callback = function(value) aoeRange = value end })-- ================== 卓越级 2D 天线透视模块 ==================
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
    billboard.Size = UDim2.new(4, 0, 5.5, 0) -- 方框大小
    billboard.StudsOffset = Vector3.new(0, 0.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = targetCharacter
    
    -- 2D方框
    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    local uiStroke = Instance.new("UIStroke", frame)
    uiStroke.Color = Color3.fromRGB(255, 50, 50)
    uiStroke.Thickness = 1.5

    -- 天线引线
    local line = Instance.new("Frame", billboard)
    line.Size = UDim2.new(0, 1, 0, 30)
    line.Position = UDim2.new(0.5, 0, 0, -30)
    line.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    line.BorderSizePixel = 0

    -- 头顶文字 (名字/血量/距离)
    local textGui = Instance.new("BillboardGui")
    textGui.Name = "TextESP"
    textGui.Adornee = head
    textGui.Size = UDim2.new(0, 200, 0, 50)
    textGui.StudsOffset = Vector3.new(0, 2.5, 0)
    textGui.AlwaysOnTop = true
    textGui.Parent = targetCharacter

    local nameTag = Instance.new("TextLabel", textGui)
    nameTag.Size = UDim2.new(1, 0, 1, 0)
    nameTag.BackgroundTransparency = 1
    nameTag.TextColor3 = Color3.fromRGB(255, 50, 50)
    nameTag.TextStrokeTransparency = 0.5
    nameTag.TextSize = 13
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
                    
                    -- 实时更新距离和血量
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
                                        label.Text = string.format("<font color='#00FF00'>[%d m]</font> %s [<font color='#FF3333'>%d HP</font>]", dist, char.Name, hp)
                                    end
                                end
                            end
                        end)
                    end
                    task.wait(0.1)
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
