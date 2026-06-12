LinkLuaModifier("modifier_clinkz_strafe_custom", "clinkz_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_clinkz_strafe_custom_archer", "clinkz_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_clinkz_searing_arrows_custom", "clinkz_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_clinkz_death_pact_custom", "clinkz_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_clinkz_death_pact_custom_buff", "clinkz_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_clinkz_wind_walk_custom", "clinkz_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)

clinkz_strafe_custom = class({})
clinkz_searing_arrows_custom = class({})
clinkz_death_pact_custom = class({})
clinkz_wind_walk_custom = class({})

function clinkz_strafe_custom:GetIntrinsicModifierName()
	return "modifier_clinkz_strafe_custom"
end

function clinkz_searing_arrows_custom:GetIntrinsicModifierName()
	return "modifier_clinkz_searing_arrows_custom"
end

function clinkz_death_pact_custom:GetIntrinsicModifierName()
	return "modifier_clinkz_death_pact_custom"
end

function clinkz_wind_walk_custom:GetIntrinsicModifierName()
	return "modifier_clinkz_wind_walk_custom"
end

modifier_clinkz_strafe_custom = class({})

function modifier_clinkz_strafe_custom:IsHidden() return false end
function modifier_clinkz_strafe_custom:IsPurgable() return false end

function modifier_clinkz_strafe_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_clinkz_strafe_custom:OnIntervalThink()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local radius = ability:GetSpecialValueFor("strafe_skeleton_radius")
	local duration = 0.75
	local allies = FindUnitsInRadius(
		parent:GetTeamNumber(),
		parent:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	for _, ally in pairs(allies) do
		if ally:GetUnitName() == "npc_dota_clinkz_skeleton_archer" then
			ally:AddNewModifier(parent, ability, "modifier_clinkz_strafe_custom_archer", { duration = duration })
		end
	end
end

function modifier_clinkz_strafe_custom:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
	}
end

function modifier_clinkz_strafe_custom:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attack_speed_bonus")
end

function modifier_clinkz_strafe_custom:GetModifierAttackRangeBonus()
	return self:GetAbility():GetSpecialValueFor("attack_range_bonus")
end

modifier_clinkz_strafe_custom_archer = class({})

function modifier_clinkz_strafe_custom_archer:IsHidden() return false end
function modifier_clinkz_strafe_custom_archer:IsPurgable() return false end

function modifier_clinkz_strafe_custom_archer:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE }
end

function modifier_clinkz_strafe_custom_archer:GetModifierAttackSpeedPercentage()
	return self:GetAbility():GetSpecialValueFor("archer_attack_speed_pct")
end

modifier_clinkz_searing_arrows_custom = class({})

function modifier_clinkz_searing_arrows_custom:IsHidden() return false end
function modifier_clinkz_searing_arrows_custom:IsPurgable() return false end

function modifier_clinkz_searing_arrows_custom:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_clinkz_searing_arrows_custom:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("damage_bonus")
end

modifier_clinkz_death_pact_custom = class({})

function modifier_clinkz_death_pact_custom:IsHidden() return true end
function modifier_clinkz_death_pact_custom:IsPurgable() return false end

function modifier_clinkz_death_pact_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.25)
end

function modifier_clinkz_death_pact_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local parent = self:GetParent()
	if parent:HasModifier("modifier_clinkz_death_pact_custom_buff") then
		self:StartIntervalThink(1.0)
		return
	end

	local victim = self:FindPactTarget(parent, ability)
	if victim then
		self:ConsumeTarget(parent, ability, victim)
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("pact_interval")))
end

function modifier_clinkz_death_pact_custom:FindPactTarget(parent, ability)
	local radius = ability:GetSpecialValueFor("search_radius")
	local allies = FindUnitsInRadius(
		parent:GetTeamNumber(),
		parent:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_CLOSEST,
		false
	)

	for _, unit in pairs(allies) do
		if unit ~= parent and unit:GetUnitName() == "npc_dota_clinkz_skeleton_archer" then
			return unit
		end
	end

	local enemies = FindUnitsInRadius(
		parent:GetTeamNumber(),
		parent:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_CLOSEST,
		false
	)

	local maxLevel = ability:GetSpecialValueFor("creep_level")
	for _, unit in pairs(enemies) do
		if not unit:IsAncient() and unit:GetLevel() <= maxLevel then
			return unit
		end
	end

	return nil
end

function modifier_clinkz_death_pact_custom:ConsumeTarget(parent, ability, victim)
	local duration = ability:GetSpecialValueFor("duration")
	local healthGain = ability:GetSpecialValueFor("health_gain")

	parent:AddNewModifier(parent, ability, "modifier_clinkz_death_pact_custom_buff", { duration = duration })
	parent:Heal(healthGain, ability)

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_clinkz/clinkz_death_pact.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(particle, 1, victim, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", victim:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(particle)
	EmitSoundOn("Hero_Clinkz.DeathPact", parent)

	victim:Kill(ability, parent)
end

modifier_clinkz_death_pact_custom_buff = class({})

function modifier_clinkz_death_pact_custom_buff:IsHidden() return false end
function modifier_clinkz_death_pact_custom_buff:IsPurgable() return false end

function modifier_clinkz_death_pact_custom_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS }
end

function modifier_clinkz_death_pact_custom_buff:GetModifierExtraHealthBonus()
	return self:GetAbility():GetSpecialValueFor("health_gain")
end

modifier_clinkz_wind_walk_custom = class({})

function modifier_clinkz_wind_walk_custom:IsHidden() return false end
function modifier_clinkz_wind_walk_custom:IsPurgable() return false end

function modifier_clinkz_wind_walk_custom:OnCreated()
	if not IsServer() then return end
	self.archers = {}
	self:StartIntervalThink(0.5)
end

function modifier_clinkz_wind_walk_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	self:RemoveDeadArchers()

	local parent = self:GetParent()
	local maxArchers = ability:GetSpecialValueFor("skeleton_count")
	while #self.archers < maxArchers do
		self:SpawnArcher(parent, ability)
	end

	self:StartIntervalThink(1.0)
end

function modifier_clinkz_wind_walk_custom:RemoveDeadArchers()
	for index = #self.archers, 1, -1 do
		local unit = self.archers[index]
		if not unit or unit:IsNull() or not unit:IsAlive() then
			table.remove(self.archers, index)
		end
	end
end

function modifier_clinkz_wind_walk_custom:SpawnArcher(parent, ability)
	local offset = RandomVector(RandomFloat(150, 250))
	local position = parent:GetAbsOrigin() + offset
	local archer = CreateUnitByName("npc_dota_clinkz_skeleton_archer", position, true, parent, parent, parent:GetTeamNumber())
	if not archer then return end

	archer:SetOwner(parent)
	archer:SetControllableByPlayer(parent:GetPlayerOwnerID(), true)
	archer:AddNewModifier(parent, ability, "modifier_kill", { duration = ability:GetSpecialValueFor("skeleton_duration") })
	archer:SetBaseAttackTime(ability:GetSpecialValueFor("attack_rate"))

	local damage = math.max(1, math.floor(parent:GetAverageTrueAttackDamage(parent) * ability:GetSpecialValueFor("damage_percent") / 100))
	archer:SetBaseDamageMin(damage)
	archer:SetBaseDamageMax(damage)

	local searing = parent:FindAbilityByName("clinkz_searing_arrows_custom")
	if searing and searing:GetLevel() > 0 then
		archer:AddNewModifier(parent, searing, "modifier_clinkz_searing_arrows_custom", { duration = ability:GetSpecialValueFor("skeleton_duration") })
	end

	table.insert(self.archers, archer)
end

function modifier_clinkz_wind_walk_custom:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_clinkz_wind_walk_custom:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("move_speed_bonus_pct")
end

function modifier_clinkz_wind_walk_custom:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end
