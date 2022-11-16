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
        content = InfoTable.Content,

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
        local IsValidItem = Item.MaxUpgrades

        if IsValidItem and ItemPreferedStat and ItemPreferedStat > Last and ItemPreferedStat > EquippedWeapon[AutoEquipBest.PreferedStat] then
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

local PrioritizeKillingMobsFirst = {
    "Spearman"
}

local function GrabMob(CurStage)
    local Last = math.huge
    local ReturnMob

    for Index, Mob in next, workspace.Mobs:FindFirstChild("Stage" .. tostring(CurStage)):GetChildren() do
        if Mob.Name ~= "Diversion" and Mob:FindFirstChild("HumanoidRootPart") then
            if table.find(PrioritizeKillingMobsFirst, Mob.Name) then
                return Mob
            end

            if (Mob.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).Magnitude < Last then
                ReturnMob = Mob
                Last = (Mob.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).Magnitude
            end
        end
    end

    return ReturnMob
end

local function GetTouchingParts(Part)
    return workspace:GetPartsInPart(Part, OverlapParams.new({
        MaxParts = math.huge, 
        RespectCanCollide = false,
        FilterType = Enum.RaycastFilterType.Blacklist,
        FilterDescendantsInstances = {
            workspace.Mobs,
            workspace.Filter.Map,
            Player.Character,
        }
    }))
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

CoreGui.RobloxPromptGui.promptOverlay.DescendantAdded:Connect(function(Child)
    TeleportService:Teleport("6998582502") --If the user gets kicked, send them back to the lobby
    task.wait(9e9)
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

    task.wait(ExtraDungeonInfo.WaitTimeBeforeStartingDungeon)
    ReplicatedStorage.Core.CoreEvents.PartyEvents.Request:InvokeServer("Create", DungeonInfo)
    ReplicatedStorage.Core.CoreEvents.PartyEvents.Comm:FireServer("Start")
else --Not in lobby
    repeat task.wait() until game:IsLoaded()
    repeat Player.Character.HumanoidRootPart.CFrame = workspace.DungeonConfig.Podium.Listener.CFrame task.wait() until Player.PlayerGui.GUI.GameInfo.MobCount.Text ~= "Start Pending..."

    local CurStage = 1
    local OldInventory = GetInventory("InvItems") --//For checking when items get added
    local TimeAtStartOfDungeon = os.time()
    local InputHandler = getsenv(Player.PlayerScripts.Main.main.Core.InputHandler) --For firing spells

    RunService.Stepped:Connect(function()
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.Velocity = Vector3.new(0, -1, 0)
        end
    end)

    --Init doding stuff

    local Root
    local ConstantSpace = 4

    --Makes a grid around "root", so we can use it to find safe positions around the mobs
    local Parts = {}
    for X = -4.5, 4.5 do
        for Z = -4.5, 4.5 do
            local Part = Instance.new("Part", workspace)

            Part.Name = "AutofarmPart"
            Part.Transparency = 0.5
            Part.Anchored = true
            Part.CanCollide = false
            Part.Size = Vector3.new(Player.Character.HumanoidRootPart.Size.X, 15, Player.Character.HumanoidRootPart.Size.Z)

            coroutine.wrap(function()
                while task.wait() do
                    if Part then
                        if Root then
                            Part.CFrame = CFrame.new(Root.Position + Vector3.new(X * ConstantSpace, 0, Z * ConstantSpace))
                        end
                    else
                        break
                    end
                end
            end)()

            table.insert(Parts, Part)
        end
    end

    local function CheckIfSafe(Part)
        local IsSafe = true

        for Index, TouchingPart in next, GetTouchingParts(Part) do
            if TouchingPart.Name ~= "AutofarmPart" and TouchingPart.Transparency ~= 1 and (workspace:FindFirstChild(TouchingPart.Name) or TouchingPart:IsDescendantOf(workspace.Filter.Effects)) then
                IsSafe = false
            end
        end

        return IsSafe
    end

    local function GetSafePosition(ClosestOrFarthest)
        local OldMagnitude = ClosestOrFarthest == "Closest" and math.huge or 0
        local ReturnPart

        for Index, Part in next, Parts do
            if (ClosestOrFarthest == "Closest" and (Part.Position - Root.Position).Magnitude < OldMagnitude) or (ClosestOrFarthest ~= "Closest" and (Part.Position - Root.Position).Magnitude > OldMagnitude) then
                local IsPartSafe = CheckIfSafe(Part)

                if IsPartSafe then
                    ReturnPart = Part
                    OldMagnitude = (Part.Position - Root.Position).Magnitude
                end
            end
        end

        return ReturnPart
    end

    while task.wait() do
        local DefeatedAllMobs = true

        --Actually murdering the mods + doding
        if workspace.Mobs:FindFirstChild("Stage" .. tostring(CurStage)) then
            local Mob = GrabMob(CurStage)

            if Mob then
                Root = Mob.HumanoidRootPart
                while Mob:FindFirstChild("HumanoidRootPart") do
                    local SafePos = GetSafePosition("Closest")

                    if SafePos and Player.Character:FindFirstChild("HumanoidRootPart") then
                        Player.Character.HumanoidRootPart.CFrame = CFrame.lookAt(SafePos.Position, Root.Position + Vector3.new(0, 1, 0))
                        ReplicatedStorage.Core.CoreEvents.ClientServerNetwork.MagicNetwork:FireServer("Swing", Root.Position)
                    end
                    if not Player.PlayerGui.GUI.HUD.Q:FindFirstChild("cdTemplate") or not Player.PlayerGui.GUI.HUD.E:FindFirstChild("cdTemplate") then
                        InputHandler.ActivateE()
                        InputHandler.ActivateQ()
                    end

                    task.wait()
                end

                DefeatedAllMobs = false
            end
        end

        if DefeatedAllMobs then
            CurStage = CurStage + 1
        end




        --Webhook stuff
        if Player.PlayerGui.EndGUI.Enabled then
            if Webhook.SendWebooks then
                local AllFeilds = {}
                local PingContent = ""

                local RawEquippedItems = ServerNetwork:InvokeServer("DataFunctions", {
                    Function = "RetrieveEquippedLoadout",
                    userId = Player.userId
                })

                for Index, GotItem in next, GetInventory("InvItems") do
                    if Index > #OldInventory then

                        if table.find(Webhook.PingForRarity, GotItem.Tier) then
                            PingContent = "<@" .. Webhook.UserId .. ">"
                        end

                        table.insert(AllFeilds, {
                            name = GotItem.Name,
                            value = "```Tier: " .. tostring(GotItem.Tier) .. "\nMagic Damage: " .. tostring(GotItem.MagicDamage) .. "\nPhysical Damage: " .. tostring(GotItem.PhysicalDamage) .. "\nHealth: " .. tostring(GotItem.Health) .. "\nLvl Requirement: " .. tostring(GotItem.Requirement) .. "\nMax Upgrades: " .. tostring(GotItem.MaxUpgrades) .. "```",
                            inline = true
                        })
                    end
                end

                SendWebook({
                    Title = "Completed dungeon " .. DungeonInfo.PartyInfo.Dungeon .. " [" .. DungeonInfo.PartyInfo.Difficulty .. "]," .. " [Hardcore: " .. tostring(DungeonInfo.PartyInfo.Hardcore) .. "]," .. " [Extreme: " .. tostring(DungeonInfo.PartyInfo.Extreme) .. "]",
                    Description = "Player: ``" .. Player.Name .. "``\nLvl: ``" .. tostring(RawEquippedItems.Level) .. "``" .. "\nAmount of runs finished: ``" .. StorageFile .. "``",
                    Content = PingContent,
                    Feilds = AllFeilds,
                    TimeCompleted = Player.PlayerGui.GUI.Top.Timer.Text .. " (Took " .. os.time() - TimeAtStartOfDungeon .. " sec), \nUser local time: " .. os.date()
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
    end
end
