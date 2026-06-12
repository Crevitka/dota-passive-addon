LinkLuaModifier("modifier_alchemist_unstable_concoction_custom", "alchemist_unstable_concoction_custom", LUA_MODIFIER_MOTION_NONE)

alchemist_unstable_concoction_custom = class({})

function alchemist_unstable_concoction_custom:GetAbilityTextureName()
    return "alchemist_unstable_concoction"
end

function alchemist_unstable_concoction_custom:GetIntrinsicModifierName()
    return "modifier_alchemist_unstable_concoction_custom"
end

function alchemist_unstable_concoction_custom:LaunchConcoction(target)
    local caster = self:GetCaster()

    ProjectileManager:CreateTrackingProjectile({
        Target = target,
        Source = caster,
        Ability = self,
        EffectName = "particles/units/heroes/hero_alchemist/alchemist_unstable_concoction_projectile.vpcf",
        iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
        bDodgeable = true,
        bProvidesVision = false,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
    })

    caster:EmitSound("Hero_Alchemist.UnstableConcoction.Throw")
end

function alchemist_unstable_concoction_custom:OnProjectileHit(target, location)
    if not target then
        return false
    end

    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")
    local damage = self:GetSpecialValueFor("max_damage")
    local stun_duration = self:GetSpecialValueFor("max_stun")

    EmitSoundOnLocationWithCaster(location, "Hero_Alchemist.UnstableConcoction.Stun", caster)

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        location,
        nil,
        radius,
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
            damage_type = self:GetAbilityDamageType(),
            ability = self
        })

        enemy:AddNewModifier(caster, self, "modifier_stunned", { duration = stun_duration })
    end

    return true
end

modifier_alchemist_unstable_concoction_custom = class({})

function modifier_alchemist_unstable_concoction_custom:IsHidden()
    return true
end

function modifier_alchemist_unstable_concoction_custom:IsPurgable()
    return false
end

function modifier_alchemist_unstable_concoction_custom:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("launch_interval"))
end

function modifier_alchemist_unstable_concoction_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetParent()

    if not ability or ability:IsNull() or ability:GetLevel() < 1 then
        return
    end

    if caster:IsIllusion() or not caster:IsAlive() or caster:IsStunned() or caster:IsSilenced() then
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

    ability:LaunchConcoction(enemies[RandomInt(1, #enemies)])
end
