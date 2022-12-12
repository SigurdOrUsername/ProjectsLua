getgenv().AutoEquipBest = {
    DoAutoEquipBest = true, --Auto equips [Armor, Weapon, Jewelry]
    PreferedStat = "MagicDamage" --//[PhysicalDamage, MagicDamage, Health]
}

getgenv().Autosell = {
    DoAutoSell = true,

    KeepAllSpells = true, --//Wont sell any spells if true [This keeps all spells, regardless of name and rarity]
    KeepAllJewelery = false, --//Wont sell any jewelry if true [This keeps all jewelry, regardless of name and rarity]

    RaritiesToKeep = {
        "Mythic",
        "Legendary",
        --"Epic",
        --"Rare",
        --"Uncommon",
        --"Common"
    },
    ItemsToKeep = {

    }
}

getgenv().ExtraDungeonInfo = {
    RepeatDungeon = false, --//THIS ONLY WORKS IF YOU HAVE THE GAMEPASS

    --These functions exist so that the roblox error code 286 whatever thingy is minigated (if you sever hop too much, you might get soft ip-banned from roblox for a couple of hours)

    WaitTimeBeforeStartingDungeon = 80, --//If you want delay before the dungeon stats
    WaitTimeBeforeLeavingDungeon = 80, --//If you want delay before leaving the dungeon

    --For offsets when autofarming
    Cords = {
        X = 0,
        Y = 1,
        Z = 0,
    }
}

getgenv().DungeonInfo = {
    PartyInfo = {
		Difficulty = "Chaos", --//Difficult level [Novice [1-5], Advanced [5-10], Chaos [10 - inf]] / Auto
		Hardcore = false, --//Need to be lvl 11
		Extreme = true,--//Need to be lvl 12
		Private = false,
		Dungeon = "Jungle" --//Dungeon name / Auto
	}
}

getgenv().MultifarmInfo = {
    DoMultiFarm = true,

    Host = "Wanwood1960907364092",
    Accounts = {
        "TestingTesting12052",
    }
}

getgenv().Webhook = {
    SendWebooks = true,
    Url = "https://discord.com/api/webhooks/1041480610172116993/fl_-PsEkaikn31sO_3od7KCC6D0JN6ptXH5k06dei0n7wQMY5sjvdglVIkNHgYU0i-5C",

    UserId = "everyone", --Which person it will ping. UserId/everyone/here/Whatnot
    PingForRarity = { --Will send you a ping if any of these rarities are dropped
        "Mythic",
        "Legendary",
        --"Epic",
        --"Rare",
        --"Uncommon",
        --"Common"
    }
}

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerNetwork = ReplicatedStorage.Core.CoreEvents.ClientServerNetwork.ServerNetwork
local PartyEvents = ReplicatedStorage.Core.CoreEvents.PartyEvents
local ReplicatedFirst = game:GetService("ReplicatedFirst")

repeat task.wait() until Player:FindFirstChild("leaderstats")

local UserService = game:GetService("UserService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Request = http_request or request or HttpPost or syn.request

local Utilities = loadstring(game:HttpGet("https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/DungeonCrusaders/SpellSpamFarm/Utilities.lua"))()

local LobbyManager = Utilities.LobbyManager
local InventoryManager = Utilities.InventoryManager
local DungeonManager = Utilities.DungeonManager

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

--If the user gets kicked, send them back to the lobby
CoreGui.RobloxPromptGui.promptOverlay.DescendantAdded:Connect(function(Child)
    TeleportService:Teleport("6998582502")
end)

if ReplicatedFirst:FindFirstChild("IsLobby") then --In lobby
    --//Equip better stuff
    if getgenv().AutoEquipBest.DoAutoEquipBest then
        --EQUIP BEST WEAPON
        local BetterWeaponItem = InventoryManager.GetBestWeapon()

        if BetterWeaponItem then
            ServerNetwork:InvokeServer("WeaponFunction", {
                Function = "EquipSlot",
                Slot = BetterWeaponItem.ItemStats.Slot
            })
        end

        --EQUIP BEST ARMOR
        for Index = 1, 3 do
            local ArmorToGet = Index == 1 and "Legs" or Index == 2 and "Helmet" or Index == 3 and "Armor"
            local BetterArmor = InventoryManager.GetBestArmor(ArmorToGet)

            if BetterArmor then
                ServerNetwork:InvokeServer("WeaponFunction", {
                    Function = "EquipSlot",
                    Slot = BetterArmor.ItemStats.Slot
                })
            end
        end

        --EQUIP BEST JEWELRY
        local BetterJewelry = InventoryManager.GetBestJewelry()

        if BetterJewelry then
            ServerNetwork:InvokeServer("WeaponFunction", {
                Function = "EquipSlot",
                Slot = BetterJewelry.ItemStats.Slot
            })
        end
    end
    
    --//Autosell stuff
    if getgenv().Autosell.DoAutoSell then
        for Index, Item in next, InventoryManager.GetItemsToSell() do
            ServerNetwork:InvokeServer("ShopFunctions", {
                Function = "InsertItem",
                Slot = Item.ItemStats.Slot
            })
        end

        ServerNetwork:InvokeServer("ShopFunctions", {
            Function = "CompleteTransaction"
        })
    end

    if getgenv().ExtraDungeonInfo.WaitTimeBeforeStartingDungeon > 0 then
        task.wait(math.random(getgenv().ExtraDungeonInfo.WaitTimeBeforeStartingDungeon/2, getgenv().ExtraDungeonInfo.WaitTimeBeforeStartingDungeon))
    end

    --//Multi farm
    if getgenv().MultifarmInfo.DoMultiFarm then
        if Player.Name == getgenv().MultifarmInfo.Host then
            PartyEvents.Request:InvokeServer("Create", getgenv().DungeonInfo)

            repeat
                for Index, Plr in next, getgenv().MultifarmInfo.Accounts do
                    local PlrUser = Players:FindFirstChild(Plr)

                    if PlrUser then
                        PartyEvents.Comm:FireServer("Invite", PlrUser)
                    end
                end
                task.wait(5)
            until LobbyManager.AllUsersHaveJoined()
        else
            --This will fire when you get an invitation to a dungeon in the lobby
            Player.PlayerGui.GUI.InviteFrame:GetPropertyChangedSignal("Visible"):Connect(function()
                PartyEvents.Request:InvokeServer("Join", {
                    Host = Players:FindFirstChild(getgenv().MultifarmInfo.Host).UserId
                })
            end)
        end

        --Remove any other people from the party who arent supposed to be there
        for Index, Teammate in next, Player.PlayerGui.GUI.Party.MyParty.Players:GetChildren() do
            if Teammate:FindFirstChild("Level") then
                local UsernameFromUserId = UserService:GetUserInfosByUserIdsAsync({tonumber(Teammate.Name)})[1].Username

                if getgenv().MultifarmInfo.Host ~= UsernameFromUserId and not table.find(getgenv().MultifarmInfo.Accounts, UsernameFromUserId) then
                    warn(UsernameFromUserId)
                    PartyEvents.Comm:FireServer("Kick", Players:FindFirstChild(UsernameFromUserId))
                end
            end
        end
    else
        PartyEvents.Request:InvokeServer("Create", getgenv().DungeonInfo)
    end

    PartyEvents.Comm:FireServer("Start")
else --Not in lobby
    repeat task.wait() until game:IsLoaded()
    repeat Player.Character.HumanoidRootPart.CFrame = workspace.DungeonConfig.Podium.Listener.CFrame task.wait() until Player.PlayerGui.GUI.GameInfo.MobCount.Text ~= "Start Pending..."

    Player.Character.Info:Destroy() --God mode
    local OldInventory = InventoryManager.GetInventory("InvItems") --//For checking when items get added
    local TimeAtStartOfDungeon = os.time()

    --//Spell spam bypass
    Player.Character.ChildAdded:Connect(function(Child)
        DungeonManager.DestroyIfSpellCooldown(Child)
    end)
    Player.CharacterAdded:Connect(function(Char)
        Player.Character:WaitForChild("Info"):Destroy()
        Char.ChildAdded:Connect(function(Child)
            DungeonManager.DestroyIfSpellCooldown(Child)
        end)
    end)

    --//Anti lag
    workspace.Filter.Effects.ChildAdded:Connect(function(Child) --Mob spells / some player spells
        task.wait()
        Child:Destroy()
    end)
    workspace.ChildAdded:Connect(function(Child) --Plr spells
        if Child.Name ~= Player.Name then
            task.wait()
            Child:Destroy()
        end
    end)

    --//Handling leaving in multi farm
    if getgenv().MultifarmInfo.DoMultiFarm then
        --This will fire when you get an invitation in the dungeon
        Player.PlayerGui.GUI.InviteFrame:GetPropertyChangedSignal("Visible"):Connect(function()
            PartyEvents.DungeonComm:FireServer("JoinDungeonParty")
        end)
    end

    local CurStage = 1
    local HasWaited = false
    while task.wait() do
        local KilledAllMobs = true

        --If at last stage, wait if the user specified it
        if not workspace.Mobs:FindFirstChild("Stage" .. tostring(CurStage + 1)) and not HasWaited then
            HasWaited = true

            if getgenv().ExtraDungeonInfo.WaitTimeBeforeLeavingDungeon > 0 then
                task.wait(math.random(getgenv().ExtraDungeonInfo.WaitTimeBeforeLeavingDungeon/2, getgenv().ExtraDungeonInfo.WaitTimeBeforeLeavingDungeon))
            end
        end

        --Actually murdering the mods
        if Player.Character:FindFirstChild("HumanoidRootPart") and workspace.Mobs:FindFirstChild("Stage" .. tostring(CurStage)) then
            for Index, Mob in next, workspace.Mobs:FindFirstChild("Stage" .. tostring(CurStage)):GetChildren() do
                if Mob.Name ~= "Diversion" and Mob:FindFirstChild("HumanoidRootPart") and Mob:FindFirstChild("DisplayName") or Mob:FindFirstChild("Animate") then

                    while Mob:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("HumanoidRootPart") do
                        Player.Character.HumanoidRootPart.CFrame = CFrame.lookAt(Mob.HumanoidRootPart.Position + Vector3.new(getgenv().ExtraDungeonInfo.Cords.X, getgenv().ExtraDungeonInfo.Cords.Y, getgenv().ExtraDungeonInfo.Cords.Z), Mob.HumanoidRootPart.Position)
                        coroutine.wrap(DungeonManager.FireSpells)()
                        task.wait()
                    end

                    KilledAllMobs = false
                end
            end

            if KilledAllMobs then
                CurStage = CurStage + 1
            end
        end

        if Player.PlayerGui.EndGUI.Enabled then
            --Webhook stuff
            if getgenv().Webhook.SendWebooks then
                local AllFeilds = {}
                local PingContent = ""

                local RawEquippedItems = ServerNetwork:InvokeServer("DataFunctions", {
                    Function = "RetrieveEquippedLoadout",
                    userId = Player.userId
                })

                for Index, GotItem in next, InventoryManager.GetInventory("InvItems") do
                    if Index > #OldInventory then

                        if table.find(getgenv().Webhook.PingForRarity, GotItem.ItemStats.Tier) then
                            PingContent = "<@" .. getgenv().Webhook.UserId .. ">"
                        end

                        table.insert(AllFeilds, {
                            name = GotItem.FullItemInfo.Name,
                            value = "```Tier: " .. tostring(GotItem.ItemStats.Tier) .. "\nMagic Damage: " .. tostring(GotItem.ItemStats.MagicDamage) .. "\nPhysical Damage: " .. tostring(GotItem.ItemStats.PhysicalDamage) .. "\nHealth: " .. tostring(GotItem.ItemStats.Health) .. "\nLvl Requirement: " .. tostring(GotItem.ItemStats.Requirement) .. "\nMax Upgrades: " .. tostring(GotItem.ItemStats.MaxUpgrades) .. "```",
                            inline = true
                        })
                    end
                end

                DungeonManager.SendWebook({
                    Title = "Completed dungeon " .. getgenv().DungeonInfo.PartyInfo.Dungeon .. " [" .. getgenv().DungeonInfo.PartyInfo.Difficulty .. "]," .. " [Hardcore: " .. tostring(getgenv().DungeonInfo.PartyInfo.Hardcore) .. "]," .. " [Extreme: " .. tostring(DungeonInfo.PartyInfo.Extreme) .. "]",
                    Description = "Player: ``" .. Player.Name .. "``\nLvl: ``" .. tostring(RawEquippedItems.Level) .. "``\nAmount of runs finished: ``" .. StorageFile .. "``",
                    Content = PingContent,
                    Feilds = AllFeilds,
                    FooterText = "Completed with a time of: " .. Player.PlayerGui.GUI.Top.Timer.Text .. " (Took " .. os.time() - TimeAtStartOfDungeon .. " sec), \nUser local time: " .. os.date()
                })
            end

            writefile("StorageFile.txt", tostring(tonumber(StorageFile) + 1))

            --Teleporting back to lobby
            if getgenv().ExtraDungeonInfo.RepeatDungeon then
                PartyEvents.DungeonRequest:InvokeServer("TeleportPartyDungeon")
            else
                if getgenv().MultifarmInfo.DoMultiFarm then
                    if Player.Name == getgenv().MultifarmInfo.Host then
                        PartyEvents.DungeonRequest:InvokeServer("TeleportPartyLobby")
                    end
                else
                    PartyEvents.DungeonRequest:InvokeServer("TeleportAlone")
                end
            end
            break
        end
    end
end
