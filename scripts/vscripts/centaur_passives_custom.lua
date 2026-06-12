LinkLuaModifier("modifier_centaur_hoof_stomp_custom", "centaur_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_centaur_double_edge_custom", "centaur_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_centaur_return_custom", "centaur_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_centaur_stampede_custom", "centaur_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_centaur_stampede_custom_slow", "centaur_passives_custom", LUA_MODIFIER_MOTION_NONE)

centaur_hoof_stomp_custom = class({})
centaur_double_edge_custom = class({})
centaur_return_custom = class({})
centaur_stampede_custom = class({})

function centaur_hoof_stomp_custom:GetAbilityTextureName()
    return "centaur_hoof_stomp"
end

function centaur_hoof_stomp_custom:GetIntrinsicModifierName()
    return "modifier_centaur_hoof_stomp_custom"
end

function centaur_double_edge_custom:GetAbilityTextureName()
    return "centaur_double_edge"
end

function centaur_double_edge_custom:GetIntrinsicModifierName()
    return "modifier_centaur_double_edge_custom"
end

function centaur_return_custom:GetAbilityTextureName()
    return "centaur_return"
end

function centaur_return_custom:GetIntrinsicModifierName()
    return "modifier_centaur_return_custom"
end

function centaur_stampede_custom:GetAbilityTextureName()
    return "centaur_stampede"
end

function centaur_stampede_custom:GetIntrinsicModifierName()
    return "modifier_centaur_stampede_custom"
end

modifier_centaur_hoof_stomp_custom = class({})

function modifier_centaur_hoof_stomp_custom:IsHidden()
    return true
end

function modifier_centaur_hoof_stomp_custom:IsPurgable()
    return false
end

function modifier_centaur_hoof_stomp_custom:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("stomp_interval"))
end

function modifier_centaur_hoof_stomp_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetParent()

    if not ability or ability:IsNull() or ability:GetLevel() < 1 or not caster:IsAlive() then
        return
    end

    local radius = ability:GetSpecialValueFor("radius")
    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    if #enemies < 1 then
        return
    end

    caster:EmitSound("Hero_Centaur.HoofStomp")
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_warstomp.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
    ParticleManager:ReleaseParticleIndex(particle)

    for _, enemy in pairs(enemies) do
        ApplyDamage({
            victim = enemy,
            attacker = caster,
            damage = ability:GetSpecialValueFor("stomp_damage"),
            damage_type = ability:GetAbilityDamageType(),
            ability = ability
        })
        enemy:AddNewModifier(caster, ability, "modifier_stunned", { duration = ability:GetSpecialValueFor("stun_duration") })
    end
end

modifier_centaur_double_edge_custom = class({})

function modifier_centaur_double_edge_custom:IsHidden()
    return true
end

function modifier_centaur_double_edge_custom:IsPurgable()
    return false
end

function modifier_centaur_double_edge_custom:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("edge_interval"))
end

function modifier_centaur_double_edge_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetParent()

    if not ability or ability:IsNull() or ability:GetLevel() < 1 or not caster:IsAlive() then
        return
    end

    local targets = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        ability:GetSpecialValueFor("search_radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
        FIND_CLOSEST,
        false
    )

    if #targets < 1 then
        return
    end

    local target = targets[1]
    local damage = ability:GetSpecialValueFor("edge_damage") + caster:GetStrength() * ability:GetSpecialValueFor("strength_damage") / 100

    caster:EmitSound("Hero_Centaur.DoubleEdge")
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_double_edge.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:ReleaseParticleIndex(particle)

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        target:GetAbsOrigin(),
        nil,
        ability:GetSpecialValueFor("radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        ApplyDamage({
            victim = enemy,
            attacker = caster,
            damage = damage,
            damage_type = ability:GetAbilityDamageType(),
            ability = ability
        })
    end

    local self_damage = math.floor(math.min(damage, caster:GetHealth() - 1))
    if self_damage > 0 then
        caster:SetHealth(caster:GetHealth() - self_damage)
    end
end

modifier_centaur_return_custom = class({})

function modifier_centaur_return_custom:IsHidden()
    return true
end

function modifier_centaur_return_custom:IsPurgable()
    return false
end

function modifier_centaur_return_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_centaur_return_custom:OnAttackLanded(event)
    if not IsServer() or event.target ~= self:GetParent() then
        return
    end

    local ability = self:GetAbility()
    local caster = self:GetParent()
    local attacker = event.attacker

    if not ability or ability:IsNull() or ability:GetLevel() < 1 or not attacker or attacker:IsNull() then
        return
    end

    if attacker:GetTeamNumber() == caster:GetTeamNumber() or attacker:IsOther() then
        return
    end

    local damage = ability:GetSpecialValueFor("return_damage") + caster:GetStrength() * ability:GetSpecialValueFor("return_damage_str") / 100
    if attacker:IsBuilding() then
        damage = damage * 0.5
    end

    ApplyDamage({
        victim = attacker,
        attacker = caster,
        damage = damage,
        damage_type = ability:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_REFLECTION,
        ability = ability
    })
end

modifier_centaur_stampede_custom = class({})

function modifier_centaur_stampede_custom:IsHidden()
    return false
end

function modifier_centaur_stampede_custom:IsPurgable()
    return false
end

function modifier_centaur_stampede_custom:OnCreated()
    if not IsServer() then
        return
    end

    self.hit_targets = {}
    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("pulse_interval"))
end

function modifier_centaur_stampede_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetParent()

    if not ability or ability:IsNull() or ability:GetLevel() < 1 or not caster:IsAlive() then
        return
    end

    self.hit_targets = {}
    local radius = ability:GetSpecialValueFor("radius")
    local allies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        1200,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, ally in pairs(allies) do
        local enemies = FindUnitsInRadius(
            caster:GetTeamNumber(),
            ally:GetAbsOrigin(),
            nil,
            radius,
            DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER,
            false
        )

        for _, enemy in pairs(enemies) do
            local index = enemy:entindex()
            if not self.hit_targets[index] then
                self.hit_targets[index] = true
                ApplyDamage({
                    victim = enemy,
                    attacker = caster,
                    damage = caster:GetStrength() * ability:GetSpecialValueFor("strength_damage"),
                    damage_type = ability:GetAbilityDamageType(),
                    ability = ability
                })
                enemy:AddNewModifier(caster, ability, "modifier_centaur_stampede_custom_slow", {
                    duration = ability:GetSpecialValueFor("slow_duration")
                })
            end
        end
    end
end

function modifier_centaur_stampede_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT
    }
end

function modifier_centaur_stampede_custom:CheckState()
    return {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }
end

function modifier_centaur_stampede_custom:GetModifierMoveSpeedBonus_Percentage()
    local ability = self:GetAbility()
    if not ability or ability:GetLevel() < 1 then
        return 0
    end

    return ability:GetSpecialValueFor("bonus_movespeed")
end

function modifier_centaur_stampede_custom:GetModifierIgnoreMovespeedLimit()
    return 1
end

modifier_centaur_stampede_custom_slow = class({})

function modifier_centaur_stampede_custom_slow:IsDebuff()
    return true
end

function modifier_centaur_stampede_custom_slow:IsPurgable()
    return true
end

function modifier_centaur_stampede_custom_slow:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_centaur_stampede_custom_slow:GetModifierMoveSpeedBonus_Percentage()
    return -self:GetAbility():GetSpecialValueFor("slow_movement_speed")
end
