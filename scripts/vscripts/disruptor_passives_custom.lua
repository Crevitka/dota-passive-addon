LinkLuaModifier("modifier_disruptor_thunder_strike_custom", "disruptor_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_disruptor_thunder_strike_custom_debuff", "disruptor_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_disruptor_glimpse_custom", "disruptor_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_disruptor_kinetic_field_custom", "disruptor_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_disruptor_kinetic_field_custom_area", "disruptor_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_disruptor_static_storm_custom", "disruptor_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_disruptor_static_storm_custom_area", "disruptor_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_disruptor_static_storm_custom_silence", "disruptor_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)

disruptor_thunder_strike_custom = class({})
disruptor_glimpse_custom = class({})
disruptor_kinetic_field_custom = class({})
disruptor_static_storm_custom = class({})

function disruptor_thunder_strike_custom:GetIntrinsicModifierName()
	return "modifier_disruptor_thunder_strike_custom"
end

function disruptor_glimpse_custom:GetIntrinsicModifierName()
	return "modifier_disruptor_glimpse_custom"
end

function disruptor_kinetic_field_custom:GetIntrinsicModifierName()
	return "modifier_disruptor_kinetic_field_custom"
end

function disruptor_static_storm_custom:GetIntrinsicModifierName()
	return "modifier_disruptor_static_storm_custom"
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

local function FindRandomEnemy(caster, radius, heroesOnly)
	local enemies = FindEnemies(caster, caster:GetAbsOrigin(), radius, heroesOnly)
	if #enemies == 0 then return nil end
	return enemies[RandomInt(1, #enemies)]
end

modifier_disruptor_thunder_strike_custom = class({})

function modifier_disruptor_thunder_strike_custom:IsHidden() return true end
function modifier_disruptor_thunder_strike_custom:IsPurgable() return false end

function modifier_disruptor_thunder_strike_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_disruptor_thunder_strike_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local target = FindRandomEnemy(caster, ability:GetSpecialValueFor("search_radius"), false)
	if target then
		target:AddNewModifier(caster, ability, "modifier_disruptor_thunder_strike_custom_debuff", {
			duration = ability:GetSpecialValueFor("strikes") * ability:GetSpecialValueFor("strike_interval") + 0.1
		})
		EmitSoundOn("Hero_Disruptor.ThunderStrike.Target", target)
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("thunder_interval")))
end

modifier_disruptor_thunder_strike_custom_debuff = class({})

function modifier_disruptor_thunder_strike_custom_debuff:IsPurgable() return true end

function modifier_disruptor_thunder_strike_custom_debuff:OnCreated()
	if not IsServer() then return end
	self.strikes = 0
	self:StartIntervalThink(0.01)
end

function modifier_disruptor_thunder_strike_custom_debuff:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	if not ability or not caster then return end

	self.strikes = self.strikes + 1
	local radius = ability:GetSpecialValueFor("radius")
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_thunder_strike_bolt.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:ReleaseParticleIndex(particle)
	EmitSoundOn("Hero_Disruptor.ThunderStrike.Target", parent)

	for _, enemy in pairs(FindEnemies(caster, parent:GetAbsOrigin(), radius, false)) do
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			damage = ability:GetSpecialValueFor("strike_damage"),
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = ability,
		})
	end

	if self.strikes >= ability:GetSpecialValueFor("strikes") then
		self:Destroy()
		return
	end

	self:StartIntervalThink(ability:GetSpecialValueFor("strike_interval"))
end

function modifier_disruptor_thunder_strike_custom_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_disruptor_thunder_strike_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_amount")
end

modifier_disruptor_glimpse_custom = class({})

function modifier_disruptor_glimpse_custom:IsHidden() return true end
function modifier_disruptor_glimpse_custom:IsPurgable() return false end

function modifier_disruptor_glimpse_custom:OnCreated()
	if not IsServer() then return end
	self.positions = {}
	self:StartIntervalThink(0.25)
end

function modifier_disruptor_glimpse_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local now = GameRules:GetGameTime()
	for _, enemy in pairs(FindEnemies(caster, caster:GetAbsOrigin(), ability:GetSpecialValueFor("cast_range"), true)) do
		local index = enemy:entindex()
		self.positions[index] = self.positions[index] or {}
		table.insert(self.positions[index], { time = now, position = enemy:GetAbsOrigin() })
		while #self.positions[index] > 0 and now - self.positions[index][1].time > ability:GetSpecialValueFor("backtrack_time") do
			table.remove(self.positions[index], 1)
		end
	end

	if not self.nextGlimpse or now >= self.nextGlimpse then
		self:TryGlimpse(caster, ability, now)
		self.nextGlimpse = now + math.max(1.0, ability:GetSpecialValueFor("glimpse_interval"))
	end
end

function modifier_disruptor_glimpse_custom:TryGlimpse(caster, ability, now)
	local target = FindRandomEnemy(caster, ability:GetSpecialValueFor("cast_range"), true)
	if not target then return end

	local history = self.positions[target:entindex()]
	if not history or #history == 0 then return end

	local old = history[1].position
	local current = target:GetAbsOrigin()
	local distance = (current - old):Length2D()
	FindClearSpaceForUnit(target, old, true)
	EmitSoundOn("Hero_Disruptor.Glimpse.Target", target)

	local damage = math.min(
		ability:GetSpecialValueFor("max_damage"),
		math.max(ability:GetSpecialValueFor("min_damage"), distance * ability:GetSpecialValueFor("damage_to_distance_pct") / 100)
	)
	ApplyDamage({
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = ability,
	})
end

modifier_disruptor_kinetic_field_custom = class({})

function modifier_disruptor_kinetic_field_custom:IsHidden() return true end
function modifier_disruptor_kinetic_field_custom:IsPurgable() return false end

function modifier_disruptor_kinetic_field_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_disruptor_kinetic_field_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local target = FindRandomEnemy(caster, ability:GetSpecialValueFor("search_radius"), false)
	if target then
		local totalDuration = ability:GetSpecialValueFor("formation_time") + ability:GetSpecialValueFor("duration")
		CreateModifierThinker(caster, ability, "modifier_disruptor_kinetic_field_custom_area", {
			duration = totalDuration,
			active_duration = ability:GetSpecialValueFor("duration"),
			formation_time = ability:GetSpecialValueFor("formation_time"),
			radius = ability:GetSpecialValueFor("radius"),
		}, target:GetAbsOrigin(), caster:GetTeamNumber(), false)
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("field_interval")))
end

modifier_disruptor_kinetic_field_custom_area = class({})

function modifier_disruptor_kinetic_field_custom_area:IsHidden() return true end
function modifier_disruptor_kinetic_field_custom_area:IsPurgable() return false end

function modifier_disruptor_kinetic_field_custom_area:OnCreated(params)
	if not IsServer() then return end
	self.radius = params.radius or self:GetAbility():GetSpecialValueFor("radius")
	self.formationTime = params.formation_time or self:GetAbility():GetSpecialValueFor("formation_time")
	self.activeDuration = params.active_duration or self:GetAbility():GetSpecialValueFor("duration")
	self.totalDuration = self.formationTime + self.activeDuration
	self:SetDuration(self.totalDuration, true)
	local parent = self:GetParent()
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_kineticfield.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, parent:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, Vector(self.radius, self.formationTime, self.activeDuration))
	ParticleManager:SetParticleControl(particle, 2, Vector(self.totalDuration, 0, 0))
	self:AddParticle(particle, false, false, -1, false, false)
	EmitSoundOn("Hero_Disruptor.KineticField", parent)
	self:StartIntervalThink(0.1)
end

function modifier_disruptor_kinetic_field_custom_area:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local center = self:GetParent():GetAbsOrigin()
	for _, enemy in pairs(FindEnemies(caster, center, self.radius + 150, false)) do
		local offset = enemy:GetAbsOrigin() - center
		local distance = offset:Length2D()
		if distance > self.radius then
			FindClearSpaceForUnit(enemy, center + offset:Normalized() * (self.radius - 24), true)
		end
		local dps = ability:GetSpecialValueFor("damage_per_second")
		if dps > 0 and distance <= self.radius then
			ApplyDamage({
				victim = enemy,
				attacker = caster,
				damage = dps * 0.1,
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = ability,
			})
		end
	end
end

modifier_disruptor_static_storm_custom = class({})

function modifier_disruptor_static_storm_custom:IsHidden() return false end
function modifier_disruptor_static_storm_custom:IsPurgable() return false end

function modifier_disruptor_static_storm_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_disruptor_static_storm_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local target = FindRandomEnemy(caster, ability:GetSpecialValueFor("search_radius"), false)
	if target then
		local duration = ability:GetSpecialValueFor("duration")
		CreateModifierThinker(caster, ability, "modifier_disruptor_static_storm_custom_area", {
			duration = duration,
			storm_duration = duration,
			radius = ability:GetSpecialValueFor("radius"),
		}, target:GetAbsOrigin(), caster:GetTeamNumber(), false)
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("storm_interval")))
end

modifier_disruptor_static_storm_custom_area = class({})

function modifier_disruptor_static_storm_custom_area:IsHidden() return true end
function modifier_disruptor_static_storm_custom_area:IsPurgable() return false end

function modifier_disruptor_static_storm_custom_area:OnCreated(params)
	if not IsServer() then return end
	self.radius = params.radius or self:GetAbility():GetSpecialValueFor("radius")
	self.stormDuration = params.storm_duration or self:GetAbility():GetSpecialValueFor("duration")
	self:SetDuration(self.stormDuration, true)
	self.elapsed = 0
	local parent = self:GetParent()
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_static_storm.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, parent:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, Vector(self.radius, self.radius, self.radius))
	ParticleManager:SetParticleControl(particle, 2, Vector(self.stormDuration, 0, 0))
	self:AddParticle(particle, false, false, -1, false, false)
	EmitSoundOn("Hero_Disruptor.StaticStorm.Cast", parent)
	self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("tick_rate"))
end

function modifier_disruptor_static_storm_custom_area:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local tick = ability:GetSpecialValueFor("tick_rate")
	self.elapsed = self.elapsed + tick
	local damagePerTick = ability:GetSpecialValueFor("damage_max") / ability:GetSpecialValueFor("duration") * tick

	for _, enemy in pairs(FindEnemies(caster, self:GetParent():GetAbsOrigin(), self.radius, false)) do
		enemy:AddNewModifier(caster, ability, "modifier_disruptor_static_storm_custom_silence", { duration = tick + 0.1 })
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			damage = damagePerTick,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = ability,
		})
	end
end

modifier_disruptor_static_storm_custom_silence = class({})

function modifier_disruptor_static_storm_custom_silence:IsPurgable() return false end

function modifier_disruptor_static_storm_custom_silence:CheckState()
	return { [MODIFIER_STATE_SILENCED] = true }
end
