local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local VelonLib = {
    Version = "1.1.5",
    Flags = {},
    Windows = {},
}

local GLOBAL_ENV = (type(getgenv) == "function" and getgenv()) or _G
local previousLibrary = GLOBAL_ENV.__VELONLIB_ACTIVE
if type(previousLibrary) == "table" and type(previousLibrary.DestroyAll) == "function" then
    pcall(function() previousLibrary:DestroyAll() end)
end

local COLORS = {
    Background = Color3.fromRGB(10, 10, 11),
    Surface = Color3.fromRGB(17, 17, 19),
    Surface2 = Color3.fromRGB(24, 24, 27),
    Surface3 = Color3.fromRGB(31, 31, 35),
    Border = Color3.fromRGB(38, 38, 42),
    Text = Color3.fromRGB(244, 244, 245),
    Muted = Color3.fromRGB(153, 153, 164),
    Accent = Color3.fromRGB(255, 255, 255),
    AccentText = Color3.fromRGB(8, 8, 9),
    Danger = Color3.fromRGB(239, 68, 68),
    Success = Color3.fromRGB(74, 222, 128),
}

local ICONS = {
    home = {16898613509, 820, 147}, ["code-2"] = {16898613044, 453, 771},
    ["map-pin"] = {16898613613, 820, 257}, user = {16898613869, 661, 869},
    star = {16898613777, 967, 147}, bell = {16898612819, 820, 257},
    settings = {16898613777, 771, 257}, link = {16898613869, 869, 612},
    minus = {16898613613, 771, 196}, x = {16898613869, 869, 906},
    eye = {16898613353, 771, 563}, crosshair = {16898613044, 453, 869},
    shield = {16898613777, 869, 0}, ["key-round"] = {16898613509, 967, 306},
    palette = {16898613613, 453, 918}, ["sliders-horizontal"] = {16898613777, 820, 355},
    monitor = {16898613613, 404, 820}, smartphone = {16898613777, 257, 918},
    info = {16898613509, 612, 869}, ["circle-help"] = {16898613044, 820, 257},
    search = {16898613699, 918, 857}, users = {16898613869, 967, 98},
    server = {16898613777, 771, 0}, database = {16898613044, 710, 869},
    activity = {16898612629, 514, 771}, zap = {16898613869, 918, 906},
    moon = {16898613613, 306, 918}, sun = {16898613777, 967, 453},
    menu = {16898613613, 49, 820}, ["chevron-down"] = {16898612819, 196, 918},
    check = {16898612819, 710, 869}, copy = {16898613044, 918, 612},
    ["external-link"] = {16898613353, 257, 820}, lock = {16898613869, 771, 710},
    save = {16898613699, 918, 453}, ["trash-2"] = {16898613869, 257, 918},
    ["refresh-cw"] = {16898613699, 404, 869}, power = {16898613699, 820, 147},
}

local function merge(base, extra)
    local result = {}
    for key, value in pairs(type(base) == "table" and base or {}) do result[key] = value end
    for key, value in pairs(type(extra) == "table" and extra or {}) do result[key] = value end
    return result
end

local function preferredTextScale()
    local ok, value = pcall(function() return GuiService.PreferredTextSize end)
    if not ok or not value then return 1 end
    local name = value.Name
    if name == "Large" or name == "Large1" then return 1.06 end
    if name == "Larger" or name == "Larger1" then return 1.12 end
    if name == "Largest" then return 1.18 end
    return 1
end

local function reducedMotionEnabled()
    local ok, value = pcall(function() return GuiService.ReducedMotionEnabled end)
    return ok and value == true
end

local function touchInputPreferred()
    local ok, value = pcall(function() return UserInputService.PreferredInput end)
    if ok and value then return value.Name == "Touch" end
    return UserInputService.TouchEnabled
end

local function create(className, properties, children)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        if key ~= "Parent" then object[key] = value end
    end
    for _, child in ipairs(children or {}) do child.Parent = object end
    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
        local baseSize = properties and properties.TextSize
        if type(baseSize) == "number" then
            object:SetAttribute("VelonBaseTextSize", baseSize)
            object.TextSize = math.floor(baseSize * preferredTextScale() + 0.5)
        end
    end
    if properties and properties.Parent then object.Parent = properties.Parent end
    return object
end

local function corner(radius)
    return create("UICorner", {CornerRadius = UDim.new(0, radius or 8)})
end

local function stroke(color, transparency, thickness)
    return create("UIStroke", {
        Color = color or COLORS.Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function padding(left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0), PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or left or 0), PaddingBottom = UDim.new(0, bottom or top or left or 0),
    })
end

local function tween(object, duration, properties, style, direction)
    if reducedMotionEnabled() then duration = 0.01 end
    local animation = TweenService:Create(object, TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    ), properties)
    animation:Play()
    return animation
end

local function safeCall(callback, ...)
    if type(callback) ~= "function" then return true end
    local ok, resultA, resultB = pcall(callback, ...)
    if not ok then warn("[VelonLib] Callback error: " .. tostring(resultA)) end
    return ok, resultA, resultB
end

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then return result end
    end
    return PlayerGui
end

local function applyIcon(image, icon)
    if typeof(icon) == "number" then
        image.Image = "rbxassetid://" .. tostring(icon)
        image.ImageRectOffset, image.ImageRectSize = Vector2.zero, Vector2.zero
        return true
    end
    if type(icon) == "table" then
        local id = icon.Id or icon[1]
        if id then
            image.Image = tostring(id):find("rbxasset") and tostring(id) or "rbxassetid://" .. tostring(id)
            image.ImageRectSize = icon.Size or Vector2.new(48, 48)
            image.ImageRectOffset = icon.Offset or Vector2.new(icon[2] or 0, icon[3] or 0)
            return true
        end
    end
    if type(icon) == "string" then
        if icon:find("rbxasset") or icon:find("https?://") then
            image.Image = icon
            image.ImageRectOffset, image.ImageRectSize = Vector2.zero, Vector2.zero
            return true
        end
        local data = ICONS[icon:lower()]
        if data then
            image.Image = "rbxassetid://" .. data[1]
            image.ImageRectSize = Vector2.new(48, 48)
            image.ImageRectOffset = Vector2.new(data[2], data[3])
            return true
        end
    end
    local fallback = ICONS["circle-help"]
    image.Image = "rbxassetid://" .. fallback[1]
    image.ImageRectSize = Vector2.new(48, 48)
    image.ImageRectOffset = Vector2.new(fallback[2], fallback[3])
    return false
end

local function makeIcon(parent, icon, size, color, zIndex)
    local image = create("ImageLabel", {
        Parent = parent, BackgroundTransparency = 1, Size = UDim2.fromOffset(size or 18, size or 18),
        ImageColor3 = color or COLORS.Text, ScaleType = Enum.ScaleType.Fit, ZIndex = zIndex or 1,
    })
    applyIcon(image, icon)
    return image
end

local function bindResponsiveScale(screenGui, root, baseWidth, baseHeight)
    local scaler = create("UIScale", {Parent = root, Scale = 1})
    local cameraConnection
    local viewportConnection
    local sizeConnection
    local function update()
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(baseWidth, baseHeight)
        local currentWidth = root.Size.X.Offset > 0 and root.Size.X.Offset + 24 or baseWidth
        local currentHeight = root.Size.Y.Offset > 0 and root.Size.Y.Offset + 24 or baseHeight
        local fitX = (viewport.X - 24) / currentWidth
        local fitY = (viewport.Y - 24) / currentHeight
        scaler.Scale = math.clamp(math.min(fitX, fitY, 1), 0.35, 1)
    end
    local function watchCamera()
        if viewportConnection then viewportConnection:Disconnect() end
        local camera = workspace.CurrentCamera
        if camera then viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(update) end
        update()
    end
    cameraConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
    sizeConnection = root:GetPropertyChangedSignal("Size"):Connect(update)
    watchCamera()
    local cleaned = false
    local function cleanup()
        if cleaned then return end
        cleaned = true
        if cameraConnection then cameraConnection:Disconnect() end
        if viewportConnection then viewportConnection:Disconnect() end
        if sizeConnection then sizeConnection:Disconnect() end
    end
    screenGui.Destroying:Connect(cleanup)
    root.Destroying:Connect(cleanup)
    return scaler, cleanup
end

local function getRequestFunction()
    if type(request) == "function" then return request end
    if type(http_request) == "function" then return http_request end
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    if type(fluxus) == "table" and type(fluxus.request) == "function" then return fluxus.request end
    return nil
end

local function copyText(text)
    if type(setclipboard) == "function" then
        return pcall(setclipboard, tostring(text))
    end
    if type(toclipboard) == "function" then
        return pcall(toclipboard, tostring(text))
    end
    return false
end

local function openDiscord(link)
    local invite = tostring(link or ""):match("discord%.gg/([%w%-_]+)")
        or tostring(link or ""):match("discord%.com/invite/([%w%-_]+)")
    local requestFunction = getRequestFunction()
    if invite and requestFunction then
        local ok, response = pcall(requestFunction, {
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json", Origin = "https://discord.com" },
            Body = HttpService:JSONEncode({
                cmd = "INVITE_BROWSER",
                nonce = HttpService:GenerateGUID(false),
                args = {code = invite},
            }),
        })
        local status = ok and type(response) == "table" and (response.StatusCode or response.Status)
        if ok and (status == 200 or status == 204) then return true, "Discord opened" end
    end
    if copyText(link) then return true, "Link copied" end
    return false, "Executor does not support Discord RPC or clipboard"
end

local function makeScreenGui(name, displayOrder)
    local guiParent = getGuiParent()
    local old = guiParent:FindFirstChild(name)
    local reuseSplash = name == "VelonLib_Splash" and old and old:IsA("ScreenGui")
    local gui
    if reuseSplash then
        gui = old
        gui.Enabled = true
        for _, child in ipairs(gui:GetChildren()) do
            if child:IsA("GuiObject") then child.Visible = false end
        end
        gui.DisplayOrder = displayOrder or 50
    else
        if old then old:Destroy() end
        gui = create("ScreenGui", {
            Name = name, ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = displayOrder or 50,
        })
        gui.Parent = guiParent
    end
    local textPreferenceConnection
    if not reuseSplash then
        local ok = pcall(function()
            textPreferenceConnection = GuiService:GetPropertyChangedSignal("PreferredTextSize"):Connect(function()
                local scale = preferredTextScale()
                for _, item in ipairs(gui:GetDescendants()) do
                    if item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox") then
                        local baseSize = item:GetAttribute("VelonBaseTextSize")
                        if type(baseSize) == "number" then item.TextSize = math.floor(baseSize * scale + 0.5) end
                    end
                end
            end)
        end)
        if ok and textPreferenceConnection then
            gui.Destroying:Connect(function() textPreferenceConnection:Disconnect() end)
        end
    end
    return gui
end

function VelonLib:RegisterIcon(name, data)
    assert(type(name) == "string", "VelonLib:RegisterIcon name must be a string")
    ICONS[name:lower()] = data
end

function VelonLib:GetIcon(name)
    return ICONS[type(name) == "string" and name:lower() or name]
end

function VelonLib:ShowSplash(options)
    options = merge({
        Enabled = true, Duration = 1.8, Title = "VelonLib",
        Subtitle = "Loading interface", Icon = "moon",
    }, options)
    if options.Enabled == false then return end
    local gui = makeScreenGui("VelonLib_Splash", 110)
    local holder = create("CanvasGroup", {
        Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53),
        Size = UDim2.fromOffset(420, 130), BackgroundTransparency = 1,
        GroupTransparency = 1, ZIndex = 20,
    })
    local _, cleanupResponsiveScale = bindResponsiveScale(gui, holder, 450, 160)
    local card = create("Frame", {
        Parent = holder, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 21,
    })
    local cardScale = create("UIScale", {Parent = card, Scale = 0.96})
    local title = create("TextLabel", {
        Parent = card, Position = UDim2.fromOffset(24, 2), Size = UDim2.new(1, -48, 0, 28),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = options.Title,
        TextColor3 = COLORS.Text, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 22,
    })
    local subtitle = create("TextLabel", {
        Parent = card, Position = UDim2.fromOffset(24, 34), Size = UDim2.new(1, -48, 0, 20),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = options.Subtitle,
        TextColor3 = COLORS.Muted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 22,
    })
    local status = create("TextLabel", {
        Parent = card, Position = UDim2.fromOffset(24, 68), Size = UDim2.new(1, -96, 0, 20),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "Preparing interface",
        TextColor3 = COLORS.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22,
    })
    local percentage = create("TextLabel", {
        Parent = card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 68),
        Size = UDim2.fromOffset(52, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
        Text = "0%", TextColor3 = COLORS.Muted, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 22,
    })
    local progressTrack = create("Frame", {
        Parent = card, Position = UDim2.fromOffset(24, 101), Size = UDim2.new(1, -48, 0, 4),
        BackgroundColor3 = COLORS.Surface3, BorderSizePixel = 0, ZIndex = 22,
    }, {corner(3)})
    local progressFill = create("Frame", {
        Parent = progressTrack, Size = UDim2.fromScale(0, 1), BackgroundColor3 = COLORS.Accent,
        BorderSizePixel = 0, ZIndex = 23,
    }, {corner(3)})
    create("UIGradient", {
        Parent = progressFill,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 196)),
    })
    local progressValue = create("NumberValue", {Value = 0})
    local progressConnection = progressValue.Changed:Connect(function(value)
        percentage.Text = tostring(math.floor(value + 0.5)) .. "%"
    end)
    local duration = reducedMotionEnabled() and 0.15 or math.max(tonumber(options.Duration) or 1.8, 0.7)
    title.TextTransparency, subtitle.TextTransparency = 1, 1
    tween(holder, 0.42, {GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5)}, Enum.EasingStyle.Quart)
    tween(cardScale, 0.48, {Scale = 1}, Enum.EasingStyle.Back)
    tween(title, 0.38, {TextTransparency = 0})
    tween(subtitle, 0.46, {TextTransparency = 0})
    tween(progressFill, duration, {Size = UDim2.fromScale(1, 1)}, Enum.EasingStyle.Quart)
    tween(progressValue, duration, {Value = 100}, Enum.EasingStyle.Linear)
    task.delay(duration * 0.42, function()
        if status.Parent then status.Text = "Loading components" end
    end)
    task.delay(duration * 0.78, function()
        if status.Parent then status.Text = "Finalizing session" end
    end)
    task.wait(duration)
    if gui.Parent then
        status.Text = "Ready"
        percentage.Text = "100%"
        task.wait(0.12)
        tween(holder, 0.35, {GroupTransparency = 1, Position = UDim2.fromScale(0.5, 0.47)})
        tween(cardScale, 0.35, {Scale = 0.96})
        task.wait(0.37)
    end
    progressConnection:Disconnect()
    progressValue:Destroy()
    cleanupResponsiveScale()
    if gui.Parent then
        holder.Visible = false
        gui.Enabled = false
    end
end

function VelonLib:CreateKeySystem(options)
    options = merge({
        Title = "VelonLib", Subtitle = "Key System", Icon = "key-round",
        KeyLink = "", Placeholder = "Enter key...", ButtonText = "Verify key",
        GetKeyText = "Discord", Note = "Join the Discord server, get your key, then paste it on the left.", Validate = nil,
        Splash = {Enabled = true, Duration = 1.8},
    }, options)
    assert(type(options.Validate) == "function", "CreateKeySystem requires Validate(key)")

    if type(GLOBAL_ENV.__VELONLIB_CANCEL_KEY_SYSTEM) == "function" then
        pcall(GLOBAL_ENV.__VELONLIB_CANCEL_KEY_SYSTEM)
    end
    GLOBAL_ENV.__VELONLIB_CANCEL_KEY_SYSTEM = nil
    local splashOptions = merge({Enabled = true, Duration = 1.8}, options.Splash)
    splashOptions.Icon = splashOptions.Icon or options.Icon
    splashOptions.Title = splashOptions.Title or options.Title
    splashOptions.Subtitle = splashOptions.Subtitle or "Loading secure access"
    self:ShowSplash(splashOptions)
    local gui = makeScreenGui("VelonLib_KeySystem", 100)
    local dim = create("Frame", {Parent = gui, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1})
    local panel = create("CanvasGroup", {
        Parent = dim, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(586, 352), BackgroundColor3 = COLORS.Background,
        GroupTransparency = 1, Active = true,
    }, {corner(16), stroke(COLORS.Border, 0.35)})
    local keyScale = bindResponsiveScale(gui, panel, 616, 382)
    local topbar = create("Frame", {Parent = panel, Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = COLORS.Surface, BorderSizePixel = 0, ZIndex = 4})
    create("Frame", {Parent = topbar, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = COLORS.Border, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 5})
    local lights = {Color3.fromRGB(255, 95, 86), Color3.fromRGB(255, 189, 46), Color3.fromRGB(39, 201, 63)}
    for index, color in ipairs(lights) do
        create("Frame", {Parent = topbar, Position = UDim2.fromOffset(17 + ((index - 1) * 19), 17), Size = UDim2.fromOffset(11, 11), BackgroundColor3 = color, ZIndex = 6}, {corner(6)})
    end
    local minimizeKey = create("TextButton", {Parent = topbar, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -48, 0, 7), Size = UDim2.fromOffset(34, 30), AutoButtonColor = false, BackgroundColor3 = COLORS.Surface2, Font = Enum.Font.GothamBold, Text = "–", TextColor3 = COLORS.Muted, TextSize = 16, ZIndex = 7}, {corner(8)})
    local closeKey = create("TextButton", {Parent = topbar, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 7), Size = UDim2.fromOffset(34, 30), AutoButtonColor = false, BackgroundColor3 = COLORS.Surface2, Font = Enum.Font.GothamBold, Text = "×", TextColor3 = COLORS.Muted, TextSize = 16, ZIndex = 7}, {corner(8)})

    local dragHandle = create("Frame", {
        Parent = topbar, Size = UDim2.new(1, -96, 1, 0), BackgroundTransparency = 1,
        Active = true, ZIndex = 8,
    })
    local dragging, dragStart, startPosition = false, nil, nil
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPosition = true, input.Position, panel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    local dragConnection = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = (input.Position - dragStart) / keyScale.Scale
            panel.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    gui.Destroying:Connect(function() dragConnection:Disconnect() end)

    create("TextLabel", {Parent = panel, BackgroundTransparency = 1, Position = UDim2.fromOffset(34, 64), Size = UDim2.fromOffset(287, 28), Font = Enum.Font.GothamBold, Text = options.Title, TextColor3 = COLORS.Text, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left})
    create("TextLabel", {Parent = panel, BackgroundTransparency = 1, Position = UDim2.fromOffset(34, 93), Size = UDim2.fromOffset(287, 20), Font = Enum.Font.Gotham, Text = options.Subtitle, TextColor3 = COLORS.Muted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
    create("Frame", {Parent = panel, Position = UDim2.fromOffset(340, 120), Size = UDim2.fromOffset(1, 202), BackgroundColor3 = COLORS.Border, BorderSizePixel = 0})
    create("TextLabel", {Parent = panel, BackgroundTransparency = 1, Position = UDim2.fromOffset(34, 123), Size = UDim2.fromOffset(287, 18), Font = Enum.Font.GothamBold, Text = "KEY", TextColor3 = COLORS.Muted, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left})
    local inputHolder = create("Frame", {Parent = panel, Position = UDim2.fromOffset(34, 146), Size = UDim2.fromOffset(287, 52), BackgroundColor3 = COLORS.Surface2}, {corner(9), stroke(COLORS.Border, 0.55), padding(14, 14, 0, 0)})
    local keyBox = create("TextBox", {Parent = inputHolder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClearTextOnFocus = false, Font = Enum.Font.Gotham, PlaceholderText = options.Placeholder, PlaceholderColor3 = COLORS.Muted, Text = "", TextColor3 = COLORS.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
    local verify = create("TextButton", {Parent = panel, Position = UDim2.fromOffset(34, 208), Size = UDim2.fromOffset(287, 46), AutoButtonColor = false, BackgroundColor3 = COLORS.Accent, Font = Enum.Font.GothamBold, Text = options.ButtonText, TextColor3 = COLORS.AccentText, TextSize = 13}, {corner(9)})
    local status = create("TextLabel", {Parent = panel, BackgroundTransparency = 1, Position = UDim2.fromOffset(34, 271), Size = UDim2.fromOffset(287, 20), Font = Enum.Font.Gotham, Text = "Waiting for key.", TextColor3 = COLORS.Muted, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left})
    create("TextLabel", {Parent = panel, BackgroundTransparency = 1, Position = UDim2.fromOffset(359, 123), Size = UDim2.fromOffset(209, 18), Font = Enum.Font.GothamBold, Text = "NOTE", TextColor3 = COLORS.Muted, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left})
    create("TextLabel", {Parent = panel, BackgroundTransparency = 1, Position = UDim2.fromOffset(359, 146), Size = UDim2.fromOffset(209, 58), Font = Enum.Font.Gotham, Text = options.Note, TextColor3 = COLORS.Muted, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top})
    create("TextLabel", {Parent = panel, BackgroundTransparency = 1, Position = UDim2.fromOffset(359, 224), Size = UDim2.fromOffset(209, 18), Font = Enum.Font.GothamBold, Text = "LINKS", TextColor3 = COLORS.Muted, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left})
    local getKey = create("TextButton", {Parent = panel, Position = UDim2.fromOffset(359, 248), Size = UDim2.fromOffset(209, 46), AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(78, 87, 255), Font = Enum.Font.GothamBold, Text = options.GetKeyText, TextColor3 = Color3.new(1, 1, 1), TextSize = 13}, {corner(9)})

    local finished = Instance.new("BindableEvent")
    local busy = false
    local resolved = false
    local cancelCurrent
    local function clearCancellation()
        if GLOBAL_ENV.__VELONLIB_CANCEL_KEY_SYSTEM == cancelCurrent then
            GLOBAL_ENV.__VELONLIB_CANCEL_KEY_SYSTEM = nil
        end
    end
    local function finish(value)
        if resolved then return end
        resolved = true
        clearCancellation()
        if not gui.Parent then finished:Fire(value) return end
        tween(panel, 0.28, {GroupTransparency = 1})
        tween(panel, 0.28, {Position = UDim2.fromScale(0.5, 0.53)}, Enum.EasingStyle.Quart)
        task.delay(0.3, function()
            if gui and gui.Parent then gui:Destroy() end
            finished:Fire(value)
        end)
    end
    cancelCurrent = function()
        if resolved then return end
        resolved = true
        clearCancellation()
        if gui and gui.Parent then gui:Destroy() end
        finished:Fire(false)
    end
    GLOBAL_ENV.__VELONLIB_CANCEL_KEY_SYSTEM = cancelCurrent
    gui.Destroying:Connect(function()
        if resolved then return end
        resolved = true
        clearCancellation()
        task.defer(function() finished:Fire(false) end)
    end)
    local keyMinimized = false
    minimizeKey.MouseButton1Click:Connect(function()
        keyMinimized = not keyMinimized
        tween(panel, 0.28, {Size = UDim2.fromOffset(586, keyMinimized and 44 or 352)}, Enum.EasingStyle.Quart)
    end)
    closeKey.MouseButton1Click:Connect(function() finish(false) end)
    minimizeKey.MouseEnter:Connect(function() tween(minimizeKey, 0.14, {BackgroundColor3 = COLORS.Surface3, TextColor3 = COLORS.Text}) end)
    minimizeKey.MouseLeave:Connect(function() tween(minimizeKey, 0.14, {BackgroundColor3 = COLORS.Surface2, TextColor3 = COLORS.Muted}) end)
    closeKey.MouseEnter:Connect(function() tween(closeKey, 0.14, {BackgroundColor3 = COLORS.Danger, TextColor3 = Color3.new(1, 1, 1)}) end)
    closeKey.MouseLeave:Connect(function() tween(closeKey, 0.14, {BackgroundColor3 = COLORS.Surface2, TextColor3 = COLORS.Muted}) end)
    local function validate()
        if busy or keyBox.Text == "" then return end
        busy = true
        status.Text, status.TextColor3 = "Checking...", COLORS.Muted
        tween(verify, 0.15, {BackgroundColor3 = COLORS.Surface3, TextColor3 = COLORS.Muted})
        task.spawn(function()
            local ok, result, message = safeCall(options.Validate, keyBox.Text)
            if resolved or not gui.Parent then return end
            local success = ok and (result == true or (type(result) == "table" and result.Success == true))
            local resultMessage = message or (type(result) == "table" and result.Message)
            if success then
                status.Text, status.TextColor3 = resultMessage or "Access granted", COLORS.Success
                task.wait(0.35)
                finish(true)
            else
                status.Text, status.TextColor3 = resultMessage or (ok and "Invalid key" or "Validation failed"), COLORS.Danger
                local currentPosition = panel.Position
                tween(panel, 0.06, {Position = UDim2.new(currentPosition.X.Scale, currentPosition.X.Offset - 7, currentPosition.Y.Scale, currentPosition.Y.Offset)}, Enum.EasingStyle.Linear)
                task.wait(0.06)
                tween(panel, 0.12, {Position = currentPosition}, Enum.EasingStyle.Bounce)
                busy = false
                tween(verify, 0.18, {BackgroundColor3 = COLORS.Accent, TextColor3 = COLORS.AccentText})
            end
        end)
    end
    verify.MouseButton1Click:Connect(validate)
    keyBox.FocusLost:Connect(function(enterPressed) if enterPressed then validate() end end)
    getKey.MouseButton1Click:Connect(function()
        if options.KeyLink ~= "" then
            local success, message = openDiscord(options.KeyLink)
            status.Text = message
            status.TextColor3 = success and COLORS.Success or COLORS.Danger
        end
    end)
    verify.MouseEnter:Connect(function() if not busy then tween(verify, 0.15, {BackgroundColor3 = Color3.fromRGB(220, 220, 224)}) end end)
    verify.MouseLeave:Connect(function() if not busy then tween(verify, 0.15, {BackgroundColor3 = COLORS.Accent}) end end)
    panel.Position = UDim2.fromScale(0.5, 0.53)
    tween(panel, 0.42, {GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5)}, Enum.EasingStyle.Quart)
    local result = finished.Event:Wait()
    clearCancellation()
    finished:Destroy()
    return result
end

local function attachHover(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function() tween(button, 0.16, {BackgroundColor3 = hoverColor}) end)
    button.MouseLeave:Connect(function() tween(button, 0.16, {BackgroundColor3 = normalColor}) end)
end

local function makeLine(parent, color, thickness, zIndex)
    return create("Frame", {
        Parent = parent, AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0,
        BackgroundColor3 = color, Size = UDim2.fromOffset(0, thickness), Visible = false, ZIndex = zIndex or 3,
    })
end

local function setLine(line, pointA, pointB, thickness, visible)
    if not visible then line.Visible = false return end
    local delta = pointB - pointA
    line.Position = UDim2.fromOffset((pointA.X + pointB.X) / 2, (pointA.Y + pointB.Y) / 2)
    line.Size = UDim2.fromOffset(delta.Magnitude, thickness)
    line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    line.Visible = true
end

function VelonLib:CreateWindow(options)
    options = merge({
        Title = "VelonLib", Subtitle = "Modern interface", Icon = "moon",
        Link = "", ToggleKey = Enum.KeyCode.RightShift,
        MainTab = {Name = "Main", Icon = "home"},
        Splash = {Enabled = true, Duration = 1.8, Text = "VelonLib"},
        Theme = {}, Width = 820, Height = 520, Mobile = {Enabled = true, ToggleButton = true},
    }, options)
    options.Width = math.max(tonumber(options.Width) or 820, 640)
    options.Height = math.max(tonumber(options.Height) or 520, 420)
    if type(options.ToggleKey) == "string" then options.ToggleKey = Enum.KeyCode[options.ToggleKey] end
    if typeof(options.ToggleKey) ~= "EnumItem" then options.ToggleKey = Enum.KeyCode.RightShift end
    if options.Splash and options.Splash.Enabled ~= false then
        self:ShowSplash({
            Enabled = true,
            Duration = options.Splash.Duration or 1.6,
            Title = options.Splash.Title or options.Splash.Text or options.Title,
            Subtitle = options.Splash.Subtitle or "Preparing your interface",
        })
    end
    local theme = merge(COLORS, options.Theme)
    local gui = makeScreenGui("VelonLib_UI", 60)
    local window = {
        Gui = gui, Options = options, Theme = theme, Flags = {}, Tabs = {}, Connections = {},
        Destroyed = false, Minimized = false, Visible = true, ESPControllers = {}, Modals = {},
        SplashActive = false,
    }
    table.insert(self.Windows, window)

    local overlay = create("Frame", {Parent = gui, Name = "ESPOverlay", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2})
    local windowHost = create("Frame", {
        Parent = gui, Name = "WindowHost", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(options.Width, options.Height),
        BackgroundTransparency = 1, ZIndex = 20,
    })
    local root = create("CanvasGroup", {
        Parent = windowHost, Name = "Window", Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = theme.Background,
        GroupTransparency = 1, ZIndex = 20,
    }, {corner(14)})
    local scale = bindResponsiveScale(gui, windowHost, options.Width + 24, options.Height + 24)
    window.Host, window.Root, window.Scale, window.Overlay = windowHost, root, scale, overlay

    local topbar = create("Frame", {Parent = root, Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = theme.Surface, BorderSizePixel = 0, ZIndex = 22})
    create("Frame", {Parent = topbar, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = theme.Border, BackgroundTransparency = 0.72, BorderSizePixel = 0, ZIndex = 23})
    local trafficHolder = create("Frame", {Parent = topbar, Position = UDim2.fromOffset(16, 11), Size = UDim2.fromOffset(38, 36), BackgroundTransparency = 1, ZIndex = 23})
    local trafficColors = {Color3.fromRGB(255, 95, 86), Color3.fromRGB(255, 189, 46), Color3.fromRGB(39, 201, 63)}
    for index, color in ipairs(trafficColors) do
        local light = create("Frame", {Parent = trafficHolder, Position = UDim2.fromOffset((index - 1) * 13, 13), Size = UDim2.fromOffset(9, 9), BackgroundColor3 = color, ZIndex = 24}, {corner(5)})
        light.BackgroundTransparency = 0.08
    end
    local titleLabel = create("TextLabel", {Parent = topbar, BackgroundTransparency = 1, Position = UDim2.fromOffset(64, 11), Size = UDim2.new(1, -270, 0, 21), Font = Enum.Font.GothamBold, Text = options.Title, TextColor3 = theme.Text, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 23})
    local subtitleLabel = create("TextLabel", {Parent = topbar, BackgroundTransparency = 1, Position = UDim2.fromOffset(64, 31), Size = UDim2.new(1, -270, 0, 16), Font = Enum.Font.Gotham, Text = options.Subtitle, TextColor3 = theme.Muted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 23})

    local actionHolder = create("Frame", {Parent = topbar, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(168, 34), BackgroundTransparency = 1, ZIndex = 23})
    create("UIListLayout", {Parent = actionHolder, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})
    local function actionButton(icon, order)
        local button = create("TextButton", {Parent = actionHolder, LayoutOrder = order, Size = UDim2.fromOffset(34, 34), AutoButtonColor = false, Text = "", BackgroundColor3 = theme.Surface2, ZIndex = 24}, {corner(8)})
        local image = makeIcon(button, icon, 16, theme.Muted, 25)
        image.AnchorPoint, image.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
        attachHover(button, theme.Surface2, theme.Surface3)
        button.MouseEnter:Connect(function() tween(image, 0.14, {ImageColor3 = theme.Text}) end)
        button.MouseLeave:Connect(function() tween(image, 0.14, {ImageColor3 = theme.Muted}) end)
        return button, image
    end
    local searchButton = actionButton("search", 1)
    local linkButton = actionButton("link", 2)
    local minimizeButton = actionButton("minus", 3)
    local closeButton, closeIcon = actionButton("x", 4)
    closeButton.MouseEnter:Connect(function() tween(closeButton, 0.14, {BackgroundColor3 = theme.Danger}); tween(closeIcon, 0.14, {ImageColor3 = Color3.new(1, 1, 1)}) end)

    local sidebar = create("Frame", {Parent = root, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(0, 64, 1, -58), BackgroundColor3 = theme.Surface, BorderSizePixel = 0, ZIndex = 21})
    create("Frame", {Parent = sidebar, Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = theme.Border, BackgroundTransparency = 0.72, BorderSizePixel = 0, ZIndex = 22})
    local tabList = create("Frame", {Parent = sidebar, Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 1, -24), BackgroundTransparency = 1, ZIndex = 22})
    create("UIListLayout", {Parent = tabList, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder})
    local content = create("Frame", {Parent = root, Position = UDim2.fromOffset(64, 58), Size = UDim2.new(1, -64, 1, -58), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 21})
    local pages = create("Frame", {Parent = content, Position = UDim2.fromOffset(18, 18), Size = UDim2.new(1, -36, 1, -36), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 22})
    window.Sidebar, window.Content, window.Pages, window.BrandIcon = sidebar, content, pages, nil

    local searchPanel = create("CanvasGroup", {
        Parent = root, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 66),
        Size = UDim2.fromOffset(310, 48), BackgroundColor3 = theme.Surface2,
        GroupTransparency = 1, Visible = false, ZIndex = 60,
    }, {corner(10), stroke(theme.Border, 0.4)})
    local searchIcon = makeIcon(searchPanel, "search", 17, theme.Muted, 62)
    searchIcon.AnchorPoint, searchIcon.Position = Vector2.new(0, 0.5), UDim2.new(0, 14, 0.5, 0)
    local searchBox = create("TextBox", {
        Parent = searchPanel, Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -84, 1, 0),
        BackgroundTransparency = 1, ClearTextOnFocus = false, Font = Enum.Font.Gotham,
        PlaceholderText = "Search current tab...", PlaceholderColor3 = theme.Muted,
        Text = "", TextColor3 = theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62,
    })
    local searchClose = create("TextButton", {
        Parent = searchPanel, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(32, 32), BackgroundColor3 = theme.Surface3, AutoButtonColor = false,
        Text = "", ZIndex = 62,
    }, {corner(7)})
    local searchCloseIcon = makeIcon(searchClose, "x", 14, theme.Muted, 63)
    searchCloseIcon.AnchorPoint, searchCloseIcon.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
    window.SearchPanel, window.SearchBox, window.SearchQuery = searchPanel, searchBox, ""

    local mobileOptions = type(options.Mobile) == "table" and options.Mobile or {}
    local mobileToggle = create("TextButton", {
        Parent = gui, Name = "MobileToggle", AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18), Size = UDim2.fromOffset(52, 52),
        BackgroundColor3 = theme.Surface2, AutoButtonColor = false, Text = "",
        Visible = false, ZIndex = 86,
    }, {corner(14), stroke(theme.Border, 0.3)})
    local mobileToggleIcon = makeIcon(mobileToggle, "menu", 21, theme.Text, 87)
    mobileToggleIcon.AnchorPoint, mobileToggleIcon.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
    window.MobileToggle = mobileToggle

    local dragging, dragStart, startPosition
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            window.UserPositioned = true
            dragging, dragStart, startPosition = true, input.Position, windowHost.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    table.insert(window.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = (input.Position - dragStart) / scale.Scale
            windowHost.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end))

    local setTabPreviews
    local function refreshMobileToggle()
        local enabled = options.Mobile ~= false and mobileOptions.Enabled ~= false and mobileOptions.ToggleButton ~= false
        mobileToggle.Visible = enabled and window.MobileMode == true and not window.Visible and not window.Destroyed
    end

    function window:SetMobileMode(enabled)
        self.MobileMode = enabled == true
        self.UserPositioned = false
        local actionSize = self.MobileMode and 38 or 34
        local targetWidth = self.MobileMode and math.min(options.Width, 560) or options.Width
        local targetHeight = self.MobileMode and math.min(options.Height, 360) or options.Height
        if not self.Minimized then windowHost.Size = UDim2.fromOffset(targetWidth, targetHeight) end
        windowHost.Position = UDim2.fromScale(0.5, 0.5)
        actionHolder.Size = UDim2.fromOffset(self.MobileMode and 184 or 168, actionSize)
        for _, item in ipairs(actionHolder:GetChildren()) do
            if item:IsA("GuiButton") then item.Size = UDim2.fromOffset(actionSize, actionSize) end
        end
        for _, tab in ipairs(self.Tabs) do
            if tab.Button then tab.Button.Size = UDim2.fromOffset(self.MobileMode and 46 or 42, self.MobileMode and 46 or 42) end
            for _, panel in ipairs(tab.PreviewPanels or {}) do
                local height = self.MobileMode and math.min(options.Height, 360) or options.Height
                panel.Size = UDim2.fromOffset(280, height)
                local card = panel:FindFirstChildOfClass("Frame")
                if card then card.Size = UDim2.fromOffset(280, height) end
            end
        end
        refreshMobileToggle()
    end

    mobileToggle.MouseButton1Click:Connect(function() window:SetVisible(true) end)
    local preferredInputConnection
    local preferredInputOk = pcall(function()
        preferredInputConnection = UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
            window:SetMobileMode(touchInputPreferred())
        end)
    end)
    if preferredInputOk and preferredInputConnection then table.insert(window.Connections, preferredInputConnection) end

    function window:ApplySearch(query)
        if self.Destroyed then return end
        self.SearchQuery = string.lower(tostring(query or "")):gsub("^%s+", ""):gsub("%s+$", "")
        local tab = self.SelectedTab
        if not tab or not tab.Scroll then return end
        for _, item in ipairs(tab.Scroll:GetChildren()) do
            if item:IsA("GuiObject") then
                local text = item:GetAttribute("VelonSearchText")
                if type(text) == "string" then
                    item.Visible = self.SearchQuery == "" or string.find(text, self.SearchQuery, 1, true) ~= nil
                end
            end
        end
    end

    function window:SetSearchVisible(visible)
        if self.Destroyed then return end
        self.SearchVisible = visible == true
        if self.SearchVisible then
            searchPanel.Visible = true
            tween(searchPanel, 0.16, {GroupTransparency = 0, Position = UDim2.new(1, -14, 0, 66)})
            task.defer(function() if searchBox.Parent then searchBox:CaptureFocus() end end)
        else
            searchBox.Text = ""
            self:ApplySearch("")
            tween(searchPanel, 0.14, {GroupTransparency = 1, Position = UDim2.new(1, -14, 0, 60)})
            task.delay(reducedMotionEnabled() and 0.02 or 0.15, function()
                if searchPanel.Parent and not self.SearchVisible then searchPanel.Visible = false end
            end)
        end
    end

    searchButton.MouseButton1Click:Connect(function() window:SetSearchVisible(not window.SearchVisible) end)
    searchClose.MouseButton1Click:Connect(function() window:SetSearchVisible(false) end)
    searchBox:GetPropertyChangedSignal("Text"):Connect(function() window:ApplySearch(searchBox.Text) end)

    function window:Modal(config)
        if self.Destroyed or not gui.Parent then return end
        config = merge({
            Title = "Confirm action", Content = "", Icon = "circle-help",
            ConfirmText = "Confirm", CancelText = "Cancel", ShowCancel = true,
            DismissOnBackdrop = false,
        }, config)
        local backdrop = create("TextButton", {
            Parent = gui, Name = "Modal", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Active = true, ZIndex = 90,
        })
        local dialog = create("CanvasGroup", {
            Parent = backdrop, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52),
            Size = UDim2.fromOffset(430, 224), BackgroundColor3 = theme.Surface,
            GroupTransparency = 1, ZIndex = 91,
        }, {corner(13), stroke(theme.Border, 0.35)})
        bindResponsiveScale(gui, dialog, 460, 254)
        local iconHolder = create("Frame", {Parent = dialog, Position = UDim2.fromOffset(20, 20), Size = UDim2.fromOffset(38, 38), BackgroundColor3 = theme.Surface3, ZIndex = 92}, {corner(9)})
        local modalIcon = makeIcon(iconHolder, config.Icon, 19, theme.Text, 93)
        modalIcon.AnchorPoint, modalIcon.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
        create("TextLabel", {Parent = dialog, Position = UDim2.fromOffset(70, 18), Size = UDim2.new(1, -90, 0, 27), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = tostring(config.Title), TextColor3 = theme.Text, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 92})
        create("TextLabel", {Parent = dialog, Position = UDim2.fromOffset(70, 46), Size = UDim2.new(1, -90, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "VELONLIB", TextColor3 = theme.Muted, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 92})
        create("TextLabel", {Parent = dialog, Position = UDim2.fromOffset(20, 82), Size = UDim2.new(1, -40, 0, 66), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = tostring(config.Content), TextColor3 = theme.Muted, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 92})
        local buttonRow = create("Frame", {Parent = dialog, Position = UDim2.new(0, 20, 1, -56), Size = UDim2.new(1, -40, 0, 36), BackgroundTransparency = 1, ZIndex = 92})
        create("UIListLayout", {Parent = buttonRow, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})
        local buttonWidth = config.ShowCancel == false and 390 or 128
        local controller = {Root = backdrop, Closed = false}
        local function removeController()
            for index, item in ipairs(window.Modals) do if item == controller then table.remove(window.Modals, index) break end end
        end
        function controller:Close(result)
            if self.Closed then return end
            self.Closed = true
            removeController()
            tween(backdrop, 0.16, {BackgroundTransparency = 1})
            tween(dialog, 0.16, {GroupTransparency = 1, Position = UDim2.fromScale(0.5, 0.48)})
            safeCall(config.Callback, result == true)
            task.delay(reducedMotionEnabled() and 0.02 or 0.17, function() if backdrop.Parent then backdrop:Destroy() end end)
        end
        if config.ShowCancel ~= false then
            local cancel = create("TextButton", {Parent = buttonRow, LayoutOrder = 1, Size = UDim2.fromOffset(buttonWidth, 36), BackgroundColor3 = theme.Surface3, AutoButtonColor = false, Font = Enum.Font.GothamSemibold, Text = tostring(config.CancelText), TextColor3 = theme.Text, TextSize = 12, ZIndex = 93}, {corner(8)})
            attachHover(cancel, theme.Surface3, theme.Border)
            cancel.MouseButton1Click:Connect(function() controller:Close(false) end)
        end
        local confirm = create("TextButton", {Parent = buttonRow, LayoutOrder = 2, Size = UDim2.fromOffset(buttonWidth, 36), BackgroundColor3 = theme.Accent, AutoButtonColor = false, Font = Enum.Font.GothamSemibold, Text = tostring(config.ConfirmText), TextColor3 = theme.AccentText, TextSize = 12, ZIndex = 93}, {corner(8)})
        attachHover(confirm, theme.Accent, Color3.fromRGB(210, 210, 215))
        confirm.MouseButton1Click:Connect(function() controller:Close(true) end)
        backdrop.MouseButton1Click:Connect(function() if config.DismissOnBackdrop then controller:Close(false) end end)
        table.insert(self.Modals, controller)
        tween(backdrop, 0.18, {BackgroundTransparency = 0.38})
        tween(dialog, 0.22, {GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5)}, Enum.EasingStyle.Quart)
        return controller
    end

    function window:Notify(notification)
        if self.Destroyed or not gui.Parent then return end
        if type(notification) == "table" and (notification.Modal == true or notification.Type == "Modal") then return self:Modal(notification) end
        notification = merge({Title = "VelonLib", Content = "", Duration = 3, Icon = "info"}, notification)
        local holder = gui:FindFirstChild("Notifications") or create("Frame", {Parent = gui, Name = "Notifications", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18), Size = UDim2.fromOffset(320, 400), BackgroundTransparency = 1, ZIndex = 80})
        if not holder:FindFirstChildOfClass("UIListLayout") then create("UIListLayout", {Parent = holder, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8)}) end
        local toast = create("CanvasGroup", {Parent = holder, Size = UDim2.fromOffset(310, 76), BackgroundColor3 = theme.Surface, GroupTransparency = 1, ZIndex = 81}, {corner(10), stroke(theme.Border, 0.58), padding(14, 14, 12, 12)})
        local icon = makeIcon(toast, notification.Icon, 18, theme.Text, 82)
        icon.Position = UDim2.fromOffset(0, 2)
        create("TextLabel", {Parent = toast, BackgroundTransparency = 1, Position = UDim2.fromOffset(30, -2), Size = UDim2.new(1, -30, 0, 22), Font = Enum.Font.GothamSemibold, Text = notification.Title, TextColor3 = theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 82})
        create("TextLabel", {Parent = toast, BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 21), Size = UDim2.new(1, -30, 0, 31), Font = Enum.Font.Gotham, Text = notification.Content, TextColor3 = theme.Muted, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 82})
        toast.Position = UDim2.fromOffset(35, 0)
        tween(toast, 0.3, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Quart)
        task.delay(notification.Duration, function()
            if toast.Parent then tween(toast, 0.25, {GroupTransparency = 1, Position = UDim2.fromOffset(25, 0)}); task.wait(0.27); toast:Destroy() end
        end)
    end

    function window:SetTitle(title, subtitle)
        if self.Destroyed then return end
        options.Title, titleLabel.Text = title, title
        if subtitle ~= nil then options.Subtitle, subtitleLabel.Text = subtitle, subtitle end
    end
    function window:SetIcon(icon) if self.Destroyed then return end options.Icon = icon end
    function window:SetLink(link) if self.Destroyed then return end options.Link = link end
    function window:SetVisible(visible)
        if self.Destroyed then return end
        self.Visible = visible
        refreshMobileToggle()
        if setTabPreviews then setTabPreviews(self.SelectedTab, visible) end
        if visible then
            windowHost.Visible = true
            root.GroupTransparency = 1
            tween(root, 0.25, {GroupTransparency = 0})
        else
            tween(root, 0.2, {GroupTransparency = 1})
            task.delay(0.21, function() if windowHost.Parent and not self.Visible then windowHost.Visible = false end end)
        end
    end
    function window:Toggle() self:SetVisible(not self.Visible) end
    function window:Minimize(state)
        if self.Destroyed then return end
        if state == nil then state = not self.Minimized end
        self.Minimized = state
        local targetHeight = state and 58 or (self.MobileMode and math.min(options.Height, 360) or options.Height)
        local targetWidth = self.MobileMode and math.min(options.Width, 560) or options.Width
        if not state then sidebar.Visible, content.Visible = true, true end
        if setTabPreviews then setTabPreviews(self.SelectedTab, not state) end
        tween(windowHost, 0.35, {Size = UDim2.fromOffset(targetWidth, targetHeight)}, Enum.EasingStyle.Quart)
        if state then task.delay(0.16, function() if self.Minimized then sidebar.Visible, content.Visible = false, false end end) end
    end
    function window:Destroy(fromGuiDestroy)
        if self.Destroyed then return end
        self.Destroyed = true
        for _, modal in ipairs(self.Modals) do
            modal.Closed = true
            if modal.Root and modal.Root.Parent then modal.Root:Destroy() end
        end
        self.Modals = {}
        for _, controller in ipairs(self.ESPControllers) do controller:Destroy() end
        for _, connection in ipairs(self.Connections) do pcall(function() connection:Disconnect() end) end
        for index, item in ipairs(VelonLib.Windows) do
            if item == self then table.remove(VelonLib.Windows, index) break end
        end
        if fromGuiDestroy then
            return
        elseif windowHost.Parent then
            tween(root, 0.2, {GroupTransparency = 1})
            tween(windowHost, 0.2, {Position = UDim2.new(windowHost.Position.X.Scale, windowHost.Position.X.Offset, windowHost.Position.Y.Scale, windowHost.Position.Y.Offset + 20)})
            task.delay(0.22, function() if gui and gui.Parent then gui:Destroy() end end)
        elseif gui and gui.Parent then
            gui:Destroy()
        end
    end

    table.insert(window.Connections, gui.Destroying:Connect(function()
        if not window.Destroyed then window:Destroy(true) end
    end))

    linkButton.MouseButton1Click:Connect(function()
        if options.Link == "" then window:Notify({Title = "Link", Content = "No link configured", Icon = "link"}) return end
        local _, message = openDiscord(options.Link)
        window:Notify({Title = "Community", Content = message, Icon = "link"})
    end)
    minimizeButton.MouseButton1Click:Connect(function() window:Minimize() end)
    closeButton.MouseButton1Click:Connect(function() window:SetVisible(false) end)
    table.insert(window.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Escape and window.SearchVisible then window:SetSearchVisible(false) return end
        if input.KeyCode == options.ToggleKey and (not window.Visible or UserInputService:GetFocusedTextBox() == nil) then window:Toggle() end
    end))

    setTabPreviews = function(tab, visible)
        if not tab or not tab.PreviewPanels then return end
        if window.MobileMode and not window.UserPositioned then
            local targetX = visible and #tab.PreviewPanels > 0 and 0.36 or 0.5
            tween(windowHost, 0.22, {Position = UDim2.new(targetX, 0, windowHost.Position.Y.Scale, windowHost.Position.Y.Offset)}, Enum.EasingStyle.Quart)
        end
        visible = visible and window.Visible and not window.Minimized and not window.SplashActive
        for _, panel in ipairs(tab.PreviewPanels) do
            if panel and panel.Parent then
                local token = (panel:GetAttribute("VelonPreviewToken") or 0) + 1
                panel:SetAttribute("VelonPreviewToken", token)
                if visible then
                    panel.Visible = true
                    panel.GroupTransparency = 1
                    tween(panel, 0.24, {GroupTransparency = 0}, Enum.EasingStyle.Quart)
                else
                    tween(panel, 0.18, {GroupTransparency = 1})
                    task.delay(0.19, function()
                        if panel.Parent and panel:GetAttribute("VelonPreviewToken") == token then panel.Visible = false end
                    end)
                end
            end
        end
    end

    function window:SelectTab(tab)
        if self.Destroyed or type(tab) ~= "table" or tab.Window ~= self or not tab.Page.Parent then return end
        if self.SelectedTab == tab then return end
        if self.SelectedTab then
            local previous = self.SelectedTab
            setTabPreviews(previous, false)
            tween(previous.Button, 0.18, {BackgroundColor3 = theme.Surface})
            tween(previous.Icon, 0.18, {ImageColor3 = theme.Muted})
            tween(previous.Page, 0.15, {GroupTransparency = 1, Position = UDim2.fromOffset(12, 0)})
            task.delay(0.16, function() if self.SelectedTab ~= previous then previous.Page.Visible = false end end)
        end
        self.SelectedTab = tab
        tab.Page.Visible, tab.Page.GroupTransparency, tab.Page.Position = true, 1, UDim2.fromOffset(-10, 0)
        tween(tab.Button, 0.18, {BackgroundColor3 = theme.Accent})
        tween(tab.Icon, 0.18, {ImageColor3 = theme.AccentText})
        tween(tab.Page, 0.24, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Quart)
        self:ApplySearch(self.SearchQuery)
        setTabPreviews(tab, true)
    end

    function window:CreateTab(tabOptions)
        if type(tabOptions) == "string" then tabOptions = {Name = tabOptions} end
        tabOptions = merge({Name = "Tab", Icon = "circle-help"}, tabOptions)
        local tab = {Window = self, Options = tabOptions, Controls = {}, PreviewPanels = {}}
        local button = create("TextButton", {Parent = tabList, Size = UDim2.fromOffset(42, 42), AutoButtonColor = false, BackgroundColor3 = theme.Surface, Text = "", ZIndex = 23}, {corner(9)})
        local icon = makeIcon(button, tabOptions.Icon, 18, theme.Muted, 24)
        icon.AnchorPoint, icon.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
        local page = create("CanvasGroup", {Parent = pages, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1, ZIndex = 23})
        local heading = create("TextLabel", {Parent = page, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), Font = Enum.Font.GothamBold, Text = tabOptions.Name, TextColor3 = theme.Text, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 24})
        local scroll = create("ScrollingFrame", {Parent = page, Position = UDim2.fromOffset(0, 39), Size = UDim2.new(1, 0, 1, -39), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = theme.Border, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 24}, {padding(0, 5, 0, 4)})
        create("UIListLayout", {Parent = scroll, Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder})
        tab.Button, tab.Icon, tab.Page, tab.Scroll, tab.Heading = button, icon, page, scroll, heading
        button.MouseButton1Click:Connect(function() window:SelectTab(tab) end)
        table.insert(self.Tabs, tab)
        if window.MobileMode then button.Size = UDim2.fromOffset(46, 46) end

        function tab:SetName(name)
            self.Options.Name = tostring(name)
            self.Heading.Text = self.Options.Name
        end

        function tab:SetIcon(newIcon)
            self.Options.Icon = newIcon
            applyIcon(self.Icon, newIcon)
        end

        function tab:Select()
            window:SelectTab(self)
        end

        local function controlBase(config, height)
            config = merge({Name = "Control", Description = ""}, config)
            config.Name = config.Title or config.Name
            config.Description = config.Subtitle or config.Description
            local holder = create("Frame", {Parent = scroll, Size = UDim2.new(1, -5, 0, height or 60), BackgroundColor3 = theme.Surface, ClipsDescendants = true, ZIndex = 25}, {corner(9), stroke(theme.Border, 0.58)})
            local searchText = string.lower(tostring(config.Name) .. " " .. tostring(config.Description) .. " " .. tostring(config.Content or ""))
            holder:SetAttribute("VelonSearchText", searchText)
            if window.SearchQuery ~= "" then holder.Visible = string.find(searchText, window.SearchQuery, 1, true) ~= nil end
            local hasSubtitle = config.Description ~= ""
            local rightSpace = config.RightSpace or 14
            local title = create("TextLabel", {Parent = holder, BackgroundTransparency = 1, Position = UDim2.fromOffset(14, hasSubtitle and 9 or 0), Size = UDim2.new(1, -(14 + rightSpace), 0, hasSubtitle and 22 or height or 60), Font = Enum.Font.GothamMedium, Text = config.Name, TextColor3 = theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 26})
            if hasSubtitle then create("TextLabel", {Parent = holder, BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 31), Size = UDim2.new(1, -(14 + rightSpace), 0, 18), Font = Enum.Font.Gotham, Text = config.Description, TextColor3 = theme.Muted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 26}) end
            holder.MouseEnter:Connect(function() tween(holder, 0.16, {BackgroundColor3 = theme.Surface2}) end)
            holder.MouseLeave:Connect(function() tween(holder, 0.16, {BackgroundColor3 = theme.Surface}) end)
            return holder, title, config
        end

        local function saveFlag(config, value)
            if config.Flag then window.Flags[config.Flag] = value VelonLib.Flags[config.Flag] = value end
        end

        function tab:CreateSection(name)
            local label = create("TextLabel", {Parent = scroll, Size = UDim2.new(1, -5, 0, 26), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = string.upper(tostring(name)), TextColor3 = theme.Muted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 25})
            local searchText = string.lower(tostring(name))
            label:SetAttribute("VelonSearchText", searchText)
            if window.SearchQuery ~= "" then label.Visible = string.find(searchText, window.SearchQuery, 1, true) ~= nil end
            return label
        end

        function tab:CreateHeader(config)
            if type(config) == "string" then config = {Title = config} end
            config = merge({Title = "Header", Subtitle = "", Icon = nil}, config)
            local holder = create("Frame", {Parent = scroll, Size = UDim2.new(1, -5, 0, config.Subtitle ~= "" and 70 or 58), BackgroundColor3 = theme.Surface2, ZIndex = 25}, {corner(10)})
            local searchText = string.lower(tostring(config.Title) .. " " .. tostring(config.Subtitle))
            holder:SetAttribute("VelonSearchText", searchText)
            if window.SearchQuery ~= "" then holder.Visible = string.find(searchText, window.SearchQuery, 1, true) ~= nil end
            create("Frame", {Parent = holder, Position = UDim2.fromOffset(0, 12), Size = UDim2.fromOffset(3, config.Subtitle ~= "" and 46 or 34), BackgroundColor3 = theme.Accent, BorderSizePixel = 0, ZIndex = 26}, {corner(2)})
            local textOffset = config.Icon and 54 or 16
            if config.Icon then
                local iconHolder = create("Frame", {Parent = holder, Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = theme.Surface3, ZIndex = 26}, {corner(8)})
                local headerIcon = makeIcon(iconHolder, config.Icon, 17, theme.Text, 27)
                headerIcon.AnchorPoint, headerIcon.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
            end
            local title = create("TextLabel", {Parent = holder, BackgroundTransparency = 1, Position = UDim2.fromOffset(textOffset, config.Subtitle ~= "" and 11 or 0), Size = UDim2.new(1, -textOffset - 14, 0, config.Subtitle ~= "" and 24 or 58), Font = Enum.Font.GothamBold, Text = config.Title, TextColor3 = theme.Text, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 26})
            local subtitle
            if config.Subtitle ~= "" then subtitle = create("TextLabel", {Parent = holder, BackgroundTransparency = 1, Position = UDim2.fromOffset(textOffset, 36), Size = UDim2.new(1, -textOffset - 14, 0, 20), Font = Enum.Font.Gotham, Text = config.Subtitle, TextColor3 = theme.Muted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 26}) end
            return {
                SetTitle = function(_, value) title.Text = tostring(value) end,
                SetSubtitle = function(_, value) if subtitle then subtitle.Text = tostring(value) end end,
                Destroy = function() holder:Destroy() end,
            }
        end

        function tab:CreateParagraph(config)
            if type(config) == "string" then config = {Name = config} end
            local holder, title, final = controlBase(config, 72)
            title.Size = UDim2.new(1, -28, 0, 21)
            local contentLabel = create("TextLabel", {Parent = holder, BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -28, 0, 32), Font = Enum.Font.Gotham, Text = final.Content or final.Description or "", TextColor3 = theme.Muted, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 26})
            return {Set = function(_, value) contentLabel.Text = value end, Destroy = function() holder:Destroy() end}
        end

        function tab:CreateButton(config)
            config = merge({RightSpace = 106}, config)
            local holder, _, final = controlBase(config, 54)
            local button = create("TextButton", {Parent = holder, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(92, 32), AutoButtonColor = false, BackgroundColor3 = theme.Accent, Font = Enum.Font.GothamSemibold, Text = final.ButtonText or "Run", TextColor3 = theme.AccentText, TextSize = 12, ZIndex = 27}, {corner(7)})
            attachHover(button, theme.Accent, Color3.fromRGB(210, 210, 215))
            button.MouseButton1Click:Connect(function() tween(button, 0.07, {Size = UDim2.fromOffset(88, 29)}); task.delay(0.08, function() if button.Parent then tween(button, 0.12, {Size = UDim2.fromOffset(92, 32)}) end end); safeCall(final.Callback) end)
            return {Fire = function() safeCall(final.Callback) end, Destroy = function() holder:Destroy() end}
        end

        function tab:CreateToggle(config)
            config = merge({CurrentValue = false}, config)
            if config.Subtitle == nil and config.Description == nil then config.Subtitle = "Enable or disable this option" end
            config.RightSpace = config.RightSpace or 68
            local holder, _, final = controlBase(config, 62)
            local track = create("TextButton", {Parent = holder, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(42, 24), AutoButtonColor = false, BackgroundColor3 = theme.Surface3, Text = "", ZIndex = 27}, {corner(12)})
            local knob = create("Frame", {Parent = track, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = theme.Muted, ZIndex = 28}, {corner(8)})
            local control = {Value = final.CurrentValue == true}
            function control:Set(value, silent)
                self.Value = value == true saveFlag(final, self.Value)
                tween(track, 0.2, {BackgroundColor3 = self.Value and theme.Accent or theme.Surface3})
                tween(knob, 0.2, {Position = self.Value and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 4, 0.5, 0), BackgroundColor3 = self.Value and theme.AccentText or theme.Muted})
                if not silent then safeCall(final.Callback, self.Value) end
            end
            function control:Get() return self.Value end
            function control:Destroy() holder:Destroy() end
            track.MouseButton1Click:Connect(function() control:Set(not control.Value) end)
            control:Set(control.Value, true)
            table.insert(tab.Controls, control)
            return control
        end

        function tab:CreateSlider(config)
            config = merge({Range = {0, 100}, Increment = 1, CurrentValue = 0, Suffix = ""}, config)
            config.RightSpace = config.RightSpace or 100
            local holder, _, final = controlBase(config, 72)
            local valueLabel = create("TextLabel", {Parent = holder, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 9), Size = UDim2.fromOffset(90, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextColor3 = theme.Muted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 27})
            local bar = create("TextButton", {Parent = holder, Position = UDim2.new(0, 14, 1, -20), Size = UDim2.new(1, -28, 0, 6), AutoButtonColor = false, BackgroundColor3 = theme.Surface3, Text = "", ZIndex = 27}, {corner(3)})
            local fill = create("Frame", {Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = theme.Accent, BorderSizePixel = 0, ZIndex = 28}, {corner(3)})
            local knob = create("Frame", {Parent = fill, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = theme.Accent, ZIndex = 29}, {corner(6), stroke(theme.Background, 0, 2)})
            local range = type(final.Range) == "table" and final.Range or {0, 100}
            local minimum = tonumber(range[1]) or 0
            local maximum = tonumber(range[2]) or 100
            if maximum < minimum then minimum, maximum = maximum, minimum end
            local increment = math.abs(tonumber(final.Increment) or 1)
            if increment == 0 then increment = 1 end
            if maximum == minimum then maximum = minimum + increment end
            final.Range, final.Increment = {minimum, maximum}, increment
            local incrementDecimals = tostring(increment):match("%.(%d+)")
            local decimalPlaces = math.min(incrementDecimals and #incrementDecimals or 0, 6)
            local control = {Value = final.CurrentValue, Connection = nil, EndedConnection = nil}
            local sliding = false
            function control:Set(value, silent)
                value = math.clamp(tonumber(value) or minimum, minimum, maximum)
                value = minimum + math.floor(((value - minimum) / increment) + 0.5) * increment
                value = math.clamp(value, minimum, maximum)
                if decimalPlaces > 0 then value = tonumber(string.format("%." .. decimalPlaces .. "f", value)) or value end
                self.Value = value saveFlag(final, value)
                local alpha = (value - minimum) / (maximum - minimum)
                tween(fill, 0.08, {Size = UDim2.fromScale(alpha, 1)}, Enum.EasingStyle.Linear)
                valueLabel.Text = tostring(value) .. final.Suffix
                if not silent then safeCall(final.Callback, value) end
            end
            function control:Get() return self.Value end
            function control:Destroy()
                sliding = false
                if self.Connection then self.Connection:Disconnect() self.Connection = nil end
                if self.EndedConnection then self.EndedConnection:Disconnect() self.EndedConnection = nil end
                holder:Destroy()
            end
            local function fromInput(input)
                if bar.AbsoluteSize.X <= 0 then return end
                local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                control:Set(minimum + (maximum - minimum) * alpha)
            end
            bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = true fromInput(input) end end)
            bar.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = false end end)
            control.Connection = UserInputService.InputChanged:Connect(function(input) if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then fromInput(input) end end)
            control.EndedConnection = UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = false end end)
            table.insert(window.Connections, control.Connection)
            table.insert(window.Connections, control.EndedConnection)
            control:Set(control.Value, true)
            table.insert(tab.Controls, control)
            return control
        end

        function tab:CreateInput(config)
            config = merge({CurrentValue = "", Placeholder = "Type here...", RemoveTextAfterFocusLost = false}, config)
            config.RightSpace = config.RightSpace or 204
            local holder, _, final = controlBase(config, 62)
            local boxHolder = create("Frame", {Parent = holder, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -13, 0.5, 0), Size = UDim2.fromOffset(190, 36), BackgroundColor3 = theme.Background, ZIndex = 27}, {corner(7), stroke(theme.Border, 0.58), padding(10, 10, 0, 0)})
            local box = create("TextBox", {Parent = boxHolder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClearTextOnFocus = false, Font = Enum.Font.Gotham, Text = tostring(final.CurrentValue), PlaceholderText = final.Placeholder, PlaceholderColor3 = theme.Muted, TextColor3 = theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 28})
            local control = {Value = tostring(final.CurrentValue)}
            function control:Set(value, silent) self.Value = tostring(value or "") box.Text = self.Value saveFlag(final, self.Value) if not silent then safeCall(final.Callback, self.Value) end end
            function control:Get() return self.Value end
            function control:Destroy() holder:Destroy() end
            box.FocusLost:Connect(function(enterPressed) control:Set(box.Text) if final.RemoveTextAfterFocusLost then box.Text = "" end if final.Finished then safeCall(final.Finished, control.Value, enterPressed) end end)
            control:Set(control.Value, true)
            table.insert(tab.Controls, control)
            return control
        end

        function tab:CreateDropdown(config)
            config = merge({Options = {}, CurrentOption = nil}, config)
            if type(config.Options) ~= "table" then config.Options = {} end
            config.RightSpace = config.RightSpace or 204
            local holder, _, final = controlBase(config, 62)
            local selectedButton = create("TextButton", {Parent = holder, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -13, 0, 13), Size = UDim2.fromOffset(190, 36), AutoButtonColor = false, BackgroundColor3 = theme.Background, Font = Enum.Font.Gotham, Text = "", TextColor3 = theme.Text, TextSize = 12, ZIndex = 27}, {corner(7), stroke(theme.Border, 0.58)})
            local selectedText = create("TextLabel", {Parent = selectedButton, BackgroundTransparency = 1, Position = UDim2.fromOffset(11, 0), Size = UDim2.new(1, -38, 1, 0), Font = Enum.Font.GothamMedium, TextColor3 = theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 28})
            local arrow = makeIcon(selectedButton, "chevron-down", 14, theme.Muted, 28)
            arrow.AnchorPoint, arrow.Position = Vector2.new(1, 0.5), UDim2.new(1, -10, 0.5, 0)
            local list = create("ScrollingFrame", {Parent = holder, Position = UDim2.fromOffset(14, 62), Size = UDim2.new(1, -28, 0, 0), BackgroundColor3 = theme.Background, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 2, ScrollBarImageColor3 = theme.Muted, ZIndex = 29}, {corner(7), stroke(theme.Border, 0.58), padding(5, 5, 5, 5)})
            create("UIListLayout", {Parent = list, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})
            local control = {Value = final.CurrentOption or final.Options[1], Open = false, Options = final.Options}
            local function rebuild()
                for _, child in ipairs(list:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
                for _, option in ipairs(control.Options) do
                    local optionButton = create("TextButton", {Parent = list, Size = UDim2.new(1, 0, 0, 32), AutoButtonColor = false, BackgroundColor3 = theme.Surface2, BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = tostring(option), TextColor3 = theme.Muted, TextSize = 12, ZIndex = 30}, {corner(5)})
                    optionButton.MouseEnter:Connect(function() tween(optionButton, 0.12, {BackgroundTransparency = 0, TextColor3 = theme.Text}) end)
                    optionButton.MouseLeave:Connect(function() tween(optionButton, 0.12, {BackgroundTransparency = 1, TextColor3 = theme.Muted}) end)
                    optionButton.MouseButton1Click:Connect(function() control:Set(option) control:SetOpen(false) end)
                end
            end
            function control:Set(value, silent) self.Value = value selectedText.Text = tostring(value or "Select...") saveFlag(final, value) if not silent then safeCall(final.Callback, value) end end
            function control:Get() return self.Value end
            function control:SetOpen(open)
                self.Open = open list.Visible = true
                local listHeight = math.min(#self.Options * 36 + 10, 190)
                tween(arrow, 0.18, {Rotation = open and 180 or 0})
                tween(holder, 0.22, {Size = UDim2.new(1, -5, 0, open and (72 + listHeight) or 62)})
                tween(list, 0.22, {Size = UDim2.new(1, -28, 0, open and listHeight or 0)})
                if not open then task.delay(0.23, function() if not self.Open then list.Visible = false end end) end
            end
            function control:Refresh(optionsList, keepSelection)
                self.Options = type(optionsList) == "table" and optionsList or {}
                local selectionExists = false
                if keepSelection then
                    for _, option in ipairs(self.Options) do
                        if option == self.Value then selectionExists = true break end
                    end
                end
                rebuild()
                if not selectionExists then self:Set(self.Options[1]) end
                if self.Open then self:SetOpen(true) end
            end
            function control:Destroy() self.Open = false holder:Destroy() end
            selectedButton.MouseButton1Click:Connect(function() control:SetOpen(not control.Open) end)
            rebuild() control:Set(control.Value, true)
            table.insert(tab.Controls, control)
            return control
        end

        function tab:CreateKeybind(config)
            config = merge({CurrentKeybind = Enum.KeyCode.RightShift}, config)
            config.RightSpace = config.RightSpace or 120
            local holder, _, final = controlBase(config, 62)
            local keyButton = create("TextButton", {Parent = holder, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -13, 0.5, 0), Size = UDim2.fromOffset(108, 34), AutoButtonColor = false, BackgroundColor3 = theme.Background, Font = Enum.Font.GothamMedium, TextColor3 = theme.Text, TextSize = 12, ZIndex = 27}, {corner(7), stroke(theme.Border, 0.58)})
            local control = {Value = final.CurrentKeybind, Listening = false, Connection = nil}
            function control:Set(value, silent)
                self.Value = value
                keyButton.Text = typeof(value) == "EnumItem" and value.Name or tostring(value or "None")
                saveFlag(final, value)
                if not silent then safeCall(final.ChangedCallback, value) end
            end
            function control:Get() return self.Value end
            function control:Destroy()
                self.Listening = false
                if self.Connection then self.Connection:Disconnect() self.Connection = nil end
                holder:Destroy()
            end
            keyButton.MouseButton1Click:Connect(function() control.Listening = true keyButton.Text = "Press a key" end)
            control.Connection = UserInputService.InputBegan:Connect(function(input, processed)
                if control.Listening then
                    if input.UserInputType == Enum.UserInputType.Keyboard then control.Listening = false control:Set(input.KeyCode) end
                    return
                end
                if not processed and input.KeyCode == control.Value then safeCall(final.Callback, input.KeyCode) end
            end)
            table.insert(window.Connections, control.Connection)
            control:Set(control.Value, true)
            table.insert(tab.Controls, control)
            return control
        end

        function tab:CreateColorPicker(config)
            config = merge({CurrentColor = Color3.new(1, 1, 1)}, config)
            if typeof(config.CurrentColor) ~= "Color3" then config.CurrentColor = Color3.new(1, 1, 1) end
            config.RightSpace = config.RightSpace or 82
            local holder, _, final = controlBase(config, 62)
            local swatch = create("TextButton", {Parent = holder, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -13, 0, 14), Size = UDim2.fromOffset(68, 34), AutoButtonColor = false, BackgroundColor3 = final.CurrentColor, Text = "", ZIndex = 27}, {corner(7), stroke(theme.Border, 0.58)})
            local picker = create("Frame", {Parent = holder, Position = UDim2.fromOffset(14, 64), Size = UDim2.new(1, -28, 0, 142), BackgroundTransparency = 1, Visible = false, ZIndex = 27})
            local sv = create("Frame", {Parent = picker, Size = UDim2.new(1, -48, 1, 0), BackgroundColor3 = Color3.fromHSV(0, 1, 1), Active = true, ClipsDescendants = true, ZIndex = 28}, {corner(7)})
            local white = create("Frame", {Parent = sv, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 29})
            create("UIGradient", {Parent = white, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})})
            local black = create("Frame", {Parent = sv, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 30})
            create("UIGradient", {Parent = black, Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})})
            local cursor = create("Frame", {Parent = sv, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = 32}, {corner(5), stroke(Color3.new(1, 1, 1), 0, 2)})
            local hue = create("Frame", {Parent = picker, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(34, 142), BackgroundColor3 = Color3.new(1, 1, 1), Active = true, ClipsDescendants = true, ZIndex = 28}, {corner(7)})
            create("UIGradient", {Parent = hue, Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromHSV(0,1,1)), ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17,1,1)), ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33,1,1)), ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5,1,1)), ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67,1,1)), ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83,1,1)), ColorSequenceKeypoint.new(1, Color3.fromHSV(1,1,1))})})
            local hueCursor = create("Frame", {Parent = hue, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(1, -4, 0, 4), BackgroundColor3 = Color3.new(1,1,1), ZIndex = 31}, {corner(2), stroke(Color3.new(0,0,0), 0.4)})
            local h, s, v = Color3.toHSV(final.CurrentColor)
            local control = {Value = final.CurrentColor, Open = false, ChangedConnection = nil, EndedConnection = nil}
            function control:Set(value, silent)
                if typeof(value) ~= "Color3" then return end
                self.Value = value h, s, v = Color3.toHSV(value)
                swatch.BackgroundColor3, sv.BackgroundColor3 = value, Color3.fromHSV(h, 1, 1)
                cursor.Position = UDim2.fromScale(math.clamp(s, 0.02, 0.98), math.clamp(1-v, 0.035, 0.965))
                hueCursor.Position = UDim2.fromScale(0.5, math.clamp(h, 0.025, 0.975))
                saveFlag(final, value) if not silent then safeCall(final.Callback, value) end
            end
            function control:Get() return self.Value end
            function control:SetOpen(open) self.Open = open picker.Visible = true tween(holder, 0.22, {Size = UDim2.new(1, -5, 0, open and 220 or 62)}) if not open then task.delay(0.23, function() if not self.Open then picker.Visible = false end end) end end
            function control:Destroy()
                self.Open = false
                if self.ChangedConnection then self.ChangedConnection:Disconnect() self.ChangedConnection = nil end
                if self.EndedConnection then self.EndedConnection:Disconnect() self.EndedConnection = nil end
                holder:Destroy()
            end
            swatch.MouseButton1Click:Connect(function() control:SetOpen(not control.Open) end)
            local draggingSV, draggingHue = false, false
            local function updateSV(input) s = math.clamp((input.Position.X-sv.AbsolutePosition.X)/sv.AbsoluteSize.X,0,1) v = 1-math.clamp((input.Position.Y-sv.AbsolutePosition.Y)/sv.AbsoluteSize.Y,0,1) control:Set(Color3.fromHSV(h,s,v)) end
            local function updateHue(input) h = math.clamp((input.Position.Y-hue.AbsolutePosition.Y)/hue.AbsoluteSize.Y,0,1) control:Set(Color3.fromHSV(h,s,v)) end
            sv.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSV=true updateSV(input) end end)
            hue.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingHue=true updateHue(input) end end)
            control.ChangedConnection = UserInputService.InputChanged:Connect(function(input) if draggingSV then updateSV(input) elseif draggingHue then updateHue(input) end end)
            control.EndedConnection = UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSV,draggingHue=false,false end end)
            table.insert(window.Connections, control.ChangedConnection) table.insert(window.Connections, control.EndedConnection)
            control:Set(control.Value, true)
            table.insert(tab.Controls, control)
            return control
        end

        function tab:CreateESP(config)
            config = merge({
                FlagPrefix = "ESP_",
                Controls = true,
                Settings = {},
                PreviewPlayer = LocalPlayer,
            }, config)
            local settings = merge({
                Enabled = false,
                TeamCheck = false,
                MaxDistance = 2000,
                Boxes = true,
                Names = true,
                Distance = true,
                HealthBar = true,
                Tracers = false,
                Skeleton = false,
                Chams = false,
                BoxColor = Color3.fromRGB(255, 255, 255),
                TextColor = Color3.fromRGB(255, 255, 255),
                SkeletonColor = Color3.fromRGB(255, 255, 255),
                TracerColor = Color3.fromRGB(255, 255, 255),
                ChamsColor = Color3.fromRGB(255, 255, 255),
                Thickness = 1,
                TextSize = 12,
                UpdateRate = 1 / 60,
            }, config.Settings)

            local controller = {
                Settings = settings,
                Objects = {},
                Targets = {},
                Connections = {},
                Destroyed = false,
                Preview = nil,
            }

            local function createPreview()
                local previewHeight = window.MobileMode and math.min(options.Height, 360) or options.Height
                local sidePanel = create("CanvasGroup", {
                    Parent = windowHost, Position = UDim2.new(1, 12, 0, 0), Size = UDim2.fromOffset(280, previewHeight),
                    BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, ZIndex = 25,
                })
                local card = create("Frame", {
                    Parent = sidePanel, Size = UDim2.fromOffset(280, previewHeight),
                    BackgroundColor3 = theme.Surface, ZIndex = 26,
                }, {corner(10), stroke(theme.Border, 0.58)})
                create("TextLabel", {
                    Parent = card, BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 8),
                    Size = UDim2.new(1, -120, 0, 28), Font = Enum.Font.GothamSemibold,
                    Text = "Character Preview", TextColor3 = theme.Text, TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 27,
                })
                local badge = create("TextLabel", {
                    Parent = card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 10),
                    Size = UDim2.fromOffset(82, 24), BackgroundColor3 = theme.Surface3,
                    Font = Enum.Font.GothamBold, Text = "PREVIEW", TextColor3 = theme.Muted,
                    TextSize = 10, ZIndex = 27,
                }, {corner(6)})
                local stage = create("Frame", {
                    Parent = card, Position = UDim2.fromOffset(14, 43), Size = UDim2.new(1, -28, 1, -57),
                    BackgroundColor3 = theme.Background, ClipsDescendants = true, ZIndex = 26,
                }, {corner(8)})
                local avatar = create("ImageLabel", {
                    Parent = stage, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53),
                    Size = UDim2.fromOffset(250, 250), BackgroundTransparency = 1,
                    ScaleType = Enum.ScaleType.Fit, ZIndex = 27,
                })
                local nameLabel = create("TextLabel", {
                    Parent = stage, AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1,
                    Font = Enum.Font.GothamSemibold, Text = "PLAYER", TextColor3 = settings.TextColor,
                    TextSize = 12, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.25,
                    Visible = false, ZIndex = 34,
                })
                local distanceLabel = create("TextLabel", {
                    Parent = stage, AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium, Text = "125 studs", TextColor3 = settings.TextColor,
                    TextSize = 11, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.25,
                    Visible = false, ZIndex = 34,
                })
                local healthBack = create("Frame", {
                    Parent = stage, AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    BorderSizePixel = 0, Visible = false, ZIndex = 32,
                }, {corner(2)})
                local healthFill = create("Frame", {
                    Parent = healthBack, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
                    Size = UDim2.fromScale(1, 0.72), BackgroundColor3 = Color3.fromRGB(90, 255, 110),
                    BorderSizePixel = 0, ZIndex = 33,
                }, {corner(2)})
                local boxLines = {}
                local skeletonLines = {}
                for _ = 1, 4 do table.insert(boxLines, makeLine(stage, settings.BoxColor, settings.Thickness, 33)) end
                for _ = 1, 14 do table.insert(skeletonLines, makeLine(stage, settings.SkeletonColor, settings.Thickness, 33)) end
                local tracer = makeLine(stage, settings.TracerColor, settings.Thickness, 32)

                controller.Preview = {
                    Root = sidePanel, Card = card, Stage = stage, Avatar = avatar, Badge = badge,
                    Name = nameLabel, Distance = distanceLabel,
                    HealthBack = healthBack, HealthFill = healthFill,
                    Box = boxLines, Skeleton = skeletonLines, Tracer = tracer,
                    Token = 0,
                }
                table.insert(tab.PreviewPanels, sidePanel)

                function controller:RefreshPreview()
                    local preview = self.Preview
                    if self.Destroyed or not preview or not preview.Root.Parent then return end
                    local size = preview.Stage.AbsoluteSize
                    if size.X <= 0 or size.Y <= 0 then return end
                    local centerX = size.X / 2
                    local top = size.Y * 0.36
                    local bottom = size.Y * 0.71
                    local height = bottom - top
                    local width = math.min(height * 0.72, size.X * 0.48)
                    local left, right = centerX - width / 2, centerX + width / 2
                    local boxPoints = {
                        {Vector2.new(left, top), Vector2.new(right, top)},
                        {Vector2.new(right, top), Vector2.new(right, bottom)},
                        {Vector2.new(right, bottom), Vector2.new(left, bottom)},
                        {Vector2.new(left, bottom), Vector2.new(left, top)},
                    }
                    for index, line in ipairs(preview.Box) do
                        line.BackgroundColor3 = settings.BoxColor
                        setLine(line, boxPoints[index][1], boxPoints[index][2], settings.Thickness, settings.Boxes)
                    end

                    preview.Name.TextColor3 = settings.TextColor
                    preview.Name.TextSize = math.max(settings.TextSize, 11)
                    preview.Name.Position = UDim2.fromOffset(centerX, top - 4)
                    preview.Name.Size = UDim2.fromOffset(width + 80, 18)
                    preview.Name.Visible = settings.Names
                    preview.Distance.TextColor3 = settings.TextColor
                    preview.Distance.TextSize = math.max(settings.TextSize - 1, 10)
                    preview.Distance.Position = UDim2.fromOffset(centerX, bottom + 4)
                    preview.Distance.Size = UDim2.fromOffset(width + 80, 18)
                    preview.Distance.Visible = settings.Distance
                    preview.HealthBack.Position = UDim2.fromOffset(left - 7, top)
                    preview.HealthBack.Size = UDim2.fromOffset(4, height)
                    preview.HealthBack.Visible = settings.HealthBar
                    preview.Tracer.BackgroundColor3 = settings.TracerColor
                    setLine(preview.Tracer, Vector2.new(size.X / 2, size.Y), Vector2.new(centerX, bottom), settings.Thickness, settings.Tracers)

                    local nodes = {
                        Head = Vector2.new(centerX, top + height * 0.12),
                        Neck = Vector2.new(centerX, top + height * 0.24),
                        Chest = Vector2.new(centerX, top + height * 0.37),
                        Pelvis = Vector2.new(centerX, top + height * 0.56),
                        LShoulder = Vector2.new(centerX - width * 0.24, top + height * 0.29),
                        LElbow = Vector2.new(centerX - width * 0.37, top + height * 0.46),
                        LHand = Vector2.new(centerX - width * 0.42, top + height * 0.63),
                        RShoulder = Vector2.new(centerX + width * 0.24, top + height * 0.29),
                        RElbow = Vector2.new(centerX + width * 0.37, top + height * 0.46),
                        RHand = Vector2.new(centerX + width * 0.42, top + height * 0.63),
                        LKnee = Vector2.new(centerX - width * 0.18, top + height * 0.76),
                        LFoot = Vector2.new(centerX - width * 0.24, top + height * 0.96),
                        RKnee = Vector2.new(centerX + width * 0.18, top + height * 0.76),
                        RFoot = Vector2.new(centerX + width * 0.24, top + height * 0.96),
                    }
                    local skeletonPairs = {
                        {nodes.Head, nodes.Neck}, {nodes.Neck, nodes.Chest}, {nodes.Chest, nodes.Pelvis},
                        {nodes.Neck, nodes.LShoulder}, {nodes.LShoulder, nodes.LElbow}, {nodes.LElbow, nodes.LHand},
                        {nodes.Neck, nodes.RShoulder}, {nodes.RShoulder, nodes.RElbow}, {nodes.RElbow, nodes.RHand},
                        {nodes.Pelvis, nodes.LKnee}, {nodes.LKnee, nodes.LFoot},
                        {nodes.Pelvis, nodes.RKnee}, {nodes.RKnee, nodes.RFoot},
                    }
                    for index, line in ipairs(preview.Skeleton) do
                        local pair = skeletonPairs[index]
                        line.BackgroundColor3 = settings.SkeletonColor
                        setLine(line, pair and pair[1] or Vector2.zero, pair and pair[2] or Vector2.zero, settings.Thickness, settings.Skeleton and pair ~= nil)
                    end
                    preview.Avatar.ImageColor3 = settings.Chams and settings.ChamsColor or Color3.new(1, 1, 1)
                    preview.Avatar.ImageTransparency = settings.Chams and 0.08 or 0
                    preview.Badge.Text = settings.Enabled and "ESP ON" or "PREVIEW"
                    preview.Badge.TextColor3 = settings.Enabled and theme.Success or theme.Muted
                end

                function controller:SetPreviewPlayer(playerOrUserId)
                    local preview = self.Preview
                    if self.Destroyed or not preview then return end
                    local userId
                    local displayName = "PLAYER"
                    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
                        userId = playerOrUserId.UserId
                        displayName = playerOrUserId.DisplayName
                    else
                        userId = tonumber(playerOrUserId)
                    end
                    if not userId then return end
                    preview.Token = preview.Token + 1
                    local token = preview.Token
                    preview.Name.Text = displayName
                    task.spawn(function()
                        local ok, image = pcall(function()
                            return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420)
                        end)
                        if ok and not self.Destroyed and self.Preview == preview and preview.Token == token then
                            preview.Avatar.Image = image
                        end
                    end)
                end

                table.insert(controller.Connections, stage:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    controller:RefreshPreview()
                end))
                controller:SetPreviewPlayer(config.PreviewPlayer or LocalPlayer)
                task.defer(function()
                    controller:RefreshPreview()
                    if window.SelectedTab == tab and setTabPreviews then setTabPreviews(tab, true) end
                end)
            end

            local function hideVisual(visual)
                for _, line in ipairs(visual.Box) do line.Visible = false end
                for _, line in ipairs(visual.Skeleton) do line.Visible = false end
                visual.Name.Visible = false
                visual.Distance.Visible = false
                visual.HealthBack.Visible = false
                visual.HealthFill.Visible = false
                visual.Tracer.Visible = false
                visual.Highlight.Enabled = false
            end

            local function removeVisual(player)
                controller.Targets[player] = nil
                local visual = controller.Objects[player]
                if not visual then return end
                for _, object in ipairs(visual.All) do pcall(function() object:Destroy() end) end
                controller.Objects[player] = nil
            end

            local function makeVisual(player)
                local visual = {Player = player, Box = {}, Skeleton = {}, All = {}}
                for _ = 1, 4 do
                    local line = makeLine(overlay, settings.BoxColor, settings.Thickness, 6)
                    table.insert(visual.Box, line)
                    table.insert(visual.All, line)
                end
                for _ = 1, 15 do
                    local line = makeLine(overlay, settings.SkeletonColor, settings.Thickness, 6)
                    table.insert(visual.Skeleton, line)
                    table.insert(visual.All, line)
                end
                visual.Name = create("TextLabel", {
                    Parent = overlay, AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1,
                    Font = Enum.Font.GothamSemibold, TextColor3 = settings.TextColor,
                    TextSize = settings.TextSize, TextStrokeColor3 = Color3.new(0, 0, 0),
                    TextStrokeTransparency = 0.35, Visible = false, ZIndex = 7,
                })
                visual.Distance = create("TextLabel", {
                    Parent = overlay, AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham, TextColor3 = settings.TextColor,
                    TextSize = settings.TextSize - 1, TextStrokeColor3 = Color3.new(0, 0, 0),
                    TextStrokeTransparency = 0.35, Visible = false, ZIndex = 7,
                })
                visual.HealthBack = create("Frame", {
                    Parent = overlay, AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    BorderSizePixel = 0, Visible = false, ZIndex = 6,
                })
                visual.HealthFill = create("Frame", {
                    Parent = visual.HealthBack, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
                    Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(74, 222, 128),
                    BorderSizePixel = 0, Visible = false, ZIndex = 7,
                })
                visual.Tracer = makeLine(overlay, settings.TracerColor, settings.Thickness, 5)
                visual.Highlight = create("Highlight", {
                    Parent = gui, Enabled = false, FillColor = settings.ChamsColor,
                    FillTransparency = 0.72, OutlineColor = settings.ChamsColor,
                    OutlineTransparency = 0.05, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                })
                table.insert(visual.All, visual.Name)
                table.insert(visual.All, visual.Distance)
                table.insert(visual.All, visual.HealthBack)
                table.insert(visual.All, visual.Tracer)
                table.insert(visual.All, visual.Highlight)
                controller.Objects[player] = visual
                return visual
            end

            local function getVisual(player)
                return controller.Objects[player] or makeVisual(player)
            end

            local function projectPart(camera, part)
                if not part then return nil end
                local point = camera:WorldToViewportPoint(part.Position)
                if point.Z <= 0 then return nil end
                return Vector2.new(point.X, point.Y)
            end

            local function drawSkeleton(camera, character, visual)
                local pairsToDraw
                if character:FindFirstChild("UpperTorso") then
                    pairsToDraw = {
                        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
                        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
                        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
                        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
                        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
                    }
                else
                    pairsToDraw = {
                        {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
                        {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
                    }
                end
                for index, line in ipairs(visual.Skeleton) do
                    local pair = pairsToDraw[index]
                    if pair then
                        local pointA = projectPart(camera, character:FindFirstChild(pair[1]))
                        local pointB = projectPart(camera, character:FindFirstChild(pair[2]))
                        line.BackgroundColor3 = settings.SkeletonColor
                        setLine(line, pointA or Vector2.zero, pointB or Vector2.zero, settings.Thickness, pointA ~= nil and pointB ~= nil)
                    else
                        line.Visible = false
                    end
                end
            end

            local function updatePlayer(camera, player, visual)
                if player == LocalPlayer then hideVisual(visual) return end
                if settings.TeamCheck and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then hideVisual(visual) return end
                local character = player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                local head = character and character:FindFirstChild("Head")
                if not character or not humanoid or humanoid.Health <= 0 or not rootPart or not head then hideVisual(visual) return end

                local worldDistance = (camera.CFrame.Position - rootPart.Position).Magnitude
                if worldDistance > settings.MaxDistance then hideVisual(visual) return end
                local rootPoint, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                local topPoint = camera:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y * 0.75, 0))
                local bottomPoint = camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3.25, 0))
                if not onScreen or rootPoint.Z <= 0 or topPoint.Z <= 0 or bottomPoint.Z <= 0 then hideVisual(visual) return end

                local height = math.max(math.abs(bottomPoint.Y - topPoint.Y), 12)
                local width = math.max(height * 0.56, 7)
                local centerX = rootPoint.X
                local left, right = centerX - width / 2, centerX + width / 2
                local top, bottom = topPoint.Y, bottomPoint.Y
                local boxPoints = {
                    {Vector2.new(left, top), Vector2.new(right, top)},
                    {Vector2.new(right, top), Vector2.new(right, bottom)},
                    {Vector2.new(right, bottom), Vector2.new(left, bottom)},
                    {Vector2.new(left, bottom), Vector2.new(left, top)},
                }
                for index, line in ipairs(visual.Box) do
                    line.BackgroundColor3 = settings.BoxColor
                    setLine(line, boxPoints[index][1], boxPoints[index][2], settings.Thickness, settings.Boxes)
                end

                visual.Name.Text = player.DisplayName
                visual.Name.TextColor3 = settings.TextColor
                visual.Name.TextSize = settings.TextSize
                visual.Name.Position = UDim2.fromOffset(centerX, top - 5)
                visual.Name.Size = UDim2.fromOffset(math.max(width + 60, 110), 18)
                visual.Name.Visible = settings.Names

                visual.Distance.Text = tostring(math.floor(worldDistance + 0.5)) .. " studs"
                visual.Distance.TextColor3 = settings.TextColor
                visual.Distance.TextSize = math.max(settings.TextSize - 1, 8)
                visual.Distance.Position = UDim2.fromOffset(centerX, bottom + 4)
                visual.Distance.Size = UDim2.fromOffset(math.max(width + 50, 100), 18)
                visual.Distance.Visible = settings.Distance

                local healthAlpha = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
                visual.HealthBack.Position = UDim2.fromOffset(left - 5, top)
                visual.HealthBack.Size = UDim2.fromOffset(3, height)
                visual.HealthBack.Visible = settings.HealthBar
                visual.HealthFill.Visible = settings.HealthBar
                visual.HealthFill.Size = UDim2.fromScale(1, healthAlpha)
                visual.HealthFill.BackgroundColor3 = Color3.fromHSV(healthAlpha * 0.33, 0.9, 1)

                visual.Tracer.BackgroundColor3 = settings.TracerColor
                local viewport = camera.ViewportSize
                setLine(visual.Tracer, Vector2.new(viewport.X / 2, viewport.Y - 2), Vector2.new(centerX, bottom), settings.Thickness, settings.Tracers)

                if settings.Skeleton then drawSkeleton(camera, character, visual) else
                    for _, line in ipairs(visual.Skeleton) do line.Visible = false end
                end
                visual.Highlight.Adornee = character
                visual.Highlight.FillColor = settings.ChamsColor
                visual.Highlight.OutlineColor = settings.ChamsColor
                visual.Highlight.Enabled = settings.Chams
            end

            function controller:SetEnabled(enabled)
                settings.Enabled = enabled == true
                if not settings.Enabled then
                    for _, visual in pairs(self.Objects) do hideVisual(visual) end
                end
                if self.RefreshPreview then self:RefreshPreview() end
            end

            function controller:Set(key, value)
                if settings[key] == nil then error("Unknown ESP setting: " .. tostring(key), 2) end
                settings[key] = value
                if key == "Enabled" then self:SetEnabled(value) end
                if key ~= "Enabled" and self.RefreshPreview then self:RefreshPreview() end
            end

            function controller:Get(key) return settings[key] end

            function controller:Destroy()
                if self.Destroyed then return end
                self.Destroyed = true
                for _, connection in ipairs(self.Connections) do pcall(function() connection:Disconnect() end) end
                local playersToRemove = {}
                for player in pairs(self.Objects) do table.insert(playersToRemove, player) end
                for _, player in ipairs(playersToRemove) do removeVisual(player) end
                self.Targets = {}
                if self.Preview and self.Preview.Root then self.Preview.Root:Destroy() end
                self.Preview = nil
            end

            local function addTarget(player)
                if player ~= LocalPlayer then controller.Targets[player] = true end
            end
            table.insert(controller.Connections, Players.PlayerAdded:Connect(addTarget))
            table.insert(controller.Connections, Players.PlayerRemoving:Connect(removeVisual))
            for _, player in ipairs(Players:GetPlayers()) do addTarget(player) end
            local elapsed = 0
            table.insert(controller.Connections, RunService.RenderStepped:Connect(function(deltaTime)
                if controller.Destroyed then return end
                if not settings.Enabled then return end
                elapsed = elapsed + deltaTime
                local updateRate = math.max(tonumber(settings.UpdateRate) or 0, 0)
                if elapsed < updateRate then return end
                elapsed = updateRate > 0 and math.max(elapsed - updateRate, 0) or 0
                local camera = workspace.CurrentCamera
                if not camera then return end
                for player in pairs(controller.Targets) do
                    updatePlayer(camera, player, getVisual(player))
                end
            end))

            if config.Controls ~= false then
                local prefix = config.FlagPrefix
                tab:CreateHeader({Title = config.SectionName or "ESP Renderer", Subtitle = "Configure how players appear on screen", Icon = "eye"})
                createPreview()
                tab:CreateToggle({Title = "ESP Enabled", Subtitle = "Master switch for every ESP feature", Flag = prefix .. "Enabled", CurrentValue = settings.Enabled, Callback = function(value) controller:SetEnabled(value) end})
                tab:CreateSlider({Title = "Max Distance", Subtitle = "Ignore players outside this range", Flag = prefix .. "MaxDistance", Range = {100, 15000}, Increment = 100, CurrentValue = settings.MaxDistance, Suffix = " studs", Callback = function(value) controller:Set("MaxDistance", value) end})
                tab:CreateToggle({Title = "Team Check", Subtitle = "Hide players on your team", Flag = prefix .. "TeamCheck", CurrentValue = settings.TeamCheck, Callback = function(value) controller:Set("TeamCheck", value) end})
                tab:CreateToggle({Title = "Boxes", Subtitle = "Draw a box around each player", Flag = prefix .. "Boxes", CurrentValue = settings.Boxes, Callback = function(value) controller:Set("Boxes", value) end})
                tab:CreateToggle({Title = "Names", Subtitle = "Show player display names", Flag = prefix .. "Names", CurrentValue = settings.Names, Callback = function(value) controller:Set("Names", value) end})
                tab:CreateToggle({Title = "Distance", Subtitle = "Show distance in studs", Flag = prefix .. "Distance", CurrentValue = settings.Distance, Callback = function(value) controller:Set("Distance", value) end})
                tab:CreateToggle({Title = "Health Bar", Subtitle = "Show current player health", Flag = prefix .. "HealthBar", CurrentValue = settings.HealthBar, Callback = function(value) controller:Set("HealthBar", value) end})
                tab:CreateToggle({Title = "Tracers", Subtitle = "Draw lines from the screen bottom", Flag = prefix .. "Tracers", CurrentValue = settings.Tracers, Callback = function(value) controller:Set("Tracers", value) end})
                tab:CreateToggle({Title = "Skeleton", Subtitle = "Draw character rig connections", Flag = prefix .. "Skeleton", CurrentValue = settings.Skeleton, Callback = function(value) controller:Set("Skeleton", value) end})
                tab:CreateToggle({Title = "Chams", Subtitle = "Highlight characters through walls", Flag = prefix .. "Chams", CurrentValue = settings.Chams, Callback = function(value) controller:Set("Chams", value) end})
                tab:CreateSlider({Title = "Line Thickness", Subtitle = "Adjust ESP line width", Flag = prefix .. "Thickness", Range = {1, 4}, Increment = 1, CurrentValue = settings.Thickness, Callback = function(value) controller:Set("Thickness", value) end})
                tab:CreateColorPicker({Name = "Box Color", Flag = prefix .. "BoxColor", CurrentColor = settings.BoxColor, Callback = function(value) controller:Set("BoxColor", value) end})
                tab:CreateColorPicker({Name = "Text Color", Flag = prefix .. "TextColor", CurrentColor = settings.TextColor, Callback = function(value) controller:Set("TextColor", value) end})
                tab:CreateColorPicker({Name = "Skeleton Color", Flag = prefix .. "SkeletonColor", CurrentColor = settings.SkeletonColor, Callback = function(value) controller:Set("SkeletonColor", value) end})
                tab:CreateColorPicker({Name = "Tracer Color", Flag = prefix .. "TracerColor", CurrentColor = settings.TracerColor, Callback = function(value) controller:Set("TracerColor", value) end})
                tab:CreateColorPicker({Name = "Chams Color", Flag = prefix .. "ChamsColor", CurrentColor = settings.ChamsColor, Callback = function(value) controller:Set("ChamsColor", value) end})
            end

            table.insert(window.ESPControllers, controller)
            return controller
        end

        return tab
    end

    local mainConfig = merge({Name = "Main", Icon = "home"}, options.MainTab)
    window.MainTab = window:CreateTab(mainConfig)
    window:SelectTab(window.MainTab)
    window:SetMobileMode(touchInputPreferred())

    windowHost.Position = UDim2.fromScale(0.5, 0.53)
    tween(root, 0.42, {GroupTransparency = 0}, Enum.EasingStyle.Quart)
    tween(windowHost, 0.42, {Position = UDim2.fromScale(0.5, 0.5)}, Enum.EasingStyle.Quart)

    return window
end

function VelonLib:DestroyAll()
    if type(GLOBAL_ENV.__VELONLIB_CANCEL_KEY_SYSTEM) == "function" then
        pcall(GLOBAL_ENV.__VELONLIB_CANCEL_KEY_SYSTEM)
    end
    local active = {}
    for _, window in ipairs(self.Windows) do table.insert(active, window) end
    for _, window in ipairs(active) do
        if type(window.Destroy) == "function" then pcall(function() window:Destroy() end) end
    end
    self.Windows = {}
end

GLOBAL_ENV.__VELONLIB_ACTIVE = VelonLib

return VelonLib
