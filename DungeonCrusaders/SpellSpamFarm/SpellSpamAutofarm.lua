print("client: 1.0.1")

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

    WaitTimeBeforeStartingDungeon = 10, --//If you want delay before the dungeon stats
    WaitTimeBeforeLeavingDungeon = 50, --//If you want delay before leaving the dungeon

    --For offsets when autofarming
    Cords = {
        X = 30,
        Y = 1,
        Z = 0,
    }
}

getgenv().DungeonInfo = {
    PartyInfo = {
		Difficulty = "Chaos", --//Difficult level [Novice [1-5], Advanced [5-10], Chaos [10 - inf]] / Auto
		Hardcore = false, --//Need to be lvl 11
		Extreme = true, --//Need to be lvl 12
		Private = true,
		Dungeon = "Jungle" --//Dungeon name / Auto
	}
}

getgenv().MultifarmInfo = {
    DoMultiFarm = false,

    Host = "Wanwood1960907364092",
    Accounts = {
        "TestingTesting12052",
    }
}

getgenv().Webhook = {
    SendWebooks = true,
    Url = "",

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

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerNetwork = ReplicatedStorage.Core.CoreEvents.ClientServerNetwork.ServerNetwork
local PartyEvents = ReplicatedStorage.Core.CoreEvents.PartyEvents
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")

Player:WaitForChild("leaderstats", math.huge)

local UserService = game:GetService("UserService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Request = http_request or request or HttpPost or syn.request

local Utilities = loadstring(game:HttpGet("https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/DungeonCrusaders/SpellSpamFarm/Utilities.lua"))()

local LobbyManager = Utilities.LobbyManager
local InventoryManager = Utilities.InventoryManager
local DungeonManager = Utilities.DungeonManager

--If the user gets kicked, send them back to the lobby
CoreGui.RobloxPromptGui.promptOverlay.DescendantAdded:Connect(function(Child)
    TeleportService:Teleport("6998582502")
end)

if ReplicatedFirst:FindFirstChild("IsLobby") then --In lobby
    --//Equip better stuff
    if Utilities.ExploitEnv.AutoEquipBest.DoAutoEquipBest then
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
    if Utilities.ExploitEnv.Autosell.DoAutoSell then
        local ItemsToSell = InventoryManager.GetItemsToSell()

        if ItemsToSell then
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
    end

    --//Wait before dungeon starts
    if Utilities.ExploitEnv.ExtraDungeonInfo.WaitTimeBeforeStartingDungeon > 0 then
        task.wait(math.random(Utilities.ExploitEnv.ExtraDungeonInfo.WaitTimeBeforeStartingDungeon/2, Utilities.ExploitEnv.ExtraDungeonInfo.WaitTimeBeforeStartingDungeon))
    end

    --//Multi farm
    if Utilities.ExploitEnv.MultifarmInfo.DoMultiFarm then
        if Player.Name == Utilities.ExploitEnv.MultifarmInfo.Host then
            PartyEvents.Request:InvokeServer("Create", Utilities.ExploitEnv.DungeonInfo)

            while not LobbyManager.AllUsersHaveJoined() do
                for Index, Plr in next, Utilities.ExploitEnv.MultifarmInfo.Accounts do
                    local PlrUser = Players:FindFirstChild(Plr)

                    if PlrUser then
                        PartyEvents.Comm:FireServer("Invite", PlrUser)
                    end
                end

                task.wait(2.5)
            end

        else
            --This will fire when you get an invitation to a dungeon in the lobby
            Player.PlayerGui.GUI.InviteFrame:GetPropertyChangedSignal("Visible"):Connect(function()
                PartyEvents.Request:InvokeServer("Join", {
                    Host = Players:FindFirstChild(Utilities.ExploitEnv.MultifarmInfo.Host).UserId
                })
            end)
        end

        --Remove any other people from the party who arent supposed to be there
        for Index, Teammate in next, Player.PlayerGui.GUI.Party.MyParty.Players:GetChildren() do
            if Teammate:FindFirstChild("Level") then
                local UsernameFromUserId = UserService:GetUserInfosByUserIdsAsync({tonumber(Teammate.Name)})[1].Username

                if Utilities.ExploitEnv.MultifarmInfo.Host ~= UsernameFromUserId and not table.find(Utilities.ExploitEnv.MultifarmInfo.Accounts, UsernameFromUserId) then
                    PartyEvents.Comm:FireServer("Kick", Players:FindFirstChild(UsernameFromUserId))
                end
            end
        end
    else
        PartyEvents.Request:InvokeServer("Create", Utilities.ExploitEnv.DungeonInfo)
    end

    PartyEvents.Comm:FireServer("Start")
else --Not in lobby
    while Player:WaitForChild("PlayerGui", math.huge).GUI.GameInfo.MobCount.Text == "Start Pending..." do
        Player.Character.HumanoidRootPart.CFrame = workspace.DungeonConfig.Podium.Listener.CFrame
        task.wait()
    end

    Player.Character.Info:Destroy() --God mode
    local OldInventory = InventoryManager.GetInventory("InvItems") --For checking when items get added
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
    
    --//Webhook and leaving the game
    coroutine.wrap(function() --In a coroutine to bypass waiting for boss to be dead, incase it dies when other accounts are waiting [Multifarm]
        Player.PlayerGui.EndGUI:GetPropertyChangedSignal("Enabled"):Connect(function()
            --Webhook stuff
            if Utilities.ExploitEnv.Webhook.SendWebooks then
                local AllFeilds = {}
                local PingContent = ""

                local RawEquippedItems = ServerNetwork:InvokeServer("DataFunctions", {
                    Function = "RetrieveEquippedLoadout",
                    userId = Player.userId
                })

                for Index, GotItem in next, InventoryManager.GetInventory("InvItems") do
                    if Index > #OldInventory then

                        if table.find(Utilities.ExploitEnv.Webhook.PingForRarity, GotItem.ItemStats.Tier) then
                            PingContent = "<@" .. Utilities.ExploitEnv.Webhook.UserId .. ">"
                        end

                        table.insert(AllFeilds, {
                            name = GotItem.FullItemInfo.Name,
                            value = "```Tier: " .. tostring(GotItem.ItemStats.Tier) .. "\nMagic Damage: " .. tostring(GotItem.ItemStats.MagicDamage) .. "\nPhysical Damage: " .. tostring(GotItem.ItemStats.PhysicalDamage) .. "\nHealth: " .. tostring(GotItem.ItemStats.Health) .. "\nLvl Requirement: " .. tostring(GotItem.ItemStats.Requirement) .. "\nMax Upgrades: " .. tostring(GotItem.ItemStats.MaxUpgrades) .. "```",
                            inline = true
                        })
                    end
                end

                DungeonManager.SendWebook({
                    Title = "Completed dungeon " .. Utilities.ExploitEnv.DungeonInfo.PartyInfo.Dungeon .. " [" .. Utilities.ExploitEnv.DungeonInfo.PartyInfo.Difficulty .. "]," .. " [Hardcore: " .. tostring(Utilities.ExploitEnv.DungeonInfo.PartyInfo.Hardcore) .. "]," .. " [Extreme: " .. tostring(DungeonInfo.PartyInfo.Extreme) .. "]",
                    Description = "Player: ``" .. Player.Name .. "``\nLvl: ``" .. tostring(RawEquippedItems.Level) .. "``\nAmount of runs finished: ``" .. StorageFile .. "``",
                    Content = PingContent,
                    Feilds = AllFeilds,
                    FooterText = "Completed with a time of: " .. Player.PlayerGui.GUI.Top.Timer.Text .. " (Took " .. os.time() - TimeAtStartOfDungeon .. " sec), \nUser local time: " .. os.date()
                })
            end

            --Store / read how many runs you've done
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

            writefile("StorageFile.txt", tostring(tonumber(StorageFile) + 1))

            --Teleporting back to lobby
            if Utilities.ExploitEnv.ExtraDungeonInfo.RepeatDungeon then
                PartyEvents.DungeonRequest:InvokeServer("TeleportPartyDungeon")
            else
                if Utilities.ExploitEnv.MultifarmInfo.DoMultiFarm then

                    --Leaving dungeon as multi farm
                    if Player.Name == Utilities.ExploitEnv.MultifarmInfo.Host then
                        PartyEvents.DungeonRequest:InvokeServer("TeleportPartyLobby")
                    else
                        while task.wait() do
                            warn("joining")
                            PartyEvents.DungeonComm:FireServer("JoinDungeonParty")
                        end
                    end

                else
                    PartyEvents.DungeonComm:FireServer("TeleportAlone")
                end
            end
        end)
    end)()

    local CurStage = 1
    local HasWaited = false
    while task.wait() do
        local KilledAllMobs = true
        local StageObject = workspace.Mobs:FindFirstChild("Stage" .. tostring(CurStage))

        --If at last stage, wait if the user specified it
        if not workspace.Mobs:FindFirstChild("Stage" .. tostring(CurStage + 1)) and not HasWaited then
            HasWaited = true

            if Utilities.ExploitEnv.ExtraDungeonInfo.WaitTimeBeforeLeavingDungeon > 0 then
                task.wait(math.random(Utilities.ExploitEnv.ExtraDungeonInfo.WaitTimeBeforeLeavingDungeon/2, Utilities.ExploitEnv.ExtraDungeonInfo.WaitTimeBeforeLeavingDungeon))
            end
        end

        --Actually murdering the mods
        if Player.Character:FindFirstChild("HumanoidRootPart") and StageObject then
            for Index, Mob in next, StageObject:GetChildren() do
                if Mob:FindFirstChild("HumanoidRootPart") and Mob:FindFirstChild("DisplayName") or Mob:FindFirstChild("Animate") then

                    while Mob:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("HumanoidRootPart") do
                        Player.Character.HumanoidRootPart.CFrame = CFrame.lookAt(Mob.HumanoidRootPart.Position + Vector3.new(Utilities.ExploitEnv.ExtraDungeonInfo.Cords.X, Utilities.ExploitEnv.ExtraDungeonInfo.Cords.Y, Utilities.ExploitEnv.ExtraDungeonInfo.Cords.Z), Mob.HumanoidRootPart.Position)
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
    end
end