--!nonstrict
-- COMBOWICK — Script Selector GUI
-- Small, draggable, mobile-friendly, rounded picker. Given a list of scripts the
-- user can run, it auto-loads when there's exactly one, or shows a button per
-- script when there are two or more. Load it and call:
--
--   local Selector = loadstring(game:HttpGet("<this file raw url>"))()
--   Selector.show(scripts)   -- scripts = { {name="Autofarm", url="https://..."}, {name="Spawner", url="https://..."} }
--
-- Returns a table with .show(scripts, opts).

local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local function safeParent(gui)
	-- Prefer CoreGui (survives respawn / hidden from most anti-cheat). Fall back to PlayerGui.
	local ok = pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui) end
		if gethui then gui.Parent = gethui() else gui.Parent = game:GetService("CoreGui") end
	end)
	if not ok or not gui.Parent then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
end

local function runScript(url)
	task.spawn(function()
		local ok, src = pcall(function() return game:HttpGet(url, true) end)
		if not ok or type(src) ~= "string" then return end
		local fn, err = loadstring(src)
		if fn then pcall(fn) end
	end)
end

local function makeDraggable(frame, handle)
	handle = handle or frame
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInput.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local Selector = {}

function Selector.show(scripts, opts)
	opts = opts or {}
	scripts = scripts or {}

	-- normalize
	local list = {}
	for _, s in ipairs(scripts) do
		if s and s.url and s.url ~= "" then
			table.insert(list, { name = tostring(s.name or "Script"), url = tostring(s.url) })
		end
	end
	if #list == 0 then return end

	-- exactly one → just run it, no GUI
	if #list == 1 then
		runScript(list[1].url)
		return
	end

	-- build the picker
	local gui = Instance.new("ScreenGui")
	gui.Name = "CW_Selector"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true

	local frame = Instance.new("Frame")
	frame.Name = "Main"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.42)
	frame.Size = UDim2.fromOffset(230, 0) -- height auto-sized below
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(52, 211, 153) -- emerald accent
	stroke.Thickness = 1
	stroke.Transparency = 0.35
	stroke.Parent = frame

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	-- header (drag handle)
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 22)
	header.BackgroundTransparency = 1
	header.LayoutOrder = 0
	header.Parent = frame

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -24, 1, 0)
	title.Position = UDim2.fromOffset(0, 0)
	title.Font = Enum.Font.GothamBold
	title.Text = opts.title or "COMBOWICK"
	title.TextSize = 14
	title.TextColor3 = Color3.fromRGB(52, 211, 153)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.Position = UDim2.new(1, 0, 0.5, 0)
	close.Size = UDim2.fromOffset(22, 22)
	close.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
	close.Text = "✕"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 12
	close.TextColor3 = Color3.fromRGB(200, 200, 200)
	close.AutoButtonColor = true
	close.Parent = header
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 8); cc.Parent = close
	close.MouseButton1Click:Connect(function() gui:Destroy() end)

	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.new(1, 0, 0, 14)
	sub.LayoutOrder = 1
	sub.Font = Enum.Font.Gotham
	sub.Text = opts.subtitle or "Pick a script to run"
	sub.TextSize = 11
	sub.TextColor3 = Color3.fromRGB(150, 150, 155)
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Parent = frame

	-- a button per script
	for i, s in ipairs(list) do
		local btn = Instance.new("TextButton")
		btn.Name = "Script_" .. i
		btn.Size = UDim2.new(1, 0, 0, 38)
		btn.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
		btn.Text = s.name
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 14
		btn.TextColor3 = Color3.fromRGB(235, 235, 235)
		btn.AutoButtonColor = false
		btn.LayoutOrder = i + 1
		btn.Parent = frame
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 10); bc.Parent = btn
		local bs = Instance.new("UIStroke"); bs.Color = Color3.fromRGB(60, 60, 66); bs.Thickness = 1; bs.Transparency = 0.4; bs.Parent = btn

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(52, 211, 153) }):Play()
			btn.TextColor3 = Color3.fromRGB(10, 10, 10)
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(24, 24, 27) }):Play()
			btn.TextColor3 = Color3.fromRGB(235, 235, 235)
		end)
		btn.MouseButton1Click:Connect(function()
			gui:Destroy()
			runScript(s.url)
		end)
	end

	makeDraggable(frame, header)
	safeParent(gui)
	return gui
end

return Selector
