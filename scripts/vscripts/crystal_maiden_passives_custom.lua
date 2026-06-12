LinkLuaModifier("modifier_crystal_maiden_crystal_nova_custom", "crystal_maiden_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_crystal_nova_custom_slow", "crystal_maiden_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_frostbite_custom", "crystal_maiden_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_frostbite_custom_debuff", "crystal_maiden_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_brilliance_aura_custom", "crystal_maiden_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_brilliance_aura_custom_effect", "crystal_maiden_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_freezing_field_custom", "crystal_maiden_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_freezing_field_custom_slow", "crystal_maiden_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)

crystal_maiden_crystal_nova_custom = class({})
crystal_maiden_frostbite_custom = class({})
crystal_maiden_brilliance_aura_custom = class({})
crystal_maiden_freezing_field_custom = class({})

function crystal_maiden_crystal_nova_custom:GetIntrinsicModifierName()
	return "modifier_crystal_maiden_crystal_nova_custom"
end

function crystal_maiden_frostbite_custom:GetIntrinsicModifierName()
	return "modifier_crystal_maiden_frostbite_custom"
end

function crystal_maiden_brilliance_aura_custom:GetIntrinsicModifierName()
	return "modifier_crystal_maiden_brilliance_aura_custom"
end

function crystal_maiden_freezing_field_custom:GetIntrinsicModifierName()
	return "modifier_crystal_maiden_freezing_field_custom"
end

local function FindRandomEnemy(caster, radius)
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

	if #enemies == 0 then return nil end
	return enemies[RandomInt(1, #enemies)]
end

modifier_crystal_maiden_crystal_nova_custom = class({})

function modifier_crystal_maiden_crystal_nova_custom:IsHidden() return true end
function modifier_crystal_maiden_crystal_nova_custom:IsPurgable() return false end

function modifier_crystal_maiden_crystal_nova_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_crystal_maiden_crystal_nova_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local target = FindRandomEnemy(caster, ability:GetSpecialValueFor("search_radius"))
	if target then
		self:ReleaseNova(caster, ability, target:GetAbsOrigin())
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("nova_interval")))
end

function modifier_crystal_maiden_crystal_nova_custom:ReleaseNova(caster, ability, position)
	local radius = ability:GetSpecialValueFor("radius")
	local duration = ability:GetSpecialValueFor("duration")

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden/maiden_crystal_nova.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(particle)
	EmitSoundOnLocationWithCaster(position, "Hero_Crystal.CrystalNova", caster)

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		position,
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
			damage = ability:GetSpecialValueFor("nova_damage"),
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = ability,
		})
		enemy:AddNewModifier(caster, ability, "modifier_crystal_maiden_crystal_nova_custom_slow", { duration = duration })
	end
end

modifier_crystal_maiden_crystal_nova_custom_slow = class({})

function modifier_crystal_maiden_crystal_nova_custom_slow:IsPurgable() return true end

function modifier_crystal_maiden_crystal_nova_custom_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_crystal_maiden_crystal_nova_custom_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movespeed_slow")
end

function modifier_crystal_maiden_crystal_nova_custom_slow:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attackspeed_slow")
end

modifier_crystal_maiden_frostbite_custom = class({})

function modifier_crystal_maiden_frostbite_custom:IsHidden() return true end
function modifier_crystal_maiden_frostbite_custom:IsPurgable() return false end

function modifier_crystal_maiden_frostbite_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_crystal_maiden_frostbite_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local target = FindRandomEnemy(caster, ability:GetSpecialValueFor("search_radius"))
	if target then
		target:AddNewModifier(caster, ability, "modifier_crystal_maiden_frostbite_custom_debuff", {
			duration = ability:GetSpecialValueFor("duration")
		})
		EmitSoundOn("hero_Crystal.frostbite", target)
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("frostbite_interval")))
end

modifier_crystal_maiden_frostbite_custom_debuff = class({})

function modifier_crystal_maiden_frostbite_custom_debuff:IsPurgable() return true end

function modifier_crystal_maiden_frostbite_custom_debuff:OnCreated()
	if not IsServer() then return end
	self.tick = self:GetAbility():GetSpecialValueFor("tick_interval")
	self:StartIntervalThink(self.tick)
end

function modifier_crystal_maiden_frostbite_custom_debuff:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	if not ability or not caster then return end

	local dps = ability:GetSpecialValueFor("damage_per_second")
	if parent:IsCreep() then
		dps = dps * ability:GetSpecialValueFor("creep_multiplier")
	end

	ApplyDamage({
		victim = parent,
		attacker = caster,
		damage = dps * self.tick,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = ability,
	})
end

function modifier_crystal_maiden_frostbite_custom_debuff:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
end

modifier_crystal_maiden_brilliance_aura_custom = class({})

function modifier_crystal_maiden_brilliance_aura_custom:IsHidden() return true end
function modifier_crystal_maiden_brilliance_aura_custom:IsPurgable() return false end
function modifier_crystal_maiden_brilliance_aura_custom:IsAura() return true end
function modifier_crystal_maiden_brilliance_aura_custom:GetModifierAura() return "modifier_crystal_maiden_brilliance_aura_custom_effect" end
function modifier_crystal_maiden_brilliance_aura_custom:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_crystal_maiden_brilliance_aura_custom:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_crystal_maiden_brilliance_aura_custom:GetAuraRadius() return 25000 end
function modifier_crystal_maiden_brilliance_aura_custom:GetAuraDuration() return 0.5 end

modifier_crystal_maiden_brilliance_aura_custom_effect = class({})

function modifier_crystal_maiden_brilliance_aura_custom_effect:IsPurgable() return false end

function modifier_crystal_maiden_brilliance_aura_custom_effect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
	}
end

function modifier_crystal_maiden_brilliance_aura_custom_effect:GetModifierConstantManaRegen()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	if not ability or not caster then return 0 end

	local regen = ability:GetSpecialValueFor("base_mana_regen")
	local radius = ability:GetSpecialValueFor("proximity_bonus_radius")
	if (self:GetParent():GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() <= radius then
		regen = regen * ability:GetSpecialValueFor("proximity_bonus_factor")
	end

	return regen
end

function modifier_crystal_maiden_brilliance_aura_custom_effect:GetModifierTotalPercentageManaRegen()
	return self:GetAbility():GetSpecialValueFor("mana_regen_amp")
end

modifier_crystal_maiden_freezing_field_custom = class({})

function modifier_crystal_maiden_freezing_field_custom:IsHidden() return false end
function modifier_crystal_maiden_freezing_field_custom:IsPurgable() return false end

function modifier_crystal_maiden_freezing_field_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_crystal_maiden_freezing_field_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
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

	if #enemies > 0 then
		self:CreateExplosion(caster, ability)
	end

	self:StartIntervalThink(math.max(0.1, ability:GetSpecialValueFor("explosion_interval")))
end

function modifier_crystal_maiden_freezing_field_custom:CreateExplosion(caster, ability)
	local minDistance = ability:GetSpecialValueFor("explosion_min_dist")
	local maxDistance = ability:GetSpecialValueFor("explosion_max_dist")
	local position = caster:GetAbsOrigin() + RandomVector(RandomFloat(minDistance, maxDistance))
	local radius = ability:GetSpecialValueFor("explosion_radius")

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(particle)

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		position,
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
			damage = ability:GetSpecialValueFor("damage"),
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = ability,
		})
		enemy:AddNewModifier(caster, ability, "modifier_crystal_maiden_freezing_field_custom_slow", {
			duration = ability:GetSpecialValueFor("slow_duration")
		})
	end
end

modifier_crystal_maiden_freezing_field_custom_slow = class({})

function modifier_crystal_maiden_freezing_field_custom_slow:IsPurgable() return true end

function modifier_crystal_maiden_freezing_field_custom_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_crystal_maiden_freezing_field_custom_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movespeed_slow")
end

function modifier_crystal_maiden_freezing_field_custom_slow:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attack_slow")
end
