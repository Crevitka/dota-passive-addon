LinkLuaModifier("modifier_dark_willow_bramble_maze_custom", "dark_willow_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_willow_bramble_maze_custom_root", "dark_willow_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_willow_shadow_realm_custom", "dark_willow_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_willow_cursed_crown_custom", "dark_willow_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_willow_cursed_crown_custom_delay", "dark_willow_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_willow_terrorize_custom", "dark_willow_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_willow_terrorize_custom_fear", "dark_willow_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)

dark_willow_bramble_maze_custom = class({})
dark_willow_shadow_realm_custom = class({})
dark_willow_cursed_crown_custom = class({})
dark_willow_terrorize_custom = class({})

function dark_willow_bramble_maze_custom:GetIntrinsicModifierName()
	return "modifier_dark_willow_bramble_maze_custom"
end

function dark_willow_shadow_realm_custom:GetIntrinsicModifierName()
	return "modifier_dark_willow_shadow_realm_custom"
end

function dark_willow_cursed_crown_custom:GetIntrinsicModifierName()
	return "modifier_dark_willow_cursed_crown_custom"
end

function dark_willow_terrorize_custom:GetIntrinsicModifierName()
	return "modifier_dark_willow_terrorize_custom"
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

local function FindEnemiesAt(caster, position, radius)
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

modifier_dark_willow_bramble_maze_custom = class({})

function modifier_dark_willow_bramble_maze_custom:IsHidden() return true end
function modifier_dark_willow_bramble_maze_custom:IsPurgable() return false end

function modifier_dark_willow_bramble_maze_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_dark_willow_bramble_maze_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local target = FindRandomEnemy(caster, ability:GetSpecialValueFor("search_radius"))
	if target then
		self:CreateMaze(caster, ability, target:GetAbsOrigin())
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("bramble_interval")))
end

function modifier_dark_willow_bramble_maze_custom:CreateMaze(caster, ability, center)
	local count = ability:GetSpecialValueFor("placement_count")
	local range = ability:GetSpecialValueFor("placement_range")
	local latchRange = ability:GetSpecialValueFor("latch_range")
	local duration = ability:GetSpecialValueFor("latch_duration")

	EmitSoundOnLocationWithCaster(center, "Hero_DarkWillow.Bramble.Cast", caster)
	for i = 1, count do
		local position = center + RandomVector(RandomFloat(0, range))
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_willow/dark_willow_bramble.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, position)
		ParticleManager:ReleaseParticleIndex(particle)

		local enemies = FindEnemiesAt(caster, position, latchRange)
		for _, enemy in pairs(enemies) do
			enemy:AddNewModifier(caster, ability, "modifier_dark_willow_bramble_maze_custom_root", { duration = duration })
		end
	end
end

modifier_dark_willow_bramble_maze_custom_root = class({})

function modifier_dark_willow_bramble_maze_custom_root:IsPurgable() return true end

function modifier_dark_willow_bramble_maze_custom_root:OnCreated()
	if not IsServer() then return end
	self.tick = 1.0
	self:StartIntervalThink(self.tick)
end

function modifier_dark_willow_bramble_maze_custom_root:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	if not ability or not caster then return end

	ApplyDamage({
		victim = self:GetParent(),
		attacker = caster,
		damage = ability:GetSpecialValueFor("damage_per_tick"),
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = ability,
	})
end

function modifier_dark_willow_bramble_maze_custom_root:CheckState()
	return { [MODIFIER_STATE_ROOTED] = true }
end

modifier_dark_willow_shadow_realm_custom = class({})

function modifier_dark_willow_shadow_realm_custom:IsHidden() return false end
function modifier_dark_willow_shadow_realm_custom:IsPurgable() return false end

function modifier_dark_willow_shadow_realm_custom:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_dark_willow_shadow_realm_custom:GetModifierAttackRangeBonus()
	return self:GetAbility():GetSpecialValueFor("attack_range_bonus")
end

function modifier_dark_willow_shadow_realm_custom:OnAttackLanded(event)
	if not IsServer() or event.attacker ~= self:GetParent() then return end

	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 or not ability:IsCooldownReady() then return end

	ApplyDamage({
		victim = event.target,
		attacker = event.attacker,
		damage = ability:GetSpecialValueFor("damage"),
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = ability,
	})
	EmitSoundOn("Hero_DarkWillow.Shadow_Realm.Damage", event.target)
	ability:StartCooldown(ability:GetSpecialValueFor("attack_cooldown"))
end

modifier_dark_willow_cursed_crown_custom = class({})

function modifier_dark_willow_cursed_crown_custom:IsHidden() return true end
function modifier_dark_willow_cursed_crown_custom:IsPurgable() return false end

function modifier_dark_willow_cursed_crown_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_dark_willow_cursed_crown_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local target = FindRandomEnemy(caster, ability:GetSpecialValueFor("search_radius"))
	if target then
		target:AddNewModifier(caster, ability, "modifier_dark_willow_cursed_crown_custom_delay", {
			duration = ability:GetSpecialValueFor("delay")
		})
		EmitSoundOn("Hero_DarkWillow.CursedCrown.Cast", target)
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("crown_interval")))
end

modifier_dark_willow_cursed_crown_custom_delay = class({})

function modifier_dark_willow_cursed_crown_custom_delay:IsPurgable() return true end

function modifier_dark_willow_cursed_crown_custom_delay:OnDestroy()
	if not IsServer() then return end

	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	if not ability or not caster or not parent:IsAlive() then return end

	local position = parent:GetAbsOrigin()
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell_marker.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:ReleaseParticleIndex(particle)
	EmitSoundOnLocationWithCaster(position, "Hero_DarkWillow.CursedCrown.Stun", caster)

	local enemies = FindEnemiesAt(caster, position, ability:GetSpecialValueFor("stun_radius"))
	for _, enemy in pairs(enemies) do
		enemy:AddNewModifier(caster, ability, "modifier_stunned", {
			duration = ability:GetSpecialValueFor("stun_duration")
		})
	end
end

modifier_dark_willow_terrorize_custom = class({})

function modifier_dark_willow_terrorize_custom:IsHidden() return false end
function modifier_dark_willow_terrorize_custom:IsPurgable() return false end

function modifier_dark_willow_terrorize_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_dark_willow_terrorize_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local target = FindRandomEnemy(caster, ability:GetSpecialValueFor("search_radius"))
	if target then
		local position = target:GetAbsOrigin()
		local radius = ability:GetSpecialValueFor("destination_radius")
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_willow/dark_willow_terrorize.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, position)
		ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
		ParticleManager:ReleaseParticleIndex(particle)
		EmitSoundOnLocationWithCaster(position, "Hero_DarkWillow.Terrorize.Cast", caster)

		local enemies = FindEnemiesAt(caster, position, radius)
		for _, enemy in pairs(enemies) do
			enemy:AddNewModifier(caster, ability, "modifier_dark_willow_terrorize_custom_fear", {
				duration = ability:GetSpecialValueFor("destination_status_duration")
			})
			ApplyDamage({
				victim = enemy,
				attacker = caster,
				damage = ability:GetSpecialValueFor("impact_damage"),
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = ability,
			})
		end
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("terrorize_interval")))
end

modifier_dark_willow_terrorize_custom_fear = class({})

function modifier_dark_willow_terrorize_custom_fear:IsPurgable() return true end

function modifier_dark_willow_terrorize_custom_fear:CheckState()
	return {
		[MODIFIER_STATE_FEARED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end
