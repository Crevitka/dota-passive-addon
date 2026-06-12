LinkLuaModifier("modifier_alchemist_chemical_rage_effect", "modifier_alchemist_chemical_rage_effect", LUA_MODIFIER_MOTION_NONE)

alchemist_chemical_rage_custom = class({})

function alchemist_chemical_rage_custom:GetAbilityTextureName()
    return "alchemist_chemical_rage"
end

function alchemist_chemical_rage_custom:GetIntrinsicModifierName()
    return "modifier_alchemist_chemical_rage_effect"
end
