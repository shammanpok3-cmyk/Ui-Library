--!strict
-- UltimateUI | Roblox Studio-compatible client UI framework
-- Place this ModuleScript in ReplicatedStorage. Require it from a LocalScript.
-- No executor APIs, injection, or external dependencies are used.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local UltimateUI = {}
UltimateUI.__index = UltimateUI

-- Forward declarations for the internal class tables.
local Window, Tab, Section

local DEFAULT_THEME = {
    Background = Color3.fromRGB(17, 18, 25),
    Surface = Color3.fromRGB(25, 27, 37),
    SurfaceAlt = Color3.fromRGB(32, 35, 47),
    Accent = Color3.fromRGB(155, 110, 255),
    AccentAlt = Color3.fromRGB(105, 190, 255),
    Text = Color3.fromRGB(245, 245, 250),
    MutedText = Color3.fromRGB(155, 160, 175),
    Border = Color3.fromRGB(58, 61, 78),
    Success = Color3.fromRGB(90, 210, 145),
    Warning = Color3.fromRGB(255, 190, 85),
    Danger = Color3.fromRGB(245, 95, 110),
    CornerRadius = 10,
    Transparency = 0,
    AnimationSpeed = 0.18,
    Font = Enum.Font.Gotham,
    TextSize = 13,
    Scale = 1,
}

local function copyTable(source)
    local result = {}
    for k, v in pairs(source) do
        result[k] = type(v) == "table" and copyTable(v) or v
    end
    return result
end

local function make(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local function stroke(parent, color, transparency)
    return make("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = 1,
    }, parent)
end

local function tween(object, duration, properties)
    local info = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local animation = TweenService:Create(object, info, properties)
    animation:Play()
    return animation
end

local function round(n)
    return math.floor(n + 0.5)
end

local function toHex(color)
    return string.format("#%02X%02X%02X",
        round(color.R * 255), round(color.G * 255), round(color.B * 255))
end

local function fromHex(value)
    local hex = tostring(value):gsub("#", "")
    if #hex ~= 6 then return nil end
    local r, g, b = tonumber(hex:sub(1,2),16), tonumber(hex:sub(3,4),16), tonumber(hex:sub(5,6),16)
    if not r or not g or not b then return nil end
    return Color3.fromRGB(r,g,b)
end

local function createText(parent, text, size, color, font)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        TextColor3 = color,
        Font = font or Enum.Font.Gotham,
        TextSize = size or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 18),
        RichText = false,
    }, parent)
end

function UltimateUI.new(options)
    options = options or {}
    local self = setmetatable({}, UltimateUI)
    self.Theme = copyTable(DEFAULT_THEME)
    for key, value in pairs(options.Theme or {}) do self.Theme[key] = value end
    self.Title = options.Title or "UltimateUI"
    self.Subtitle = options.Subtitle or "Custom interface framework"
    self.Destroyed = false
    self.Windows = {}
    self.Connections = {}
    self.Keybinds = {}
    self._config = {}
    self._screenGui = nil
    self:_createRoot(options.Parent)
    return self
end

function UltimateUI:_track(connection)
    table.insert(self.Connections, connection)
    return connection
end

function UltimateUI:_createRoot(parent)
    local player = Players.LocalPlayer
    local guiParent = parent or (player and player:WaitForChild("PlayerGui"))
    assert(guiParent, "UltimateUI must be created on the client with a PlayerGui parent")
    local gui = make("ScreenGui", {
        Name = "UltimateUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, guiParent)
    self._screenGui = gui
end

function UltimateUI:GetTheme()
    return copyTable(self.Theme)
end

function UltimateUI:SetTheme(changes)
    for key, value in pairs(changes or {}) do
        if self.Theme[key] ~= nil then self.Theme[key] = value end
    end
    for _, window in ipairs(self.Windows) do
        window:RefreshTheme()
    end
end

function UltimateUI:CreateThemeEditor(section)
    section:CreateParagraph("Theme editor", "Edit the live accent, background, surface, and text colors. Changes apply immediately.")
    local colorFields = {"Accent", "Background", "Surface", "Text", "MutedText", "Border"}
    for _, field in ipairs(colorFields) do
        local captured = field
        section:CreateColorPicker({
            Name = captured,
            Default = self.Theme[captured],
            Callback = function(color) self:SetTheme({[captured] = color}) end,
        })
    end
    section:CreateSlider({
        Name = "Corner radius", Min = 0, Max = 24, Default = self.Theme.CornerRadius,
        Callback = function(v) self:SetTheme({CornerRadius = v}) end,
    })
    section:CreateSlider({
        Name = "Animation speed", Min = 0, Max = 0.6, Decimals = 2,
        Default = self.Theme.AnimationSpeed, Callback = function(v) self:SetTheme({AnimationSpeed = v}) end,
    })
    section:CreateSlider({
        Name = "UI scale", Min = 0.75, Max = 1.25, Decimals = 2, Default = self.Theme.Scale,
        Callback = function(v) self:SetTheme({Scale = v}) end,
    })
end

function UltimateUI:Notify(options)
    options = options or {}
    local theme = self.Theme
    local toast = make("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 330, 0, 18),
        Size = UDim2.fromOffset(300, 76),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = theme.Transparency,
        BorderSizePixel = 0,
    }, self._screenGui)
    corner(toast, theme.CornerRadius)
    stroke(toast, theme.Border)
    local accent = make("Frame", {
        Size = UDim2.new(0, 4, 1, -16),
        Position = UDim2.fromOffset(8, 8),
        BackgroundColor3 = options.Color or theme.Accent,
        BorderSizePixel = 0,
    }, toast)
    corner(accent, 3)
    local title = createText(toast, options.Title or "Notification", 14, theme.Text, theme.Font)
    title.Position = UDim2.fromOffset(22, 10)
    title.Size = UDim2.new(1, -34, 0, 20)
    local body = createText(toast, options.Content or "", 12, theme.MutedText, theme.Font)
    body.Position = UDim2.fromOffset(22, 34)
    body.Size = UDim2.new(1, -34, 0, 30)
    body.TextWrapped = true
    tween(toast, theme.AnimationSpeed, {Position = UDim2.new(1, -18, 0, 18)})
    task.delay(options.Duration or 3, function()
        if toast.Parent then
            tween(toast, theme.AnimationSpeed, {Position = UDim2.new(1, 330, 0, 18)})
            task.wait(theme.AnimationSpeed)
            toast:Destroy()
        end
    end)
end

function UltimateUI:CreateWindow(options)
    options = options or {}
    local window = setmetatable({}, {__index = Window})
    window.Library = self
    window.Theme = self.Theme
    window.Tabs = {}
    window.Components = {}
    window.Visible = true
    window.Minimized = false
    window._connections = {}
    window:_build(options)
    table.insert(self.Windows, window)
    return window
end

-- Window implementation
Window = {}
Window.__index = Window

function Window:_build(options)
    local theme = self.Theme
    local width = options.Width or 720
    local height = options.Height or 480
    local frame = make("Frame", {
        Name = "MainWindow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = theme.Transparency,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, self.Library._screenGui)
    corner(frame, theme.CornerRadius)
    stroke(frame, theme.Border)
    self.Frame = frame
    self._originalSize = UDim2.fromOffset(width, height)
    self.Scale = make("UIScale", {Scale = theme.Scale}, frame)

    local top = make("Frame", {
        Name = "Topbar", Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = theme.Surface, BorderSizePixel = 0,
    }, frame)
    self.Topbar = top
    local title = createText(top, options.Title or self.Library.Title, 15, theme.Text, theme.Font)
    title.Position = UDim2.fromOffset(16, 7)
    title.Size = UDim2.new(1, -120, 0, 21)
    local subtitle = createText(top, options.Subtitle or self.Library.Subtitle, 11, theme.MutedText, theme.Font)
    subtitle.Position = UDim2.fromOffset(16, 28)
    subtitle.Size = UDim2.new(1, -120, 0, 16)

    local minimize = make("TextButton", {
        Text = "—", Font = theme.Font, TextSize = 18, TextColor3 = theme.MutedText,
        BackgroundTransparency = 1, Size = UDim2.fromOffset(34, 34),
        Position = UDim2.new(1, -44, 0, 9),
    }, top)
    minimize.Activated:Connect(function() self:SetMinimized(not self.Minimized) end)

    local sidebar = make("ScrollingFrame", {
        Name = "Sidebar", Position = UDim2.fromOffset(0, 52),
        Size = UDim2.new(0, options.SidebarWidth or 160, 1, -52),
        BackgroundColor3 = theme.Surface, BorderSizePixel = 0,
        ScrollBarThickness = 3, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, frame)
    make("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
    make("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, sidebar)
    self.Sidebar = sidebar

    local content = make("Frame", {
        Name = "Content", Position = UDim2.new(0, options.SidebarWidth or 160, 0, 52),
        Size = UDim2.new(1, -(options.SidebarWidth or 160), 1, -52),
        BackgroundTransparency = 1,
    }, frame)
    self.Content = content

    -- Dragging
    local dragging, dragStart, startPos = false, nil, nil
    self.Library:_track(top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, frame.Position
        end
    end))
    self.Library:_track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    self.Library:_track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))

    -- Resize grip
    local grip = make("TextButton", {
        Name = "ResizeGrip", Text = "◢", TextSize = 13, TextColor3 = theme.MutedText,
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1,1),
        Position = UDim2.new(1,0,1,0), Size = UDim2.fromOffset(22,22),
    }, frame)
    local resizing, resizeStart, sizeStart = false, nil, nil
    grip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing, resizeStart, sizeStart = true, input.Position, frame.Size
        end
    end)
    self.Library:_track(UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            frame.Size = UDim2.fromOffset(math.max(420, sizeStart.X.Offset + delta.X), math.max(280, sizeStart.Y.Offset + delta.Y))
        end
    end))
    self.Library:_track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = false end
    end))

    self:_bindSearch(options.Search ~= false)
end

function Window:_bindSearch(enabled)
    if not enabled then return end
    local box = make("TextBox", {
        PlaceholderText = "Search components…", Text = "", ClearTextOnFocus = false,
        Font = self.Theme.Font, TextSize = 12, TextColor3 = self.Theme.Text,
        PlaceholderColor3 = self.Theme.MutedText, BackgroundColor3 = self.Theme.SurfaceAlt,
        BorderSizePixel = 0, Size = UDim2.new(1, -24, 0, 30),
        Position = UDim2.new(0, 12, 1, -42),
    }, self.Frame)
    corner(box, 7)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(box.Text)
        for _, item in ipairs(self.Components) do
            local match = query == "" or string.find(string.lower(item.Name or ""), query, 1, true)
            if item.Object and item.Object.Parent then item.Object.Visible = match end
        end
    end)
end

function Window:RefreshTheme()
    local theme = self.Theme
    self.Frame.BackgroundColor3 = theme.Background
    self.Frame.BackgroundTransparency = theme.Transparency
    self.Scale.Scale = theme.Scale
    self.Topbar.BackgroundColor3 = theme.Surface
    self.Sidebar.BackgroundColor3 = theme.Surface
    for _, component in ipairs(self.Components) do
        if component.Refresh then component:Refresh() end
    end
end

function Window:SetVisible(value)
    self.Visible = value
    if value then
        self.Frame.Visible = true
        self.Frame.Size = UDim2.fromOffset(0, 0)
        tween(self.Frame, self.Theme.AnimationSpeed, {Size = self._originalSize})
    else
        local t = tween(self.Frame, self.Theme.AnimationSpeed, {Size = UDim2.fromOffset(0, 0)})
        t.Completed:Once(function() if not self.Visible then self.Frame.Visible = false end end)
    end
end

function Window:SetMinimized(value)
    self.Minimized = value
    if value then
        tween(self.Frame, self.Theme.AnimationSpeed, {Size = UDim2.fromOffset(self.Frame.AbsoluteSize.X, 52)})
        self.Content.Visible = false
        self.Sidebar.Visible = false
    else
        self.Content.Visible = true
        self.Sidebar.Visible = true
        tween(self.Frame, self.Theme.AnimationSpeed, {Size = self._originalSize})
    end
end

function Window:CreateTab(options)
    options = options or {}
    local tab = setmetatable({
        Window = self, Name = options.Name or "Tab",
        Sections = {}, Buttons = {}, Active = false,
    }, Tab)
    tab:_build()
    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then tab:Select() end
    return tab
end

Tab = {}
Tab.__index = Tab

function Tab:_build()
    local theme = self.Window.Theme
    local button = make("TextButton", {
        Text = self.Name, Font = theme.Font, TextSize = 12,
        TextColor3 = theme.MutedText, TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = theme.Surface, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34), AutoButtonColor = false,
    }, self.Window.Sidebar)
    make("UIPadding", {PaddingLeft = UDim.new(0, 10)}, button)
    local page = make("ScrollingFrame", {
        Name = self.Name, Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 4, Visible = false,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
    }, self.Window.Content)
    make("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    make("UIPadding", {PaddingTop = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14)}, page)
    self.Button, self.Page = button, page
    button.Activated:Connect(function() self:Select() end)
end

function Tab:Select()
    for _, tab in ipairs(self.Window.Tabs) do
        tab.Active = tab == self
        tab.Page.Visible = tab == self
        tween(tab.Button, self.Window.Theme.AnimationSpeed, {
            BackgroundTransparency = tab == self and 0 or 1,
            TextColor3 = tab == self and self.Window.Theme.Text or self.Window.Theme.MutedText,
        })
        if tab == self then tab.Button.BackgroundColor3 = self.Window.Theme.Accent end
    end
end

function Tab:CreateSection(options)
    options = options or {}
    local section = setmetatable({Tab = self, Name = options.Name or "Section", Components = {}}, Section)
    section:_build()
    table.insert(self.Sections, section)
    return section
end

Section = {}
Section.__index = Section

function Section:_build()
    local theme = self.Tab.Window.Theme
    local frame = make("Frame", {
        Name = self.Name, Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = theme.Surface, BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, self.Tab.Page)
    corner(frame, theme.CornerRadius)
    stroke(frame, theme.Border)
    local layout = make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, frame)
    make("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, frame)
    local header = make("TextButton", {
        Text = self.Name .. "  ▾", Font = theme.Font, TextSize = 13,
        TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22),
    }, frame)
    self.Frame, self.Header, self.Collapsed = frame, header, false
    header.Activated:Connect(function()
        self.Collapsed = not self.Collapsed
        for _, child in ipairs(frame:GetChildren()) do
            if child ~= header and child:IsA("GuiObject") then child.Visible = not self.Collapsed end
        end
        header.Text = self.Name .. (self.Collapsed and "  ▸" or "  ▾")
    end)
end

function Section:_component(name, height)
    local theme = self.Tab.Window.Theme
    local object = make("Frame", {
        Name = name, Size = UDim2.new(1, 0, 0, height or 34),
        BackgroundTransparency = 1, BorderSizePixel = 0,
    }, self.Frame)
    local item = {Name = name, Object = object, Theme = theme}
    table.insert(self.Tab.Window.Components, item)
    table.insert(self.Components, item)
    return object, item
end

function Section:CreateLabel(text)
    local object, item = self:_component(text, 24)
    local label = createText(object, text, 13, self.Tab.Window.Theme.Text, self.Tab.Window.Theme.Font)
    label.Size = UDim2.fromScale(1,1)
    item.Refresh = function() label.TextColor3 = self.Tab.Window.Theme.Text end
    return item
end

function Section:CreateParagraph(title, content)
    local object, item = self:_component(title, 54)
    local heading = createText(object, title, 13, self.Tab.Window.Theme.Text, self.Tab.Window.Theme.Font)
    heading.Size = UDim2.new(1,0,0,18)
    local body = createText(object, content, 11, self.Tab.Window.Theme.MutedText, self.Tab.Window.Theme.Font)
    body.Position = UDim2.fromOffset(0, 21)
    body.Size = UDim2.new(1,0,0,32)
    body.TextWrapped = true
    item.Refresh = function()
        heading.TextColor3 = self.Tab.Window.Theme.Text
        body.TextColor3 = self.Tab.Window.Theme.MutedText
    end
    return item
end

function Section:CreateButton(options)
    options = options or {}
    local name = options.Name or "Button"
    local object, item = self:_component(name, 34)
    local theme = self.Tab.Window.Theme
    local button = make("TextButton", {
        Text = name, Font = theme.Font, TextSize = 12, TextColor3 = theme.Text,
        BackgroundColor3 = theme.SurfaceAlt, BorderSizePixel = 0,
        Size = UDim2.fromScale(1,1), AutoButtonColor = false,
    }, object)
    corner(button, theme.CornerRadius)
    button.MouseEnter:Connect(function() tween(button, theme.AnimationSpeed, {BackgroundColor3 = theme.Accent}) end)
    button.MouseLeave:Connect(function() tween(button, theme.AnimationSpeed, {BackgroundColor3 = theme.SurfaceAlt}) end)
    button.Activated:Connect(function()
        tween(button, 0.08, {Size = UDim2.new(1, -4, 1, -2)})
        task.delay(0.08, function() if button.Parent then tween(button, 0.12, {Size = UDim2.fromScale(1,1)}) end end)
        if options.Callback then options.Callback() end
    end)
    item.Refresh = function() button.TextColor3 = self.Tab.Window.Theme.Text end
    return item
end

function Section:CreateToggle(options)
    options = options or {}
    local name, value = options.Name or "Toggle", options.Default == true
    local object, item = self:_component(name, 34)
    local theme = self.Tab.Window.Theme
    local label = createText(object, name, 12, theme.Text, theme.Font)
    label.Size = UDim2.new(1, -60, 1, 0)
    local track = make("TextButton", {
        Text = "", AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,0,0.5,0),
        Size = UDim2.fromOffset(42,22), BackgroundColor3 = value and theme.Accent or theme.SurfaceAlt,
        BorderSizePixel = 0, AutoButtonColor = false,
    }, object)
    corner(track, 20)
    local knob = make("Frame", {
        Size = UDim2.fromOffset(16,16), Position = value and UDim2.new(1,-19,0.5,-8) or UDim2.fromOffset(3,3),
        BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
    }, track)
    corner(knob, 20)
    local function set(v, silent)
        value = v == true
        tween(track, theme.AnimationSpeed, {BackgroundColor3 = value and self.Tab.Window.Theme.Accent or self.Tab.Window.Theme.SurfaceAlt})
        tween(knob, theme.AnimationSpeed, {Position = value and UDim2.new(1,-19,0.5,-8) or UDim2.fromOffset(3,3)})
        if not silent and options.Callback then options.Callback(value) end
    end
    track.Activated:Connect(function() set(not value) end)
    item.Set = set
    item.Get = function() return value end
    item.Refresh = function() set(value, true) end
    return item
end

function Section:CreateSlider(options)
    options = options or {}
    local name, min, max = options.Name or "Slider", options.Min or 0, options.Max or 100
    local value = math.clamp(options.Default or min, min, max)
    local object, item = self:_component(name, 52)
    local theme = self.Tab.Window.Theme
    local label = createText(object, name, 12, theme.Text, theme.Font)
    label.Size = UDim2.new(1, -70, 0, 18)
    local valueLabel = createText(object, tostring(value), 11, theme.MutedText, theme.Font)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Position = UDim2.new(1, -60, 0, 0)
    valueLabel.Size = UDim2.fromOffset(60,18)
    local bar = make("Frame", {Position = UDim2.fromOffset(0,28), Size = UDim2.new(1,0,0,7), BackgroundColor3 = theme.SurfaceAlt, BorderSizePixel = 0}, object)
    corner(bar, 8)
    local fill = make("Frame", {Size = UDim2.new((value-min)/(max-min),0,1,0), BackgroundColor3 = theme.Accent, BorderSizePixel = 0}, bar)
    corner(fill, 8)
    local hit = make("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.new(1,0,0,24), Position = UDim2.new(0,0,0.5,-12)}, bar)
    local function set(v, silent)
        value = math.clamp(v, min, max)
        local decimals = options.Decimals or 0
        local mult = 10 ^ decimals
        value = math.floor(value * mult + 0.5) / mult
        fill.Size = UDim2.new((value-min)/(max-min),0,1,0)
        valueLabel.Text = tostring(value)
        if not silent and options.Callback then options.Callback(value) end
    end
    local function update(input)
        local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        set(min + (max-min)*alpha)
    end
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then update(input) end
    end)
    hit.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then update(input) end
        end
    end)
    item.Set, item.Get = set, function() return value end
    item.Refresh = function() fill.BackgroundColor3 = self.Tab.Window.Theme.Accent end
    return item
end

function Section:CreateInput(options)
    options = options or {}
    local name = options.Name or "Input"
    local object, item = self:_component(name, 36)
    local theme = self.Tab.Window.Theme
    local box = make("TextBox", {
        PlaceholderText = options.Placeholder or name, Text = options.Default or "",
        ClearTextOnFocus = false, Font = theme.Font, TextSize = 12,
        TextColor3 = theme.Text, PlaceholderColor3 = theme.MutedText,
        BackgroundColor3 = theme.SurfaceAlt, BorderSizePixel = 0,
        Size = UDim2.fromScale(1,1), TextXAlignment = Enum.TextXAlignment.Left,
    }, object)
    corner(box, theme.CornerRadius)
    make("UIPadding", {PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10)}, box)
    box.FocusLost:Connect(function(enter)
        if options.Callback then options.Callback(box.Text, enter) end
    end)
    item.Set = function(v) box.Text = tostring(v) end
    item.Get = function() return box.Text end
    return item
end

function Section:CreateDropdown(options)
    options = options or {}
    local name, values = options.Name or "Dropdown", options.Options or {}
    local selected = options.Default
    local object, item = self:_component(name, 36)
    local theme = self.Tab.Window.Theme
    local button = make("TextButton", {
        Text = name .. "  ▾    " .. tostring(selected or "Select"),
        Font = theme.Font, TextSize = 12, TextColor3 = theme.Text,
        BackgroundColor3 = theme.SurfaceAlt, BorderSizePixel = 0,
        Size = UDim2.fromScale(1,1), AutoButtonColor = false,
    }, object)
    corner(button, theme.CornerRadius)
    local popup
    local function choose(v)
        selected = v
        button.Text = name .. "  ▾    " .. tostring(v)
        if popup then popup:Destroy(); popup = nil end
        if options.Callback then options.Callback(v) end
    end
    button.Activated:Connect(function()
        if popup then popup:Destroy(); popup = nil; return end
        popup = make("Frame", {
            Position = UDim2.new(0,0,1,4), Size = UDim2.new(1,0,0,math.min(#values*30,150)),
            BackgroundColor3 = theme.Surface, BorderSizePixel = 0, ZIndex = 20,
        }, object)
        corner(popup, theme.CornerRadius)
        make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, popup)
        for _, v in ipairs(values) do
            local option = make("TextButton", {
                Text = tostring(v), Font = theme.Font, TextSize = 12, TextColor3 = theme.Text,
                BackgroundTransparency = 1, Size = UDim2.new(1,0,0,30), ZIndex = 21,
            }, popup)
            option.Activated:Connect(function() choose(v) end)
        end
    end)
    item.Set = choose
    item.Get = function() return selected end
    return item
end

function Section:CreateKeybind(options)
    options = options or {}
    local name, key, mode = options.Name or "Keybind", options.Default or Enum.KeyCode.RightShift, options.Mode or "Toggle"
    local active, listening = false, false
    local object, item = self:_component(name, 34)
    local theme = self.Tab.Window.Theme
    local label = createText(object, name .. " (" .. mode .. ")", 12, theme.Text, theme.Font)
    label.Size = UDim2.new(1,-110,1,0)
    local button = make("TextButton", {
        Text = key.Name, AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,0,0.5,0),
        Size = UDim2.fromOffset(100,28), BackgroundColor3 = theme.SurfaceAlt,
        TextColor3 = theme.Text, Font = theme.Font, TextSize = 11, BorderSizePixel = 0,
    }, object)
    corner(button, 6)
    local function setActive(v)
        active = v
        if options.Callback then options.Callback(active) end
    end
    button.Activated:Connect(function()
        listening = true
        button.Text = "Press a key…"
    end)
    local connection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if listening then
            if input.KeyCode ~= Enum.KeyCode.Unknown then key = input.KeyCode end
            listening = false
            button.Text = key.Name
            return
        end
        if input.KeyCode == key then
            if mode == "Toggle" then setActive(not active)
            elseif mode == "Press" or mode == "Hold" then setActive(true) end
        end
    end)
    local ended = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == key and (mode == "Hold" or mode == "Press") then setActive(false) end
    end)
    table.insert(self.Tab.Window._connections, connection)
    table.insert(self.Tab.Window._connections, ended)
    item.SetMode = function(v)
        assert(v == "Toggle" or v == "Hold" or v == "Press" or v == "Always", "Unsupported keybind mode")
        mode = v
        label.Text = name .. " (" .. mode .. ")"
        if mode == "Always" then setActive(true) end
    end
    item.SetKey = function(v) key = v; button.Text = key.Name end
    item.Get = function() return key, mode, active end
    if mode == "Always" then setActive(true) end
    return item
end

function Section:CreateColorPicker(options)
    options = options or {}
    local name, color = options.Name or "Color", options.Default or Color3.new(1,1,1)
    local object, item = self:_component(name, 36)
    local theme = self.Tab.Window.Theme
    local label = createText(object, name, 12, theme.Text, theme.Font)
    label.Size = UDim2.new(1,-110,1,0)
    local swatch = make("TextButton", {
        Text = toHex(color), TextColor3 = Color3.new(1,1,1), Font = theme.Font, TextSize = 10,
        AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,0,0.5,0),
        Size = UDim2.fromOffset(104,28), BackgroundColor3 = color, BorderSizePixel = 0,
    }, object)
    corner(swatch, 6)
    local function set(v, silent)
        color = v
        swatch.BackgroundColor3 = v
        swatch.Text = toHex(v)
        if not silent and options.Callback then options.Callback(v) end
    end
    swatch.Activated:Connect(function()
        local popup = make("Frame", {
            Position = UDim2.new(1,-220,1,4), Size = UDim2.fromOffset(220,72),
            BackgroundColor3 = theme.Surface, BorderSizePixel = 0, ZIndex = 30,
        }, object)
        corner(popup, theme.CornerRadius)
        local hex = make("TextBox", {
            Text = toHex(color), PlaceholderText = "#RRGGBB", ClearTextOnFocus = false,
            Position = UDim2.fromOffset(8,8), Size = UDim2.new(1,-16,0,28),
            BackgroundColor3 = theme.SurfaceAlt, TextColor3 = theme.Text,
            Font = theme.Font, TextSize = 12, BorderSizePixel = 0, ZIndex = 31,
        }, popup)
        corner(hex, 5)
        local apply = make("TextButton", {
            Text = "Apply", Position = UDim2.fromOffset(8,42), Size = UDim2.new(1,-16,0,22),
            BackgroundColor3 = theme.Accent, TextColor3 = theme.Text,
            Font = theme.Font, TextSize = 11, BorderSizePixel = 0, ZIndex = 31,
        }, popup)
        corner(apply, 5)
        apply.Activated:Connect(function()
            local parsed = fromHex(hex.Text)
            if parsed then set(parsed) end
            popup:Destroy()
        end)
    end)
    item.Set, item.Get = set, function() return color end
    return item
end

function Section:CreateImage(options)
    options = options or {}
    local name = options.Name or "Image"
    local object, item = self:_component(name, options.Height or 130)
    local image = make("ImageLabel", {
        Name = name, Image = options.Image or "", ScaleType = options.ScaleType or Enum.ScaleType.Fit,
        BackgroundColor3 = self.Tab.Window.Theme.SurfaceAlt, BorderSizePixel = 0,
        Size = UDim2.fromScale(1,1),
    }, object)
    corner(image, self.Tab.Window.Theme.CornerRadius)
    if options.Clickable then
        local button = make("TextButton", {Text="", BackgroundTransparency=1, Size=UDim2.fromScale(1,1)}, image)
        button.Activated:Connect(function() if options.Callback then options.Callback() end end)
    end
    item.Image = image
    return item
end

function Section:CreateCharacterPreview(options)
    options = options or {}
    local name = options.Name or "Character preview"
    local object, item = self:_component(name, options.Height or 210)
    local viewport = make("ViewportFrame", {
        BackgroundColor3 = options.Background or self.Tab.Window.Theme.SurfaceAlt,
        BorderSizePixel = 0, Size = UDim2.fromScale(1,1),
        Ambient = Color3.fromRGB(180,180,180), LightColor = Color3.new(1,1,1),
        LightDirection = Vector3.new(-1,-1,-1),
    }, object)
    corner(viewport, self.Tab.Window.Theme.CornerRadius)
    local world = Instance.new("WorldModel")
    world.Parent = viewport
    local camera = Instance.new("Camera")
    camera.Parent = viewport
    viewport.CurrentCamera = camera
    local model = options.Model
    if model then
        local clone = model:Clone()
        clone.Parent = world
        local cf, size = clone:GetBoundingBox()
        local maxAxis = math.max(size.X, size.Y, size.Z)
        camera.CFrame = CFrame.new(cf.Position + Vector3.new(0, size.Y * 0.1, maxAxis * 2.2), cf.Position)
        item.Model = clone
    else
        local hint = createText(viewport, "Pass a character Model to preview it", 11, self.Tab.Window.Theme.MutedText)
        hint.TextXAlignment = Enum.TextXAlignment.Center
        hint.Size = UDim2.fromScale(1,1)
    end
    local rotation = 0
    local dragging, lastX = false, 0
    viewport.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging, lastX = true, input.Position.X end
    end)
    viewport.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    viewport.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and item.Model then
            rotation += (input.Position.X-lastX)*0.01
            lastX = input.Position.X
            local cf, size = item.Model:GetBoundingBox()
            item.Model:PivotTo(CFrame.new(cf.Position) * CFrame.Angles(0,rotation,0))
        end
    end)
    item.SetModel = function(newModel)
        for _, child in ipairs(world:GetChildren()) do child:Destroy() end
        local clone = newModel:Clone()
        clone.Parent = world
        local cf, size = clone:GetBoundingBox()
        camera.CFrame = CFrame.new(cf.Position + Vector3.new(0,size.Y*0.1,math.max(size.X,size.Y,size.Z)*2.2), cf.Position)
        item.Model = clone
    end
    return item
end

function Section:CreateProgressBar(options)
    options = options or {}
    local name, value = options.Name or "Progress", options.Default or 0
    local object, item = self:_component(name, 42)
    local theme = self.Tab.Window.Theme
    local label = createText(object, name .. "  " .. tostring(value) .. "%", 11, theme.Text, theme.Font)
    label.Size = UDim2.new(1,0,0,16)
    local bar = make("Frame", {Position=UDim2.fromOffset(0,23),Size=UDim2.new(1,0,0,8),BackgroundColor3=theme.SurfaceAlt,BorderSizePixel=0}, object)
    corner(bar, 8)
    local fill = make("Frame", {Size=UDim2.new(math.clamp(value/100,0,1),0,1,0),BackgroundColor3=theme.Accent,BorderSizePixel=0}, bar)
    corner(fill, 8)
    item.Set = function(v)
        value = math.clamp(v,0,100)
        label.Text = name .. "  " .. tostring(round(value)) .. "%"
        tween(fill, theme.AnimationSpeed, {Size=UDim2.new(value/100,0,1,0)})
    end
    return item
end

function UltimateUI:ExportConfig()
    local config = {Theme = {}}
    for key, value in pairs(self.Theme) do
        if typeof(value) == "Color3" then config.Theme[key] = toHex(value)
        elseif typeof(value) == "EnumItem" then config.Theme[key] = value.Name
        else config.Theme[key] = value end
    end
    return config
end

function UltimateUI:ImportConfig(config)
    assert(type(config) == "table" and type(config.Theme) == "table", "Invalid UltimateUI config")
    local changes = {}
    for key, value in pairs(config.Theme) do
        if self.Theme[key] ~= nil then
            if typeof(self.Theme[key]) == "Color3" and type(value) == "string" then
                changes[key] = fromHex(value) or self.Theme[key]
            else
                changes[key] = value
            end
        end
    end
    self:SetTheme(changes)
end

function Window:Destroy()
    for _, connection in ipairs(self._connections) do connection:Disconnect() end
    if self.Frame then self.Frame:Destroy() end
end

function UltimateUI:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    for _, connection in ipairs(self.Connections) do connection:Disconnect() end
    for _, window in ipairs(self.Windows) do window:Destroy() end
    if self._screenGui then self._screenGui:Destroy() end
end

return UltimateUI
