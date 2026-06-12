LinkLuaModifier("modifier_chen_penitence_custom", "chen_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chen_penitence_custom_debuff", "chen_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chen_penitence_custom_attack_buff", "chen_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chen_holy_persuasion_custom", "chen_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chen_holy_persuasion_custom_convert", "chen_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chen_divine_favor_custom", "chen_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chen_divine_favor_custom_aura", "chen_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chen_hand_of_god_custom", "chen_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chen_hand_of_god_custom_hot", "chen_passives_custom", LUA_MODIFIER_MOTION_NONE)

chen_penitence_custom = class({})
chen_holy_persuasion_custom = class({})
chen_divine_favor_custom = class({})
chen_hand_of_god_custom = class({})

function chen_penitence_custom:GetAbilityTextureName()
    return "chen_penitence"
end

function chen_penitence_custom:GetIntrinsicModifierName()
    return "modifier_chen_penitence_custom"
end

function chen_holy_persuasion_custom:GetAbilityTextureName()
    return "chen_holy_persuasion"
end

function chen_holy_persuasion_custom:GetIntrinsicModifierName()
    return "modifier_chen_holy_persuasion_custom"
end

function chen_divine_favor_custom:GetAbilityTextureName()
    return "chen_divine_favor"
end

function chen_divine_favor_custom:GetIntrinsicModifierName()
    return "modifier_chen_divine_favor_custom"
end

function chen_hand_of_god_custom:GetAbilityTextureName()
    return "chen_hand_of_god"
end

function chen_hand_of_god_custom:GetIntrinsicModifierName()
    return "modifier_chen_hand_of_god_custom"
end

modifier_chen_penitence_custom = class({})

function modifier_chen_penitence_custom:IsHidden()
    return true
end

function modifier_chen_penitence_custom:IsPurgable()
    return false
end

function modifier_chen_penitence_custom:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("penitence_interval"))
end

function modifier_chen_penitence_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetParent()

    if not ability or ability:IsNull() or ability:GetLevel() < 1 or not caster:IsAlive() then
        return
    end

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        ability:GetSpecialValueFor("search_radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
        FIND_ANY_ORDER,
        false
    )

    if #enemies < 1 then
        return
    end

    local target = enemies[RandomInt(1, #enemies)]
    caster:EmitSound("Hero_Chen.PenitenceCast")
    ApplyDamage({
        victim = target,
        attacker = caster,
        damage = ability:GetSpecialValueFor("damage"),
        damage_type = ability:GetAbilityDamageType(),
        ability = ability
    })
    target:AddNewModifier(caster, ability, "modifier_chen_penitence_custom_debuff", {
        duration = ability:GetSpecialValueFor("duration")
    })
    caster:AddNewModifier(caster, ability, "modifier_chen_penitence_custom_attack_buff", {
        duration = ability:GetSpecialValueFor("duration")
    })
end

modifier_chen_penitence_custom_debuff = class({})

function modifier_chen_penitence_custom_debuff:IsDebuff()
    return true
end

function modifier_chen_penitence_custom_debuff:IsPurgable()
    return true
end

function modifier_chen_penitence_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_chen_penitence_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
end

modifier_chen_penitence_custom_attack_buff = class({})

function modifier_chen_penitence_custom_attack_buff:IsPurgable()
    return true
end

function modifier_chen_penitence_custom_attack_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end

function modifier_chen_penitence_custom_attack_buff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

modifier_chen_holy_persuasion_custom = class({})

function modifier_chen_holy_persuasion_custom:IsHidden()
    return true
end

function modifier_chen_holy_persuasion_custom:IsPurgable()
    return false
end

function modifier_chen_holy_persuasion_custom:OnCreated()
    if not IsServer() then
        return
    end

    self.converts = {}
    self:StartIntervalThink(1.0)
end

function modifier_chen_holy_persuasion_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetParent()

    if not ability or ability:IsNull() or ability:GetLevel() < 1 or not caster:IsAlive() then
        return
    end

    self:RemoveDeadConverts()
    if #self.converts >= ability:GetSpecialValueFor("max_units") then
        return
    end

    if self.next_summon_time and GameRules:GetGameTime() < self.next_summon_time then
        return
    end

    self.next_summon_time = GameRules:GetGameTime() + ability:GetSpecialValueFor("summon_interval")
    local unit_name = caster:GetTeamNumber() == DOTA_TEAM_GOODGUYS and "npc_dota_chen_zealot_goodguys" or "npc_dota_chen_zealot_badguys"
    local convert = CreateUnitByName(unit_name, caster:GetAbsOrigin() + RandomVector(160), true, caster, caster, caster:GetTeamNumber())
    if not convert then
        return
    end

    convert:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
    convert:SetOwner(caster)
    convert:AddNewModifier(caster, ability, "modifier_chen_holy_persuasion_custom_convert", {})
    table.insert(self.converts, convert)
    caster:EmitSound("Hero_Chen.HolyPersuasionCast")
end

function modifier_chen_holy_persuasion_custom:RemoveDeadConverts()
    local alive = {}
    for _, convert in pairs(self.converts or {}) do
        if convert and not convert:IsNull() and convert:IsAlive() then
            table.insert(alive, convert)
        end
    end

    self.converts = alive
end

modifier_chen_holy_persuasion_custom_convert = class({})

function modifier_chen_holy_persuasion_custom_convert:IsPurgable()
    return false
end

function modifier_chen_holy_persuasion_custom_convert:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
    }
end

function modifier_chen_holy_persuasion_custom_convert:GetModifierExtraHealthBonus()
    return self:GetAbility():GetSpecialValueFor("health_min")
end

function modifier_chen_holy_persuasion_custom_convert:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("movement_speed_bonus")
end

function modifier_chen_holy_persuasion_custom_convert:GetModifierBaseDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_bonus")
end

modifier_chen_divine_favor_custom = class({})

function modifier_chen_divine_favor_custom:IsHidden()
    return true
end

function modifier_chen_divine_favor_custom:IsPurgable()
    return false
end

function modifier_chen_divine_favor_custom:IsAura()
    return true
end

function modifier_chen_divine_favor_custom:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_chen_divine_favor_custom:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_chen_divine_favor_custom:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_chen_divine_favor_custom:GetModifierAura()
    return "modifier_chen_divine_favor_custom_aura"
end

modifier_chen_divine_favor_custom_aura = class({})

function modifier_chen_divine_favor_custom_aura:IsPurgable()
    return false
end

function modifier_chen_divine_favor_custom_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET
    }
end

function modifier_chen_divine_favor_custom_aura:GetModifierConstantHealthRegen()
    return self:GetAbility():GetSpecialValueFor("heal_rate")
end

function modifier_chen_divine_favor_custom_aura:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_chen_divine_favor_custom_aura:GetModifierHealAmplify_PercentageTarget()
    return self:GetAbility():GetSpecialValueFor("heal_amp")
end

modifier_chen_hand_of_god_custom = class({})

function modifier_chen_hand_of_god_custom:IsHidden()
    return true
end

function modifier_chen_hand_of_god_custom:IsPurgable()
    return false
end

function modifier_chen_hand_of_god_custom:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("heal_interval"))
end

function modifier_chen_hand_of_god_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetParent()

    if not ability or ability:IsNull() or ability:GetLevel() < 1 or not caster:IsAlive() then
        return
    end

    local allies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        FIND_UNITS_EVERYWHERE,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
        FIND_ANY_ORDER,
        false
    )

    caster:EmitSound("Hero_Chen.HandOfGodHealHero")
    for _, ally in pairs(allies) do
        ally:Heal(ability:GetSpecialValueFor("heal_amount"), ability)
        ally:AddNewModifier(caster, ability, "modifier_chen_hand_of_god_custom_hot", {
            duration = ability:GetSpecialValueFor("hot_duration")
        })
    end
end

modifier_chen_hand_of_god_custom_hot = class({})

function modifier_chen_hand_of_god_custom_hot:IsPurgable()
    return true
end

function modifier_chen_hand_of_god_custom_hot:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(1.0)
end

function modifier_chen_hand_of_god_custom_hot:OnIntervalThink()
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
        self:GetParent():Heal(ability:GetSpecialValueFor("heal_per_second"), ability)
    end
end

function modifier_chen_hand_of_god_custom_hot:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_chen_hand_of_god_custom_hot:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("heal_per_second")
end
