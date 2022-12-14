print("ver 1.0.0")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerNetwork = ReplicatedStorage.Core.CoreEvents.ClientServerNetwork.ServerNetwork
local HttpService = game:GetService("HttpService")
local Request = http_request or request or HttpPost or syn.request

local ReturnTable = {}

ReturnTable.ExploitEnv = getgenv()

ReturnTable.LobbyManager = {}
ReturnTable.InventoryManager = {}
ReturnTable.DungeonManager = {}

ReturnTable.LobbyManager.AllUsersHaveJoined = function()
    local AllHasJoined = true

    for Index, Plr in next, Utilities.ExploitEnv.MultifarmInfo.Accounts do
        local PlrUser = Players:FindFirstChild(Plr)

        if not PlrUser then
            return false
        end
        if not Player.PlayerGui.GUI.Party.MyParty.Players:FindFirstChild(PlrUser.UserId) then
            return false
        end
    end

    return AllHasJoined
end

local AllItems = {}
local Items = ReplicatedStorage.Core.CoreInfo.Items
for Index, ItemInfo in next, require(Items.Items) do
    AllItems[Index] = ItemInfo
end
for Index, ItemInfo in next, require(Items.Spells) do
    AllItems[Index] = ItemInfo
end
for Index, ItemInfo in next, require(Items.Jewelry) do
    AllItems[Index] = ItemInfo
end
for Index, ItemInfo in next, require(Items.Books) do
    AllItems[Index] = ItemInfo
end

ReturnTable.InventoryManager.GrabConstantItemInfo = function(Name)
    return AllItems[Name]
end

ReturnTable.InventoryManager.GetInventory = function(Type)
    if Type == "InvItems" then
        local Items = ServerNetwork:InvokeServer("DataFunctions", {
            Function = "RetrieveItems"
        })

        local NewItems = {}

        for Index, ItemParent in next, Items do
            if typeof(ItemParent) == "table" then
                for Name, ActualItem in next, ItemParent do
                    local InfoTable = {}

                    InfoTable.ItemStats = ActualItem
                    InfoTable.FullItemInfo = ReturnTable.InventoryManager.GrabConstantItemInfo(Name)
                    InfoTable.ItemStats.Slot = Index

                    if not InfoTable.ItemStats.Tier then
                        InfoTable.ItemStats.Tier = InfoTable.FullItemInfo.Tier
                    end

                    table.insert(NewItems, InfoTable)
                end
            end
        end
        return NewItems
    end

    if Type == "EquippedItems" then
        local EquippedItems = ServerNetwork:InvokeServer("DataFunctions", {
            Function = "RetrieveEquippedLoadout",
            userId = Player.userId
        })

        local NewEquippedItems = {}

        for Index, ItemParent in next, EquippedItems do
            if typeof(ItemParent) == "table" then
    
                for Index, ItemArea in next, ItemParent do
                    for NonArmorName, NonArmorItem in next, ItemArea do --This should be all of the items, apart for armor items
                        if typeof(NonArmorItem) == "table" then

                            if NonArmorItem["Requirement"] then --If not armor item, insert into inventory
                                local InfoTable = {}

                                InfoTable.ItemStats = NonArmorItem
                                InfoTable.FullItemInfo = ReturnTable.InventoryManager.GrabConstantItemInfo(NonArmorName)

                                if not InfoTable.ItemStats.Tier then --If item for some reason dosent have a tier, assign it it's default tier
                                    InfoTable.ItemStats.Tier = InfoTable.FullItemInfo.Tier
                                end

                                table.insert(NewEquippedItems, InfoTable)
                            else
                                for ArmorName, ArmorItem in next, NonArmorItem do --If armor item, get the actual items
                                    if typeof(ArmorItem) == "table" then
                                        local InfoTable = {}

                                        InfoTable.ItemStats = ArmorItem
                                        InfoTable.FullItemInfo = ReturnTable.InventoryManager.GrabConstantItemInfo(ArmorName)

                                        if not InfoTable.ItemStats.Tier then --If item for some reason dosent have a tier, assign it it's default tier
                                            InfoTable.ItemStats.Tier = InfoTable.FullItemInfo.Tier
                                        end

                                        table.insert(NewEquippedItems, InfoTable)
                                    end
                                end
                            end

                        end
                    end 
                end

            end
        end

        return NewEquippedItems
    end
end

ReturnTable.InventoryManager.GetEquippedWeapon = function()
    for Index, Item in next, ReturnTable.InventoryManager.GetInventory("EquippedItems") do
        if Item.FullItemInfo.type == "Weapon" then
            return Item
        end
    end
end

ReturnTable.InventoryManager.GetEquippedArmor = function()
    local EquippedArmor = {
        ["Legs"] = {ItemStats = {[AutoEquipBest.PreferedStat] = 0}, FullItemInfo = {BodyPart = "Legs"}},
        ["Helmet"] = {ItemStats = {[AutoEquipBest.PreferedStat] = 0}, FullItemInfo = {BodyPart = "Helmet"}},
        ["Armor"] = {ItemStats = {[AutoEquipBest.PreferedStat] = 0}, FullItemInfo = {BodyPart = "Armor"}}
    }

    for Index, Item in next, ReturnTable.InventoryManager.GetInventory("EquippedItems") do
        if Item.FullItemInfo.BodyPart == "Legs" or Item.FullItemInfo.BodyPart == "Helmet" or Item.FullItemInfo.BodyPart == "Armor" then
            EquippedArmor[Item.FullItemInfo.BodyPart] = Item
        end
    end

    return EquippedArmor
end

ReturnTable.InventoryManager.GetEquippedJewelry = function()
    local EquippedJewelry = {}

    for Index, Item in next, ReturnTable.InventoryManager.GetInventory("EquippedItems") do
        if Item.FullItemInfo.type == "Jewelry" and Item.ItemStats[AutoEquipBest.PreferedStat] then
            EquippedJewelry[#EquippedJewelry + 1] = Item
        end
    end

    --If there's less than 1 jewlery items equipped, add template items coresponding to the amount of items not equipped so code wont break
    if #EquippedJewelry == 0 then
        EquippedJewelry[1] = {ItemStats = {[AutoEquipBest.PreferedStat] = 0}}
    end

    return EquippedJewelry
end

ReturnTable.InventoryManager.GetBestWeapon = function()
    local Last = 0
    local BetterWeaponItem

    local EquippedWeapon = ReturnTable.InventoryManager.GetEquippedWeapon() or {
        ItemStats = {[AutoEquipBest.PreferedStat] = 0}
    }

    for Index, Item in next, ReturnTable.InventoryManager.GetInventory("InvItems") do
        local ItemPreferedStat = Item.ItemStats[AutoEquipBest.PreferedStat]

        if Item.FullItemInfo.type == "Weapon" and ItemPreferedStat and ItemPreferedStat > Last and ItemPreferedStat > EquippedWeapon.ItemStats[AutoEquipBest.PreferedStat] then
            Last = ItemPreferedStat
            BetterWeaponItem = Item
        end
    end

    return BetterWeaponItem
end

ReturnTable.InventoryManager.GetBestArmor = function(WhichArmor)
    local EquippedArmor = ReturnTable.InventoryManager.GetEquippedArmor()
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

    for Index, Item in next, ReturnTable.InventoryManager.GetInventory("InvItems") do
        if Item.FullItemInfo.BodyPart == "Legs" or Item.FullItemInfo.BodyPart == "Helmet" or Item.FullItemInfo.BodyPart == "Armor" then
            local ArmorType = Item.FullItemInfo.BodyPart
            local ArmorPreferedStat = Item.ItemStats[AutoEquipBest.PreferedStat]

            if ArmorPreferedStat > Last[ArmorType] then
                for Index, ArmorEquipped in next, EquippedArmor do
                    if ArmorType == ArmorEquipped.FullItemInfo.BodyPart and ArmorPreferedStat > ArmorEquipped.ItemStats[AutoEquipBest.PreferedStat] then
                        Last[ArmorType] = ArmorPreferedStat
                        ArmorToEquip[ArmorType] = Item
                    end
                end
            end

        end
    end

    return ArmorToEquip[WhichArmor]
end

ReturnTable.InventoryManager.GetBestJewelry = function(WhichJewelry)
    local EquippedJewelry = ReturnTable.InventoryManager.GetEquippedJewelry()
    local JewelryToEquip
    local Last = 0

    for Index, Item in next, ReturnTable.InventoryManager.GetInventory("InvItems") do
        if Item.FullItemInfo.type == "Jewelry" then
            local JewleryPreferedStat = Item.ItemStats[AutoEquipBest.PreferedStat]

            if JewleryPreferedStat and JewleryPreferedStat > Last  then
                for Index, JewleryEquipped in next, EquippedJewelry do
                    if JewleryPreferedStat > JewleryEquipped.ItemStats[AutoEquipBest.PreferedStat] then
                        JewelryToEquip = Item
                        Last = JewleryPreferedStat
                    end
                end
            end

        end
    end

    return JewelryToEquip
end

ReturnTable.InventoryManager.CanItemBeSold = function(Item)
    local ReturnValue = true

    if table.find(Utilities.ExploitEnv.Autosell.RaritiesToKeep, Item.ItemStats.Tier) or table.find(Utilities.ExploitEnv.Autosell.ItemsToKeep, Item.FullItemInfo.Name) then
        return false
    end
    if Utilities.ExploitEnv.Autosell.KeepAllSpells and Item.FullItemInfo.type == "Spell" then
        return false
    end
    if Utilities.ExploitEnv.Autosell.KeepAllJewelery and Item.FullItemInfo.type == "Jewelry" then
        return false
    end

    return ReturnValue
end

ReturnTable.InventoryManager.GetItemsToSell = function()
    local ItemsToSell = {}

    for Index, Item in next, ReturnTable.InventoryManager.GetInventory("InvItems", "Inv") do
        if ReturnTable.InventoryManager.CanItemBeSold(Item) then
            print(Item.FullItemInfo.Name, Item.ItemStats.Tier, Item.ItemStats.Slot, ReturnTable.InventoryManager.CanItemBeSold(Item))
            table.insert(ItemsToSell, Item)
        end
    end

    return ItemsToSell
end

ReturnTable.DungeonManager.FireSpells = function()
    pcall(function()
        ServerNetwork.Parent.MagicFunction:InvokeServer("Q", "Spell")
        ServerNetwork.Parent.MagicFunction:InvokeServer("E", "Spell")
    end)
end

ReturnTable.DungeonManager.DestroyIfSpellCooldown = function(Child)
    if Child.Name == "Q" or Child.Name == "E" then
        task.wait()
        Child:Destroy()
    end
end

ReturnTable.DungeonManager.SendWebook = function(InfoTable)
    local Data = {
        content = InfoTable.Content,
        embeds = {
            {
                title = InfoTable.Title,
                description = InfoTable.Description,
                fields = InfoTable.Feilds,
                color = tonumber(0x00ff00),
                footer = {
                    text = InfoTable.FooterText
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

return ReturnTable
