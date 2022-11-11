local ScriptsForPlaceId = {
    ["3891149796"] = "https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/BoogaBooga/MainGui.lua", --Booga booga
    [""] = "https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/ClickerSimulator/MainGui.lua" --Clicker Simulator
}



local MarketplaceService = game:GetService("MarketplaceService")
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
local Script = ScriptsForPlaceId[tostring(game.GameId)]

if Script == nil and GameName:lower():find("project") then
    warn("Project pokemon game detected!, changing script to PP gui")
    Script = "https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/PPGames/MainGui.lua"
end

local RanSuccessfully, Error = pcall(function()
    --Introvers bypasse(s), for adonis. Full credit goes to Introvert#1337
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if string.match(getinfo(3, "s").source, "ClientMover") and getnamecallmethod() == "GetService" then
            return
        end

        return oldNamecall(self, ...)
    end)
    replaceclosure(game:GetService("Players").LocalPlayer.Kick, function() end)

    loadstring(game:HttpGet(Script))()
end)

if not RanSuccessfully then
    warn("Script error happened! Report to username (Username#6161) on discord: \n" .. Error)
else
    warn("Executed script successfully!")
end
