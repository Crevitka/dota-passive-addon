LinkLuaModifier("modifier_broodmother_insatiable_hunger_custom", "broodmother_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_broodmother_spin_web_custom", "broodmother_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_broodmother_incapacitating_bite_custom", "broodmother_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_broodmother_incapacitating_bite_custom_debuff", "broodmother_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_broodmother_spawn_spiderlings_custom", "broodmother_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_broodmother_spawn_spiderlings_custom_debuff", "broodmother_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_broodmother_spawn_spiderlings_custom_slow", "broodmother_passives_custom", LUA_MODIFIER_MOTION_NONE)

broodmother_insatiable_hunger_custom = class({})
broodmother_spin_web_custom = class({})
broodmother_incapacitating_bite_custom = class({})
broodmother_spawn_spiderlings_custom = class({})

function broodmother_insatiable_hunger_custom:GetAbilityTextureName()
    return "broodmother_insatiable_hunger"
end

function broodmother_insatiable_hunger_custom:GetIntrinsicModifierName()
    return "modifier_broodmother_insatiable_hunger_custom"
end

function broodmother_spin_web_custom:GetAbilityTextureName()
    return "broodmother_spin_web"
end

function broodmother_spin_web_custom:GetIntrinsicModifierName()
    return "modifier_broodmother_spin_web_custom"
end

function broodmother_incapacitating_bite_custom:GetAbilityTextureName()
    return "broodmother_incapacitating_bite"
end

function broodmother_incapacitating_bite_custom:GetIntrinsicModifierName()
    return "modifier_broodmother_incapacitating_bite_custom"
end

function broodmother_spawn_spiderlings_custom:GetAbilityTextureName()
    return "broodmother_spawn_spiderlings"
end

function broodmother_spawn_spiderlings_custom:GetIntrinsicModifierName()
    return "modifier_broodmother_spawn_spiderlings_custom"
end

function broodmother_spawn_spiderlings_custom:InfectTarget(target)
    local caster = self:GetCaster()
    if not target or target:IsNull() or not target:IsAlive() then
        return
    end

    target:AddNewModifier(caster, self, "modifier_broodmother_spawn_spiderlings_custom_debuff", {
        duration = self:GetSpecialValueFor("buff_duration")
    })
    target:AddNewModifier(caster, self, "modifier_broodmother_spawn_spiderlings_custom_slow", {
        duration = self:GetSpecialValueFor("slow_duration")
    })

    ApplyDamage({
        victim = target,
        attacker = caster,
        damage = self:GetSpecialValueFor("damage"),
        damage_type = self:GetAbilityDamageType(),
        ability = self
    })

    target:EmitSound("Hero_Broodmother.SpawnSpiderlingsImpact")
end

modifier_broodmother_insatiable_hunger_custom = class({})

function modifier_broodmother_insatiable_hunger_custom:IsHidden()
    return false
end

function modifier_broodmother_insatiable_hunger_custom:IsPurgable()
    return false
end

function modifier_broodmother_insatiable_hunger_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_broodmother_insatiable_hunger_custom:GetModifierBaseDamageOutgoing_Percentage()
    local ability = self:GetAbility()
    if not ability or ability:GetLevel() < 1 then
        return 0
    end

    return ability:GetSpecialValueFor("bonus_damage")
end

function modifier_broodmother_insatiable_hunger_custom:OnAttackLanded(event)
    if not IsServer() or event.attacker ~= self:GetParent() then
        return
    end

    local ability = self:GetAbility()
    if not ability or ability:GetLevel() < 1 or event.target:IsBuilding() then
        return
    end

    local lifesteal = ability:GetSpecialValueFor("lifesteal_pct")
    local heal = event.damage * lifesteal / 100
    self:GetParent():Heal(heal, ability)
end

function modifier_broodmother_insatiable_hunger_custom:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("lifesteal_pct")
end

modifier_broodmother_spin_web_custom = class({})

function modifier_broodmother_spin_web_custom:IsHidden()
    return false
end

function modifier_broodmother_spin_web_custom:IsPurgable()
    return false
end

function modifier_broodmother_spin_web_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT
    }
end

function modifier_broodmother_spin_web_custom:CheckState()
    return {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
    }
end

function modifier_broodmother_spin_web_custom:GetModifierMoveSpeedBonus_Percentage()
    local ability = self:GetAbility()
    if not ability or ability:GetLevel() < 1 then
        return 0
    end

    return ability:GetSpecialValueFor("bonus_movespeed")
end

function modifier_broodmother_spin_web_custom:GetModifierTurnRate_Percentage()
    local ability = self:GetAbility()
    if not ability or ability:GetLevel() < 1 then
        return 0
    end

    return ability:GetSpecialValueFor("bonus_turn_rate") * 100
end

function modifier_broodmother_spin_web_custom:GetModifierIgnoreMovespeedLimit()
    return 1
end

modifier_broodmother_incapacitating_bite_custom = class({})

function modifier_broodmother_incapacitating_bite_custom:IsHidden()
    return true
end

function modifier_broodmother_incapacitating_bite_custom:IsPurgable()
    return false
end

function modifier_broodmother_incapacitating_bite_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
    }
end

function modifier_broodmother_incapacitating_bite_custom:GetModifierPreAttack_BonusDamage()
    local ability = self:GetAbility()
    if not ability or ability:GetLevel() < 1 then
        return 0
    end

    return ability:GetSpecialValueFor("attack_damage")
end

function modifier_broodmother_incapacitating_bite_custom:OnAttackLanded(event)
    if not IsServer() or event.attacker ~= self:GetParent() then
        return
    end

    local ability = self:GetAbility()
    if not ability or ability:GetLevel() < 1 or not event.target:IsAlive() then
        return
    end

    event.target:AddNewModifier(event.attacker, ability, "modifier_broodmother_incapacitating_bite_custom_debuff", {
        duration = ability:GetSpecialValueFor("duration")
    })
end

modifier_broodmother_incapacitating_bite_custom_debuff = class({})

function modifier_broodmother_incapacitating_bite_custom_debuff:IsDebuff()
    return true
end

function modifier_broodmother_incapacitating_bite_custom_debuff:IsPurgable()
    return true
end

function modifier_broodmother_incapacitating_bite_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MISS_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_broodmother_incapacitating_bite_custom_debuff:GetModifierMiss_Percentage()
    return self:GetAbility():GetSpecialValueFor("miss_chance")
end

function modifier_broodmother_incapacitating_bite_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_movespeed")
end

modifier_broodmother_spawn_spiderlings_custom = class({})

function modifier_broodmother_spawn_spiderlings_custom:IsHidden()
    return true
end

function modifier_broodmother_spawn_spiderlings_custom:IsPurgable()
    return false
end

function modifier_broodmother_spawn_spiderlings_custom:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("spawn_interval"))
end

function modifier_broodmother_spawn_spiderlings_custom:OnIntervalThink()
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

    if #enemies > 0 then
        ability:InfectTarget(enemies[RandomInt(1, #enemies)])
    end
end

modifier_broodmother_spawn_spiderlings_custom_debuff = class({})

function modifier_broodmother_spawn_spiderlings_custom_debuff:IsDebuff()
    return true
end

function modifier_broodmother_spawn_spiderlings_custom_debuff:IsPurgable()
    return true
end

function modifier_broodmother_spawn_spiderlings_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_broodmother_spawn_spiderlings_custom_debuff:OnDeath(event)
    if not IsServer() or event.unit ~= self:GetParent() then
        return
    end

    local ability = self:GetAbility()
    local caster = self:GetCaster()
    if not ability or ability:IsNull() or not caster or caster:IsNull() then
        return
    end

    local count = ability:GetSpecialValueFor("count")
    local duration = ability:GetSpecialValueFor("spiderling_duration")
    local origin = event.unit:GetAbsOrigin()

    for i = 1, count do
        local spider = CreateUnitByName("npc_dota_broodmother_spiderling", origin + RandomVector(RandomInt(80, 140)), true, caster, caster, caster:GetTeamNumber())
        if spider then
            spider:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
            spider:AddNewModifier(caster, ability, "modifier_kill", { duration = duration })
        end
    end
end

modifier_broodmother_spawn_spiderlings_custom_slow = class({})

function modifier_broodmother_spawn_spiderlings_custom_slow:IsDebuff()
    return true
end

function modifier_broodmother_spawn_spiderlings_custom_slow:IsPurgable()
    return true
end

function modifier_broodmother_spawn_spiderlings_custom_slow:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_broodmother_spawn_spiderlings_custom_slow:GetModifierMoveSpeedBonus_Percentage()
    return -self:GetAbility():GetSpecialValueFor("movement_speed")
end
