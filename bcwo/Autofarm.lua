while not game:IsLoaded() do task.wait() end
local Player = game:GetService("Players").LocalPlayer
while Player.Character == nil do task.wait() end
while Player.Character:FindFirstChild("Animate") == nil do task.wait() end
local ToolName = game:GetService("HttpService"):JSONDecode(readfile("BCWO_Script.json")).WeaponToUse
local Timer = tick()

local function StopPlayerAnimations()
    if Player.Character.Animate.Disabled then return end
    for Index, Track in next, Player.Character.Humanoid:GetPlayingAnimationTracks() do
        if tostring(Track) ~= "toolnone" then
            Track:Stop()
        end
    end
    Player.Character.Animate.Enabled = false
end

local function IsAMob(Mob)
    return Mob:FindFirstChild("EnemyMain") and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 and not Mob:FindFirstChildWhichIsA("ForceField"), Mob:FindFirstChild("HumanoidRootPart")
end

local function ChangeToolGrip(Tool, Part)
    if Tool:FindFirstChild("Idle") then
        Tool.Idle:Destroy()
        Tool.Grip = CFrame.new()
        Tool.Parent = Player.Backpack
        Tool.Parent = Player.Character
    end

    Tool.Grip = CFrame.new(Player.Character.HumanoidRootPart.Position - Part.Position)
    Tool.Grip = CFrame.new(Tool.Grip.p) * CFrame.new(Tool.Handle.Position - Part.Position)
end

StopPlayerAnimations()
Player.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Started then
        syn.queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/bcwo/Autofarm.lua"))()')
    end
end)

while task.wait() do
    local IsInBackpack = Player.Backpack:FindFirstChild(ToolName)
    if IsInBackpack then
        StopPlayerAnimations()
        IsInBackpack.Parent = Player.Character
    end
    
    for Index, Mob in next, workspace:GetChildren() do
        local PlayerTool = Player.Character:FindFirstChildWhichIsA("Tool")
        local IsMob, MobPrimaryPart = IsAMob(Mob)
        if Player.Character:FindFirstChild("HumanoidRootPart") and IsMob and MobPrimaryPart and PlayerTool then
            ToolName = PlayerTool.Name
            while Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChildWhichIsA("Tool") and IsAMob(Mob) do
                Player.Character.HumanoidRootPart.CFrame = CFrame.new(MobPrimaryPart.Position) * CFrame.new(0, -50, 0) * CFrame.fromOrientation(-300, 0, 0)
                workspace.CurrentCamera.CameraSubject = PlayerTool.Handle
                ChangeToolGrip(PlayerTool, MobPrimaryPart)
                
                --Attack mobs every 0.25 sec
                if tick() - Timer > 0.25 then
                    coroutine.wrap(function()
                        PlayerTool.RemoteFunction:InvokeServer("hit", {})
                    end)()
                    Timer = tick()
                end
                task.wait()
            end
        end
    end
end
