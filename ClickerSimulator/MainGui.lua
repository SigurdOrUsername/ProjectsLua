local Player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

loadstring(game:HttpGet("https://pastebin.com/raw/cwDSpepQ", true))()

local FunctionsModule = require(ReplicatedStorage.FunctionsModule)
local EggModule = require(ReplicatedStorage.EggModule)
local HUDHandler = getsenv(Player.PlayerGui.mainUI.HUDHandler)
local PortalModule = require(game.ReplicatedStorage.PortalModule)
local Data = Player.Data

local Window = library:AddWindow("Lol")
local GeneralClick = Window:AddTab("GeneralClick")
local Pets = Window:AddTab("Pets")
local Rebirth = Window:AddTab("Rebirth")
local ZoneTab = Window:AddTab("Zone")
local GamepassTab = Window:AddTab("Gamepasses")

--GENERAL
local GeneralClick_Settings = {
    DoAutoClick = false,
    AutoClaimQuest = false,
}

GeneralClick:AddSwitch("Autoclick", function(Value)
    GeneralClick_Settings.DoAutoClick = Value
end)
GeneralClick:AddSwitch("Auto claim quests", function(Value)
    GeneralClick_Settings.AutoClaimQuest = Value
end)
GeneralClick:AddLabel("You can disable/enable the click popups in the game settings!")

--PETS
local Pets_Settings = {
    AutoShinyPets = false,
    AutoEquipBestPets = false,
    AutoBuyEgg = false,
    GetBestEgg = false,
    EggDropdown,
    CurEggLocation = "Basic",
    AutoDeletePets = false,
    Threshold = 100,
}

Pets:AddSwitch("Auto upgrade pet (shiny, golden, rainbow, ect)", function(Value)
    Pets_Settings.AutoShinyPets = Value
end)
Pets:AddSwitch("Auto equip best pets", function(Value)
    Pets_Settings.AutoEquipBestPets = Value
    if Value then
        ReplicatedStorage.Events.Client.petsTools.equipBest:FireServer()
    end
end)

--Equipping best pets when new pet is added to inventory
Player.petOwned.ChildAdded:Connect(function()
    if Pets_Settings.AutoEquipBestPets then
        ReplicatedStorage.Events.Client.petsTools.equipBest:FireServer()
    end
end)

local EggPetsFolder = Pets:AddFolder("Eggs")

EggPetsFolder:AddSwitch("Auto buy selected egg", function(Value)
    Pets_Settings.AutoBuyEgg = Value
end)
EggPetsFolder:AddSwitch("Auto select best egg", function(Value)
    Pets_Settings.GetBestEgg = Value
end)
EggDropdown = EggPetsFolder:AddDropdown("Egg location", function(Value)
    Pets_Settings.CurEggLocation = Value
end)

local TempEggFolder = workspace.Eggs:GetChildren()
table.sort(TempEggFolder, function(a, b)
    return a.Name:lower() < b.Name:lower()
end)
table.foreach(TempEggFolder, function(EggLocationIndex)
    EggDropdown:Add(TempEggFolder[EggLocationIndex])
end)

local DeletePetsFolder = Pets:AddFolder("Delete pets")

--Making it into a function for easier use
local function GenerateWarningString()
    return "All pets below " .. tostring(Pets_Settings.Threshold) .. " multiplier will be deleted!"
end

DeletePetsFolder:AddSwitch("Auto delete pets", function(Value)
    Pets_Settings.AutoDeletePets = Value
end)
DeletePetsFolder:AddTextBox("Threshold (multiplier): ", function(Value)
    Pets_Settings.Threshold = tonumber(Value)
    Pets_Settings.WarningLabel.Text = GenerateWarningString()
end)
Pets_Settings.WarningLabel = DeletePetsFolder:AddLabel(GenerateWarningString())

--REBIRTH
local Rebirth_Settings = {
    DoAutoRebirth = false,
    RebirthPer = "Auto"
}

Rebirth:AddSwitch("Auto rebirth", function(Value)
    Rebirth_Settings.DoAutoRebirth = Value
end)
Rebirth:AddTextBox("Rebirths per", function(Value)
    if tonumber(Value) then
        Rebirth_Settings.RebirthPer = tonumber(Value)
    else
        Rebirth_Settings.RebirthPer = "Auto"
    end
end)
Rebirth:AddLabel("If you set 'Rebirths per' to 'Auto' the script will calculate the highest rebirth amount you can do!")

--ZONES
local Zone_Settings = {
    TeleportDropdown,
    CurZoneLocation = "",
    AutoBuyZone = false,
}

local function GetBestZone()
    local UnlockedZones = Data.unlockedZones.Value:split(";") --Formatted like:   ;Sky;;Ice;
    return UnlockedZones[#UnlockedZones - 1]
end

ZoneTab:AddSwitch("Auto buy zones", function(Value)
    Zone_Settings.AutoBuyZone = Value
end)
ZoneTab:AddButton("Teleport to best zone", function()
    local Zone = workspace.Zones:FindFirstChild(GetBestZone())

    Player.Character.HumanoidRootPart.CFrame = Zone.teleport.CFrame
end)
ZoneTab:AddButton("Teleport to specific zone", function()
    local Zone = workspace.Zones:FindFirstChild(Zone_Settings.CurZoneLocation)

    Player.Character.HumanoidRootPart.CFrame = Zone.teleport.CFrame
end)

local TempZoneFolder = workspace.Zones:GetChildren()
TeleportDropdown = ZoneTab:AddDropdown("Zone", function(Value)
    Zone_Settings.CurZoneLocation = Value
end)
table.sort(TempZoneFolder, function(a, b)
    return a.Name:lower() < b.Name:lower()
end)
table.foreach(TempZoneFolder, function(ZoneIndex)
    TeleportDropdown:Add(TempZoneFolder[ZoneIndex])
end)

--GAMEPASS
GamepassTab:AddButton("")

local Debounces = {
    BuyEggDebounce = false,
    SellingPets = false,
    Rebirth = false,
    BuyZone = false,
}

local GameFunctions = {
    getPetLevelData = function(p10, p11, p12)
        local v14 = 30
        if p10 then
            if p10:FindFirstChild("UsedSuperMaxLevelPotion") then
                v14 = 40
            end
        end
        local v15 = p11 and FunctionsModule.getPetBaseMultiplier(nil, p11) or FunctionsModule.getPetBaseMultiplier(p10)
        local v16 = math.floor(v15 * 1.5)
        local v17 = math.floor(v16 - v15)
        local v18 = math.min(v17, v14)
        local v19 = math.max(1, math.floor(v17 / v14))
        if p12 then
            return v18
        end;
        local v20 = p11 and p11.level or p10:WaitForChild("level").Value
        local v21 = math.ceil(400 * 1.1 ^ v20)
        local v22 = v15 + v20 * v19
        if v14 == 40 then
            v22 = v22 * (1 + (v20 - 30) * 0.03)
        end;
        local v23 = require(game.ReplicatedStorage.EnchantUtil)
        local v24 = v23:GetPetEnchant(p10 and p10:FindFirstAncestorWhichIsA("Player"), p10)
        if v24 then
            if v24[1] == 1 then
                v22 = v22 * (1 + v23.EnchantData[1].Bonuses[v24[2]] * 0.01)
            end
        end
        return {
            baseMultiplier = v15, 
            maxMultiplier = v16, 
            maxMultiplierAdd = v17, 
            maxLevel = v18, 
            eachLevelMultiplierAdd = v19, 
            experienceNeededToLevelUp = v21, 
            fullMultiplier = v22
        }
    end,

    GetSortedZones = function()
        local OwnedZones = Data.unlockedZones.Value:split(";") --Formatted like:   ;Sky;;Ice;
        local SortedOwnedZones = {}

        for Index, OwnedZone in next, OwnedZones do
            if OwnedZone ~= "" then
                table.insert(SortedOwnedZones, OwnedZone)
            end
        end

        return SortedOwnedZones
    end
}

while task.wait() do
    --General
    if GeneralClick_Settings.DoAutoClick then
        HUDHandler.activateClick()
    end
    if GeneralClick_Settings.AutoClaimQuest then
        for Index, Quest in next, Player.PlayerGui.rewardsUI.rewardsBackground.background.ScrollingFrame:GetChildren() do
            if Quest:FindFirstChild("claim") and Quest.claim.Visible then
                ReplicatedStorage.Events.Client.claimQuest:FireServer(Quest.Name)
            end
        end
    end

    --Pets
    if Pets_Settings.AutoShinyPets then
        local Pets = FunctionsModule.getPetDataFromFolder(Player.petOwned)

        for Index, Pet in next, Pets do
            local CanShiny = FunctionsModule.canUpgradePet(Player.petOwned, Pet.name, Pet.petType, nil, Data.gamepasses.value)

            if CanShiny and CanShiny.hasEnough then
                ReplicatedStorage.Events.Client.upgradePet:FireServer(Pet.name, Pet.petType, Pet.folder)
                break
            end
        end
    end
    if Pets_Settings.AutoBuyEgg then
        coroutine.wrap(function()
            if not Debounces.BuyEggDebounce then
                Debounces.BuyEggDebounce = true
                local EggName = Pets_Settings.CurEggLocation

                if Pets_Settings.GetBestEgg then
                    local SortedZones = GameFunctions.GetSortedZones()
                    for Index, Egg in next, EggModule.Eggs do
                        if Egg.Island == SortedZones[#SortedZones] then
                            EggName = Egg.Name
                        end
                    end
                end

                local EggInfo = EggModule.Eggs[EggName]

                if EggInfo.Cost <= tonumber(Data.clicksClient.Value) then
                    ReplicatedStorage.Events.Client.purchaseEgg2:InvokeServer(workspace.Eggs:FindFirstChild(EggInfo.Name), false, false)
                end
                task.wait(0.5)
                Debounces.BuyEggDebounce = false
            end
        end)()
    end
    if Pets_Settings.AutoDeletePets then
        local Pets = FunctionsModule.getPetDataFromFolder(Player.petOwned)
        local PetsToDelete = {}

        for Index, Pet in next, Pets do
            local Multiplier = GameFunctions.getPetLevelData(Pet.folder).fullMultiplier

            --If the pet's multiplier is lower than the threshold the user sets, delete it
            if Multiplier <= Pets_Settings.Threshold then
                local PetsEquipped = Data.petsEquipped.Value:split(";") --formatted like:   ;35;;23;

                if not table.find(PetsEquipped, Pet.folder.Name) then
                    table.insert(PetsToDelete, {
                        ["Equipped"] = false,
                        ["selectedPetFolder"] = Pet.folder,
                        ["PetName"] = Pet.name
                    })
                end
            end
        end

        coroutine.wrap(function()
            if #PetsToDelete > 0 and not Debounces.SellingPets then
                Debounces.SellingPets = true
                ReplicatedStorage.Events.Client.petsTools.deleteUnlocked:FireServer(PetsToDelete)
                task.wait(0.5)
                Debounces.SellingPets = false
            end
        end)()
    end

    --Rebirth
    coroutine.wrap(function()
        if Rebirth_Settings.DoAutoRebirth and not Debounces.Rebirth then
            Debounces.Rebirth = true
            local RebirthPer = Rebirth_Settings.RebirthPer
            if Rebirth_Settings.RebirthPer == "Auto" then
                for Index, RebirthAmount in next, Player.PlayerGui.mainUI.rebirthBackground.Background.Background.ScrollingFrame:GetChildren() do
                    RebirthPer = tonumber(RebirthAmount.Name)
                end
            end

            local RebirthPrice = FunctionsModule.calculateRebirthsCost(tonumber(Data.Rebirths.Value), RebirthPer)

            if RebirthPrice <= tonumber(Data.clicksClient.Value) then
                ReplicatedStorage.Events.Client.requestRebirth:FireServer(RebirthPer, false, false)
            end
            task.wait(0.5)
            Debounces.Rebirth = false
        end
    end)()

    --Zones
    if Zone_Settings.AutoBuyZone then
        local SortedOwnedZones = GameFunctions.GetSortedZones()

        coroutine.wrap(function()
            if PortalModule[#SortedOwnedZones + 2].cost <= tonumber(Data.clicksClient.Value) and not Debounces.BuyZone then
                Debounces.BuyZone = true
                ReplicatedStorage.Events.Client.purchaseZone:FireServer(tostring(#SortedOwnedZones + 1))
                task.wait(0.5)
                Debounces.BuyZone = false
            end
        end)()
    end
end
