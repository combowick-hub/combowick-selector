local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local SYDE_URL = "https://raw.githubusercontent.com/combowick-hub/syde/main/source"
local ACCENT = Color3.fromRGB(52, 211, 153)
local WALLPAPER_ID = "14554547135"
local WINDOW_SCALE = 1.15   -- was 0.7 (too small to read); scale the whole window up

-- entry = { url = "..." }  (public GitHub-style URL)  OR  { body = "..." } (PROTECTED:
-- the script body delivered inline in the validate response, never a public URL).
local function runScript(entry)
	task.spawn(function()
		local src
		if type(entry) == "table" and type(entry.body) == "string" and entry.body ~= "" then
			src = entry.body
		else
			local url = (type(entry) == "table") and entry.url or entry
			if type(url) ~= "string" or url == "" then return end
			local ok, s = pcall(function() return game:HttpGet(url, true) end)
			if not ok or type(s) ~= "string" then return end
			src = s
		end
		local fn = loadstring(src)
		if fn then pcall(fn) end
	end)
end

local function findMain()
	local roots = {}
	if gethui then pcall(function() table.insert(roots, gethui()) end) end
	table.insert(roots, game:GetService("CoreGui"))
	pcall(function() table.insert(roots, Players.LocalPlayer.PlayerGui) end)
	for _, root in ipairs(roots) do
		for _, sg in ipairs(root:GetChildren()) do
			local m = sg:FindFirstChild("main")
			if m and m:FindFirstChild("wallpaper") then return m end
		end
	end
end

local PAGE_BG = { { "pages", "v0" }, { "pages", "v1" }, { "pages", "clipframe", "v0" }, { "pages", "clipframe", "v1" } }
local function dig(root, path)
	local n = root
	for _, s in ipairs(path) do n = n and n:FindFirstChild(s) end
	return n
end

local function decorate()
	local w = findMain()
	if not w then return end
	pcall(function()
		local wp = w:FindFirstChild("wallpaper")
		if wp then
			wp.Image = "rbxassetid://" .. WALLPAPER_ID
			wp.Visible = true
			local ison = wp:FindFirstChild("ison")
			if ison then ison.Value = true end
			for _, p in ipairs(PAGE_BG) do
				local node = dig(w, p)
				if node then node.Visible = false end
			end
		end
		local sc = w:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		sc.Scale = WINDOW_SCALE
		sc.Parent = w
	end)
end

local function showSyde(list)
	local ok, syde = pcall(function() return loadstring(game:HttpGet(SYDE_URL, true))() end)
	if not ok or type(syde) ~= "table" then return false end
	return pcall(function()
		syde:Load({
			Name = "COMBOWICK", Status = "Script Selector",
			Accent = ACCENT, HitBox = ACCENT,
			AutoLoad = false, ConfigurationSaving = { Enabled = false },
		})
		local Window = syde:Init({ Title = "COMBOWICK", SubText = "Choose a script to run" })
		if not Window or not Window.InitTab then error("no window") end
		local Tab = Window:InitTab({ Title = "Scripts" })
		Tab:Section("Available Scripts")
		local function close()
			pcall(function()
				if syde.Destroy then syde:Destroy() elseif Window and Window.main then Window.main:Destroy() end
			end)
		end
		for _, s in ipairs(list) do
			Tab:Button({ Title = s.name, Description = "Run " .. s.name, CallBack = function()
				close()
				runScript(s)
			end })
		end
		task.wait(0.6)
		decorate()
	end)
end

local function showFallback(list)
	local gui = Instance.new("ScreenGui")
	gui.Name = "CW_Selector"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
	local ok = pcall(function()
		if gethui then gui.Parent = gethui() else gui.Parent = game:GetService("CoreGui") end
	end)
	if not ok or not gui.Parent then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5); frame.Position = UDim2.fromScale(0.5, 0.42)
	frame.Size = UDim2.fromOffset(200, 0); frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundColor3 = Color3.fromRGB(16, 16, 18); frame.BorderSizePixel = 0; frame.Parent = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke", frame); stroke.Color = ACCENT; stroke.Transparency = 0.35
	local pad = Instance.new("UIPadding", frame)
	pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10); pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
	local layout = Instance.new("UIListLayout", frame); layout.Padding = UDim.new(0, 6); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local title = Instance.new("TextLabel"); title.BackgroundTransparency = 1; title.Size = UDim2.new(1, 0, 0, 18)
	title.Font = Enum.Font.GothamBold; title.Text = "COMBOWICK"; title.TextSize = 13; title.TextColor3 = ACCENT
	title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = frame
	for i, s in ipairs(list) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 34); btn.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
		btn.Text = s.name; btn.Font = Enum.Font.GothamMedium; btn.TextSize = 13; btn.TextColor3 = Color3.fromRGB(235, 235, 235)
		btn.AutoButtonColor = true; btn.LayoutOrder = i; btn.Parent = frame
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		btn.MouseButton1Click:Connect(function() gui:Destroy(); runScript(s) end)
	end
	local dragging, ds, sp
	title.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; ds = inp.Position; sp = frame.Position
		end
	end)
	UserInput.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	UserInput.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local d = inp.Position - ds
			frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end
	end)
end

local Selector = {}

function Selector.show(scripts, opts)
	scripts = scripts or {}
	local list = {}
	for _, s in ipairs(scripts) do
		local hasUrl = s and type(s.url) == "string" and s.url ~= ""
		local hasBody = s and type(s.body) == "string" and s.body ~= ""
		if hasUrl or hasBody then
			list[#list + 1] = {
				name = tostring(s.name or "Script"),
				url = hasUrl and tostring(s.url) or nil,
				body = hasBody and tostring(s.body) or nil,
			}
		end
	end
	if #list == 0 then return end
	if #list == 1 then
		runScript(list[1])
		return
	end
	if not showSyde(list) then showFallback(list) end
end

return Selector
