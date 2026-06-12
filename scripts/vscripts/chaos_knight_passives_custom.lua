LinkLuaModifier("modifier_chaos_knight_chaos_bolt_custom", "chaos_knight_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chaos_knight_reality_rift_custom", "chaos_knight_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chaos_knight_reality_rift_custom_debuff", "chaos_knight_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chaos_knight_chaos_strike_custom", "chaos_knight_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chaos_knight_phantasm_custom", "chaos_knight_passives_custom", LUA_MODIFIER_MOTION_NONE)

chaos_knight_chaos_bolt_custom = class({})
chaos_knight_reality_rift_custom = class({})
chaos_knight_chaos_strike_custom = class({})
chaos_knight_phantasm_custom = class({})

function chaos_knight_chaos_bolt_custom:GetAbilityTextureName()
    return "chaos_knight_chaos_bolt"
end

function chaos_knight_chaos_bolt_custom:GetIntrinsicModifierName()
    return "modifier_chaos_knight_chaos_bolt_custom"
end

function chaos_knight_reality_rift_custom:GetAbilityTextureName()
    return "chaos_knight_reality_rift"
end

function chaos_knight_reality_rift_custom:GetIntrinsicModifierName()
    return "modifier_chaos_knight_reality_rift_custom"
end

function chaos_knight_chaos_strike_custom:GetAbilityTextureName()
    return "chaos_knight_chaos_strike"
end

function chaos_knight_chaos_strike_custom:GetIntrinsicModifierName()
    return "modifier_chaos_knight_chaos_strike_custom"
end

function chaos_knight_phantasm_custom:GetAbilityTextureName()
    return "chaos_knight_phantasm"
end

function chaos_knight_phantasm_custom:GetIntrinsicModifierName()
    return "modifier_chaos_knight_phantasm_custom"
end

local function FindRandomVisibleEnemy(caster, radius)
    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
        FIND_ANY_ORDER,
        false
    )

    if #enemies < 1 then
        return nil
    end

    return enemies[RandomInt(1, #enemies)]
end

modifier_chaos_knight_chaos_bolt_custom = class({})

function modifier_chaos_knight_chaos_bolt_custom:IsHidden()
    return true
end

function modifier_chaos_knight_chaos_bolt_custom:IsPurgable()
    return false
end

function modifier_chaos_knight_chaos_bolt_custom:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("bolt_interval"))
end

function modifier_chaos_knight_chaos_bolt_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetParent()

    if not ability or ability:IsNull() or ability:GetLevel() < 1 or not caster:IsAlive() then
        return
    end

    local target = FindRandomVisibleEnemy(caster, ability:GetSpecialValueFor("search_radius"))
    if not target then
        return
    end

    local stun = RandomFloat(ability:GetSpecialValueFor("stun_min"), ability:GetSpecialValueFor("stun_max"))
    local damage = RandomInt(ability:GetSpecialValueFor("damage_min"), ability:GetSpecialValueFor("damage_max"))

    caster:EmitSound("Hero_ChaosKnight.ChaosBolt.Cast")
    target:EmitSound("Hero_ChaosKnight.ChaosBolt")
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_chaos_bolt.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:ReleaseParticleIndex(particle)

    ApplyDamage({
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = ability:GetAbilityDamageType(),
        ability = ability
    })
    target:AddNewModifier(caster, ability, "modifier_stunned", { duration = stun })
end

modifier_chaos_knight_reality_rift_custom = class({})

function modifier_chaos_knight_reality_rift_custom:IsHidden()
    return true
end

function modifier_chaos_knight_reality_rift_custom:IsPurgable()
    return false
end

function modifier_chaos_knight_reality_rift_custom:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("rift_interval"))
end

function modifier_chaos_knight_reality_rift_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetParent()

    if not ability or ability:IsNull() or ability:GetLevel() < 1 or not caster:IsAlive() then
        return
    end

    local target = FindRandomVisibleEnemy(caster, ability:GetSpecialValueFor("search_radius"))
    if not target then
        return
    end

    local caster_origin = caster:GetAbsOrigin()
    local target_origin = target:GetAbsOrigin()
    local direction = target_origin - caster_origin
    direction.z = 0

    if direction:Length2D() < 1 then
        return
    end

    direction = direction:Normalized()
    local midpoint = caster_origin + direction * math.min(ability:GetSpecialValueFor("pull_distance"), (target_origin - caster_origin):Length2D() / 2)

    caster:EmitSound("Hero_ChaosKnight.RealityRift")
    FindClearSpaceForUnit(caster, midpoint - direction * 64, true)
    FindClearSpaceForUnit(target, midpoint + direction * 64, true)
    caster:MoveToTargetToAttack(target)
    target:AddNewModifier(caster, ability, "modifier_chaos_knight_reality_rift_custom_debuff", {
        duration = ability:GetSpecialValueFor("duration")
    })
end

modifier_chaos_knight_reality_rift_custom_debuff = class({})

function modifier_chaos_knight_reality_rift_custom_debuff:IsDebuff()
    return true
end

function modifier_chaos_knight_reality_rift_custom_debuff:IsPurgable()
    return true
end

function modifier_chaos_knight_reality_rift_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end

function modifier_chaos_knight_reality_rift_custom_debuff:GetModifierPhysicalArmorBonus()
    return -self:GetAbility():GetSpecialValueFor("armor_reduction")
end

modifier_chaos_knight_chaos_strike_custom = class({})

function modifier_chaos_knight_chaos_strike_custom:IsHidden()
    return true
end

function modifier_chaos_knight_chaos_strike_custom:IsPurgable()
    return false
end

function modifier_chaos_knight_chaos_strike_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_chaos_knight_chaos_strike_custom:GetModifierPreAttack_CriticalStrike()
    local ability = self:GetAbility()
    if not ability or ability:GetLevel() < 1 then
        return nil
    end

    if RandomFloat(0, 100) <= ability:GetSpecialValueFor("chance") then
        self.record = true
        return RandomInt(ability:GetSpecialValueFor("crit_min"), ability:GetSpecialValueFor("crit_max"))
    end

    self.record = false
    return nil
end

function modifier_chaos_knight_chaos_strike_custom:OnAttackLanded(event)
    if not IsServer() or event.attacker ~= self:GetParent() or not self.record then
        return
    end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() or event.target:IsBuilding() then
        return
    end

    local heal = event.damage * ability:GetSpecialValueFor("lifesteal") / 100
    event.attacker:Heal(heal, ability)
    event.attacker:EmitSound("Hero_ChaosKnight.ChaosStrike")
    self.record = false
end

modifier_chaos_knight_phantasm_custom = class({})

function modifier_chaos_knight_phantasm_custom:IsHidden()
    return true
end

function modifier_chaos_knight_phantasm_custom:IsPurgable()
    return false
end

function modifier_chaos_knight_phantasm_custom:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("phantasm_interval"))
end

function modifier_chaos_knight_phantasm_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetParent()

    if not ability or ability:IsNull() or ability:GetLevel() < 1 or not caster:IsAlive() then
        return
    end

    caster:EmitSound("Hero_ChaosKnight.Phantasm")
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_phantasm.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:ReleaseParticleIndex(particle)

    local illusions = CreateIllusions(caster, caster, {
        outgoing_damage = ability:GetSpecialValueFor("outgoing_damage"),
        incoming_damage = ability:GetSpecialValueFor("incoming_damage"),
        duration = ability:GetSpecialValueFor("illusion_duration")
    }, ability:GetSpecialValueFor("images_count"), 72, true, true)

    for _, illusion in pairs(illusions or {}) do
        illusion:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
    end
end
