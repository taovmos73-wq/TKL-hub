-- TKL Hub (SAFE TEMPLATE) — dùng trong chính game của bạn
-- Yêu cầu: Bạn tag đối tượng trong Studio bằng CollectionService:
--  - "Fruit" cho item muốn nhặt (Part/Model có PrimaryPart)
--  - "Enemy" cho NPC thường
--  - "Boss" cho NPC boss
-- Ở Player có thể đặt Attribute Bool "IsAdmin" để demo tạm dừng

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

-- ========== GUI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TKLHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ảnh bật/tắt
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "Toggle"
ToggleBtn.Size = UDim2.new(0,64,0,64)
ToggleBtn.Position = UDim2.new(1,-80,1,-80)
ToggleBtn.AnchorPoint = Vector2.new(1,1)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Image = "rbxassetid://1234567890" -- TODO: đổi sang asset ảnh của bạn
ToggleBtn.Parent = ScreenGui

-- Khung menu
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0,360,0,320)
Main.Position = UDim2.new(1,-380,1,-380)
Main.AnchorPoint = Vector2.new(1,1)
Main.BackgroundColor3 = Color3.fromRGB(30,30,35)
Main.BorderSizePixel = 0
Main.Visible = false
Main.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,40)
Title.BackgroundColor3 = Color3.fromRGB(45,45,55)
Title.BorderSizePixel = 0
Title.Text = "⚡ TKL Hub (SAFE)"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = Main

local function mkToggle(text, order, onToggle)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-20,0,36)
    btn.Position = UDim2.new(0,10,0,50 + (order*42))
    btn.BackgroundColor3 = Color3.fromRGB(60,60,70)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Text = text .. " (Tắt)"
    btn.AutoButtonColor = true
    btn.Parent = Main
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = text .. (state and " (Bật)" or " (Tắt)")
        onToggle(state)
    end)
    return function() return state end, function(v) state=v; btn.Text=text..(state and " (Bật)" or " (Tắt)") end
end

ToggleBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

-- ========== TRẠNG THÁI ==========
local S = {
    AutoFarm = false,
    AutoCollect = false,
    AutoBoss = false,
    AutoSwitch = true, -- ưu tiên Collect > Boss > Farm
    StealthPause = false, -- tạm dừng khi có Admin (game của bạn)
}

-- ========== TIỆN ÍCH ==========
local function getChar(plr)
    plr = plr or LocalPlayer
    return plr.Character or plr.CharacterAdded:Wait()
end

local function root(cfChar)
    return cfChar:FindFirstChild("HumanoidRootPart")
end

local function primary(modelOrPart)
    if modelOrPart:IsA("Model") then
        return modelOrPart.PrimaryPart or modelOrPart:FindFirstChildWhichIsA("BasePart")
    elseif modelOrPart:IsA("BasePart") then
        return modelOrPart
    end
end

local function distance(a,b)
    if not a or not b then return math.huge end
    return (a.Position - b.Position).Magnitude
end

local function moveTo(targetPos)
    local ch = getChar()
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if hum and targetPos then
        hum:MoveTo(targetPos)
        hum.MoveToFinished:Wait()
    end
end

local function tweenTo(targetPos, speed)
    local ch = getChar()
    local hrp = root(ch)
    if not hrp or not targetPos then return end
    local dist = (hrp.Position - targetPos).Magnitude
    local t = TweenService:Create(hrp, TweenInfo.new(math.clamp(dist/(speed or 40),0.1,5), Enum.EasingStyle.Quad), {CFrame = CFrame.new(targetPos)})
    t:Play()
    t.Completed:Wait()
end

local function nearestTagged(tag)
    local ch = getChar()
    local hrp = root(ch)
    local best, bestD = nil, math.huge
    for _,obj in ipairs(CollectionService:GetTagged(tag)) do
        local p = primary(obj)
        if p and p:IsDescendantOf(workspace) then
            local d = distance(hrp, p)
            if d < bestD then
                best, bestD = obj, d
            end
        end
    end
    return best, bestD
end

-- ========== LOOP LOGIC ==========
local taskToken = {collect={}, boss={}, farm={}}

local function safeLoop(stepFn, gateFn, tokenTable, key, interval)
    coroutine.wrap(function()
        tokenTable[key] = {}
        local myToken = tokenTable[key]
        while gateFn() do
            if S.StealthPause then break end
            stepFn()
            task.wait(interval or 0.2)
            if myToken ~= tokenTable[key] then break end -- cancel if restarted
        end
    end)()
end

-- AutoCollect (Fruit)
local function startCollect()
    safeLoop(function()
        local target = nearestTagged("Fruit")
        if target then
            local p = primary(target)
            if p then
                -- di chuyển “người chơi” tới item để nhặt (do bạn tự viết trigger Touch/ProximityPrompt)
                tweenTo(p.Position + Vector3.new(0,3,0), 60)
                -- ví dụ kích hoạt ProximityPrompt nếu có
                local prompt = target:FindFirstChildOfClass("ProximityPrompt", true)
                if prompt then
                    fireproximityprompt(prompt)
                end
            end
        end
    end, function() return S.AutoCollect and not S.StealthPause end, taskToken, "collect", 0.25)
end

-- AutoBoss
local function startBoss()
    safeLoop(function()
        local boss = nearestTagged("Boss")
        if boss then
            local p = primary(boss)
            if p then
                tweenTo(p.Position + Vector3.new(0,5,0), 50)
                -- giả lập tấn công: tới gần boss
                moveTo(p.Position)
                -- bạn có thể thêm logic gây sát thương hợp pháp trong game của bạn
            end
        end
    end, function() return S.AutoBoss and not S.StealthPause and not S.AutoCollect end, taskToken, "boss", 0.25)
end

-- AutoFarm (Enemy)
local function startFarm()
    safeLoop(function()
        local enemy = nearestTagged("Enemy")
        if enemy then
            local p = primary(enemy)
            if p then
                tweenTo(p.Position + Vector3.new(0,5,0), 45)
                moveTo(p.Position)
                -- thêm combat hợp pháp trong game của bạn tại đây
            end
        end
    end, function()
        if S.StealthPause then return false end
        if S.AutoSwitch then
            -- ưu tiên: Collect > Boss > Farm
            return S.AutoFarm and not S.AutoCollect and not S.AutoBoss
        else
            return S.AutoFarm
        end
    end, taskToken, "farm", 0.25)
end

-- ========== NÚT / TOGGLE ==========
local getAF, setAF   = mkToggle("🔄 Auto Farm", 0, function(v) S.AutoFarm=v; if v then startFarm() end end)
local getAC, setAC   = mkToggle("🍏 Auto Collect", 1, function(v) S.AutoCollect=v; if v then startCollect() end end)
local getAB, setAB   = mkToggle("🗡 Auto Boss", 2, function(v) S.AutoBoss=v; if v then startBoss() end end)
local getAS, setAS   = mkToggle("🔀 Auto Switch", 3, function(v) S.AutoSwitch=v end)

-- Anti-AFK (vô hại)
local vu = game:GetService("VirtualUser")
Players.LocalPlayer.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame); task.wait(1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ========== PAUSE KHI CÓ ADMIN (TRONG GAME CỦA BẠN) ==========
-- Không phải “anti-ban”; đây chỉ là cơ chế **tạm dừng** nếu bạn phát hiện
-- người có quyền trong chính experience của bạn (ví dụ teammate QA).
local Banner = Instance.new("TextLabel")
Banner.Size = UDim2.new(1,0,0,30)
Banner.Position = UDim2.new(0,0,0,40)
Banner.BackgroundColor3 = Color3.fromRGB(120,30,30)
Banner.TextColor3 = Color3.fromRGB(255,255,255)
Banner.Font = Enum.Font.Gotham
Banner.TextSize = 14
Banner.Text = ""
Banner.Visible = false
Banner.Parent = Main

local function setStealthPause(pause, reason)
    S.StealthPause = pause
    Banner.Visible = pause
    Banner.Text = pause and ("⏸ Tạm dừng: "..(reason or "Admin hiện diện")) or ""
end

local function onPlayerAdded(plr)
    -- Ví dụ: bạn tự gán Attribute "IsAdmin" = true cho người test/admin trong game của bạn
    local function check()
        if plr:GetAttribute("IsAdmin") then
            setStealthPause(true, "Admin: "..plr.Name)
        end
    end
    check()
    plr.AttributeChanged:Connect(function(attr)
        if attr=="IsAdmin" then check() end
    end)
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _,p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end

-- Hotkeys nhanh
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.L then
        Main.Visible = not Main.Visible
    elseif input.KeyCode == Enum.KeyCode.K then
        setAS(not getAS())
    elseif input.KeyCode == Enum.KeyCode.J then
        setStealthPause(not S.StealthPause, "Toggle thủ công (J)")
    end
end)

StarterGui:SetCore("SendNotification", {Title="TKL Hub (SAFE)", Text="Đã khởi động trong game của bạn", Duration=5})
