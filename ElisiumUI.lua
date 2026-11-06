local ElisiumUI = {}
ElisiumUI.__index = ElisiumUI

ElisiumUI.Theme = {
    Background = Color3.fromRGB(10, 10, 10),
    Main = Color3.fromRGB(18, 18, 18),
    Panel = Color3.fromRGB(14, 14, 14),
    Text = Color3.fromRGB(224, 212, 214),
    Muted = Color3.fromRGB(130, 130, 130),
    Accent = Color3.fromRGB(166, 93, 103),
    Border = Color3.fromRGB(35, 30, 31)
}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local function create(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(object, radius)
    create("UICorner", {CornerRadius = UDim.new(0, radius or 4)}, object)
end

local function stroke(object, color, thickness)
    create("UIStroke", {
        Color = color or ElisiumUI.Theme.Border,
        Thickness = thickness or 1,
        Transparency = 0
    }, object)
end

local function label(parent, text, size, color, font)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        TextColor3 = color or ElisiumUI.Theme.Text,
        TextSize = size or 13,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 0, 20)
    }, parent)
end

local function tween(object, properties, duration)
    TweenService:Create(object, TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play()
end

local function makeDraggable(handle, target)
    local dragging, dragStart, startPosition
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

function ElisiumUI.new(config)
    config = config or {}
    local self = setmetatable({}, ElisiumUI)
    self.Theme = table.clone(ElisiumUI.Theme)
    for key, value in pairs(config.Theme or {}) do
        self.Theme[key] = value
    end
    self.Toggles = {}
    self.Options = {}
    self.Tabs = {}
    self.Unloaded = false

    local player = Players.LocalPlayer
    local gui = create("ScreenGui", {
        Name = config.Name or "ElisiumUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, player:WaitForChild("PlayerGui"))
    self.ScreenGui = gui

    local window = create("Frame", {
        Name = "Window",
        Size = config.Size or UDim2.fromOffset(620, 440),
        Position = config.Position or UDim2.new(0.5, -310, 0.5, -220),
        BackgroundColor3 = self.Theme.Main,
        BorderSizePixel = 0
    }, gui)
    corner(window, 5)
    stroke(window, self.Theme.Border)
    self.Window = window

    local top = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0
    }, window)
    corner(top, 5)
    local title = label(top, config.Title or "Elisium", 14, self.Theme.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(14, 0)
    title.Size = UDim2.new(1, -60, 1, 0)
    self.TitleLabel = title
    makeDraggable(top, window)

    local close = create("TextButton", {
        Text = "×",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = self.Theme.Muted,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(34, 34),
        Position = UDim2.new(1, -38, 0, 2)
    }, top)
    close.MouseButton1Click:Connect(function() self:Unload() end)

    local tabBar = create("ScrollingFrame", {
        Name = "Tabs",
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 38),
        Size = UDim2.new(1, 0, 0, 34),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ScrollBarThickness = 0
    }, window)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 4),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder
    }, tabBar)
    create("UIPadding", {PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9)}, tabBar)
    self.TabBar = tabBar

    local content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 82),
        Size = UDim2.new(1, -20, 1, -92)
    }, window)
    self.Content = content

    if config.ToggleKey then
        self.ToggleKey = config.ToggleKey
        UIS.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == self.ToggleKey then
                window.Visible = not window.Visible
            end
        end)
    end
    return self
end

function ElisiumUI:SetTheme(theme)
    for key, value in pairs(theme or {}) do
        self.Theme[key] = value
    end
    for _, object in ipairs(self.ScreenGui:GetDescendants()) do
        if object:GetAttribute("ElisiumRole") then
            local role = object:GetAttribute("ElisiumRole")
            if self.Theme[role] then
                if object:IsA("TextLabel") or object:IsA("TextButton") then
                    object.TextColor3 = self.Theme[role]
                elseif object:IsA("Frame") then
                    object.BackgroundColor3 = self.Theme[role]
                end
            end
        end
    end
end

function ElisiumUI:AddTab(name)
    local tab = {Name = name, Groupboxes = {}}
    local button = create("TextButton", {
        Name = name .. "Tab",
        Text = string.lower(name),
        TextSize = 12,
        Font = Enum.Font.GothamSemibold,
        TextColor3 = self.Theme.Muted,
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(math.max(74, #name * 8 + 22), 26),
        AutoButtonColor = false
    }, self.TabBar)
    corner(button, 3)

    local page = create("ScrollingFrame", {
        Name = name .. "Page",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.Accent
    }, self.Content)
    local columns = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    }, page)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalFlex = Enum.UIFlexAlignment.Fill
    }, columns)

    function tab:_select()
        for _, other in ipairs(self.Library.Tabs) do
            other.Page.Visible = false
            tween(other.Button, {TextColor3 = self.Library.Theme.Muted, BackgroundColor3 = self.Library.Theme.Background})
        end
        page.Visible = true
        tween(button, {TextColor3 = self.Library.Theme.Text, BackgroundColor3 = self.Library.Theme.Panel})
    end
    tab.Library, tab.Button, tab.Page, tab.Columns = self, button, page, columns
    table.insert(self.Tabs, tab)
    button.MouseButton1Click:Connect(function() tab:_select() end)
    if #self.Tabs == 1 then tab:_select() end
    return tab
end

function ElisiumUI:_addGroupbox(tab, name, side)
    local box = {Name = name, Controls = {}}
    local parent = tab.Columns
    local column = parent:FindFirstChild(side == "Right" and "RightColumn" or "LeftColumn")
    if not column then
        column = create("Frame", {
            Name = side == "Right" and "RightColumn" or "LeftColumn",
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y
        }, parent)
        create("UIListLayout", {Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder}, column)
    end
    local frame = create("Frame", {
        BackgroundColor3 = self.Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
        AutomaticSize = Enum.AutomaticSize.Y
    }, column)
    corner(frame, 4)
    stroke(frame, self.Theme.Border)
    local heading = label(frame, string.lower(name), 12, self.Theme.Accent, Enum.Font.GothamBold)
    heading.Position = UDim2.fromOffset(10, 5)
    heading.Size = UDim2.new(1, -20, 0, 22)
    local holder = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(9, 30),
        Size = UDim2.new(1, -18, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    }, frame)
    create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, holder)
    create("UIPadding", {PaddingBottom = UDim.new(0, 9)}, holder)
    box.Frame, box.Container = frame, holder
    return box
end

function ElisiumUI:AddGroupbox(name)
    return self:_addGroupbox(self, name, "Left")
end

function ElisiumUI:AddLeftGroupbox(name)
    return self:_addGroupbox(self, name, "Left")
end

function ElisiumUI:AddRightGroupbox(name)
    return self:_addGroupbox(self, name, "Right")
end

local function controlRow(box, height)
    local row = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height or 28)
    }, box.Container)
    return row
end

function ElisiumUI:_addToggle(box, id, info)
    info = info or {}
    local value = info.Default == true
    local row = controlRow(box, 28)
    local text = label(row, info.Text or id, 12, self.Theme.Text)
    text.Size = UDim2.new(1, -48, 1, 0)
    local switch = create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = value and self.Theme.Accent or self.Theme.Background,
        Position = UDim2.new(1, -38, 0.5, -9),
        Size = UDim2.fromOffset(36, 18),
        BorderSizePixel = 0
    }, row)
    corner(switch, 9)
    local knob = create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.fromOffset(12, 12),
        Position = value and UDim2.new(1, -15, 0.5, -6) or UDim2.fromOffset(3, 3),
        BorderSizePixel = 0
    }, switch)
    corner(knob, 8)
    local option = {Value = value, Type = "Toggle"}
    function option:SetValue(nextValue)
        value = not not nextValue
        self.Value = value
        tween(switch, {BackgroundColor3 = value and self.Library.Theme.Accent or self.Library.Theme.Background})
        tween(knob, {Position = value and UDim2.new(1, -15, 0.5, -6) or UDim2.fromOffset(3, 3)})
        if info.Callback then info.Callback(value) end
    end
    option.Library = self
    switch.MouseButton1Click:Connect(function() option:SetValue(not value) end)
    self.Toggles[id] = option
    self.Options[id] = option
    table.insert(box.Controls, option)
    return option
end

function ElisiumUI:_addButton(box, text, callback)
    local row = controlRow(box, 30)
    local button = create("TextButton", {
        Text = text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = self.Theme.Text,
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        AutoButtonColor = false
    }, row)
    corner(button, 3)
    stroke(button, self.Theme.Border)
    button.MouseEnter:Connect(function() tween(button, {BackgroundColor3 = self.Theme.Accent}) end)
    button.MouseLeave:Connect(function() tween(button, {BackgroundColor3 = self.Theme.Background}) end)
    button.MouseButton1Click:Connect(function() if callback then callback() end end)
    return button
end

function ElisiumUI:_addLabel(box, text)
    local row = controlRow(box, 22)
    return label(row, text, 11, self.Theme.Muted)
end

function ElisiumUI:_addDivider(box)
    local row = controlRow(box, 8)
    create("Frame", {
        BackgroundColor3 = self.Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1)
    }, row)
end

function ElisiumUI:_addSlider(box, id, info)
    info = info or {}
    local min, max = info.Min or 0, info.Max or 100
    local value = math.clamp(info.Default or min, min, max)
    local row = controlRow(box, 48)
    local title = label(row, info.Text or id, 12, self.Theme.Text)
    title.Size = UDim2.new(1, -55, 0, 19)
    local valueText = label(row, tostring(value) .. (info.Suffix or ""), 11, self.Theme.Muted)
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Position = UDim2.new(1, -55, 0, 0)
    valueText.Size = UDim2.fromOffset(55, 19)
    local track = create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 27),
        Size = UDim2.new(1, 0, 0, 5)
    }, row)
    corner(track, 4)
    local fill = create("Frame", {
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new((value - min) / math.max(max - min, 0.0001), 0, 1, 0)
    }, track)
    corner(fill, 4)
    local option = {Value = value, Type = "Slider", Library = self}
    local function setFromX(x)
        local ratio = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local nextValue = min + (max - min) * ratio
        local rounding = info.Rounding
        if rounding ~= nil then
            local factor = 10 ^ rounding
            nextValue = math.floor(nextValue * factor + 0.5) / factor
        end
        value, option.Value = nextValue, nextValue
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        valueText.Text = tostring(nextValue) .. (info.Suffix or "")
        if info.Callback then info.Callback(nextValue) end
    end
    local sliding = false
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            setFromX(input.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = false end
    end)
    function option:SetValue(v)
        setFromX(track.AbsolutePosition.X + track.AbsoluteSize.X * ((math.clamp(v, min, max) - min) / math.max(max - min, 0.0001)))
    end
    self.Options[id] = option
    table.insert(box.Controls, option)
    return option
end

function ElisiumUI:_addDropdown(box, id, info)
    info = info or {}
    local values = info.Values or {}
    local selected = info.Default or values[1] or ""
    local row = controlRow(box, 48)
    label(row, info.Text or id, 12, self.Theme.Text).Size = UDim2.new(1, 0, 0, 18)
    local button = create("TextButton", {
        Text = tostring(selected) .. "  ▾",
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextColor3 = self.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 21),
        Size = UDim2.new(1, 0, 0, 25)
    }, row)
    corner(button, 3)
    local option = {Value = selected, Type = "Dropdown", Library = self}
    local popup
    local function close()
        if popup then popup:Destroy(); popup = nil end
    end
    button.MouseButton1Click:Connect(function()
        if popup then close(); return end
        popup = create("Frame", {
            BackgroundColor3 = self.Theme.Main,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, 3),
            Size = UDim2.new(1, 0, 0, math.min(#values * 25, 125)),
            ZIndex = 20
        }, button)
        corner(popup, 3)
        stroke(popup, self.Theme.Border)
        local list = create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(0, 0, 0, #values * 25),
            ScrollBarThickness = 3,
            ZIndex = 21
        }, popup)
        for index, item in ipairs(values) do
            local choice = create("TextButton", {
                Text = tostring(item),
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextColor3 = self.Theme.Text,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(4, (index - 1) * 25),
                Size = UDim2.new(1, -8, 0, 25),
                ZIndex = 22
            }, list)
            choice.MouseButton1Click:Connect(function()
                selected, option.Value = item, item
                button.Text = tostring(item) .. "  ▾"
                close()
                if info.Callback then info.Callback(item) end
            end)
        end
    end)
    function option:SetValue(v)
        selected, self.Value = v, v
        button.Text = tostring(v) .. "  ▾"
        if info.Callback then info.Callback(v) end
    end
    self.Options[id] = option
    table.insert(box.Controls, option)
    return option
end

function ElisiumUI:_addInput(box, id, info)
    info = info or {}
    local row = controlRow(box, 48)
    label(row, info.Text or id, 12, self.Theme.Text).Size = UDim2.new(1, 0, 0, 18)
    local input = create("TextBox", {
        Text = info.Default or "",
        PlaceholderText = info.Placeholder or "",
        ClearTextOnFocus = info.ClearTextOnFocus == true,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextColor3 = self.Theme.Text,
        PlaceholderColor3 = self.Theme.Muted,
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 21),
        Size = UDim2.new(1, 0, 0, 25)
    }, row)
    corner(input, 3)
    local option = {Value = input.Text, Type = "Input", Library = self}
    input.FocusLost:Connect(function()
        option.Value = input.Text
        if info.Callback then info.Callback(input.Text) end
    end)
    function option:SetValue(v)
        input.Text = tostring(v)
        self.Value = input.Text
        if info.Callback then info.Callback(input.Text) end
    end
    self.Options[id] = option
    table.insert(box.Controls, option)
    return option
end

function ElisiumUI:_addColorPicker(box, id, info)
    info = info or {}
    local row = controlRow(box, 28)
    label(row, info.Title or info.Text or id, 12, self.Theme.Text).Size = UDim2.new(1, -44, 1, 0)
    local color = info.Default or self.Theme.Accent
    local swatch = create("TextButton", {
        Text = "",
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -34, 0.5, -9),
        Size = UDim2.fromOffset(34, 18),
        AutoButtonColor = false
    }, row)
    corner(swatch, 3)
    local option = {Value = color, Type = "ColorPicker", Library = self}
    swatch.MouseButton1Click:Connect(function()
        local h, s, v = Color3.toHSV(color)
        color = Color3.fromHSV((h + 0.08) % 1, math.max(s, 0.7), math.max(v, 0.75))
        option.Value = color
        swatch.BackgroundColor3 = color
        if info.Callback then info.Callback(color) end
    end)
    function option:SetValue(v)
        color, self.Value = v, v
        swatch.BackgroundColor3 = v
        if info.Callback then info.Callback(v) end
    end
    self.Options[id] = option
    table.insert(box.Controls, option)
    return option
end

function ElisiumUI:_addKeyPicker(box, id, info)
    info = info or {}
    local row = controlRow(box, 28)
    label(row, info.Text or id, 12, self.Theme.Text).Size = UDim2.new(1, -80, 1, 0)
    local key = info.Default or Enum.KeyCode.RightShift
    local waiting = false
    local button = create("TextButton", {
        Text = key.Name,
        TextSize = 10,
        Font = Enum.Font.GothamSemibold,
        TextColor3 = self.Theme.Text,
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -76, 0.5, -10),
        Size = UDim2.fromOffset(76, 20)
    }, row)
    corner(button, 3)
    local option = {Value = key, Type = "KeyPicker", Library = self}
    button.MouseButton1Click:Connect(function()
        waiting = true
        button.Text = "..."
    end)
    UIS.InputBegan:Connect(function(input, processed)
        if waiting and input.UserInputType == Enum.UserInputType.Keyboard then
            waiting = false
            key, option.Value = input.KeyCode, input.KeyCode
            button.Text = key.Name
            if info.Callback then info.Callback(key) end
        elseif not processed and key and input.KeyCode == key and info.ChangedCallback then
            info.ChangedCallback(true)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.KeyCode == key and info.ChangedCallback then info.ChangedCallback(false) end
    end)
    function option:SetValue(v)
        key, self.Value = v, v
        button.Text = v.Name
    end
    self.Options[id] = option
    table.insert(box.Controls, option)
    return option
end

local function attachGroupboxMethods(lib, box)
    function box:AddToggle(id, info) return lib:_addToggle(self, id, info) end
    function box:AddButton(text, callback) return lib:_addButton(self, text, callback) end
    function box:AddLabel(text) return lib:_addLabel(self, text) end
    function box:AddDivider() return lib:_addDivider(self) end
    function box:AddSlider(id, info) return lib:_addSlider(self, id, info) end
    function box:AddDropdown(id, info) return lib:_addDropdown(self, id, info) end
    function box:AddInput(id, info) return lib:_addInput(self, id, info) end
    function box:AddColorPicker(id, info) return lib:_addColorPicker(self, id, info) end
    function box:AddKeyPicker(id, info) return lib:_addKeyPicker(self, id, info) end
    function box:SetVisible(visible) self.Frame.Visible = visible end
    return box
end

local originalAddTab = ElisiumUI.AddTab
function ElisiumUI:AddTab(name)
    local tab = originalAddTab(self, name)
    function tab:AddLeftGroupbox(groupName)
        return attachGroupboxMethods(self.Library, self.Library:_addGroupbox(self, groupName, "Left"))
    end
    function tab:AddRightGroupbox(groupName)
        return attachGroupboxMethods(self.Library, self.Library:_addGroupbox(self, groupName, "Right"))
    end
    function tab:AddGroupbox(groupName)
        return self:AddLeftGroupbox(groupName)
    end
    return tab
end

function ElisiumUI:Notify(text, duration)
    local toast = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.fromOffset(230, 48),
        BackgroundColor3 = self.Theme.Panel,
        BorderSizePixel = 0,
        ZIndex = 100
    }, self.ScreenGui)
    corner(toast, 4)
    stroke(toast, self.Theme.Accent)
    local message = label(toast, text, 12, self.Theme.Text)
    message.Position = UDim2.fromOffset(10, 5)
    message.Size = UDim2.new(1, -20, 1, -10)
    task.delay(duration or 3, function()
        if toast.Parent then
            tween(toast, {BackgroundTransparency = 1}, 0.2)
            task.wait(0.22)
            toast:Destroy()
        end
    end)
    return toast
end

function ElisiumUI:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    if self.ScreenGui then self.ScreenGui:Destroy() end
end

return ElisiumUI
