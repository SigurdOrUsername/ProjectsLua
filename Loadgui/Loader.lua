local ScriptsForPlaceId = {
}



local MarketplaceService = game:GetService("MarketplaceService")
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
local Script = ScriptsForPlaceId[game.PlaceId]

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
