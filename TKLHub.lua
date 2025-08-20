--========================================================--
-- 🔥 TKL Hub - All in one script for Blox Fruits
-- Made by GPT + User Cao Phúc
--========================================================--

-- 🪪 Khởi tạo GUI
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- GUI chính
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "TKLHub"

-- Nút bật/tắt menu (ảnh bạn đưa)
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0,60,0,60)
ToggleButton.Position = UDim2.new(0,10,0,200)
ToggleButton.Image = "rbxassetid://1234567890" -- 🔥 đổi ID ảnh bạn muốn

-- Khung menu
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0,300,0,400)
MainFrame.Position = UDim2.new(0,80,0,200)
MainFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true

-- Tiêu đề
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1,0,0,40)
Title.BackgroundColor3 = Color3.fromRGB(20,20,20)
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Text = "🔥 TKL Hub"
Title.TextScaled = true

-- Tạo container nút
local ButtonContainer = Instance.new("Frame", MainFrame)
ButtonContainer.Size = UDim2.new(1,0,1,-40)
ButtonContainer.Position = UDim2.new(0,0,0,40)
ButtonContainer.BackgroundTransparency = 1

-- Hàm tạo nút
local function CreateButton(name, callback)
    local btn = Instance.new("TextButton", ButtonContainer)
    btn.Size = UDim2.new(1,-20,0,40)
    btn.Position = UDim2.new(0,10,0,#ButtonContainer:GetChildren()*45)
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Text = name
    btn.TextScaled = true
    btn.MouseButton1Click:Connect(callback)
end

--========================================================--
-- 🔹 Các chức năng
--========================================================--

local autoFarm = false
local autoFruit = false
local autoRaid = false
local autoSwitch = true -- auto ưu tiên trái ác quỷ / boss
local adminCheck = true

-- Auto Farm
CreateButton("⚔️ Auto Farm (ON/OFF)", function()
    autoFarm = not autoFarm
    print("Auto Farm:", autoFarm)
end)

-- Auto Fruit
CreateButton("🍏 Auto Collect Fruit (ON/OFF)", function()
    autoFruit = not autoFruit
    print("Auto Fruit:", autoFruit)
end)

-- Auto Raid
CreateButton("💀 Auto Raid (ON/OFF)", function()
    autoRaid = not autoRaid
    print("Auto Raid:", autoRaid)
end)

-- Auto Switch
CreateButton("🔄 Auto Switch Mode (ON/OFF)", function()
    autoSwitch = not autoSwitch
    print("Auto Switch:", autoSwitch)
end)

-- Thoát game
CreateButton("🚪 Thoát Game", function()
    LocalPlayer:Kick("Bạn đã out game từ TKLHub")
end)

--========================================================--
-- 🔹 Toggle Menu
--========================================================--
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

--========================================================--
-- 🔥 Admin Detection
--========================================================--
local Admins = {
    [34612345] = true, -- ví dụ
    [11223344] = true, 
}

local WarningGui = Instance.new("TextLabel", ScreenGui)
WarningGui.Size = UDim2.new(1,0,0,50)
WarningGui.Position = UDim2.new(0,0,0,0)
WarningGui.BackgroundColor3 = Color3.fromRGB(255,0,0)
WarningGui.TextColor3 = Color3.fromRGB(255,255,255)
WarningGui.TextScaled = true
WarningGui.Text = ""
WarningGui.Visible = false

local function StopAll()
    autoFarm = false
    autoFruit = false
    autoRaid = false
    print("⚠️ Stop tất cả chức năng vì phát hiện Admin!")
end

local function CheckAdmin(plr)
    if Admins[plr.UserId] and adminCheck then
        WarningGui.Text = "⚠️ ADMIN " .. plr.Name .. " ĐANG ONLINE!"
        WarningGui.Visible = true
        StopAll()
        task.wait(3)
        LocalPlayer:Kick("Out game vì phát hiện Admin!")
    end
end

Players.PlayerAdded:Connect(CheckAdmin)
for _,plr in pairs(Players:GetPlayers()) do
    CheckAdmin(plr)
end

--========================================================--
print("🔥 TKL Hub đã khởi động thành công!")
--========================================================--
