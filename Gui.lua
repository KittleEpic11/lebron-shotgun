-- LocalScript (Place in StarterPlayerScripts)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ==================================================================
-- PASTE YOUR CODE BLOCKS BELOW (Edit these functions)
-- ==================================================================

-- Button 1 Code (Edit inside the function)
local function button1Code()
    -- PASTE YOUR CODE HERE
  
-- LocalScript (Place in StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local lockedTarget = nil

-- 1. REQUIRED INITIALIZATION
camera.CameraType = Enum.CameraType.Scriptable

-- 2. CONFIGURATION
local LOCK_ANGLE = math.cos(math.rad(15)) -- 15 degree cone
local HEAD_OFFSET = Vector3.new(0, 1.5, 0)

-- 3. VALIDATION FUNCTIONS
local function isEnemy(otherPlayer)
    -- Team check logic
    return player.Neutral 
        or otherPlayer.Neutral 
        or otherPlayer.Team ~= player.Team
end

local function isValidTarget(targetChar, otherPlayer)
    if not targetChar then return false end
    local humanoid = targetChar:FindFirstChild("Humanoid")
    return humanoid 
        and humanoid.Health > 0
        and isEnemy(otherPlayer)
end

-- 4. TARGET ACQUISITION
local function getHeadPosition(targetChar)
    local head = targetChar:FindFirstChild("Head")
    return head and (head.Position + HEAD_OFFSET)
end

local function findTarget()
    if not player.Character then return end
    local localHead = player.Character:FindFirstChild("Head")
    if not localHead then return end

    local cameraPos = camera.CFrame.Position
    local cameraLook = camera.CFrame.LookVector

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and isEnemy(otherPlayer) then
            local targetChar = otherPlayer.Character
            if isValidTarget(targetChar, otherPlayer) then
                local headPos = getHeadPosition(targetChar)
                if headPos then
                    local toTarget = (headPos - cameraPos).Unit
                    local dot = cameraLook:Dot(toTarget)
                    
                    -- 15 degree cone check
                    if dot > LOCK_ANGLE then
                        return targetChar
                    end
                end
            end
        end
    end
end

-- 5. LOCKING SYSTEM
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        lockedTarget = findTarget()
        
        if lockedTarget then
            RunService:BindToRenderStep("AimLock", Enum.RenderPriority.Camera.Value, function()
                if not isValidTarget(lockedTarget, Players:GetPlayerFromCharacter(lockedTarget)) then
                    RunService:UnbindFromRenderStep("AimLock")
                    lockedTarget = nil
                    return
                end
                
                local headPos = getHeadPosition(lockedTarget)
                if headPos then
                    camera.CFrame = CFrame.new(camera.CFrame.Position, headPos)
                end
            end)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RunService:UnbindFromRenderStep("AimLock")
        lockedTarget = nil
    end
end)
-- 2
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local function applyHighlight(character, player)
    -- Create Highlight object
    local highlight = Instance.new("Highlight")
    highlight.Name = "TeamHighlight"
    
    -- Configure highlight properties
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 1  -- Transparent fill (only outline visible)
    highlight.OutlineColor = player.TeamColor.Color
    
    -- Parent highlight to character
    highlight.Parent = character
end

local function onCharacterAdded(character, player)
    -- Wait for Humanoid to ensure character is fully loaded
    if character:WaitForChild("Humanoid") then
        -- Remove existing highlight if exists
        local existingHighlight = character:FindFirstChild("TeamHighlight")
        if existingHighlight then
            existingHighlight:Destroy()
        end
        
        -- Apply new highlight
        applyHighlight(character, player)
    end
end

local function onPlayerAdded(player)
    -- Handle character added event
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(character, player)
    end)
    
    -- Handle existing character
    if player.Character then
        onCharacterAdded(player.Character, player)
    end
end

-- Initialize for all current players
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

-- Connect for future players
Players.PlayerAdded:Connect(onPlayerAdded)
-- 3
local Players = game:GetService("Players")

local function createHealthBar(character)
    -- Wait for required components
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end

    -- Create health bar GUI
    local healthBar = Instance.new("BillboardGui")
    healthBar.Name = "PlayerHealthBar"
    healthBar.Adornee = hrp
    healthBar.Size = UDim2.new(4, 0, 0.5, 0)  -- Width: 4 studs, Height: 0.5 studs
    healthBar.StudsOffset = Vector3.new(0, 2.5, 0)  -- Position above head
    healthBar.AlwaysOnTop = true
    healthBar.MaxDistance = 100  -- Visible up to 100 studs away

    -- Background container
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    background.BackgroundTransparency = 0.3
    background.BorderSizePixel = 0
    background.Size = UDim2.new(1, 0, 1, 0)

    -- Health fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = Color3.new(1, 0, 0)  -- Red color
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
    fill.AnchorPoint = Vector2.new(0, 0.5)
    fill.Position = UDim2.new(0, 0, 0.5, 0)
    fill.ZIndex = 2

    -- Assemble GUI elements
    fill.Parent = background
    background.Parent = healthBar
    healthBar.Parent = character

    -- Update health bar when health changes
    humanoid.HealthChanged:Connect(function(currentHealth)
        fill.Size = UDim2.new(currentHealth / humanoid.MaxHealth, 0, 1, 0)
    end)
end

local function onCharacterAdded(character, player)
    -- Clean up existing health bar
    local existingBar = character:FindFirstChild("PlayerHealthBar")
    if existingBar then
        existingBar:Destroy()
    end
    
    -- Create new health bar
    if character:WaitForChild("Humanoid") then
        createHealthBar(character)
    end
end

local function onPlayerAdded(player)
    -- Connect character events
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(character, player)
    end)
    
    -- Handle existing character
    if player.Character then
        onCharacterAdded(player.Character, player)
    end
end

-- Initialize for all players
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
    print("Button 1 executed!")
end

-- Button 2 Code (Edit inside the function)
local function button2Code()
    -- PASTE YOUR CODE HERE
  --Credit to Kohltastrophe for most of this

local Player = game.Players.LocalPlayer
local Char = Player.Character
while not Char do wait()
	Char = Player.Character
end
local Humanoid = Char:WaitForChild("Humanoid")
local Root = Char:FindFirstChild("HumanoidRootPart")
while not Root do wait()
	Root = Char:FindFirstChild("HumanoidRootPart")
end
local Mouse = Player:GetMouse()
local Cam = game.Workspace.CurrentCamera

local dir = {w = 0, s = 0, a = 0, d = 0}
local spd = 2
Mouse.KeyDown:connect(function(key)
	if key:lower() == "w" then
		dir.w = 1
	elseif key:lower() == "s" then
		dir.s = 1
	elseif key:lower() == "a" then
		dir.a = 1
	elseif key:lower() == "d" then
		dir.d = 1
	elseif key:lower() == "q" then
		spd = spd + 1
	elseif key:lower() == "e" then
		spd = spd - 1
	end
end)
Mouse.KeyUp:connect(function(key)
	if key:lower() == "w" then
		dir.w = 0
	elseif key:lower() == "s" then
		dir.s = 0
	elseif key:lower() == "a" then
		dir.a = 0
	elseif key:lower() == "d" then
		dir.d = 0
	end
end)
Root.Anchored = true
Humanoid.PlatformStand = true
Humanoid.Changed:connect(function()
	Humanoid.PlatformStand = true
end)
repeat
	wait(1/44)
	Root.CFrame = CFrame.new(Root.Position, Cam.CoordinateFrame.p) 
		* CFrame.Angles(0,math.rad(180),0)
		* CFrame.new((dir.d-dir.a)*spd,0,(dir.s-dir.w)*spd)
until nil
    print("Button 2 executed!")
end

-- Button 3 Code (Edit inside the function)
local function button3Code()
    -- PASTE YOUR CODE HERE
  local enabled = true
local toggle = Enum.KeyCode.H
local mouse = game:GetService("Players").LocalPlayer:GetMouse()
game:GetService("RunService").RenderStepped:Connect(function()
    if mouse.Target.Parent:FindFirstChildOfClass("Humanoid") and mouse.Target.Parent:FindFirstChildOfClass("Humanoid").Health > 0 and game:GetService("Players"):GetPlayerFromCharacter(mouse.Target.Parent).Team ~= game:GetService("Players").LocalPlayer.Team and enabled then
        mouse1press()
        repeat
            game:GetService("RunService").RenderStepped:Wait()
        until not mouse.Target.Parent:FindFirstChildOfClass("Humanoid")
        mouse1release()
    end
end)

game:GetService("UserInputService").InputBegan:Connect(function(i,gp)
    if i.KeyCode == toggle then
        enabled = not enabled
        local hint = Instance.new("Hint",game.CoreGui)
        hint.Text = "Toggled: "..tostring(enabled)
        wait(1.5)
        hint:Destroy()
    end
end)
    print("Button 3 executed!")
end

-- Button 4 Code (Edit inside the function)
local function button4Code()
    -- PASTE YOUR CODE HERE
    print("Button 4 executed!")
end

-- Button 5 Code (Edit inside the function)
local function button5Code()
    -- PASTE YOUR CODE HERE
    print("Button 5 executed!")
end

-- ==================================================================
-- DON'T EDIT BELOW THIS LINE (GUI Setup)
-- ==================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0.2, 0, 0.4, 0)
MainFrame.Position = UDim2.new(0.01, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame

local buttons = {
    {name = "Ez Hax", func = button1Code},
    {name = "Noclip", func = button2Code},
    {name = "Trigger Bot", func = button3Code},
    {name = "NA", func = button4Code},
    {name = "NA", func = button5Code}
}

for _, btnData in ipairs(buttons) do
    local button = Instance.new("TextButton")
    button.Text = btnData.name
    button.Size = UDim2.new(1, 0, 0.2, 0)
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.SourceSansBold
    button.TextScaled = true
    
    button.MouseButton1Click:Connect(function()
        pcall(btnData.func) -- Safely execute code
    end)
    
    button.Parent = MainFrame
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.T and not gameProcessed then
        MainFrame.Visible = not MainFrame.Visible
    end
end)
