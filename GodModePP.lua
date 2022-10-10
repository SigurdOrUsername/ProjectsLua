local function GodMode(Pokemon)
    Pokemon:WaitForChild("CurrentHP").Value = Pokemon.Stats.HPStat.Value
end

for Index, Pokemon in next, Player.PokemonParty:GetChildren() do
    Pokemon:WaitForChild("CurrentHP"):GetPropertyChangedSignal("Value"):Connect(function()
        GodMode(Pokemon)
    end)
end

Player.PokemonParty.ChildAdded:Connect(function(Child)
    Child:WaitForChild("CurrentHP"):GetPropertyChangedSignal("Value"):Connect(function()
        GodMode(Child)
    end)
end)
