local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- ================== 白名单 ==================
local WHITELIST = {
	["wswswsdddxf"] = true,
	["yuh5710t"] = true,
}

if not WHITELIST[player.Name] then
	warn("[传送攻击] 你不是白名单用户，脚本已停止。")
	return
end
-- ============================================

local enemies = Workspace:WaitForChild("Runtime"):WaitForChild("Enemies")
local actors = ReplicatedStorage:WaitForChild("Runtime"):WaitForChild("Actors")

-- nil = 攻击全部怪物；只打指定怪可改为：{ ["1_1_5"] = true }
local TARGET_NAMES = nil
local ATTACK_DISTANCE = 4

if _G.TeleportAttackCleanup then
	pcall(_G.TeleportAttackCleanup)
end

local enabled = false
local closed = false
local currentTarget = nil
local connections = {}

local oldGui = CoreGui:FindFirstChild("TeleportAttackGui")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "TeleportAttackGui"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(310, 155)
main.Position = UDim2.new(0.5, -155, 0.35, 0)
main.BackgroundColor3 = Color3.fromRGB(24, 26, 31)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 35)
title.Position = UDim2.fromOffset(10, 5)
title.BackgroundTransparency = 1
title.Text = "传送攻击"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, -20, 0, 25)
targetLabel.Position = UDim2.fromOffset(10, 42)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "目标：无"
targetLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
targetLabel.TextSize = 14
targetLabel.Font = Enum.Font.Gotham
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = main

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.fromOffset(10, 68)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "状态：已停止"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = main

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 40)
toggleButton.Position = UDim2.fromOffset(10, 103)
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 160, 90)
toggleButton.Text = "开始"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 17
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = main

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = toggleButton

local function setStatus(text)
	statusLabel.Text = "状态：" .. text
end

local function getRootPart(model)
	if not model then
		return nil
	end
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	return model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("RootPart")
		or model:FindFirstChildWhichIsA("BasePart")
end

local function isAlive(model)
	if not model or not model.Parent or not model:IsA("Model") then
		return false
	end
	if TARGET_NAMES and not TARGET_NAMES[model.Name] then
		return false
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health > 0 and getRootPart(model) ~= nil
end

local function getCharacterRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function findNearestTarget()
	local characterRoot = getCharacterRoot()
	if not characterRoot then
		return nil
	end

	local nearest = nil
	local nearestDistance = math.huge

	for _, model in ipairs(enemies:GetChildren()) do
		if isAlive(model) then
			local rootPart = getRootPart(model)
			local distance = (rootPart.Position - characterRoot.Position).Magnitude
			if distance < nearestDistance then
				nearest = model
				nearestDistance = distance
			end
		end
	end

	return nearest
end

local function getAttackRemote()
	local character = player.Character
	local tool = character and character:FindFirstChildWhichIsA("Tool")
	if not tool then
		return nil, "请先装备武器"
	end

	local actorId = tool:FindFirstChild("ActorId")
	if not actorId then
		return nil, "当前武器缺少 ActorId"
	end

	local actor = actors:FindFirstChild(actorId.Value)
	local functions = actor and actor:FindFirstChild("Functions")
	local remote = functions and functions:FindFirstChild("Attack")

	if remote and remote:IsA("RemoteFunction") then
		return remote
	end

	return nil, "正在等待武器 Attack"
end

table.insert(connections, RunService.Heartbeat:Connect(function()
	if not enabled then
		return
	end

	local characterRoot = getCharacterRoot()
	if not characterRoot then
		setStatus("等待角色加载")
		return
	end

	if not isAlive(currentTarget) then
		currentTarget = findNearestTarget()
	end

	if not currentTarget then
		targetLabel.Text = "目标：无"
		setStatus("没有找到存活怪物")
		return
	end

	local targetRoot = getRootPart(currentTarget)
	local destination = targetRoot.Position - targetRoot.CFrame.LookVector * ATTACK_DISTANCE

	characterRoot.CFrame = CFrame.lookAt(destination, targetRoot.Position)
	characterRoot.AssemblyLinearVelocity = Vector3.zero
	characterRoot.AssemblyAngularVelocity = Vector3.zero

	local humanoid = currentTarget:FindFirstChildOfClass("Humanoid")
	targetLabel.Text = string.format(
		"目标：%s  %.0f/%.0f",
		currentTarget.Name,
		humanoid.Health,
		humanoid.MaxHealth
	)
end))

table.insert(connections, toggleButton.MouseButton1Click:Connect(function()
	enabled = not enabled
	currentTarget = nil

	if enabled then
		toggleButton.Text = "停止"
		toggleButton.BackgroundColor3 = Color3.fromRGB(200, 65, 65)
		setStatus("运行中")
	else
		toggleButton.Text = "开始"
		toggleButton.BackgroundColor3 = Color3.fromRGB(40, 160, 90)
		targetLabel.Text = "目标：无"
		setStatus("已停止")
	end
end))

table.insert(connections, player.CharacterAdded:Connect(function()
	currentTarget = nil
end))

task.spawn(function()
	while not closed do
		if enabled and isAlive(currentTarget) then
			local remote, err = getAttackRemote()
			if remote then
				-- 每帧异步攻击，不等待上一次 InvokeServer 返回
				task.spawn(function()
					local ok, invokeError = pcall(function()
						remote:InvokeServer()
					end)
					if ok then
						setStatus("最大速度传送攻击中")
					else
						setStatus("攻击调用失败：" .. tostring(invokeError))
					end
				end)
			else
				setStatus(err)
			end
		end

		RunService.Heartbeat:Wait()
	end
end)

_G.TeleportAttackCleanup = function()
	closed = true
	enabled = false
	currentTarget = nil
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	gui:Destroy()
	if _G.TeleportAttackCleanup then
		_G.TeleportAttackCleanup = nil
	end
end
