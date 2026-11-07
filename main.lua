local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local player = Players.LocalPlayer

-- 如果之前开启过，清理一下旧界面
if _G.LootAttackCleanup then pcall(_G.LootAttackCleanup) end

-- ================== 加载 WindUI 库 ==================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- 用 WindUI 自带的精美公告弹窗，不做手写弹窗
WindUI:Notify({
    Title = "更新与玩法公告",
    Content = "【更新内容】\n1. 新增 AOE 范围全屏真伤打怪（测试中）\n2. 新增 3D/2D 人物透视\n3. 新增自动互动 UI 模块\n\n【玩法介绍】\n打开 AOE 战斗后，会贴脸轮流切死范围内的怪。如果觉得有假伤，请调高攻击结算间隔。",
    Duration = 10,
    Icon = "info",
})

-- ================== 创建主窗口 ==================
local Window = WindUI:CreateWindow({
    Title = "布洛克斯战利品",
    Icon = "crosshair",
    Author = "索尼",
    Folder = "LootAttack",
    Size = UDim2.fromOffset(480, 400),
    Transparent = true,
    Theme = "Dark",
    NewElements = true,
})

-- 创建三个标签页
local TabCombat = Window:Tab({ Title = "AOE战斗", Icon = "shield" })
local TabVisual = Window:Tab({ Title = "视觉透视", Icon = "eye" })
local TabAssist = Window:Tab({ Title = "辅助功能", Icon = "star" })

-- ================== 核心状态变量 ==================
local aimbotEnabled = false
local espEnabled = false
local autoInteractEnabled = false
local originalFOV = Camera.FieldOfView
local attackThread = nil
local interactThread = nil
local espMode = "3D"
local spinSpeed = 100
local attackDelay = 0.05 
local aoeRange = 40

-- ================== 屏幕正中心彩虹框 ==================
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

-- 彩虹流光动画线程
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

-- ================== AOE 战斗模块 ==================
TabCombat:Toggle({
    Title = "开启范围AOE打怪 (真伤防假)",
    Default = false,
    Callback = function(state)
        aimbotEnabled = state
        circle.Visible = state
        Camera.FieldOfView = state and 100 or originalFOV
        
        if state and not attackThread then
            attackThread = task.spawn(function()
                while aimbotEnabled do
                    pcall(function()
                        local enemiesFolder = Workspace:FindFirstChild("Runtime") and Workspace.Runtime:FindFirstChild("Enemies")
                        local actorsFolder = ReplicatedStorage:FindFirstChild("Runtime") and ReplicatedStorage.Runtime:FindFirstChild("Actors")
                        local character = player.Character
                        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                        local tool = character and character:FindFirstChildWhichIsA("Tool")
                        
                        if enemiesFolder and actorsFolder and humanoidRootPart and tool then
                            local actorId = tool:FindFirstChild("ActorId")
                            local actor = actorId and actorsFolder:FindFirstChild(actorId.Value)
                            local remoteFunction = actor and actor:FindFirstChild("Functions") and actor.Functions:FindFirstChild("Attack")
                            
                            if remoteFunction then
                                -- 收集范围内所有怪物
                                local targets = {}
                                for _, model in ipairs(enemiesFolder:GetChildren()) do
                                    local humanoid = model:FindFirstChildOfClass("Humanoid")
                                    local rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart")
                                    if humanoid and humanoid.Health > 0 and rootPart then
                                        local distance = (rootPart.Position - humanoidRootPart.Position).Magnitude
                                        if distance <= aoeRange then
                                            table.insert(targets, rootPart)
                                        end
                                    end
                                end
                                
                                -- 贴脸轮流打
                                if #targets > 0 then
                                    for _, targetRoot in ipairs(targets) do
                                        if not aimbotEnabled then break end
                                        
                                        -- 强制贴脸1.5距离
                                        local destination = targetRoot.Position - targetRoot.CFrame.LookVector * 1.5
                                        humanoidRootPart.CFrame = CFrame.new(destination) * CFrame.Angles(0, math.rad(tick() * spinSpeed), 0)
                                        
                                        -- 镜头锁定
                                        local cameraPos = humanoidRootPart.Position + Vector3.new(0, 6, 0) - targetRoot.CFrame.LookVector * 5
                                        Camera.CFrame = CFrame.lookAt(cameraPos, targetRoot.Position)
                                        
                                        -- 清空速度防抖
                                        humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                                        humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                                        
                                        -- 发包攻击
                                        pcall(function() remoteFunction:InvokeServer() end)
                                        
                                        -- 等服务器结算，防假伤
                                        task.wait(attackDelay)
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.01)
                end
            end)
        elseif not state and attackThread then
            task.cancel(attackThread)
            attackThread = nil
            Camera.FieldOfView = originalFOV
        end
    end
})

TabCombat:Slider({ Title = "自转速度", Value = { Min = 10, Max = 200, Default = 100 }, Increment = 5, Callback = function(value) spinSpeed = value end })
TabCombat:Slider({ Title = "攻击结算间隔 (防假伤)", Value = { Min = 0.01, Max = 0.2, Default = 0.05 }, Increment = 0.01, Callback = function(value) attackDelay = value end })
TabCombat:Slider({ Title = "AOE范围 (米)", Value = { Min = 10, Max = 150, Default = 40 }, Increment = 5, Callback = function(value) aoeRange = value end })-- ================== 视觉透视模块 ==================
local espObjects = {}
local function ClearESP()
    for _, object in pairs(espObjects) do
        if object and object.Parent then
            object:Destroy()
        end
    end
    espObjects = {}
end

local function CreateESP(targetCharacter)
    if not targetCharacter then return end
    local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    local rootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart or humanoid.Health <= 0 then return end
    
    local color = Color3.fromRGB(255, 50, 50)

    if espMode == "3D" then
        local highlight = Instance.new("Highlight")
        highlight.Name = "BonesESP"
        highlight.Adornee = targetCharacter
        highlight.FillColor = color
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = targetCharacter
        table.insert(espObjects, highlight)
    elseif espMode == "2D" then
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
        nameTag.Text = targetCharacter.Name
        nameTag.TextColor3 = color
        nameTag.TextStrokeTransparency = 0.5
        nameTag.TextSize = 12
        nameTag.Font = Enum.Font.GothamBold

        table.insert(espObjects, billboard)
    end
end

TabVisual:Toggle({
    Title = "开启人物透视 (3D/2D)",
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
                                if object.Adornee == otherPlayer.Character or object.Parent == otherPlayer.Character then
                                    hasESP = true
                                    break
                                end
                            end
                            if not hasESP then
                                CreateESP(otherPlayer.Character)
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        else
            ClearESP()
        end
    end
})

TabVisual:Dropdown({
    Title = "透视模式",
    Values = { "3D 骨骼高亮", "2D 方框" },
    Default = "3D 骨骼高亮",
    Callback = function(selected)
        if selected == "3D 骨骼高亮" then
            espMode = "3D"
        else
            espMode = "2D"
        end
        ClearESP() -- 切换模式时清空旧的
    end
})

-- ================== 自动互动 UI 模块 ==================
TabAssist:Toggle({
    Title = "开启自动点击互动UI",
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
                                    if object:IsA("TextButton") then
                                        buttonText = object.Text
                                    end
                                    -- 检测常见互动词汇
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

-- ================== 脚本清理函数 ==================
_G.LootAttackCleanup = function()
    aimbotEnabled = false
    espEnabled = false
    autoInteractEnabled = false
    
    if attackThread then 
        pcall(function() task.cancel(attackThread) end) 
        attackThread = nil 
    end
    if interactThread then 
        pcall(function() task.cancel(interactThread) end) 
        interactThread = nil 
    end
    
    ClearESP()
    Camera.FieldOfView = originalFOV
    
    if gui then gui:Destroy() end
    if Window then pcall(function() Window:Destroy() end) end
    
    _G.LootAttackCleanup = nil
end
