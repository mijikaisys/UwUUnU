local Stats = game:GetService('Stats')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Nurysium_Util = loadstring(game:HttpGet('https://raw.githubusercontent.com/cracklua/cracks/m/sources/pitbull/Scripts/Blade%20Ball.lua'))()

local local_player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local hit_Sound = nil
local closest_Entity = nil
local hitremote = nil

getgenv().aura_Enabled = true 
getgenv().hit_sound_Enabled = false
getgenv().hit_effect_Enabled = false
getgenv().night_mode_Enabled = false
getgenv().trail_Enabled = false
getgenv().self_effect_Enabled = false
getgenv().antiCurveEnabled = true 

local Services = {
    game:GetService('AdService'),
    game:GetService('SocialService')
}

function initialize(dataFolder_name: string)
    local nurysium_Data = Instance.new('Folder', game:GetService('CoreGui'))
    nurysium_Data.Name = dataFolder_name
    hit_Sound = Instance.new('Sound', nurysium_Data)
    hit_Sound.SoundId = 'rbxassetid://936447863'
    hit_Sound.Volume = 5
end

local function get_closest_entity(Object: Part)
    local closest_Entity = nil
    local max_distance = math.huge

    for _, entity in workspace.Alive:GetChildren() do
        if entity.Name ~= Players.LocalPlayer.Name then
            local distance = (Object.Position - entity.HumanoidRootPart.Position).Magnitude
            if distance < max_distance then
                closest_Entity = entity
                max_distance = distance
            end
        end
    end
    
    return closest_Entity
end

function resolve_hitRemote()
    for _, value in Services do
        local temp_remote = value:FindFirstChildOfClass('RemoteEvent')
        if temp_remote and temp_remote.Name:find('\n') then
            hitremote = temp_remote
            break
        end
    end
end

local aura_table = {
    canParry = true,
    hit_Count = 0,
    parry_Range = 0,
    hit_Time = tick(),
}

ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    if getgenv().hit_sound_Enabled then
        hit_Sound:Play()
    end
    if getgenv().hit_effect_Enabled then
        local hit_effect = game:GetObjects("rbxassetid://17407244385")[1]
        hit_effect.Parent = Nurysium_Util.getBall()
        hit_effect:Emit(3)
        task.delay(5, function()
            hit_effect:Destroy()
        end)
    end
end)

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function()
    aura_table.hit_Count += 1
    task.delay(0.15, function()
        aura_table.hit_Count -= 1
    end)
end)

workspace:WaitForChild("Balls").ChildRemoved:Connect(function(child)
    aura_table.hit_Count = 0
end)

task.defer(function()
    game:GetService("RunService").Heartbeat:Connect(function()
        if not local_player.Character then return end

        if getgenv().trail_Enabled then
            local trail = game:GetObjects("rbxassetid://17483658369")[1]
            trail.Name = 'nurysium_fx'
            if local_player.Character.PrimaryPart:FindFirstChild('nurysium_fx') then return end

            local Attachment0 = Instance.new("Attachment", local_player.Character.PrimaryPart)
            local Attachment1 = Instance.new("Attachment", local_player.Character.PrimaryPart)
            Attachment0.Position = Vector3.new(0, -2.411, 0)
            Attachment1.Position = Vector3.new(0, 2.504, 0)
            trail.Parent = local_player.Character.PrimaryPart
            trail.Attachment0 = Attachment0
            trail.Attachment1 = Attachment1
        else
            if local_player.Character.PrimaryPart:FindFirstChild('nurysium_fx') then
                local_player.Character.PrimaryPart['nurysium_fx']:Destroy()
            end
        end
    end)
end)

task.spawn(function()
    while task.wait(1) do
        if getgenv().night_mode_Enabled then
            game:GetService("TweenService"):Create(game:GetService("Lighting"), TweenInfo.new(3), {ClockTime = 3.9}):Play()
        else
            game:GetService("TweenService"):Create(game:GetService("Lighting"), TweenInfo.new(3), {ClockTime = 13.5}):Play()
        end
    end
end)

function autoparry()
    RunService.Heartbeat:Connect(function()
        if not getgenv().aura_Enabled then return end

        local self = Nurysium_Util.getBall()
        if not self or not local_player.Character then return end

        local player_Position = local_player.Character.PrimaryPart.Position
        local ball_Position = self.Position
        local ball_Velocity = self.AssemblyLinearVelocity

        local distanceToBall = (player_Position - ball_Position).Magnitude

        if distanceToBall <= aura_table.parry_Range and ball_Velocity.Magnitude > 0 then
            local target_Position = self.Position
            hitremote:FireServer(
                0.5,
                CFrame.new(camera.CFrame.Position, target_Position),
                {[closest_Entity.Name] = target_Position},
                {target_Position.X, target_Position.Y},
                false
            )

            aura_table.canParry = false
            task.delay(0.15, function() 
                aura_table.canParry = true 
            end)
        end
    end)
end

function preventCurve(ball)
    local previousPosition = ball.Position
    RunService.Heartbeat:Connect(function()
        if getgenv().antiCurveEnabled then
            local currentPosition = ball.Position
            local velocity = ball.Velocity

            if (currentPosition - previousPosition).Magnitude > 0.1 and velocity.Magnitude > 0 then
                ball.Velocity = (currentPosition - previousPosition).Unit * velocity.Magnitude
            end

            previousPosition = currentPosition
        end
    end)
end

local function onBallAdded(ball)
    if ball:IsA("BasePart") and ball.Name == "Ball" then
        preventCurve(ball)
    end
end

workspace:WaitForChild("Balls").ChildAdded:Connect(onBallAdded)

for _, ball in ipairs(workspace:WaitForChild("Balls"):GetChildren()) do
    onBallAdded(ball)
end

initialize('nurysium_temp')
resolve_hitRemote()
autoparry() -- Activation de l'autoparry dès l'exécution du script.
