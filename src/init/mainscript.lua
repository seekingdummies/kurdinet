
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local desyncEnabled = false
local startTime = 0
local timerConnection = nil

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.CoreGui
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 150, 0, 70)
frame.Position = UDim2.new(0.5, 0, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Transparency=1
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0.6, 0)
label.BackgroundTransparency = 1
label.Text = "OFF PORNO KEY:INSERT"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextSize = 16
label.Font = Enum.Font.GothamBold
label.Parent = frame

local function toggleDesync()
    desyncEnabled = not desyncEnabled
    Raknet.desync(desyncEnabled)
    
    if desyncEnabled then
        label.Text = "ON PORNO KEY:INSERT"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        label.Text = "OFF PORNO KEY:INSERT"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

local function onDeath()
    if desyncEnabled then
        desyncEnabled = false
        Raknet.desync(false)
        
        label.Text = "OFF PORNO KEY:INSERT"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

humanoid.Died:Connect(onDeath)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(onDeath)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        toggleDesync()
    end
end)
