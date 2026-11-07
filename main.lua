local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Camera = Workspace.CurrentCamera

local player = Players.LocalPlayer

-- ================== 高级加载动画 ==================
if CoreGui:FindFirstChild("PremiumLoadingScreen") then CoreGui.PremiumLoadingScreen:Destroy() end

local LoadingGui = Instance.new("ScreenGui")
LoadingGui.Name = "PremiumLoadingScreen"
LoadingGui.IgnoreGuiInset = true
LoadingGui.DisplayOrder = 9999
LoadingGui.Parent = CoreGui

-- 纯黑背景
local BgFrame = Instance.new("Frame", LoadingGui)
BgFrame.Size = UDim2.new(1, 0, 1, 0)
BgFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
BgFrame.BackgroundTransparency = 1
TweenService:Create(BgFrame, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()

-- 主容器
local Box = Instance.new("Frame", BgFrame)
Box.Size = UDim2.new(0, 260, 0, 100)
Box.Position = UDim2.new(0.5, -130, 0.5, -50)
Box.BackgroundTransparency = 1
Box.Parent = BgFrame

-- 标题（极简白字）
local Title = Instance.new("TextLabel", Box)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "L O A D I N G"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamMedium
Title.TextSize = 16
Title.TextTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Center
TweenService:Create(Title, TweenInfo.new(0.6), {TextTransparency = 0}):Play()

-- 进度条底槽
local BarBg = Instance.new("Frame", Box)
BarBg.Size = UDim2.new(0, 200, 0, 2)
BarBg.Position = UDim2.new(0.5, -100, 0, 60)
BarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
BarBg.BorderSizePixel = 0
Instance.new("UICorner", BarBg).CornerRadius = UDim.new(1, 0)

-- 进度条填色（带一点渐变流光）
local BarFill = Instance.new("Frame", BarBg)
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BarFill.BorderSizePixel = 0
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)

local FillGradient = Instance.new("UIGradient", BarFill)
FillGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 150, 150)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})

-- 进度条动画
TweenService:Create(BarFill, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    Size = UDim2.new(1, 0, 1, 0)
}):Play()

-- 底部小字
local SubTitle = Instance.new("TextLabel", Box)
SubTitle.Size = UDim2.new(1, 0, 0, 20)
SubTitle.Position = UDim2.new(0, 0, 0, 72)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Initializing modules..."
SubTitle.TextColor3 = Color3.fromRGB(120, 120, 130)
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 12
SubTitle.TextTransparency = 1
SubTitle.TextXAlignment = Enum.TextXAlignment.Center
TweenService:Create(SubTitle, TweenInfo.new(0.6), {TextTransparency = 0}):Play()

-- 等待进度条走完，淡出关闭
task.wait(2)
TweenService:Create(BgFrame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
TweenService:Create(Title, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
TweenService:Create(SubTitle, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
task.wait(0.4)
LoadingGui:Destroy()

-- ================== 加载 WindUI ==================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "布洛克斯战利品",
    Icon = "crosshair",
    Author = "自转锁怪版",
    Folder = "LootAttack",
    Size = UDim2.fromOffset(480, 400),
    Transparent = true,
    Theme = "Dark",
    NewElements = true,
})

local Tab = Window:Tab({ Title = "自转战斗", Icon = "shield" })

-- ================== 状态变量 ==================
local aimbotEnabled = false
local originalFOV = Camera.FieldOfView
local attackThread = nil
local spinSpeed = 80
local attackDelay = 0.001

-- ================== 屏幕正中心的圆形彩虹框 ==================
local gui = Instance.new("ScreenGui")
gui.Name = "CircleLockUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
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

local dot = Instance.new("Frame", circle)
dot.Size = UDim2.fromOffset(6, 6)
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.new(0.5, 0, 0.5, 0)
dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

-- 彩虹流光
task.spawn(function()
    local hue = 0
    while task.wait() do
        if circle.Visible then
            hue = (hue + 0.015) % 1
            stroke.Color = Color3.fromHSV(hue, 1, 1)
            dot.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        end
    end
end)

-- ================== 菜单设置 ==================
Tab:Toggle({
    Title = "开启自转打怪",
    Default = false,
    Callback = function(state)
        aimbotEnabled = state
        circle.Visible = state
        Camera.FieldOfView = state and 100 or originalFOV
        
        if state and not attackThread then
            attackThread = task.spawn(function()
                while aimbotEnabled do
                    local runtime = Workspace:FindFirstChild("Runtime")
                    local enemiesFolder = runtime and runtime:FindFirstChild("Enemies")
                    local actorsFolder = ReplicatedStorage:FindFirstChild("Runtime") and ReplicatedStorage.Runtime:FindFirstChild("Actors")
                    
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local tool = char and char:FindFirstChildWhichIsA("Tool")
                    
                    if enemiesFolder and actorsFolder and hrp and tool then
                        local actorId = tool:FindFirstChild("ActorId")
                        local actor = actorId and actorsFolder:FindFirstChild(actorId.Value)
                        local remote = actor and actor:FindFirstChild("Functions") and actor.Functions:FindFirstChild("Attack")
                        
                        if remote then
                            local nearest, minDist = nil, math.huge
                            for _, model in ipairs(enemiesFolder:GetChildren()) do
                                local hum = model:FindFirstChildOfClass("Humanoid")
                                local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart")
                                if hum and hum.Health > 0 and root then
                                    local dist = (root.Position - hrp.Position).Magnitude
                                    if dist < minDist then
                                        nearest, minDist = model, dist
                                    end
                                end
                            end
                            
                            if nearest then
                                local targetRoot = nearest:FindFirstChild("HumanoidRootPart") or nearest:FindFirstChild("RootPart")
                                if targetRoot then
                                    -- 贴脸
                                    local dest = targetRoot.Position - targetRoot.CFrame.LookVector * 1.5
                                    
                                    -- 人物自转
                                    local spinAngle = math.rad(tick() * spinSpeed)
                                    hrp.CFrame = CFrame.new(dest) * CFrame.Angles(0, spinAngle, 0)
                                    
                                    -- 镜头死锁怪物（不跟着人转）
                                    local camPos = dest + Vector3.new(0, 8, 0) - targetRoot.CFrame.LookVector * 6
                                    Camera.CFrame = CFrame.lookAt(camPos, targetRoot.Position)
                                    
                                    -- 清空速度
                                    hrp.AssemblyLinearVelocity = Vector3.zero
                                    hrp.AssemblyAngularVelocity = Vector3.zero
                                    
                                    -- 极速发包
                                    pcall(function()
                                        remote:InvokeServer()
                                    end)
                                end
                            end
                        end
                    end
                    task.wait(attackDelay)
                end
            end)
        elseif not state and attackThread then
            task.cancel(attackThread)
            attackThread = nil
        end
    end
})

Tab:Slider({
    Title = "人物自转速度",
    Value = { Min = 10, Max = 150, Default = 80 },
    Increment = 5,
    Callback = function(value) spinSpeed = value end
})

Tab:Slider({
    Title = "攻击间隔 (秒)",
    Value = { Min = 0.001, Max = 0.1, Default = 0.001 },
    Increment = 0.001,
    Callback = function(value) attackDelay = value end
})

-- ================== 清理函数 ==================
_G.LootAttackCleanup = function()
    aimbotEnabled = false
    if attackThread then task.cancel(attackThread) end
    Camera.FieldOfView = originalFOV
    if gui then gui:Destroy() end
    _G.LootAttackCleanup = nil
end
