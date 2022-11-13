
repeat task.wait() until game:IsLoaded()

local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerNetwork = ReplicatedStorage.Core.CoreEvents.ClientServerNetwork.ServerNetwork
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")

repeat task.wait() until Player:FindFirstChild("leaderstats")

local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local function GetInventory(Type, ItemType)
    local Inventory = {}
    
    local Items = ServerNetwork:InvokeServer("DataFunctions", {
        Function = "RetrieveItems"
    })
    local EquippedItems = ServerNetwork:InvokeServer("DataFunctions", {
    	Function = "RetrieveEquippedLoadout", 
    	userId = game.Players.LocalPlayer.userId
    })
    
    --//Items are sorted like this 
    --AllItems = {
        --["Item"] = ActualItem
    --}
    if Type == "InvItems" then
        for Index, Item in next, Items do
            if typeof(Item) == "table" then
                for Name, ActualItem in next, Item do
                    ActualItem.FromArea = Index
                    ActualItem.Name = Name
                    ActualItem.Slot = Index--(#Items - Index) + 1

                    table.insert(Inventory, ActualItem)
                end
            end
        end
    end

    --//Items are sorted like this 
    --AllItems = {
        --["Legs"] = {AllItems}
        --["Armor"] = {AllItems}
    --}
    if Type == "EquippedItems" then
        for Index, ItemParent in next, EquippedItems do
            if typeof(ItemParent) == "table" then

                if ItemType == "All" then
                    for Index, ItemArea in next, ItemParent do
                        for CurIndex, ActualItem in next, ItemArea do --This should be all of the items, apart for armor items
                            if typeof(ActualItem) == "table" then

                                if ActualItem[AutoEquipBest.PreferedStat] then --If not armor item, insert into inventory
                                    ActualItem.FromArea = Index
                                    ActualItem.Name = CurIndex

                                    table.insert(Inventory, ActualItem)
                                else
                                    for Name, ActualItemForArmors in next, ActualItem do --If armor item, get the actual items
                                        if typeof(ActualItemForArmors) == "table" then
                                            ActualItemForArmors.Name = Name
                                            ActualItemForArmors.FromArea = Index

                                            table.insert(Inventory, ActualItemForArmors)
                                        end
                                    end
                                end

                            end
                        end 
                    end
                end

            end
        end
    end
    
    return Inventory
end

local function GetEquippedWeapon()
    local Inventory = GetInventory("EquippedItems", "All")

    for Index, Item in next, Inventory do
        if Item.FromArea == 1 and Item.MaxUpgrades then
            return Item
        end
    end
end

local function GetBestWeapon(InvItems)
    local Last = 0
    local BetterWeaponItem

    local EquippedWeapon = GetEquippedWeapon() or {
        [AutoEquipBest.PreferedStat] = 0
    }

    for Index, Item in next, InvItems do
        if Item[AutoEquipBest.PreferedStat] and Item[AutoEquipBest.PreferedStat] > Last and Item[AutoEquipBest.PreferedStat] > EquippedWeapon[AutoEquipBest.PreferedStat] then
            Last = Item[AutoEquipBest.PreferedStat]
            BetterWeaponItem = Item
        end
    end

    return BetterWeaponItem
end

CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(Child)
    if Child.Name == "ErrorPrompt" and Child:FindFirstChild("MessageArea") and Child.MessageArea:FindFirstChild("ErrorFrame") then
        TeleportService:Teleport("6998582502") --If the user gets kicked, send them back to the lobby
    end
end)

if ReplicatedFirst:FindFirstChild("IsLobby") then --In lobby

    local InvItems = GetInventory("InvItems")

    --EQUIP BEST WEAPON
    local BetterWeaponItem = GetBestWeapon(InvItems)

    if BetterWeaponItem then --If there is a better weapon, equip it
        ServerNetwork:InvokeServer("WeaponFunction", {
            Function = "EquipSlot",
            Slot = BetterWeaponItem.Slot
        })
    end

    ReplicatedStorage.Core.CoreEvents.PartyEvents.Request:InvokeServer("Create", DungeonInfo)
    ReplicatedStorage.Core.CoreEvents.PartyEvents.Comm:FireServer("Start")
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
                            if not SpellsDebounce then
                                SpellsDebounce = true
                                ReplicatedStorage.Core.CoreEvents.ClientServerNetwork.MagicFunction:InvokeServer("Q", "Spell")
                                ReplicatedStorage.Core.CoreEvents.ClientServerNetwork.MagicFunction:InvokeServer("E", "Spell")
                                task.wait(DungeonInfo.SpellSpamCooldown)
                                SpellsDebounce = false
                            end
                        end)()

                        task.wait()
                    end

                    DefeatedAllMobs = false
                end
            end
        end

        if Player.PlayerGui.EndGUI.Enabled then
            ReplicatedStorage.Core.CoreEvents.PartyEvents.DungeonComm:FireServer("TeleportAlone")
            break
        end

        if DefeatedAllMobs then
            CurStage = CurStage + 1
        end
    end
end
