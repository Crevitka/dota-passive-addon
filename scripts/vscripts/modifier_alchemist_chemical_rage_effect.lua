modifier_alchemist_chemical_rage_effect = class({})

local function GetAbilitySpecialValue(modifier, value_name, fallback, level_values)
    local ability = modifier:GetAbility()
    if ability then
        local value = ability:GetSpecialValueFor(value_name)
        if value and value ~= 0 then
            return value
        end

        local level = math.max(ability:GetLevel() - 1, 0)
        local level_value = ability:GetLevelSpecialValueFor(value_name, level)
        if level_value and level_value ~= 0 then
            return level_value
        end
    end

    if level_values then
        local ability_level = ability and math.max(ability:GetLevel(), 1) or 1
        return level_values[ability_level] or fallback
    end

    return fallback
end

function modifier_alchemist_chemical_rage_effect:IsHidden()
    return false
end

function modifier_alchemist_chemical_rage_effect:IsPurgable()
    return false
end

function modifier_alchemist_chemical_rage_effect:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_alchemist_chemical_rage_effect:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS
    }
end

function modifier_alchemist_chemical_rage_effect:GetModifierBaseAttackTimeConstant()
    return GetAbilitySpecialValue(self, "base_attack_time", 1.2, { 1.2, 1.1, 1.0 })
end

function modifier_alchemist_chemical_rage_effect:GetModifierMoveSpeedBonus_Constant()
    return GetAbilitySpecialValue(self, "bonus_movespeed", 20, { 20, 30, 40 })
end

function modifier_alchemist_chemical_rage_effect:GetModifierConstantHealthRegen()
    return GetAbilitySpecialValue(self, "bonus_health_regen", 50, { 50, 85, 120 })
end

function modifier_alchemist_chemical_rage_effect:GetActivityTranslationModifiers()
    return "chemical_rage"
end

function modifier_alchemist_chemical_rage_effect:GetEffectName()
    return "particles/units/heroes/hero_alchemist/alchemist_chemical_rage.vpcf"
end

function modifier_alchemist_chemical_rage_effect:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_alchemist_chemical_rage_effect:OnCreated()
    if not IsServer() then
        return
    end

    self:GetParent():EmitSound("Hero_Alchemist.ChemicalRage")
end

function modifier_alchemist_chemical_rage_effect:OnDestroy()
    if not IsServer() then
        return
    end

    self:GetParent():StopSound("Hero_Alchemist.ChemicalRage")
end
