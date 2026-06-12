LinkLuaModifier("modifier_dazzle_poison_touch_custom", "dazzle_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dazzle_poison_touch_custom_debuff", "dazzle_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dazzle_shallow_grave_custom", "dazzle_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dazzle_shallow_grave_custom_buff", "dazzle_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dazzle_shadow_wave_custom", "dazzle_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dazzle_weave_custom", "dazzle_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dazzle_weave_custom_effect", "dazzle_passives_custom.lua", LUA_MODIFIER_MOTION_NONE)

dazzle_poison_touch_custom = class({})
dazzle_shallow_grave_custom = class({})
dazzle_shadow_wave_custom = class({})
dazzle_weave_custom = class({})

function dazzle_poison_touch_custom:GetIntrinsicModifierName()
	return "modifier_dazzle_poison_touch_custom"
end

function dazzle_shallow_grave_custom:GetIntrinsicModifierName()
	return "modifier_dazzle_shallow_grave_custom"
end

function dazzle_shadow_wave_custom:GetIntrinsicModifierName()
	return "modifier_dazzle_shadow_wave_custom"
end

function dazzle_weave_custom:GetIntrinsicModifierName()
	return "modifier_dazzle_weave_custom"
end

local function FindUnits(caster, team, position, radius)
	return FindUnitsInRadius(
		caster:GetTeamNumber(),
		position,
		nil,
		radius,
		team,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)
end

modifier_dazzle_poison_touch_custom = class({})

function modifier_dazzle_poison_touch_custom:IsHidden() return true end
function modifier_dazzle_poison_touch_custom:IsPurgable() return false end

function modifier_dazzle_poison_touch_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_dazzle_poison_touch_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local enemies = FindUnits(caster, DOTA_UNIT_TARGET_TEAM_ENEMY, caster:GetAbsOrigin(), ability:GetSpecialValueFor("search_radius"))
	if #enemies > 0 then
		local maxTargets = ability:GetSpecialValueFor("targets")
		for i = 1, math.min(maxTargets, #enemies) do
			local enemy = enemies[i]
			enemy:AddNewModifier(caster, ability, "modifier_dazzle_poison_touch_custom_debuff", {
				duration = ability:GetSpecialValueFor("duration")
			})
		end
		EmitSoundOn("Hero_Dazzle.Poison_Touch", caster)
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("poison_interval")))
end

modifier_dazzle_poison_touch_custom_debuff = class({})

function modifier_dazzle_poison_touch_custom_debuff:IsPurgable() return true end

function modifier_dazzle_poison_touch_custom_debuff:OnCreated()
	if not IsServer() then return end
	self.tick = 1.0
	self:StartIntervalThink(self.tick)
end

function modifier_dazzle_poison_touch_custom_debuff:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	if not ability or not caster then return end

	ApplyDamage({
		victim = self:GetParent(),
		attacker = caster,
		damage = ability:GetSpecialValueFor("damage"),
		damage_type = DAMAGE_TYPE_PHYSICAL,
		ability = ability,
	})
end

function modifier_dazzle_poison_touch_custom_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_dazzle_poison_touch_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow")
end

modifier_dazzle_shallow_grave_custom = class({})

function modifier_dazzle_shallow_grave_custom:IsHidden() return true end
function modifier_dazzle_shallow_grave_custom:IsPurgable() return false end

function modifier_dazzle_shallow_grave_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_dazzle_shallow_grave_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local allies = FindUnits(caster, DOTA_UNIT_TARGET_TEAM_FRIENDLY, caster:GetAbsOrigin(), ability:GetSpecialValueFor("search_radius"))
	local threshold = ability:GetSpecialValueFor("health_threshold_pct")
	for _, ally in pairs(allies) do
		if ally:IsHero() and ally:GetHealthPercent() <= threshold and not ally:HasModifier("modifier_dazzle_shallow_grave_custom_buff") then
			ally:AddNewModifier(caster, ability, "modifier_dazzle_shallow_grave_custom_buff", {
				duration = ability:GetSpecialValueFor("duration")
			})
			EmitSoundOn("Hero_Dazzle.Shallow_Grave", ally)
			self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("grave_interval")))
			return
		end
	end

	self:StartIntervalThink(0.5)
end

modifier_dazzle_shallow_grave_custom_buff = class({})

function modifier_dazzle_shallow_grave_custom_buff:IsPurgable() return false end

function modifier_dazzle_shallow_grave_custom_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MIN_HEALTH,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
	}
end

function modifier_dazzle_shallow_grave_custom_buff:GetMinHealth()
	return 1
end

function modifier_dazzle_shallow_grave_custom_buff:GetModifierHealAmplify_PercentageTarget()
	return self:GetAbility():GetSpecialValueFor("heal_amplify")
end

modifier_dazzle_shadow_wave_custom = class({})

function modifier_dazzle_shadow_wave_custom:IsHidden() return true end
function modifier_dazzle_shadow_wave_custom:IsPurgable() return false end

function modifier_dazzle_shadow_wave_custom:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_dazzle_shadow_wave_custom:OnIntervalThink()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() <= 0 then return end

	local caster = self:GetParent()
	local allies = FindUnits(caster, DOTA_UNIT_TARGET_TEAM_FRIENDLY, caster:GetAbsOrigin(), ability:GetSpecialValueFor("search_radius"))
	table.sort(allies, function(a, b) return a:GetHealthPercent() < b:GetHealthPercent() end)

	if #allies > 0 then
		self:ReleaseWave(caster, ability, allies[1])
	end

	self:StartIntervalThink(math.max(1.0, ability:GetSpecialValueFor("wave_interval")))
end

function modifier_dazzle_shadow_wave_custom:ReleaseWave(caster, ability, firstTarget)
	local touched = {}
	local touchedCount = 0
	local queue = { firstTarget }
	local maxTargets = ability:GetSpecialValueFor("max_targets")
	local bounceRadius = ability:GetSpecialValueFor("bounce_radius")

	EmitSoundOn("Hero_Dazzle.Shadow_Wave", caster)
	while #queue > 0 and touchedCount < maxTargets do
		local unit = table.remove(queue, 1)
		if unit and not unit:IsNull() and unit:IsAlive() and not touched[unit:entindex()] then
			touched[unit:entindex()] = true
			touchedCount = touchedCount + 1
			unit:Heal(ability:GetSpecialValueFor("damage"), ability)

			local enemies = FindUnits(caster, DOTA_UNIT_TARGET_TEAM_ENEMY, unit:GetAbsOrigin(), ability:GetSpecialValueFor("damage_radius"))
			for _, enemy in pairs(enemies) do
				ApplyDamage({
					victim = enemy,
					attacker = caster,
					damage = ability:GetSpecialValueFor("damage"),
					damage_type = DAMAGE_TYPE_PHYSICAL,
					ability = ability,
				})
			end

			local nextAllies = FindUnits(caster, DOTA_UNIT_TARGET_TEAM_FRIENDLY, unit:GetAbsOrigin(), bounceRadius)
			for _, ally in pairs(nextAllies) do
				if not touched[ally:entindex()] then
					table.insert(queue, ally)
				end
			end
		end
	end
end

modifier_dazzle_weave_custom = class({})

function modifier_dazzle_weave_custom:IsHidden() return false end
function modifier_dazzle_weave_custom:IsPurgable() return false end
function modifier_dazzle_weave_custom:IsAura() return true end
function modifier_dazzle_weave_custom:GetModifierAura() return "modifier_dazzle_weave_custom_effect" end
function modifier_dazzle_weave_custom:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_BOTH end
function modifier_dazzle_weave_custom:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dazzle_weave_custom:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_dazzle_weave_custom:GetAuraDuration() return 0.5 end

modifier_dazzle_weave_custom_effect = class({})

function modifier_dazzle_weave_custom_effect:IsPurgable() return false end

function modifier_dazzle_weave_custom_effect:OnCreated()
	self:SetStackCount(math.floor(self:GetAbility():GetSpecialValueFor("armor_per_second") * self:GetAbility():GetSpecialValueFor("duration")))
end

function modifier_dazzle_weave_custom_effect:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_dazzle_weave_custom_effect:GetModifierPhysicalArmorBonus()
	if self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber() then
		return self:GetStackCount()
	end
	return -self:GetStackCount()
end
