local ScriptsForPlaceId = {
    ["3891149796"] = "https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/BoogaBooga/MainGui.lua", --Booga booga
    [""] = "https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/ClickerSimulator/MainGui.lua", --Clicker Simulator
    ["601130232"] = "https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/Beeswarm%20Simulator/Beeswarm%20GUI.lua" --Beeswarm Simulator
}



local MarketplaceService = game:GetService("MarketplaceService")
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
local Script = ScriptsForPlaceId[tostring(game.GameId)]

if Script == nil and GameName:lower():find("project") then
    warn("Project pokemon game detected!, changing script to PP gui")
    Script = "https://raw.githubusercontent.com/SigurdOrUsername/ProjectsLua/main/PPGamesGUI"
end

local RanSuccessfully, Error = pcall(function()
    loadstring(game:HttpGet(Script))()
end)

if not RanSuccessfully then
    warn("Script error happened! Report to username (Username#6161) on discord: \n" .. Error)
else
    warn("Executed script successfully!")
end
