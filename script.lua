-- ============================================================
-- RM HUB DUELS - COMPLETELY REDESIGNED GUI 
-- discord.gg/RdDfxStsU4 (Deep Ocean Edition)
-- ============================================================

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

-- Safe character wait - don't force anything
local function waitForCharacter()
    local char = Player.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
        return char
    end
    return Player.CharacterAdded:Wait()
end

-- Wait for character without forcing reset
task.spawn(function()
    waitForCharacter()
end)

if not getgenv then
    getgenv = function() return _G end
end

local ConfigFileName = "RMHub_Duels_Config.json" 

local Enabled = {
    SpeedBoost = false,
    AntiRagdoll = false,
    SpinBot = false,
    SpeedWhileStealing = false,
    AutoSteal = false,
    Unwalk = false,
    Optimizer = false,
    Galaxy = false,
    SpamBat = false,
    BatAimbot = false,
    AutoDisableSpeed = true,
    GalaxySkyBright = false,
    AutoWalkEnabled = false,
    AutoRightEnabled = false,
    ScriptUserESP = true
}

local Values = {
    BoostSpeed = 30,
    SpinSpeed = 30,
    StealingSpeedValue = 29,
    STEAL_RADIUS = 20,
    STEAL_DURATION = 1.3,
    DEFAULT_GRAVITY = 196.2,
    GalaxyGravityPercent = 70,
    HOP_POWER = 35,
    HOP_COOLDOWN = 0.08
}

local KEYBINDS = {
    SPEED = Enum.KeyCode.V,
    SPIN = Enum.KeyCode.N,
    GALAXY = Enum.KeyCode.M,
    BATAIMBOT = Enum.KeyCode.X,
    NUKE = Enum.KeyCode.Q,
    AUTOLEFT = Enum.KeyCode.Z,
    AUTORIGHT = Enum.KeyCode.C
}

-- Load Config FIRST before anything else
local configLoaded = false
pcall(function()
    if readfile and isfile and isfile(ConfigFileName) then
        local data = HttpService:JSONDecode(readfile(ConfigFileName))
        if data then
            for k, v in pairs(data) do
                if Enabled[k] ~= nil then
                    Enabled[k] = v
                end
            end
            for k, v in pairs(data) do
                if Values[k] ~= nil then
                    Values[k] = v
                end
            end
            if data.KEY_SPEED then KEYBINDS.SPEED = Enum.KeyCode[data.KEY_SPEED] end
            if data.KEY_SPIN then KEYBINDS.SPIN = Enum.KeyCode[data.KEY_SPIN] end
            if data.KEY_GALAXY then KEYBINDS.GALAXY = Enum.KeyCode[data.KEY_GALAXY] end
            if data.KEY_BATAIMBOT then KEYBINDS.BATAIMBOT = Enum.KeyCode[data.KEY_BATAIMBOT] end
            if data.KEY_AUTOLEFT then KEYBINDS.AUTOLEFT = Enum.KeyCode[data.KEY_AUTOLEFT] end
            if data.KEY_AUTORIGHT then KEYBINDS.AUTORIGHT = Enum.KeyCode[data.KEY_AUTORIGHT] end
            configLoaded = true
            print("[RM Hub] Config loaded successfully!") 
        end
    end
end)

-- Save Config
local function SaveConfig()
    local data = {}
    for k, v in pairs(Enabled) do
        data[k] = v
    end
    for k, v in pairs(Values) do
        data[k] = v
    end
    data.KEY_SPEED = KEYBINDS.SPEED.Name
    data.KEY_SPIN = KEYBINDS.SPIN.Name
    data.KEY_GALAXY = KEYBINDS.GALAXY.Name
    data.KEY_BATAIMBOT = KEYBINDS.BATAIMBOT.Name
    data.KEY_AUTOLEFT = KEYBINDS.AUTOLEFT.Name
    data.KEY_AUTORIGHT = KEYBINDS.AUTORIGHT.Name
    
    local success = false
    if writefile then
        pcall(function()
            writefile(ConfigFileName, HttpService:JSONEncode(data))
            success = true
        end)
    end
    return success
end

local Connections = {}
local isStealing = false
local lastBatSwing = 0
local BAT_SWING_COOLDOWN = 0.12

local SlapList = {
    {1, "Bat"}, {2, "Slap"}, {3, "Iron Slap"}, {4, "Gold Slap"},
    {5, "Diamond Slap"}, {6, "Emerald Slap"}, {7, "Ruby Slap"},
    {8, "Dark Matter Slap"}, {9, "Flame Slap"}, {10, "Nuclear Slap"},
    {11, "Galaxy Slap"}, {12, "Glitched Slap"}
}

local ADMIN_KEY = "78a772b6-9e1c-4827-ab8b-04a07838f298"
local REMOTE_EVENT_ID = "352aad58-c786-4998-886b-3e4fa390721e"
local BALLOON_REMOTE = ReplicatedStorage:FindFirstChild(REMOTE_EVENT_ID, true)

local function INSTANT_NUKE(target)
    if not BALLOON_REMOTE or not target then return end
    for _, p in ipairs({"balloon", "ragdoll", "jumpscare", "morph", "tiny", "rocket", "inverse", "jail"}) do
        BALLOON_REMOTE:FireServer(ADMIN_KEY, target, p)
    end
end

local function getNearestPlayer()
    local c = Player.Character
    if not c then return nil end
    local h = c:FindFirstChild("HumanoidRootPart")
    if not h then return nil end
    local pos = h.Position
    local nearest = nil
    local dist = math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local oh = p.Character:FindFirstChild("HumanoidRootPart")
            if oh then
                local d = (pos - oh.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = p
                end
            end
        end
    end
    return nearest
end

local function findBat()
    local c = Player.Character
    if not c then return nil end
    local bp = Player:FindFirstChildOfClass("Backpack")
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then
            return ch
        end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then
                return ch
            end
        end
    end
    for _, i in ipairs(SlapList) do
        local t = c:FindFirstChild(i[2]) or (bp and bp:FindFirstChild(i[2]))
        if t then return t end
    end
    return nil
end

local function startSpamBat()
    if Connections.spamBat then return end
    Connections.spamBat = RunService.Heartbeat:Connect(function()
        if not Enabled.SpamBat then return end
        local c = Player.Character
        if not c then return end
        local bat = findBat()
        if not bat then return end
        if bat.Parent ~= c then
            bat.Parent = c
        end
        local now = tick()
        if now - lastBatSwing < BAT_SWING_COOLDOWN then return end
        lastBatSwing = now
        pcall(function() bat:Activate() end)
    end)
end

local function stopSpamBat()
    if Connections.spamBat then
        Connections.spamBat:Disconnect()
        Connections.spamBat = nil
    end
end

local spinBAV = nil

local function startSpinBot()
    local c = Player.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if spinBAV then spinBAV:Destroy() spinBAV = nil end
    for _, v in pairs(hrp:GetChildren()) do
        if v.Name == "SpinBAV" then v:Destroy() end
    end
    spinBAV = Instance.new("BodyAngularVelocity")
    spinBAV.Name = "SpinBAV"
    spinBAV.MaxTorque = Vector3.new(0, math.huge, 0)
    spinBAV.AngularVelocity = Vector3.new(0, Values.SpinSpeed, 0)
    spinBAV.Parent = hrp
end

local function stopSpinBot()
    if spinBAV then spinBAV:Destroy() spinBAV = nil end
    local c = Player.Character
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, v in pairs(hrp:GetChildren()) do
                if v.Name == "SpinBAV" then v:Destroy() end
            end
        end
    end
end

-- ================================================================
-- ================================================================
local AutoWalkEnabled = false
local AutoRightEnabled = false

RunService.Heartbeat:Connect(function()
    if Enabled.SpinBot and spinBAV then
        if Player:GetAttribute("Stealing") then
            spinBAV.AngularVelocity = Vector3.new(0, 0, 0)
        else
            spinBAV.AngularVelocity = Vector3.new(0, Values.SpinSpeed, 0)
        end
    end
end)

-- Bat Aimbot (no radius limit, NO auto swing, purple line, smooth movement)
local aimbotTarget = nil

local function findNearestEnemy(myHRP)
    local nearest = nil
    local nearestDist = math.huge
    local nearestTorso = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            local torso = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - myHRP.Position).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearest = eh
                    nearestTorso = torso or eh
                end
            end
        end
    end
    return nearest, nearestDist, nearestTorso
end

local function startBatAimbot()
    if Connections.batAimbot then return end
    
    Connections.batAimbot = RunService.Heartbeat:Connect(function(dt)
        if not Enabled.BatAimbot then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        
        -- Equip bat if not equipped (no swinging)
        local bat = findBat()
        if bat and bat.Parent ~= c then
            hum:EquipTool(bat)
        end
        
        -- Find target
        local target, dist, torso = findNearestEnemy(h)
        aimbotTarget = torso or target
        
        if target and torso then
            local dir = (torso.Position - h.Position)
            local flatDir = Vector3.new(dir.X, 0, dir.Z)
            local flatDist = flatDir.Magnitude
            local spd = 55 -- Fixed aimbot speed
            
            if flatDist > 1.5 then
                local moveDir = flatDir.Unit
                h.AssemblyLinearVelocity = Vector3.new(moveDir.X * spd, h.AssemblyLinearVelocity.Y, moveDir.Z * spd)
            else
                local tv = target.AssemblyLinearVelocity
                h.AssemblyLinearVelocity = Vector3.new(tv.X, h.AssemblyLinearVelocity.Y, tv.Z)
            end
        end
    end)
end

local function stopBatAimbot()
    if Connections.batAimbot then
        Connections.batAimbot:Disconnect()
        Connections.batAimbot = nil
    end
    aimbotTarget = nil
end



-- Galaxy Mode
local galaxyVectorForce = nil
local galaxyAttachment = nil
local galaxyEnabled = false
local hopsEnabled = false
local lastHopTime = 0
local spaceHeld = false
local originalJumpPower = 50

-- Capture original jump power safely when character is ready
local function captureJumpPower()
    local c = Player.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum.JumpPower > 0 then
            originalJumpPower = hum.JumpPower
        end
    end
end

-- Capture on current character
task.spawn(function()
    task.wait(1)
    captureJumpPower()
end)

-- Recapture when character respawns
Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    captureJumpPower()
end)

local function setupGalaxyForce()
    pcall(function()
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        if galaxyVectorForce then galaxyVectorForce:Destroy() end
        if galaxyAttachment then galaxyAttachment:Destroy() end
        galaxyAttachment = Instance.new("Attachment")
        galaxyAttachment.Parent = h
        galaxyVectorForce = Instance.new("VectorForce")
        galaxyVectorForce.Attachment0 = galaxyAttachment
        galaxyVectorForce.ApplyAtCenterOfMass = true
        galaxyVectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
        galaxyVectorForce.Force = Vector3.new(0, 0, 0)
        galaxyVectorForce.Parent = h
    end)
end

local function updateGalaxyForce()
    if not galaxyEnabled or not galaxyVectorForce then return end
    local c = Player.Character
    if not c then return end
    local mass = 0
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            mass = mass + p:GetMass()
        end
    end
    local tg = Values.DEFAULT_GRAVITY * (Values.GalaxyGravityPercent / 100)
    galaxyVectorForce.Force = Vector3.new(0, mass * (Values.DEFAULT_GRAVITY - tg) * 0.95, 0)
end

local function adjustGalaxyJump()
    pcall(function()
        local c = Player.Character
        if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if not galaxyEnabled then
            hum.JumpPower = originalJumpPower
            return
        end
        local ratio = math.sqrt((Values.DEFAULT_GRAVITY * (Values.GalaxyGravityPercent / 100)) / Values.DEFAULT_GRAVITY)
        hum.JumpPower = originalJumpPower * ratio
    end)
end

local function doMiniHop()
    if not hopsEnabled then return end
    pcall(function()
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        if tick() - lastHopTime < Values.HOP_COOLDOWN then return end
        lastHopTime = tick()
        if hum.FloorMaterial == Enum.Material.Air then
            h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, Values.HOP_POWER, h.AssemblyLinearVelocity.Z)
        end
    end)
end

local function startGalaxy()
    galaxyEnabled = true
    hopsEnabled = true
    setupGalaxyForce()
    adjustGalaxyJump()
end

local function stopGalaxy()
    galaxyEnabled = false
    hopsEnabled = false
    if galaxyVectorForce then
        galaxyVectorForce:Destroy()
        galaxyVectorForce = nil
    end
    if galaxyAttachment then
        galaxyAttachment:Destroy()
        galaxyAttachment = nil
    end
    adjustGalaxyJump()
end

RunService.Heartbeat:Connect(function()
    if hopsEnabled and spaceHeld then
        doMiniHop()
    end
    if galaxyEnabled then
        updateGalaxyForce()
    end
end)

local function getMovementDirection()
    local c = Player.Character
    if not c then return Vector3.zero end
    local hum = c:FindFirstChildOfClass("Humanoid")
    return hum and hum.MoveDirection or Vector3.zero
end

local function isOnEnemyPlot()
    local character = Player.Character
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local playerPos = hrp.Position
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    
    for _, plot in ipairs(plots:GetChildren()) do
        local isMyPlot = false
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local yourBase = sign:FindFirstChild("YourBase")
            if yourBase and yourBase:IsA("BillboardGui") then 
                isMyPlot = yourBase.Enabled == true 
            end
        end
        
        if not isMyPlot then
            local plotPart = plot:FindFirstChild("Plot") or plot:FindFirstChildWhichIsA("BasePart")
            if plotPart and plotPart:IsA("BasePart") then
                local plotPos, plotSize = plotPart.Position, plotPart.Size
                if math.abs(playerPos.X - plotPos.X) <= plotSize.X/2 + 5 and 
                   math.abs(playerPos.Z - plotPos.Z) <= plotSize.Z/2 + 5 then 
                    return true 
                end
            end
            
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if podiums then
                for _, podium in ipairs(podiums:GetChildren()) do
                    local base = podium:FindFirstChild("Base")
                    if base then
                        local spawn = base:FindFirstChild("Spawn")
                        if spawn and (spawn.Position - playerPos).Magnitude <= 25 then 
                            return true 
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Auto walk/right destination coordinates (forward declared for speed boost check)
local POSITION_2 = Vector3.new(-483.12, -4.95, 94.80)
local POSITION_R2 = Vector3.new(-483.04, -5.09, 23.14)
local autoWalkPhase = 1
local autoRightPhase = 1

local function startSpeedBoost()
    if Connections.speed then return end
    Connections.speed = RunService.Heartbeat:Connect(function()
        if not Enabled.SpeedBoost then return end
        pcall(function()
            local c = Player.Character
            if not c then return end
            local h = c:FindFirstChild("HumanoidRootPart")
            if not h then return end
            local md = getMovementDirection()
            if md.Magnitude > 0.1 then
                h.AssemblyLinearVelocity = Vector3.new(md.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, md.Z * Values.BoostSpeed)
            end
        end)
    end)
end

local function stopSpeedBoost()
    if Connections.speed then
        Connections.speed:Disconnect()
        Connections.speed = nil
    end
end

-- ============================================
-- AUTO LEFT / AUTO RIGHT COORDINATE ESP
-- Small precise markers at exact positions
-- ============================================
local coordESPFolder = Instance.new("Folder", workspace)
coordESPFolder.Name = "OceanHub_CoordESP"

local function createCoordMarker(position, labelText, color)
    -- Small dot at exact position
    local dot = Instance.new("Part", coordESPFolder)
    dot.Name = "CoordMarker_" .. labelText
    dot.Anchored = true
    dot.CanCollide = false
    dot.CastShadow = false
    dot.Material = Enum.Material.Neon
    dot.Color = color
    dot.Shape = Enum.PartType.Ball
    dot.Size = Vector3.new(1, 1, 1)
    dot.Position = position
    dot.Transparency = 0.2

    -- Small billboard label
    local bb = Instance.new("BillboardGui", dot)
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 100, 0, 20)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.MaxDistance = 300

    local text = Instance.new("TextLabel", bb)
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = labelText
    text.TextColor3 = color
    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    text.TextStrokeTransparency = 0
    text.Font = Enum.Font.GothamBold
    text.TextSize = 12
    text.TextScaled = false

    return dot
end

-- Create markers at exact coordinates
createCoordMarker(Vector3.new(-476.48, -6.28, 92.73), "L1", Color3.fromRGB(64, 224, 208))
createCoordMarker(Vector3.new(-483.12, -4.95, 94.80), "L END", Color3.fromRGB(0, 191, 255))
createCoordMarker(Vector3.new(-476.16, -6.52, 25.62), "R1", Color3.fromRGB(72, 209, 204))
createCoordMarker(Vector3.new(-483.04, -5.09, 23.14), "R END", Color3.fromRGB(32, 178, 170))

-- Auto Walk
local autoWalkConnection = nil
local POSITION_1 = Vector3.new(-476.48, -6.28, 92.73)

local autoRightConnection = nil
local POSITION_R1 = Vector3.new(-476.16, -6.52, 25.62)

local function faceSouth()
    local c = Player.Character
    if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart")
    if not h then return end
    h.CFrame = CFrame.new(h.Position) * CFrame.Angles(0, 0, 0)
    local camera = workspace.CurrentCamera
    if camera then
        local camDistance = 12
        local camHeight = 5
        local charPos = h.Position
        camera.CFrame = CFrame.new(charPos.X, charPos.Y + camHeight, charPos.Z - camDistance) * CFrame.Angles(math.rad(-15), 0, 0)
    end
end

local function faceNorth()
    local c = Player.Character
    if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart")
    if not h then return end
    h.CFrame = CFrame.new(h.Position) * CFrame.Angles(0, math.rad(180), 0)
    local camera = workspace.CurrentCamera
    if camera then
        local camDistance = 12
        local charPos = h.Position
        camera.CFrame = CFrame.new(charPos.X, charPos.Y + 2, charPos.Z + camDistance) * CFrame.Angles(0, math.rad(180), 0)
    end
end

local function startAutoWalk()
    if autoWalkConnection then autoWalkConnection:Disconnect() end
    autoWalkPhase = 1
    
    autoWalkConnection = RunService.Heartbeat:Connect(function()
        if not AutoWalkEnabled then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        
        if autoWalkPhase == 1 then
            local targetPos = Vector3.new(POSITION_1.X, h.Position.Y, POSITION_1.Z)
            local dist = (targetPos - h.Position).Magnitude
            if dist < 1 then
                autoWalkPhase = 2
                -- Immediately start moving to coord 2 this same frame
                local dir = (POSITION_2 - h.Position)
                local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
                hum:Move(moveDir, false)
                h.AssemblyLinearVelocity = Vector3.new(moveDir.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, moveDir.Z * Values.BoostSpeed)
                return
            end
            local dir = (POSITION_1 - h.Position)
            local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
            hum:Move(moveDir, false)
            h.AssemblyLinearVelocity = Vector3.new(moveDir.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, moveDir.Z * Values.BoostSpeed)
            
        elseif autoWalkPhase == 2 then
            local targetPos = Vector3.new(POSITION_2.X, h.Position.Y, POSITION_2.Z)
            local dist = (targetPos - h.Position).Magnitude
            if dist < 1 then
                hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                AutoWalkEnabled = false
                Enabled.AutoWalkEnabled = false

                if _G.setAutoLeftVisual then _G.setAutoLeftVisual(false) end
                if VisualSetters and VisualSetters.AutoWalkEnabled then VisualSetters.AutoWalkEnabled(false, true) end
                if autoWalkConnection then autoWalkConnection:Disconnect() autoWalkConnection = nil end
                faceSouth()
                return
            end
            local dir = (POSITION_2 - h.Position)
            local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
            hum:Move(moveDir, false)
            h.AssemblyLinearVelocity = Vector3.new(moveDir.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, moveDir.Z * Values.BoostSpeed)
        end
    end)
end

local function stopAutoWalk()
    if autoWalkConnection then autoWalkConnection:Disconnect() autoWalkConnection = nil end
    autoWalkPhase = 1
    local c = Player.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then hum:Move(Vector3.zero, false) end
    end
end

local function startAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect() end
    autoRightPhase = 1
    
    autoRightConnection = RunService.Heartbeat:Connect(function()
        if not AutoRightEnabled then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        
        if autoRightPhase == 1 then
            local targetPos = Vector3.new(POSITION_R1.X, h.Position.Y, POSITION_R1.Z)
            local dist = (targetPos - h.Position).Magnitude
            if dist < 1 then
                autoRightPhase = 2
                local dir = (POSITION_R2 - h.Position)
                local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
                hum:Move(moveDir, false)
                h.AssemblyLinearVelocity = Vector3.new(moveDir.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, moveDir.Z * Values.BoostSpeed)
                return
            end
            local dir = (POSITION_R1 - h.Position)
            local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
            hum:Move(moveDir, false)
            h.AssemblyLinearVelocity = Vector3.new(moveDir.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, moveDir.Z * Values.BoostSpeed)
            
        elseif autoRightPhase == 2 then
            local targetPos = Vector3.new(POSITION_R2.X, h.Position.Y, POSITION_R2.Z)
            local dist = (targetPos - h.Position).Magnitude
            if dist < 1 then
                hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                AutoRightEnabled = false
                Enabled.AutoRightEnabled = false

                if _G.setAutoRightVisual then _G.setAutoRightVisual(false) end
                if VisualSetters and VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(false, true) end
                if autoRightConnection then autoRightConnection:Disconnect() autoRightConnection = nil end
                faceNorth()
                return
            end
            local dir = (POSITION_R2 - h.Position)
            local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
            hum:Move(moveDir, false)
            h.AssemblyLinearVelocity = Vector3.new(moveDir.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, moveDir.Z * Values.BoostSpeed)
        end
    end)
end

local function stopAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect() autoRightConnection = nil end
    autoRightPhase = 1
    local c = Player.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then hum:Move(Vector3.zero, false) end
    end
end

local function startAntiRagdoll()
    if Connections.antiRagdoll then return end
    Connections.antiRagdoll = RunService.Heartbeat:Connect(function()
        if not Enabled.AntiRagdoll then return end
        local char = Player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local humState = hum:GetState()
            if humState == Enum.HumanoidStateType.Physics or humState == Enum.HumanoidStateType.Ragdoll or humState == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                pcall(function()
                    if Player.Character then
                        local PlayerModule = Player.PlayerScripts:FindFirstChild("PlayerModule")
                        if PlayerModule then
                            local Controls = require(PlayerModule:FindFirstChild("ControlModule"))
                            Controls:Enable()
                        end
                    end
                end)
                if root then
                    root.Velocity = Vector3.new(0, 0, 0)
                    root.RotVelocity = Vector3.new(0, 0, 0)
                end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then obj.Enabled = true end
        end
    end)
end

local function stopAntiRagdoll()
    if Connections.antiRagdoll then
        Connections.antiRagdoll:Disconnect()
        Connections.antiRagdoll = nil
    end
end

local function startSpeedWhileStealing()
    if Connections.speedWhileStealing then return end
    Connections.speedWhileStealing = RunService.Heartbeat:Connect(function()
        if not Enabled.SpeedWhileStealing or not Player:GetAttribute("Stealing") then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        local md = getMovementDirection()
        if md.Magnitude > 0.1 then
            h.AssemblyLinearVelocity = Vector3.new(md.X * Values.StealingSpeedValue, h.AssemblyLinearVelocity.Y, md.Z * Values.StealingSpeedValue)
        end
    end)
end

local function stopSpeedWhileStealing()
    if Connections.speedWhileStealing then
        Connections.speedWhileStealing:Disconnect()
        Connections.speedWhileStealing = nil
    end
end

-- Auto Steal
local ProgressBarFill, ProgressLabel, ProgressPercentLabel, RadiusInput
local stealStartTime = nil
local progressConnection = nil
local StealData = {}

-- Discord text for progress bar
local DISCORD_TEXT = "discord.gg/RdDfxStsU4"

local function getDiscordProgress(percent)
    local totalChars = #DISCORD_TEXT
    -- Speed up the text reveal - complete by 70% progress so it's visible longer
    local adjustedPercent = math.min(percent * 1.5, 100)
    local charsToShow = math.floor((adjustedPercent / 100) * totalChars)
    return string.sub(DISCORD_TEXT, 1, charsToShow)
end

local function isMyPlotByName(pn)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(pn)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then
            return yb.Enabled == true
        end
    end
    return false
end

local function findNearestPrompt()
    local h = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not h then return nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local np, nd, nn = nil, math.huge, nil
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then continue end
        for _, pod in ipairs(podiums:GetChildren()) do
            pcall(function()
                local base = pod:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - h.Position).Magnitude
                    if dist < nd and dist <= Values.STEAL_RADIUS then
                        local att = spawn:FindFirstChild("PromptAttachment")
                        if att then
                            for _, ch in ipairs(att:GetChildren()) do
                                if ch:IsA("ProximityPrompt") then
                                    np, nd, nn = ch, dist, pod.Name
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
    return np, nd, nn
end

local function ResetProgressBar()
    if ProgressLabel then ProgressLabel.Text = "READY" end
    if ProgressPercentLabel then ProgressPercentLabel.Text = "" end
    if ProgressBarFill then ProgressBarFill.Size = UDim2.new(0, 0, 1, 0) end
end

local function executeSteal(prompt, name)
    if isStealing then return end
    if not StealData[prompt] then
        StealData[prompt] = {hold = {}, trigger = {}, ready = true}
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(StealData[prompt].hold, c.Function) end
                end
                for _, c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(StealData[prompt].trigger, c.Function) end
                end
            end
        end)
    end
    local data = StealData[prompt]
    if not data.ready then return end
    data.ready = false
    isStealing = true
    stealStartTime = tick()
    if ProgressLabel then ProgressLabel.Text = name or "STEALING..." end
    if progressConnection then progressConnection:Disconnect() end
    progressConnection = RunService.Heartbeat:Connect(function()
        if not isStealing then progressConnection:Disconnect() return end
        local prog = math.clamp((tick() - stealStartTime) / Values.STEAL_DURATION, 0, 1)
        if ProgressBarFill then ProgressBarFill.Size = UDim2.new(prog, 0, 1, 0) end
        if ProgressPercentLabel then 
            local percent = math.floor(prog * 100)
            ProgressPercentLabel.Text = getDiscordProgress(percent)
        end
    end)
    task.spawn(function()
        for _, f in ipairs(data.hold) do task.spawn(f) end
        task.wait(Values.STEAL_DURATION)
        for _, f in ipairs(data.trigger) do task.spawn(f) end
        if progressConnection then progressConnection:Disconnect() end
        ResetProgressBar()
        data.ready = true
        isStealing = false
    end)
end

local function startAutoSteal()
    if Connections.autoSteal then return end
    Connections.autoSteal = RunService.Heartbeat:Connect(function()
        if not Enabled.AutoSteal or isStealing then return end
        local p, _, n = findNearestPrompt()
        if p then executeSteal(p, n) end
    end)
end

local function stopAutoSteal()
    if Connections.autoSteal then
        Connections.autoSteal:Disconnect()
        Connections.autoSteal = nil
    end
    isStealing = false
    ResetProgressBar()
end

-- Unwalk
local savedAnimations = {}

local function startUnwalk()
    local c = Player.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
            t:Stop()
        end
    end
    local anim = c:FindFirstChild("Animate")
    if anim then
        savedAnimations.Animate = anim:Clone()
        anim:Destroy()
    end
end

local function stopUnwalk()
    local c = Player.Character
    if c and savedAnimations.Animate then
        savedAnimations.Animate:Clone().Parent = c
        savedAnimations.Animate = nil
    end
end

-- Optimizer
local originalTransparency = {}
local xrayEnabled = false

local function enableOptimizer()
    if getgenv and getgenv().OPTIMIZER_ACTIVE then return end
    if getgenv then getgenv().OPTIMIZER_ACTIVE = true end
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.Brightness = 3
        Lighting.FogEnd = 9e9
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    obj.Material = Enum.Material.Plastic
                end
            end)
        end
    end)
    xrayEnabled = true
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and (obj.Name:lower():find("base") or (obj.Parent and obj.Parent.Name:lower():find("base"))) then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.85
            end
        end
    end)
end

local function disableOptimizer()
    if getgenv then getgenv().OPTIMIZER_ACTIVE = false end
    if xrayEnabled then
        for part, value in pairs(originalTransparency) do
            if part then part.LocalTransparencyModifier = value end
        end
        originalTransparency = {}
        xrayEnabled = false
    end
end

-- Galaxy Sky Bright
local originalSkybox = nil
local galaxySkyBright = nil
local galaxySkyBrightConn = nil
local galaxyPlanets = {}
local galaxyBloom = nil
local galaxyCC = nil

local function enableGalaxySkyBright()
    if galaxySkyBright then return end
    
    originalSkybox = Lighting:FindFirstChildOfClass("Sky")
    if originalSkybox then originalSkybox.Parent = nil end
    
    galaxySkyBright = Instance.new("Sky")
    galaxySkyBright.SkyboxBk = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxDn = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxFt = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxLf = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxRt = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxUp = "rbxassetid://1534951537"
    galaxySkyBright.StarCount = 10000
    galaxySkyBright.CelestialBodiesShown = false
    galaxySkyBright.Parent = Lighting
    
    galaxyBloom = Instance.new("BloomEffect")
    galaxyBloom.Intensity = 1.5
    galaxyBloom.Size = 40
    galaxyBloom.Threshold = 0.8
    galaxyBloom.Parent = Lighting
    
    galaxyCC = Instance.new("ColorCorrectionEffect")
    galaxyCC.Saturation = 0.8
    galaxyCC.Contrast = 0.3
    galaxyCC.TintColor = Color3.fromRGB(200, 150, 255)
    galaxyCC.Parent = Lighting
    
    Lighting.Ambient = Color3.fromRGB(120, 60, 180)
    Lighting.Brightness = 3
    Lighting.ClockTime = 0
    
    for i = 1, 2 do
        local p = Instance.new("Part")
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(800 + i * 200, 800 + i * 200, 800 + i * 200)
        p.Anchored = true
        p.CanCollide = false
        p.CastShadow = false
        p.Material = Enum.Material.Neon
        p.Color = Color3.fromRGB(140 + i * 20, 60 + i * 10, 200 + i * 15)
        p.Transparency = 0.3
        p.Position = Vector3.new(math.cos(i * 2) * (3000 + i * 500), 1500 + i * 300, math.sin(i * 2) * (3000 + i * 500))
        p.Parent = workspace
        table.insert(galaxyPlanets, p)
    end
    
    galaxySkyBrightConn = RunService.Heartbeat:Connect(function()
        if not Enabled.GalaxySkyBright then return end
        local t = tick() * 0.5
        Lighting.Ambient = Color3.fromRGB(120 + math.sin(t) * 60, 50 + math.sin(t * 0.8) * 40, 180 + math.sin(t * 1.2) * 50)
        if galaxyBloom then
            galaxyBloom.Intensity = 1.2 + math.sin(t * 2) * 0.4
        end
    end)
end

local function disableGalaxySkyBright()
    if galaxySkyBrightConn then galaxySkyBrightConn:Disconnect() galaxySkyBrightConn = nil end
    if galaxySkyBright then galaxySkyBright:Destroy() galaxySkyBright = nil end
    if originalSkybox then originalSkybox.Parent = Lighting end
    if galaxyBloom then galaxyBloom:Destroy() galaxyBloom = nil end
    if galaxyCC then galaxyCC:Destroy() galaxyCC = nil end
    for _, obj in ipairs(galaxyPlanets) do
        if obj then obj:Destroy() end
    end
    galaxyPlanets = {}
    Lighting.Ambient = Color3.fromRGB(127, 127, 127)
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
end



-- ============================================
-- RMS SCRIPT USER ESP - OCEAN THEMED (GITHUB GIST) 
-- ALWAYS ACTIVE - NO TOGGLE - UNLIMITED REQUESTS
-- ============================================

-- Detect the correct request function for different executors
local httpRequest = nil

if syn and syn.request then
    httpRequest = syn.request
elseif http and http.request then
    httpRequest = http.request
elseif http_request then
    httpRequest = http_request
elseif request then
    httpRequest = request
elseif fluxus and fluxus.request then
    httpRequest = fluxus.request
elseif getgenv().request then
    httpRequest = getgenv().request
end

if not httpRequest then
    pcall(function()
        httpRequest = (getgenv and getgenv().request) or (shared and shared.request) or request
    end)
end

local GITHUB_TOKEN = "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"
local GIST_ID = "c2abee2486327152f66f97dc197e8f7e"
local GIST_FILENAME = "players.json"

local scriptUserESPs = {}
local espInitialized = false

-- Ocean colors for ESP
local oceanColors = {
    Color3.fromRGB(0, 105, 148),
    Color3.fromRGB(0, 119, 190),
    Color3.fromRGB(0, 153, 204),
    Color3.fromRGB(0, 180, 220),
    Color3.fromRGB(64, 224, 208),
    Color3.fromRGB(72, 209, 204),
    Color3.fromRGB(32, 178, 170),
    Color3.fromRGB(0, 206, 209),
}

local function lerpColor(c1, c2, t)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

local function getOceanColor(offset)
    local speed = 1.2
    local time = tick() * speed + offset
    local index = math.floor(time % #oceanColors) + 1
    local nextIndex = (index % #oceanColors) + 1
    local t = time % 1
    return lerpColor(oceanColors[index], oceanColors[nextIndex], t)
end

-- Forward declarations
local scanFromData
local createScriptUserESP
local cleanScriptUserESP
local scanBinUsers

local function addSelfToBin()
    if not httpRequest then return false end
    
    local success = false
    local data = {players = {}}
    
    local ok, err = pcall(function()
        -- GET current gist
        local response = httpRequest({
            Url = "https://api.github.com/gists/" .. GIST_ID,
            Method = "GET",
            Headers = {
                ["Authorization"] = "token " .. GITHUB_TOKEN,
                ["Accept"] = "application/vnd.github.v3+json"
            }
        })
        
        if response and response.Body then
            local gistData = HttpService:JSONDecode(response.Body)
            if gistData and gistData.files and gistData.files[GIST_FILENAME] then
                local content = gistData.files[GIST_FILENAME].content
                data = HttpService:JSONDecode(content) or {players = {}}
            end
            
            -- Check if already whitelisted
            local alreadyExists = false
            for _, p in ipairs(data.players) do
                if p.name == Player.Name then
                    alreadyExists = true
                    break
                end
            end
            
            -- Only PATCH if we're NEW (saves requests!)
            if not alreadyExists then
                table.insert(data.players, {
                    name = Player.Name,
                    displayName = Player.DisplayName
                })
                
                local patchResponse = httpRequest({
                    Url = "https://api.github.com/gists/" .. GIST_ID,
                    Method = "PATCH",
                    Headers = {
                        ["Authorization"] = "token " .. GITHUB_TOKEN,
                        ["Accept"] = "application/vnd.github.v3+json",
                        ["Content-Type"] = "application/json"
                    },
                    Body = HttpService:JSONEncode({
                        files = {
                            [GIST_FILENAME] = {
                                content = HttpService:JSONEncode(data)
                            }
                        }
                    })
                })
                
                if patchResponse and patchResponse.StatusCode == 200 then
                    print("[RM Hub] Whitelisted!") 
                end
            else
                print("[RM Hub] Already whitelisted!") 
            end
            
            success = true
            
            -- Scan from data we have
            task.spawn(function()
                task.wait(0.5)
                scanFromData(data)
            end)
        end
    end)
    if not success and err then
        print("[RM Hub DEBUG] Error: " .. tostring(err)) 
    end
    return success
end

createScriptUserESP = function(playerName)
    if scriptUserESPs[playerName] then return end
    if playerName == Player.Name then return end
    
    local player = Players:FindFirstChild(playerName)
    if not player or not player.Character then return end
    
    local head = player.Character:FindFirstChild("Head")
    if not head then return end
    
    -- Check if this is the owner or developer
    local isOwner = (playerName:lower() == "taleget")
    local isDeveloper = (playerName:lower() == "kenzoflx699")

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "OceanHubScriptESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 350, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.MaxDistance = math.huge
    billboard.Parent = head

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Parent = billboard
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBlack
    textLabel.TextSize = 38
    
    if isOwner then
        textLabel.Text = "👑 owner of RMs hub 👑" 
        textLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        textLabel.TextStrokeColor3 = Color3.fromRGB(139, 90, 0)
    elseif isDeveloper then
        textLabel.Text = "😡 RMS HUB Developer 😡" 
        textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        textLabel.TextStrokeColor3 = Color3.fromRGB(139, 0, 0)
    else
        textLabel.Text = "using ocean hub duels"
        textLabel.TextColor3 = Color3.fromRGB(0, 180, 220)
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 70, 120)
    end
    textLabel.TextStrokeTransparency = 0

    local highlight = Instance.new("Highlight")
    highlight.Name = "RMHubHighlight" 
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = player.Character
    
    if isOwner then
        highlight.FillColor = Color3.fromRGB(255, 215, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 185, 0)
    elseif isDeveloper then
        highlight.FillColor = Color3.fromRGB(255, 50, 50)
        highlight.OutlineColor = Color3.fromRGB(200, 0, 0)
    else
        highlight.FillColor = Color3.fromRGB(0, 153, 204)
        highlight.OutlineColor = Color3.fromRGB(0, 206, 209)
    end

    scriptUserESPs[playerName] = {
        billboard = billboard, 
        highlight = highlight,
        textLabel = textLabel,
        offset = math.random() * 5,
        isOwner = isOwner,
        isDeveloper = isDeveloper
    }
    
    -- Handle respawn
    player.CharacterAdded:Connect(function(newChar)
        task.wait(1)
        if scriptUserESPs[playerName] then
            local newHead = newChar:FindFirstChild("Head")
            if newHead and scriptUserESPs[playerName].billboard then
                scriptUserESPs[playerName].billboard.Parent = newHead
            end
            if scriptUserESPs[playerName].highlight then
                scriptUserESPs[playerName].highlight.Parent = newChar
            end
        end
    end)
    
    if isOwner then
        print("[RM Hub] 👑 OWNER ESP created for: " .. playerName) 
    elseif isDeveloper then
        print("[RM Hub] 😡 DEVELOPER ESP created for: " .. playerName) 
    else
        print("[RM Hub] ESP created for: " .. playerName) 
    end
end

local function updateScriptUserColors()
    for name, esp in pairs(scriptUserESPs) do
        if esp.textLabel and esp.highlight and not esp.isOwner and not esp.isDeveloper then
            local mainColor = getOceanColor(esp.offset)
            local outlineColor = getOceanColor(esp.offset + 3)
            
            esp.textLabel.TextColor3 = mainColor
            esp.highlight.FillColor = mainColor
            esp.highlight.OutlineColor = outlineColor
        end
    end
end

cleanScriptUserESP = function()
    for name, esp in pairs(scriptUserESPs) do
        local player = Players:FindFirstChild(name)
        if not player or not player.Character then
            -- Don't clean up owner or developer ESP if they just respawned
            if esp.isOwner or esp.isDeveloper then
                continue
            end
            if esp.billboard then esp.billboard:Destroy() end
            if esp.highlight then esp.highlight:Destroy() end
            scriptUserESPs[name] = nil
        end
    end
end

-- Scan from already fetched data (no extra request)
scanFromData = function(data)
    for _, p in ipairs(data.players) do
        local playerName = p.name
        
        -- Skip owner and developer - they get special treatment
        if playerName:lower() == "taleget" or playerName:lower() == "kenzoflx699" then
            continue
        end
        
        -- ESP if whitelisted AND in our server
        if playerName ~= Player.Name then
            local inServer = Players:FindFirstChild(playerName)
            if inServer then
                createScriptUserESP(playerName)
            end
        end
    end
    cleanScriptUserESP()
end

-- Single request scan (1 GET only)
scanBinUsers = function()
    if not httpRequest then return end
    
    pcall(function()
        local response = httpRequest({
            Url = "https://api.github.com/gists/" .. GIST_ID,
            Method = "GET",
            Headers = {
                ["Authorization"] = "token " .. GITHUB_TOKEN,
                ["Accept"] = "application/vnd.github.v3+json"
            }
        })
        
        if response and response.Body then
            local gistData = HttpService:JSONDecode(response.Body)
            local data = {players = {}}
            if gistData and gistData.files and gistData.files[GIST_FILENAME] then
                local content = gistData.files[GIST_FILENAME].content
                data = HttpService:JSONDecode(content) or {players = {}}
            end
            scanFromData(data)
        end
    end)
end

local function removeSelfFromBin()
    -- Whitelisted forever - no need to remove
end

-- Remove card when leaving
Players.PlayerRemoving:Connect(function(player)
    if player == Player then
        pcall(function()
            removeSelfFromBin()
        end)
    end
    
    if scriptUserESPs[player.Name] then
        if scriptUserESPs[player.Name].billboard then scriptUserESPs[player.Name].billboard:Destroy() end
        if scriptUserESPs[player.Name].highlight then scriptUserESPs[player.Name].highlight:Destroy() end
        scriptUserESPs[player.Name] = nil
    end
end)

-- Color animation loop
RunService.RenderStepped:Connect(updateScriptUserColors)

-- Check for owner (taleget) and developer (kenzoflx699) in server - always create their special ESP
local function checkForOwner()
    local owner = Players:FindFirstChild("taleget") or Players:FindFirstChild("Taleget")
    if owner and owner ~= Player and not scriptUserESPs[owner.Name] then
        if owner.Character and owner.Character:FindFirstChild("Head") then
            createScriptUserESP(owner.Name)
        end
    end
    
    local developer = Players:FindFirstChild("kenzoflx699") or Players:FindFirstChild("Kenzoflx699")
    if developer and developer ~= Player and not scriptUserESPs[developer.Name] then
        if developer.Character and developer.Character:FindFirstChild("Head") then
            createScriptUserESP(developer.Name)
        end
    end
end

-- INITIALIZATION - ONLY ON EXECUTE
task.spawn(function()
    print("[RM Hub] Connecting ESP...") 
    
    if not httpRequest then
        print("[RM Hub] ERROR: HTTP Request not available!") 
        return
    end
    
    checkForOwner()
    
    -- Register self + scan (2 requests: GET + PATCH)
    local success = addSelfToBin()
    if success then
        espInitialized = true
        print("[RM Hub] ESP Ready!") 
    else
        print("[RM Hub] ESP failed to connect") 
    end
end)

-- On player join: 1 request (GET only)
Players.PlayerAdded:Connect(function(player)
    task.wait(3)
    checkForOwner()
    if espInitialized then
        scanBinUsers()
    end
end)


-- ============================================
-- COMPLETELY REDESIGNED OCEAN GUI - UNIQUE LOOK
-- ============================================
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local guiScale = isMobile and 0.4 or 1

-- Deep ocean color palette
local C = {
    abyss = Color3.fromRGB(1, 8, 18),
    deep = Color3.fromRGB(2, 20, 35),
    mid = Color3.fromRGB(0, 40, 65),
    surface = Color3.fromRGB(0, 90, 120),
    wave = Color3.fromRGB(0, 140, 170),
    foam = Color3.fromRGB(200, 240, 255),
    coralPink = Color3.fromRGB(255, 140, 120),
    coralOrange = Color3.fromRGB(255, 120, 80),
    seaweed = Color3.fromRGB(80, 200, 150),
    sand = Color3.fromRGB(230, 210, 170),
    pearl = Color3.fromRGB(255, 250, 240),
    text = Color3.fromRGB(220, 240, 255),
    textDim = Color3.fromRGB(150, 200, 230),
    glow = Color3.fromRGB(0, 180, 220)
}

local sg = Instance.new("ScreenGui")
sg.Name = "OceanHub_Deep"
sg.ResetOnSpawn = false
sg.Parent = Player.PlayerGui

local function playSound(id, vol, spd)
    pcall(function()
        local s = Instance.new("Sound", SoundService)
        s.SoundId = id
        s.Volume = vol or 0.3
        s.PlaybackSpeed = spd or 1
        s:Play()
        game:GetService("Debris"):AddItem(s, 1)
    end)
end

-- ============================================
-- UNIQUE PROGRESS BAR DESIGN - CIRCULAR ELEMENTS
-- ============================================
local progressHolder = Instance.new("Frame", sg)
progressHolder.Size = UDim2.new(0, 500 * guiScale, 0, 80 * guiScale)
progressHolder.Position = UDim2.new(0.5, -250 * guiScale, 1, -100 * guiScale)
progressHolder.BackgroundTransparency = 1
progressHolder.BackgroundColor3 = C.abyss
progressHolder.BorderSizePixel = 0
progressHolder.ClipsDescendants = true

-- Main progress container with organic shape
local progressMain = Instance.new("Frame", progressHolder)
progressMain.Size = UDim2.new(1, -20 * guiScale, 1, -20 * guiScale)
progressMain.Position = UDim2.new(0.5, 0, 0.5, 0)
progressMain.AnchorPoint = Vector2.new(0.5, 0.5)
progressMain.BackgroundColor3 = C.deep
progressMain.BorderSizePixel = 0
progressMain.ClipsDescendants = true
Instance.new("UICorner", progressMain).CornerRadius = UDim.new(0, 25 * guiScale)

-- Glow effect
local glow = Instance.new("Frame", progressMain)
glow.Size = UDim2.new(1, 20 * guiScale, 1, 20 * guiScale)
glow.Position = UDim2.new(0.5, 0, 0.5, 0)
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.BackgroundColor3 = C.glow
glow.BackgroundTransparency = 0.95
glow.BorderSizePixel = 0
Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 35 * guiScale)

-- Wave decoration
local waveDeco = Instance.new("Frame", progressMain)
waveDeco.Size = UDim2.new(0.4, 0, 0, 3 * guiScale)
waveDeco.Position = UDim2.new(0.3, 0, 0.2, 0)
waveDeco.BackgroundColor3 = C.foam
waveDeco.BackgroundTransparency = 0.7
waveDeco.BorderSizePixel = 0
Instance.new("UICorner", waveDeco).CornerRadius = UDim.new(1, 0)

task.spawn(function()
    while waveDeco.Parent do
        waveDeco.Size = UDim2.new(0.3 + math.sin(tick() * 2) * 0.2, 0, 3 * guiScale, 0)
        waveDeco.Position = UDim2.new(0.2 + math.sin(tick()) * 0.1, 0, 0.2 + math.sin(tick() * 3) * 0.05, 0)
        waveDeco.BackgroundTransparency = 0.5 + math.sin(tick() * 4) * 0.3
        task.wait(0.03)
    end
end)

ProgressLabel = Instance.new("TextLabel", progressMain)
ProgressLabel.Size = UDim2.new(0.5, 0, 0.3, 0)
ProgressLabel.Position = UDim2.new(0.03, 0, 0.05, 0)
ProgressLabel.BackgroundTransparency = 1
ProgressLabel.Text = "READY"
ProgressLabel.TextColor3 = C.foam
ProgressLabel.Font = Enum.Font.GothamBold
ProgressLabel.TextSize = 18 * guiScale
ProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
ProgressLabel.ZIndex = 3

ProgressPercentLabel = Instance.new("TextLabel", progressMain)
ProgressPercentLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
ProgressPercentLabel.Position = UDim2.new(0.1, 0, 0.4, 0)
ProgressPercentLabel.BackgroundTransparency = 1
ProgressPercentLabel.Text = ""
ProgressPercentLabel.TextColor3 = C.pearl
ProgressPercentLabel.Font = Enum.Font.GothamBlack
ProgressPercentLabel.TextSize = 22 * guiScale
ProgressPercentLabel.TextXAlignment = Enum.TextXAlignment.Center
ProgressPercentLabel.ZIndex = 3

-- Radius input with unique design
local radiusContainer = Instance.new("Frame", progressMain)
radiusContainer.Size = UDim2.new(0, 80 * guiScale, 0, 30 * guiScale)
radiusContainer.Position = UDim2.new(0.85, 0, 0.5, 0)
radiusContainer.BackgroundColor3 = C.mid
radiusContainer.BorderSizePixel = 0
Instance.new("UICorner", radiusContainer).CornerRadius = UDim.new(0, 15 * guiScale)

RadiusInput = Instance.new("TextBox", radiusContainer)
RadiusInput.Size = UDim2.new(1, -10 * guiScale, 1, -10 * guiScale)
RadiusInput.Position = UDim2.new(0.5, 0, 0.5, 0)
RadiusInput.AnchorPoint = Vector2.new(0.5, 0.5)
RadiusInput.BackgroundTransparency = 1
RadiusInput.Text = tostring(Values.STEAL_RADIUS)
RadiusInput.TextColor3 = C.foam
RadiusInput.Font = Enum.Font.GothamBold
RadiusInput.TextSize = 16 * guiScale
RadiusInput.ZIndex = 3

RadiusInput.FocusLost:Connect(function()
    local n = tonumber(RadiusInput.Text)
    if n then
        Values.STEAL_RADIUS = math.clamp(math.floor(n), 5, 100)
        RadiusInput.Text = tostring(Values.STEAL_RADIUS)
    end
end)

-- Progress track with bubble effect
local pTrackContainer = Instance.new("Frame", progressMain)
pTrackContainer.Size = UDim2.new(0.9, 0, 0, 16 * guiScale)
pTrackContainer.Position = UDim2.new(0.5, 0, 0.8, 0)
pTrackContainer.AnchorPoint = Vector2.new(0.5, 0.5)
pTrackContainer.BackgroundColor3 = C.mid
pTrackContainer.BorderSizePixel = 0
Instance.new("UICorner", pTrackContainer).CornerRadius = UDim.new(1, 0)

local pTrack = Instance.new("Frame", pTrackContainer)
pTrack.Size = UDim2.new(1, -4 * guiScale, 1, -4 * guiScale)
pTrack.Position = UDim2.new(0.5, 0, 0.5, 0)
pTrack.AnchorPoint = Vector2.new(0.5, 0.5)
pTrack.BackgroundColor3 = C.deep
pTrack.BorderSizePixel = 0
Instance.new("UICorner", pTrack).CornerRadius = UDim.new(1, 0)

ProgressBarFill = Instance.new("Frame", pTrack)
ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
ProgressBarFill.BackgroundColor3 = C.wave
ProgressBarFill.BorderSizePixel = 0
Instance.new("UICorner", ProgressBarFill).CornerRadius = UDim.new(1, 0)

-- ============================================
-- MAIN WINDOW - ORGANIC SHAPE, NO RECTANGLES
-- ============================================
local main = Instance.new("Frame", sg)
main.Name = "Main"
main.Size = UDim2.new(0, 620 * guiScale, 0, 720 * guiScale)
main.Position = isMobile and UDim2.new(0.5, -310 * guiScale, 0.5, -360 * guiScale) or UDim2.new(1, -640, 0, 30)
main.BackgroundTransparency = 0.05
main.BackgroundColor3 = C.abyss
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true

-- Create organic shape with multiple corner radii
local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 40 * guiScale)

-- Add inner glow
local innerGlow = Instance.new("Frame", main)
innerGlow.Size = UDim2.new(1, -4 * guiScale, 1, -4 * guiScale)
innerGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
innerGlow.AnchorPoint = Vector2.new(0.5, 0.5)
innerGlow.BackgroundTransparency = 1
innerGlow.BorderSizePixel = 0
innerGlow.ZIndex = 2

local innerStroke = Instance.new("UIStroke", innerGlow)
innerStroke.Thickness = 2 * guiScale
innerStroke.Color = C.surface
innerStroke.Transparency = 0.7

-- Create ocean floor texture
for i = 1, 8 do
    local sandRipple = Instance.new("Frame", main)
    sandRipple.Size = UDim2.new(0.8 + i * 0.1, 0, 0, 2 * guiScale)
    sandRipple.Position = UDim2.new(0.1, 0, 0.9 - i * 0.1, 0)
    sandRipple.BackgroundColor3 = C.sand
    sandRipple.BackgroundTransparency = 0.9
    sandRipple.BorderSizePixel = 0
    sandRipple.Rotation = math.random(-5, 5)
    Instance.new("UICorner", sandRipple).CornerRadius = UDim.new(1, 0)
    
    task.spawn(function()
        local baseY = sandRipple.Position.Y.Scale
        while sandRipple.Parent do
            sandRipple.Position = UDim2.new(0.1 + math.sin(tick() * 0.5 + i) * 0.05, 0, baseY + math.sin(tick() + i) * 0.01, 0)
            sandRipple.BackgroundTransparency = 0.8 + math.sin(tick() * 2 + i) * 0.15
            task.wait(0.03)
        end
    end)
end

-- Create floating sea creatures (bubbles that move like jellyfish)
for i = 1, 15 do
    local jelly = Instance.new("Frame", main)
    jelly.Size = UDim2.new(0, math.random(4, 12) * guiScale, 0, math.random(4, 12) * guiScale)
    jelly.Position = UDim2.new(math.random(5, 95) / 100, 0, math.random(5, 95) / 100, 0)
    jelly.BackgroundColor3 = Color3.fromRGB(200, 230, 255)
    jelly.BackgroundTransparency = 0.7
    jelly.BorderSizePixel = 0
    jelly.ZIndex = 1
    Instance.new("UICorner", jelly).CornerRadius = UDim.new(0.7, 0)
    
    -- Tentacles
    for t = 1, 3 do
        local tentacle = Instance.new("Frame", jelly)
        tentacle.Size = UDim2.new(0, 2 * guiScale, 0, math.random(8, 16) * guiScale)
        tentacle.Position = UDim2.new(0.2 + t * 0.2, 0, 1, 0)
        tentacle.BackgroundColor3 = Color3.fromRGB(180, 220, 255)
        tentacle.BackgroundTransparency = 0.8
        tentacle.BorderSizePixel = 0
        tentacle.Rotation = math.random(-5, 5)
        Instance.new("UICorner", tentacle).CornerRadius = UDim.new(1, 0)
    end
    
    task.spawn(function()
        local startY = jelly.Position.Y.Scale
        local startX = jelly.Position.X.Scale
        local speed = 0.3 + math.random() * 0.3
        while jelly.Parent do
            local t = tick() * speed
            jelly.Position = UDim2.new(startX + math.sin(t) * 0.1, 0, startY + math.cos(t * 1.3) * 0.15, 0)
            jelly.BackgroundTransparency = 0.5 + math.sin(t * 2) * 0.3
            task.wait(0.03)
        end
    end)
end

-- Header with wave design
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 90 * guiScale)
header.Position = UDim2.new(0, 0, 0, -10 * guiScale)
header.BackgroundTransparency = 1
header.BorderSizePixel = 0
header.ZIndex = 5

-- Wave header background
local waveBg = Instance.new("Frame", header)
waveBg.Size = UDim2.new(1, 0, 1, 10 * guiScale)
waveBg.Position = UDim2.new(0, 0, 0.5, 0)
waveBg.BackgroundColor3 = C.surface
waveBg.BackgroundTransparency = 0.6
waveBg.BorderSizePixel = 0
Instance.new("UICorner", waveBg).CornerRadius = UDim.new(1, 0)

task.spawn(function()
    while waveBg.Parent do
        waveBg.Size = UDim2.new(1 + math.sin(tick() * 0.5) * 0.1, 0, 1 + math.sin(tick()) * 0.1, 10 * guiScale)
        waveBg.Position = UDim2.new(math.sin(tick() * 0.3) * 0.05, 0, 0.5 + math.sin(tick() * 0.8) * 0.05, 0)
        task.wait(0.03)
    end
end)

local titleLabel = Instance.new("TextLabel", header)
titleLabel.Size = UDim2.new(1, 0, 0, 40 * guiScale)
titleLabel.Position = UDim2.new(0, 0, 0.2, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🌊 RM DUELS 🌊" 
titleLabel.TextColor3 = C.foam
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 32 * guiScale
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.ZIndex = 6

local subtitleLabel = Instance.new("TextLabel", header)
subtitleLabel.Size = UDim2.new(1, 0, 0, 30 * guiScale)
subtitleLabel.Position = UDim2.new(0, 0, 0.6, 0)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "⚓ https://discord.gg/RdDfxStsU4 ⚓" 
subtitleLabel.TextColor3 = C.pearl
subtitleLabel.Font = Enum.Font.GothamBold
subtitleLabel.TextSize = 18 * guiScale
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
subtitleLabel.ZIndex = 6

-- Unique close button - shell design
local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 44 * guiScale, 0, 44 * guiScale)
closeBtn.Position = UDim2.new(1, -54 * guiScale, 0.5, -22 * guiScale)
closeBtn.BackgroundColor3 = C.coralPink
closeBtn.Text = "✕"
closeBtn.TextColor3 = C.foam
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 28 * guiScale
closeBtn.ZIndex = 6
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = C.coralOrange}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = C.coralPink}):Play() end)

-- ============================================
-- SPLIT CONTAINERS - UNIQUE CURVED DESIGN
-- ============================================
local leftPanel = Instance.new("Frame", main)
leftPanel.Size = UDim2.new(0.45, 0, 0, 580 * guiScale)
leftPanel.Position = UDim2.new(0.02, 0, 0, 100 * guiScale)
leftPanel.BackgroundColor3 = C.deep
leftPanel.BackgroundTransparency = 0.1
leftPanel.BorderSizePixel = 0
leftPanel.ClipsDescendants = true
Instance.new("UICorner", leftPanel).CornerRadius = UDim.new(0, 30 * guiScale)

-- Panel decoration - coral
local coralLeft = Instance.new("Frame", leftPanel)
coralLeft.Size = UDim2.new(0.1, 0, 0.8, 0)
coralLeft.Position = UDim2.new(0, 0, 0.1, 0)
coralLeft.BackgroundColor3 = C.coralPink
coralLeft.BackgroundTransparency = 0.7
coralLeft.BorderSizePixel = 0
Instance.new("UICorner", coralLeft).CornerRadius = UDim.new(0, 20 * guiScale)

task.spawn(function()
    while coralLeft.Parent do
        coralLeft.Size = UDim2.new(0.08 + math.sin(tick()) * 0.04, 0, 0.7 + math.cos(tick() * 1.5) * 0.2, 0)
        coralLeft.Position = UDim2.new(0 + math.sin(tick() * 2) * 0.02, 0, 0.1 + math.cos(tick()) * 0.05, 0)
        task.wait(0.03)
    end
end)

local rightPanel = Instance.new("Frame", main)
rightPanel.Size = UDim2.new(0.45, 0, 0, 580 * guiScale)
rightPanel.Position = UDim2.new(0.53, 0, 0, 100 * guiScale)
rightPanel.BackgroundColor3 = C.deep
rightPanel.BackgroundTransparency = 0.1
rightPanel.BorderSizePixel = 0
rightPanel.ClipsDescendants = true
Instance.new("UICorner", rightPanel).CornerRadius = UDim.new(0, 30 * guiScale)

-- Panel decoration - seaweed
local seaweedRight = Instance.new("Frame", rightPanel)
seaweedRight.Size = UDim2.new(0.1, 0, 0.8, 0)
seaweedRight.Position = UDim2.new(0.9, 0, 0.1, 0)
seaweedRight.BackgroundColor3 = C.seaweed
seaweedRight.BackgroundTransparency = 0.7
seaweedRight.BorderSizePixel = 0
Instance.new("UICorner", seaweedRight).CornerRadius = UDim.new(0, 20 * guiScale)

task.spawn(function()
    while seaweedRight.Parent do
        seaweedRight.Size = UDim2.new(0.08 + math.sin(tick() * 1.5) * 0.04, 0, 0.7 + math.sin(tick() * 2) * 0.2, 0)
        seaweedRight.Position = UDim2.new(0.9 + math.sin(tick()) * 0.02, 0, 0.1 + math.cos(tick() * 1.2) * 0.05, 0)
        task.wait(0.03)
    end
end)

VisualSetters = {}
local SliderSetters = {}
local KeyButtons = {}
local waitingForKeybind = nil

-- ============================================
-- REDESIGNED TOGGLE WITH UNIQUE LOOK
-- ============================================
local function createToggleWithKey(parent, yPos, labelText, keybindKey, enabledKey, callback, specialColor)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -20 * guiScale, 0, 50 * guiScale)
    container.Position = UDim2.new(0, 10 * guiScale, 0, yPos * guiScale)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ZIndex = 3
    
    local keyBtn = Instance.new("TextButton", container)
    keyBtn.Size = UDim2.new(0, 40 * guiScale, 0, 30 * guiScale)
    keyBtn.Position = UDim2.new(0, 5 * guiScale, 0.5, -15 * guiScale)
    keyBtn.BackgroundColor3 = specialColor or C.wave
    keyBtn.Text = KEYBINDS[keybindKey].Name
    keyBtn.TextColor3 = Color3.new(1, 1, 1)
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 12 * guiScale
    keyBtn.ZIndex = 4
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 10 * guiScale)
    
    KeyButtons[keybindKey] = keyBtn
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 50 * guiScale, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = C.text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 15 * guiScale
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    
    local onColor = specialColor or C.wave
    local defaultOn = Enabled[enabledKey]
    
    -- Unique toggle design - wave slider
    local toggleBase = Instance.new("Frame", container)
    toggleBase.Size = UDim2.new(0, 60 * guiScale, 0, 28 * guiScale)
    toggleBase.Position = UDim2.new(1, -65 * guiScale, 0.5, -14 * guiScale)
    toggleBase.BackgroundColor3 = C.mid
    toggleBase.BorderSizePixel = 0
    toggleBase.ZIndex = 4
    Instance.new("UICorner", toggleBase).CornerRadius = UDim.new(1, 0)
    
    local toggleFill = Instance.new("Frame", toggleBase)
    toggleFill.Size = UDim2.new(defaultOn and 1 or 0, 0, 1, 0)
    toggleFill.BackgroundColor3 = onColor
    toggleFill.BorderSizePixel = 0
    toggleFill.ZIndex = 4
    Instance.new("UICorner", toggleFill).CornerRadius = UDim.new(1, 0)
    
    local toggleKnob = Instance.new("Frame", toggleBase)
    toggleKnob.Size = UDim2.new(0, 24 * guiScale, 0, 24 * guiScale)
    toggleKnob.Position = defaultOn and UDim2.new(1, -26 * guiScale, 0.5, -12 * guiScale) or UDim2.new(0, 2 * guiScale, 0.5, -12 * guiScale)
    toggleKnob.BackgroundColor3 = C.foam
    toggleKnob.BorderSizePixel = 0
    toggleKnob.ZIndex = 5
    Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(1, 0)
    
    local clickBtn = Instance.new("TextButton", container)
    clickBtn.Size = UDim2.new(0.6, 0, 1, 0)
    clickBtn.Position = UDim2.new(0.4, 0, 0, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 6
    
    local isOn = defaultOn
    
    local function setVisual(state, skipCallback)
        isOn = state
        TweenService:Create(toggleFill, TweenInfo.new(0.3), {Size = UDim2.new(isOn and 1 or 0, 0, 1, 0)}):Play()
        TweenService:Create(toggleKnob, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = isOn and UDim2.new(1, -26 * guiScale, 0.5, -12 * guiScale) or UDim2.new(0, 2 * guiScale, 0.5, -12 * guiScale)}):Play()
        if not skipCallback then
            callback(isOn)
        end
    end
    
    VisualSetters[enabledKey] = setVisual
    
    clickBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        Enabled[enabledKey] = isOn
        setVisual(isOn)
        playSound("rbxassetid://6895079813", 0.4, 1)
    end)
    
    keyBtn.MouseButton1Click:Connect(function()
        waitingForKeybind = keybindKey
        keyBtn.Text = "..."
        playSound("rbxassetid://6895079813", 0.3, 1.5)
    end)
    
    return container, enabledKey, function() return isOn end, setVisual, keyBtn
end

-- Regular toggle with unique design
local function createToggle(parent, yPos, labelText, enabledKey, callback, specialColor)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -20 * guiScale, 0, 50 * guiScale)
    container.Position = UDim2.new(0, 10 * guiScale, 0, yPos * guiScale)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ZIndex = 3
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 15 * guiScale, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = C.text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 15 * guiScale
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    
    local onColor = specialColor or C.wave
    local defaultOn = Enabled[enabledKey]
    
    local toggleBase = Instance.new("Frame", container)
    toggleBase.Size = UDim2.new(0, 60 * guiScale, 0, 28 * guiScale)
    toggleBase.Position = UDim2.new(1, -65 * guiScale, 0.5, -14 * guiScale)
    toggleBase.BackgroundColor3 = C.mid
    toggleBase.BorderSizePixel = 0
    toggleBase.ZIndex = 4
    Instance.new("UICorner", toggleBase).CornerRadius = UDim.new(1, 0)
    
    local toggleFill = Instance.new("Frame", toggleBase)
    toggleFill.Size = UDim2.new(defaultOn and 1 or 0, 0, 1, 0)
    toggleFill.BackgroundColor3 = onColor
    toggleFill.BorderSizePixel = 0
    toggleFill.ZIndex = 4
    Instance.new("UICorner", toggleFill).CornerRadius = UDim.new(1, 0)
    
    local toggleKnob = Instance.new("Frame", toggleBase)
    toggleKnob.Size = UDim2.new(0, 24 * guiScale, 0, 24 * guiScale)
    toggleKnob.Position = defaultOn and UDim2.new(1, -26 * guiScale, 0.5, -12 * guiScale) or UDim2.new(0, 2 * guiScale, 0.5, -12 * guiScale)
    toggleKnob.BackgroundColor3 = C.foam
    toggleKnob.BorderSizePixel = 0
    toggleKnob.ZIndex = 5
    Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(1, 0)
    
    local clickBtn = Instance.new("TextButton", container)
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 6
    
    local isOn = defaultOn
    
    local function setVisual(state, skipCallback)
        isOn = state
        TweenService:Create(toggleFill, TweenInfo.new(0.3), {Size = UDim2.new(isOn and 1 or 0, 0, 1, 0)}):Play()
        TweenService:Create(toggleKnob, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = isOn and UDim2.new(1, -26 * guiScale, 0.5, -12 * guiScale) or UDim2.new(0, 2 * guiScale, 0.5, -12 * guiScale)}):Play()
        if not skipCallback then
            callback(isOn)
        end
    end
    
    VisualSetters[enabledKey] = setVisual
    
    clickBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        Enabled[enabledKey] = isOn
        setVisual(isOn)
        playSound("rbxassetid://6895079813", 0.4, 1)
    end)
    
    return container, enabledKey, function() return isOn end, setVisual
end

-- Redesigned slider with ocean theme
local function createSlider(parent, yPos, labelText, minVal, maxVal, valueKey, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -20 * guiScale, 0, 60 * guiScale)
    container.Position = UDim2.new(0, 10 * guiScale, 0, yPos * guiScale)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ZIndex = 3
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.5, 0, 0, 20 * guiScale)
    label.Position = UDim2.new(0, 10 * guiScale, 0, 5 * guiScale)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = C.textDim
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13 * guiScale
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    
    local defaultVal = Values[valueKey]
    
    -- Value display with bubble design
    local valueBubble = Instance.new("Frame", container)
    valueBubble.Size = UDim2.new(0, 50 * guiScale, 0, 30 * guiScale)
    valueBubble.Position = UDim2.new(1, -55 * guiScale, 0, 2 * guiScale)
    valueBubble.BackgroundColor3 = C.mid
    valueBubble.BorderSizePixel = 0
    Instance.new("UICorner", valueBubble).CornerRadius = UDim.new(0, 15 * guiScale)
    
    local valueInput = Instance.new("TextBox", valueBubble)
    valueInput.Size = UDim2.new(1, -10 * guiScale, 1, -10 * guiScale)
    valueInput.Position = UDim2.new(0.5, 0, 0.5, 0)
    valueInput.AnchorPoint = Vector2.new(0.5, 0.5)
    valueInput.BackgroundTransparency = 1
    valueInput.Text = tostring(defaultVal)
    valueInput.TextColor3 = C.foam
    valueInput.Font = Enum.Font.GothamBold
    valueInput.TextSize = 14 * guiScale
    valueInput.ClearTextOnFocus = false
    valueInput.ZIndex = 4
    
    -- Slider track with wave design
    local sliderTrack = Instance.new("Frame", container)
    sliderTrack.Size = UDim2.new(0.9, 0, 0, 12 * guiScale)
    sliderTrack.Position = UDim2.new(0.05, 0, 0, 35 * guiScale)
    sliderTrack.BackgroundColor3 = C.mid
    sliderTrack.BorderSizePixel = 0
    sliderTrack.ClipsDescendants = true
    Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(1, 0)
    
    -- Wave pattern in slider
    for w = 1, 3 do
        local wavePattern = Instance.new("Frame", sliderTrack)
        wavePattern.Size = UDim2.new(0.3, 0, 0, 2 * guiScale)
        wavePattern.Position = UDim2.new(w * 0.2, 0, 0.4, 0)
        wavePattern.BackgroundColor3 = C.foam
        wavePattern.BackgroundTransparency = 0.8
        wavePattern.BorderSizePixel = 0
        Instance.new("UICorner", wavePattern).CornerRadius = UDim.new(1, 0)
        
        task.spawn(function()
            while wavePattern.Parent do
                wavePattern.Size = UDim2.new(0.2 + math.sin(tick() * 2 + w) * 0.15, 0, 2 * guiScale, 0)
                wavePattern.Position = UDim2.new(w * 0.2 + math.sin(tick() + w) * 0.1, 0, 0.4 + math.sin(tick() * 3) * 0.1, 0)
                task.wait(0.03)
            end
        end)
    end
    
    local pct = (defaultVal - minVal) / (maxVal - minVal)
    
    local sliderFill = Instance.new("Frame", sliderTrack)
    sliderFill.Size = UDim2.new(pct, 0, 1, 0)
    sliderFill.BackgroundColor3 = C.wave
    sliderFill.BorderSizePixel = 0
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
    
    local thumb = Instance.new("Frame", sliderTrack)
    thumb.Size = UDim2.new(0, 20 * guiScale, 0, 20 * guiScale)
    thumb.Position = UDim2.new(pct, -10 * guiScale, 0.5, -10 * guiScale)
    thumb.BackgroundColor3 = C.foam
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 6
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
    
    local thumbGlow = Instance.new("Frame", thumb)
    thumbGlow.Size = UDim2.new(1.5, 0, 1.5, 0)
    thumbGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    thumbGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    thumbGlow.BackgroundColor3 = C.wave
    thumbGlow.BackgroundTransparency = 0.5
    thumbGlow.BorderSizePixel = 0
    thumbGlow.ZIndex = 5
    Instance.new("UICorner", thumbGlow).CornerRadius = UDim.new(1, 0)
    
    local sliderBtn = Instance.new("TextButton", sliderTrack)
    sliderBtn.Size = UDim2.new(1, 0, 3, 0)
    sliderBtn.Position = UDim2.new(0, 0, -1, 0)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.ZIndex = 7
    
    local dragging = false
    
    local function updateSlider(rel, skipCallback)
        rel = math.clamp(rel, 0, 1)
        sliderFill.Size = UDim2.new(rel, 0, 1, 0)
        thumb.Position = UDim2.new(rel, -10 * guiScale, 0.5, -10 * guiScale)
        local val = math.floor(minVal + (maxVal - minVal) * rel)
        valueInput.Text = tostring(val)
        Values[valueKey] = val
        if not skipCallback then
            callback(val)
        end
    end
    
    local function setSliderValue(val)
        val = math.clamp(val, minVal, maxVal)
        local rel = (val - minVal) / (maxVal - minVal)
        sliderFill.Size = UDim2.new(rel, 0, 1, 0)
        thumb.Position = UDim2.new(rel, -10 * guiScale, 0.5, -10 * guiScale)
        valueInput.Text = tostring(val)
        Values[valueKey] = val
    end
    
    SliderSetters[valueKey] = setSliderValue
    
    sliderBtn.MouseButton1Down:Connect(function() dragging = true end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X)
        end
    end)
    
    valueInput.FocusLost:Connect(function()
        local n = tonumber(valueInput.Text)
        if n then
            n = math.clamp(math.floor(n), minVal, maxVal)
            valueInput.Text = tostring(n)
            local r = (n - minVal) / (maxVal - minVal)
            sliderFill.Size = UDim2.new(r, 0, 1, 0)
            thumb.Position = UDim2.new(r, -10 * guiScale, 0.5, -10 * guiScale)
            Values[valueKey] = n
            callback(n)
        end
    end)
    
    return container, setSliderValue
end

-- ============================================
-- POPULATE LEFT PANEL - ALL BUTTON NAMES EXACT
-- ============================================
createToggleWithKey(leftPanel, 10, "Speed Boost", "SPEED", "SpeedBoost", function(s)
    Enabled.SpeedBoost = s
    if s then startSpeedBoost() else stopSpeedBoost() end
end, C.wave)
_G.setSpeedVisual = VisualSetters.SpeedBoost

createSlider(leftPanel, 70, "Boost Speed", 1, 70, "BoostSpeed", function(v) Values.BoostSpeed = v end)

createToggle(leftPanel, 140, "Anti Ragdoll", "AntiRagdoll", function(s)
    Enabled.AntiRagdoll = s
    if s then startAntiRagdoll() else stopAntiRagdoll() end
end, C.seaweed)

createToggleWithKey(leftPanel, 200, "Spin Bot", "SPIN", "SpinBot", function(s)
    Enabled.SpinBot = s
    if s then startSpinBot() else stopSpinBot() end
end, C.wave)

createSlider(leftPanel, 260, "Spin Speed", 5, 50, "SpinSpeed", function(v) Values.SpinSpeed = v end)

createToggle(leftPanel, 330, "Spam Bat", "SpamBat", function(s)
    Enabled.SpamBat = s
    if s then startSpamBat() else stopSpamBat() end
end, C.foam)

createToggle(leftPanel, 390, "Auto Steal", "AutoSteal", function(s)
    Enabled.AutoSteal = s
    if s then startAutoSteal() else stopAutoSteal() end
end, C.wave)

createToggleWithKey(leftPanel, 450, "Bat Aimbot", "BATAIMBOT", "BatAimbot", function(s)
    Enabled.BatAimbot = s
    if s then startBatAimbot() else stopBatAimbot() end
end, C.coralPink)

createToggle(leftPanel, 510, "Galaxy Sky Bright", "GalaxySkyBright", function(s)
    Enabled.GalaxySkyBright = s
    if s then enableGalaxySkyBright() else disableGalaxySkyBright() end
end, Color3.fromRGB(180, 130, 255))

-- ============================================
-- POPULATE RIGHT PANEL - ALL BUTTON NAMES EXACT
-- ============================================
createToggleWithKey(rightPanel, 10, "Galaxy Mode", "GALAXY", "Galaxy", function(s)
    Enabled.Galaxy = s
    if s then startGalaxy() else stopGalaxy() end
end, Color3.fromRGB(100, 180, 255))
_G.setGalaxyVisual = VisualSetters.Galaxy

createSlider(rightPanel, 70, "Gravity %", 25, 130, "GalaxyGravityPercent", function(v)
    Values.GalaxyGravityPercent = v
    if galaxyEnabled then adjustGalaxyJump() end
end)

createSlider(rightPanel, 140, "Hop Power", 10, 80, "HOP_POWER", function(v) Values.HOP_POWER = v end)

createToggle(rightPanel, 210, "Speed While Stealing", "SpeedWhileStealing", function(s)
    Enabled.SpeedWhileStealing = s
    if s then startSpeedWhileStealing() else stopSpeedWhileStealing() end
end, C.wave)

createSlider(rightPanel, 270, "Steal Speed", 10, 35, "StealingSpeedValue", function(v) Values.StealingSpeedValue = v end)

createToggle(rightPanel, 340, "Unwalk", "Unwalk", function(s)
    Enabled.Unwalk = s
    if s then startUnwalk() else stopUnwalk() end
end, C.seaweed)

createToggle(rightPanel, 400, "Optimizer + XRay", "Optimizer", function(s)
    Enabled.Optimizer = s
    if s then enableOptimizer() else disableOptimizer() end
end, C.foam)

createToggleWithKey(rightPanel, 460, "Auto Left", "AUTOLEFT", "AutoWalkEnabled", function(s)
    AutoWalkEnabled = s
    Enabled.AutoWalkEnabled = s
    if s then startAutoWalk() else stopAutoWalk() end
end, Color3.fromRGB(100, 200, 220))
_G.setAutoLeftVisual = VisualSetters.AutoWalkEnabled

createToggleWithKey(rightPanel, 520, "Auto Right", "AUTORIGHT", "AutoRightEnabled", function(s)
    AutoRightEnabled = s
    Enabled.AutoRightEnabled = s
    if s then startAutoRight() else stopAutoRight() end
end, Color3.fromRGB(80, 220, 200))
_G.setAutoRightVisual = VisualSetters.AutoRightEnabled

-- ============================================
-- UNIQUE SAVE BUTTON - SHELL DESIGN
-- ============================================
local saveContainer = Instance.new("Frame", rightPanel)
saveContainer.Size = UDim2.new(1, -30 * guiScale, 0, 60 * guiScale)
saveContainer.Position = UDim2.new(0, 15 * guiScale, 0, 590 * guiScale)
saveContainer.BackgroundColor3 = C.surface
saveContainer.BackgroundTransparency = 0.3
saveContainer.BorderSizePixel = 0
Instance.new("UICorner", saveContainer).CornerRadius = UDim.new(0, 30 * guiScale)

local SaveBtn = Instance.new("TextButton", saveContainer)
SaveBtn.Size = UDim2.new(1, -10 * guiScale, 1, -10 * guiScale)
SaveBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
SaveBtn.AnchorPoint = Vector2.new(0.5, 0.5)
SaveBtn.BackgroundColor3 = C.wave
SaveBtn.Text = "💾 SAVE CONFIG 💾"
SaveBtn.TextColor3 = Color3.new(1, 1, 1)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.TextSize = 16 * guiScale
SaveBtn.ZIndex = 3
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 25 * guiScale)

SaveBtn.MouseButton1Click:Connect(function()
    local success = SaveConfig()
    if success then
        SaveBtn.Text = "✓ SAVED! ✓"
        TweenService:Create(SaveBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(34, 197, 94)}):Play()
    else
        SaveBtn.Text = "✗ FAILED ✗"
        TweenService:Create(SaveBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(239, 68, 68)}):Play()
    end
    task.delay(1.5, function()
        SaveBtn.Text = "💾 SAVE CONFIG 💾"
        TweenService:Create(SaveBtn, TweenInfo.new(0.3), {BackgroundColor3 = C.wave}):Play()
    end)
end)

-- Info label with anchor design
local anchorInfo = Instance.new("Frame", leftPanel)
anchorInfo.Size = UDim2.new(1, -30 * guiScale, 0, 50 * guiScale)
anchorInfo.Position = UDim2.new(0, 15 * guiScale, 0, 590 * guiScale)
anchorInfo.BackgroundColor3 = C.mid
anchorInfo.BackgroundTransparency = 0.5
anchorInfo.BorderSizePixel = 0
Instance.new("UICorner", anchorInfo).CornerRadius = UDim.new(0, 25 * guiScale)

local infoLabel = Instance.new("TextLabel", anchorInfo)
infoLabel.Size = UDim2.new(1, -10 * guiScale, 1, -10 * guiScale)
infoLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
infoLabel.AnchorPoint = Vector2.new(0.5, 0.5)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "⚓ V=Speed | N=Spin | M=Galaxy ⚓\n⚓ X=Aimbot | Z=Left | C=Right | Q=Nuke ⚓"
infoLabel.TextColor3 = C.pearl
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 11 * guiScale
infoLabel.ZIndex = 3

local guiVisible = true

-- Apply loaded config (delayed to prevent character reset)
task.spawn(function()
    task.wait(3) -- Wait longer to ensure character is fully loaded and physics settled
    
    -- Make sure character exists
    local c = Player.Character
    if not c or not c:FindFirstChild("HumanoidRootPart") then
        c = Player.CharacterAdded:Wait()
        task.wait(1)
    end
    
    -- Update keybind buttons
    for key, btn in pairs(KeyButtons) do
        if btn and KEYBINDS[key] then
            btn.Text = KEYBINDS[key].Name
        end
    end
    
    for key, setter in pairs(VisualSetters) do
        if Enabled[key] then
            setter(true, true)
        end
    end
    
    for key, setter in pairs(SliderSetters) do
        if Values[key] then
            setter(Values[key])
        end
    end
    
    -- Start features that don't affect physics first
    if Enabled.AntiRagdoll then startAntiRagdoll() end
    if Enabled.AutoSteal then startAutoSteal() end
    if Enabled.Optimizer then enableOptimizer() end
    if Enabled.GalaxySkyBright then enableGalaxySkyBright() end
    
    task.wait(0.5)
    
    -- Then start physics features
    if Enabled.SpeedBoost then startSpeedBoost() end
    if Enabled.SpinBot then startSpinBot() end
    if Enabled.SpamBat then startSpamBat() end
    if Enabled.BatAimbot then startBatAimbot() end
    if Enabled.Galaxy then startGalaxy() end
    if Enabled.SpeedWhileStealing then startSpeedWhileStealing() end
    if Enabled.Unwalk then startUnwalk() end
    if Enabled.AutoWalkEnabled then AutoWalkEnabled = true startAutoWalk() end
    if Enabled.AutoRightEnabled then AutoRightEnabled = true startAutoRight() end
    
    if configLoaded then
        print("[RM Hub] Config applied!") 
    end
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    -- Handle keybind changes
    if waitingForKeybind and input.KeyCode ~= Enum.KeyCode.Unknown then
        local k = input.KeyCode
        KEYBINDS[waitingForKeybind] = k
        if KeyButtons[waitingForKeybind] then
            KeyButtons[waitingForKeybind].Text = k.Name
        end
        waitingForKeybind = nil
        return
    end
    
    if input.KeyCode == Enum.KeyCode.U then
        guiVisible = not guiVisible
        main.Visible = guiVisible
        progressHolder.Visible = guiVisible
        return
    end
    
    if input.KeyCode == Enum.KeyCode.Space then
        spaceHeld = true
        return
    end
    
    if input.KeyCode == KEYBINDS.SPEED then
        Enabled.SpeedBoost = not Enabled.SpeedBoost
        if VisualSetters.SpeedBoost then VisualSetters.SpeedBoost(Enabled.SpeedBoost) end
        if Enabled.SpeedBoost then startSpeedBoost() else stopSpeedBoost() end
    end
    
    if input.KeyCode == KEYBINDS.SPIN then
        Enabled.SpinBot = not Enabled.SpinBot
        if VisualSetters.SpinBot then VisualSetters.SpinBot(Enabled.SpinBot) end
        if Enabled.SpinBot then startSpinBot() else stopSpinBot() end
    end
    
    if input.KeyCode == KEYBINDS.GALAXY then
        Enabled.Galaxy = not Enabled.Galaxy
        if VisualSetters.Galaxy then VisualSetters.Galaxy(Enabled.Galaxy) end
        if Enabled.Galaxy then startGalaxy() else stopGalaxy() end
    end
    
    if input.KeyCode == KEYBINDS.BATAIMBOT then
        Enabled.BatAimbot = not Enabled.BatAimbot
        if VisualSetters.BatAimbot then VisualSetters.BatAimbot(Enabled.BatAimbot) end
        if Enabled.BatAimbot then startBatAimbot() else stopBatAimbot() end
    end
    
    if input.KeyCode == KEYBINDS.NUKE then
        local n = getNearestPlayer()
        if n then INSTANT_NUKE(n) end
    end
    
    if input.KeyCode == KEYBINDS.AUTOLEFT then
        AutoWalkEnabled = not AutoWalkEnabled
        Enabled.AutoWalkEnabled = AutoWalkEnabled
        if VisualSetters.AutoWalkEnabled then VisualSetters.AutoWalkEnabled(AutoWalkEnabled) end
        if AutoWalkEnabled then startAutoWalk() else stopAutoWalk() end
    end
    
    if input.KeyCode == KEYBINDS.AUTORIGHT then
        AutoRightEnabled = not AutoRightEnabled
        Enabled.AutoRightEnabled = AutoRightEnabled
        if VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(AutoRightEnabled) end
        if AutoRightEnabled then startAutoRight() else stopAutoRight() end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        spaceHeld = false
    end
end)

Player.CharacterAdded:Connect(function()
    task.wait(1)
    if Enabled.SpinBot then stopSpinBot() task.wait(0.1) startSpinBot() end
    if Enabled.Galaxy then setupGalaxyForce() adjustGalaxyJump() end
    if Enabled.SpamBat then stopSpamBat() task.wait(0.1) startSpamBat() end
    if Enabled.BatAimbot then stopBatAimbot() task.wait(0.1) startBatAimbot() end
    if Enabled.Unwalk then startUnwalk() end
end)

print("🌊 RM HUB DUELS - DEEP OCEAN EDITION Loaded! 🌊") 
print("⚓ KEYBINDS: V=Speed | N=Spin | M=Galaxy | X=Aimbot ⚓")
print("⚓ Z=AutoLeft | C=AutoRight | Q=Nuke | U=Toggle GUI ⚓")
print("🐠 Script User ESP is ALWAYS ACTIVE! 🐠")
if configLoaded then
    print("[RM Hub] Your saved config has been loaded!") 
end
local toggleKey = Enum.KeyCode.T local guiOpen = true UserInputService.InputBegan:Connect(function(input, gpe) if gpe then return end if input.KeyCode == toggleKey then guiOpen = not guiOpen main.Visible = guiOpen progressHolder.Visible = true end end)
