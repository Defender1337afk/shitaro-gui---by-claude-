--[[
    SidebarUI v2
    Roblox GUI Library — точная копия layout'а референса:
    логотип сверху, боковая навигация с активным акцентом слева,
    разворачиваемые группы (Visuals -> Players/World), сворачиваемые панели-категории
    с чекбоксами, расположенные в 2 колонки.

    Текст в примере — placeholder, замени под свои легитимные нужды.

    Использование:
        local SidebarUI = loadstring(readfile("SidebarUI.lua"))()
        local Window = SidebarUI:CreateWindow({ LogoText = "S" })

        local Combat = Window:CreateNavItem({ Title = "Combat", SubTitle = "боевые настройки", Icon = "target" })
        local P1 = Combat:CreatePanel("Category A", 0.62)
        P1:CreateCheckbox({ Text = "Option 1", Default = true })
        P1:CreateCheckbox({ Text = "Option 2" })

        local P2 = Combat:CreatePanel("Category B", 0.35)
        P2:CreateCheckbox({ Text = "Option 3" })

        local P3 = Combat:CreatePanel("Category C", 0.62)
        P3:CreateCheckbox({ Text = "Option 4" })

        -- вложенная группа с подпунктами
        local VisualsGroup = Window:CreateNavGroup({ Title = "Visuals", SubTitle = "показ доп.боксов", Icon = "eye" })
        local Players = VisualsGroup:AddSubItem({ Title = "Players", Icon = "users" })
        local World   = VisualsGroup:AddSubItem({ Title = "World", Icon = "globe" })

        Window:CreateNavItem({ Title = "Local", SubTitle = "не еби", Icon = "user" })
        Window:CreateNavItem({ Title = "Colors", SubTitle = "color settings", Icon = "palette" })
        Window:CreateNavItem({ Title = "Config", SubTitle = "menu settings", Icon = "save" })

        Window:SelectNavItem(1)
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-------------------------------------------------
-- ТЕМА
-------------------------------------------------
local Theme = {
    Background     = Color3.fromRGB(16, 16, 20),
    Sidebar        = Color3.fromRGB(11, 11, 14),
    Panel          = Color3.fromRGB(21, 21, 26),
    PanelHeader    = Color3.fromRGB(26, 26, 32),
    Stroke         = Color3.fromRGB(34, 34, 41),
    NavActiveBg    = Color3.fromRGB(22, 22, 27),
    Accent         = Color3.fromRGB(255, 255, 255),
    CheckMark      = Color3.fromRGB(15, 15, 18),
    TextPrimary    = Color3.fromRGB(232, 232, 237),
    TextSecondary  = Color3.fromRGB(110, 110, 120),
    TextTertiary   = Color3.fromRGB(75, 75, 85),
    Font           = Enum.Font.GothamMedium,
    FontBold       = Enum.Font.GothamBold,
}

local function Tween(obj, props, time)
    local tw = TweenService:Create(obj, TweenInfo.new(time or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    return inst
end

local function Corner(r) return Create("UICorner", { CornerRadius = UDim.new(0, r or 6) }) end
local function Stroke(color, thickness) return Create("UIStroke", { Color = color or Theme.Stroke, Thickness = thickness or 1 }) end

local function MakeDraggable(handle, frame)
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
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Векторные иконки: рисуются простыми фигурами (не зависят от внешних asset id)
local function DrawIcon(kind, parent, color)
    color = color or Theme.TextSecondary
    local holder = Create("Frame", {
        Size = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    if kind == "target" then
        Create("Frame", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Parent = holder }, {
            Stroke(color, 1.5)
        })
        Create("UICorner", { CornerRadius = UDim.new(1,0), Parent = holder })
        local inner = Create("Frame", {
            Size = UDim2.fromOffset(6,6),
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.fromScale(0.5,0.5),
            BackgroundColor3 = color,
            Parent = holder,
        })
        Create("UICorner", { CornerRadius = UDim.new(1,0), Parent = inner })
    elseif kind == "eye" then
        local outer = Create("Frame", {
            Size = UDim2.fromOffset(18, 10),
            Position = UDim2.fromOffset(0, 4),
            BackgroundTransparency = 1,
            Parent = holder,
        }, { Stroke(color, 1.5), Create("UICorner", { CornerRadius = UDim.new(1,0) }) })
        local pupil = Create("Frame", {
            Size = UDim2.fromOffset(6,6),
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.fromScale(0.5,0.5),
            BackgroundColor3 = color,
            Parent = outer,
        })
        Create("UICorner", { CornerRadius = UDim.new(1,0), Parent = pupil })
    elseif kind == "users" then
        for i, offsetX in ipairs({2, 9}) do
            local head = Create("Frame", {
                Size = UDim2.fromOffset(7,7),
                Position = UDim2.fromOffset(offsetX, 1),
                BackgroundColor3 = color,
                BackgroundTransparency = i == 1 and 0 or 0.3,
                Parent = holder,
            })
            Create("UICorner", { CornerRadius = UDim.new(1,0), Parent = head })
            local body = Create("Frame", {
                Size = UDim2.fromOffset(9,7),
                Position = UDim2.fromOffset(offsetX - 1, 9),
                BackgroundColor3 = color,
                BackgroundTransparency = i == 1 and 0 or 0.3,
                Parent = holder,
            })
            Create("UICorner", { CornerRadius = UDim.new(0,3), Parent = body })
        end
    elseif kind == "globe" then
        Create("Frame", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Parent = holder }, { Stroke(color, 1.5), Create("UICorner", { CornerRadius = UDim.new(1,0) }) })
        Create("Frame", { Size = UDim2.new(1,0,0,1), Position = UDim2.fromScale(0,0.5), BackgroundColor3 = color, BorderSizePixel = 0, Parent = holder })
        Create("Frame", { Size = UDim2.new(0,1,1,0), Position = UDim2.fromScale(0.5,0), BackgroundColor3 = color, BorderSizePixel = 0, Parent = holder })
    elseif kind == "user" then
        local head = Create("Frame", { Size = UDim2.fromOffset(8,8), Position = UDim2.fromOffset(5,0), BackgroundColor3 = color, Parent = holder })
        Create("UICorner", { CornerRadius = UDim.new(1,0), Parent = head })
        local body = Create("Frame", { Size = UDim2.fromOffset(14,8), Position = UDim2.fromOffset(2,10), BackgroundColor3 = color, Parent = holder })
        Create("UICorner", { CornerRadius = UDim.new(0,5), Parent = body })
    elseif kind == "palette" then
        Create("Frame", { Size = UDim2.fromOffset(18,14), Position = UDim2.fromOffset(0,2), BackgroundTransparency = 1, Parent = holder }, { Stroke(color, 1.5), Create("UICorner", { CornerRadius = UDim.new(0,9) }) })
        for _, p in ipairs({ {4,4}, {9,3}, {13,7} }) do
            local dot = Create("Frame", { Size = UDim2.fromOffset(3,3), Position = UDim2.fromOffset(p[1], p[2]+2), BackgroundColor3 = color, Parent = holder })
            Create("UICorner", { CornerRadius = UDim.new(1,0), Parent = dot })
        end
    elseif kind == "save" then
        Create("Frame", { Size = UDim2.fromOffset(16,16), Position = UDim2.fromOffset(1,1), BackgroundTransparency = 1, Parent = holder }, { Stroke(color, 1.5), Create("UICorner", { CornerRadius = UDim.new(0,3) }) })
        Create("Frame", { Size = UDim2.fromOffset(8,6), Position = UDim2.fromOffset(5,2), BackgroundColor3 = color, Parent = holder })
    elseif kind == "search" then
        Create("Frame", {
            Size = UDim2.fromOffset(11, 11),
            Position = UDim2.fromOffset(1, 1),
            BackgroundTransparency = 1,
            Parent = holder,
        }, { Stroke(color, 1.5), Create("UICorner", { CornerRadius = UDim.new(1,0) }) })
        local handle = Create("Frame", {
            Size = UDim2.fromOffset(6, 2),
            Position = UDim2.fromOffset(10, 11),
            Rotation = 45,
            BackgroundColor3 = color,
            Parent = holder,
        })
        Create("UICorner", { CornerRadius = UDim.new(1,0), Parent = handle })
    elseif kind == "dots" then
        for i = 0, 2 do
            local dot = Create("Frame", {
                Size = UDim2.fromOffset(3, 3),
                Position = UDim2.fromOffset(i * 6, 7),
                BackgroundColor3 = color,
                Parent = holder,
            })
            Create("UICorner", { CornerRadius = UDim.new(1,0), Parent = dot })
        end
    end

    return holder
end

-------------------------------------------------
-- БИБЛИОТЕКА
-------------------------------------------------
local SidebarUI = {}
SidebarUI.__index = SidebarUI

function SidebarUI:CreateWindow(config)
    config = config or {}

    local old = PlayerGui:FindFirstChild("SidebarUI_ScreenGui")
    if old then old:Destroy() end

    local ScreenGui = Create("ScreenGui", {
        Name = "SidebarUI_ScreenGui",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = (gethui and gethui()) or PlayerGui,
    })

    local Main = Create("Frame", {
        Size = UDim2.fromOffset(460, 480),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        ClipsDescendants = true,
        Parent = ScreenGui,
    }, { Corner(14), Stroke(Theme.Stroke, 1) })

    -- декоративный абстрактный узор из линий/узлов на фоне окна (анимированный, "живой")
    local Pattern = Create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 0,
        Parent = Main,
    })
    -- базовые (неподвижные) координаты точек сетки (подогнаны под уменьшенное окно)
    local PointDefs = {
        [1] = {335, 70},  [2] = {421, 47},  [3] = {456, 117}, [4] = {386, 148},
        [5] = {300, 172}, [6] = {343, 215}, [7] = {257, 257}, [8] = {222, 304},
        [9] = {160, 320}, [10] = {191, 367}, [11] = {117, 367},
    }
    local Edges = {
        {1,2},{2,3},{1,3},{1,4},{3,4},{4,5},{4,6},{5,6},
        {6,7},{7,8},{8,9},{8,10},{9,10},{9,11},{10,11},{7,9},
    }

    local AnimPoints = {}
    for k, v in pairs(PointDefs) do AnimPoints[k] = { x = v[1], y = v[2] } end

    -- линии создаются первыми, узлы вторыми — чтобы точки визуально лежали поверх линий
    local LineFrames = {}
    for _, e in ipairs(Edges) do
        local line = Create("Frame", {
            BackgroundColor3 = Theme.TextSecondary,
            BackgroundTransparency = 0.82,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = 0,
            Parent = Pattern,
        })
        table.insert(LineFrames, { frame = line, a = e[1], b = e[2] })
    end

    local NodeFrames = {}
    for k in pairs(PointDefs) do
        NodeFrames[k] = Create("Frame", {
            Size = UDim2.fromOffset(5, 5),
            BackgroundColor3 = Theme.TextSecondary,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            ZIndex = 0,
            Parent = Pattern,
        }, { Corner(3) })
    end

    local function UpdatePattern()
        local t = tick()
        for k, base in pairs(PointDefs) do
            local phase = k * 1.7
            AnimPoints[k].x = base[1] + math.sin(t * 0.5 + phase) * 6
            AnimPoints[k].y = base[2] + math.cos(t * 0.4 + phase) * 6
            local node = NodeFrames[k]
            node.Position = UDim2.fromOffset(AnimPoints[k].x - 2.5, AnimPoints[k].y - 2.5)
        end
        for _, l in ipairs(LineFrames) do
            local p1, p2 = AnimPoints[l.a], AnimPoints[l.b]
            local dx, dy = p2.x - p1.x, p2.y - p1.y
            local length = math.sqrt(dx * dx + dy * dy)
            local angle = math.deg(math.atan2(dy, dx))
            local midX, midY = (p1.x + p2.x) / 2, (p1.y + p2.y) / 2
            l.frame.Size = UDim2.fromOffset(length, 1)
            l.frame.Position = UDim2.fromOffset(midX, midY)
            l.frame.Rotation = angle
        end
    end
    UpdatePattern()
    local PatternConn = RunService.Heartbeat:Connect(UpdatePattern)
    ScreenGui.AncestryChanged:Connect(function(_, parent)
        if not parent then PatternConn:Disconnect() end
    end)

    -- верхний drag-handle (декоративная капсула по центру)
    local DragHandle = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = Main,
    })
    Create("Frame", {
        Size = UDim2.fromOffset(36, 4),
        Position = UDim2.new(0.5, -18, 0, 8),
        BackgroundColor3 = Theme.Stroke,
        Parent = DragHandle,
    }, { Corner(2) })

    MakeDraggable(DragHandle, Main)
    MakeDraggable(Main, Main)

    -- Sidebar (скруглены только левые углы, чтобы совпадать с формой окна;
    -- правые углы "довыпрямлены" накладками поверх скругления)
    local SIDEBAR_WIDTH = 148
    local Sidebar = Create("Frame", {
        Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0),
        BackgroundColor3 = Theme.Sidebar,
        ZIndex = 1,
        Parent = Main,
    }, { Corner(14) })
    Create("Frame", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(0, SIDEBAR_WIDTH - 14, 0, 0),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = Sidebar,
    })
    Create("Frame", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(0, SIDEBAR_WIDTH - 14, 1, -14),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = Sidebar,
    })

    local LogoHolder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 92),
        BackgroundTransparency = 1,
        Parent = Sidebar,
    })
    -- тень/подложка логотипа для лёгкого объёмного эффекта
    Create("TextLabel", {
        Text = config.LogoText or "S",
        Font = Enum.Font.GothamBlack,
        TextSize = 54,
        TextColor3 = Theme.TextSecondary,
        TextTransparency = 0.75,
        Rotation = -6,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 66),
        Position = UDim2.fromOffset(2, 12),
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = LogoHolder,
    })
    Create("TextLabel", {
        Text = config.LogoText or "S",
        Font = Enum.Font.GothamBlack,
        TextSize = 54,
        TextColor3 = Theme.TextPrimary,
        Rotation = -6,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 66),
        Position = UDim2.fromOffset(0, 10),
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = LogoHolder,
    })
    Create("Frame", {
        Size = UDim2.new(1, -32, 0, 1),
        Position = UDim2.new(0, 16, 1, -1),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = LogoHolder,
    })

    -- Футер: аватар + ник текущего игрока (как в оригинале)
    local FOOTER_HEIGHT = 52
    local Footer = Create("Frame", {
        Size = UDim2.new(1, 0, 0, FOOTER_HEIGHT),
        Position = UDim2.new(0, 0, 1, -FOOTER_HEIGHT),
        BackgroundTransparency = 1,
        Parent = Sidebar,
    })
    Create("Frame", {
        Size = UDim2.new(1, -20, 0, 1),
        Position = UDim2.fromOffset(10, 0),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = Footer,
    })

    local Avatar = Create("ImageLabel", {
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.fromOffset(10, 11),
        BackgroundColor3 = Theme.PanelHeader,
        ScaleType = Enum.ScaleType.Crop,
        Image = "",
        Parent = Footer,
    }, { Corner(15) })

    task.spawn(function()
        local ok, content = pcall(function()
            return Players:GetUserThumbnailAsync(
                LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
        end)
        if ok and content then
            Avatar.Image = content
        end
    end)

    Create("TextLabel", {
        Text = LocalPlayer.DisplayName,
        Font = Theme.FontBold,
        TextSize = 12,
        TextColor3 = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -52, 0, 14),
        Position = UDim2.fromOffset(48, 9),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = Footer,
    })
    Create("TextLabel", {
        Text = "@" .. LocalPlayer.Name,
        Font = Theme.Font,
        TextSize = 10,
        TextColor3 = Theme.TextSecondary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -52, 0, 12),
        Position = UDim2.fromOffset(48, 25),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = Footer,
    })

    local NavHolder = Create("Frame", {
        Size = UDim2.new(1, -16, 1, -(92 + FOOTER_HEIGHT + 8)),
        Position = UDim2.fromOffset(8, 92),
        BackgroundTransparency = 1,
        Parent = Sidebar,
    })
    Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = NavHolder,
    })

    local Content = Create("Frame", {
        Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, 0),
        Position = UDim2.fromOffset(SIDEBAR_WIDTH, 0),
        BackgroundTransparency = 1,
        Parent = Main,
    })

    -- верхняя строка контента: иконка поиска в углу (декоративная, как в референсе)
    local ContentHeader = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        Parent = Content,
    })
    local SearchBtn = Create("TextButton", {
        Text = "",
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -34, 0, 6),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Parent = ContentHeader,
    })
    local SearchIcon = DrawIcon("search", SearchBtn, Theme.TextSecondary)
    SearchIcon.Position = UDim2.fromOffset(5, 5)

    local Window = setmetatable({
        ScreenGui = ScreenGui,
        Main = Main,
        NavHolder = NavHolder,
        Content = Content,
        NavItems = {},
        _order = 0,
    }, { __index = SidebarUI })

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    return Window
end

-------------------------------------------------
-- Внутренняя функция: строит одну строку навигации
-------------------------------------------------
local function BuildNavRow(self, cfg, indent)
    indent = indent or 0
    self._order = self._order + 1

    local rowHeight = cfg.SubTitle and cfg.SubTitle ~= "" and 38 or 28

    local NavBtn = Create("TextButton", {
        Text = "",
        LayoutOrder = self._order,
        Size = UDim2.new(1, 0, 0, rowHeight),
        BackgroundColor3 = Theme.NavActiveBg,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        ClipsDescendants = false,
        Parent = self.NavHolder,
    }, { Corner(7) })

    -- мягкое свечение вокруг активного пункта (фейковый glow через radial-текстуру)
    local Glow = Create("ImageLabel", {
        Image = "rbxassetid://5028857084",
        ImageColor3 = Theme.Accent,
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Stretch,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 46, 1, 46),
        ZIndex = 0,
        Parent = NavBtn,
    })

    local AccentBar = Create("Frame", {
        Size = UDim2.fromOffset(3, rowHeight - 10),
        Position = UDim2.fromOffset(0, 5),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Parent = NavBtn,
    }, { Corner(2) })

    local iconX = 9 + indent
    local IconHolder
    if cfg.Icon then
        IconHolder = DrawIcon(cfg.Icon, NavBtn, Theme.TextSecondary)
        IconHolder.Size = UDim2.fromOffset(15, 15)
        IconHolder.Position = UDim2.fromOffset(iconX, (rowHeight - 15) / 2)
    end

    local textX = iconX + (cfg.Icon and 24 or 0)

    local Title = Create("TextLabel", {
        Text = cfg.Title or "Item",
        Font = Theme.FontBold,
        TextSize = 12,
        TextColor3 = Theme.TextSecondary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -textX - 18, 0, 14),
        Position = UDim2.fromOffset(textX, cfg.SubTitle and cfg.SubTitle ~= "" and 5 or (rowHeight-14)/2),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = NavBtn,
    })

    local Sub
    if cfg.SubTitle and cfg.SubTitle ~= "" then
        Sub = Create("TextLabel", {
            Text = cfg.SubTitle,
            Font = Theme.Font,
            TextSize = 9,
            TextColor3 = Theme.TextTertiary,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -textX - 18, 0, 11),
            Position = UDim2.fromOffset(textX, 19),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = NavBtn,
        })
    end

    local Chevron
    if cfg.Expandable then
        Chevron = Create("TextLabel", {
            Text = "⌄",
            Font = Theme.FontBold,
            TextSize = 11,
            TextColor3 = Theme.TextSecondary,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new(1, -22, 0, (rowHeight-16)/2),
            Parent = NavBtn,
        })
    end

    return NavBtn, Title, IconHolder, AccentBar, Chevron, Glow
end

function SidebarUI:CreateNavItem(cfg)
    cfg = cfg or {}
    local NavBtn, Title, IconHolder, AccentBar, _, Glow = BuildNavRow(self, cfg, 0)

    local PageScroll = Create("ScrollingFrame", {
        Size = UDim2.new(1, -24, 1, -46),
        Position = UDim2.fromOffset(12, 40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.Content,
    })
    Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = PageScroll,
    })

    local NavObj = { Button = NavBtn, Title = Title, Icon = IconHolder, Accent = AccentBar, Glow = Glow, Page = PageScroll }
    table.insert(self.NavItems, NavObj)
    local index = #self.NavItems

    local function select()
        for _, item in ipairs(self.NavItems) do
            item.Page.Visible = false
            Tween(item.Button, { BackgroundTransparency = 1 }, 0.15)
            Tween(item.Title, { TextColor3 = Theme.TextSecondary }, 0.15)
            if item.Accent then Tween(item.Accent, { BackgroundTransparency = 1 }, 0.15) end
            if item.Glow then Tween(item.Glow, { ImageTransparency = 1 }, 0.2) end
        end
        PageScroll.Visible = true
        Tween(NavBtn, { BackgroundTransparency = 0 }, 0.15)
        Tween(Title, { TextColor3 = Theme.TextPrimary }, 0.15)
        Tween(AccentBar, { BackgroundTransparency = 0 }, 0.15)
        if Glow then
            Glow.ImageTransparency = 1
            Tween(Glow, { ImageTransparency = 0.55 }, 0.35)
        end
    end

    NavBtn.MouseButton1Click:Connect(select)
    if index == 1 then select() end

    ------------------------------------------------
    -- API страницы: панели-категории (в 2 колонки)
    ------------------------------------------------
    local PageAPI = {}
    local RowHolder

    function PageAPI:CreatePanel(title, widthScale)
        widthScale = widthScale or 0.62

        if not RowHolder or #RowHolder:GetChildren() - 1 >= 2 then
            RowHolder = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = PageScroll,
            })
            Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = RowHolder,
            })
        end

        local Panel = Create("Frame", {
            Size = UDim2.new(widthScale, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.Panel,
            Parent = RowHolder,
        }, { Corner(8), Stroke() })

        local Header = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Theme.PanelHeader,
            Parent = Panel,
        }, { Corner(8) })
        Create("Frame", {
            Size = UDim2.new(1, 0, 0, 8),
            Position = UDim2.new(0, 0, 1, -8),
            BackgroundColor3 = Theme.PanelHeader,
            BorderSizePixel = 0,
            Parent = Header,
        })
        Create("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = Theme.Stroke,
            BorderSizePixel = 0,
            Parent = Header,
        })

        Create("TextLabel", {
            Text = title or "Category",
            Font = Theme.FontBold,
            TextSize = 12,
            TextColor3 = Theme.TextPrimary,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -40, 1, 0),
            Position = UDim2.fromOffset(12, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Header,
        })

        local Arrow = Create("TextLabel", {
            Text = "⌃",
            Font = Theme.FontBold,
            TextSize = 13,
            TextColor3 = Theme.TextSecondary,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(22, 22),
            Position = UDim2.new(1, -28, 0, 5),
            Parent = Header,
        })

        local Body = Create("Frame", {
            Size = UDim2.new(1, -16, 0, 0),
            Position = UDim2.fromOffset(8, 38),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = Panel,
        })
        Create("UIListLayout", {
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Body,
        })
        Create("UIPadding", { PaddingBottom = UDim.new(0, 8), Parent = Body })

        local collapsed = false
        local Click = Create("TextButton", {
            Text = "",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = Header,
        })
        Click.MouseButton1Click:Connect(function()
            collapsed = not collapsed
            Body.Visible = not collapsed
            Arrow.Text = collapsed and "⌄" or "⌃"
        end)

        local PanelAPI = {}

        function PanelAPI:CreateCheckbox(cfg2)
            cfg2 = cfg2 or {}
            local state = cfg2.Default or false

            local Row = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                Parent = Body,
            })

            local Box = Create("Frame", {
                Size = UDim2.fromOffset(15, 15),
                Position = UDim2.fromOffset(4, 4),
                BackgroundColor3 = state and Theme.Accent or Theme.PanelHeader,
                Parent = Row,
            }, { Corner(4), Stroke() })

            local Check = Create("TextLabel", {
                Text = "✓",
                Font = Theme.FontBold,
                TextSize = 11,
                TextColor3 = Theme.CheckMark,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = state,
                Parent = Box,
            })

            Create("TextLabel", {
                Text = cfg2.Text or "Option",
                Font = Theme.Font,
                TextSize = 12,
                TextColor3 = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, cfg2.Menu and -46 or -30, 1, 0),
                Position = UDim2.fromOffset(27, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row,
            })

            if cfg2.Menu then
                local MenuBtn = Create("TextButton", {
                    Text = "",
                    Size = UDim2.fromOffset(20, 20),
                    Position = UDim2.new(1, -22, 0.5, -10),
                    BackgroundTransparency = 1,
                    AutoButtonColor = false,
                    ZIndex = 2,
                    Parent = Row,
                })
                local dots = DrawIcon("dots", MenuBtn, Theme.TextSecondary)
                dots.Position = UDim2.fromOffset(2, 6)
                MenuBtn.MouseButton1Click:Connect(function()
                    if cfg2.OnMenu then task.spawn(cfg2.OnMenu) end
                end)
            end

            local Btn = Create("TextButton", {
                Text = "",
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Parent = Row,
            })
            Btn.MouseButton1Click:Connect(function()
                state = not state
                Box.BackgroundColor3 = state and Theme.Accent or Theme.PanelHeader
                Check.Visible = state
                if cfg2.Callback then task.spawn(cfg2.Callback, state) end
            end)

            return { Set = function(_, v) state = v end, Get = function() return state end }
        end

        -- строка-кнопка действия (как "lobby" / "teleport to map" на референсе)
        function PanelAPI:CreateButton(cfg2)
            cfg2 = cfg2 or {}

            local Row = Create("TextButton", {
                Text = "",
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = Theme.PanelHeader,
                AutoButtonColor = false,
                Parent = Body,
            }, { Corner(5) })

            Create("TextLabel", {
                Text = cfg2.Text or "Button",
                Font = Theme.FontBold,
                TextSize = 12,
                TextColor3 = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = Row,
            })

            Row.MouseEnter:Connect(function() Tween(Row, { BackgroundColor3 = Theme.Accent }, 0.15) end)
            Row.MouseLeave:Connect(function() Tween(Row, { BackgroundColor3 = Theme.PanelHeader }, 0.15) end)
            Row.MouseButton1Click:Connect(function()
                if cfg2.Callback then task.spawn(cfg2.Callback) end
            end)

            return Row
        end

        return PanelAPI
    end

    return PageAPI
end

-------------------------------------------------
-- Разворачиваемая группа с подпунктами (как Visuals -> Players/World)
-------------------------------------------------
function SidebarUI:CreateNavGroup(cfg)
    cfg = cfg or {}
    cfg.Expandable = true
    local NavBtn, Title, IconHolder, AccentBar, Chevron, Glow = BuildNavRow(self, cfg, 0)

    local SubHolder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = self._order,
        Visible = false,
        Parent = self.NavHolder,
    })
    Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = SubHolder,
    })

    local expanded = false
    local Click = Create("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = NavBtn,
    })
    Click.MouseButton1Click:Connect(function()
        expanded = not expanded
        SubHolder.Visible = expanded
        Tween(Chevron, { Rotation = expanded and 180 or 0 }, 0.15)
        if Glow then
            Tween(Glow, { ImageTransparency = expanded and 0.6 or 1 }, 0.3)
        end
    end)

    local GroupAPI = { SubHolder = SubHolder, self_ = self }

    function GroupAPI:AddSubItem(subcfg)
        subcfg = subcfg or {}
        self.self_._order = self.self_._order + 1
        local subOrder = self.self_._order

        local SubBtn = Create("TextButton", {
            Text = "",
            LayoutOrder = subOrder,
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = Theme.NavActiveBg,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Parent = SubHolder,
        }, { Corner(6) })

        if subcfg.Icon then
            local ic = DrawIcon(subcfg.Icon, SubBtn, Theme.TextTertiary)
            ic.Size = UDim2.fromOffset(14,14)
            ic.Position = UDim2.fromOffset(30, 7)
        end

        local SubTitle = Create("TextLabel", {
            Text = subcfg.Title or "Item",
            Font = Theme.Font,
            TextSize = 12,
            TextColor3 = Theme.TextSecondary,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -60, 1, 0),
            Position = UDim2.fromOffset(subcfg.Icon and 52 or 30, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = SubBtn,
        })

        local PageScroll = Create("ScrollingFrame", {
            Size = UDim2.new(1, -24, 1, -46),
            Position = UDim2.fromOffset(12, 40),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = self.self_.Content,
        })
        Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = PageScroll })

        local NavObj = { Button = SubBtn, Title = SubTitle, Page = PageScroll }
        table.insert(self.self_.NavItems, NavObj)

        local function select()
            for _, item in ipairs(self.self_.NavItems) do
                item.Page.Visible = false
                Tween(item.Button, { BackgroundTransparency = 1 }, 0.15)
                Tween(item.Title, { TextColor3 = Theme.TextSecondary }, 0.15)
                if item.Accent then Tween(item.Accent, { BackgroundTransparency = 1 }, 0.15) end
            end
            PageScroll.Visible = true
            Tween(SubBtn, { BackgroundTransparency = 0.5 }, 0.15)
            Tween(SubTitle, { TextColor3 = Theme.TextPrimary }, 0.15)
        end
        SubBtn.MouseButton1Click:Connect(select)

        local RowHolder
        local PageAPI = {}
        function PageAPI:CreatePanel(title, widthScale)
            widthScale = widthScale or 0.62
            if not RowHolder or #RowHolder:GetChildren() - 1 >= 2 then
                RowHolder = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Parent = PageScroll,
                })
                Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = RowHolder,
                })
            end
            local Panel = Create("Frame", {
                Size = UDim2.new(widthScale, -5, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Panel,
                Parent = RowHolder,
            }, { Corner(8), Stroke() })

            local Header = Create("Frame", { Size = UDim2.new(1,0,0,32), BackgroundColor3 = Theme.PanelHeader, Parent = Panel }, { Corner(8) })
            Create("Frame", { Size = UDim2.new(1,0,0,8), Position = UDim2.new(0,0,1,-8), BackgroundColor3 = Theme.PanelHeader, BorderSizePixel = 0, Parent = Header })
            Create("Frame", { Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,0), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = Header })
            Create("TextLabel", {
                Text = title or "Category", Font = Theme.FontBold, TextSize = 12, TextColor3 = Theme.TextPrimary,
                BackgroundTransparency = 1, Size = UDim2.new(1,-40,1,0), Position = UDim2.fromOffset(12,0),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Header,
            })

            local Body = Create("Frame", {
                Size = UDim2.new(1,-16,0,0), Position = UDim2.fromOffset(8,38),
                AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Panel,
            })
            Create("UIListLayout", { Padding = UDim.new(0,2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Body })
            Create("UIPadding", { PaddingBottom = UDim.new(0,8), Parent = Body })

            local PanelAPI = {}
            function PanelAPI:CreateCheckbox(cfg2)
                cfg2 = cfg2 or {}
                local state = cfg2.Default or false
                local Row = Create("Frame", { Size = UDim2.new(1,0,0,24), BackgroundTransparency = 1, Parent = Body })
                local Box = Create("Frame", {
                    Size = UDim2.fromOffset(15,15), Position = UDim2.fromOffset(4,4),
                    BackgroundColor3 = state and Theme.Accent or Theme.PanelHeader, Parent = Row,
                }, { Corner(4), Stroke() })
                local Check = Create("TextLabel", {
                    Text = "✓", Font = Theme.FontBold, TextSize = 11, TextColor3 = Theme.CheckMark,
                    BackgroundTransparency = 1, Size = UDim2.fromScale(1,1), Visible = state, Parent = Box,
                })
                Create("TextLabel", {
                    Text = cfg2.Text or "Option", Font = Theme.Font, TextSize = 12, TextColor3 = Theme.TextPrimary,
                    BackgroundTransparency = 1, Size = UDim2.new(1, cfg2.Menu and -46 or -30, 1, 0), Position = UDim2.fromOffset(27,0),
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = Row,
                })
                if cfg2.Menu then
                    local MenuBtn = Create("TextButton", {
                        Text = "", Size = UDim2.fromOffset(20,20), Position = UDim2.new(1,-22,0.5,-10),
                        BackgroundTransparency = 1, AutoButtonColor = false, ZIndex = 2, Parent = Row,
                    })
                    local dots = DrawIcon("dots", MenuBtn, Theme.TextSecondary)
                    dots.Position = UDim2.fromOffset(2, 6)
                    MenuBtn.MouseButton1Click:Connect(function()
                        if cfg2.OnMenu then task.spawn(cfg2.OnMenu) end
                    end)
                end
                local Btn = Create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1,1), Parent = Row })
                Btn.MouseButton1Click:Connect(function()
                    state = not state
                    Box.BackgroundColor3 = state and Theme.Accent or Theme.PanelHeader
                    Check.Visible = state
                    if cfg2.Callback then task.spawn(cfg2.Callback, state) end
                end)
                return { Set = function(_, v) state = v end, Get = function() return state end }
            end

            function PanelAPI:CreateButton(cfg2)
                cfg2 = cfg2 or {}
                local Row = Create("TextButton", {
                    Text = "", Size = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = Theme.PanelHeader, AutoButtonColor = false, Parent = Body,
                }, { Corner(5) })
                Create("TextLabel", {
                    Text = cfg2.Text or "Button", Font = Theme.FontBold, TextSize = 12, TextColor3 = Theme.TextPrimary,
                    BackgroundTransparency = 1, Size = UDim2.fromScale(1,1),
                    TextXAlignment = Enum.TextXAlignment.Center, Parent = Row,
                })
                Row.MouseEnter:Connect(function() Tween(Row, { BackgroundColor3 = Theme.Accent }, 0.15) end)
                Row.MouseLeave:Connect(function() Tween(Row, { BackgroundColor3 = Theme.PanelHeader }, 0.15) end)
                Row.MouseButton1Click:Connect(function()
                    if cfg2.Callback then task.spawn(cfg2.Callback) end
                end)
                return Row
            end

            return PanelAPI
        end

        return PageAPI
    end

    return GroupAPI
end

function SidebarUI:SelectNavItem(index)
    local item = self.NavItems[index]
    if item then
        for _, i in ipairs(self.NavItems) do i.Page.Visible = false end
        item.Page.Visible = true
    end
end

-------------------------------------------------
-- ДЕМО: наполнение по мотивам референса (нейтральный текст)
-- Удали этот блок, если подключаешь библиотеку как модуль.
-------------------------------------------------
local Window = SidebarUI:CreateWindow({ LogoText = "S" })

local Combat = Window:CreateNavItem({ Title = "Combat", SubTitle = "боевые настройки", Icon = "target" })
local P1 = Combat:CreatePanel("Category A", 0.62)
P1:CreateCheckbox({ Text = "Option 1", Default = true, Menu = true, Callback = function(v) print("Option 1:", v) end })
P1:CreateCheckbox({ Text = "Option 2", Callback = function(v) print("Option 2:", v) end })

local P2 = Combat:CreatePanel("Category B", 0.35)
P2:CreateCheckbox({ Text = "Option 3", Callback = function(v) print("Option 3:", v) end })

local P3 = Combat:CreatePanel("Category C", 0.62)
P3:CreateCheckbox({ Text = "Option 4", Callback = function(v) print("Option 4:", v) end })
P3:CreateButton({ Text = "Действие", Callback = function() print("Button pressed") end })

local VisualsGroup = Window:CreateNavGroup({ Title = "Visuals", SubTitle = "показ доп. боксов", Icon = "eye" })
local PlayersPage = VisualsGroup:AddSubItem({ Title = "Players", Icon = "users" })
PlayersPage:CreatePanel("Player Settings", 1.0):CreateCheckbox({ Text = "Show names", Default = true })

local WorldPage = VisualsGroup:AddSubItem({ Title = "World", Icon = "globe" })
WorldPage:CreatePanel("World Settings", 1.0):CreateCheckbox({ Text = "Show markers" })

Window:CreateNavItem({ Title = "Local", SubTitle = "настройки персонажа", Icon = "user" })
Window:CreateNavItem({ Title = "Colors", SubTitle = "color settings", Icon = "palette" })
Window:CreateNavItem({ Title = "Config", SubTitle = "menu settings", Icon = "save" })

Window:SelectNavItem(1)
