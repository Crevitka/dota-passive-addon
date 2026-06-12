addon_game_mode = class({})

function addon_game_mode:InitGameMode()
    print("passive addon_game_mode loaded")
end

function Activate()
    GameRules.Addon = addon_game_mode()
    GameRules.Addon:InitGameMode()
end
