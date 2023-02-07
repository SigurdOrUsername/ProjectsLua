print("server: 2.1.1")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientServerNetwork = ReplicatedStorage.Core.CoreEvents.ClientServerNetwork
local ServerNetwork = ClientServerNetwork.ServerNetwork
local HttpService = game:GetService("HttpService")
local Request = http_request or request or HttpPost or syn.request
local MarketplaceService = game:GetService("MarketplaceService")
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

local ReturnTable = {}

ReturnTable.ExploitEnv = getgenv()
ReturnTable.LobbyManager = {}
ReturnTable.InventoryManager = {}
ReturnTable.DungeonManager = {}
ReturnTable.DungeonManager.DodingManager = {}
ReturnTable.DungeonManager.DodingManager.SpesificDungeonEvents = {}

ReturnTable.ExploitEnv.FirstTimeSeeingStage = true

ReturnTable.LobbyManager.ReadWriteStorageFile = function()
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

    return StorageFile
end

ReturnTable.LobbyManager.ChildrenHasSameValues = function(Table, FirstValue)
    local LastMatched = Table[FirstValue]

    for Index, Value in next, Table do
        if Value ~= LastMatched then
            return false
        else
            LastMatched = Value
        end
    end
    
    return true, LastMatched
end

ReturnTable.LobbyManager.GetBestDungeonAndDifficulty = function()
    local AllLevelReqs = require(ReplicatedStorage.Core.CoreInfo.PartyLevels.RequiredLevels)
    local PlayerLevel = ServerNetwork:InvokeServer("DataFunctions", {
        Function = "RetrieveLevelFromPlayer",
        Player = Player
    })

    local BestDungeon
    local BestDifficulty
    local LastMatched = 0

    for Index, Dungeon in next, Player.PlayerGui.GUI.Party.CreateFrame.Dungeons:GetChildren() do
        if Dungeon:IsA("Frame") and Dungeon.Visible then
            local DungeonName = Dungeon:FindFirstChildWhichIsA("ImageButton")
            local LevelReqs = AllLevelReqs[DungeonName.Name]

            LevelReqs.Normal = nil
            LevelReqs.Hardcore = nil
            LevelReqs.Extreme = nil

            --Some dungeons have the same level for every difficulty
            local HasSameValues, LevelNeeded = ReturnTable.LobbyManager.ChildrenHasSameValues(LevelReqs, "Novice")
            if HasSameValues and LevelNeeded >= LastMatched and LevelNeeded <= PlayerLevel then
                LastMatched = LevelNeeded
                BestDifficulty = "Chaos"
                BestDungeon = DungeonName.Name
            end

            if not HasSameValues then
                for Difficulty, LevelNeeded in next, LevelReqs do
                    if LevelNeeded >= LastMatched and LevelNeeded <= PlayerLevel then
                        LastMatched = LevelNeeded
                        BestDifficulty = Difficulty
                        BestDungeon = DungeonName.Name
                    end
                end
            end
        end
    end

    return BestDungeon, BestDifficulty
end

ReturnTable.LobbyManager.AllUsersHaveJoined = function()
    for Index, Plr in next, ReturnTable.ExploitEnv.MultifarmInfo.Accounts do
        local PlrUser = Players:FindFirstChild(Plr)

        if not PlrUser then
            return false
        end
        if not Player.PlayerGui.GUI.Party.MyParty.Players:FindFirstChild(PlrUser.UserId) then
            return false
        end
    end

    return true
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

ReturnTable.InventoryManager.FormatNewItem = function(ActualItem, Name, Slot)
    local InfoTable = {}

    InfoTable.ItemStats = ActualItem
    InfoTable.ConstantItemInfo = ReturnTable.InventoryManager.GrabConstantItemInfo(Name)

    if Slot then
        InfoTable.ItemStats.Slot = Slot
    end
    if not InfoTable.ItemStats.Tier then --If item for some reason dosent have a tier, assign it it's default tier
        InfoTable.ItemStats.Tier = InfoTable.ConstantItemInfo.Tier
    end

    return InfoTable
end

ReturnTable.InventoryManager.GetInventory = function(Type)
    if Type == "InvItems" then
        local NewItems = {}
        local Items = ServerNetwork:InvokeServer("DataFunctions", {
            Function = "RetrieveItems"
        })

        for Slot, ItemParent in next, Items do
            if typeof(ItemParent) == "table" then
                for Name, ActualItem in next, ItemParent do
                    table.insert(NewItems, ReturnTable.InventoryManager.FormatNewItem(ActualItem, Name, Slot))
                end
            end
        end

        return NewItems
    end

    if Type == "EquippedItems" then
        local NewEquippedItems = {}
        local EquippedItems = ServerNetwork:InvokeServer("DataFunctions", {
            Function = "RetrieveEquippedLoadout",
            userId = Player.userId
        })

        for Index, ItemParent in next, EquippedItems do
            if typeof(ItemParent) == "table" then
    
                for Index, ItemArea in next, ItemParent do
                    for NonArmorName, NonArmorItem in next, ItemArea do --This should be all of the items, apart for armor items
                        if typeof(NonArmorItem) == "table" then

                            if NonArmorItem["Requirement"] then --If not armor item, insert into inventory
                                table.insert(NewEquippedItems, ReturnTable.InventoryManager.FormatNewItem(NonArmorItem, NonArmorName))
                            else
                                for ArmorName, ArmorItem in next, NonArmorItem do --If armor item, get the actual items
                                    if typeof(ArmorItem) == "table" then
                                        table.insert(NewEquippedItems, ReturnTable.InventoryManager.FormatNewItem(ArmorItem, ArmorName))
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
        if Item.ConstantItemInfo.type == "Weapon" then
            return Item
        end
    end
end

ReturnTable.InventoryManager.GetEquippedArmor = function()
    local EquippedArmor = {
        ["Legs"] = {ItemStats = {[ReturnTable.ExploitEnv.AutoEquipBest.PreferedStat] = 0}, ConstantItemInfo = {BodyPart = "Legs"}},
        ["Helmet"] = {ItemStats = {[ReturnTable.ExploitEnv.AutoEquipBest.PreferedStat] = 0}, ConstantItemInfo = {BodyPart = "Helmet"}},
        ["Armor"] = {ItemStats = {[ReturnTable.ExploitEnv.AutoEquipBest.PreferedStat] = 0}, ConstantItemInfo = {BodyPart = "Armor"}}
    }

    for Index, Item in next, ReturnTable.InventoryManager.GetInventory("EquippedItems") do
        if Item.ConstantItemInfo.BodyPart == "Legs" or Item.ConstantItemInfo.BodyPart == "Helmet" or Item.ConstantItemInfo.BodyPart == "Armor" then
            EquippedArmor[Item.ConstantItemInfo.BodyPart] = Item
        end
    end

    return EquippedArmor
end

ReturnTable.InventoryManager.GetEquippedJewelry = function()
    local EquippedJewelry = {}

    for Index, Item in next, ReturnTable.InventoryManager.GetInventory("EquippedItems") do
        if Item.ConstantItemInfo.type == "Jewelry" and Item.ItemStats[ReturnTable.ExploitEnv.AutoEquipBest.PreferedStat] then
            EquippedJewelry[#EquippedJewelry + 1] = Item
        end
    end

    --If there's less than 1 jewlery items equipped, add template items coresponding to the amount of items not equipped so code wont break
    if #EquippedJewelry == 0 then
        EquippedJewelry[1] = {ItemStats = {[ReturnTable.ExploitEnv.AutoEquipBest.PreferedStat] = 0}}
    end

    return EquippedJewelry
end

ReturnTable.InventoryManager.GetBestWeapon = function()
    local EquippedWeapon = ReturnTable.InventoryManager.GetEquippedWeapon() or {
        ItemStats = {[ReturnTable.ExploitEnv.AutoEquipBest.PreferedStat] = 0}
    }

    local LastMatched = 0
    local BetterWeaponItem

    for Index, Item in next, ReturnTable.InventoryManager.GetInventory("InvItems") do
        local ItemPreferedStat = Item.ItemStats[ReturnTable.ExploitEnv.AutoEquipBest.PreferedStat]

        if Item.ConstantItemInfo.type == "Weapon" and ItemPreferedStat and ItemPreferedStat > LastMatched and ItemPreferedStat > EquippedWeapon.ItemStats[ReturnTable.ExploitEnv.AutoEquipBest.PreferedStat] then
            LastMatched = ItemPreferedStat
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
    local LastMatched = {
        Legs = 0,
        Helmet = 0,
        Armor = 0
    }

    for Index, Item in next, ReturnTable.InventoryManager.GetInventory("InvItems") do
        if Item.ConstantItemInfo.BodyPart == "Legs" or Item.ConstantItemInfo.BodyPart == "Helmet" or Item.ConstantItemInfo.BodyPart == "Armor" then
            local ArmorType = Item.ConstantItemInfo.BodyPart
            local ArmorPreferedStat = Item.ItemStats[ReturnTable.ExploitEnv.AutoEquipBest.PreferedStat]

            if ArmorPreferedStat > LastMatched[ArmorType] then
                for Index, ArmorEquipped in next, EquippedArmor do
                    if ArmorType == ArmorEquipped.ConstantItemInfo.BodyPart and ArmorPreferedStat > ArmorEquipped.ItemStats[ReturnTable.ExploitEnv.AutoEquipBest.PreferedStat] then
                        LastMatched[ArmorType] = ArmorPreferedStat
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
    local LastMatched = 0

    for Index, Item in next, ReturnTable.InventoryManager.GetInventory("InvItems") do
        if Item.ConstantItemInfo.type == "Jewelry" then
            local JewleryPreferedStat = Item.ItemStats[ReturnTable.ExploitEnv.AutoEquipBest.PreferedStat]

            if JewleryPreferedStat and JewleryPreferedStat > LastMatched  then
                for Index, JewleryEquipped in next, EquippedJewelry do
                    if JewleryPreferedStat > JewleryEquipped.ItemStats[ReturnTable.ExploitEnv.AutoEquipBest.PreferedStat] then
                        JewelryToEquip = Item
                        LastMatched = JewleryPreferedStat
                    end
                end
            end

        end
    end

    return JewelryToEquip
end

ReturnTable.InventoryManager.HasTriplicatedSpell = function(Spell, ItemsToSell)
    local Inventory = ReturnTable.InventoryManager.GetInventory("InvItems", "Inv")
    local AmountSpellsFound = 0

    --First go through current items to sell
    for Index, Item in next, ItemsToSell do
        --Remove the items from our inventory that we are going to sell to "replicate" selling without actually having to sell the item
        for InvIndex, InvItem in next, Inventory do
            if Item.ConstantItemInfo.Name == InvItem.ConstantItemInfo.Name then
                Inventory[InvIndex] = nil
                break
            end
        end
    end

    --After removing items thats going to be selled, check if the spell is still triplicated
    for Index, Item in next, Inventory do
        if Item.ConstantItemInfo.type == "Spell" and Item.ConstantItemInfo.Name == Spell.ConstantItemInfo.Name then
            AmountSpellsFound = AmountSpellsFound + 1

            if AmountSpellsFound >= 4 then
                return true
            end
        end
    end

    return false
end

ReturnTable.InventoryManager.CanItemBeSold = function(Item, ItemsToSell)
    if table.find(ReturnTable.ExploitEnv.Autosell.RaritiesToKeep, Item.ItemStats.Tier) or table.find(ReturnTable.ExploitEnv.Autosell.ItemsToKeep, Item.ConstantItemInfo.Name) then
        return false
    end
    if ReturnTable.ExploitEnv.Autosell.KeepAllSpells and Item.ConstantItemInfo.type == "Spell" then
        return false
    end
    if ReturnTable.ExploitEnv.Autosell.SellTriplicatedSpells and Item.ConstantItemInfo.type == "Spell" then
        return ReturnTable.InventoryManager.HasTriplicatedSpell(Item, ItemsToSell)
    end
    if ReturnTable.ExploitEnv.Autosell.KeepAllJewelery and Item.ConstantItemInfo.type == "Jewelry" then
        return false
    end

    return true
end

ReturnTable.InventoryManager.GetItemsToSell = function()
    local ItemsToSell = {}

    for Index, Item in next, ReturnTable.InventoryManager.GetInventory("InvItems", "Inv") do
        if ReturnTable.InventoryManager.CanItemBeSold(Item, ItemsToSell) then
            print(Item.ConstantItemInfo.Name, Item.ItemStats.Tier, Item.ItemStats.Slot, ReturnTable.InventoryManager.CanItemBeSold(Item, ItemsToSell))
            table.insert(ItemsToSell, Item)
        end
    end

    return ItemsToSell
end

ReturnTable.DungeonManager.FireSpells = function()
    pcall(function()
        ClientServerNetwork.MagicFunction:InvokeServer("Q", "Spell")
        ClientServerNetwork.MagicFunction:InvokeServer("E", "Spell")
        ClientServerNetwork.MagicNetwork:FireServer("Swing", Vector3.new())
    end)
end

ReturnTable.DungeonManager.GetPrimaryPart = function(Mob)
    return Mob.PrimaryPart or Mob:FindFirstChild("HumanoidRootPart") or Mob:FindFirstChild("Hitbox")
end

ReturnTable.DungeonManager.WhitelistedMobParts = {
    "DisplayName",
    "Animate",
    "AnimSaves",
    "Rotate",
}

ReturnTable.DungeonManager.IsARealMob = function(Mob)
    for Index, Part in next, ReturnTable.DungeonManager.WhitelistedMobParts do
        if Mob:FindFirstChild(Part) then
            return true
        end
    end
end

ReturnTable.DungeonManager.GetAllMobsInStage = function(StageObject)
    local Mobs = {}

    for Index, Mob in next, StageObject:GetChildren() do
        if ReturnTable.DungeonManager.GetPrimaryPart(Mob) and ReturnTable.DungeonManager.IsARealMob(Mob) then
            table.insert(Mobs, Mob)
        end
    end

    return Mobs
end

ReturnTable.DungeonManager.GetAllMobsFromName = function(StageObject, Name)
    local SpesificMobs = {}

    for Index, Mob in next, ReturnTable.DungeonManager.GetAllMobsInStage(StageObject) do
        if Mob.Name == Name and ReturnTable.DungeonManager.GetPrimaryPart(Mob) then
            table.insert(SpesificMobs, Mob)
        end
    end

    return SpesificMobs
end

ReturnTable.DungeonManager.PrioritizedMob = {
    "Golem", "Eyeball"
}
ReturnTable.DungeonManager.IgnoreOffsetList = {
    "Source of the Unknown", "Protector of the Unknown", "Synthetic Noble Horseman"
}

ReturnTable.DungeonManager.HandleSpecialStage = {
    ["Dark Atlantis"] = {
        ["Stage4"] = function(StageObject)
            warn("handling stage 4")
            local GolemCount = 0

            for Index, Golem in next, ReturnTable.DungeonManager.GetAllMobsFromName(StageObject, "Golem") do
                if GolemCount == 2 then
                    return Mob
                end

                GolemCount = GolemCount + 1
            end

            return StageObject:FindFirstChildWhichIsA("Model")
        end
    }
}

ReturnTable.DungeonManager.OnNewStage = {
    ["Dark Atlantis"] = {
        ["Stage2"] = function(StageObject)
            local ToungeCrawlerCount = 0

            for Index, ToungeCrawler in next, ReturnTable.DungeonManager.GetAllMobsFromName(StageObject, "ToungeCrawler") do
                if ToungeCrawlerCount > 2 then
                    Player.Character.HumanoidRootPart.CFrame = CFrame.new(ReturnTable.DungeonManager.GetPrimaryPart(ToungeCrawler).Position + ReturnTable.DungeonManager.DodingManager.Offset)
                    task.wait(1.5)
                end

                ToungeCrawlerCount = ToungeCrawlerCount + 1
            end
        end,
        ["Stage4"] = function(StageObject)
            warn("first time seeing stage 4")
            local ToungeCrawlerCount = 0

            for Index, ToungeCrawler in next, ReturnTable.DungeonManager.GetAllMobsFromName(StageObject, "ToungeCrawler") do
                if ToungeCrawlerCount == 2 then
                    Player.Character.HumanoidRootPart.CFrame = CFrame.new(ReturnTable.DungeonManager.GetPrimaryPart(ToungeCrawler).Position + ReturnTable.DungeonManager.DodingManager.Offset)
                    task.wait(1)
                end

                ToungeCrawlerCount = ToungeCrawlerCount + 1
            end
        end,
        ["Stage7"] = function(StageObject)
            for Index, ToungeCrawler in next, ReturnTable.DungeonManager.GetAllMobsFromName(StageObject, "ToungeCrawler") do
                Player.Character.HumanoidRootPart.CFrame = CFrame.new(ReturnTable.DungeonManager.GetPrimaryPart(ToungeCrawler).Position + ReturnTable.DungeonManager.DodingManager.Offset)
                task.wait(1)
            end
        end
    },
}

ReturnTable.DungeonManager.ChangeOffset = function(Mob)
    if table.find(ReturnTable.DungeonManager.IgnoreOffsetList, Mob.Name) then
        return Vector3.new(0, -15, 0)
    end
    return Vector3.new(0, 50, 0)
end

ReturnTable.DungeonManager.GetBestMob = function(StageObject)
    if ReturnTable.DungeonManager.OnNewStage[GameName] and ReturnTable.ExploitEnv.FirstTimeSeeingStage and ReturnTable.DungeonManager.OnNewStage[GameName][StageObject.Name] then
        ReturnTable.ExploitEnv.FirstTimeSeeingStage = false
        ReturnTable.DungeonManager.OnNewStage[GameName][StageObject.Name](StageObject)
    end

    if ReturnTable.DungeonManager.HandleSpecialStage[GameName] and ReturnTable.DungeonManager.HandleSpecialStage[GameName][StageObject.Name] then
        return ReturnTable.DungeonManager.HandleSpecialStage[GameName][StageObject.Name](StageObject)
    end

    for Index, PrioritizedMob in next, ReturnTable.DungeonManager.PrioritizedMob do
        if StageObject:FindFirstChild(PrioritizedMob) then
            return StageObject:FindFirstChild(PrioritizedMob)
        end
    end

    for Index, Mob in next, ReturnTable.DungeonManager.GetAllMobsInStage(StageObject) do
        if ReturnTable.DungeonManager.GetPrimaryPart(Mob) then
            return Mob
        end
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
        Url = ReturnTable.ExploitEnv.Webhook.Url,
        Body = HttpService:JSONEncode(Data),
        Method = "POST",
        Headers = {
            ["content-type"] = "application/json"
        }
    })
end

--Doding
ReturnTable.DungeonManager.DodingManager.StopTeleporting = false
ReturnTable.DungeonManager.DodingManager.Offset = Vector3.new(0, 50, 0)

ReturnTable.DungeonManager.DodingManager.SpesificDungeonEvents.CoveSecondBossColor = function(FillObject)
    task.wait(10)

    ReturnTable.DungeonManager.DodingManager.StopTeleporting = true
    local ObjectToGoTo

    if FillObject.FillColor.R == 1 then
        ObjectToGoTo = workspace.Filter.Effects:WaitForChild("Red")
    end
    if FillObject.FillColor.G == 1 then
        ObjectToGoTo = workspace.Filter.Effects:WaitForChild("Green")
    end
    if FillObject.FillColor.B == 1 then
        ObjectToGoTo = workspace.Filter.Effects:WaitForChild("Blue")
    end

    if ObjectToGoTo then
        Player.Character.HumanoidRootPart.CFrame = ObjectToGoTo.Hitbox.CFrame
        task.wait(1)
    end
    ReturnTable.DungeonManager.DodingManager.StopTeleporting = false
end

return ReturnTable
