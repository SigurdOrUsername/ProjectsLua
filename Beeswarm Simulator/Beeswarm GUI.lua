local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local UniversalInfo = {
    QuestInfo = {},
}

local InitScript = {}
InitScript.GrabAllQuestInfo = function()
    local AllQuests = {}

    for Index, Value in next, getgc(true) do
        if typeof(Value) == "table" and rawget(Value, "Tasks") and typeof(rawget(Value, "Tasks")) == "table" then
            table.insert(AllQuests, Value)
        end
    end
    
    return AllQuests
end

--INIT SCRIPT

local function Init()
    --Quests
    UniversalInfo.QuestInfo.AllQuests = InitScript.GrabAllQuestInfo()
end

Init()

--INIT UI

local Flux = loadstring(game:HttpGet("https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/NewUiLib_NEW"))()

local Window = Flux:Window("Lol", "Bee Swarm Simulator", Color3.fromRGB(255, 110, 48), Enum.KeyCode.RightShift)
local World = Window:Tab("World", "http://www.roblox.com/asset/?id=6023426915")
local Feilds = Window:Tab("Feilds", "http://www.roblox.com/asset/?id=6023426915")
local AutoQuest = Window:Tab("Auto quest", "http://www.roblox.com/asset/?id=6023426915")

--UI

--WORLD

local WorldInfo = {
    AutoGrabTokens = false,
    AutoGrabTokensRadius = 100,
    IgnoreRadiusCheck = false,
}

WorldInfo.GrabAllCollectableTokens = function()
    local ValidTokens = {}

    for Index, Token in next, workspace.Collectibles:GetChildren() do
        if Token.Transparency == 0 then
            table.insert(ValidTokens, Token)
        end
    end

    return ValidTokens
end

WorldInfo.GrabToken = function(Token)
    while Token:IsDescendantOf(workspace) and Token.CFrame.YVector.Y >= 1 do
        Player.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0.3, 0)
        Player.Character.HumanoidRootPart.CFrame = Token.CFrame
        task.wait()
    end
end

World:Line()
World:Label("World", Color3.fromRGB(255, 144, 118))

World:Button("Grab all current tokens", "Grab all current tokens in the game", function()
    local Collectibles = WorldInfo.GrabAllCollectableTokens()

    if #Collectibles == 0 then
        Flux:Notification("No tokens found!", "Ok!")
        return
    end

    local OldCFrame = Player.Character.HumanoidRootPart.CFrame

    for Index, Token in next, Collectibles do
        WorldInfo.GrabToken(Token)
    end

    Player.Character.HumanoidRootPart.CFrame = OldCFrame
end)

World:Line()
World:Toggle("Ignore radius check", "Ignores the radius check when collecting new tokens added to the game", function(Value)
    WorldInfo.IgnoreRadiusCheck = Value
end)

World:Slider("Radius of 'Auto grab tokens when added'", "If the radius is higher than this value, the token wont be collected (Can be ignored with toggle above)", 5, 100, 5, function(Value)
    WorldInfo.AutoGrabTokensRadius = Value
end)

World:Toggle("Auto grab tokens when added", "Grabs tokens when added to the game", false, function(Value)
    WorldInfo.AutoGrabTokens = Value
end)

--ChildAdded event for tokens

local IsQueueFull = false
workspace.Collectibles.ChildAdded:Connect(function(Child)

    repeat task.wait() until not IsQueueFull

    if WorldInfo.AutoGrabTokens and Child then
        local Magnitude = (Player.Character.HumanoidRootPart.Position - Child.Position).Magnitude

        if WorldInfo.AutoGrabTokensRadius >= Magnitude or WorldInfo.IgnoreRadiusCheck then
            IsQueueFull = true
            local OldCFrame = Player.Character.HumanoidRootPart.CFrame
            WorldInfo.GrabToken(Child)
            Player.Character.HumanoidRootPart.CFrame = OldCFrame
            IsQueueFull = false
        end
    end

end)

--FEILDS

--AUTO QUEST

local QuestInfo = {
    AutoDoQuests = false
}

AutoQuest:Toggle("Auto do quests", "Auto does quests for you", false, function(Value)
    QuestInfo.AutoDoQuests = Value
end)