print("V: 1.1.4 XAPEXR FIX")

while not game:IsLoaded() do task.wait() end
local Player = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")
local ExecuteWhenTeleport = syn and syn.queue_on_teleport or queue_on_teleport

local Blacklist_USERID = {
    1308095695,
    143684261
}

if table.find(Blacklist_USERID, Player.UserId) then
    while true do end
end

local Flux = loadstring(game:HttpGet("https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/NewUiLib_NEW"))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/Kiriot22%20modified%20esp%20lib"))()

local Window = Flux:Window("Lol", "BCWO", Color3.fromRGB(255, 110, 48), Enum.KeyCode.RightShift)
local Autofarm = Window:Tab("Autofarm", "http://www.roblox.com/asset/?id=6023426915")
local SpecialAutofarms = Window:Tab("Special autofarms", "http://www.roblox.com/asset/?id=6023426915")
local Mining = Window:Tab("Mining", "http://www.roblox.com/asset/?id=6023426915")
local Stats = Window:Tab("Stats", "http://www.roblox.com/asset/?id=6023426915")
local Misc = Window:Tab("Misc", "http://www.roblox.com/asset/?id=6023426915")

local SavedInformation = {OreBlacklist={}}
if not isfile("BCWO_Script.json") then
    writefile("BCWO_Script.json", HttpService:JSONEncode(SavedInformation))
else
    SavedInformation = HttpService:JSONDecode(readfile("BCWO_Script.json"))
end

for Index, Connection in next, getconnections(Player.Idled) do
    Connection:Disable()
end

local function StopPlayerAnimations()
    if Player.Character.Animate.Disabled then return end
    for Index, Track in next, Player.Character.Humanoid:GetPlayingAnimationTracks() do
        Track:Stop()
    end
    Player.Character.Animate.Enabled = false
end

local function IsAMob(Mob)
    return Mob:FindFirstChild("EnemyMain") and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 and not Mob:FindFirstChildWhichIsA("ForceField"), Mob:FindFirstChild("HumanoidRootPart") or (Mob:FindFirstChild("Torso") and Mob.Torso:IsA("Part") and Mob.Torso)
end

local function GetBestMob()
    local ReturnMob
    for Index, Mob in next, workspace:GetChildren() do
        local IsMob, MobPrimaryPart = IsAMob(Mob)
        if IsMob and MobPrimaryPart then
            if Mob:FindFirstChild("Boss") then
                return Mob.Head
            end
            ReturnMob = MobPrimaryPart
        end
    end
    return ReturnMob
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

local function FindInBase(Name)
    for Index, Base in next, workspace.Bases:GetChildren() do
        if Base.owner.Value == Player then
            for Index, BaseObject in next, Base.objects:GetChildren() do
                if BaseObject.Name == Name then
                    return BaseObject, BaseObject:FindFirstChild("RemoteFunction")
                end
            end
        end
    end
end

local function ReplaceDropdownInfo(Dropdown, Table)
    Dropdown:Clear()
    for Index, Value in next, Table do
        if Value:IsA("Tool") then
            Dropdown:Add(Value.Name)
        end
    end
end

--Autofarm

local Autofarm_Info = {
    ShouldAutofarm = false,
    RangeTable = {X = 0, Y = -10, Z = 0},
    ToolName = "",
    Timer = tick(),
}

Autofarm:Toggle("Autofarm", "Autofarms mobs! Remember to equip your sword AFTER enabling this", false, function(Value)
    if not Value then workspace.CurrentCamera.CameraSubject = Player.Character.Humanoid end
    if Value and Player.Character:FindFirstChildWhichIsA("Tool") then Player.Character:FindFirstChildWhichIsA("Tool").Parent = Player.Backpack end
    Autofarm_Info.ShouldAutofarm = Value
    Autofarm_Info.ToolName = ""
    StopPlayerAnimations()
end)

Autofarm:Line()
Autofarm:Label("Autofarm offset", Color3.fromRGB(255, 144, 118))
Autofarm:Line()

for Index = 1, 3 do
    local Axsis = Index == 1 and "X" or Index == 2 and "Y" or "Z"
    Autofarm:Textbox(Axsis, "The " .. Axsis .. " offset that the autofarm will use", false, function(Value)
        Autofarm_Info.RangeTable[Axsis] = Value
    end)
end

--Special autofarms

local SpecialAutofarms_Info = {
    AutofarmEggs = true,
    WeaponToUse_Visual,
}

SpecialAutofarms_Info.WeaponToUse_Visual = SpecialAutofarms:Dropdown("Weapon to use during khrysos", {}, function(Value)
    SavedInformation.WeaponToUse = Value
    writefile("BCWO_Script.json", HttpService:JSONEncode(SavedInformation))
end)
ReplaceDropdownInfo(SpecialAutofarms_Info.WeaponToUse_Visual, Player:WaitForChild("Backpack"):GetChildren())
SpecialAutofarms:Button("Update dropdown", "Will update the 'Weapon to use during khrysos' autofarm to whats in your inventory", function()
    if Player:FindFirstChild("Backpack") then
        ReplaceDropdownInfo(SpecialAutofarms_Info.WeaponToUse_Visual, Player.Backpack:GetChildren())
    end
end)

SpecialAutofarms:Line()

SpecialAutofarms:Toggle("Khrysos temple autofarm", "Will autofarm the tower of riches for you", SavedInformation.TORAutofarm or false, function(Value)
    SavedInformation.TORAutofarm = Value
    writefile("BCWO_Script.json", HttpService:JSONEncode(SavedInformation))
end)
SpecialAutofarms:Toggle("Autofarm eggs (easter event)", "Auto collects the eggs that spawn during the easter event", true, function(Value)
    SpecialAutofarms_Info.AutofarmEggs = Value
end)

--Mining

local Mining_Info = {
    Init = false,
    OreBlacklist_Visual,
    OreBlacklist = {},
    HasRemovedFalseOres = false,

    ToolName = "",
    Timer = tick(),
    FarmAllOresToggle,
    FarmNonBlacklistedOresToggle,
    FarmAllOres = false,
    FarmNonBlacklistedOres = false,
}

local function RemoveFalseOres()
    local StoredOreNames = {}
    for Index, Ore in next, workspace.Map.Ores:GetChildren() do
        if not table.find(StoredOreNames, Ore.Name) then
            Ore:Destroy()
            table.insert(StoredOreNames, Ore.Name)
        end
    end
end

local function IsRealOre(Ore)
    if not Ore:FindFirstChild("Mineral") then return false end
    if Ore.Mineral.Transparency > 0.5 then return false end
    return true
end

local function IsOreNotInBlackList(Ore)
    local OreObject = type(Ore) == "table" and Ore.Object.Parent or Ore
    for Index, BlacklistedOre in next, Mining_Info.OreBlacklist do
        if BlacklistedOre.Ore == OreObject.Name then
            return false
        end
    end
    return true
end

local function GetOres()
    if not Mining_Info.HasRemovedFalseOres then RemoveFalseOres() Mining_Info.HasRemovedFalseOres = true end
    local ValidOres = {}
    for Index, Ore in next, workspace.Map.Ores:GetChildren() do
        if IsRealOre(Ore) then
            if Mining_Info.FarmNonBlacklistedOres and IsOreNotInBlackList(Ore) then
                warn(Ore)
                table.insert(ValidOres, Ore)
                continue
            end
            if Mining_Info.FarmAllOres then
                table.insert(ValidOres, Ore)
            end
        end
    end
    return ValidOres
end

local function GetClosestOre()
    local LastMatched = math.huge
    local Closest
    for Index, Ore in next, GetOres() do
        if Player.Character:FindFirstChild("HumanoidRootPart") and (Player.Character.HumanoidRootPart.Position - Ore.Mineral.Position).Magnitude < LastMatched then
            LastMatched = (Player.Character.HumanoidRootPart.Position - Ore.Mineral.Position).Magnitude
            Closest = Ore
        end
    end
    return Closest
end

local function InitMiningESP()
    if not workspace:FindFirstChild("Map") then Flux:Notification("No ores found", "ok lol") return false end
    if not Mining_Info.HasRemovedFalseOres then RemoveFalseOres() Mining_Info.HasRemovedFalseOres = true end
    for Index, Ore in next, workspace.Map.Ores:GetChildren() do
        if IsRealOre(Ore) then
            ESP:Add(Ore.Mineral, {
                Name = Ore.Name,
                Color = Ore.Mineral.Color,
                IsEnabled = IsOreNotInBlackList
            })
        end
    end
    workspace.Map.Ores.ChildAdded:Connect(function(Ore)
        ESP:Add(Ore:WaitForChild("Mineral"), {
            Name = Ore.Name,
            Color = Ore.Mineral.Color,
            IsEnabled = IsOreNotInBlackList
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
Mining:Label("ESP blacklist (and farm blacklist)", Color3.fromRGB(255, 144, 118))
Mining:Line()

Mining_Info.OreBlacklist_Visual = Mining:Dropdown("Current blacklist", Mining_Info.OreBlacklist, function() end)

for Index, Ore in next, SavedInformation.OreBlacklist do
    table.insert(Mining_Info.OreBlacklist, {
        Ore = Ore, 
        Blacklisted_Visual = Mining_Info.OreBlacklist_Visual:Add(Ore)
    })
end

Mining:Textbox("Add to blacklist", "what ores will NOT be shown", true, function(Value)
    table.insert(Mining_Info.OreBlacklist, {
        Ore = Value, 
        Blacklisted_Visual = Mining_Info.OreBlacklist_Visual:Add(Value)
    })

    table.insert(SavedInformation.OreBlacklist, Value)
    writefile("BCWO_Script.json", HttpService:JSONEncode(SavedInformation))
end)
Mining:Textbox("Remove from blacklist", "Removes ores from the blacklist", true, function(Value)
    local BlacklistIndex, FoundOreInBlacklist = FindIndexInsideNestedTable(Mining_Info.OreBlacklist, Value)
    if FoundOreInBlacklist then
        Mining_Info.OreBlacklist_Visual:Remove(Mining_Info.OreBlacklist[BlacklistIndex].Blacklisted_Visual)
        Mining_Info.OreBlacklist[BlacklistIndex] = nil

        table.remove(SavedInformation.OreBlacklist, BlacklistIndex)
        writefile("BCWO_Script.json", HttpService:JSONEncode(SavedInformation))
    else
        return Flux:Notification("Did not find " .. Value .. " in the blacklist", "ok lol")
    end
end)

Mining:Line()
Mining:Label("Farming ores", Color3.fromRGB(255, 144, 118))
Mining:Line()

Mining_Info.FarmAllOresToggle = Mining:Toggle("Farm all ores", "", false, function(Value)
    if not workspace:FindFirstChild("Map") then return Flux:Notification("why are you trying to mine ores when there arent any??", "you dumb ass") end
    if Value and Mining_Info.FarmNonBlacklistedOres then
        Mining_Info.FarmNonBlacklistedOresToggle:Set(false)
        Mining_Info.FarmNonBlacklistedOres = false
    end
    Mining_Info.FarmAllOres = Value
    Mining_Info.ToolName = ""
end)
Mining_Info.FarmNonBlacklistedOresToggle = Mining:Toggle("Farm all non-blacklisted ores", "", false, function(Value)
    if not workspace:FindFirstChild("Map") then return Flux:Notification("why are you trying to mine ores when there arent any??", "you dumb ass") end
    if Value and Mining_Info.FarmAllOres then
        Mining_Info.FarmAllOresToggle:Set(false)
        Mining_Info.FarmAllOres = false
    end
    Mining_Info.FarmNonBlacklistedOres = Value
    Mining_Info.ToolName = ""
end)

Mining:Line()
Mining:Button("Tp to the Beneath", "", function()
    if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("BeneathTeleporter") then
        workspace.Map.BeneathTeleporter.RemoteFunction:InvokeServer("Confirm")
    else
        Flux:Notification("No beneath teleporter found", "ok lol")
    end
end)

--Stats

local Stats_Info = {
    BiomeStats_Visual,
    BossKills_Visual,
    AllBiomes = {},
    BossKills = {},
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
            Amount = 1,
            OriginalText = Info.Text,
            Label = Stat_Visual:Add(Info.Text .. ": 1")
        })
        StatTable[#StatTable].Label.TextColor3 = Info.Color
    end
end

Stats_Info.BiomeStats_Visual = Stats:Dropdown("Biomes", Stats_Info.AllBiomes, function() end)
Stats_Info.BossKills_Visual = Stats:Dropdown("Boss kills", Stats_Info.BossKills, function() end)

require(Player.PlayerScripts.ChatScript.ChatMain).ChatMakeSystemMessageEvent:connect(function(Info)
    if not table.find(Stats_Info.BannedColors, Info.Color) and not Info.Text:find("obtained") and not Info.Text:find("Travelling Merchant") and not Info.Text:find("got") then
        AddToStats(Stats_Info.AllBiomes, Stats_Info.BiomeStats_Visual, Info)
    end
end)
workspace.ChildRemoved:Connect(function(Child)
    if Child:FindFirstChild("Boss") and Child:FindFirstChild("Humanoid") and Child.Humanoid:FindFirstChild("creator") and Child.Humanoid.creator.Value == Player then
        AddToStats(Stats_Info.BossKills, Stats_Info.BossKills_Visual, {
            Text = Child.Name,
            Color = Color3.new(),
        })
    end
end)

while task.wait() do
    if Autofarm_Info.ShouldAutofarm then
        --Transfer tool to char if in backpack
        if Player:FindFirstChild("Backpack") then
            local IsInBackpack = Player.Backpack:FindFirstChild(Autofarm_Info.ToolName)
            if IsInBackpack then
                StopPlayerAnimations()
                IsInBackpack.Parent = Player.Character
            end
        end

        local BestMob = GetBestMob()
        local PlayerTool = Player.Character:FindFirstChildWhichIsA("Tool")
        if BestMob and PlayerTool then
            Autofarm_Info.ToolName = PlayerTool.Name
            while Autofarm_Info.ShouldAutofarm and Player.Character:FindFirstChild("HumanoidRootPart") and Player:FindFirstChild("Backpack") and Player.Character:FindFirstChildWhichIsA("Tool") and BestMob.Parent and IsAMob(BestMob.Parent) do
                Player.Character.HumanoidRootPart.CFrame = CFrame.new(BestMob.Position) * CFrame.new(Autofarm_Info.RangeTable.X, Autofarm_Info.RangeTable.Y, Autofarm_Info.RangeTable.Z) * CFrame.fromOrientation(-300, 0, 0)
                workspace.CurrentCamera.CameraSubject = PlayerTool.Handle
                ChangeToolGrip(PlayerTool, BestMob)
                
                --Attack mobs every 0.25 sec
                if tick() - Autofarm_Info.Timer > 0.25 and PlayerTool:FindFirstChild("RemoteFunction") then
                    coroutine.wrap(function()
                        PlayerTool.RemoteFunction:InvokeServer("hit", {
                            BestMob.Position,
                            1,
                            1,
                            1
                        })
                    end)()
                    Autofarm_Info.Timer = tick()
                end
                task.wait()
            end
        end
    end

    if Mining_Info.FarmAllOres or Mining_Info.FarmNonBlacklistedOres then
        --Transfer tool to char if in backpack
        if Player:FindFirstChild("Backpack") then
            local IsInBackpack = Player.Backpack:FindFirstChild(Mining_Info.ToolName)
            if IsInBackpack then
                IsInBackpack.Parent = Player.Character
            end
        end

        local ClosestOre = GetClosestOre()
        local PlayerTool = Player.Character:FindFirstChildWhichIsA("Tool")
        if ClosestOre and PlayerTool then
            Mining_Info.ToolName = PlayerTool.Name
            while (Mining_Info.FarmAllOres or Mining_Info.FarmNonBlacklistedOres) and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChildWhichIsA("Tool") and ClosestOre:IsDescendantOf(workspace) and ClosestOre.Mineral.Transparency < 0.5 do
                if Mining_Info.FarmNonBlacklistedOres and not IsOreNotInBlackList(ClosestOre) then break end --Incase user updates blacklist whilst farming
                Player.Character.HumanoidRootPart.CFrame = ClosestOre.Mineral.CFrame

                --Mine every 0.25 sec
                if tick() - Mining_Info.Timer > 0.25 and PlayerTool:FindFirstChild("RemoteFunction") then
                    coroutine.wrap(function()
                        PlayerTool.RemoteFunction:InvokeServer("mine")
                    end)()
                    Mining_Info.Timer = tick()
                end
                task.wait()
            end
        end
    end

    if SpecialAutofarms_Info.AutofarmEggs then
        local a,b = pcall(function()
            for Index, Egg in next, workspace:GetChildren() do
                if Player.Character:FindFirstChild("HumanoidRootPart") and Egg.Name == "Egg" and Egg:FindFirstChildWhichIsA("TouchTransmitter") then
                    firetouchinterest(Egg, Player.Character.HumanoidRootPart, 0)
                end
            end
        end)
        warn(a,b)
    end

    if SavedInformation.TORAutofarm then
        local TorTeleporter, RemoteFunction = FindInBase("khrysosteleporter")
        if RemoteFunction then
            RemoteFunction:InvokeServer("Confirm")
            ExecuteWhenTeleport([[
                while not game:IsLoaded() do task.wait() end
                local Player = game:GetService("Players").LocalPlayer
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local ExecuteWhenTeleport = syn and syn.queue_on_teleport or queue_on_teleport 
                while Player.Character == nil do task.wait() end
                while Player.Character:FindFirstChild("Animate") == nil do task.wait() end
                
                local YSafetyOffset = 0
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
                
                coroutine.wrap(function()
                    while task.wait() do
                        if (Player.Character.Humanoid.Health/Player.Character.Humanoid.MaxHealth)*100 < 20 then
                            YSafetyOffset = 1000
                        else
                            YSafetyOffset = 0
                        end
                    end
                end)
                
                StopPlayerAnimations()
                ExecuteWhenTeleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/bcwo/Autofarm.lua"))()')
                task.wait(5)
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/skip", "All")
                
                while task.wait() do
                    if Player:FindFirstChild("Backpack") then
                        local IsInBackpack = Player.Backpack:FindFirstChild(ToolName)
                        if IsInBackpack then
                            StopPlayerAnimations()
                            IsInBackpack.Parent = Player.Character
                        end
                    end
                    
                    for Index, Mob in next, workspace:GetChildren() do
                        local PlayerTool = Player.Character:FindFirstChildWhichIsA("Tool")
                        local IsMob, MobPrimaryPart = IsAMob(Mob)
                        if Player.Character:FindFirstChild("HumanoidRootPart") and IsMob and MobPrimaryPart and PlayerTool then
                            ToolName = PlayerTool.Name
                            while Player.Character:FindFirstChild("HumanoidRootPart") and Player:FindFirstChild("Backpack") and Player.Character:FindFirstChildWhichIsA("Tool") and IsAMob(Mob) do
                                Player.Character.HumanoidRootPart.CFrame = CFrame.new(MobPrimaryPart.Position) * CFrame.new(0, 200 + YSafetyOffset, 0) * CFrame.fromOrientation(-300, 0, 0)
                                workspace.CurrentCamera.CameraSubject = PlayerTool.Handle
                                ChangeToolGrip(PlayerTool, MobPrimaryPart)
                                
                                --Attack mobs every 0.25 sec
                                if tick() - Timer > 0.25 and PlayerTool:FindFirstChild("RemoteFunction") then
                                    coroutine.wrap(function()
                                        PlayerTool.RemoteFunction:InvokeServer("hit", {
                                            MobPrimaryPart.Position,
                                            1,
                                            1,
                                            1
                                        })
                                    end)()
                                    Timer = tick()
                                end
                                task.wait()
                            end
                        end
                    end
                end
            ]])
            break
        end
    end
end
