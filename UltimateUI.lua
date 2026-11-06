--[[
    UltimateUI - Expanded Roblox Studio UI Library
    Version: 2.0.0

    Intended for legitimate Roblox Studio experiences.
    Place this ModuleScript in ReplicatedStorage and require it from a LocalScript.

    Example:
        local UltimateUI = require(game.ReplicatedStorage.UltimateUI)
        local UI = UltimateUI.new({ Title = "My Hub", Theme = "Midnight" })
        local tab = UI:CreateTab("Main", "house")
        local section = tab:CreateSection("Controls", "left")
        section:CreateButton({ Name = "Click me", Callback = function() print("Hello") end })

    This is a client-side interface framework. It does not inject into other games,
    bypass Roblox security, or provide exploit functionality.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

local UltimateUI = {}
UltimateUI.__index = UltimateUI

local Window, Tab, Section, Element

local DEFAULT_THEME = {
    Name = "Midnight",
    Background = Color3.fromRGB(17, 19, 27),
    Surface = Color3.fromRGB(25, 28, 39),
    Surface2 = Color3.fromRGB(34, 38, 52),
    SurfaceHover = Color3.fromRGB(43, 48, 65),
    Accent = Color3.fromRGB(119, 104, 255),
    AccentDark = Color3.fromRGB(88, 75, 210),
    Text = Color3.fromRGB(242, 243, 250),
    SubText = Color3.fromRGB(157, 163, 181),
    Border = Color3.fromRGB(58, 63, 82),
    Success = Color3.fromRGB(77, 196, 133),
    Warning = Color3.fromRGB(245, 185, 75),
    Danger = Color3.fromRGB(239, 91, 104),
    Font = Enum.Font.Gotham,
    CornerRadius = 8,
    Transparency = 0,
}

local PRESETS = {
    Midnight = DEFAULT_THEME,
    Ocean = {
        Background = Color3.fromRGB(12, 23, 34), Surface = Color3.fromRGB(18, 37, 52),
        Surface2 = Color3.fromRGB(26, 53, 72), SurfaceHover = Color3.fromRGB(35, 68, 90),
        Accent = Color3.fromRGB(42, 176, 214), AccentDark = Color3.fromRGB(28, 135, 171),
        Text = Color3.fromRGB(235, 248, 252), SubText = Color3.fromRGB(145, 180, 193),
        Border = Color3.fromRGB(48, 83, 101), Success = Color3.fromRGB(77, 196, 133),
        Warning = Color3.fromRGB(245, 185, 75), Danger = Color3.fromRGB(239, 91, 104),
    },
    Forest = {
        Background = Color3.fromRGB(17, 26, 21), Surface = Color3.fromRGB(25, 38, 30),
        Surface2 = Color3.fromRGB(34, 51, 40), SurfaceHover = Color3.fromRGB(43, 64, 49),
        Accent = Color3.fromRGB(93, 190, 124), AccentDark = Color3.fromRGB(61, 145, 91),
        Text = Color3.fromRGB(239, 248, 240), SubText = Color3.fromRGB(158, 181, 162),
        Border = Color3.fromRGB(57, 79, 62), Success = Color3.fromRGB(77, 196, 133),
        Warning = Color3.fromRGB(245, 185, 75), Danger = Color3.fromRGB(239, 91, 104),
    },
    Light = {
        Background = Color3.fromRGB(235, 238, 245), Surface = Color3.fromRGB(250, 251, 253),
        Surface2 = Color3.fromRGB(229, 233, 242), SurfaceHover = Color3.fromRGB(218, 224, 235),
        Accent = Color3.fromRGB(101, 88, 220), AccentDark = Color3.fromRGB(79, 67, 187),
        Text = Color3.fromRGB(31, 35, 48), SubText = Color3.fromRGB(99, 106, 124),
        Border = Color3.fromRGB(204, 210, 223), Success = Color3.fromRGB(37, 151, 94),
        Warning = Color3.fromRGB(191, 128, 25), Danger = Color3.fromRGB(204, 62, 75),
    },
    Rose = {
        Background = Color3.fromRGB(31, 19, 27), Surface = Color3.fromRGB(43, 27, 38),
        Surface2 = Color3.fromRGB(57, 35, 50), SurfaceHover = Color3.fromRGB(72, 43, 62),
        Accent = Color3.fromRGB(239, 105, 164), AccentDark = Color3.fromRGB(196, 72, 129),
        Text = Color3.fromRGB(255, 241, 248), SubText = Color3.fromRGB(191, 155, 175),
        Border = Color3.fromRGB(85, 55, 74), Success = Color3.fromRGB(77, 196, 133),
        Warning = Color3.fromRGB(245, 185, 75), Danger = Color3.fromRGB(239, 91, 104),
    },
}

local function copyTable(source)
    local result = {}
    for k, v in pairs(source) do
        result[k] = type(v) == "table" and copyTable(v) or v
    end
    return result
end

local function merge(base, extra)
    local result = copyTable(base)
    for k, v in pairs(extra or {}) do result[k] = v end
    return result
end

local function round(instance, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = instance
    return c
end

local function stroke(instance, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.new(1, 1, 1)
    s.Transparency = transparency or 0
    s.Thickness = thickness or 1
    s.Parent = instance
    return s
end

local function padding(instance, left, right, top, bottom)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.Parent = instance
    return p
end

local function listLayout(instance, direction, gap, horizontalAlignment)
    local l = Instance.new("UIListLayout")
    l.FillDirection = direction or Enum.FillDirection.Vertical
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, gap or 6)
    l.HorizontalAlignment = horizontalAlignment or Enum.HorizontalAlignment.Left
    l.Parent = instance
    return l
end

local function newInstance(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local function tween(object, duration, properties, style, direction)
    local info = TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out)
    local t = TweenService:Create(object, info, properties)
    t:Play()
    return t
end

local function makeText(parent, text, size, color, font)
    return newInstance("TextLabel", {
        BackgroundTransparency = 1, Text = tostring(text or ""), TextSize = size or 13,
        TextColor3 = color or Color3.new(1, 1, 1), Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        AutomaticSize = Enum.AutomaticSize.None,
    }, parent)
end

local function makeButton(parent, text, theme, height)
    local b = newInstance("TextButton", {
        AutoButtonColor = false, Text = text or "", TextSize = 13,
        TextColor3 = theme.Text, Font = theme.Font, BackgroundColor3 = theme.Surface2,
        Size = UDim2.new(1, 0, 0, height or 34),
    }, parent)
    round(b, theme.CornerRadius)
    return b
end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, err = pcall(callback, ...)
    if not ok then warn("[UltimateUI] Callback error: " .. tostring(err)) end
end

local function disconnectAll(list)
    for _, item in ipairs(list) do
        if typeof(item) == "RBXScriptConnection" then item:Disconnect()
        elseif type(item) == "function" then pcall(item) end
    end
    table.clear(list)
end

function UltimateUI.new(options)
    options = options or {}
    local self = setmetatable({}, UltimateUI)
    self.Theme = merge(DEFAULT_THEME, options.Theme or {})
    if type(options.Theme) == "string" and PRESETS[options.Theme] then
        self.Theme = merge(DEFAULT_THEME, PRESETS[options.Theme])
    end
    self.Theme.Name = self.Theme.Name or "Custom"
    self.Options = options
    self.Connections = {}
    self.Elements = {}
    self.Tabs = {}
    self.Destroyed = false
    self.Visible = true
    self.Minimized = false
    self._keybinds = {}
    self._notifications = {}
    self:_build(options)
    return self
end

function UltimateUI:_build(options)
    local theme = self.Theme
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local gui = newInstance("ScreenGui", {
        Name = options.Name or "UltimateUI",
        ResetOnSpawn = false, IgnoreGuiInset = options.IgnoreGuiInset ~= false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = options.DisplayOrder or 20,
    }, playerGui)
    self.Gui = gui

    local main = newInstance("Frame", {
        Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = options.Position or UDim2.fromScale(0.5, 0.5),
        Size = options.Size or UDim2.fromOffset(720, 490),
        BackgroundColor3 = theme.Background, BackgroundTransparency = theme.Transparency,
        ClipsDescendants = true,
    }, gui)
    round(main, theme.CornerRadius + 3)
    stroke(main, theme.Border, 0.15, 1)
    self.Main = main

    local top = newInstance("Frame", {
        Name = "Topbar", Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = theme.Surface, BorderSizePixel = 0,
    }, main)
    self.Topbar = top
    local title = makeText(top, options.Title or "UltimateUI", 15, theme.Text, theme.Font)
    title.Position = UDim2.fromOffset(17, 0)
    title.Size = UDim2.new(1, -150, 1, 0)
    title.Font = Enum.Font.GothamBold
    self.TitleLabel = title

    local subtitle = makeText(top, options.Subtitle or "Interface framework", 10, theme.SubText, theme.Font)
    subtitle.Position = UDim2.fromOffset(18, 27)
    subtitle.Size = UDim2.new(1, -160, 0, 14)
    self.SubtitleLabel = subtitle

    local controls = newInstance("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(82, 28),
    }, top)
    listLayout(controls, Enum.FillDirection.Horizontal, 7, Enum.HorizontalAlignment.Right)
    local minimize = makeButton(controls, "—", theme, 27)
    minimize.Size = UDim2.fromOffset(34, 27)
    local close = makeButton(controls, "×", theme, 27)
    close.Size = UDim2.fromOffset(34, 27)
    close.TextSize = 18
    self.MinimizeButton, self.CloseButton = minimize, close

    local body = newInstance("Frame", {
        Name = "Body", Position = UDim2.fromOffset(0, 48),
        Size = UDim2.new(1, 0, 1, -48), BackgroundTransparency = 1,
    }, main)
    self.Body = body

    local sidebar = newInstance("Frame", {
        Name = "Sidebar", Size = UDim2.new(0, options.SidebarWidth or 164, 1, 0),
        BackgroundColor3 = theme.Surface, BorderSizePixel = 0,
    }, body)
    self.Sidebar = sidebar
    padding(sidebar, 10, 10, 12, 10)
    local tabScroll = newInstance("ScrollingFrame", {
        Name = "Tabs", BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Accent,
    }, sidebar)
    listLayout(tabScroll, Enum.FillDirection.Vertical, 5)
    self.TabScroll = tabScroll

    local content = newInstance("Frame", {
        Name = "Content", Position = UDim2.new(0, options.SidebarWidth or 164, 0, 0),
        Size = UDim2.new(1, -(options.SidebarWidth or 164), 1, 0),
        BackgroundColor3 = theme.Background, BorderSizePixel = 0,
    }, body)
    self.Content = content

    local search = newInstance("TextBox", {
        Name = "Search", PlaceholderText = "Search controls...",
        Text = "", ClearTextOnFocus = false, Font = theme.Font, TextSize = 12,
        TextColor3 = theme.Text, PlaceholderColor3 = theme.SubText,
        BackgroundColor3 = theme.Surface, BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 12), Size = UDim2.new(1, -28, 0, 32),
    }, content)
    round(search, theme.CornerRadius)
    padding(search, 10, 8, 0, 0)
    self.SearchBox = search

    local pages = newInstance("Frame", {
        Name = "Pages", Position = UDim2.fromOffset(14, 54),
        Size = UDim2.new(1, -28, 1, -66), BackgroundTransparency = 1,
    }, content)
    self.Pages = pages

    local resize = newInstance("TextButton", {
        Name = "ResizeGrip", Text = "", AutoButtonColor = false,
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0), Size = UDim2.fromOffset(18, 18),
    }, main)
    self.ResizeGrip = resize

    self:_makeDraggable(top, main)
    self:_makeResizable(resize, main)
    table.insert(self.Connections, minimize.Activated:Connect(function() self:Minimize() end))
    table.insert(self.Connections, close.Activated:Connect(function() self:Hide() end))
    table.insert(self.Connections, search:GetPropertyChangedSignal("Text"):Connect(function()
        self:Search(search.Text)
    end))
end

function UltimateUI:_makeDraggable(handle, target)
    local dragging, start, origin
    table.insert(self.Connections, handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start = input.Position
            origin = target.Position
        end
    end))
    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - start
            target.Position = UDim2.new(origin.X.Scale, origin.X.Offset + delta.X,
                origin.Y.Scale, origin.Y.Offset + delta.Y)
        end
    end))
    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

function UltimateUI:_makeResizable(grip, target)
    local resizing, start, original
    table.insert(self.Connections, grip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing, start, original = true, input.Position, target.Size
        end
    end))
    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - start
            target.Size = UDim2.fromOffset(math.max(480, original.X.Offset + d.X), math.max(320, original.Y.Offset + d.Y))
        end
    end))
    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = false end
    end))
end

function UltimateUI:CreateTab(name, icon)
    assert(not self.Destroyed, "UltimateUI has been destroyed")
    local tab = setmetatable({
        Window = self, Name = name, Icon = icon, Sections = {}, Elements = {},
        Theme = self.Theme, Active = false,
    }, Tab)
    local button = makeButton(self.TabScroll, (icon and (tostring(icon) .. "   ") or "") .. tostring(name), self.Theme, 36)
    button.TextXAlignment = Enum.TextXAlignment.Left
    padding(button, 10, 6, 0, 0)
    tab.Button = button
    local page = newInstance("ScrollingFrame", {
        Name = tostring(name) .. "Page", BackgroundTransparency = 1,
        BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4, ScrollBarImageColor3 = self.Theme.Accent,
        Visible = false,
    }, self.Pages)
    padding(page, 1, 8, 2, 10)
    local layout = listLayout(page, Enum.FillDirection.Vertical, 10)
    tab.Page, tab.Layout = page, layout
    table.insert(self.Tabs, tab)
    table.insert(self.Elements, tab)
    table.insert(self.Connections, button.Activated:Connect(function() self:SelectTab(tab) end))
    if #self.Tabs == 1 or self.Options.SelectFirstTab then self:SelectTab(tab) end
    return tab
end

function UltimateUI:SelectTab(target)
    for _, tab in ipairs(self.Tabs) do
        local active = tab == target
        tab.Active = active
        tab.Page.Visible = active
        tween(tab.Button, 0.15, {
            BackgroundColor3 = active and self.Theme.AccentDark or self.Theme.Surface2,
            TextColor3 = self.Theme.Text,
        })
    end
    self.ActiveTab = target
end

function Tab:CreateSection(name, side)
    local section = setmetatable({
        Tab = self, Window = self.Window, Name = name, Side = side or "left",
        Elements = {}, Theme = self.Theme,
    }, Section)
    local frame = newInstance("Frame", {
        Name = tostring(name), BackgroundColor3 = self.Theme.Surface,
        Size = UDim2.new(1, 0, 0, 42), AutomaticSize = Enum.AutomaticSize.Y,
    }, self.Page)
    round(frame, self.Theme.CornerRadius)
    stroke(frame, self.Theme.Border, 0.35, 1)
    padding(frame, 10, 10, 9, 10)
    local title = makeText(frame, name, 13, self.Theme.Text, self.Theme.Font)
    title.Size = UDim2.new(1, 0, 0, 22)
    title.Font = Enum.Font.GothamBold
    local holder = newInstance("Frame", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 28),
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    }, frame)
    listLayout(holder, Enum.FillDirection.Vertical, 7)
    section.Frame, section.Holder = frame, holder
    table.insert(self.Sections, section)
    table.insert(self.Elements, section)
    return section
end

function Section:_register(element)
    table.insert(self.Elements, element)
    table.insert(self.Tab.Elements, element)
    table.insert(self.Window.Elements, element)
    return element
end

local function elementBase(section, name, height)
    local frame = newInstance("Frame", {
        Name = name or "Element", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height or 34),
    }, section.Holder)
    return frame
end

function Section:CreateLabel(config)
    config = type(config) == "table" and config or { Text = config }
    local f = elementBase(self, config.Name or "Label", config.Height or 24)
    local label = makeText(f, config.Text or "", config.TextSize or 13, config.Color or self.Theme.Text, self.Theme.Font)
    label.Size = UDim2.fromScale(1, 1)
    local e = { Frame = f, Label = label, Set = function(_, value) label.Text = tostring(value) end }
    return self:_register(e)
end

function Section:CreateParagraph(config)
    config = config or {}
    local f = elementBase(self, config.Name or "Paragraph", config.Height or 58)
    local heading = makeText(f, config.Title or "Information", 13, self.Theme.Text, self.Theme.Font)
    heading.Size = UDim2.new(1, 0, 0, 19)
    heading.Font = Enum.Font.GothamBold
    local body = makeText(f, config.Content or "", 11, self.Theme.SubText, self.Theme.Font)
    body.Position = UDim2.fromOffset(0, 20)
    body.Size = UDim2.new(1, 0, 1, -20)
    body.TextWrapped = true
    body.TextYAlignment = Enum.TextYAlignment.Top
    local e = { Frame = f, Title = heading, Label = body }
    function e:Set(title, content) heading.Text, body.Text = tostring(title), tostring(content) end
    return self:_register(e)
end

function Section:CreateDivider(text)
    local f = elementBase(self, "Divider", 22)
    local line = newInstance("Frame", {
        BorderSizePixel = 0, BackgroundColor3 = self.Theme.Border,
        Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 1),
    }, f)
    if text then
        local label = makeText(f, "  " .. text .. "  ", 10, self.Theme.SubText, self.Theme.Font)
        label.AutomaticSize = Enum.AutomaticSize.X
        label.Size = UDim2.fromOffset(0, 18)
        label.Position = UDim2.fromScale(0.5, 0.5)
        label.AnchorPoint = Vector2.new(0.5, 0.5)
        label.BackgroundColor3 = self.Theme.Surface
        label.BackgroundTransparency = 0
    end
    return self:_register({ Frame = f })
end

function Section:CreateButton(config)
    config = config or {}
    local f = elementBase(self, config.Name or "Button", config.Height or 34)
    local b = makeButton(f, config.Name or "Button", self.Theme, 34)
    b.Size = UDim2.fromScale(1, 1)
    local e = { Frame = f, Button = b }
    function e:SetText(value) b.Text = tostring(value) end
    table.insert(self.Window.Connections, b.Activated:Connect(function()
        if config.Confirm then
            b.Text = config.ConfirmText or "Confirm?"
            task.delay(config.ConfirmDuration or 2, function()
                if b.Parent then b.Text = config.Name or "Button" end
            end)
            if e._confirming then safeCallback(config.Callback) end
            e._confirming = true
            task.delay(config.ConfirmDuration or 2, function() e._confirming = false end)
        else
            safeCallback(config.Callback)
        end
    end))
    return self:_register(e)
end

function Section:CreateToggle(config)
    config = config or {}
    local value = config.Default == true
    local f = elementBase(self, config.Name or "Toggle", 34)
    local label = makeText(f, config.Name or "Toggle", 12, self.Theme.Text, self.Theme.Font)
    label.Size = UDim2.new(1, -55, 1, 0)
    local track = newInstance("TextButton", {
        Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(43, 23),
        BackgroundColor3 = value and self.Theme.Accent or self.Theme.Surface2,
    }, f)
    round(track, 20)
    local knob = newInstance("Frame", {
        Size = UDim2.fromOffset(17, 17), Position = value and UDim2.new(1, -20, 0.5, 0) or UDim2.fromOffset(3, 3),
        BackgroundColor3 = Color3.new(1, 1, 1),
    }, track)
    round(knob, 20)
    local e = { Frame = f, Value = value, Button = track }
    function e:Set(nextValue, silent)
        value = nextValue == true
        e.Value = value
        tween(track, 0.15, { BackgroundColor3 = value and self.Theme.Accent or self.Theme.Surface2 })
        tween(knob, 0.15, { Position = value and UDim2.new(1, -20, 0.5, 0) or UDim2.fromOffset(3, 3) })
        if not silent then safeCallback(config.Callback, value) end
    end
    table.insert(self.Window.Connections, track.Activated:Connect(function() e:Set(not value) end))
    return self:_register(e)
end

function Section:CreateSlider(config)
    config = config or {}
    local min, max = config.Min or 0, config.Max or 100
    local value = math.clamp(config.Default or min, min, max)
    local f = elementBase(self, config.Name or "Slider", 52)
    local label = makeText(f, config.Name or "Slider", 12, self.Theme.Text, self.Theme.Font)
    label.Size = UDim2.new(0.7, 0, 0, 20)
    local valueLabel = makeText(f, tostring(value), 11, self.Theme.SubText, self.Theme.Font)
    valueLabel.Size = UDim2.new(0.3, 0, 0, 20)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    local bar = newInstance("TextButton", {
        Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(0, 29),
        Size = UDim2.new(1, 0, 0, 7), BackgroundColor3 = self.Theme.Surface2,
    }, f)
    round(bar, 8)
    local fill = newInstance("Frame", {
        BorderSizePixel = 0, Size = UDim2.fromScale((value - min) / (max - min), 1),
        BackgroundColor3 = self.Theme.Accent,
    }, bar)
    round(fill, 8)
    local e = { Frame = f, Value = value }
    local function setFromX(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local raw = min + (max - min) * alpha
        local step = config.Step or 1
        local v = math.clamp(min + math.floor((raw - min) / step + 0.5) * step, min, max)
        e:Set(v)
    end
    function e:Set(v, silent)
        value = math.clamp(v, min, max)
        e.Value = value
        local alpha = (value - min) / (max - min)
        fill.Size = UDim2.fromScale(alpha, 1)
        valueLabel.Text = (config.Suffix and (tostring(value) .. config.Suffix)) or tostring(value)
        if not silent then safeCallback(config.Callback, value) end
    end
    local dragging = false
    table.insert(self.Window.Connections, bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setFromX(input.Position.X)
        end
    end))
    table.insert(self.Window.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end))
    table.insert(self.Window.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))
    return self:_register(e)
end

function Section:CreateInput(config)
    config = config or {}
    local f = elementBase(self, config.Name or "Input", config.Height or 60)
    local label = makeText(f, config.Name or "Input", 12, self.Theme.Text, self.Theme.Font)
    label.Size = UDim2.new(1, 0, 0, 20)
    local box = newInstance("TextBox", {
        Text = config.Default or "", PlaceholderText = config.Placeholder or "Enter text...",
        ClearTextOnFocus = false, Font = self.Theme.Font, TextSize = 12,
        TextColor3 = self.Theme.Text, PlaceholderColor3 = self.Theme.SubText,
        BackgroundColor3 = self.Theme.Surface2, BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 32),
    }, f)
    round(box, self.Theme.CornerRadius); padding(box, 9, 9, 0, 0)
    local e = { Frame = f, Input = box }
    function e:Get() return box.Text end
    function e:Set(value) box.Text = tostring(value) end
    table.insert(self.Window.Connections, box.FocusLost:Connect(function(enterPressed)
        safeCallback(config.Callback, box.Text, enterPressed)
    end))
    return self:_register(e)
end

function Section:CreateDropdown(config)
    config = config or {}
    local options = config.Options or {}
    local selected = config.Default
    if selected == nil then selected = options[1] end
    local f = elementBase(self, config.Name or "Dropdown", config.Multi and 62 or 60)
    local label = makeText(f, config.Name or "Dropdown", 12, self.Theme.Text, self.Theme.Font)
    label.Size = UDim2.new(1, 0, 0, 19)
    local button = makeButton(f, tostring(selected or "Select...") .. "   ▾", self.Theme, 32)
    button.Position = UDim2.fromOffset(0, 23)
    button.Size = UDim2.new(1, 0, 0, 32)
    local popup = newInstance("Frame", {
        Visible = false, BackgroundColor3 = self.Theme.Surface2,
        BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, 3),
        Size = UDim2.new(1, 0, 0, math.min(#options * 29, 145)), ZIndex = 20,
    }, f)
    round(popup, self.Theme.CornerRadius)
    local scroll = newInstance("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3, ZIndex = 21,
    }, popup)
    padding(scroll, 5, 5, 5, 5); listLayout(scroll, Enum.FillDirection.Vertical, 3)
    local chosen = config.Multi and (type(config.Default) == "table" and copyTable(config.Default) or {}) or selected
    local e = { Frame = f, Button = button, Popup = popup }
    local function updateText()
        if config.Multi then
            button.Text = (#chosen > 0 and table.concat(chosen, ", ") or "Select...") .. "   ▾"
        else button.Text = tostring(chosen or "Select...") .. "   ▾" end
    end
    function e:Get() return config.Multi and copyTable(chosen) or chosen end
    function e:Set(v, silent)
        chosen = v
        updateText()
        if not silent then safeCallback(config.Callback, e:Get()) end
    end
    for _, option in ipairs(options) do
        local opt = makeButton(scroll, tostring(option), self.Theme, 27)
        opt.ZIndex = 22
        opt.Activated:Connect(function()
            if config.Multi then
                local found = table.find(chosen, option)
                if found then table.remove(chosen, found) else table.insert(chosen, option) end
                e:Set(chosen)
            else
                e:Set(option); popup.Visible = false
            end
        end)
    end
    table.insert(self.Window.Connections, button.Activated:Connect(function() popup.Visible = not popup.Visible end))
    updateText()
    return self:_register(e)
end

function Section:CreateKeybind(config)
    config = config or {}
    local key = config.Default or Enum.KeyCode.RightShift
    local mode = config.Mode or "Press"
    local listening, held, toggled = false, false, false
    local validModes = { Press = true, Toggle = true, Hold = true, Always = true }
    assert(validModes[mode], "Keybind Mode must be Press, Toggle, Hold, or Always")
    local f = elementBase(self, config.Name or "Keybind", 34)
    local label = makeText(f, config.Name or "Keybind", 12, self.Theme.Text, self.Theme.Font)
    label.Size = UDim2.new(1, -115, 1, 0)
    local button = makeButton(f, key.Name, self.Theme, 29)
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, 0, 0.5, 0)
    button.Size = UDim2.fromOffset(108, 29)
    local e = { Frame = f, Mode = mode, Key = key, Active = mode == "Always" }
    function e:SetKey(newKey) key = newKey; e.Key = newKey; button.Text = newKey.Name end
    function e:SetMode(newMode)
        assert(validModes[newMode], "Invalid keybind mode")
        mode = newMode; e.Mode = newMode; e.Active = newMode == "Always"
        safeCallback(config.Callback, e.Active, mode, key)
    end
    function e:Get() return key, mode end
    table.insert(self.Window.Connections, button.Activated:Connect(function()
        listening = true; button.Text = "Press key..."
    end))
    table.insert(self.Window.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                key = input.KeyCode; e.Key = key; button.Text = key.Name; listening = false
            end
            return
        end
        if processed or input.KeyCode ~= key then return end
        if mode == "Toggle" then toggled = not toggled; e.Active = toggled
        elseif mode == "Hold" then held = true; e.Active = true
        elseif mode == "Press" then safeCallback(config.Callback, true, mode, key); return end
        safeCallback(config.Callback, e.Active, mode, key)
    end))
    table.insert(self.Window.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == key and mode == "Hold" then
            held = false; e.Active = false; safeCallback(config.Callback, false, mode, key)
        end
    end))
    return self:_register(e)
end

function Section:CreateColorPicker(config)
    config = config or {}
    local color = config.Default or self.Theme.Accent
    local h, s, v = color:ToHSV()
    local f = elementBase(self, config.Name or "Color", 38)
    local label = makeText(f, config.Name or "Color", 12, self.Theme.Text, self.Theme.Font)
    label.Size = UDim2.new(1, -55, 1, 0)
    local swatch = makeButton(f, "", self.Theme, 27)
    swatch.AnchorPoint = Vector2.new(1, 0.5)
    swatch.Position = UDim2.new(1, 0, 0.5, 0)
    swatch.Size = UDim2.fromOffset(48, 27)
    swatch.BackgroundColor3 = color
    local panel = newInstance("Frame", {
        Visible = false, BackgroundColor3 = self.Theme.Surface2,
        Position = UDim2.new(0, 0, 1, 4), Size = UDim2.new(1, 0, 0, 112),
        ZIndex = 30,
    }, f)
    round(panel, self.Theme.CornerRadius); padding(panel, 8, 8, 8, 8)
    local hue = newInstance("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(1,1,1),
        Size = UDim2.new(1, 0, 0, 15), ZIndex = 31,
    }, panel)
    local gradient = newInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)),
        }),
    }, hue)
    local sat = newInstance("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(1,1,1),
        Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 15), ZIndex = 31,
    }, panel)
    local satGradient = newInstance("UIGradient", {
        Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1)),
    }, sat)
    local brightness = newInstance("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(1,1,1),
        Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 0, 15), ZIndex = 31,
    }, panel)
    local brightGradient = newInstance("UIGradient", {
        Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(0,0,0)),
    }, brightness)
    local hex = newInstance("TextBox", {
        Text = "#" .. color:ToHex(), ClearTextOnFocus = false,
        BackgroundColor3 = self.Theme.Surface, TextColor3 = self.Theme.Text,
        Font = self.Theme.Font, TextSize = 11, Position = UDim2.fromOffset(0, 73),
        Size = UDim2.new(1, 0, 0, 25), ZIndex = 31,
    }, panel)
    round(hex, 5)
    local e = { Frame = f, Value = color, Panel = panel }
    local function refresh(silent)
        color = Color3.fromHSV(h, s, v); e.Value = color
        swatch.BackgroundColor3 = color
        sat.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        satGradient.Transparency = NumberSequence.new(0, 0)
        brightGradient.Color = ColorSequence.new(Color3.fromHSV(h, s, 1), Color3.new(0,0,0))
        hex.Text = "#" .. color:ToHex()
        if not silent then safeCallback(config.Callback, color) end
    end
    local function setFromButton(button, input, modeName)
        local alpha = math.clamp((input.Position.X - button.AbsolutePosition.X) / button.AbsoluteSize.X, 0, 1)
        if modeName == "h" then h = alpha
        elseif modeName == "s" then s = alpha
        else v = 1 - alpha end
        refresh()
    end
    local function bindBar(button, modeName)
        local dragging = false
        table.insert(self.Window.Connections, button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; setFromButton(button, input, modeName)
            end
        end))
        table.insert(self.Window.Connections, UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                setFromButton(button, input, modeName)
            end
        end))
        table.insert(self.Window.Connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end))
    end
    bindBar(hue, "h"); bindBar(sat, "s"); bindBar(brightness, "v")
    table.insert(self.Window.Connections, swatch.Activated:Connect(function() panel.Visible = not panel.Visible end))
    table.insert(self.Window.Connections, hex.FocusLost:Connect(function()
        local raw = hex.Text:gsub("#", "")
        if #raw == 6 then
            local ok, parsed = pcall(Color3.fromHex, raw)
            if ok then h, s, v = parsed:ToHSV(); refresh() else refresh(true) end
        else refresh(true) end
    end))
    function e:Set(newColor, silent) h, s, v = newColor:ToHSV(); refresh(silent) end
    function e:Get() return color end
    refresh(true)
    return self:_register(e)
end

function Section:CreateImage(config)
    config = config or {}
    local height = config.Height or 120
    local f = elementBase(self, config.Name or "Image", height + (config.Title and 22 or 0))
    if config.Title then
        local title = makeText(f, config.Title, 12, self.Theme.Text, self.Theme.Font)
        title.Size = UDim2.new(1, 0, 0, 20)
    end
    local image = newInstance(config.Clickable and "ImageButton" or "ImageLabel", {
        BackgroundColor3 = self.Theme.Surface2, BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, config.Title and 23 or 0),
        Size = UDim2.new(1, 0, 0, height), Image = config.Image or "",
        ScaleType = config.ScaleType or Enum.ScaleType.Fit,
        AutoButtonColor = false,
    }, f)
    round(image, self.Theme.CornerRadius)
    local e = { Frame = f, Image = image }
    function e:SetImage(asset) image.Image = asset end
    if config.Clickable then
        table.insert(self.Window.Connections, image.Activated:Connect(function() safeCallback(config.Callback, image.Image) end))
    end
    return self:_register(e)
end

function Section:CreateProgressBar(config)
    config = config or {}
    local value = math.clamp(config.Default or 0, 0, 1)
    local f = elementBase(self, config.Name or "Progress", 44)
    local label = makeText(f, config.Name or "Progress", 12, self.Theme.Text, self.Theme.Font)
    label.Size = UDim2.new(0.7, 0, 0, 18)
    local valueLabel = makeText(f, tostring(math.floor(value * 100)) .. "%", 11, self.Theme.SubText, self.Theme.Font)
    valueLabel.Size = UDim2.new(0.3, 0, 0, 18)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    local bar = newInstance("Frame", {
        BackgroundColor3 = self.Theme.Surface2, BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 25), Size = UDim2.new(1, 0, 0, 9),
    }, f)
    round(bar, 8)
    local fill = newInstance("Frame", {
        BackgroundColor3 = self.Theme.Accent, BorderSizePixel = 0,
        Size = UDim2.fromScale(value, 1),
    }, bar)
    round(fill, 8)
    local e = { Frame = f, Value = value }
    function e:Set(v)
        value = math.clamp(v, 0, 1); e.Value = value
        tween(fill, 0.2, { Size = UDim2.fromScale(value, 1) })
        valueLabel.Text = tostring(math.floor(value * 100)) .. "%"
    end
    return self:_register(e)
end

function Tab:CreateCharacterPreview(config)
    config = config or {}
    local section = self:CreateSection(config.Name or "Character Preview")
    local viewport = section:CreateImage({ Height = 1 })
    viewport.Frame:Destroy()
    local f = elementBase(section, "CharacterPreview", config.Height or 220)
    local view = newInstance("ViewportFrame", {
        BackgroundColor3 = self.Theme.Surface2, BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1), Ambient = Color3.fromRGB(180,180,180),
        LightColor = Color3.new(1,1,1), LightDirection = Vector3.new(-1,-1,-1),
    }, f)
    round(view, self.Theme.CornerRadius)
    local world = Instance.new("WorldModel"); world.Parent = view
    local camera = Instance.new("Camera"); camera.Parent = view; view.CurrentCamera = camera
    local e = { Frame = f, Viewport = view, World = world }
    local function loadCharacter(character)
        world:ClearAllChildren()
        local clone = character:Clone()
        for _, item in ipairs(clone:GetDescendants()) do
            if item:IsA("Script") or item:IsA("LocalScript") then item:Destroy() end
        end
        clone.Parent = world
        local root = clone:FindFirstChild("HumanoidRootPart")
        local humanoid = clone:FindFirstChildOfClass("Humanoid")
        if root then
            clone.PrimaryPart = root
            clone:PivotTo(CFrame.new(0, 0, 0))
            local _, size = clone:GetBoundingBox()
            camera.CFrame = CFrame.new(Vector3.new(0, size.Y * 0.1, math.max(size.X, size.Y, size.Z) * 1.8),
                Vector3.new(0, size.Y * 0.1, 0))
        end
        if humanoid then humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
    end
    if LocalPlayer.Character then loadCharacter(LocalPlayer.Character) end
    table.insert(self.Window.Connections, LocalPlayer.CharacterAdded:Connect(loadCharacter))
    local rotating, lastX = false, 0
    table.insert(self.Window.Connections, view.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            rotating = true; lastX = input.Position.X
        end
    end))
    table.insert(self.Window.Connections, view.InputChanged:Connect(function(input)
        if rotating and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position.X - lastX; lastX = input.Position.X
            local model = world:GetChildren()[1]
            if model then model:PivotTo(model:GetPivot() * CFrame.Angles(0, math.rad(delta * 0.7), 0)) end
        end
    end))
    table.insert(self.Window.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then rotating = false end
    end))
    function e:Refresh() if LocalPlayer.Character then loadCharacter(LocalPlayer.Character) end end
    return self:_register(e)
end

function UltimateUI:Notify(config)
    config = type(config) == "string" and { Title = "Notification", Content = config } or (config or {})
    local theme = self.Theme
    local toast = newInstance("Frame", {
        BackgroundColor3 = theme.Surface, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 350, 1, -18),
        Size = UDim2.fromOffset(290, config.Height or 82), ZIndex = 100,
    }, self.Gui)
    round(toast, theme.CornerRadius); stroke(toast, theme.Border, 0.2)
    local barColor = config.Color or theme.Accent
    local bar = newInstance("Frame", {
        BackgroundColor3 = barColor, BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0), ZIndex = 101,
    }, toast)
    round(bar, 4)
    local title = makeText(toast, config.Title or "Notification", 13, theme.Text, theme.Font)
    title.Position = UDim2.fromOffset(14, 9); title.Size = UDim2.new(1, -25, 0, 20)
    title.Font = Enum.Font.GothamBold; title.ZIndex = 101
    local content = makeText(toast, config.Content or "", 11, theme.SubText, theme.Font)
    content.Position = UDim2.fromOffset(14, 31); content.Size = UDim2.new(1, -25, 1, -38)
    content.TextWrapped = true; content.TextYAlignment = Enum.TextYAlignment.Top; content.ZIndex = 101
    table.insert(self._notifications, toast)
    tween(toast, 0.35, { Position = UDim2.new(1, -18, 1, -18) }, Enum.EasingStyle.Back)
    task.delay(config.Duration or 4, function()
        if toast.Parent then
            tween(toast, 0.25, { Position = UDim2.new(1, 350, 1, -18), BackgroundTransparency = 1 })
            task.wait(0.28); toast:Destroy()
        end
    end)
    return toast
end

function UltimateUI:Search(query)
    query = string.lower(query or "")
    for _, item in ipairs(self.Elements) do
        if item.Frame and item.Frame.Parent then
            local name = string.lower(item.Name or item.Frame.Name)
            local visible = query == "" or string.find(name, query, 1, true) ~= nil
            item.Frame.Visible = visible
        end
    end
    for _, tab in ipairs(self.Tabs) do
        for _, section in ipairs(tab.Sections) do
            local any = query == "" or string.find(string.lower(section.Name), query, 1, true) ~= nil
            for _, element in ipairs(section.Elements) do
                if element.Frame then
                    local elementName = string.lower(element.Frame.Name)
                    element.Frame.Visible = query == "" or any or string.find(elementName, query, 1, true) ~= nil
                end
            end
            section.Frame.Visible = query == "" or any or section.Frame.Visible
        end
    end
end

function UltimateUI:SetTheme(theme)
    if type(theme) == "string" then
        assert(PRESETS[theme], "Unknown theme preset: " .. theme)
        self.Theme = merge(DEFAULT_THEME, PRESETS[theme])
        self.Theme.Name = theme
    else
        self.Theme = merge(self.Theme, theme or {})
        self.Theme.Name = "Custom"
    end
    -- Existing instances are refreshed by traversing common UI classes.
    for _, obj in ipairs(self.Gui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            if obj.TextColor3 == DEFAULT_THEME.Text or obj.TextColor3 == self.Theme.Text then obj.TextColor3 = self.Theme.Text end
            if obj:IsA("TextButton") and obj.BackgroundColor3 == DEFAULT_THEME.Surface2 then obj.BackgroundColor3 = self.Theme.Surface2 end
            obj.Font = self.Theme.Font
        elseif obj:IsA("UIStroke") then
            obj.Color = self.Theme.Border
        end
    end
    self.Main.BackgroundColor3 = self.Theme.Background
    self.Topbar.BackgroundColor3 = self.Theme.Surface
    self.Sidebar.BackgroundColor3 = self.Theme.Surface
    self.Content.BackgroundColor3 = self.Theme.Background
    self.SearchBox.BackgroundColor3 = self.Theme.Surface
    self.SearchBox.TextColor3 = self.Theme.Text
    for _, tab in ipairs(self.Tabs) do
        tab.Button.BackgroundColor3 = tab.Active and self.Theme.AccentDark or self.Theme.Surface2
        tab.Button.TextColor3 = self.Theme.Text
    end
end

function UltimateUI:GetTheme()
    return copyTable(self.Theme)
end

function UltimateUI:CreateThemeEditor(tab)
    tab = tab or self:CreateTab("Appearance", "palette")
    local section = tab:CreateSection("Theme")
    section:CreateDropdown({
        Name = "Preset",
        Options = { "Midnight", "Ocean", "Forest", "Light", "Rose" },
        Default = self.Theme.Name,
        Callback = function(name) self:SetTheme(name) end,
    })
    for _, key in ipairs({ "Background", "Surface", "Accent", "Text", "SubText", "Border" }) do
        section:CreateColorPicker({
            Name = key, Default = self.Theme[key],
            Callback = function(color)
                self:SetTheme({ [key] = color })
            end,
        })
    end
    section:CreateSlider({
        Name = "Corner radius", Min = 0, Max = 18, Step = 1,
        Default = self.Theme.CornerRadius,
        Callback = function(value) self:SetTheme({ CornerRadius = value }) end,
    })
    return tab
end

function UltimateUI:ExportConfig()
    local data = {
        Theme = {},
        Window = {
            Position = { self.Main.Position.X.Scale, self.Main.Position.X.Offset,
                self.Main.Position.Y.Scale, self.Main.Position.Y.Offset },
            Size = { self.Main.Size.X.Offset, self.Main.Size.Y.Offset },
        },
    }
    for key, value in pairs(self.Theme) do
        if typeof(value) == "Color3" then
            data.Theme[key] = { value.R, value.G, value.B }
        elseif typeof(value) ~= "EnumItem" then
            data.Theme[key] = value
        end
    end
    return HttpService:JSONEncode(data)
end

function UltimateUI:ImportConfig(json)
    local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
    if not ok or type(data) ~= "table" then return false, "Invalid config JSON" end
    local theme = {}
    for key, value in pairs(data.Theme or {}) do
        if type(value) == "table" and #value == 3 then
            theme[key] = Color3.new(value[1], value[2], value[3])
        else theme[key] = value end
    end
    self:SetTheme(theme)
    local w = data.Window
    if w and w.Position and w.Size then
        self.Main.Position = UDim2.new(w.Position[1], w.Position[2], w.Position[3], w.Position[4])
        self.Main.Size = UDim2.fromOffset(w.Size[1], w.Size[2])
    end
    return true
end

function UltimateUI:Minimize()
    self.Minimized = not self.Minimized
    self.Body.Visible = not self.Minimized
    tween(self.Main, 0.2, { Size = self.Minimized and UDim2.new(self.Main.Size.X.Scale, self.Main.Size.X.Offset, 0, 48)
        or UDim2.new(self.Main.Size.X.Scale, self.Main.Size.X.Offset, 0, self.Options.Size and self.Options.Size.Y.Offset or 490) })
end

function UltimateUI:Show()
    self.Visible = true
    self.Gui.Enabled = true
    self.Main.Visible = true
end

function UltimateUI:Hide()
    self.Visible = false
    self.Gui.Enabled = false
end

function UltimateUI:Toggle()
    if self.Visible then self:Hide() else self:Show() end
end

function UltimateUI:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    disconnectAll(self.Connections)
    for _, toast in ipairs(self._notifications) do
        if toast and toast.Parent then toast:Destroy() end
    end
    if self.Gui then self.Gui:Destroy() end
    table.clear(self.Tabs)
    table.clear(self.Elements)
end

UltimateUI.Themes = PRESETS
UltimateUI.Version = "2.0.0"

return UltimateUI
