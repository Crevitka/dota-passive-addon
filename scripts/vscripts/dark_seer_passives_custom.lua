LinkLuaModifier("modifier_dark_seer_vacuum_custom", "dark_seer_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_seer_ion_shell_custom", "dark_seer_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_seer_surge_custom", "dark_seer_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_seer_surge_custom_slow", "dark_seer_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_seer_wall_of_replica_custom", "dark_seer_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_seer_wall_of_replica_custom_slow", "dark_seer_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)

dark_seer_vacuum_custom = class({})
dark_seer_ion_shell_custom = class({})
dark_seer_surge_custom = class({})
dark_seer_wall_of_replica_custom = class({})

function dark_seer_vacuum_custom:GetIntrinsicModifierName()
	return "modifier_dark_seer_vacuum_custom"
end

function dark_seer_ion_shell_custom:GetIntrinsicModifierName()
	return "modifier_dark_seer_ion_shell_custom"
end

function dark_seer_surge_custom:GetIntrinsicModifierName()
	return "modifier_dark_seer_surge_custom"
end

function dark_seer_wall_of_replica_custom:GetIntrinsicModifierName()
	return "modifier_dark_seer_wall_of_replica_custom"
end

local function FindEnemies(caster, position, radius, heroesOnly)
	local targetType = DOTA_UNIT_TARGET_HERO
	if not heroesOnly then
		targetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
	end

	return FindUnitsInRadius(
		caster:GetTeamNumber(),
		position,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		targetType,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)
end

modifier_dark_seer_vacuum_custom = class({})

function modifier_dark_seer_vacuum_custom:IsHidden() return true end
function modifier_dark_seer_vacuum_custom:IsPurgable() return false end

function modifier_dark_seer_vacuum_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_dark_seer_vacuum_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local radius = ability:GetSpecialValueFor("radius")
	local enemies = FindEnemies(caster, caster:GetAbsOrigin(), radius, false)
	if #enemies == 0 then
		self:StartIntervalThink(1.0)
		return
	end

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_seer/dark_seer_vacuum.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(particle)
	EmitSoundOn("Hero_Dark_Seer.Vacuum", caster)

	for _, enemy in pairs(enemies) do
		local direction = (enemy:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
		local destination = caster:GetAbsOrigin() + direction * ability:GetSpecialValueFor("pull_distance")
		FindClearSpaceForUnit(enemy, destination, true)
		enemy:AddNewModifier(caster, ability, "modifier_stunned", { duration = ability:GetSpecialValueFor("duration") })
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			damage = ability:GetSpecialValueFor("damage"),
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = ability,
		})
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("vacuum_interval")))
end

modifier_dark_seer_ion_shell_custom = class({})

function modifier_dark_seer_ion_shell_custom:IsHidden() return false end
function modifier_dark_seer_ion_shell_custom:IsPurgable() return false end

function modifier_dark_seer_ion_shell_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("tick_interval"))
end

function modifier_dark_seer_ion_shell_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local tick = ability:GetSpecialValueFor("tick_interval")
	local enemies = FindEnemies(caster, caster:GetAbsOrigin(), ability:GetSpecialValueFor("radius"), false)
	for _, enemy in pairs(enemies) do
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			damage = ability:GetSpecialValueFor("damage_per_second") * tick,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = ability,
		})
	end
end

function modifier_dark_seer_ion_shell_custom:GetEffectName()
	return "particles/units/heroes/hero_dark_seer/dark_seer_ion_shell.vpcf"
end

function modifier_dark_seer_ion_shell_custom:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_dark_seer_ion_shell_custom:DeclareFunctions()
	return { MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS }
end

function modifier_dark_seer_ion_shell_custom:GetModifierExtraHealthBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_health")
end

modifier_dark_seer_surge_custom = class({})

function modifier_dark_seer_surge_custom:IsHidden() return false end
function modifier_dark_seer_surge_custom:IsPurgable() return false end

function modifier_dark_seer_surge_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("trail_damage_interval"))
end

function modifier_dark_seer_surge_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local radius = ability:GetSpecialValueFor("trail_radius")
	if radius <= 0 then return end

	local enemies = FindEnemies(caster, caster:GetAbsOrigin(), radius, false)
	for _, enemy in pairs(enemies) do
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			damage = ability:GetSpecialValueFor("trail_damage"),
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = ability,
		})
		enemy:AddNewModifier(caster, ability, "modifier_dark_seer_surge_custom_slow", {
			duration = ability:GetSpecialValueFor("trail_damage_interval") + 0.1
		})
	end
end

function modifier_dark_seer_surge_custom:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN }
end

function modifier_dark_seer_surge_custom:GetModifierMoveSpeed_AbsoluteMin()
	return self:GetAbility():GetSpecialValueFor("speed_boost")
end

function modifier_dark_seer_surge_custom:CheckState()
	return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end

modifier_dark_seer_surge_custom_slow = class({})

function modifier_dark_seer_surge_custom_slow:IsPurgable() return true end

function modifier_dark_seer_surge_custom_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_dark_seer_surge_custom_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("trail_move_slow")
end

modifier_dark_seer_wall_of_replica_custom = class({})

function modifier_dark_seer_wall_of_replica_custom:IsHidden() return false end
function modifier_dark_seer_wall_of_replica_custom:IsPurgable() return false end

function modifier_dark_seer_wall_of_replica_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_dark_seer_wall_of_replica_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local enemies = FindEnemies(caster, caster:GetAbsOrigin(), ability:GetSpecialValueFor("search_radius"), true)
	if #enemies > 0 then
		self:CreateReplica(caster, ability, enemies[RandomInt(1, #enemies)])
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("wall_interval")))
end

function modifier_dark_seer_wall_of_replica_custom:CreateReplica(caster, ability, target)
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_seer/dark_seer_wall_of_replica.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin() + RandomVector(250))
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin() + RandomVector(250))
	ParticleManager:ReleaseParticleIndex(particle)
	EmitSoundOn("Hero_Dark_Seer.Wall_of_Replica_Start", caster)

	ApplyDamage({
		victim = target,
		attacker = caster,
		damage = ability:GetSpecialValueFor("wall_damage"),
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = ability,
	})
	target:AddNewModifier(caster, ability, "modifier_dark_seer_wall_of_replica_custom_slow", {
		duration = ability:GetSpecialValueFor("slow_duration")
	})

	local illusions = CreateIllusions(
		caster,
		target,
		{
			outgoing_damage = ability:GetSpecialValueFor("replica_damage_outgoing"),
			incoming_damage = ability:GetSpecialValueFor("replica_damage_incoming"),
			duration = ability:GetSpecialValueFor("duration"),
		},
		1,
		64,
		false,
		true
	)

	for _, illusion in pairs(illusions or {}) do
		illusion:SetOwner(caster)
		illusion:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
	end
end

modifier_dark_seer_wall_of_replica_custom_slow = class({})

function modifier_dark_seer_wall_of_replica_custom_slow:IsPurgable() return true end

function modifier_dark_seer_wall_of_replica_custom_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_dark_seer_wall_of_replica_custom_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("movement_slow")
end
