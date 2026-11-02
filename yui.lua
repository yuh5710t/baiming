-- =====================================================================
-- 索尼克中心 [第一段]：究极排面公告 + 白名单
-- =====================================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- 1. 白名单校验
local WhiteList = {["yuh5710t"] = true}
if not WhiteList[LocalPlayer.Name] then
    LocalPlayer:Kick("【安全拦截】\n您不在索尼克中心的授权名单中。\n请联系管理员 (李佳)。")
    return
end

-- 2. 创建排面公告 UI
local NoticeGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
NoticeGui.DisplayOrder = 9999
NoticeGui.IgnoreGuiInset = true

-- 全屏黑色遮罩
local Overlay = Instance.new("Frame", NoticeGui)
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
Overlay.BackgroundTransparency = 0.1
Overlay.BorderSizePixel = 0

-- 超大主面板 (宽600，高320)
local Frame = Instance.new("Frame", Overlay)
Frame.Size = UDim2.new(0, 600, 0, 320)
Frame.Position = UDim2.new(0.5, -300, 0.5, -160)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Frame.BorderSizePixel = 0
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)

local FrameStroke = Instance.new("UIStroke", Frame)
FrameStroke.Color = Color3.fromRGB(218, 165, 32) -- 亮金边
FrameStroke.Thickness = 3

-- 顶部装饰线
local TopLine = Instance.new("Frame", Frame)
TopLine.Size = UDim2.new(0.9, 0, 0, 3)
TopLine.Position = UDim2.new(0.05, 0, 0, 60)
TopLine.BackgroundColor3 = Color3.fromRGB(218, 165, 32)
TopLine.BorderSizePixel = 0

-- 大标题
local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 50)
Title.Position = UDim2.new(0, 0, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "索尼克中心 - 核心注入成功"
Title.TextColor3 = Color3.fromRGB(218, 165, 32)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 26

-- 身份信息
local Sub = Instance.new("TextLabel", Frame)
Sub.Size = UDim2.new(1, -60, 0, 30)
Sub.Position = UDim2.new(0, 30, 0, 80)
Sub.BackgroundTransparency = 1
Sub.Text = "当前账户: " .. LocalPlayer.Name .. "   |   权限等级: 超级管理员 (白名单已授权)"
Sub.TextColor3 = Color3.fromRGB(240, 240, 240)
Sub.Font = Enum.Font.GothamBold
Sub.TextSize = 16
Sub.TextXAlignment = Enum.TextXAlignment.Left

-- 大字内容文本
local Content = Instance.new("TextLabel", Frame)
Content.Size = UDim2.new(1, -60, 0, 80)
Content.Position = UDim2.new(0, 30, 0, 130)
Content.BackgroundTransparency = 1
Content.Text = "底层引擎已接管服务器物理与渲染逻辑。\n请点击下方按钮进入主控台，选择你需要运行的模块。"
Content.TextColor3 = Color3.fromRGB(200, 200, 200)
Content.Font = Enum.Font.GothamMedium
Content.TextSize = 18
Content.TextXAlignment = Enum.TextXAlignment.Left

-- 确认按钮
local ConfirmBtn = Instance.new("TextButton", Frame)
ConfirmBtn.Size = UDim2.new(0, 260, 0, 55)
ConfirmBtn.Position = UDim2.new(0.5, -130, 1, -80)
ConfirmBtn.BackgroundColor3 = Color3.fromRGB(218, 165, 32)
ConfirmBtn.Text = "确认并进入主控台"
ConfirmBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
ConfirmBtn.Font = Enum.Font.GothamBlack
ConfirmBtn.TextSize = 18
Instance.new("UICorner", ConfirmBtn).CornerRadius = UDim.new(0, 8)

-- 3. 点击确认后的动画
ConfirmBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Overlay, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    TweenService:Create(Frame, TweenInfo.new(0.4), {BackgroundTransparency = 1, Size = UDim2.new(0, 500, 0, 250), Position = UDim2.new(0.5, -250, 0.5, -125)}):Play()
    task.wait(0.45)
    NoticeGui:Destroy()
    _G.SonicAuthorized = true -- 通知第二段可以运行
end)-- =====================================================================
-- 索尼克中心 [第二段]：主控台与模块加载
-- =====================================================================
if not _G.SonicAuthorized then return end

local LocalPlayer = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")

-- 1. 主框架
local MainGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
MainGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", MainGui)
MainFrame.Size = UDim2.new(0, 700, 0, 450)
MainFrame.Position = UDim2.new(0.5, -350, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22) 
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(60, 60, 65)
MainStroke.Thickness = 1.5

-- 2. 左侧导航栏
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 200, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 15) 
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)

local NavTitle = Instance.new("TextLabel", Sidebar)
NavTitle.Size = UDim2.new(1, 0, 0, 70)
NavTitle.BackgroundTransparency = 1
NavTitle.Text = "索尼克中心"
NavTitle.TextColor3 = Color3.fromRGB(218, 165, 32)
NavTitle.Font = Enum.Font.GothamBold
NavTitle.TextSize = 22

-- 3. 右侧内容区
local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Size = UDim2.new(1, -220, 1, -40)
ContentArea.Position = UDim2.new(0, 210, 0, 20)
ContentArea.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Instance.new("UICorner", ContentArea).CornerRadius = UDim.new(0, 10)

-- 关闭按钮
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -45, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
CloseBtn.MouseButton1Click:Connect(function() MainGui:Destroy() end)

-- 4. 页面容器
local Page1 = Instance.new("Frame", ContentArea)
Page1.Size = UDim2.new(1, 0, 1, 0)
Page1.BackgroundTransparency = 1
Page1.Visible = true

local Page2 = Instance.new("Frame", ContentArea)
Page2.Size = UDim2.new(1, 0, 1, 0)
Page2.BackgroundTransparency = 1
Page2.Visible = false

-- 5. 填充脚本外链按钮
local function CreateLinkBtn(text, url, yPos)
    local btn = Instance.new("TextButton", Page1)
    btn.Size = UDim2.new(0.9, 0, 0, 70)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(function()
        btn.Text = "正在加载模块..."
        task.spawn(function()
            local success = pcall(function() loadstring(game:HttpGet(url))() end)
            btn.Text = success and text or "加载失败"
            task.wait(2)
            btn.Text = text
        end)
    end)
end
CreateLinkBtn("🚀 加载 造船寻宝", "https://raw.githubusercontent.com/yuh5710t/zhao/main/miao.lua", 40)
CreateLinkBtn("⚔️ 加载 破坏者谜团2", "https://raw.githubusercontent.com/yuh5710t/miake/main/miao.lua", 130)

-- 6. 填充关于页
local AboutTitle = Instance.new("TextLabel", Page2)
AboutTitle.Size = UDim2.new(1, 0, 0, 80)
AboutTitle.BackgroundTransparency = 1
AboutTitle.Text = "索尼克中心 - 系统信息"
AboutTitle.TextColor3 = Color3.fromRGB(218, 165, 32)
AboutTitle.Font = Enum.Font.GothamBold
AboutTitle.TextSize = 28
AboutTitle.Position = UDim2.new(0, 0, 0, 40)

local AboutText = Instance.new("TextLabel", Page2)
AboutText.Size = UDim2.new(1, -60, 0, 200)
AboutText.Position = UDim2.new(0, 30, 0, 120)
AboutText.BackgroundTransparency = 1
AboutText.Text = "主理人：李佳\n\n本控制台采用底层白名单加密校验。\n所有加载均直接调用 GitHub 核心源文件。\n点击左侧导航切换功能。"
AboutText.TextColor3 = Color3.fromRGB(180, 180, 180)
AboutText.Font = Enum.Font.Gotham
AboutText.TextSize = 16
AboutText.TextXAlignment = Enum.TextXAlignment.Left

-- 7. 导航切换逻辑
local function CreateTabBtn(text, yPos, pageFrame)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(0.9, 0, 0, 50)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 16
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(function()
        for _, child in ipairs(Sidebar:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                child.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        Page1.Visible = false
        Page2.Visible = false
        pageFrame.Visible = true
    end)
end

CreateTabBtn("📁 脚本仓库", 80, Page1)
CreateTabBtn("ℹ️ 系统信息", 140, Page2)

-- 8. 主框架拖拽逻辑
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end
end)
