--[[
    🔥 TKL Hub 🔥
    Script Demo học tập (không đảm bảo bypass anti-cheat Roblox)

    Chức năng:
    - Auto Farm
    - Auto Fruit
    - Auto Pirates/Boss
    - Auto Switch thông minh
    - Anti AFK
    - Admin Detect (tự out game)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")

local farming, autoFruit, autoPirates, antiAFK, autoSwitch = false, false, false, false, true
local hubVisible = false

-- UI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 240, 0, 320)
Frame.Position = UDim2.new(0.5, -120, 0.5, -160)
Frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
Frame.Visible = false
Frame.Parent = ScreenGui

local UIListLayout = Instance.new("UIListLayout", Frame)
UIListLayout.Padding = UDim.new(0,5)

local function makeBtn(txt, func)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-10,0,40)
    b.Position = UDim2.new(0,5,0,0)
    b.Text = txt
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = Color3.fromRGB(50,50,50)
    b.Parent = Frame
    b.MouseButton1Click:Connect(func)
    return b
end

-- Buttons
local farmBtn = makeBtn("Farm: OFF", function()
    farming = not farming
    farmBtn.Text = farming and "Farm: ON" or "Farm: OFF"
end)

local fruitBtn = makeBtn("Auto Fruit: OFF", function()
    autoFruit = not autoFruit
    fruitBtn.Text = autoFruit and "Auto Fruit: ON" or "Auto Fruit: OFF"
end)

local pirateBtn = makeBtn("Auto Pirates: OFF", function()
    autoPirates = not autoPirates
    pirateBtn.Text = autoPirates and "Auto Pirates: ON" or "Auto Pirates: OFF"
end)

local antiAfkBtn = makeBtn("Anti AFK: OFF", function()
    antiAFK = not antiAFK
    antiAfkBtn.Text = antiAFK and "Anti AFK: ON" or "Anti AFK: OFF"
end)

local autoSwitchBtn = makeBtn("Auto Switch: ON", function()
    autoSwitch = not autoSwitch
    autoSwitchBtn.Text = autoSwitch and "Auto Switch: ON" or "Auto Switch: OFF"
end)

local closeBtn = makeBtn("Đóng Menu", function()
    Frame.Visible = false
    hubVisible = false
end)

-- Toggle menu
UserInputService.InputBegan:Connect(function(input,gp)
    if input.KeyCode == Enum.KeyCode.Insert then
        hubVisible = not hubVisible
        Frame.Visible = hubVisible
    end
end)

-- Anti AFK
LocalPlayer.Idled:Connect(function()
    if antiAFK then
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end
end)

-- Detect Admin
Players.PlayerAdded:Connect(function(p)
    if p:GetRankInGroup(1200769) >= 200 then -- ví dụ group Blox Fruits Staff
        warn("[TKL Hub] Admin vào game!")
        farming, autoFruit, autoPirates = false,false,false
        TeleportService:Teleport(tonumber(game.PlaceId), LocalPlayer)
    end
end)

-- Fake functions (bạn cần thay code farm/collect thật)
local function farmNPC()
    print("[TKL Hub] Đang farm NPC...")
end

local function collectFruit()
    print("[TKL Hub] Teleport nhặt trái spawn...")
end

local function fightPirates()
    print("[TKL Hub] Teleport đánh Hải Tặc Event...")
end

-- Main loop
RunService.RenderStepped:Connect(function()
    if farming then
        farmNPC()
    end

    if autoFruit then
        if autoSwitch then
            farming = false
        end
        collectFruit()
    end

    if autoPirates then
        if autoSwitch then
            farming = false
        end
        fightPirates()
    end
end)

print("[TKL Hub] Loaded ✅ Nhấn Insert để mở menu")
