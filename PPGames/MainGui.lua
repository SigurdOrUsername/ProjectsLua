local Player = game.Players.LocalPlayer
local ReplicatedStorage = game.ReplicatedStorage

local OldPcall = pcall
local OldUnpack = table.unpack

local UniversalInfo = {
    PokemonParty,
    AllPokemon = {},

    AllImportantModuleScripts = {},
    AllImportantLocalScripts = {},
    InfoTable = {},
    NewMove,
    SpawningFunction,
    IsUltima = function()
        return getrenv()._G.wowthatsprettyfunnydud
    end,
    IsPolaro = function()
        return getrenv()._G.nwiqkndqwndqlwkndlkqoc
    end,
    BypassEnvCheck = function(Func, ...)
        local ReturnValue

        local Mt = getrawmetatable(getfenv())
        local OldIndex = Mt.__index
        local NewIndex = {}

        local GameEnv = getrenv()
        local ExploitEnv = getgenv()
        local ExploitEnvMt = getrawmetatable(ExploitEnv)

        for FuncName, Func in next, ExploitEnv do
            if GameEnv[FuncName] then
                NewIndex[FuncName] = Func
            end
        end

        if ExploitEnvMt and ExploitEnvMt.__index then
            for FuncName, Func in next, ExploitEnvMt.__index do
                if not NewIndex[FuncName] and GameEnv[FuncName] then
                    NewIndex[FuncName] = Func
                end
            end
        end

        local Args = {...}
        Mt.__index = NewIndex
        OldPcall(function()
            ReturnValue = Func(OldUnpack(Args))
        end)
        Mt.__index = OldIndex

        return ReturnValue
    end
}

--//Start init
for Index, ModuleScript in next, ReplicatedStorage:GetDescendants() do
    if ModuleScript.ClassName == "ModuleScript" then
        table.insert(UniversalInfo.AllImportantModuleScripts, ModuleScript)
    end
end

for Index, LocalScript in next, Player:GetDescendants() do
    if LocalScript.ClassName == "LocalScript" then
        table.insert(UniversalInfo.AllImportantLocalScripts, LocalScript)
    end
end

local function FindInfoInModuleScript(Info)
    for Index, ModuleScript in next, UniversalInfo.AllImportantModuleScripts do
        local TempInfo

        local _, Error = pcall(function()
            TempInfo = require(ModuleScript)
        end)

        if not Error and type(TempInfo) == "table" then
            for FuncName, Func in next, TempInfo do
                if FuncName == Info then
                    return TempInfo, ModuleScript
                end
            end
        end
    end
end

local function FindInfoInLocalScriptENV(Info)
    for Index, LocalScript in next, UniversalInfo.AllImportantLocalScripts do
        local TempEnv

        local _, Error = pcall(function()
            TempEnv = getsenv(LocalScript)
        end)

        if not Error then
            for FuncName, Func in next, TempEnv do
                if FuncName == Info then
                    return TempEnv, LocalScript
                end
            end
        end
    end
end

local function GetSpawningFunction()
    for FuncName, Value in next, getrenv()._G do
        if type(Value) == "function" then
            local FuncConstants = getconstants(Value)

            if table.find(FuncConstants, "getrenv") and table.find(FuncConstants, "InvokeServer") then
                return Value
            end
        end
    end
end

local function GetPokemonParty()
    local TempEvents = {}

    for Index, PlayerChildren in next, Player:GetChildren() do
        if PlayerChildren.ClassName == "Configuration" then
            local Config = PlayerChildren:FindFirstChildWhichIsA("Configuration")

            if Config and Config:FindFirstChild("PartyPosition") then
                UniversalInfo.PokemonParty = PlayerChildren
                return
            end
        end
    end

    for Index, PlayerChildren in next, Player:GetChildren() do
        if PlayerChildren.ClassName == "Configuration" and #PlayerChildren:GetChildren() == 0 then
            TempEvents[#TempEvents + 1] = PlayerChildren.ChildAdded:Connect(function(Child)
                if Child.ClassName == "Configuration" then
                    for Index, Event in next, TempEvents do
                        TempEvents[Index]:Disconnect()
                    end

                    UniversalInfo.PokemonParty = Child.Parent
                end
            end)
        end
    end
end

local function Init()
    GetPokemonParty()
    repeat task.wait() until UniversalInfo.PokemonParty ~= nil
    UniversalInfo.AllPokemon = FindInfoInModuleScript("Pikachu")

    UniversalInfo.InfoTable = FindInfoInModuleScript("FuncAddItem")
    UniversalInfo.NewMove = FindInfoInModuleScript("NewMove").NewMove
    UniversalInfo.SpawningFunction = GetSpawningFunction()
    UniversalInfo.ChangePos = FindInfoInModuleScript("Change").Change

    UniversalInfo.Hash = FindInfoInLocalScriptENV("hash").hash
    UniversalInfo.Dehash = FindInfoInLocalScriptENV("dehash").dehash

    UniversalInfo.ParentChange = FindInfoInModuleScript("Change").ParentChange
    UniversalInfo.Release = FindInfoInModuleScript("Release").Release

    UniversalInfo.ExpUpdate = FindInfoInLocalScriptENV("expupdate").expupdate
    UniversalInfo.ExpTable = FindInfoInModuleScript("FastExp")
    for Index, RemoteFunction in next, game:GetDescendants() do
        if RemoteFunction.ClassName == "RemoteFunction" and RemoteFunction.Name:lower():find("fiaj") then --bad method i know
            UniversalInfo.GiveExp = RemoteFunction
        end
    end
end

--//End init

Init()

--//Start UI

local Flux = loadstring(game:HttpGet("https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/NewUiLib_NEW"))()

local Window = Flux:Window("Lol", "PP games", Color3.fromRGB(255, 110, 48), Enum.KeyCode.RightShift)
local Inventory = Window:Tab("Inventory", "http://www.roblox.com/asset/?id=6023426915")
local Pokemon = Window:Tab("Pokemon", "http://www.roblox.com/asset/?id=6023426915")
local Roulette = Window:Tab("Roulette", "http://www.roblox.com/asset/?id=6023426915")
local InBattle = Window:Tab("In Battle", "http://www.roblox.com/asset/?id=6023426915")
local PokemonList = Window:Tab("List of pokemon", "http://www.roblox.com/asset/?id=6023426915")
local Misc = Window:Tab("Misc", "http://www.roblox.com/asset/?id=6023426915")
local ChangeLog = Window:Tab("Change Log", "http://www.roblox.com/asset/?id=6023426915")

--Inventory

local Inventory_Info = {
    ItemToAdd = "",
    ItemLocationDropdown,
    NumItemToAdd = 1,
    ItemLocationObject
}

Inventory:Line()
Inventory:Label("Inventory stuff", Color3.fromRGB(255, 144, 118))

Inventory:Textbox("Item to add: ", "Which item should be added", false, function(Value)
    Inventory_Info.ItemToAdd = Value
end, {
    ["clear"] = false,
})
Inventory:Textbox("Amount of item to add: ", "How much of the item should be added", false, function(Value)
    Inventory_Info.NumItemToAdd = tonumber(Value)
end, {  
    ["clear"] = false,
})
Inventory_Info.ItemLocationDropdown = Inventory:Dropdown("Where to add item: ", {}, function(Value)
    Inventory_Info.ItemLocationObject = Player.Bag:FindFirstChild(Value)
end)
Inventory:Button("Add item", "Adds the item to the location you specified", function()
    UniversalInfo.InfoTable.FuncAddItem(nil, Inventory_Info.ItemToAdd, Inventory_Info.ItemLocationObject, Inventory_Info.NumItemToAdd)
end)

for Index, Value in next, Player.Bag:GetChildren() do
    Inventory_Info.ItemLocationDropdown:Add(Value.Name)
end

--Inventory: Currency

local Currency_Info = {
    NumBP = 1,
}

Inventory:Line()
Inventory:Label("Currency", Color3.fromRGB(255, 144, 118))

Inventory:Textbox("Amount of BP: ", "You cannot spawn more than 300Bp at once!", false, function(Value)
    if tonumber(Value) then
        Currency_Info.NumBP = tonumber(Value)
    end
end, {
    ["clear"] = false
})
Inventory:Button("Spawn BP!", "Spawns BP for you", function()
    UniversalInfo.InfoTable.BPChange(nil, Currency_Info.NumBP)
end)

--Pokemon: Spawner

local PokemonSpawner_Info = {
    DebounceSpawningPokemon = false,
    PokemonName = "Pidgey",
    Location = UniversalInfo.PokemonParty,
    LocationPicker,
    Lvl = 1,
}

local PokemonSpawnerRepeat_Info = {
    SpawnUntilShiny = false,
    SpawnUntilAura = false,
    DoRepeatSpawn = false,
    SpawnUntilForm = false,
}

local function CheckPokemon(Pokemon, CheckForShiny, CheckForAura, CheckForForm)
    local ReturnValue = true
    
    if CheckForShiny then
        ReturnValue = Pokemon.Shiny.Value
    end
    if CheckForAura then
        ReturnValue = Pokemon:FindFirstChild("Aura")
    end
    if CheckForForm then
        ReturnValue = Pokemon:FindFirstChild("Form")
    end
    
    return ReturnValue
end

local function SpawnPokemon()
    if PokemonSpawner_Info.DebounceSpawningPokemon then
        return
    end
    if not UniversalInfo.AllPokemon[PokemonSpawner_Info.PokemonName] then
        Flux:Notification("The pokemon " .. PokemonSpawner_Info.PokemonName .. " is not a real pokemon (Illegal pokemon error)", "ok lol")
    end

    PokemonSpawner_Info.DebounceSpawningPokemon = true
    local Pokemon

    if UniversalInfo.IsPolaro() then
        Pokemon = UniversalInfo.BypassEnvCheck(UniversalInfo.SpawningFunction, PokemonSpawner_Info.PokemonName, Player, PokemonSpawner_Info.Lvl, true)
    else
        Pokemon = UniversalInfo.BypassEnvCheck(UniversalInfo.SpawningFunction, PokemonSpawner_Info.PokemonName, UniversalInfo.PokemonParty, PokemonSpawner_Info.Lvl, true)
    end

    if Pokemon then
        if CheckPokemon(Pokemon, PokemonSpawnerRepeat_Info.SpawnUntilShiny, PokemonSpawnerRepeat_Info.SpawnUntilAura, PokemonSpawnerRepeat_Info.SpawnUntilForm) then
            UniversalInfo.BypassEnvCheck(UniversalInfo.ParentChange, nil, Pokemon, PokemonSpawner_Info.Location)
            if Player.PC:FindFirstChild(PokemonSpawner_Info.Location.Name) then --Adding to location
                UniversalInfo.ChangePos(nil, Pokemon, #PokemonSpawner_Info.Location:GetChildren()) --Adding to pc if user specified it
            else
                UniversalInfo.InfoTable.SwapParty(nil, Pokemon, #UniversalInfo.PokemonParty:GetChildren()) --Else add it it to the party
            end
        else
            warn("Destroyed!")
            UniversalInfo.Release(nil, Pokemon)
        end
    end
    task.wait(0.5)
    PokemonSpawner_Info.DebounceSpawningPokemon = false
end

--Pokemon: Spawner (ui)

Pokemon:Line()
Pokemon:Label("Spawner", Color3.fromRGB(255, 144, 118))

Pokemon:Label("PS: Works for every exploit now!")
Pokemon:Textbox("Pokemon name", "If this does not work, try again, but press enter after writing in the name!", false, function(Value)
    PokemonSpawner_Info.PokemonName = Value
end, {
    ["clear"] = false
})
Pokemon:Textbox("Lvl", "If this does not work, try again, but press enter after writing in the lvl!", false, function(Value)
    if tonumber(Value) then
        PokemonSpawner_Info.Lvl = tonumber(Value)
    end
end, {
    ["clear"] = false
})
PokemonSpawner_Info.LocationPicker = Pokemon:Dropdown("Location", {}, function(Value)
    PokemonSpawner_Info.Location = Player.PC:FindFirstChild(Value) or UniversalInfo.PokemonParty
end)

PokemonSpawner_Info.LocationPicker:Add("Pokemon Party")
for Index, BoxName in next, Player.PC:GetChildren() do
    PokemonSpawner_Info.LocationPicker:Add(BoxName.Name)
end

Pokemon:Button("Spawn!", "Spawns in the pokemon in the specified location", function()
    SpawnPokemon()
end)

--Pokemon: Repeatedly spawn pokemon

Pokemon:Line()
Pokemon:Label("Repeatedly spawn pokemon", Color3.fromRGB(255, 144, 118))

Pokemon:Toggle("Spawn until shiny", "Spawns selected pokemon until it is shiny", false, function(Value)
    PokemonSpawnerRepeat_Info.SpawnUntilShiny = Value
end)
Pokemon:Toggle("Spawn until aura", "Spawns selected pokemon until it has an aura", false, function(Value)
    PokemonSpawnerRepeat_Info.SpawnUntilAura = Value
end)
Pokemon:Toggle("Spawn until reskin/form", "Spawns selected pokemon until it has a tint/reskin", false, function(Value)
    PokemonSpawnerRepeat_Info.SpawnUntilForm = Value
end)
Pokemon:Toggle("Repeatedly spawn pokemon!", "Repeatedly spawns the pokemon and deletes it if it does not fill all of the criteria you've selected", false, function(Value)
    PokemonSpawnerRepeat_Info.DoRepeatSpawn = Value
end)

coroutine.wrap(function()
    while task.wait() do
        if PokemonSpawnerRepeat_Info.DoRepeatSpawn then
            SpawnPokemon()
            warn("Spawned!")
        end
    end
end)()

--Pokemon: Skin Modifier

local ModifySkin_Info = {
    PokemonToModify,
    PokemonToModifyDropdown,
    PokemonToModifyDropdownInfo = {}
}

local function UpdateDropdown(InfoDropdown, Dropdown, InfoContent)
    for Index, Value in next, InfoDropdown do
        InfoDropdown[Index]:Remove()
    end
    if InfoContent then
        for Index, Value in next, InfoContent:GetChildren() do
            if Value then
                InfoDropdown[#InfoDropdown + 1] = Dropdown:Add(Value.Name)
            end
        end
    end
end

Pokemon:Line()
Pokemon:Label("Skin modifier", Color3.fromRGB(255, 144, 118))

Pokemon:Label("This only works for Project Polaro! (for now)")
ModifySkin_Info.PokemonToModifyDropdown = Pokemon:Dropdown("Pokemon party", {}, function(Value)
    ModifySkin_Info.PokemonToModify = UniversalInfo.PokemonParty:FindFirstChild(Value)
end)

--updating the pokemonparty dropdown for skin modifying
UpdateDropdown(ModifySkin_Info.PokemonToModifyDropdownInfo, ModifySkin_Info.PokemonToModifyDropdown, UniversalInfo.PokemonParty)
UniversalInfo.PokemonParty.ChildAdded:Connect(function(Child)
    UpdateDropdown(ModifySkin_Info.PokemonToModifyDropdownInfo, ModifySkin_Info.PokemonToModifyDropdown, UniversalInfo.PokemonParty)
end)
UniversalInfo.PokemonParty.ChildRemoved:Connect(function(Child)
    UpdateDropdown(ModifySkin_Info.PokemonToModifyDropdownInfo, ModifySkin_Info.PokemonToModifyDropdown, UniversalInfo.PokemonParty)
end)

Pokemon:Button("Modify skin!", "Modifies the skin of the selected pokemon", function()
    UniversalInfo.InfoTable.FuncAddItem(nil, "Dark Skinifier", Player.Bag.Evolution, 1)
    UniversalInfo.InfoTable.Skinify(nil, ModifySkin_Info.PokemonToModify, nil, true)
end)

--Pokemon: Moves

local Pokemon_Info = {
    PokemonToModify,
    PokemonMove,
    PokemonToModifyDropdown,
    PokemonToModifyDropdownInfo = {},
    ReplaceMove,
    MovesToReplaceDropdown,
    MovesToReplaceDropdownInfo = {},
}

Pokemon:Line()
Pokemon:Label("Moves", Color3.fromRGB(255, 144, 118))

Pokemon_Info.PokemonToModifyDropdown = Pokemon:Dropdown("Pokemon party", {}, function(Value)
    Pokemon_Info.PokemonToModify = UniversalInfo.PokemonParty:FindFirstChild(Value)
    UpdateDropdown(Pokemon_Info.MovesToReplaceDropdownInfo, Pokemon_Info.MovesToReplaceDropdown, Pokemon_Info.PokemonToModify.Moves)
end)
Pokemon:Textbox("Name of move to add: ", "Which move should be added", false, function(Value)
    Pokemon_Info.PokemonMove = Value
    UpdateDropdown(Pokemon_Info.MovesToReplaceDropdownInfo, Pokemon_Info.MovesToReplaceDropdown, Pokemon_Info.PokemonToModify.Moves)
end, {
    ["clear"] = false
})
Pokemon:Button("Add move", "Adds the move", function()
    UniversalInfo.NewMove(nil, Pokemon_Info.PokemonToModify, Pokemon_Info.PokemonMove)
    UpdateDropdown(Pokemon_Info.MovesToReplaceDropdownInfo, Pokemon_Info.MovesToReplaceDropdown, Pokemon_Info.PokemonToModify.Moves)
end)

--Updating the pokemonparty dropdown for moves
UpdateDropdown(Pokemon_Info.PokemonToModifyDropdownInfo, Pokemon_Info.PokemonToModifyDropdown, UniversalInfo.PokemonParty)
UniversalInfo.PokemonParty.ChildAdded:Connect(function(Child)
    UpdateDropdown(Pokemon_Info.PokemonToModifyDropdownInfo, Pokemon_Info.PokemonToModifyDropdown, UniversalInfo.PokemonParty)
end)
UniversalInfo.PokemonParty.ChildRemoved:Connect(function(Child)
    UpdateDropdown(Pokemon_Info.PokemonToModifyDropdownInfo, Pokemon_Info.PokemonToModifyDropdown, UniversalInfo.PokemonParty)
end)

--Pokemon: Moves: Replace moves

Pokemon:Line()
Pokemon:Label("If you have 4 moves, you can replace moves here", Color3.fromRGB(255, 144, 118))

Pokemon_Info.MovesToReplaceDropdown = Pokemon:Dropdown("Moves to replace: ", {}, function(Value)
    Pokemon_Info.ReplaceMove = Pokemon_Info.PokemonToModify.Moves:FindFirstChild(Value)
end)
Pokemon:Textbox("Name of move to replace: ", "Which move should be replaced", false, function(Value)
    Pokemon_Info.PokemonMove = Value
end, {
    ["clear"] = false
})
Pokemon:Button("Replace move", "Replaces the move with 'Name of move to replace'", function()
    UniversalInfo.InfoTable.MoveLearn(nil, Pokemon_Info.PokemonToModify, Pokemon_Info.ReplaceMove, Pokemon_Info.PokemonMove)
    UpdateDropdown(Pokemon_Info.MovesToReplaceDropdownInfo, Pokemon_Info.MovesToReplaceDropdown, Pokemon_Info.PokemonToModify.Moves)
end)

--Pokemon: Level Modifier

local ModifyLevel_Info = {
    PokemonToModify,
    Lvl = 1,
    PokemonToModifyDropdown,
    PokemonToModifyDropdownInfo = {},
}

Pokemon:Line()
Pokemon:Label("Level modifying", Color3.fromRGB(255, 144, 118))

ModifyLevel_Info.PokemonToModifyDropdown = Pokemon:Dropdown("Pokemon party", {}, function(Value)
    ModifyLevel_Info.PokemonToModify = UniversalInfo.PokemonParty:FindFirstChild(Value)
end)

--Updating the pokemonparty dropdown for lvl modifying
UpdateDropdown(ModifyLevel_Info.PokemonToModifyDropdownInfo, ModifyLevel_Info.PokemonToModifyDropdown, UniversalInfo.PokemonParty)
UniversalInfo.PokemonParty.ChildAdded:Connect(function(Child)
    UpdateDropdown(ModifyLevel_Info.PokemonToModifyDropdownInfo, ModifyLevel_Info.PokemonToModifyDropdown, UniversalInfo.PokemonParty)
end)
UniversalInfo.PokemonParty.ChildRemoved:Connect(function(Child)
    UpdateDropdown(ModifyLevel_Info.PokemonToModifyDropdownInfo, ModifyLevel_Info.PokemonToModifyDropdown, UniversalInfo.PokemonParty)
end)

Pokemon:Textbox("Level of pokemon: ", "", false, function(Value)
    ModifyLevel_Info.Lvl = tonumber(Value)
end)
Pokemon:Button("Set lvl of pokemon", "Changes level of selected pokemon to whatever ya want (within reason of course (1-100))", function()
    UniversalInfo.InfoTable.ResetLevel(nil, ModifyLevel_Info.PokemonToModify)
    local ExpNeeded = UniversalInfo.ExpTable[UniversalInfo.AllPokemon[ModifyLevel_Info.PokemonToModify.Name].ExpType .. "Exp"](ModifyLevel_Info.Lvl)

    UniversalInfo.GiveExp:InvokeServer(ModifyLevel_Info.PokemonToModify, UniversalInfo.Hash(ExpNeeded))
    for Index = 1, ModifyLevel_Info.Lvl do
        coroutine.wrap(function()
            UniversalInfo.InfoTable.NeoPill(nil, ModifyLevel_Info.PokemonToModify)
        end)()
    end
    Flux:Notification(ModifyLevel_Info.PokemonToModify.Name .. "'s level has been changed to " .. tostring(ModifyLevel_Info.Lvl), "ok lol")
end)

--Roulette

local Namecall_Info = {
    DontPayForRoulettes = false,
    BypassSwearFilter = true,
}

local Old
Old = hookmetamethod(game, "__namecall", function(Self, ...)
    local Args = {...}

    if Namecall_Info.DontPayForRoulettes then
        if tostring(Self) == "MarketplaceService" and getcallingscript() and tostring(getcallingscript()):find("Roulettes") then
            return
        end
    end
    if Namecall_Info.BypassSwearFilter then
        if tostring(Self) == "SayMessageRequest" then
            ReplicatedStorage.DefaultChatSystemChatEvents.SayPokemonRequest:FireServer(Args[1], "All")
            return
        end
    end
    return Old(Self, ...)
end)

Roulette:Line()
Roulette:Label("Roulette stuff", Color3.fromRGB(255, 144, 118))

Roulette:Label("This only works for Ultima! (for now)")
Roulette:Toggle("Disable needing to pay for roulettes", "You wont have to pay for roulettes anymore!", false, function(Value)
    Namecall_Info.DontPayForRoulettes = Value
end)

if UniversalInfo.IsUltima() then --I know this is easily changable, but oh well
    local function CreateClickEvent(Location, Script)
        Location.MouseButton1Down:Connect(function()
            local Env = getsenv(Script)

            Env.scroll()
            Env.selected = true
        end)
    end

    CreateClickEvent(Player.PlayerGui.Main.ReskinRoulette.Bottom.Roll, Player.PlayerGui["_G.ReskinRoulettes"])
    CreateClickEvent(Player.PlayerGui.Main.UltimateRoulette.Bottom.Roll, Player.PlayerGui["_G.UltimateRoulettes"])
    CreateClickEvent(Player.PlayerGui.Main.UpgradedRoulette.Bottom.Roll, Player.PlayerGui["_G.UpgradedRoulettes"])
    CreateClickEvent(Player.PlayerGui.Main.Roulette.Bottom.Roll, Player.PlayerGui["_G.Roulettes"])
end

--Inbattle

local Inbattle_Info = {

}

InBattle:Line()
InBattle:Label("In battle stuff", Color3.fromRGB(255, 144, 118))

InBattle:Button("Heal your pokemon fully", "Heals your pokemon fully", function(Value)
    for Index, Pokemon in next, UniversalInfo.PokemonParty:GetChildren() do
        Pokemon.CurrentHP.Value = Pokemon.Stats.HPStat.Value
    end
end)
InBattle:Button("Kill all enemy pokemon", "Kills all enemy pokemon on the battlefeild (takes 1 turn to take effect!)", function(Value)
    for Index, Pokemon in next, Player.OppPokemon:GetChildren() do
        Pokemon.CurrentHP.Value = 0
    end
end)

--Change log

ChangeLog:Label("Latest changes", Color3.fromRGB(255, 144, 118))
ChangeLog:Label("")
ChangeLog:Label("")

--Pokemon list

for Index, Pokemon in next, UniversalInfo.AllPokemon do
    PokemonList:Button(tostring(Index), "Click to copy!", function()
        setclipboard(tostring(Index))
        Flux:Notification("Added to clipboard", "ok lol")
    end)
end

--Misc

local Misc_Info = {
    Badges = {1, 2, 3, 4, 5 , 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, "Sword", "Sheild", "Eternatus", "Cherry", "Kanto Indigo", "Johto Indigo", "Hoenn Indigo", "Oldale", "Petalburg", "Stateport", "Verdanturf", "Fallarbor", "Lilycove", "Pacifidlog", "Grande", "GraniteBadge", "Aether Paradise", "JohtoChamp", "Champ", "HoennChamp", "EV", "Mysterious Grotto", "BattleTower", "Mausoleum of Origins"}
}

Misc:Line()
Misc:Label("Misc stuff", Color3.fromRGB(255, 144, 118))

Misc:Label("Get all badges only works for Ultima! (for now)")
Misc:Button("Get all badges!", "Click this button to get all the badges for Ultima (There's a 8 ish sec cooldown per badge)", function()
    for Index, Badge in next, Misc_Info.Badges do
        if not Player.Badges:FindFirstChild(tostring(Badge)) then
            UniversalInfo.InfoTable.AwardBadge(nil, tostring(Badge))
            task.wait(8 + math.random(3, 5))
        end
    end
end)
Misc:Label("A tad bit of trolling", Color3.fromRGB(255, 144, 118))
Misc:Label("Thanks to ethnicity#0001 for telling me about this method! :]")
Misc:Toggle("Bypass chat filter", "E.g fuck would normally be replaced with ####, but now it simply wont!", true, function(Value)
    Namecall_Info.BypassSwearFilter = Value
end)

--//End UI
