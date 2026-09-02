--!nonstrict
-- COMBOWICK — Script Selector
-- Renders a professional picker using the syde UI library. Given the scripts a
-- user's key unlocks: 1 script auto-runs (no UI); 2+ shows a syde window with a
-- button per script. Falls back to a small built-in frame if syde can't load.
--
--   local Selector = loadstring(game:HttpGet("<this file raw url>"))()
--   Selector.show(scripts)   -- scripts = { {name="Script 1", url="https://..."}, ... }

local Players = game:GetService("Players")
local SYDE_URL = "https://raw.githubusercontent.com/essencejs/syde/refs/heads/main/source"
local ACCENT = Color3.fromRGB(52, 211, 153) -- COMBOWICK emerald

local function runScript(url)
	task.spawn(function()
		local ok, src = pcall(function() return game:HttpGet(url, true) end)
		if not ok or type(src) ~= "string" then return end
		local fn = loadstring(src)
		if fn then pcall(fn) end
	end)
end

-- ---------------------------------------------------------------------------
-- syde UI (primary)
-- ---------------------------------------------------------------------------
local function showSyde(list, opts)
	local ok, syde = pcall(function() return loadstring(game:HttpGet(SYDE_URL, true))() end)
	if not ok or type(syde) ~= "table" then return false end

	local built = pcall(function()
		syde:Load({
			Name = "COMBOWICK",
			Status = opts.status or "Script Selector",
			Accent = opts.accent or ACCENT,
			HitBox = opts.accent or ACCENT,
			AutoLoad = false,
			ConfigurationSaving = { Enabled = false },
		})

		local Window = syde:Init({ Title = "COMBOWICK", SubText = opts.subtitle or "Choose a script to run" })
		if not Window or not Window.InitTab then error("no window") end

		local Tab = Window:InitTab({ Title = "Scripts" })
		Tab:Section("Available Scripts")

		local function close()
			pcall(function()
				if syde.Destroy then syde:Destroy()
				elseif Window and Window.main then Window.main:Destroy() end
			end)
		end

		for _, s in ipairs(list) do
			Tab:Button({
				Title = s.name,
				Description = "Run " .. s.name,
				CallBack = function()
					close()
					runScript(s.url)
				end,
			})
		end

		pcall(function() syde:Notify({ Title = "COMBOWICK", Content = "Pick a script to run", Duration = 4 }) end)
	end)
	return built
end

-- ---------------------------------------------------------------------------
-- Minimal built-in frame (fallback only, if syde fails to load)
-- ---------------------------------------------------------------------------
local function showFallback(list, opts)
	local UserInput = game:GetService("UserInputService")
	local gui = Instance.new("ScreenGui")
	gui.Name = "CW_Selector"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
	local ok = pcall(function()
		if gethui then gui.Parent = gethui() else gui.Parent = game:GetService("CoreGui") end
	end)
	if not ok or not gui.Parent then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5); frame.Position = UDim2.fromScale(0.5, 0.42)
	frame.Size = UDim2.fromOffset(230, 0); frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundColor3 = Color3.fromRGB(16, 16, 18); frame.BorderSizePixel = 0; frame.Parent = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
	local st = Instance.new("UIStroke", frame); st.Color = opts.accent or ACCENT; st.Transparency = 0.35
	local pad = Instance.new("UIPadding", frame)
	pad.PaddingTop = UDim.new(0, 12); pad.PaddingBottom = UDim.new(0, 12); pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
	local lay = Instance.new("UIListLayout", frame); lay.Padding = UDim.new(0, 8); lay.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local title = Instance.new("TextLabel"); title.BackgroundTransparency = 1; title.Size = UDim2.new(1, 0, 0, 20)
	title.Font = Enum.Font.GothamBold; title.Text = "COMBOWICK"; title.TextSize = 14; title.TextColor3 = opts.accent or ACCENT
	title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = frame

	for i, s in ipairs(list) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 38); btn.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
		btn.Text = s.name; btn.Font = Enum.Font.GothamMedium; btn.TextSize = 14; btn.TextColor3 = Color3.fromRGB(235, 235, 235)
		btn.AutoButtonColor = true; btn.LayoutOrder = i; btn.Parent = frame
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
		btn.MouseButton1Click:Connect(function() gui:Destroy(); runScript(s.url) end)
	end

	-- drag
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

-- ---------------------------------------------------------------------------
local Selector = {}

function Selector.show(scripts, opts)
	opts = opts or {}
	scripts = scripts or {}

	local list = {}
	for _, s in ipairs(scripts) do
		if s and s.url and s.url ~= "" then
			list[#list + 1] = { name = tostring(s.name or "Script"), url = tostring(s.url) }
		end
	end
	if #list == 0 then return end
	if #list == 1 then
		runScript(list[1].url)
		return
	end

	if not showSyde(list, opts) then
		showFallback(list, opts)
	end
end

return Selector
