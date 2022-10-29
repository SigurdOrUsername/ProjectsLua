--INIT

local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UniversalInfo = {
    RemoteKey = ReplicatedStorage.RelativeTime,
    
    --Misc
    RobloxG = getrenv()._G,
    LocalHandlerEnv = getsenv(Player.PlayerScripts:WaitForChild("Local Handler")),
    AllGameAnimations = {},

    --Modules
    ItemData = require(ReplicatedStorage.Modules.ItemData),

}

local function GetToolbarInfo(Item)
    return UniversalInfo.RobloxG.data.toolbar[Item]
end

local function GetItemInfo(Item)
    return UniversalInfo.ItemData[GetToolbarInfo(Item).name]
end

--Get all animations
for Index, Upvalue in next, getupvalues(UniversalInfo.LocalHandlerEnv.SetupCharacter) do
    if typeof(Upvalue) == "table" and Upvalue["Slash"] then --Slash is a common animation
        UniversalInfo.AllGameAnimations = Upvalue
    end
end

--END INIT

local Flux = loadstring(game:HttpGet("https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/NewUiLib_NEW"))()
local ESP = loadstring(game:HttpGet("https://pastebin.com/raw/k2CcQ9hw"))()

local Window = Flux:Window("Lol", "Booga Booga", Color3.fromRGB(255, 110, 48), Enum.KeyCode.RightShift)
local General = Window:Tab("General", "http://www.roblox.com/asset/?id=6023426915")
local ESPTab = Window:Tab("ESP", "http://www.roblox.com/asset/?id=6023426915")
local Misc = Window:Tab("Misc", "http://www.roblox.com/asset/?id=6023426915")

--General

local General_Info = {
    SwingAuraRange = 5,
    SwingAura = false,
    KillauraRange = 5,
    DamageMobs = false,
    DamagePlayers = false,
    Killaura = false,
}

local function GrabAllValidObjects(Area, WhichRange)
    if not Player.Character then
        return
    end
    if not Player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local ValidObjects = {}

    for Index, Object in next, Area:GetChildren() do
        if Object ~= Player and Object ~= Player.Character and Object:IsA("Model") and Object.PrimaryPart and Object:FindFirstChild("Health") and Object.Health.Value >= 1 and (Player.Character.HumanoidRootPart.Position - Object.PrimaryPart.Position).Magnitude <= WhichRange then
            table.insert(ValidObjects, Object.PrimaryPart)
        end
    end

    return ValidObjects
end

local function SwingTool(DealDamageToTable)
    --Speed check so we dont spam remotes
    if GetItemInfo(UniversalInfo.RobloxG.data.equipped).speed <= UniversalInfo.RemoteKey.Value - GetToolbarInfo(UniversalInfo.RobloxG.data.equipped).lastSwing then
        GetToolbarInfo(UniversalInfo.RobloxG.data.equipped).lastSwing = UniversalInfo.RemoteKey.Value
        ReplicatedStorage.Events.SwingTool:FireServer(UniversalInfo.RemoteKey.Value, DealDamageToTable)
    else
        return
    end
end

General:Line()
General:Label("Swing aura", Color3.fromRGB(255, 144, 118))
General:Slider("Swing aura range", "The range 'Swing aura' will have", 5, 15, nil, function(Value)
    General_Info.SwingAuraRange = Value
end)
General:Toggle("Swing aura", "Mines stuff around you, gives you further reach based on 'Swing aura'", false, function(Value)
    General_Info.SwingAura = Value
end)

General:Line()
General:Label("Killaura", Color3.fromRGB(255, 144, 118))
General:Slider("Killaura range", "The range 'Killaura' will have", 5, 15, nil, function(Value)
    General_Info.KillauraRange = Value
end)
General:Toggle("Damage mobs", "Will killaura mobs", false, function(Value)
    General_Info.DamageMobs = Value
end)
General:Toggle("Damage players", "Will killaura players", false, function(Value)
    General_Info.DamagePlayers = Value
end)
General:Toggle("Killaura", "Deals damage to stuff around you", false, function(Value)
    General_Info.Killaura = Value
end)


--Swingaura and killaura
coroutine.wrap(function()
    while task.wait() do

        if General_Info.SwingAura then
            local ValidObjects = GrabAllValidObjects(workspace, General_Info.SwingAuraRange)

            warn(ValidObjects, UniversalInfo.RobloxG.data, UniversalInfo.RobloxG.data.equipped)
            if ValidObjects and #ValidObjects >= 1 and UniversalInfo.RobloxG.data.equipped then
                SwingTool(ValidObjects)
            end
        end

        if General_Info.Killaura then
            local ValidObjects = {}

            --Add mobs to valid objects if user enables the feature
            if General_Info.DamageMobs then
                for Index, Object in next, GrabAllValidObjects(workspace.Critters, General_Info.KillauraRange) do
                    table.insert(ValidObjects, Object)
                end
            end

            --Add players (excluding the users player) to valid objects if user enables the feature
            if General_Info.DamagePlayers then
                for Index, Object in next, GrabAllValidObjects(game.Players, General_Info.KillauraRange) do
                    table.insert(ValidObjects, Object)
                end
            end

            --Swings the tool the user has equipped
            if #ValidObjects >= 1 and UniversalInfo.RobloxG.data.equipped then
                SwingTool(ValidObjects)
            end
        end
    end
end)()

--ESP

local ESP_Info = {
}

local function UpdateESP(Name, SetTo)
    if not ESP[Name] then
        ESP[Name] = SetTo
    end
    ESP[Name] = SetTo
end

ESPTab:Toggle("Enable ESP", "Enables/disables the entire ESP", false, function(Value)
    ESP:Toggle(Value)
end)

ESPTab:Line()

ESPTab:Toggle("Pumpkin ESP", "Shows all the pumpkins on the map", false, function(Value)
    UpdateESP("PumpkinESP", Value)
end)
ESPTab:Toggle("God locations", "Shows the loaction of all the gods on the map", false, function(Value)
    UpdateESP("GodESP", Value)
end)

--Init pumpkin
for Index, Pumpkin in next, workspace.pumpkins:GetChildren() do
    if Pumpkin:IsA("Model") and Pumpkin:FindFirstChild("Reference") then
        ESP:Add(Pumpkin, {
            PrimaryPart = Pumpkin.Reference,
            IsEnabled = "PumpkinESP",
        })
    end
end
UpdateESP("PumpkinESP", false)

--Init god
for Index, God in next, workspace:GetChildren() do
    if God.Name:find("God") and God:FindFirstChild("Totem") then
        ESP:Add(God, {
            PrimaryPart = God.Totem,
            IsEnabled = "GodESP",
            Color = Color3.fromRGB(0, 100, 100)
        })
    end
end
UpdateESP("GodESP", false)

--Misc

local Misc_Info = {
    IncreaseReach = false,
    DontRunNamecallHook = false
}

local function GetTouchingPartsOfIncreasedArea(Area, Part)
    local TempClone = Part:Clone()
    local ReturnValue

    TempClone.Size = Area
    TempClone.CFrame = Part.CFrame
    TempClone.Parent = Part.Parent

    Misc_Info.DontRunNamecallHook = true
    ReturnValue = TempClone:GetTouchingParts()
    Misc_Info.DontRunNamecallHook = false

    local SortedResults = {}
    for Index, Result in next, ReturnValue do
        --Is part of player character, Is terrain
        if not Result:IsDescendantOf(Part.Parent) and Result ~= workspace.Terrain then
            SortedResults[#SortedResults + 1] = Result
        end
    end

    TempClone:Destroy()
    return SortedResults
end

Misc:Line()
Misc:Label("Reach hacks", Color3.fromRGB(255, 144, 118))

Misc:Toggle("Increase reach", "Increases the reach (of your swing, as far as i've tested), can be modified by the slider above", false, function(Value)
    Misc_Info.IncreaseReach = Value
end)

local Old
Old = hookmetamethod(game, "__namecall", function(Self, ...)
    local Args = {...}

    if getnamecallmethod() == "GetTouchingParts" and not Misc_Info.DontRunNamecallHook and Misc_Info.IncreaseReach then
        return GetTouchingPartsOfIncreasedArea(Vector3.new(15, 15, 15), Player.Character.HumanoidRootPart)
    end

    return Old(Self, ...)
end)
