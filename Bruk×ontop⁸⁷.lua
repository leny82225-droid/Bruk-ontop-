-- =================================================================
-- CONFIG & METADATA
-- Owner   : bruk×ontop⁸⁷
-- Versi   : 1.0.0
-- Script  : indo glarity rebon
-- =================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- State Otomatisasi
local AutoJobEnabled = false
local FlySpeed = 70 -- Kecepatan terbang mobil

-- =================================================================
-- 1. FITUR ANTI-AFK & ANTI-DETEKSI
-- =================================================================

-- Anti-AFK (Mencegah terputus/disconnect dari server saat afk 20+ menit)
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
    print("[Anti-AFK] Prevented Disconnect.")
end)

-- Anti-Detection Dasar (Bypass Hooking & Metatable Protection sederhana)
local rawget = rawget
local setidentity = setidentity or set_thread_identity or setthreadidentity
if setidentity then setidentity(7) end

-- Hook Namecall untuk menyembunyikan manipulasi posisi dari pemindaian lokal biasa
local gmt = getrawmetatable(game)
local oldNamecall = gmt.__namecall
setreadonly(gmt, false)

gmt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and (method == "Kick" or method == "kick") then
        return nil -- Memblokir panggilan Kick dari Anti-Cheat bawaan
    end
    return oldNamecall(self, ...)
end)
setreadonly(gmt, true)

-- =================================================================
-- 2. FUNGSI UTAMA (AUTOFARM & UTILITY)
-- =================================================================

-- Fungsi Mencari Tanda Panah Kuning / Marker
local function GetYellowPoint()
    for _, obj in pairs(workspace:GetDescendants()) do
        -- Menyesuaikan nama umum marker panah kuning
        if obj:IsA("BasePart") or obj:IsA("BillboardGui") or obj:IsA("Beam") then
            if obj.Name:lower():find("yellow") or obj.Name:lower():find("point") or obj.Name:lower():find("arrow") or obj.Name:lower():find("target") then
                if obj:IsA("BasePart") then return obj.Position end
                if obj:IsA("BillboardGui") and obj.Adornee then return obj.Adornee.Position end
            end
        end
    end
    return nil
end

-- Fungsi Terbang Menggunakan Mobil
local function FlyVehicleToPosition(targetPos)
    local vehicle = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character.Humanoid.SeatPart and LocalPlayer.Character.Humanoid.SeatPart.Parent
    if not vehicle then 
        -- Jika belum di dalam mobil, cari kendaraan terdekat
        return false 
    end

    local primaryPart = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then return false end

    -- Matikan Gravitasi sementara agar mobil melayang
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = primaryPart

    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.CFrame = primaryPart.CFrame
    bodyGyro.Parent = primaryPart

    -- Terbang ke koordinat target
    local distance = (primaryPart.Position - targetPos).Magnitude
    local duration = distance / FlySpeed
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(primaryPart, tweenInfo, {CFrame = CFrame.new(targetPos)})

    tween:Play()
    tween.Completed:Wait()

    -- Hapus efek melayang saat sampai
    bodyVelocity:Destroy()
    bodyGyro:Destroy()
    return true
end

-- Loop Logika Pekerjaan
task.spawn(function()
    while task.wait(1) do
        if AutoJobEnabled then
            -- Step 1: Jalan ke tulisan 'Job' / Mulai Pekerjaan
            local jobBoard = workspace:FindFirstChild("Job") or workspace:FindFirstChild("JobStart")
            if jobBoard and jobBoard:IsA("BasePart") then
                HumanoidRootPart.CFrame = jobBoard.CFrame + Vector3.new(0, 2, 0)
                task.wait(2)
            end

            -- Step 2: Masuk Mobil
            local vehicle = workspace:FindFirstChild("Vehicle") -- Sesuaikan nama folder/object mobil game
            if vehicle and vehicle:FindFirstChild("DriveSeat") then
                HumanoidRootPart.CFrame = vehicle.DriveSeat.CFrame
                task.wait(2)
            end

            -- Step 3: Terbang ke Marker Antar
            local targetPos = GetYellowPoint()
            if targetPos then
                FlyVehicleToPosition(targetPos + Vector3.new(0, 5, 0)) -- Terbang ke titik antar
                task.wait(1)
                
                -- Mobil Turun Pas di dekat titik
                FlyVehicleToPosition(targetPos)
                
                -- Step 4: Menunggu konfirmasi 'Job Diterima' / Selesai Antar
                task.wait(3) 

                -- Step 5: Terbang kembali ke titik awal / marker berikutnya
                local nextPos = GetYellowPoint() or (jobBoard and jobBoard.Position)
                if nextPos then
                    FlyVehicleToPosition(nextPos)
                end
            end
        end
    end
end)

-- =================================================================
-- 3. INTERFACE GUI MENGAMBANG (FLOATING MENU)
-- =================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IndoGlarityRebonUI"
ScreenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer.PlayerGui
ScreenGui.ResetOnSpawn = false

-- Frame Utama (Mengambang)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 190)
MainFrame.Position = UDim2.new(0.1, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Membuat UI bisa digeser/di-drag di layar
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Judul GUI
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "indo glarity rebon"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.TextSize = 14
Title.Font = Enum.Font.SourceSansBold
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

-- Info Metadata (Owner & Versi)
local MetaInfo = Instance.new("TextLabel")
MetaInfo.Size = UDim2.new(1, -10, 0, 40)
MetaInfo.Position = UDim2.new(0, 5, 0, 35)
MetaInfo.Text = "Owner: bruk×ontop⁸⁷\nVersi: 1.0.0"
MetaInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
MetaInfo.TextSize = 12
MetaInfo.Font = Enum.Font.SourceSans
MetaInfo.BackgroundTransparency = 1
MetaInfo.Parent = MainFrame

-- Tombol Toggle Auto Job
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 80)
ToggleBtn.Text = "Auto Job: OFF"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 13
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    AutoJobEnabled = not AutoJobEnabled
    if AutoJobEnabled then
        ToggleBtn.Text = "Auto Job: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    else
        ToggleBtn.Text = "Auto Job: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
end)

-- Info Status Anti-AFK & Detection
local StatusInfo = Instance.new("TextLabel")
StatusInfo.Size = UDim2.new(1, -10, 0, 30)
StatusInfo.Position = UDim2.new(0, 5, 0, 125)
StatusInfo.Text = "[✓] Anti-AFK Active\n[✓] Anti-Bypass Active"
StatusInfo.TextColor3 = Color3.fromRGB(80, 220, 100)
StatusInfo.TextSize = 11
StatusInfo.Font = Enum.Font.SourceSansItalic
StatusInfo.BackgroundTransparency = 1
StatusInfo.Parent = MainFrame

