repeat task.wait() until game:IsLoaded()

local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerNetwork = ReplicatedStorage.Core.CoreEvents.ClientServerNetwork.ServerNetwork
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")

repeat task.wait() until Player:FindFirstChild("leaderstats")

local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local HttpService = game:GetService("HttpService")
local Request = http_request or request or HttpPost or syn.request

local function SendWebook(InfoTable)
    local Data = {
        embeds = {
            {
                title = InfoTable.Title,
                description = InfoTable.Description,
                fields = InfoTable.Feilds,
                color = tonumber(0x00ff00),
                footer = {
                    text = "Completed with a time of: " .. InfoTable.TimeCompleted
                }
            }
        }
    }

    Request({
        Url = Webhook.Url,
        Body = HttpService:JSONEncode(Data),
        Method = "POST",
        Headers = {
            ["content-type"] = "application/json"
        }
    })
end

local function GetInventory(Type, ItemType)
    local Inventory = {}
    
    local Items = ServerNetwork:InvokeServer("DataFunctions", {
        Function = "RetrieveItems"
    })
    local EquippedItems = ServerNetwork:InvokeServer("DataFunctions", {
    	Function = "RetrieveEquippedLoadout", 
    	userId = Player.userId
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
                    ActualItem.Slot = Index

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

local function GetEquippedArmor()
    local Inventory = GetInventory("EquippedItems", "All")
    local EquippedArmor = {
        ["Legs"] = {[AutoEquipBest.PreferedStat] = 0, FromArea = "Legs"},
        ["Helmet"] = {[AutoEquipBest.PreferedStat] = 0, FromArea = "Helmet"},
        ["Armor"] = {[AutoEquipBest.PreferedStat] = 0, FromArea = "Armor"}
    }

    for Index, Item in next, Inventory do
        if Item.FromArea == "Legs" or Item.FromArea == "Helmet" or Item.FromArea == "Armor" then
            EquippedArmor[Item.FromArea] = Item
        end
    end

    return EquippedArmor
end

local function GetBestWeapon(InvItems)
    local Last = 0
    local BetterWeaponItem

    local EquippedWeapon = GetEquippedWeapon() or {
        [AutoEquipBest.PreferedStat] = 0
    }

    for Index, Item in next, InvItems do
        local ItemPreferedStat = Item[AutoEquipBest.PreferedStat]

        if ItemPreferedStat and ItemPreferedStat > Last and ItemPreferedStat > EquippedWeapon[AutoEquipBest.PreferedStat] then
            Last = ItemPreferedStat
            BetterWeaponItem = Item
        end
    end

    return BetterWeaponItem
end

local function GetBestArmor(InvItems, WhichArmor)
    local EquippedArmor = GetEquippedArmor()
    local ArmorToEquip = {
        Legs,
        Helmet,
        Armor,
    }
    local Last = {
        Legs = 0,
        Helmet = 0,
        Armor = 0
    }

    for Index, Item in next, InvItems do
        if Item.Name:match("Legs") or Item.Name:match("Helmet") or Item.Name:match("Armor") then
            local ArmorType = Item.Name:match("Legs") and "Legs" or Item.Name:match("Helmet") and "Helmet" or Item.Name:match("Armor") and "Armor"

            for Index, ArmorEquipped in next, EquippedArmor do
                local ArmorPreferedStat = Item[AutoEquipBest.PreferedStat]

                if ArmorType == ArmorEquipped.FromArea and ArmorPreferedStat > Last[ArmorType] and ArmorPreferedStat > ArmorEquipped[AutoEquipBest.PreferedStat] then
                    Last[ArmorType] = ArmorPreferedStat
                    ArmorToEquip[ArmorType] = Item
                end
            end

        end
    end

    return ArmorToEquip[WhichArmor]
end

local function GetItemsToSell(InvItems)
    local ItemsToSell = {}

    for Index, Item in next, InvItems do
        if Item.Tier and not table.find(Autosell.RaritiesToKeep, Item.Tier) and not table.find(Autosell.ItemsToKeep, Item.Name) then
            table.insert(ItemsToSell, Item)
        end
    end

    return ItemsToSell
end

--Store how many runs you've done
local StorageFile
local HasStorageFile = pcall(function()
    readfile("StorageFile.txt")
end)

if not HasStorageFile then
    writefile("StorageFile.txt", "0")
    StorageFile = readfile("StorageFile.txt")
else
    StorageFile = readfile("StorageFile.txt")
end

CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(Child)
    --if Child.Name == "ErrorPrompt" and Child:FindFirstChild("MessageArea") and Child.MessageArea:FindFirstChild("ErrorFrame") then
    TeleportService:Teleport("6998582502") --If the user gets kicked, send them back to the lobby
    --end
end)

if ReplicatedFirst:FindFirstChild("IsLobby") then --In lobby
    if AutoEquipBest.DoAutoEquipBest then
        --//Equip better stuff
        local BetterWeaponItem = GetBestWeapon(GetInventory("InvItems"))

        --EQUIP BEST WEAPON
        if BetterWeaponItem then --If there is a better weapon, equip it
            ServerNetwork:InvokeServer("WeaponFunction", {
                Function = "EquipSlot",
                Slot = BetterWeaponItem.Slot
            })
        end

        --EQUIP BEST ARMOR
        for Index = 1, 3 do
            local ArmorToGet = Index == 1 and "Legs" or Index == 2 and "Helmet" or Index == 3 and "Armor"
            local BetterArmor = GetBestArmor(GetInventory("InvItems"), ArmorToGet)

            if BetterArmor then
                ServerNetwork:InvokeServer("WeaponFunction", {
                    Function = "EquipSlot",
                    Slot = BetterArmor.Slot
                })
            end
            task.wait(1)
        end
    end

    if Autosell.DoAutoSell then
        --//Autosell stuff
        local ToSell = GetItemsToSell(GetInventory("InvItems"))

        for Index, Item in next, ToSell do
            ServerNetwork:InvokeServer("ShopFunctions", {
                Function = "InsertItem",
                Slot = Item.Slot
            })
        end

        ServerNetwork:InvokeServer("ShopFunctions", {
            Function = "CompleteTransaction"
        })
    end

    ReplicatedStorage.Core.CoreEvents.PartyEvents.Request:InvokeServer("Create", DungeonInfo)
    task.wait(ExtraDungeonInfo.WaitTimeBeforeStartingDungeon)
    ReplicatedStorage.Core.CoreEvents.PartyEvents.Comm:FireServer("Start")
else --Not in lobby
    repeat task.wait() until game:IsLoaded()

    Player.Character.HumanoidRootPart.CFrame = workspace.DungeonConfig.Podium.Listener.CFrame
    repeat task.wait() until Player.PlayerGui.GUI.GameInfo.MobCount.Text ~= "Start Pending..."

    local CurStage = 1
    local OldInventory = GetInventory("InvItems") --//For checking when items get added

    RunService.Stepped:Connect(function()
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.Velocity = Vector3.new(0, -1, 0)
        end
    end)

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
            if Webhook.SendWebooks then
                local AllFeilds = {}
                local RawEquippedItems = ServerNetwork:InvokeServer("DataFunctions", {
                    Function = "RetrieveEquippedLoadout",
                    userId = Player.userId
                })

                for Index, GotItem in next, GetInventory("InvItems") do
                    if Index > #OldInventory then
                        table.insert(AllFeilds, {
                            name = GotItem.Name,
                            value = "```Tier: " .. tostring(GotItem.Tier) .. "\nMagic Damage: " .. tostring(GotItem.MagicDamage) .. "\nPhysical Damage: " .. tostring(GotItem.PhysicalDamage) .. "\nHealth: " .. tostring(GotItem.Health) .. "\nLvl Requirement: " .. tostring(GotItem.Requirement) .. "\nMax Upgrades: " .. tostring(GotItem.MaxUpgrades) .. "```",
                            inline = true
                        })
                    end
                end

                SendWebook({
                    Title = "Completed dungeon " .. DungeonInfo.PartyInfo.Dungeon .. " [" .. DungeonInfo.PartyInfo.Difficulty .. "]," .. " [Hardcore: " .. tostring(DungeonInfo.PartyInfo.Hardcore) .. "]," .. " [Extreme: " .. tostring(DungeonInfo.PartyInfo.Extreme) .. "]",
                    Description = "Player: ``" .. Player.Name .. "``\nLvl: ``" .. tostring(RawEquippedItems.Level) .. "``" .. "\nCurrent run times: ``" .. StorageFile .. "``",
                    Feilds = AllFeilds,
                    TimeCompleted = Player.PlayerGui.GUI.Top.Timer.Text .. ", \nUser local time: " .. os.date()
                })
            end

            writefile("StorageFile.txt", tostring(tonumber(StorageFile) + 1))
            task.wait(ExtraDungeonInfo.WaitTimeBeforeLeavingDungeon)

            if ExtraDungeonInfo.RepeatDungeon then
                ReplicatedStorage.Core.CoreEvents.PartyEvents.DungeonRequest:InvokeServer(TeleportPartyDungeon)
            else
                ReplicatedStorage.Core.CoreEvents.PartyEvents.DungeonComm:FireServer("TeleportAlone")
            end
            break
        end

        if DefeatedAllMobs then
            CurStage = CurStage + 1
        end
    end
end
