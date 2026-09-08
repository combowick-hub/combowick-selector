-- COMBOWICK script selector — fully self-contained native GUI (no third-party UI lib).
-- Dark theme, own loading animation, big readable text, draggable, uniform resize.
-- Selector.show(scripts, opts): opts.onSelect(script) takes over loading (free path uses
-- it to fetch through the token-gated endpoint); otherwise run an inline body or a URL.

local Players       = game:GetService("Players")
local UserInput     = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")

local ACCENT     = Color3.fromRGB(52, 211, 153)
local BG         = Color3.fromRGB(20, 20, 24)
local CARD       = Color3.fromRGB(30, 30, 36)
local CARD_HOVER = Color3.fromRGB(42, 42, 50)
local WALLPAPER  = "rbxassetid://14554547135"

-- Run a chosen script. opts.onSelect (when provided) takes over loading entirely.
-- Otherwise: run an inline body verbatim, else HttpGet a URL.
local function runItem(s, opts)
	if opts and type(opts.onSelect) == "function" then
		task.spawn(function() pcall(opts.onSelect, s) end)
		return
	end
	task.spawn(function()
		if type(s.body) == "string" and #s.body > 0 then
			local fn = loadstring(s.body)
			if fn then pcall(fn) end
			return
		end
		if type(s.url) == "string" and s.url ~= "" then
			local ok, src = pcall(function() return game:HttpGet(s.url, true) end)
			if not ok or type(src) ~= "string" then return end
			local fn = loadstring(src)
			if fn then pcall(fn) end
		end
	end)
end

local function corner(parent, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = parent; return c end

local function buildGui(list, opts)
	local parent = game:GetService("CoreGui")
	pcall(function() if gethui then local h = gethui(); if h then parent = h end end end)
	pcall(function() local o = parent:FindFirstChild("CW_Selector"); if o then o:Destroy() end end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "CW_Selector"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 9999999
	gui.Parent = parent

	-- root panel
	local root = Instance.new("Frame")
	root.AnchorPoint = Vector2.new(0.5, 0.5); root.Position = UDim2.fromScale(0.5, 0.45)
	root.Size = UDim2.fromOffset(480, 300); root.BackgroundColor3 = BG; root.BorderSizePixel = 0; root.Parent = gui
	local scale = Instance.new("UIScale"); scale.Scale = 1; scale.Parent = root
	corner(root, 18)
	local stroke = Instance.new("UIStroke", root); stroke.Color = ACCENT; stroke.Transparency = 0.45; stroke.Thickness = 1.5

	local wp = Instance.new("ImageLabel"); wp.Size = UDim2.fromScale(1, 1); wp.BackgroundTransparency = 1
	wp.Image = WALLPAPER; wp.ImageTransparency = 0.9; wp.ScaleType = Enum.ScaleType.Crop; wp.Parent = root; corner(wp, 18)

	local pad = Instance.new("UIPadding", root)
	pad.PaddingTop = UDim.new(0, 18); pad.PaddingBottom = UDim.new(0, 16); pad.PaddingLeft = UDim.new(0, 18); pad.PaddingRight = UDim.new(0, 18)

	-- header
	local title = Instance.new("TextLabel"); title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -40, 0, 28); title.Font = Enum.Font.GothamBold; title.TextSize = 24
	title.TextColor3 = ACCENT; title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = "COMBOWICK"; title.Parent = root
	local sub = Instance.new("TextLabel"); sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromOffset(0, 30); sub.Size = UDim2.new(1, -40, 0, 18)
	sub.Font = Enum.Font.Gotham; sub.TextSize = 14; sub.TextColor3 = Color3.fromRGB(150, 150, 158)
	sub.TextXAlignment = Enum.TextXAlignment.Left; sub.Text = "Choose a script to run"; sub.Parent = root
	local close = Instance.new("TextButton"); close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, 0, 0, 0)
	close.Size = UDim2.fromOffset(30, 30); close.BackgroundColor3 = Color3.fromRGB(40, 40, 46); close.Text = "✕"
	close.Font = Enum.Font.GothamBold; close.TextSize = 16; close.TextColor3 = Color3.fromRGB(220, 220, 220); close.Parent = root
	corner(close, 15)
	close.MouseButton1Click:Connect(function() gui:Destroy() end)

	-- footer
	local footer = Instance.new("TextLabel"); footer.BackgroundTransparency = 1; footer.AnchorPoint = Vector2.new(0, 1)
	footer.Position = UDim2.new(0, 0, 1, 0); footer.Size = UDim2.new(1, -20, 0, 14)
	footer.Font = Enum.Font.Gotham; footer.TextSize = 11; footer.TextColor3 = Color3.fromRGB(110, 110, 118)
	footer.TextXAlignment = Enum.TextXAlignment.Left; footer.Text = "COMBOWICK • free session"; footer.Parent = root

	-- loading row (phase 1)
	local loading = Instance.new("Frame"); loading.BackgroundTransparency = 1
	loading.Position = UDim2.fromOffset(0, 70); loading.Size = UDim2.new(1, 0, 0, 70); loading.Parent = root
	local ltxt = Instance.new("TextLabel"); ltxt.BackgroundTransparency = 1; ltxt.Size = UDim2.new(1, 0, 0, 20)
	ltxt.Font = Enum.Font.Gotham; ltxt.TextSize = 14; ltxt.TextColor3 = Color3.fromRGB(180, 180, 188); ltxt.Text = "Preparing scripts…"; ltxt.Parent = loading
	local dotsHolder = Instance.new("Frame"); dotsHolder.BackgroundTransparency = 1; dotsHolder.AnchorPoint = Vector2.new(0.5, 0)
	dotsHolder.Position = UDim2.new(0.5, 0, 0, 34); dotsHolder.Size = UDim2.fromOffset(58, 12); dotsHolder.Parent = loading
	local dl = Instance.new("UIListLayout", dotsHolder); dl.FillDirection = Enum.FillDirection.Horizontal
	dl.Padding = UDim.new(0, 8); dl.HorizontalAlignment = Enum.HorizontalAlignment.Center; dl.VerticalAlignment = Enum.VerticalAlignment.Center
	local dots = {}
	for i = 1, 3 do
		local d = Instance.new("Frame"); d.Size = UDim2.fromOffset(10, 10); d.BackgroundColor3 = ACCENT
		d.BackgroundTransparency = 0.6; d.LayoutOrder = i; d.Parent = dotsHolder; corner(d, 5); dots[i] = d
	end

	-- list container (phase 2)
	local rowH = 68
	local listFrame = Instance.new("Frame"); listFrame.BackgroundTransparency = 1; listFrame.Visible = false
	listFrame.Position = UDim2.fromOffset(0, 60); listFrame.Size = UDim2.new(1, 0, 1, -90); listFrame.Parent = root
	local layout = Instance.new("UIListLayout", listFrame); layout.Padding = UDim.new(0, 10); layout.SortOrder = Enum.SortOrder.LayoutOrder

	for i, item in ipairs(list) do
		local card = Instance.new("TextButton"); card.Size = UDim2.new(1, 0, 0, rowH); card.BackgroundColor3 = CARD
		card.AutoButtonColor = false; card.Text = ""; card.LayoutOrder = i; card.Parent = listFrame
		corner(card, 12)
		local cs = Instance.new("UIStroke", card); cs.Color = Color3.fromRGB(55, 55, 62); cs.Transparency = 0.35
		local bar = Instance.new("Frame"); bar.Size = UDim2.fromOffset(4, rowH - 26); bar.Position = UDim2.fromOffset(0, 13)
		bar.BackgroundColor3 = ACCENT; bar.BorderSizePixel = 0; bar.Parent = card; corner(bar, 2)
		local nm = Instance.new("TextLabel"); nm.BackgroundTransparency = 1; nm.Position = UDim2.fromOffset(18, 12); nm.Size = UDim2.new(1, -54, 0, 24)
		nm.Font = Enum.Font.GothamBold; nm.TextSize = 18; nm.TextColor3 = Color3.fromRGB(240, 240, 245)
		nm.TextXAlignment = Enum.TextXAlignment.Left; nm.TextTruncate = Enum.TextTruncate.AtEnd; nm.Text = item.name; nm.Parent = card
		local ds = Instance.new("TextLabel"); ds.BackgroundTransparency = 1; ds.Position = UDim2.fromOffset(18, 38); ds.Size = UDim2.new(1, -54, 0, 18)
		ds.Font = Enum.Font.Gotham; ds.TextSize = 14; ds.TextColor3 = Color3.fromRGB(150, 150, 158); ds.TextXAlignment = Enum.TextXAlignment.Left
		ds.Text = item.mins and ("Tap to run  •  " .. tostring(item.mins) .. " min free") or "Tap to run"; ds.Parent = card
		local arrow = Instance.new("TextLabel"); arrow.BackgroundTransparency = 1; arrow.AnchorPoint = Vector2.new(1, 0.5)
		arrow.Position = UDim2.new(1, -14, 0.5, 0); arrow.Size = UDim2.fromOffset(20, 20)
		arrow.Font = Enum.Font.GothamBold; arrow.TextSize = 22; arrow.TextColor3 = ACCENT; arrow.Text = "›"; arrow.Parent = card
		card.MouseEnter:Connect(function() TweenService:Create(card, TweenInfo.new(0.15), { BackgroundColor3 = CARD_HOVER }):Play() end)
		card.MouseLeave:Connect(function() TweenService:Create(card, TweenInfo.new(0.15), { BackgroundColor3 = CARD }):Play() end)
		card.MouseButton1Click:Connect(function()
			gui:Destroy()
			runItem(item.s, opts)
		end)
	end

	-- entrance pop
	scale.Scale = 0.9
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	-- loading dots loop
	local playing = true
	task.spawn(function()
		while playing and loading.Parent do
			for i = 1, 3 do
				if not playing then break end
				TweenService:Create(dots[i], TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
				task.wait(0.16)
				TweenService:Create(dots[i], TweenInfo.new(0.3), { BackgroundTransparency = 0.6 }):Play()
			end
		end
	end)

	-- reveal the list after the short splash
	task.spawn(function()
		task.wait(0.85)
		playing = false
		loading.Visible = false
		root.Size = UDim2.fromOffset(480, 64 + #list * (rowH + 10) + 42)
		listFrame.Visible = true
	end)

	-- drag by the header
	local dragging, dStart, startPos
	local function beginDrag(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dStart = inp.Position; startPos = root.Position
		end
	end
	title.InputBegan:Connect(beginDrag); sub.InputBegan:Connect(beginDrag)

	-- resize grip (bottom-right) -> uniform scale 0.7 .. 1.8
	local grip = Instance.new("TextButton"); grip.AnchorPoint = Vector2.new(1, 1); grip.Position = UDim2.new(1, 2, 1, 2)
	grip.Size = UDim2.fromOffset(20, 20); grip.BackgroundTransparency = 1; grip.Text = "◢"; grip.Font = Enum.Font.GothamBold
	grip.TextSize = 14; grip.TextColor3 = Color3.fromRGB(120, 120, 128); grip.Parent = root
	local resizing, rStart, rScale
	grip.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			resizing = true; rStart = inp.Position; rScale = scale.Scale
		end
	end)

	UserInput.InputChanged:Connect(function(inp)
		if not gui.Parent then return end
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				local d = inp.Position - dStart
				root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			elseif resizing then
				scale.Scale = math.clamp(rScale + (inp.Position.X - rStart.X) / 400, 0.7, 1.8)
			end
		end
	end)
	UserInput.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false; resizing = false
		end
	end)
end

local Selector = {}

function Selector.show(scripts, opts)
	scripts = scripts or {}
	local hasSelect = opts and type(opts.onSelect) == "function"
	local list = {}
	for _, s in ipairs(scripts) do
		local runnable = hasSelect or (s and ((s.url and s.url ~= "") or (s.body and s.body ~= "")))
		if s and runnable then
			local mins = nil
			if tonumber(s.session_seconds) and tonumber(s.session_seconds) > 0 then
				mins = math.floor(tonumber(s.session_seconds) / 60 + 0.5)
			end
			list[#list + 1] = { name = tostring(s.name or "Script"), s = s, mins = mins }
		end
	end
	if #list == 0 then return end
	if #list == 1 then runItem(list[1].s, opts); return end
	local ok, err = pcall(buildGui, list, opts)
	if not ok then warn("[COMBOWICK] selector error: " .. tostring(err)) end
end

return Selector
