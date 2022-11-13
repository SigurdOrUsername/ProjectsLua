repeat task.wait() until game:IsLoaded()

local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerNetwork = ReplicatedStorage.Core.CoreEvents.ClientServerNetwork.ServerNetwork
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")

repeat task.wait() until Player:FindFirstChild("leaderstats")

local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local function GetInventory(Type)
    local Inventory = {}
    
    local Items = ServerNetwork:InvokeServer("DataFunctions", {
        Function = "RetrieveItems"
    })
    local EquippedItems = ServerNetwork:InvokeServer("DataFunctions", {
    	Function = "RetrieveEquippedLoadout", 
    	userId = game.Players.LocalPlayer.userId
    })
    
    if Type == "InvItems" then
        for Index, Item in next, Items do
            if typeof(Item) == "table" then
                table.insert(Inventory, Item)
            end
        end
    end
    if Type == "EquippedItems" then
        for Index, Item in next, EquippedItems do
            if typeof(Item) == "table" then
                table.insert(Inventory, Item)
            end
        end
    end
    
    return Inventory
end

CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(Child)
    if Child.Name == "ErrorPrompt" and Child:FindFirstChild("MessageArea") and Child.MessageArea:FindFirstChild("ErrorFrame") then
        TeleportService:Teleport("6998582502") --If the user gets kicked, send them back to the lobby
    end
end)

if ReplicatedFirst:FindFirstChild("IsLobby") then --In lobby

    --[[
    local InvItems = GetInventory("InvItems")

    for Index, Item in next, InvItems do
    end
    ]]
    warn(DungeonInfo)
    ReplicatedStorage.Core.CoreEvents.PartyEvents.Request:InvokeServer("Create", DungeonInfo)
    game:GetService("ReplicatedStorage").Core.CoreEvents.PartyEvents.Comm:FireServer("Start")
else --Not in lobby
    repeat task.wait() until game:IsLoaded()

    Player.Character.HumanoidRootPart.CFrame = workspace.DungeonConfig.Podium.Listener.CFrame
    repeat task.wait() until Player.PlayerGui.GUI.GameInfo.MobCount.Text ~= "Start Pending..."

    local CurStage = 1

    RunService.Stepped:Connect(function()
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.Velocity = Vector3.new(0, -1, 0)
        end
    end)

    local SpellsDebounce = false
    while task.wait() do
        local DefeatedAllMobs = true
        
        if workspace.Mobs:FindFirstChild("Stage" .. tostring(CurStage)) then
            for Index, Mob in next, workspace.Mobs:FindFirstChild("Stage" .. tostring(CurStage)):GetChildren() do
                if Mob.Name ~= "Diversion" and Mob:FindFirstChild("HumanoidRootPart") then
                    while Mob:FindFirstChild("HumanoidRootPart") do
                        Player.Character.HumanoidRootPart.CFrame = CFrame.lookAt(Mob.HumanoidRootPart.Position + Vector3.new(0, 1, 0), Mob.HumanoidRootPart.Position)
                        coroutine.wrap(function()
                            ReplicatedStorage.Core.CoreEvents.ClientServerNetwork.MagicFunction:InvokeServer("Q", "Spell")
                            ReplicatedStorage.Core.CoreEvents.ClientServerNetwork.MagicFunction:InvokeServer("E", "Spell")
                        end)()

                        task.wait()
                    end

                    DefeatedAllMobs = false
                end
            end
        end

        if Player.PlayerGui.EndGUI.Enabled then
            task.wait()
            ReplicatedStorage.Core.CoreEvents.PartyEvents.DungeonComm:FireServer("TeleportAlone")
            break
        end

        if DefeatedAllMobs then
            CurStage = CurStage + 1
        end
    end
end
