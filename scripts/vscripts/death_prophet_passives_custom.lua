LinkLuaModifier("modifier_death_prophet_carrion_swarm_custom", "death_prophet_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_death_prophet_silence_custom", "death_prophet_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_death_prophet_silence_custom_debuff", "death_prophet_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_death_prophet_spirit_siphon_custom", "death_prophet_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_death_prophet_spirit_siphon_custom_debuff", "death_prophet_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_death_prophet_exorcism_custom", "death_prophet_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)

death_prophet_carrion_swarm_custom = class({})
death_prophet_silence_custom = class({})
death_prophet_spirit_siphon_custom = class({})
death_prophet_exorcism_custom = class({})

function death_prophet_carrion_swarm_custom:GetIntrinsicModifierName()
	return "modifier_death_prophet_carrion_swarm_custom"
end

function death_prophet_silence_custom:GetIntrinsicModifierName()
	return "modifier_death_prophet_silence_custom"
end

function death_prophet_spirit_siphon_custom:GetIntrinsicModifierName()
	return "modifier_death_prophet_spirit_siphon_custom"
end

function death_prophet_exorcism_custom:GetIntrinsicModifierName()
	return "modifier_death_prophet_exorcism_custom"
end

local function FindEnemies(caster, position, radius)
	return FindUnitsInRadius(
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
end

local function FindRandomEnemy(caster, radius)
	local enemies = FindEnemies(caster, caster:GetAbsOrigin(), radius)
	if #enemies == 0 then return nil end
	return enemies[RandomInt(1, #enemies)]
end

modifier_death_prophet_carrion_swarm_custom = class({})

function modifier_death_prophet_carrion_swarm_custom:IsHidden() return true end
function modifier_death_prophet_carrion_swarm_custom:IsPurgable() return false end

function modifier_death_prophet_carrion_swarm_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_death_prophet_carrion_swarm_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local target = FindRandomEnemy(caster, ability:GetSpecialValueFor("search_radius"))
	if target then
		local position = target:GetAbsOrigin()
		local radius = ability:GetSpecialValueFor("end_radius")
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_death_prophet/death_prophet_carrion_swarm.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle, 1, position)
		ParticleManager:ReleaseParticleIndex(particle)
		EmitSoundOn("Hero_DeathProphet.CarrionSwarm", caster)

		for _, enemy in pairs(FindEnemies(caster, position, radius)) do
			ApplyDamage({
				victim = enemy,
				attacker = caster,
				damage = ability:GetSpecialValueFor("damage"),
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = ability,
			})
		end
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("swarm_interval")))
end

modifier_death_prophet_silence_custom = class({})

function modifier_death_prophet_silence_custom:IsHidden() return true end
function modifier_death_prophet_silence_custom:IsPurgable() return false end

function modifier_death_prophet_silence_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_death_prophet_silence_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local target = FindRandomEnemy(caster, ability:GetSpecialValueFor("search_radius"))
	if target then
		local position = target:GetAbsOrigin()
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_death_prophet/death_prophet_silence.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, position)
		ParticleManager:SetParticleControl(particle, 1, Vector(ability:GetSpecialValueFor("radius"), 0, 0))
		ParticleManager:ReleaseParticleIndex(particle)
		EmitSoundOnLocationWithCaster(position, "Hero_DeathProphet.Silence", caster)

		for _, enemy in pairs(FindEnemies(caster, position, ability:GetSpecialValueFor("radius"))) do
			enemy:AddNewModifier(caster, ability, "modifier_death_prophet_silence_custom_debuff", {
				duration = ability:GetSpecialValueFor("duration")
			})
		end
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("silence_interval")))
end

modifier_death_prophet_silence_custom_debuff = class({})

function modifier_death_prophet_silence_custom_debuff:IsPurgable() return true end

function modifier_death_prophet_silence_custom_debuff:CheckState()
	return { [MODIFIER_STATE_SILENCED] = true }
end

modifier_death_prophet_spirit_siphon_custom = class({})

function modifier_death_prophet_spirit_siphon_custom:IsHidden() return true end
function modifier_death_prophet_spirit_siphon_custom:IsPurgable() return false end

function modifier_death_prophet_spirit_siphon_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_death_prophet_spirit_siphon_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local target = FindRandomEnemy(caster, ability:GetSpecialValueFor("search_radius"))
	if target then
		target:AddNewModifier(caster, ability, "modifier_death_prophet_spirit_siphon_custom_debuff", {
			duration = ability:GetSpecialValueFor("haunt_duration")
		})
		EmitSoundOn("Hero_DeathProphet.SpiritSiphon.Cast", target)
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("siphon_interval")))
end

modifier_death_prophet_spirit_siphon_custom_debuff = class({})

function modifier_death_prophet_spirit_siphon_custom_debuff:IsPurgable() return false end

function modifier_death_prophet_spirit_siphon_custom_debuff:OnCreated()
	if not IsServer() then return end
	self.tick = self:GetAbility():GetSpecialValueFor("tick_interval")
	self:StartIntervalThink(self.tick)
end

function modifier_death_prophet_spirit_siphon_custom_debuff:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	if not ability or not caster then return end

	local damage = ability:GetSpecialValueFor("damage")
	ApplyDamage({
		victim = parent,
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = ability,
	})
	caster:Heal(damage, ability)
end

function modifier_death_prophet_spirit_siphon_custom_debuff:GetEffectName()
	return "particles/units/heroes/hero_death_prophet/death_prophet_spiritsiphon.vpcf"
end

function modifier_death_prophet_spirit_siphon_custom_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_death_prophet_exorcism_custom = class({})

function modifier_death_prophet_exorcism_custom:IsHidden() return false end
function modifier_death_prophet_exorcism_custom:IsPurgable() return false end

function modifier_death_prophet_exorcism_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(1.0)
end

function modifier_death_prophet_exorcism_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local enemies = FindEnemies(caster, caster:GetAbsOrigin(), ability:GetSpecialValueFor("radius"))
	if #enemies == 0 then return end

	local spirits = ability:GetSpecialValueFor("spirits")
	local damage = ability:GetSpecialValueFor("average_damage") * math.min(spirits, #enemies)
	local healTotal = 0
	EmitSoundOn("Hero_DeathProphet.Exorcism.Attack", caster)

	for _, enemy in pairs(enemies) do
		local dealt = damage / #enemies
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			damage = dealt,
			damage_type = DAMAGE_TYPE_PHYSICAL,
			ability = ability,
		})
		healTotal = healTotal + dealt
	end

	caster:Heal(healTotal * ability:GetSpecialValueFor("heal_percent") / 100, ability)
end
