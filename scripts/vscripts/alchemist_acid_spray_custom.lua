LinkLuaModifier("modifier_alchemist_acid_spray_custom_aura", "alchemist_acid_spray_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_alchemist_acid_spray_custom_debuff", "alchemist_acid_spray_custom", LUA_MODIFIER_MOTION_NONE)

alchemist_acid_spray_custom = class({})

function alchemist_acid_spray_custom:GetAbilityTextureName()
    return "alchemist_acid_spray"
end

function alchemist_acid_spray_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function alchemist_acid_spray_custom:OnToggle()
    local caster = self:GetCaster()

    if self:GetToggleState() then
        caster:AddNewModifier(caster, self, "modifier_alchemist_acid_spray_custom_aura", {})
        caster:EmitSound("Hero_Alchemist.AcidSpray")
    else
        caster:RemoveModifierByName("modifier_alchemist_acid_spray_custom_aura")
        caster:StopSound("Hero_Alchemist.AcidSpray")
    end
end

modifier_alchemist_acid_spray_custom_aura = class({})

function modifier_alchemist_acid_spray_custom_aura:IsHidden()
    return false
end

function modifier_alchemist_acid_spray_custom_aura:IsPurgable()
    return false
end

function modifier_alchemist_acid_spray_custom_aura:IsAura()
    return true
end

function modifier_alchemist_acid_spray_custom_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_alchemist_acid_spray_custom_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_alchemist_acid_spray_custom_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_alchemist_acid_spray_custom_aura:GetModifierAura()
    return "modifier_alchemist_acid_spray_custom_debuff"
end

function modifier_alchemist_acid_spray_custom_aura:GetAuraDuration()
    return 0.5
end

function modifier_alchemist_acid_spray_custom_aura:OnCreated()
    if not IsServer() then
        return
    end

    local parent = self:GetParent()
    local radius = self:GetAbility():GetSpecialValueFor("radius")
    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_alchemist/alchemist_acid_spray.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.particle, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.particle, 1, Vector(radius, 1, 1))
    self:AddParticle(self.particle, false, false, -1, false, false)

    self:StartIntervalThink(1.0)
end

function modifier_alchemist_acid_spray_custom_aura:OnIntervalThink()
    local ability = self:GetAbility()
    local parent = self:GetParent()

    if not ability or ability:IsNull() or not parent or parent:IsNull() then
        return
    end

    local mana_cost = ability:GetSpecialValueFor("mana_per_second")
    if parent:GetMana() < mana_cost then
        ability:ToggleAbility()
        return
    end

    parent:SpendMana(mana_cost, ability)
end

function modifier_alchemist_acid_spray_custom_aura:OnDestroy()
    if not IsServer() then
        return
    end

    self:GetParent():StopSound("Hero_Alchemist.AcidSpray")
end

modifier_alchemist_acid_spray_custom_debuff = class({})

function modifier_alchemist_acid_spray_custom_debuff:IsDebuff()
    return true
end

function modifier_alchemist_acid_spray_custom_debuff:IsPurgable()
    return false
end

function modifier_alchemist_acid_spray_custom_debuff:OnCreated()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("tick_rate"))
end

function modifier_alchemist_acid_spray_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end

function modifier_alchemist_acid_spray_custom_debuff:GetModifierPhysicalArmorBonus()
    return -self:GetAbility():GetSpecialValueFor("armor_reduction")
end

function modifier_alchemist_acid_spray_custom_debuff:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    if not ability or ability:IsNull() or not caster or caster:IsNull() then
        return
    end

    ApplyDamage({
        victim = parent,
        attacker = caster,
        damage = ability:GetSpecialValueFor("damage"),
        damage_type = ability:GetAbilityDamageType(),
        ability = ability
    })
end
