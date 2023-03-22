local Player = game:GetService("Players").LocalPlayer

local Flux = loadstring(game:HttpGet("https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/NewUiLib_NEW"))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/Kiriot22%20modified%20esp%20lib"))()

local Window = Flux:Window("Lol", "BCWO", Color3.fromRGB(255, 110, 48), Enum.KeyCode.RightShift)
local Autofarm = Window:Tab("Autofarm", "http://www.roblox.com/asset/?id=6023426915")
local Mining = Window:Tab("Mining", "http://www.roblox.com/asset/?id=6023426915")
local Stats = Window:Tab("Stats", "http://www.roblox.com/asset/?id=6023426915")
local Misc = Window:Tab("Misc", "http://www.roblox.com/asset/?id=6023426915")

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

local function FindIndexInsideNestedTable(Table, Value)
    for ParentIndex, TableValue in next, Table do
        for Index, TableChildValue in next, TableValue do
            if TableChildValue == Value then
                return ParentIndex, true
            end
        end
    end
    return nil, false
end

--Autofarm

local Autofarm_Info = {
    ShouldAutofarm = false,
    RangeTable = {X = 0, Y = -20, Z = 0},
    ToolName = "",
    Timer = tick(),
}

Autofarm:Toggle("Autofarm", "Autofarms mobs! Remember to equip your sword", false, function(Value)
    Autofarm_Info.ShouldAutofarm = Value
    Autofarm_Info.ToolName = ""
end)

Autofarm:Line()
Autofarm:Label("Autofarm offset", Color3.fromRGB(255, 144, 118))

for Index = 1, 3 do
    local Axsis = Index == 1 and "X" or Index == 2 and "Y" or "Z"
    Autofarm:Textbox(Axsis, "The " .. Axsis .. " offset that the autofarm will use", false, function(Value)
        Autofarm_Info.RangeTable[Axsis] = Value
    end)
end

--Mining

local Mining_Info = {
    Init = false,
    OreBlacklist_Visual,
    OreBlacklist = {}
}

local function ShouldOreBeShown(Ore)
    for Index, BlacklistedOre in next, Mining_Info.OreBlacklist do
        if BlacklistedOre.Ore == Ore.Object.Parent.Name then
            return false
        end
    end
    return true
end

local function InitMiningESP()
    if not workspace:FindFirstChild("Map") then Flux:Notification("No ores found", "ok lol") return false end
    for Index, Ore in next, workspace.Map.Ores:GetChildren() do
        if Ore:FindFirstChild("Mineral") then
            ESP:Add(Ore.Mineral, {
                Name = Ore.Name,
                Color = Ore.Mineral.Color,
                IsEnabled = ShouldOreBeShown
            })
        end
    end
    workspace.Map.Ores.ChildAdded:Connect(function(Ore)
        ESP:Add(Ore:WaitForChild("Mineral"), {
            Name = Ore.Name,
            Color = Ore.Mineral.Color,
            IsEnabled = ShouldOreBeShown
        })
    end)
    return true
end

Mining:Toggle("Enable ESP", "Toggles the ESP", false, function(Value)
    if not Mining_Info.Init then
        Mining_Info.Init = InitMiningESP()
    end
    ESP:Toggle(Value)
end)

Mining:Line()
Mining:Label("ESP blacklist", Color3.fromRGB(255, 144, 118))

Mining_Info.OreBlacklist_Visual = Mining:Dropdown("Current blacklist", Mining_Info.OreBlacklist, function() end)
Mining:Textbox("Add to blacklist", "what ores will NOT be shown", true, function(Value)
    table.insert(Mining_Info.OreBlacklist, {
        Ore = Value, 
        Blacklisted_Visual = Mining_Info.OreBlacklist_Visual:Add(Value)
    })
end)
Mining:Textbox("Remove from blacklist", "Removes ores from the blacklist", true, function(Value)
    local BlacklistIndex, FoundOreInBlacklist = FindIndexInsideNestedTable(Mining_Info.OreBlacklist, Value)
    if FoundOreInBlacklist then
        Mining_Info.OreBlacklist_Visual:Remove(Mining_Info.OreBlacklist[BlacklistIndex].Blacklisted_Visual)
        Mining_Info.OreBlacklist[BlacklistIndex] = nil
    else
        return Flux:Notification("Did not find " .. Value .. " in the blacklist", "ok lol")
    end
end)

--Stats

local Stats_Info = {
    BiomeStats_Visual,
    ItemsDropped_Visual,
    AllBiomes = {},
    ItemsDropped = {},
    BannedColors = {
        Color3.new(1, 1, 0),
        Color3.new(1, 0.25, 0.25)
    }
}

local function AddToStats(StatTable, Stat_Visual, Info)
    local Index, HasStatInStatTable = FindIndexInsideNestedTable(StatTable, Info.Text)
    if HasStatInStatTable then
        StatTable[Index].Amount += 1
        StatTable[Index].Label.Text = Info.Text .. ": " .. StatTable[Index].Amount
    else
        table.insert(StatTable, {
            Amount = 0,
            OriginalText = Info.Text,
            Label = Stat_Visual:Add(Info.Text .. ": 0")
        })
        StatTable[#StatTable].Label.TextColor3 = Info.Color
    end
end

Stats_Info.BiomeStats_Visual = Stats:Dropdown("Biomes", Stats_Info.AllBiomes, function() end)
Stats_Info.ItemsDropped_Visual = Stats:Dropdown("Items", Stats_Info.ItemsDropped, function() end)

require(Player.PlayerScripts.ChatScript.ChatMain).ChatMakeSystemMessageEvent:connect(function(Info)
    if not table.find(Stats_Info.BannedColors, Info.Color) then
        if Info.Text:find("got") then
            --AddToStats(Stats_Info.ItemsDropped, Stats_Info.ItemsDropped_Visual, Info)
        else
            AddToStats(Stats_Info.AllBiomes, Stats_Info.BiomeStats_Visual, Info)
        end
    end
end)


while task.wait() do
    if Autofarm_Info.ShouldAutofarm then
        --Transfer tool to char if in backpack
        local IsInBackpack = Player.Backpack:FindFirstChild(Autofarm_Info.ToolName)
        if IsInBackpack then
            StopPlayerAnimations()
            IsInBackpack.Parent = Player.Character
        end

        for Index, Mob in next, workspace:GetChildren() do
            local PlayerTool = Player.Character:FindFirstChildWhichIsA("Tool")
            local IsMob, MobPrimaryPart = IsAMob(Mob)
            if Player.Character:FindFirstChild("HumanoidRootPart") and IsMob and MobPrimaryPart and PlayerTool then
                Autofarm_Info.ToolName = PlayerTool.Name
                while Autofarm_Info.ShouldAutofarm and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChildWhichIsA("Tool") and IsAMob(Mob) do
                    Player.Character.HumanoidRootPart.CFrame = CFrame.new(MobPrimaryPart.Position) * CFrame.new(Autofarm_Info.RangeTable.X, Autofarm_Info.RangeTable.Y, Autofarm_Info.RangeTable.Z) * CFrame.fromOrientation(-300, 0, 0)
                    workspace.CurrentCamera.CameraSubject = PlayerTool.Handle
                    ChangeToolGrip(PlayerTool, MobPrimaryPart)
                    
                    --Attack mobs every 0.5 sec
                    if tick() - Autofarm_Info.Timer > 0.5 and PlayerTool:FindFirstChild("RemoteFunction") then
                        coroutine.wrap(function()
                            PlayerTool.RemoteFunction:InvokeServer("hit", {})
                        end)()
                        Autofarm_Info.Timer = tick()
                    end
                    task.wait()
                end
            end
        end
    end
end
