LinkLuaModifier("modifier_bristleback_viscous_nasal_goo_custom", "bristleback_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_viscous_nasal_goo_custom_debuff", "bristleback_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_quill_spray_custom", "bristleback_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_quill_spray_custom_stack", "bristleback_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_bristleback_custom", "bristleback_passives_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_warpath_custom", "bristleback_passives_custom", LUA_MODIFIER_MOTION_NONE)

bristleback_viscous_nasal_goo_custom = class({})
bristleback_quill_spray_custom = class({})
bristleback_bristleback_custom = class({})
bristleback_warpath_custom = class({})

local function AddWarpathStack(caster)
    if not caster or caster:IsNull() then
        return
    end

    local ability = caster:FindAbilityByName("bristleback_warpath_custom")
    if not ability or ability:IsNull() or ability:GetLevel() < 1 then
        return
    end

    local duration = ability:GetSpecialValueFor("stack_duration")
    local max_stacks = ability:GetSpecialValueFor("max_stacks")
    local modifier = caster:FindModifierByName("modifier_bristleback_warpath_custom")

    if not modifier then
        modifier = caster:AddNewModifier(caster, ability, "modifier_bristleback_warpath_custom", { duration = duration })
    else
        modifier:SetDuration(duration, true)
    end

    if modifier then
        modifier:SetStackCount(math.min(modifier:GetStackCount() + 1, max_stacks))
    end
end

function bristleback_viscous_nasal_goo_custom:GetAbilityTextureName()
    return "bristleback_viscous_nasal_goo"
end

function bristleback_viscous_nasal_goo_custom:GetIntrinsicModifierName()
    return "modifier_bristleback_viscous_nasal_goo_custom"
end

function bristleback_viscous_nasal_goo_custom:LaunchGoo(target)
    local caster = self:GetCaster()
    if not target or target:IsNull() or not target:IsAlive() then
        return
    end

    caster:EmitSound("Hero_Bristleback.ViscousGoo.Cast")
    ProjectileManager:CreateTrackingProjectile({
        Target = target,
        Source = caster,
        Ability = self,
        EffectName = "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo.vpcf",
        iMoveSpeed = self:GetSpecialValueFor("goo_speed"),
        bDodgeable = true,
        bProvidesVision = false,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
    })
end

function bristleback_viscous_nasal_goo_custom:OnProjectileHit(target, location)
    if not target or target:IsNull() or not target:IsAlive() then
        return true
    end

    self:ApplyGooNow(target)
    return true
end

function bristleback_viscous_nasal_goo_custom:ApplyGooNow(target)
    local caster = self:GetCaster()
    if not target or target:IsNull() or not target:IsAlive() then
        return
    end

    local duration = self:GetSpecialValueFor("goo_duration")
    local stack_limit = self:GetSpecialValueFor("stack_limit")
    local modifier = target:FindModifierByNameAndCaster("modifier_bristleback_viscous_nasal_goo_custom_debuff", caster)

    if not modifier then
        modifier = target:AddNewModifier(caster, self, "modifier_bristleback_viscous_nasal_goo_custom_debuff", { duration = duration })
        if modifier then
            modifier:SetStackCount(1)
        end
    else
        modifier:SetDuration(duration, true)
        modifier:SetStackCount(math.min(modifier:GetStackCount() + 1, stack_limit))
    end

    target:EmitSound("Hero_Bristleback.ViscousGoo.Target")
    AddWarpathStack(caster)
end

function bristleback_quill_spray_custom:GetAbilityTextureName()
    return "bristleback_quill_spray"
end

function bristleback_quill_spray_custom:GetIntrinsicModifierName()
    return "modifier_bristleback_quill_spray_custom"
end

function bristleback_quill_spray_custom:Spray(reflected)
    local caster = self:GetCaster()
    if not caster or caster:IsNull() or not caster:IsAlive() or self:GetLevel() < 1 then
        return
    end

    local radius = self:GetSpecialValueFor("radius")
    local base_damage = self:GetSpecialValueFor("quill_base_damage")
    local stack_damage = self:GetSpecialValueFor("quill_stack_damage")
    local stack_duration = self:GetSpecialValueFor("quill_stack_duration")
    local max_damage = self:GetSpecialValueFor("max_damage")

    caster:EmitSound("Hero_Bristleback.QuillSpray")
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_quill_spray.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
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
        local stack_modifier = enemy:FindModifierByNameAndCaster("modifier_bristleback_quill_spray_custom_stack", caster)
        local stacks = 0
        if stack_modifier then
            stacks = stack_modifier:GetStackCount()
        end

        local damage = math.min(base_damage + stack_damage * stacks, max_damage)
        ApplyDamage({
            victim = enemy,
            attacker = caster,
            damage = damage,
            damage_type = self:GetAbilityDamageType(),
            damage_flags = reflected and DOTA_DAMAGE_FLAG_REFLECTION or 0,
            ability = self
        })

        if not stack_modifier then
            stack_modifier = enemy:AddNewModifier(caster, self, "modifier_bristleback_quill_spray_custom_stack", { duration = stack_duration })
            if stack_modifier then
                stack_modifier:SetStackCount(1)
            end
        else
            stack_modifier:SetDuration(stack_duration, true)
            stack_modifier:IncrementStackCount()
        end
    end

    AddWarpathStack(caster)
end

function bristleback_bristleback_custom:GetAbilityTextureName()
    return "bristleback_bristleback"
end

function bristleback_bristleback_custom:GetIntrinsicModifierName()
    return "modifier_bristleback_bristleback_custom"
end

function bristleback_warpath_custom:GetAbilityTextureName()
    return "bristleback_warpath"
end

function bristleback_warpath_custom:GetIntrinsicModifierName()
    return "modifier_bristleback_warpath_custom"
end

modifier_bristleback_viscous_nasal_goo_custom = class({})

function modifier_bristleback_viscous_nasal_goo_custom:IsHidden()
    return true
end

function modifier_bristleback_viscous_nasal_goo_custom:IsPurgable()
    return false
end

function modifier_bristleback_viscous_nasal_goo_custom:OnCreated()
    if not IsServer() then
        return
    end

    self:UpdateInterval()
end

function modifier_bristleback_viscous_nasal_goo_custom:OnRefresh()
    if not IsServer() then
        return
    end

    self:UpdateInterval()
end

function modifier_bristleback_viscous_nasal_goo_custom:UpdateInterval()
    local ability = self:GetAbility()
    if not ability or ability:IsNull() or ability:GetLevel() < 1 then
        self:StartIntervalThink(0.5)
        return
    end

    self:StartIntervalThink(math.max(0.1, ability:GetSpecialValueFor("apply_interval")))
end

function modifier_bristleback_viscous_nasal_goo_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetParent()

    if not ability or ability:IsNull() or ability:GetLevel() < 1 or not caster:IsAlive() then
        self:UpdateInterval()
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
        self:UpdateInterval()
        return
    end

    ability:LaunchGoo(enemies[RandomInt(1, #enemies)])
    self:UpdateInterval()
end

modifier_bristleback_viscous_nasal_goo_custom_debuff = class({})

function modifier_bristleback_viscous_nasal_goo_custom_debuff:IsDebuff()
    return true
end

function modifier_bristleback_viscous_nasal_goo_custom_debuff:IsPurgable()
    return true
end

function modifier_bristleback_viscous_nasal_goo_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_bristleback_viscous_nasal_goo_custom_debuff:GetModifierPhysicalArmorBonus()
    local ability = self:GetAbility()
    return -(ability:GetSpecialValueFor("base_armor") + ability:GetSpecialValueFor("armor_per_stack") * self:GetStackCount())
end

function modifier_bristleback_viscous_nasal_goo_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    local ability = self:GetAbility()
    return -(ability:GetSpecialValueFor("base_move_slow") + ability:GetSpecialValueFor("move_slow_per_stack") * self:GetStackCount())
end

modifier_bristleback_quill_spray_custom = class({})

function modifier_bristleback_quill_spray_custom:IsHidden()
    return true
end

function modifier_bristleback_quill_spray_custom:IsPurgable()
    return false
end

function modifier_bristleback_quill_spray_custom:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("spray_interval"))
end

function modifier_bristleback_quill_spray_custom:OnIntervalThink()
    local ability = self:GetAbility()
    if ability and not ability:IsNull() and ability:GetLevel() > 0 then
        ability:Spray(false)
    end
end

modifier_bristleback_quill_spray_custom_stack = class({})

function modifier_bristleback_quill_spray_custom_stack:IsDebuff()
    return true
end

function modifier_bristleback_quill_spray_custom_stack:IsPurgable()
    return false
end

modifier_bristleback_bristleback_custom = class({})

function modifier_bristleback_bristleback_custom:IsHidden()
    return true
end

function modifier_bristleback_bristleback_custom:IsPurgable()
    return false
end

function modifier_bristleback_bristleback_custom:OnCreated()
    self.damage_taken_from_back = 0
    self.last_release_time = -999
end

function modifier_bristleback_bristleback_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
    }
end

function modifier_bristleback_bristleback_custom:GetModifierIncomingDamage_Percentage(event)
    local ability = self:GetAbility()
    local parent = self:GetParent()

    if not ability or ability:IsNull() or ability:GetLevel() < 1 or not event.attacker or event.attacker:IsNull() then
        return 0
    end

    local reduction = self:GetDamageReduction(event.attacker)
    if reduction <= 0 then
        return 0
    end

    if IsServer() and reduction == ability:GetSpecialValueFor("back_damage_reduction") then
        self.damage_taken_from_back = self.damage_taken_from_back + event.damage
        if self.damage_taken_from_back >= ability:GetSpecialValueFor("quill_release_threshold") then
            if GameRules:GetGameTime() - self.last_release_time >= ability:GetSpecialValueFor("quill_release_interval") then
                self.damage_taken_from_back = 0
                self.last_release_time = GameRules:GetGameTime()

                local quill = parent:FindAbilityByName("bristleback_quill_spray_custom")
                if quill and not quill:IsNull() and quill:GetLevel() > 0 then
                    quill:Spray(true)
                end
            end
        end
    end

    return -reduction
end

function modifier_bristleback_bristleback_custom:GetDamageReduction(attacker)
    local ability = self:GetAbility()
    local parent = self:GetParent()
    local direction = attacker:GetAbsOrigin() - parent:GetAbsOrigin()
    direction.z = 0

    if direction:Length2D() < 1 then
        return 0
    end

    direction = direction:Normalized()
    local back = parent:GetForwardVector() * -1
    back.z = 0
    back = back:Normalized()

    local dot = math.max(-1, math.min(1, direction:Dot(back)))
    local angle = math.deg(math.acos(dot))

    if angle <= ability:GetSpecialValueFor("back_angle") then
        return ability:GetSpecialValueFor("back_damage_reduction")
    end

    if angle <= ability:GetSpecialValueFor("side_angle") then
        return ability:GetSpecialValueFor("side_damage_reduction")
    end

    return 0
end

modifier_bristleback_warpath_custom = class({})

function modifier_bristleback_warpath_custom:IsHidden()
    return self:GetStackCount() < 1
end

function modifier_bristleback_warpath_custom:IsPurgable()
    return false
end

function modifier_bristleback_warpath_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_bristleback_warpath_custom:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("damage_per_stack") * self:GetStackCount()
end

function modifier_bristleback_warpath_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_speed_per_stack") * self:GetStackCount()
end
