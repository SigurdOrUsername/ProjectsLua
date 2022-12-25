print("client: 1.0.6")

getgenv().AutoEquipBest = {
    DoAutoEquipBest = true, --//Auto equips [Armor, Weapon, Jewelry]
    PreferedStat = "PhysicalDamage" --//[PhysicalDamage, MagicDamage, Health]
}

getgenv().Autosell = {
    DoAutoSell = true,

    SellTriplicatedSpells = true, --//Will keep all spells til you have 3 of them, if you get more after you have 3, script will sell it [KeepAllSpells will overrule this setting]
    KeepAllSpells = false, --//Wont sell any spells if true [This keeps all spells, regardless of name and rarity]
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

    RejoinIfKicked = true, --//If you disconnect, get kicked, anything like that, the script will auto rejoin the game for you
    WaitTimeBeforeStartingDungeon = 40, --//If you want delay before the dungeon stats
    WaitTimeBeforeLeavingDungeon = 60, --//If you want delay before leaving the dungeon
    TakeBreakAfterXRuns = 10, --//This will wait in the loby for 5 minutes when x runs have been completed

    --For offsets when autofarming
    Cords = {
        X = 0,
        Y = 1,
        Z = 0,
    }
}

getgenv().DungeonInfo = {
    AutoSelectDungeonAndDifficulty = true, --//Enable if you want the script to auto select the dungeon and difficulty

    PartyInfo = {
		Difficulty = "Novice", --//Difficult level [Novice, Advanced, Chaos]
		Hardcore = false, --//Need to be lvl 11+
		Extreme = false, --//Need to be lvl 12+
		Private = false,
		Dungeon = "Snow" --//Dungeon name
	}
}

getgenv().MultifarmInfo = {
    DoMultiFarm = false,

    Host = "DungeonCrusadersPro",
    Accounts = {
        "TestingTesting12052",
    }
}

getgenv().Webhook = {
    SendWebhooks = true,
    Url = "",

    WhichWebhooksToSend = {
        SendWebhookWhenDungeonCompleted = true,
        SendWebhookWhenScriptTakingABreak = true,
    },

    UserId = "everyone", --Which person it will ping. UserId/everyone/here/whatnot
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

local ExploitEnv = Utilities.ExploitEnv

local LobbyManager = Utilities.LobbyManager
local InventoryManager = Utilities.InventoryManager
local DungeonManager = Utilities.DungeonManager

--If the user gets kicked, send them back to the lobby
CoreGui.RobloxPromptGui.promptOverlay.DescendantAdded:Connect(function(Child)
    if ExploitEnv.ExtraDungeonInfo.RejoinIfKicked then
        TeleportService:Teleport("6998582502")
    end
end)

--In lobby
if ReplicatedFirst:FindFirstChild("IsLobby") then
    --Taking a break after X runs
    local StorageFile = tonumber(LobbyManager.ReadWriteStorageFile())
    if StorageFile >= ExploitEnv.ExtraDungeonInfo.TakeBreakAfterXRuns then
        if ExploitEnv.Webhook.SendWebhooks and ExploitEnv.Webhook.WhichWebhooksToSend.SendWebhookWhenScriptTakingABreak then
            DungeonManager.SendWebook({
                Title = "Taking a break for 5 minutes",
                Description = "Script completed " .. tostring(StorageFile) .. " runs",
                FooterText = "User local time: " .. os.date()
            })
        end

        writefile("StorageFile.txt", "0")
        task.wait(300)
    end

    --Equip better stuff
    if ExploitEnv.AutoEquipBest.DoAutoEquipBest then
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
    
    --Autosell stuff
    if ExploitEnv.Autosell.DoAutoSell then
        local ItemsToSell = InventoryManager.GetItemsToSell()

        if ItemsToSell then
            for Index, Item in next, ItemsToSell do
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

    --Wait before dungeon starts
    if ExploitEnv.ExtraDungeonInfo.WaitTimeBeforeStartingDungeon > 0 then
        task.wait(ExploitEnv.ExtraDungeonInfo.WaitTimeBeforeStartingDungeon)
    end

    --If the user wants the script to select the best dungeon / difficulty
    if ExploitEnv.DungeonInfo.AutoSelectDungeonAndDifficulty then
        local BestDungeon, BestDifficulty = LobbyManager.GetBestDungeonAndDifficulty()

        --Replacing Dungeon = "Auto" and Difficulty = "Auto" in the DungeonInfo table
        ExploitEnv.DungeonInfo.PartyInfo.Dungeon = BestDungeon
        ExploitEnv.DungeonInfo.PartyInfo.Difficulty = BestDifficulty
    end

    --Multi farm
    local TempDungeonInfo = {PartyInfo = ExploitEnv.DungeonInfo.PartyInfo} --Making a temp table for dungeon info so that the right remote arguments are passed for creating the dungeon

    if ExploitEnv.MultifarmInfo.DoMultiFarm then
        if Player.Name == ExploitEnv.MultifarmInfo.Host then
            PartyEvents.Request:InvokeServer("Create", TempDungeonInfo)

            while not LobbyManager.AllUsersHaveJoined() do
                for Index, Plr in next, ExploitEnv.MultifarmInfo.Accounts do
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
                    Host = Players:FindFirstChild(ExploitEnv.MultifarmInfo.Host).UserId
                })
            end)
        end

        --Remove any other people from the party who arent supposed to be there
        for Index, Teammate in next, Player.PlayerGui.GUI.Party.MyParty.Players:GetChildren() do
            if Teammate:FindFirstChild("Level") then
                local UsernameFromUserId = UserService:GetUserInfosByUserIdsAsync({tonumber(Teammate.Name)})[1].Username

                if ExploitEnv.MultifarmInfo.Host ~= UsernameFromUserId and not table.find(ExploitEnv.MultifarmInfo.Accounts, UsernameFromUserId) then
                    PartyEvents.Comm:FireServer("Kick", Players:FindFirstChild(UsernameFromUserId))
                end
            end
        end
    else
        PartyEvents.Request:InvokeServer("Create", TempDungeonInfo)
    end

    PartyEvents.Comm:FireServer("Start")
else --Not in lobby
    while Player:WaitForChild("PlayerGui", math.huge).GUI.GameInfo.MobCount.Text == "Start Pending..." do
        Player.Character.HumanoidRootPart.CFrame = workspace.DungeonConfig.Podium.Listener.CFrame * CFrame.new(2.5, 0, 0)
        task.wait()
    end

    --God mode
    Player.Character.Info:Destroy()
    Player.Character.IsDead:Destroy()

    local OldInventory = InventoryManager.GetInventory("InvItems") --For checking when items get added
    local TimeAtStartOfDungeon = os.time()

    --Spell spam bypass
    Player.Character.ChildAdded:Connect(function(Child)
        DungeonManager.DestroyIfSpellCooldown(Child)
    end)
    Player.CharacterAdded:Connect(function(Char)
        Player.Character:WaitForChild("Info"):Destroy()
        Player.Character:WaitForChild("IsDead"):Destroy()

        Char.ChildAdded:Connect(function(Child)
            DungeonManager.DestroyIfSpellCooldown(Child)
        end)
    end)

    --Anti lag
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
    
    --Webhook and leaving the game
    Player.PlayerGui.EndGUI:GetPropertyChangedSignal("Enabled"):Connect(function()
        --Webhook stuff
        local StorageFile = tonumber(LobbyManager.ReadWriteStorageFile())
        writefile("StorageFile.txt", tostring(StorageFile + 1))

        if ExploitEnv.Webhook.SendWebhooks and ExploitEnv.Webhook.WhichWebhooksToSend.SendWebhookWhenDungeonCompleted then
            local AllFeilds = {}
            local PingContent = ""

            local PlayerLevel = ServerNetwork:InvokeServer("DataFunctions", {
                Function = "RetrieveLevelFromPlayer",
                Player = Player
            })

            --Adding fields of every item the user got after the dungeon was completed
            for Index, GotItem in next, InventoryManager.GetInventory("InvItems") do
                if Index > #OldInventory then

                    if table.find(ExploitEnv.Webhook.PingForRarity, GotItem.ItemStats.Tier) then
                        PingContent = "<@" .. ExploitEnv.Webhook.UserId .. ">"
                    end

                    table.insert(AllFeilds, {
                        name = GotItem.FullItemInfo.Name,
                        value = "```Tier: " .. tostring(GotItem.ItemStats.Tier) .. "\nMagic Damage: " .. tostring(GotItem.ItemStats.MagicDamage) .. "\nPhysical Damage: " .. tostring(GotItem.ItemStats.PhysicalDamage) .. "\nHealth: " .. tostring(GotItem.ItemStats.Health) .. "\nLvl Requirement: " .. tostring(GotItem.ItemStats.Requirement) .. "\nMax Upgrades: " .. tostring(GotItem.ItemStats.MaxUpgrades) .. "```",
                        inline = true
                    })
                end
            end

            local CompletedDungeon = ExploitEnv.DungeonInfo.PartyInfo.Dungeon
            
            --If the user has autoselect dungeon and difficulty, than the current dungeon is the best dungeon possible
            if ExploitEnv.DungeonInfo.AutoSelectDungeonAndDifficulty then
                CompletedDungeon = LobbyManager.GetBestDungeonAndDifficulty()
            end

            DungeonManager.SendWebook({
                Title = "Completed dungeon: " .. CompletedDungeon .. " [Mode: " .. Player.PlayerGui.GUI.GameInfo.Mode.Mode.Text .. ", Difficulty: " .. Player.PlayerGui.GUI.GameInfo.Difficulty.Text .. "]",
                Description = "Player: ``" .. Player.Name .. "``\nLvl: ``" .. tostring(PlayerLevel) .. "``\nEXP: ``" .. Player.PlayerGui.GUI.HUD.EXP.Amount.Text .. "``\n#Runs finished: ``" .. tostring(StorageFile + 1) .. "``",
                Content = PingContent,
                Feilds = AllFeilds,
                FooterText = "Completed with a time of: " .. Player.PlayerGui.GUI.Top.Timer.Text .. " (Took " .. os.time() - TimeAtStartOfDungeon .. " sec), \nUser local time: " .. os.date()
            })
        end

        --Teleporting back to lobby
        if ExploitEnv.ExtraDungeonInfo.RepeatDungeon then
            PartyEvents.DungeonRequest:InvokeServer("TeleportPartyDungeon")
        else
            if ExploitEnv.MultifarmInfo.DoMultiFarm then

                --Leaving dungeon as multi farm
                if Player.Name == ExploitEnv.MultifarmInfo.Host then
                    PartyEvents.DungeonRequest:InvokeServer("TeleportPartyLobby")
                else
                    while task.wait() do
                        PartyEvents.DungeonComm:FireServer("JoinDungeonParty")
                    end
                end

            else
                PartyEvents.DungeonComm:FireServer("TeleportAlone")
                --game:Shutdown()
            end
        end
    end)

    local CurStage = 1
    local HasWaited = false
    while task.wait() do
        local KilledAllMobs = true
        local StageObject = workspace.Mobs:FindFirstChild("Stage" .. tostring(CurStage))

        --If at last stage, wait if the user specified it
        if not workspace.Mobs:FindFirstChild("Stage" .. tostring(CurStage + 1)) and not HasWaited then
            HasWaited = true

            if ExploitEnv.ExtraDungeonInfo.WaitTimeBeforeLeavingDungeon > 0 then
                task.wait(ExploitEnv.ExtraDungeonInfo.WaitTimeBeforeLeavingDungeon)
            end
        end

        --Actually murdering the mods
        if Player.Character:FindFirstChild("HumanoidRootPart") and StageObject then
            for Index, Mob in next, StageObject:GetChildren() do
                if Mob:FindFirstChild("HumanoidRootPart") and Mob:FindFirstChild("DisplayName") or Mob:FindFirstChild("Animate") then

                    while Mob:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("HumanoidRootPart") do
                        Player.Character.HumanoidRootPart.CFrame = CFrame.lookAt(Mob.HumanoidRootPart.Position + Vector3.new(ExploitEnv.ExtraDungeonInfo.Cords.X, ExploitEnv.ExtraDungeonInfo.Cords.Y, ExploitEnv.ExtraDungeonInfo.Cords.Z), Mob.HumanoidRootPart.Position)
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
