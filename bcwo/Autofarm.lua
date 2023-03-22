local Player = game:GetService("Players").LocalPlayer

local Flux = loadstring(game:HttpGet("https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/NewUiLib_NEW"))()

local Window = Flux:Window("Lol", "BCWO", Color3.fromRGB(255, 110, 48), Enum.KeyCode.RightShift)
local Autofarm = Window:Tab("Autofarm", "http://www.roblox.com/asset/?id=6023426915")
local Stats = Window:Tab("Stats", "http://www.roblox.com/asset/?id=6023426915")

--Autofarm

local Autofarm_Info = {
    ShouldAutofarm = false,
}

Autofarm:Toggle("Do autofarm", "Autofarms mobs", false, function(Value)
    Autofarm_Info.ShouldAutofarm = Value
end)

--Stats



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
    return Mob:FindFirstChild("EnemyMain") and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0, Mob:FindFirstChild("HumanoidRootPart")
end

local function ChangeToolGrip(Tool, Part)
    StopPlayerAnimations()
    if Tool:FindFirstChild("Idle") then
        Tool.Idle:Destroy()
        Tool.Grip = CFrame.new()
        Tool.Parent = Player.Backpack
        Tool.Parent = Player.Character
    end

    Tool.Grip = CFrame.new(Player.Character.HumanoidRootPart.Position - Part.Position)
    Tool.Grip = CFrame.new(Tool.Grip.p) * CFrame.new(Tool.Handle.Position - Part.Position)
end

local ToolName = ""
local Timer = tick()

while task.wait() do
    if Autofarm_Info.ShouldAutofarm then
        --Transfer tool to char if in backpack
        local IsInBackpack = Player.Backpack:FindFirstChild(ToolName)
        if IsInBackpack then
            StopPlayerAnimations()
            task.wait()
            IsInBackpack.Parent = Player.Character
        end

        for Index, Mob in next, workspace:GetChildren() do
            local PlayerTool = Player.Character:FindFirstChildWhichIsA("Tool")
            local IsMob, MobPrimaryPart = IsAMob(Mob)
            if Player.Character:FindFirstChild("HumanoidRootPart") and IsAMob(Mob) and MobPrimaryPart and PlayerTool then
                ToolName = PlayerTool.Name
                while Autofarm_Info.ShouldAutofarm and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChildWhichIsA("Tool") and Mob:IsDescendantOf(workspace) and IsAMob(Mob) do
                    Player.Character.HumanoidRootPart.CFrame = CFrame.new(MobPrimaryPart.Position) * CFrame.new(0, -20, 0) * CFrame.fromOrientation(-300, 0, 0)
                    workspace.CurrentCamera.CameraSubject = PlayerTool.Handle
                    ChangeToolGrip(PlayerTool, MobPrimaryPart)
                    
                    --Attack mobs every 0.5 sec
                    if tick() - Timer > 0.5 and PlayerTool:FindFirstChild("RemoteFunction") then
                        coroutine.wrap(function()
                            PlayerTool.RemoteFunction:InvokeServer("hit", {9e9,9e9})
                        end)()
                        Timer = tick()
                    end
                    task.wait()
                end
            end
        end
    end
end
