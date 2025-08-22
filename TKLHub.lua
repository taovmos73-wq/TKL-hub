--[[
  ██████╗ ███╗   ███╗   T K L   H U B
  ╚════██╗████╗ ████║  Demo học tập – 1 file đầy đủ
  █████╔╝██╔████╔██║   • Toggle menu bằng nút trên màn hình (không cần Insert)
  ╚═══██╗██║╚██╔╝██║   • Auto Farm • Auto Fruit • Auto Pirates (sự kiện)
  ██████╔╝██║ ╚═╝ ██║  • Auto-Switch thông minh • Anti-AFK • Admin Detect + Auto Leave
  ╚═════╝ ╚═╝     ╚═╝  • Safe-FPS • Rejoin
  Lưu ý: Dùng script client có thể vi phạm điều khoản game. Tự chịu rủi ro.
]]--

-- ====== DỊCH VỤ / TIỆN ÍCH CƠ BẢN ======
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local TeleportService   = game:GetService("TeleportService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")

local LP     = Players.LocalPlayer
local Char   = LP.Character or LP.CharacterAdded:Wait()
local Root   = Char:WaitForChild("HumanoidRootPart")
local Hum    = Char:WaitForChild("Humanoid")

local function safe(fn, tag)
  local ok, err = pcall(fn)
  if not ok then warn("[TKL Hub]["..(tag or "err").."]", err) end
  return ok
end

local function tpCF(cf, timeSec)
  timeSec = timeSec or 0.35
  if not Root then return end
  local ti = TweenInfo.new(timeSec, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
  safe(function()
    TweenService:Create(Root, ti, {CFrame = cf}):Play()
  end, "tpCF")
end

local function equipBestWeapon()
  local best
  for _,tool in ipairs(LP.Backpack:GetChildren()) do
    if tool:IsA("Tool") then
      if (not best) or #tool.Name > #best.Name then
        best = tool
      end
    end
  end
  if best then
    safe(function() Hum:EquipTool(best) end, "equip")
  end
end

local function attackOnce()
  equipBestWeapon()
  local tool = Char:FindFirstChildOfClass("Tool")
  if tool and tool:FindFirstChild("Activate") then
    safe(function() tool:Activate() end, "tool:Activate")
  elseif tool and tool:FindFirstChild("RemoteEvent") then
    safe(function() tool.RemoteEvent:FireServer("Light") end, "tool:Remote")
  else
    -- fallback: nháy chuột ảo
    local vu = game:GetService("VirtualUser")
    vu:CaptureController()
    vu:ClickButton1(Vector2.new(0,0))
  end
end

-- ====== TRẠNG THÁI / CỜ BẬT TẮT ======
local STATE = {
  Farming     = false,
  AutoFruit   = false,
  AutoPirates = false,
  AutoSwitch  = true,
  AntiAFK     = true,
  SafeFPS     = false,
  AdminLeave  = true,
  BusyReason  = nil, -- "FRUIT" | "PIRATE" | nil
}

-- ====== UI: NÚT BẬT/TẮT + MENU ======
local Gui = Instance.new("ScreenGui")
Gui.Name = "TKLHubUI"
Gui.ResetOnSpawn = false
Gui.Parent = game.CoreGui

-- Nút toggle nhỏ (text, dễ dùng trên mobile/PC)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = Gui
ToggleBtn.Size = UDim2.new(0, 90, 0, 34)
ToggleBtn.Position = UDim2.new(0, 12, 0, 200)
ToggleBtn.Text = "TKL Menu"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
ToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.AutoButtonColor = true
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16
ToggleBtn.Active = true
ToggleBtn.Draggable = true -- kéo thả vị trí cho tiện

-- Frame menu
local Main = Instance.new("Frame")
Main.Parent = Gui
Main.Size = UDim2.new(0, 260, 0, 330)
Main.Position = UDim2.new(0.5, -130, 0.45, -165)
Main.BackgroundColor3 = Color3.fromRGB(23,23,23)
Main.Visible = true
Main.Active = true
Main.Draggable = true

local UICorner = Instance.new("UICorner", Main)
UICorner.CornerRadius = UDim.new(0,12)
local Pad = Instance.new("UIPadding", Main)
Pad.PaddingTop   = UDim.new(0,10)
Pad.PaddingLeft  = UDim.new(0,10)
Pad.PaddingRight = UDim.new(0,10)
Pad.PaddingBottom= UDim.new(0,10)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1,0,0,26)
Title.Text = "TKL Hub — vDemo"
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextSize = 18

local List = Instance.new("UIListLayout", Main)
List.Padding = UDim.new(0,8)
List.FillDirection = Enum.FillDirection.Vertical
List.SortOrder = Enum.SortOrder.LayoutOrder

local function mkToggle(text, initial, onChange)
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(1,0,0,34)
  b.BackgroundColor3 = Color3.fromRGB(40,40,40)
  b.TextColor3 = Color3.fromRGB(255,255,255)
  b.Font = Enum.Font.Gotham
  b.TextSize = 15
  b.AutoButtonColor = true
  b.Parent = Main
  local state = initial
  local function redraw()
    b.Text = string.format("%s: %s", text, state and "ON" or "OFF")
    b.BackgroundColor3 = state and Color3.fromRGB(60,110,60) or Color3.fromRGB(40,40,40)
  end
  redraw()
  b.MouseButton1Click:Connect(function()
    state = not state
    redraw()
    safe(function() onChange(state) end, "toggle-"..text)
  end)
  return b
end

mkToggle("Auto Farm", STATE.Farming, function(v) STATE.Farming = v end)
mkToggle("Auto Fruit", STATE.AutoFruit, function(v) STATE.AutoFruit = v end)
mkToggle("Auto Pirates", STATE.AutoPirates, function(v) STATE.AutoPirates = v end)
mkToggle("Auto Switch", STATE.AutoSwitch, function(v) STATE.AutoSwitch = v end)
mkToggle("Anti AFK", STATE.AntiAFK, function(v) STATE.AntiAFK = v end)
mkToggle("Safe FPS", STATE.SafeFPS, function(v)
  STATE.SafeFPS = v
  safe(function()
    workspace.StreamingEnabled = v
    settings().Rendering.QualityLevel = v and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
  end, "safe-fps")
end)
mkToggle("Admin Detect -> Leave", STATE.AdminLeave, function(v) STATE.AdminLeave = v end)

local Rejoin = Instance.new("TextButton", Main)
Rejoin.Size = UDim2.new(1,0,0,34)
Rejoin.BackgroundColor3 = Color3.fromRGB(70,40,40)
Rejoin.TextColor3 = Color3.fromRGB(255,255,255)
Rejoin.Font = Enum.Font.Gotham
Rejoin.TextSize = 15
Rejoin.Text = "Rejoin"
Rejoin.MouseButton1Click:Connect(function()
  TeleportService:Teleport(game.PlaceId, LP)
end)

-- Nút toggle frame
ToggleBtn.MouseButton1Click:Connect(function()
  Main.Visible = not Main.Visible
end)

-- ====== ANTI-AFK ======
LP.Idled:Connect(function()
  if STATE.AntiAFK then
    local vu = game:GetService("VirtualUser")
    vu:CaptureController()
    vu:ClickButton2(Vector2.new())
  end
end)

-- ====== ADMIN DETECT (ví dụ group staff – bạn chỉnh tuỳ ý) ======
local STAFF_GROUPS = {
  {id = 1200769, minRank = 200}, -- ví dụ Blox Fruits staff (tham khảo)
}
local function isStaff(p)
  for _,g in ipairs(STAFF_GROUPS) do
    safe(function()
      if p:GetRankInGroup(g.id) >= g.minRank then
        warn("[TKL Hub] Staff/QA phát hiện: "..p.Name.." (Group "..g.id..")")
        error("STAFF") -- thoát nhanh nhánh kiểm tra này
      end
    end, "check-rank")
  end
end

Players.PlayerAdded:Connect(function(p)
  if not STATE.AdminLeave then return end
  if p ~= LP then
    if p.AccountAge < 3 then return end
    local ok = pcall(function() isStaff(p) end)
    if not ok and STATE.AdminLeave then
      STATE.Farming, STATE.AutoFruit, STATE.AutoPirates = false,false,false
      TeleportService:Teleport(game.PlaceId, LP)
    end
  end
end)

-- ====== LOGIC TÌM MỤC TIÊU ======
local function isNPC(m)
  if not m:IsA("Model") then return false end
  local hum = m:FindFirstChildOfClass("Humanoid")
  local hrp = m:FindFirstChild("HumanoidRootPart")
  if hum and hrp and m ~= Char then
    -- tránh chọn người chơi
    if Players:GetPlayerFromCharacter(m) then return false end
    -- loại trừ object không liên quan
    if tostring(m.Name):lower():find("boss") or tostring(m.Name):lower():find("bandit") or hum.HealthMax > 1 then
      return true
    end
  end
  return false
end

local function nearestNPC()
  local best, bestDist
  for _,m in ipairs(workspace:GetDescendants()) do
    if isNPC(m) then
      local hrp = m:FindFirstChild("HumanoidRootPart")
      if hrp then
        local d = (hrp.Position - Root.Position).Magnitude
        if not best or d < bestDist then
          best, bestDist = m, d
        end
      end
    end
  end
  return best
end

local function isFruit(inst)
  local name = tostring(inst.Name):lower()
  return (name:find("fruit") or name:find("bomu") or name:find("kilo") or name:find("spin")) -- tuỳ mở rộng
end

local function findFruit()
  for _,inst in ipairs(workspace:GetDescendants()) do
    if inst:IsA("Tool") or inst:IsA("Model") or inst:IsA("BasePart") then
      if isFruit(inst) then
        local cf = inst:IsA("BasePart") and inst.CFrame or (inst:FindFirstChild("Handle") and inst.Handle.CFrame)
        if cf then return inst, cf end
      end
    end
  end
  return nil
end

local function piratesEventSpot()
  -- demo: tìm vùng có tên chứa "pirate" / "raid" / "event"
  for _,v in ipairs(workspace:GetDescendants()) do
    local n = tostring(v.Name):lower()
    if n:find("pirate") or n:find("raid") or n:find("event") then
      if v:IsA("BasePart") then return v.CFrame end
    end
  end
  return nil
end

-- ====== LUỒNG CHÍNH / AUTO-SWITCH ======
local function doFarmStep()
  local target = nearestNPC()
  if not target then return end
  local hrp = target:FindFirstChild("HumanoidRootPart")
  local hum = target:FindFirstChildOfClass("Humanoid")
  if not hrp or not hum or hum.Health <= 0 then return end
  tpCF(hrp.CFrame * CFrame.new(0, 0, 4)) -- tiếp cận
  attackOnce()
end

local function doPickFruit()
  local inst, cf = findFruit()
  if not inst or not cf then return false end
  STATE.BusyReason = "FRUIT"
  tpCF(cf + Vector3.new(0,3,0))
  task.wait(0.2)
  -- cố gắng nhặt (nếu là Tool)
  if inst:IsA("Tool") then
    safe(function() firetouchinterest(Root, inst.Handle, 0) end, "touch-0")
    task.wait(0.05)
    safe(function() firetouchinterest(Root, inst.Handle, 1) end, "touch-1")
  end
  task.wait(0.2)
  STATE.BusyReason = nil
  return true
end

local function doPirates()
  local cf = piratesEventSpot()
  if not cf then return false end
  STATE.BusyReason = "PIRATE"
  tpCF(cf + Vector3.new(0,5,0))
  -- đánh đại khái nếu có NPC gần
  for _=1,40 do
    doFarmStep()
    task.wait(0.05)
  end
  STATE.BusyReason = nil
  return true
end

-- vòng lặp điều phối thông minh
task.spawn(function()
  while task.wait(0.06) do
    -- ưu tiên FRUIT / PIRATE nếu bật AutoSwitch
    if STATE.AutoSwitch then
      if STATE.AutoFruit then
        local ok = doPickFruit()
        if ok then
          -- xong việc sẽ tiếp tục farm ở vòng sau
        end
      end
      if STATE.AutoPirates then
        local ok = doPirates()
        if ok then
          -- xong việc sẽ tiếp tục farm
        end
      end
    else
      -- nếu KHÔNG auto switch: chỉ chạy các job bật riêng
      if STATE.AutoFruit then doPickFruit() end
      if STATE.AutoPirates then doPirates() end
    end

    if STATE.Farming and not STATE.BusyReason then
      doFarmStep()
    end
  end
end)

print("[TKL Hub] Loaded ✅ • Có nút 'TKL Menu' để bật/tắt menu. Hãy tinh chỉnh hàm nhận diện NPC/Trái cho map bạn đang chơi.")
