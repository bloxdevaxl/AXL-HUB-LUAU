-- ╔══════════════════════════════════════════════════════════════╗
-- ║           CHAT REALTY - FULL SYSTEM v1.0                    ║
-- ║           Developers: YOUSIF_TOBE & AXL_7K                 ║
-- ║           © 2024 ChatRealty - All Rights Reserved           ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ┌─────────────────────────────────────────────────────┐
-- │  JSONBIN CONFIG - ضع بيانات JSONBin هنا             │
-- └─────────────────────────────────────────────────────┘
local JSONBIN_API_KEY  = "$2a$10$pzxXosBbXXur39PkfRYLmunYofz.qB15KUDxAV70Nm14e.Kq8Zl9C" -- ضع API Key هنا
local JSONBIN_BIN_ID   = "6a36f834f5f4af5e2915bce7"  -- ضع Bin ID للشات العالمي
local JSONBIN_FRIENDS_BIN = "6a36f87dda38895dfee438ef" -- Bin ID للأصدقاء

local UPDATE_INTERVAL  = 3    -- ثواني تحديث الشات
local CLEAR_INTERVAL   = 250  -- ثانية لمسح الغرفة كل مرة
local MAX_MESSAGES     = 50   -- أقصى رسائل تُحفظ

-- ══════════════════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local TextService      = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════════════════════════
--  DEVELOPER ACCOUNTS - Rainbow Aura Special
-- ══════════════════════════════════════════════════════════════
local DEVELOPERS = {
    ["YOUSIF_TOBE"] = true,
    ["AXL_7K"]      = true,
}

-- ══════════════════════════════════════════════════════════════
--  ROBLOX CHAT COLORS (same system)
-- ══════════════════════════════════════════════════════════════
local ROBLOX_COLORS = {
    Color3.fromRGB(253,41,67),
    Color3.fromRGB(1,162,255),
    Color3.fromRGB(2,184,87),
    Color3.fromRGB(255,165,0),
    Color3.fromRGB(170,0,255),
    Color3.fromRGB(255,230,0),
    Color3.fromRGB(0,200,200),
    Color3.fromRGB(255,100,180),
}

local function getPlayerColor(name)
    local hash = 0
    for i = 1, #name do
        hash = hash + string.byte(name, i)
    end
    return ROBLOX_COLORS[(hash % #ROBLOX_COLORS) + 1]
end

-- ══════════════════════════════════════════════════════════════
--  RAINBOW AURA for Developers
-- ══════════════════════════════════════════════════════════════
local rainbowHue = 0
local function getRainbowColor()
    rainbowHue = (rainbowHue + 1) % 360
    return Color3.fromHSV(rainbowHue / 360, 1, 1)
end

-- ══════════════════════════════════════════════════════════════
--  BAD WORD FILTER (Roblox-style)
-- ══════════════════════════════════════════════════════════════
local BAD_WORDS = {
    -- قائمة كلمات سيئة شائعة (Roblox style filter)
    "fuck","shit","bitch","ass","damn","crap","hell","bastard","dick","cock",
    "pussy","fag","nigga","nigger","whore","slut","retard","idiot","moron",
    "كس","خرا","زب","كلب","حمار","غبي","ابن","بنت","حيوان"
}

local function filterMessage(msg)
    local filtered = msg
    for _, word in ipairs(BAD_WORDS) do
        local pattern = word:gsub("(%W)", "%%%1")
        filtered = filtered:gsub(pattern, function(m)
            return string.rep("#", #m)
        end)
    end
    return filtered
end

local function hasBadWord(msg)
    local lower = msg:lower()
    for _, word in ipairs(BAD_WORDS) do
        if lower:find(word) then return true end
    end
    return false
end

-- ══════════════════════════════════════════════════════════════
--  JSONBIN HTTP HELPERS
-- ══════════════════════════════════════════════════════════════
local function jsonGet(binId)
    local ok, res = pcall(function()
        return game:HttpGet(
            "https://api.jsonbin.io/v3/b/" .. binId .. "/latest",
            true
        )
    end)
    if not ok then return nil end
    local decoded = HttpService:JSONDecode(res)
    return decoded and decoded.record
end

local function jsonSet(binId, data)
    pcall(function()
        local body = HttpService:JSONEncode(data)
        -- HttpService PUT (requires executor with HttpRequest)
        if syn and syn.request then
            syn.request({
                Url = "https://api.jsonbin.io/v3/b/" .. binId,
                Method = "PUT",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["X-Master-Key"]  = JSONBIN_API_KEY,
                },
                Body = body,
            })
        elseif http and http.request then
            http.request({
                Url = "https://api.jsonbin.io/v3/b/" .. binId,
                Method = "PUT",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["X-Master-Key"]  = JSONBIN_API_KEY,
                },
                Body = body,
            })
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--  DESTROY OLD GUI
-- ══════════════════════════════════════════════════════════════
if PlayerGui:FindFirstChild("ChatRealty") then
    PlayerGui.ChatRealty:Destroy()
end

-- ══════════════════════════════════════════════════════════════
--  HIDE ROBLOX CHAT
-- ══════════════════════════════════════════════════════════════
local function hideRobloxChat()
    local robloxChat = PlayerGui:FindFirstChild("Chat")
    if robloxChat then
        robloxChat.Enabled = false
    end
    -- Also hide the bubble chat button from topbar if exists
    local coreGui = game:GetService("CoreGui")
    pcall(function()
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    end)
end
hideRobloxChat()

-- ══════════════════════════════════════════════════════════════
--  MAIN SCREENGUI
-- ══════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChatRealty"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = PlayerGui

-- ══════════════════════════════════════════════════════════════
--  LOADING SCREEN (Full Black)
-- ══════════════════════════════════════════════════════════════
local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingScreen"
LoadingFrame.Size = UDim2.new(1,0,1,0)
LoadingFrame.Position = UDim2.new(0,0,0,0)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.ZIndex = 100
LoadingFrame.Parent = ScreenGui

-- Loading content frame (centered)
local LoadCenter = Instance.new("Frame")
LoadCenter.Size = UDim2.new(0,420,0,340)
LoadCenter.Position = UDim2.new(0.5,-210,0.5,-170)
LoadCenter.BackgroundTransparency = 1
LoadCenter.ZIndex = 101
LoadCenter.Parent = LoadingFrame

-- Logo / Title
local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1,0,0,70)
LoadTitle.Position = UDim2.new(0,0,0,0)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Text = "مرحبا بك في شات ريلتي"
LoadTitle.TextColor3 = Color3.fromRGB(255,255,255)
LoadTitle.Font = Enum.Font.GothamBold
LoadTitle.TextSize = 28
LoadTitle.ZIndex = 102
LoadTitle.Parent = LoadCenter

-- Subtitle developers
local LoadDev = Instance.new("TextLabel")
LoadDev.Size = UDim2.new(1,0,0,36)
LoadDev.Position = UDim2.new(0,0,0,75)
LoadDev.BackgroundTransparency = 1
LoadDev.Text = "مطورين: YOUSIF_TOBE  X  AXL_7K"
LoadDev.TextColor3 = Color3.fromRGB(180,180,180)
LoadDev.Font = Enum.Font.Gotham
LoadDev.TextSize = 16
LoadDev.ZIndex = 102
LoadDev.Parent = LoadCenter

-- Divider
local LoadDiv = Instance.new("Frame")
LoadDiv.Size = UDim2.new(0.85,0,0,1)
LoadDiv.Position = UDim2.new(0.075,0,0,120)
LoadDiv.BackgroundColor3 = Color3.fromRGB(60,60,60)
LoadDiv.BorderSizePixel = 0
LoadDiv.ZIndex = 102
LoadDiv.Parent = LoadCenter

-- Warning label
local LoadWarn = Instance.new("TextLabel")
LoadWarn.Size = UDim2.new(1,0,0,30)
LoadWarn.Position = UDim2.new(0,0,0,132)
LoadWarn.BackgroundTransparency = 1
LoadWarn.Text = "⚠️  تنبيه"
LoadWarn.TextColor3 = Color3.fromRGB(255,80,80)
LoadWarn.Font = Enum.Font.GothamBold
LoadWarn.TextSize = 18
LoadWarn.ZIndex = 102
LoadWarn.Parent = LoadCenter

local LoadWarnText = Instance.new("TextLabel")
LoadWarnText.Size = UDim2.new(1,0,0,60)
LoadWarnText.Position = UDim2.new(0,0,0,166)
LoadWarnText.BackgroundTransparency = 1
LoadWarnText.Text = "أي سب تلقائي يُرسل للمطورين\nولديهم كامل الحرية لحظرك  —  انتبه!"
LoadWarnText.TextColor3 = Color3.fromRGB(220,220,220)
LoadWarnText.Font = Enum.Font.Gotham
LoadWarnText.TextSize = 14
LoadWarnText.TextWrapped = true
LoadWarnText.ZIndex = 102
LoadWarnText.Parent = LoadCenter

-- Update link
local LoadLink = Instance.new("TextLabel")
LoadLink.Size = UDim2.new(1,0,0,24)
LoadLink.Position = UDim2.new(0,0,0,236)
LoadLink.BackgroundTransparency = 1
LoadLink.Text = "t.me/addlist/T6HlvZw2I9c3MGQy"
LoadLink.TextColor3 = Color3.fromRGB(0,162,255)
LoadLink.Font = Enum.Font.Gotham
LoadLink.TextSize = 12
LoadLink.ZIndex = 102
LoadLink.Parent = LoadCenter

-- Progress bar background
local ProgressBG = Instance.new("Frame")
ProgressBG.Size = UDim2.new(0.85,0,0,6)
ProgressBG.Position = UDim2.new(0.075,0,0,278)
ProgressBG.BackgroundColor3 = Color3.fromRGB(40,40,40)
ProgressBG.BorderSizePixel = 0
ProgressBG.ZIndex = 102
ProgressBG.Parent = LoadCenter
Instance.new("UICorner", ProgressBG).CornerRadius = UDim.new(0,3)

local ProgressFill = Instance.new("Frame")
ProgressFill.Size = UDim2.new(0,0,1,0)
ProgressFill.BackgroundColor3 = Color3.fromRGB(0,162,255)
ProgressFill.BorderSizePixel = 0
ProgressFill.ZIndex = 103
ProgressFill.Parent = ProgressBG
Instance.new("UICorner", ProgressFill).CornerRadius = UDim.new(0,3)

local LoadStatus = Instance.new("TextLabel")
LoadStatus.Size = UDim2.new(1,0,0,20)
LoadStatus.Position = UDim2.new(0,0,0,292)
LoadStatus.BackgroundTransparency = 1
LoadStatus.Text = "جاري التحميل..."
LoadStatus.TextColor3 = Color3.fromRGB(130,130,130)
LoadStatus.Font = Enum.Font.Gotham
LoadStatus.TextSize = 12
LoadStatus.ZIndex = 102
LoadStatus.Parent = LoadCenter

-- Copyright bottom
local LoadCopy = Instance.new("TextLabel")
LoadCopy.Size = UDim2.new(1,0,0,20)
LoadCopy.Position = UDim2.new(0,0,1,-30)
LoadCopy.BackgroundTransparency = 1
LoadCopy.Text = "© 2024 ChatRealty — All Rights Reserved"
LoadCopy.TextColor3 = Color3.fromRGB(60,60,60)
LoadCopy.Font = Enum.Font.Gotham
LoadCopy.TextSize = 11
LoadCopy.ZIndex = 102
LoadCopy.Parent = LoadingFrame

-- Animate progress bar
local function animateLoading(callback)
    local steps = {
        {0.2, "جاري تهيئة الواجهة..."},
        {0.45, "جاري الاتصال بالخادم..."},
        {0.65, "جاري تحميل الأصدقاء..."},
        {0.85, "جاري تطبيق الإعدادات..."},
        {1.0,  "اكتمل التحميل!"},
    }
    local i = 0
    local function nextStep()
        i = i + 1
        if i > #steps then
            task.wait(0.4)
            callback()
            return
        end
        local pct, label = steps[i][1], steps[i][2]
        LoadStatus.Text = label
        TweenService:Create(ProgressFill,
            TweenInfo.new(0.5, Enum.EasingStyle.Quint),
            {Size = UDim2.new(pct,0,1,0)}
        ):Play()
        task.delay(0.7, nextStep)
    end
    nextStep()
end

-- ══════════════════════════════════════════════════════════════
--  TOPBAR BUTTON (replaces Roblox chat button, same position)
-- ══════════════════════════════════════════════════════════════
-- Roblox chat button is at top-left corner, same coordinates
local TopbarButton = Instance.new("TextButton")
TopbarButton.Name = "ChatRealtyBtn"
TopbarButton.Size = UDim2.new(0, 44, 0, 44)
-- Same position as Roblox chat topbar icon (X=104 after leaderboard)
TopbarButton.Position = UDim2.new(0, 104, 0, 4)
TopbarButton.BackgroundColor3 = Color3.fromRGB(0,0,0)
TopbarButton.BorderSizePixel = 0
TopbarButton.ZIndex = 10
TopbarButton.Visible = false
TopbarButton.Parent = ScreenGui

local TopbarCorner = Instance.new("UICorner", TopbarButton)
TopbarCorner.CornerRadius = UDim.new(0, 8)

-- Chat bubble icon (same as Roblox)
local TopbarIcon = Instance.new("TextLabel", TopbarButton)
TopbarIcon.Size = UDim2.new(1,0,0.6,0)
TopbarIcon.Position = UDim2.new(0,0,0.05,0)
TopbarIcon.BackgroundTransparency = 1
TopbarIcon.Text = "💬"
TopbarIcon.TextSize = 20
TopbarIcon.Font = Enum.Font.GothamBold
TopbarIcon.ZIndex = 11

local TopbarLabel = Instance.new("TextLabel", TopbarButton)
TopbarLabel.Size = UDim2.new(1,0,0.38,0)
TopbarLabel.Position = UDim2.new(0,0,0.62,0)
TopbarLabel.BackgroundTransparency = 1
TopbarLabel.TextColor3 = Color3.fromRGB(255,255,255)
TopbarLabel.Font = Enum.Font.GothamBold
TopbarLabel.TextSize = 9
TopbarLabel.ZIndex = 11

-- ══════════════════════════════════════════════════════════════
--  MAIN CHAT FRAME (Left side, like Roblox)
-- ══════════════════════════════════════════════════════════════
local ChatFrame = Instance.new("Frame")
ChatFrame.Name = "ChatFrame"
-- Roblox chat is at bottom-left
ChatFrame.Size = UDim2.new(0, 350, 0, 240)
ChatFrame.Position = UDim2.new(0, 0, 1, -296)
ChatFrame.BackgroundTransparency = 1
ChatFrame.ZIndex = 5
ChatFrame.Visible = false
ChatFrame.Parent = ScreenGui

-- Messages scroll (transparent bg, messages appear on top)
local MessagesScroll = Instance.new("ScrollingFrame")
MessagesScroll.Name = "Messages"
MessagesScroll.Size = UDim2.new(1,0,1,-56)
MessagesScroll.Position = UDim2.new(0,0,0,0)
MessagesScroll.BackgroundTransparency = 1
MessagesScroll.BorderSizePixel = 0
MessagesScroll.ScrollBarThickness = 3
MessagesScroll.ScrollBarImageColor3 = Color3.fromRGB(100,100,100)
MessagesScroll.CanvasSize = UDim2.new(0,0,0,0)
MessagesScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
MessagesScroll.ZIndex = 6
MessagesScroll.Parent = ChatFrame

local MsgLayout = Instance.new("UIListLayout", MessagesScroll)
MsgLayout.SortOrder = Enum.SortOrder.LayoutOrder
MsgLayout.Padding = UDim.new(0,2)

local MsgPad = Instance.new("UIPadding", MessagesScroll)
MsgPad.PaddingLeft = UDim.new(0,8)
MsgPad.PaddingRight = UDim.new(0,8)
MsgPad.PaddingTop = UDim.new(0,4)

-- Input bar (same as Roblox - dark semi-transparent)
local InputBar = Instance.new("Frame")
InputBar.Size = UDim2.new(1,0,0,40)
InputBar.Position = UDim2.new(0,0,1,-40)
InputBar.BackgroundColor3 = Color3.fromRGB(25,25,25)
InputBar.BackgroundTransparency = 0.25
InputBar.BorderSizePixel = 0
InputBar.ZIndex = 6
InputBar.Parent = ChatFrame

local InputCorner = Instance.new("UICorner", InputBar)
InputCorner.CornerRadius = UDim.new(0,6)

local InputBox = Instance.new("TextBox", InputBar)
InputBox.Size = UDim2.new(1,-56,1,0)
InputBox.Position = UDim2.new(0,10,0,0)
InputBox.BackgroundTransparency = 1
InputBox.Text = ""
InputBox.PlaceholderText = "للدردشة..."
InputBox.PlaceholderColor3 = Color3.fromRGB(130,130,130)
InputBox.TextColor3 = Color3.fromRGB(255,255,255)
InputBox.Font = Enum.Font.Gotham
InputBox.TextSize = 14
InputBox.TextXAlignment = Enum.TextXAlignment.Left
InputBox.ClearTextOnFocus = false
InputBox.ZIndex = 7

local SendBtn = Instance.new("TextButton", InputBar)
SendBtn.Size = UDim2.new(0,40,0,32)
SendBtn.Position = UDim2.new(1,-46,0,4)
SendBtn.BackgroundColor3 = Color3.fromRGB(0,162,255)
SendBtn.Text = "↑"
SendBtn.TextColor3 = Color3.fromRGB(255,255,255)
SendBtn.Font = Enum.Font.GothamBold
SendBtn.TextSize = 16
SendBtn.ZIndex = 7
Instance.new("UICorner", SendBtn).CornerRadius = UDim.new(0,6)

-- ══════════════════════════════════════════════════════════════
--  BUBBLE CHAT (Roblox-style small bubbles above players)
-- ══════════════════════════════════════════════════════════════
local BillboardTemplate = Instance.new("BillboardGui")
BillboardTemplate.Size = UDim2.new(0,200,0,40)
BillboardTemplate.StudsOffset = Vector3.new(0,2.5,0)
BillboardTemplate.AlwaysOnTop = true
BillboardTemplate.ResetOnSpawn = false

local function showBubble(player, message)
    pcall(function()
        local char = player.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        -- Remove existing bubble
        local existing = head:FindFirstChild("ChatBubble")
        if existing then existing:Destroy() end
        local bg = BillboardTemplate:Clone()
        bg.Name = "ChatBubble"
        -- Bubble background
        local bubble = Instance.new("Frame", bg)
        bubble.Size = UDim2.new(0,0,0,0)
        bubble.AnchorPoint = Vector2.new(0.5,1)
        bubble.Position = UDim2.new(0.5,0,1,0)
        bubble.BackgroundColor3 = Color3.fromRGB(255,255,255)
        bubble.BorderSizePixel = 0
        bubble.AutomaticSize = Enum.AutomaticSize.XY
        Instance.new("UICorner",bubble).CornerRadius = UDim.new(0,12)
        local UIPad = Instance.new("UIPadding",bubble)
        UIPad.PaddingLeft   = UDim.new(0,10)
        UIPad.PaddingRight  = UDim.new(0,10)
        UIPad.PaddingTop    = UDim.new(0,6)
        UIPad.PaddingBottom = UDim.new(0,6)
        local txt = Instance.new("TextLabel",bubble)
        txt.Text = message
        txt.TextColor3 = Color3.fromRGB(30,30,30)
        txt.Font = Enum.Font.Gotham
        txt.TextSize = 14
        txt.BackgroundTransparency = 1
        txt.TextWrapped = true
        txt.AutomaticSize = Enum.AutomaticSize.XY
        txt.MaxVisibleGraphemes = -1
        bg.Size = UDim2.new(0,200,0,60)
        bg.Parent = head
        -- Auto destroy after 8 sec
        task.delay(8, function()
            if bg and bg.Parent then bg:Destroy() end
        end)
    end)
end

-- ══════════════════════════════════════════════════════════════
--  MESSAGE RENDERING
-- ══════════════════════════════════════════════════════════════
local msgCount = 0
local function addMessage(sender, text, isDev, isSystem)
    msgCount = msgCount + 1
    local row = Instance.new("Frame")
    row.Name = "Msg"..msgCount
    row.Size = UDim2.new(1,0,0,0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1
    row.LayoutOrder = msgCount
    row.Parent = MessagesScroll

    -- Semi-transparent message bg (hover effect like Roblox)
    local bg = Instance.new("Frame", row)
    bg.Size = UDim2.new(1,0,0,0)
    bg.AutomaticSize = Enum.AutomaticSize.Y
    bg.BackgroundColor3 = Color3.fromRGB(18,18,18)
    bg.BackgroundTransparency = 0.4
    bg.BorderSizePixel = 0
    Instance.new("UICorner",bg).CornerRadius = UDim.new(0,4)

    local pad = Instance.new("UIPadding",bg)
    pad.PaddingLeft = UDim.new(0,8)
    pad.PaddingRight = UDim.new(0,8)
    pad.PaddingTop = UDim.new(0,3)
    pad.PaddingBottom = UDim.new(0,3)

    local line = Instance.new("Frame",bg)
    line.Size = UDim2.new(1,-16,0,0)
    line.AutomaticSize = Enum.AutomaticSize.Y
    line.BackgroundTransparency = 1

    if isSystem then
        local sysTxt = Instance.new("TextLabel",line)
        sysTxt.Size = UDim2.new(1,0,0,0)
        sysTxt.AutomaticSize = Enum.AutomaticSize.Y
        sysTxt.BackgroundTransparency = 1
        sysTxt.Text = text
        sysTxt.TextColor3 = Color3.fromRGB(150,150,150)
        sysTxt.Font = Enum.Font.GothamItalic
        sysTxt.TextSize = 13
        sysTxt.TextWrapped = true
        sysTxt.TextXAlignment = Enum.TextXAlignment.Left
    else
        -- Name label
        local nameLabel = Instance.new("TextLabel",line)
        nameLabel.Size = UDim2.new(1,0,0,18)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextColor3 = getPlayerColor(sender)
        nameLabel.Text = sender
        if isDev then
            nameLabel.Text = "⭐ " .. sender
        end

        -- Rainbow for devs
        if isDev then
            RunService.Heartbeat:Connect(function()
                nameLabel.TextColor3 = getRainbowColor()
            end)
        end

        -- Message text
        local msgLabel = Instance.new("TextLabel",line)
        msgLabel.Size = UDim2.new(1,0,0,0)
        msgLabel.Position = UDim2.new(0,0,0,20)
        msgLabel.AutomaticSize = Enum.AutomaticSize.Y
        msgLabel.BackgroundTransparency = 1
        msgLabel.Text = text
        msgLabel.TextColor3 = Color3.fromRGB(255,255,255)
        msgLabel.Font = Enum.Font.Gotham
        msgLabel.TextSize = 14
        msgLabel.TextWrapped = true
        msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    end

    -- Auto scroll to bottom
    task.wait()
    MessagesScroll.CanvasPosition = Vector2.new(0, MessagesScroll.AbsoluteCanvasSize.Y)

    -- Delete old messages to save memory
    if msgCount > MAX_MESSAGES then
        local old = MessagesScroll:FindFirstChild("Msg"..(msgCount - MAX_MESSAGES))
        if old then old:Destroy() end
    end
end

-- ══════════════════════════════════════════════════════════════
--  GLOBAL CHAT STATE
-- ══════════════════════════════════════════════════════════════
local lastMessageCount = 0
local chatOpen = false

local function loadMessages()
    local data = jsonGet(JSONBIN_BIN_ID)
    if not data or not data.messages then return end
    local msgs = data.messages
    if #msgs == lastMessageCount then return end
    -- Only show new ones
    for i = lastMessageCount+1, #msgs do
        local m = msgs[i]
        local isDev = DEVELOPERS[m.sender] == true
        addMessage(m.sender, m.text, isDev, false)
        -- Show bubble if player exists
        local p = Players:FindFirstChild(m.sender)
        if p then showBubble(p, m.text) end
    end
    lastMessageCount = #msgs
end

local function sendMessage(text)
    if text == "" then return end
    local filtered = filterMessage(text)

    -- Report to devs if bad word
    if hasBadWord(text) then
        -- Log the original bad message
        pcall(function()
            local data = jsonGet(JSONBIN_BIN_ID) or {messages={},reports={}}
            if not data.reports then data.reports = {} end
            table.insert(data.reports, {
                sender = LocalPlayer.Name,
                text   = text,
                time   = os.time(),
            })
            jsonSet(JSONBIN_BIN_ID, data)
        end)
    end

    pcall(function()
        local data = jsonGet(JSONBIN_BIN_ID) or {messages={}}
        if not data.messages then data.messages = {} end
        table.insert(data.messages, {
            sender = LocalPlayer.Name,
            text   = filtered,
            time   = os.time(),
        })
        -- Keep last MAX_MESSAGES only
        while #data.messages > MAX_MESSAGES do
            table.remove(data.messages, 1)
        end
        jsonSet(JSONBIN_BIN_ID, data)
    end)
end

-- ══════════════════════════════════════════════════════════════
--  AUTO CLEAR ROOM CHAT every 250 seconds
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(CLEAR_INTERVAL)
        -- Clear all messages UI
        for _, child in ipairs(MessagesScroll:GetChildren()) do
            if child:IsA("Frame") and child.Name:sub(1,3) == "Msg" then
                child:Destroy()
            end
        end
        msgCount = 0
        lastMessageCount = 0
        addMessage("", "— تم تنظيف الشات تلقائياً —", false, true)
        -- Also clear JSONBin
        pcall(function()
            jsonSet(JSONBIN_BIN_ID, {messages={},reports={}})
        end)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  FRIENDS PANEL
-- ══════════════════════════════════════════════════════════════
local FriendsPanel = Instance.new("Frame")
FriendsPanel.Name = "FriendsPanel"
FriendsPanel.Size = UDim2.new(0,260,0,380)
FriendsPanel.Position = UDim2.new(0,354,1,-430)
FriendsPanel.BackgroundColor3 = Color3.fromRGB(30,30,30)
FriendsPanel.BackgroundTransparency = 0.05
FriendsPanel.BorderSizePixel = 0
FriendsPanel.ZIndex = 8
FriendsPanel.Visible = false
FriendsPanel.Parent = ScreenGui
Instance.new("UICorner",FriendsPanel).CornerRadius = UDim.new(0,8)

local FriendsTitle = Instance.new("TextLabel",FriendsPanel)
FriendsTitle.Size = UDim2.new(1,0,0,40)
FriendsTitle.BackgroundColor3 = Color3.fromRGB(20,20,20)
FriendsTitle.BackgroundTransparency = 0.3
FriendsTitle.Text = "👥  اختيار أصدقائك"
FriendsTitle.TextColor3 = Color3.fromRGB(255,255,255)
FriendsTitle.Font = Enum.Font.GothamBold
FriendsTitle.TextSize = 15
FriendsTitle.ZIndex = 9
Instance.new("UICorner",FriendsTitle).CornerRadius = UDim.new(0,8)

local FriendsScroll = Instance.new("ScrollingFrame",FriendsPanel)
FriendsScroll.Size = UDim2.new(1,0,1,-50)
FriendsScroll.Position = UDim2.new(0,0,0,44)
FriendsScroll.BackgroundTransparency = 1
FriendsScroll.BorderSizePixel = 0
FriendsScroll.ScrollBarThickness = 4
FriendsScroll.CanvasSize = UDim2.new(0,0,0,0)
FriendsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
FriendsScroll.ZIndex = 9

local FriendsList = Instance.new("UIListLayout",FriendsScroll)
FriendsList.Padding = UDim.new(0,4)
local FPad = Instance.new("UIPadding",FriendsScroll)
FPad.PaddingAll = UDim.new(0,8)

-- Private chat panel
local PrivateChat = Instance.new("Frame")
PrivateChat.Name = "PrivateChat"
PrivateChat.Size = UDim2.new(0,320,0,300)
PrivateChat.Position = UDim2.new(0,354,1,-340)
PrivateChat.BackgroundColor3 = Color3.fromRGB(26,26,26)
PrivateChat.BackgroundTransparency = 0.05
PrivateChat.BorderSizePixel = 0
PrivateChat.ZIndex = 8
PrivateChat.Visible = false
PrivateChat.Parent = ScreenGui
Instance.new("UICorner",PrivateChat).CornerRadius = UDim.new(0,8)

local PCHeader = Instance.new("Frame",PrivateChat)
PCHeader.Size = UDim2.new(1,0,0,40)
PCHeader.BackgroundColor3 = Color3.fromRGB(20,20,20)
PCHeader.BackgroundTransparency = 0.2
PCHeader.BorderSizePixel = 0
Instance.new("UICorner",PCHeader).CornerRadius = UDim.new(0,8)

local PCBack = Instance.new("TextButton",PCHeader)
PCBack.Size = UDim2.new(0,36,0,30)
PCBack.Position = UDim2.new(0,6,0,5)
PCBack.BackgroundColor3 = Color3.fromRGB(60,60,60)
PCBack.Text = "←"
PCBack.TextColor3 = Color3.fromRGB(255,255,255)
PCBack.Font = Enum.Font.GothamBold
PCBack.TextSize = 16
PCBack.ZIndex = 10
Instance.new("UICorner",PCBack).CornerRadius = UDim.new(0,6)

local PCTitle = Instance.new("TextLabel",PCHeader)
PCTitle.Size = UDim2.new(1,-50,1,0)
PCTitle.Position = UDim2.new(0,46,0,0)
PCTitle.BackgroundTransparency = 1
PCTitle.Text = "محادثة خاصة"
PCTitle.TextColor3 = Color3.fromRGB(255,255,255)
PCTitle.Font = Enum.Font.GothamBold
PCTitle.TextSize = 14
PCTitle.TextXAlignment = Enum.TextXAlignment.Left
PCTitle.ZIndex = 10

local PCScroll = Instance.new("ScrollingFrame",PrivateChat)
PCScroll.Size = UDim2.new(1,-16,1,-90)
PCScroll.Position = UDim2.new(0,8,0,46)
PCScroll.BackgroundTransparency = 1
PCScroll.BorderSizePixel = 0
PCScroll.ScrollBarThickness = 3
PCScroll.CanvasSize = UDim2.new(0,0,0,0)
PCScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PCScroll.ZIndex = 9

local PCMsgLayout = Instance.new("UIListLayout",PCScroll)
PCMsgLayout.Padding = UDim.new(0,4)

local PCInput = Instance.new("Frame",PrivateChat)
PCInput.Size = UDim2.new(1,0,0,40)
PCInput.Position = UDim2.new(0,0,1,-40)
PCInput.BackgroundColor3 = Color3.fromRGB(40,40,40)
PCInput.BackgroundTransparency = 0.2
PCInput.BorderSizePixel = 0
Instance.new("UICorner",PCInput).CornerRadius = UDim.new(0,6)

local PCBox = Instance.new("TextBox",PCInput)
PCBox.Size = UDim2.new(1,-56,1,0)
PCBox.Position = UDim2.new(0,10,0,0)
PCBox.BackgroundTransparency = 1
PCBox.Text = ""
PCBox.PlaceholderText = "رسالة خاصة..."
PCBox.PlaceholderColor3 = Color3.fromRGB(130,130,130)
PCBox.TextColor3 = Color3.fromRGB(255,255,255)
PCBox.Font = Enum.Font.Gotham
PCBox.TextSize = 14
PCBox.TextXAlignment = Enum.TextXAlignment.Left
PCBox.ClearTextOnFocus = false
PCBox.ZIndex = 10

local PCSend = Instance.new("TextButton",PCInput)
PCSend.Size = UDim2.new(0,40,0,32)
PCSend.Position = UDim2.new(1,-46,0,4)
PCSend.BackgroundColor3 = Color3.fromRGB(0,162,255)
PCSend.Text = "↑"
PCSend.TextColor3 = Color3.fromRGB(255,255,255)
PCSend.Font = Enum.Font.GothamBold
PCSend.TextSize = 16
PCSend.ZIndex = 10
Instance.new("UICorner",PCSend).CornerRadius = UDim.new(0,6)

-- ══════════════════════════════════════════════════════════════
--  RIGHTS TAB (Third tab)
-- ══════════════════════════════════════════════════════════════
local RightsPanel = Instance.new("Frame")
RightsPanel.Name = "RightsPanel"
RightsPanel.Size = UDim2.new(0,300,0,280)
RightsPanel.Position = UDim2.new(0,354,1,-300)
RightsPanel.BackgroundColor3 = Color3.fromRGB(20,20,20)
RightsPanel.BackgroundTransparency = 0.05
RightsPanel.BorderSizePixel = 0
RightsPanel.ZIndex = 8
RightsPanel.Visible = false
RightsPanel.Parent = ScreenGui
Instance.new("UICorner",RightsPanel).CornerRadius = UDim.new(0,8)

local RightsContent = Instance.new("TextLabel",RightsPanel)
RightsContent.Size = UDim2.new(1,-20,1,-20)
RightsContent.Position = UDim2.new(0,10,0,10)
RightsContent.BackgroundTransparency = 1
RightsContent.Font = Enum.Font.Gotham
RightsContent.TextSize = 14
RightsContent.TextColor3 = Color3.fromRGB(220,220,220)
RightsContent.TextWrapped = true
RightsContent.TextXAlignment = Enum.TextXAlignment.Right
RightsContent.TextYAlignment = Enum.TextYAlignment.Top
RightsContent.ZIndex = 9
RightsContent.Text = [[⚖️ مرحبا بك في حقوقنا

انسخ رابط التحديث:
t.me/addlist/T6HlvZw2I9c3MGQy

المطورون:
⭐ YOUSIF_TOBE
⭐ AXL_7K

© 2024 ChatRealty
جميع الحقوق محفوظة

أي نسخ أو توزيع
بدون إذن ممنوع]]
RightsContent.ZIndex = 9

-- ══════════════════════════════════════════════════════════════
--  FRIENDS TAB BUTTON (on topbar)
-- ══════════════════════════════════════════════════════════════
local FriendsBtn = Instance.new("TextButton")
FriendsBtn.Size = UDim2.new(0,44,0,44)
FriendsBtn.Position = UDim2.new(0,152,0,4)
FriendsBtn.BackgroundColor3 = Color3.fromRGB(0,0,0)
FriendsBtn.BorderSizePixel = 0
FriendsBtn.ZIndex = 10
FriendsBtn.Visible = false
FriendsBtn.Parent = ScreenGui
Instance.new("UICorner",FriendsBtn).CornerRadius = UDim.new(0,8)

local FriendsBtnLabel = Instance.new("TextLabel",FriendsBtn)
FriendsBtnLabel.Size = UDim2.new(1,0,0.6,0)
FriendsBtnLabel.Position = UDim2.new(0,0,0.05,0)
FriendsBtnLabel.BackgroundTransparency = 1
FriendsBtnLabel.Text = "👥"
FriendsBtnLabel.TextSize = 20
FriendsBtnLabel.Font = Enum.Font.GothamBold
FriendsBtnLabel.ZIndex = 11

local FriendsBtnTxt = Instance.new("TextLabel",FriendsBtn)
FriendsBtnTxt.Size = UDim2.new(1,0,0.38,0)
FriendsBtnTxt.Position = UDim2.new(0,0,0.62,0)
FriendsBtnTxt.BackgroundTransparency = 1
FriendsBtnTxt.TextColor3 = Color3.fromRGB(255,255,255)
FriendsBtnTxt.Font = Enum.Font.GothamBold
FriendsBtnTxt.TextSize = 8
FriendsBtnTxt.Text = "أصدقاء"
FriendsBtnTxt.ZIndex = 11

-- Rights button
local RightsBtn = Instance.new("TextButton")
RightsBtn.Size = UDim2.new(0,44,0,44)
RightsBtn.Position = UDim2.new(0,200,0,4)
RightsBtn.BackgroundColor3 = Color3.fromRGB(0,0,0)
RightsBtn.BorderSizePixel = 0
RightsBtn.ZIndex = 10
RightsBtn.Visible = false
RightsBtn.Parent = ScreenGui
Instance.new("UICorner",RightsBtn).CornerRadius = UDim.new(0,8)

local RightsBtnLabel = Instance.new("TextLabel",RightsBtn)
RightsBtnLabel.Size = UDim2.new(1,0,0.6,0)
RightsBtnLabel.Position = UDim2.new(0,0,0.05,0)
RightsBtnLabel.BackgroundTransparency = 1
RightsBtnLabel.Text = "⚖️"
RightsBtnLabel.TextSize = 20
RightsBtnLabel.Font = Enum.Font.GothamBold
RightsBtnLabel.ZIndex = 11

local RightsBtnTxt = Instance.new("TextLabel",RightsBtn)
RightsBtnTxt.Size = UDim2.new(1,0,0.38,0)
RightsBtnTxt.Position = UDim2.new(0,0,0.62,0)
RightsBtnTxt.BackgroundTransparency = 1
RightsBtnTxt.TextColor3 = Color3.fromRGB(255,255,255)
RightsBtnTxt.Font = Enum.Font.GothamBold
RightsBtnTxt.TextSize = 8
RightsBtnTxt.Text = "الحقوق"
RightsBtnTxt.ZIndex = 11

-- ══════════════════════════════════════════════════════════════
--  TOGGLE CHAT
-- ══════════════════════════════════════════════════════════════
local function toggleChat()
    chatOpen = not chatOpen
    ChatFrame.Visible = chatOpen
    if chatOpen then
        TopbarLabel.Text = "إغلاق"
        TopbarIcon.Text = "✖️"
        InputBox:CaptureFocus()
    else
        TopbarLabel.Text = "فتح"
        TopbarIcon.Text = "💬"
    end
end

TopbarButton.MouseButton1Click:Connect(toggleChat)

-- ══════════════════════════════════════════════════════════════
--  FRIENDS LOGIC
-- ══════════════════════════════════════════════════════════════
local currentPrivateFriend = nil

local function openPrivateChat(friendName)
    currentPrivateFriend = friendName
    PCTitle.Text = "💬 " .. friendName
    -- Clear old messages
    for _, c in ipairs(PCScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    FriendsPanel.Visible = false
    PrivateChat.Visible  = true
end

PCBack.MouseButton1Click:Connect(function()
    PrivateChat.Visible  = false
    FriendsPanel.Visible = true
    currentPrivateFriend = nil
end)

local function loadFriends()
    FriendsScroll:ClearAllChildren()
    Instance.new("UIListLayout",FriendsScroll).Padding = UDim.new(0,4)
    -- Get friends from Roblox API
    pcall(function()
        local friendsData = Players:GetFriendsAsync(LocalPlayer.UserId)
        local added = 0
        while friendsData.CurrentPage and added < 20 do
            for _, friend in ipairs(friendsData:GetCurrentPage()) do
                local row = Instance.new("TextButton",FriendsScroll)
                row.Size = UDim2.new(1,0,0,44)
                row.BackgroundColor3 = Color3.fromRGB(45,45,45)
                row.BackgroundTransparency = 0.2
                row.Text = ""
                row.ZIndex = 10
                Instance.new("UICorner",row).CornerRadius = UDim.new(0,6)

                -- Emoji avatar placeholder
                local emojiLabel = Instance.new("TextLabel",row)
                emojiLabel.Size = UDim2.new(0,36,1,0)
                emojiLabel.BackgroundTransparency = 1
                emojiLabel.Text = "👤"
                emojiLabel.TextSize = 22
                emojiLabel.Font = Enum.Font.GothamBold
                emojiLabel.ZIndex = 11

                local nameLabel = Instance.new("TextLabel",row)
                nameLabel.Size = UDim2.new(1,-44,0,22)
                nameLabel.Position = UDim2.new(0,40,0,5)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = friend.Username
                nameLabel.TextColor3 = getPlayerColor(friend.Username)
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextSize = 14
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.ZIndex = 11

                local statusLabel = Instance.new("TextLabel",row)
                statusLabel.Size = UDim2.new(1,-44,0,16)
                statusLabel.Position = UDim2.new(0,40,0,24)
                statusLabel.BackgroundTransparency = 1
                statusLabel.Text = friend.IsOnline and "🟢 متصل" or "⚫ غير متصل"
                statusLabel.TextColor3 = friend.IsOnline
                    and Color3.fromRGB(0,200,100)
                    or  Color3.fromRGB(120,120,120)
                statusLabel.Font = Enum.Font.Gotham
                statusLabel.TextSize = 11
                statusLabel.TextXAlignment = Enum.TextXAlignment.Left
                statusLabel.ZIndex = 11

                local fName = friend.Username
                row.MouseButton1Click:Connect(function()
                    openPrivateChat(fName)
                end)
                added = added + 1
            end
            if friendsData.IsFinished then break end
            friendsData:AdvanceToNextPageAsync()
        end
    end)
end

FriendsBtn.MouseButton1Click:Connect(function()
    FriendsPanel.Visible = not FriendsPanel.Visible
    PrivateChat.Visible = false
    if FriendsPanel.Visible then loadFriends() end
end)

RightsBtn.MouseButton1Click:Connect(function()
    RightsPanel.Visible = not RightsPanel.Visible
end)

-- ══════════════════════════════════════════════════════════════
--  PRIVATE CHAT SEND
-- ══════════════════════════════════════════════════════════════
local function sendPrivate(text)
    if text == "" or not currentPrivateFriend then return end
    local filtered = filterMessage(text)
    -- Add to UI
    local msg = Instance.new("Frame",PCScroll)
    msg.Size = UDim2.new(1,0,0,0)
    msg.AutomaticSize = Enum.AutomaticSize.Y
    msg.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel",msg)
    lbl.Size = UDim2.new(1,0,0,0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    local isDev = DEVELOPERS[LocalPlayer.Name] == true
    lbl.Text = (isDev and "⭐ " or "") .. LocalPlayer.Name .. ": " .. filtered
    lbl.TextColor3 = getPlayerColor(LocalPlayer.Name)
    -- Save to JSONBin under private key
    pcall(function()
        local key = "private_"..LocalPlayer.Name.."_"..currentPrivateFriend
        local data = jsonGet(JSONBIN_FRIENDS_BIN) or {}
        if not data[key] then data[key] = {} end
        table.insert(data[key], {
            from = LocalPlayer.Name,
            text = filtered,
            time = os.time(),
        })
        jsonSet(JSONBIN_FRIENDS_BIN, data)
    end)
    task.wait()
    PCScroll.CanvasPosition = Vector2.new(0, PCScroll.AbsoluteCanvasSize.Y)
end

PCSend.MouseButton1Click:Connect(function()
    local t = PCBox.Text
    PCBox.Text = ""
    sendPrivate(t)
end)
PCBox.FocusLost:Connect(function(enter)
    if enter then
        local t = PCBox.Text
        PCBox.Text = ""
        sendPrivate(t)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  GLOBAL CHAT SEND
-- ══════════════════════════════════════════════════════════════
SendBtn.MouseButton1Click:Connect(function()
    local t = InputBox.Text
    InputBox.Text = ""
    sendMessage(t)
end)
InputBox.FocusLost:Connect(function(enter)
    if enter then
        local t = InputBox.Text
        InputBox.Text = ""
        sendMessage(t)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  PERIODIC MESSAGE FETCH
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(UPDATE_INTERVAL)
        pcall(loadMessages)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  LAUNCH SEQUENCE - Animate Loading then show UI
-- ══════════════════════════════════════════════════════════════
animateLoading(function()
    -- Fade out loading screen
    TweenService:Create(LoadingFrame,
        TweenInfo.new(0.8, Enum.EasingStyle.Quint),
        {BackgroundTransparency = 1}
    ):Play()
    for _, desc in ipairs(LoadingFrame:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("Frame") then
            pcall(function()
                TweenService:Create(desc,
                    TweenInfo.new(0.6),
                    {BackgroundTransparency = 1, TextTransparency = 1}
                ):Play()
            end)
        end
    end
    task.wait(0.9)
    LoadingFrame:Destroy()

    -- Show topbar buttons
    TopbarButton.Visible = true
    FriendsBtn.Visible   = true
    RightsBtn.Visible    = true
    TopbarLabel.Text     = "فتح"
    TopbarIcon.Text      = "💬"

    -- Welcome system message
    addMessage("", "🟢 مرحبا بك في شات ريلتي!", false, true)
    addMessage("", "المطورون: YOUSIF_TOBE & AXL_7K", false, true)

    -- Initial load
    pcall(loadMessages)
end)

print("[ChatRealty] ✅ Loaded Successfully — by YOUSIF_TOBE & AXL_7K")
