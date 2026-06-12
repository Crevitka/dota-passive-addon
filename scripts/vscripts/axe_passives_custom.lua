LinkLuaModifier("modifier_axe_berserkers_call_custom", "axe_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_berserkers_call_custom_armor", "axe_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_berserkers_call_custom_taunt", "axe_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_battle_hunger_custom", "axe_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_battle_hunger_custom_debuff", "axe_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_counter_helix_custom", "axe_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_culling_blade_custom", "axe_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_culling_blade_custom_buff", "axe_passives_custom", LUA_MODIFIER_MOTION_NONE)

axe_berserkers_call_custom = class({})
axe_battle_hunger_custom = class({})
axe_counter_helix_custom = class({})
axe_culling_blade_custom = class({})

function axe_berserkers_call_custom:GetAbilityTextureName()
    return "axe_berserkers_call"
end

function axe_berserkers_call_custom:GetIntrinsicModifierName()
    return "modifier_axe_berserkers_call_custom"
end

function axe_battle_hunger_custom:GetAbilityTextureName()
    return "axe_battle_hunger"
end

function axe_battle_hunger_custom:GetIntrinsicModifierName()
    return "modifier_axe_battle_hunger_custom"
end

function axe_counter_helix_custom:GetAbilityTextureName()
    return "axe_counter_helix"
end

function axe_counter_helix_custom:GetIntrinsicModifierName()
    return "modifier_axe_counter_helix_custom"
end

function axe_culling_blade_custom:GetAbilityTextureName()
    return "axe_culling_blade"
end

function axe_culling_blade_custom:GetIntrinsicModifierName()
    return "modifier_axe_culling_blade_custom"
end

modifier_axe_berserkers_call_custom = class({})

function modifier_axe_berserkers_call_custom:IsHidden()
    return true
end

function modifier_axe_berserkers_call_custom:IsPurgable()
    return false
end

function modifier_axe_berserkers_call_custom:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("call_interval"))
end

function modifier_axe_berserkers_call_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetParent()

    if not ability or ability:IsNull() or ability:GetLevel() < 1 or not caster:IsAlive() then
        return
    end

    local radius = ability:GetSpecialValueFor("radius")
    local duration = ability:GetSpecialValueFor("duration")
    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        FIND_ANY_ORDER,
        false
    )

    if #enemies < 1 then
        return
    end

    caster:AddNewModifier(caster, ability, "modifier_axe_berserkers_call_custom_armor", { duration = duration })
    caster:EmitSound("Hero_Axe.Berserkers_Call")

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:ReleaseParticleIndex(particle)

    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(caster, ability, "modifier_axe_berserkers_call_custom_taunt", { duration = duration })
    end
end

modifier_axe_berserkers_call_custom_armor = class({})

function modifier_axe_berserkers_call_custom_armor:IsPurgable()
    return false
end

function modifier_axe_berserkers_call_custom_armor:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end

function modifier_axe_berserkers_call_custom_armor:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

modifier_axe_berserkers_call_custom_taunt = class({})

function modifier_axe_berserkers_call_custom_taunt:IsDebuff()
    return true
end

function modifier_axe_berserkers_call_custom_taunt:IsPurgable()
    return false
end

function modifier_axe_berserkers_call_custom_taunt:OnCreated()
    if not IsServer() then
        return
    end

    self:GetParent():SetForceAttackTarget(self:GetCaster())
end

function modifier_axe_berserkers_call_custom_taunt:OnDestroy()
    if not IsServer() then
        return
    end

    self:GetParent():SetForceAttackTarget(nil)
end

function modifier_axe_berserkers_call_custom_taunt:CheckState()
    return {
        [MODIFIER_STATE_TAUNTED] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true
    }
end

modifier_axe_battle_hunger_custom = class({})

function modifier_axe_battle_hunger_custom:IsHidden()
    return true
end

function modifier_axe_battle_hunger_custom:IsPurgable()
    return false
end

function modifier_axe_battle_hunger_custom:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("apply_interval"))
end

function modifier_axe_battle_hunger_custom:OnIntervalThink()
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
    target:AddNewModifier(caster, ability, "modifier_axe_battle_hunger_custom_debuff", {
        duration = ability:GetSpecialValueFor("duration")
    })
    caster:EmitSound("Hero_Axe.Battle_Hunger")
end

modifier_axe_battle_hunger_custom_debuff = class({})

function modifier_axe_battle_hunger_custom_debuff:IsDebuff()
    return true
end

function modifier_axe_battle_hunger_custom_debuff:IsPurgable()
    return true
end

function modifier_axe_battle_hunger_custom_debuff:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(1.0)
end

function modifier_axe_battle_hunger_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_axe_battle_hunger_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_axe_battle_hunger_custom_debuff:OnDeath(event)
    if not IsServer() then
        return
    end

    if event.attacker == self:GetParent() then
        self:Destroy()
    end
end

function modifier_axe_battle_hunger_custom_debuff:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetCaster()

    ApplyDamage({
        victim = self:GetParent(),
        attacker = caster,
        damage = ability:GetSpecialValueFor("damage_per_second"),
        damage_type = ability:GetAbilityDamageType(),
        ability = ability
    })
end

modifier_axe_counter_helix_custom = class({})

function modifier_axe_counter_helix_custom:IsHidden()
    return true
end

function modifier_axe_counter_helix_custom:IsPurgable()
    return false
end

function modifier_axe_counter_helix_custom:OnCreated()
    self.attack_count = 0
    self.last_spin_time = -999
end

function modifier_axe_counter_helix_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_axe_counter_helix_custom:OnAttackLanded(event)
    if not IsServer() or event.target ~= self:GetParent() then
        return
    end

    local ability = self:GetAbility()
    local caster = self:GetParent()
    if not ability or ability:IsNull() or ability:GetLevel() < 1 or event.attacker:GetTeamNumber() == caster:GetTeamNumber() then
        return
    end

    if event.attacker:IsBuilding() or event.attacker:IsOther() then
        return
    end

    self.attack_count = self.attack_count + 1
    if self.attack_count < ability:GetSpecialValueFor("trigger_attacks") then
        return
    end

    if GameRules:GetGameTime() - self.last_spin_time < ability:GetSpecialValueFor("helix_cooldown") then
        return
    end

    self.attack_count = 0
    self.last_spin_time = GameRules:GetGameTime()

    local radius = ability:GetSpecialValueFor("radius")
    caster:EmitSound("Hero_Axe.CounterHelix")
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_counterhelix.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:ReleaseParticleIndex(particle)

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        ApplyDamage({
            victim = enemy,
            attacker = caster,
            damage = ability:GetSpecialValueFor("damage"),
            damage_type = ability:GetAbilityDamageType(),
            ability = ability
        })
    end
end

modifier_axe_culling_blade_custom = class({})

function modifier_axe_culling_blade_custom:IsHidden()
    return true
end

function modifier_axe_culling_blade_custom:IsPurgable()
    return false
end

function modifier_axe_culling_blade_custom:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("scan_interval"))
end

function modifier_axe_culling_blade_custom:OnIntervalThink()
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
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        FIND_CLOSEST,
        false
    )

    for _, enemy in pairs(enemies) do
        if enemy:GetHealth() <= ability:GetSpecialValueFor("damage") then
            caster:EmitSound("Hero_Axe.Culling_Blade_Success")
            local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
            ParticleManager:ReleaseParticleIndex(particle)
            enemy:Kill(ability, caster)
            self:ApplyCullingBuffs()
            return
        end
    end
end

function modifier_axe_culling_blade_custom:ApplyCullingBuffs()
    local ability = self:GetAbility()
    local caster = self:GetParent()
    local allies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        ability:GetSpecialValueFor("speed_aoe"),
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, ally in pairs(allies) do
        ally:AddNewModifier(caster, ability, "modifier_axe_culling_blade_custom_buff", {
            duration = ability:GetSpecialValueFor("speed_duration")
        })
    end
end

modifier_axe_culling_blade_custom_buff = class({})

function modifier_axe_culling_blade_custom_buff:IsPurgable()
    return true
end

function modifier_axe_culling_blade_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end

function modifier_axe_culling_blade_custom_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("speed_bonus")
end

function modifier_axe_culling_blade_custom_buff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("speed_bonus")
end

function modifier_axe_culling_blade_custom_buff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("armor_bonus")
end
