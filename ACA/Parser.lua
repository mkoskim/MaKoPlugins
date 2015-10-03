-- ****************************************************************************
-- ****************************************************************************
--
-- Alternative Combat Analyzer: Combat line parser, copied & modified from
-- CA parser.
--
-- ****************************************************************************
-- ****************************************************************************

import "MaKoPlugins.Utils";

local println = MaKoPlugins.Utils.println

-- ****************************************************************************
-- ****************************************************************************

UpdateType = {
    ["Damage"] = 1,
    -- 2,
    ["RestoreMorale"] = 3,
    ["RestorePower"] = 4,
    -- 5,
    -- 6,
    ["Interrupt"] = 7,
    ["Dispell"] = 8,
    ["Defeat"] = 9,
    ["Revive"] = 10,
    -- 11,
    -- 12,
    -- 13,
    ["Bubble"] = 14,
    ["Break"] = 16,
    ["Buff"] = 17,
}

-- ****************************************************************************

HitType = {
    ["Regular"] = 1,
    ["Critical"] = 2,
    ["Devastate"] = 3,
    ["Miss"] = 4,
    ["Immune"] = 5,
    ["Resist"] = 6,
    ["Block"] = 7,
    ["Parry"] = 8,
    ["Evade"] = 9,
    ["PartialBlock"] = 10,
    ["PartialParry"] = 11,
    ["PartialEvade"] = 12,
    ["Deflect"] = 13,
    ["Unknown"] = 14,
}

DamageType = {
    ["Common"] = 1,
    ["Fire"] = 2,
    ["Lightning"] = 3,
    ["Frost"] = 4,
    ["Acid"] = 5,
    ["Shadow"] = 6,
    ["Light"] = 7,
    ["Beleriand"] = 8,
    ["Westernesse"] = 9,
    ["AncientDwarf"] = 10,
    ["FellWrought"] = 11,
    ["OrcCraft"] = 12,
    ["Unknown"] = 13,
}

-- ****************************************************************************
-- ****************************************************************************

local function GetDamageType(dmgType)
	-- println("<%s>", dmgType)
	return
	    dmgType == nil and nil or
		dmgType == "Common " and DamageType.Common or
		dmgType == "Fire " and DamageType.Fire or
		dmgType == "Lightning " and DamageType.Lightning or
		dmgType == "Frost " and DamageType.Frost or
		dmgType == "Acid " and DamageType.Acid or
		dmgType == "Shadow " and DamageType.Shadow or
		dmgType == "Light " and DamageType.Light or
		dmgType == "Beleriand " and DamageType.Beleriand or
		dmgType == "Westernesse " and DamageType.Westernesse or
		dmgType == "Ancient Dwarf-make " and DamageType.AncientDwarf or
		DamageType.Unknown;
end

local function _parse(line)

    -- ------------------------------------------------------------------------
	-- 1) Damage line ---
    -- ------------------------------------------------------------------------
	
	local initiatorName, avoidAndCrit, skillName, targetNameAmountAndType = string.match(line,"^(.*) scored a (.*)hit(.*) on (.*)%.$"); -- (updated in v4.1.0)

	if (initiatorName ~= nil) then

		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");

		local hitType =
			string.match(avoidAndCrit,"^partially blocked") and HitType.PartialBlock or
			string.match(avoidAndCrit,"^partially parried") and HitType.PartialParry or
			string.match(avoidAndCrit,"^partially evaded")  and HitType.PartialEvade or
			string.match(avoidAndCrit,"critical $") and HitType.Critical or
			string.match(avoidAndCrit,"devastating $") and HitType.Devastate or
			HitType.Regular;

		skillName = string.match(skillName,"^ with (.*)$") or "Direct Damage"; -- (as of v4.1.0)

		local targetName, amount, dmgType, moralePower = string.match(targetNameAmountAndType,"^(.*) for ([%d,]*) (.*)damage to (.*)$");
		-- damage was absorbed
		if targetName == nil then
			targetName = string.gsub(targetNameAmountAndType,"^[Tt]he ","");
			amount = 0;
			dmgType = DamageType.Unknown;
			moralePower = 3;
		-- some damage was dealt
		else
			targetName = string.gsub(targetName,"^[Tt]he ","");
			amount = string.gsub(amount,",","")+0;

            dmgType = string.match(dmgType, "^%(.*%) (.*)$") or dmgType; -- 4.2.3 adjust for mounted combat
            dmgType = GetDamageType(dmgType)
	        moralePower = (moralePower == "Morale" and 1 or moralePower == "Power" and 2 or 3);
		end

		-- Currently ignores damage to power
		if (moralePower == 2) then return nil end

		-- Update
		return UpdateType.Damage,
		    initiatorName, targetName, skillName,
		    amount, hitType, dmgType;
	end

    -- ------------------------------------------------------------------------
	-- 2) Heal line --
	--     (note the distinction with which self heals are now handled)
	--     (note we consider the case of heals of zero magnitude, even though
	--     they presumably never occur)
    -- ------------------------------------------------------------------------

	local initiatorName, crit, skillNameTargetNameAmountAndType = string.match(line,"^(.*) applied a (.-)heal (.*)%.$");

	if (initiatorName ~= nil) then
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
		local critType =
			crit == "critical " and HitType.Critical or
			crit == "devastating " and HitType.Devastate or
			HitType.Regular;

		local skillNameTargetNameAndAmount, ending = string.match(skillNameTargetNameAmountAndType,"^(.*)to (.*)$");

		local targetName,skillName,amount;

		moralePower = (ending == "Morale" and 1 or (ending == "Power" and 2 or 3));
		-- heal was absorbed (unfortunately it appears this actually shows as a "hit" instead, so we never get into the first conditional)
		if (moralePower == 3) then
			targetName = string.gsub(ending,"^[Tt]he ","");
			amount = 0;
			-- skill name will equal nil if this was a self heal
			skillName = string.match(skillNameTargetNameAndAmount,"^with (.*) $");
		-- heal applied
		else
			skillName,targetName,amount = string.match(skillNameTargetNameAndAmount,"^(.*)to (.*) restoring ([%d,]*) points? $");
			targetName = string.gsub(targetName,"^[Tt]he ","");
			amount = string.gsub(amount,",","")+0;
			-- skill name will equal nil if this was a self heal
			skillName = string.match(skillName,"^with (.*) $");
		end

		-- rearrange if this was a self heal
		if (skillName == nil) then
			skillName = initiatorName;
			initiatorName = targetName;
		end

		-- Update
		return (moralePower == 2 and UpdateType.RestorePower or UpdateType.RestoreMorale),
		    initiatorName, targetName, skillName, amount, critType;
	end

    -- ------------------------------------------------------------------------
	-- 3) Buff line --
    -- ------------------------------------------------------------------------

	local initiatorName, skillName, targetName = string.match(line,"^(.*) applied a benefit with (.*) on (.*)%.$");

	if (initiatorName ~= nil) then
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
		targetName = string.gsub(targetName,"^[Tt]he ","");

		-- Update
		return UpdateType.Buff, initiatorName, targetName, skillName;
	end

    -- ------------------------------------------------------------------------
	-- 4) (Full) Avoid line --
    -- ------------------------------------------------------------------------

	local initiatorNameMiss, skillName, targetNameAvoidType = string.match(line,"^(.*) to use (.*) on (.*)%.$");
	
	if (initiatorNameMiss ~= nil) then
		initiatorName = string.match(initiatorNameMiss,"^(.*) tried$");
		local targetName, avoidType = HitType.Uknown;
		-- standard avoid
		if (initiatorName ~= nil) then
			initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
			targetName,avoidType = string.match(targetNameAvoidType,"^(.*) but (.*) the attempt$");
			targetName = string.gsub(targetName,"^[Tt]he ","");
			avoidType = 
				string.match(avoidType," blocked$") and HitType.Block or
				string.match(avoidType," parried$") and HitType.Parry or
				string.match(avoidType," evaded$") and HitType.Evade or
				string.match(avoidType," resisted$") and HitType.Resist or
				string.match(avoidType," was immune to$") and HitType.Immune or
				HitType.Unknown;

		-- miss or deflect (deflect added in v4.2.2)
		else
			initiatorName = string.match(initiatorNameMiss,"^(.*) missed trying$");

            if (initiatorName == nil) then
                initiatorName = string.match(initiatorNameMiss,"^(.*) was deflected trying$");
                avoidType = HitType.Deflect;
            else
                avoidType = HitType.Miss;
            end

			initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
			targetName = string.gsub(targetNameAvoidType,"^[Tt]he ","");
		end

		-- Sanity check: must have avoided in some manner
		if (avoidType == HitType.Unknown) then return nil end

		-- Update
		return UpdateType.Damage,
		    initiatorName, targetName, skillName,
		    0, avoidType, DamageType.Unknown
	    ;
	end

    -- ------------------------------------------------------------------------
	-- 5) Reflect line --
    -- ------------------------------------------------------------------------

	local initiatorName, amount, dmgType, targetName = string.match(line,"^(.*) reflected ([%d,]*) (.*) to the Morale of (.*)%.$");

	if (initiatorName ~= nil) then
		local skillName = "Reflect";
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
		targetName = string.gsub(targetName,"^[Tt]he ","");
		amount = string.gsub(amount,",","")+0;

		local dmgType = string.match(dmgType,"^(.*)damage$");
		dmgType = GetDamageType(dmgType)

		-- a damage reflect
        if dmgType ~= nil then
			-- Update
			return UpdateType.Damage,
			    initiatorName, targetName, skillName,
			    amount, HitType.Regular, dmgType;
		-- a heal reflect
		else
			-- Update
			return UpdateType.RestoreMorale,
			    initiatorName, targetName, skillName,
			    amount, HitType.Regular;
		end
	end

    -- ------------------------------------------------------------------------
	-- 6) Temporary Morale bubble line (as of 4.1.0)
    -- ------------------------------------------------------------------------

    local amount = string.match(line,"^You have lost ([%d,]*) points of temporary Morale!$");
	if (amount ~= nil) then
		amount = string.gsub(amount,",","")+0;

		-- the only information we can extract directly is the target and amount
		return UpdateType.Bubble, nil, player.name, nil, amount;
	end

    -- ------------------------------------------------------------------------
	-- 7) Combat State Break notice (as of 4.1.0)
    -- ------------------------------------------------------------------------

	-- 7a) Root broken
	local targetName = string.match(line,"^.* ha[sv]e? released (.*) from being immobilized!$");
	if (targetName ~= nil) then
		targetName = string.gsub(targetName,"^[Tt]he ","");

		-- the only information we can extract directly is the target name
		return UpdateType.Break, nil, targetName, nil;
	end

	-- 7b) Daze broken
	local targetName = string.match(line,"^.* ha[sv]e? freed (.*) from a daze!$");
	if (targetName ~= nil) then
		targetName = string.gsub(targetName,"^[Tt]he ","");

		-- the only information we can extract directly is the target name
		return UpdateType.Break, nil, targetName, nil;
	end

	-- 7c) Fear broken (TODO: Check)
	local targetName = string.match(line,"^.* ha[sv]e? freed (.*) from a fear!$");
	if (targetName ~= nil) then
		targetName = string.gsub(targetName,"^[Tt]he ","");

		-- the only information we can extract directly is the target name
		return UpdateType.Break, nil, targetName, nil;
	end

    -- ------------------------------------------------------------------------
	-- 8) Interrupt line --
    -- ------------------------------------------------------------------------

	local targetName, initiatorName = string.match(line,"^(.*) was interrupted by (.*)!$");

	if (targetName ~= nil) then
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
		targetName = string.gsub(targetName,"^[Tt]he ","");

		-- Update
		return UpdateType.Interrupt, initiatorName, targetName;
	end

    -- ------------------------------------------------------------------------
	-- 9) Dispell line (corruption removal) --
    -- ------------------------------------------------------------------------

	local corruption, targetName = string.match(line,"You have dispelled (.*) from (.*)%.$");

	if (corruption ~= nil) then
		initiatorName = player.name;
		targetName = string.gsub(targetName,"^[Tt]he ","");

		-- NB: Currently ignore corruption name

		-- Update
		return UpdateType.Dispell, initiatorName, targetName;
	end

    -- ------------------------------------------------------------------------
	-- 10) Defeat lines ---
    -- ------------------------------------------------------------------------

	-- 10a) Defeat line 1 (mob or played was killed)
	local initiatorName = string.match(line,"^.* defeated (.*)%.$");

	if (initiatorName ~= nil) then
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");

		-- Update
		return UpdateType.Defeat, initiatorName;
	end

	-- 10b) Defeat line 2 (mob died)
	local initiatorName = string.match(line,"^(.*) died%.$");

	if (initiatorName ~= nil) then
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");

		-- Update
		return UpdateType.Defeat, initiatorName;
	end

	-- 10c) Defeat line 3 (a player was killed or died)
	local initiatorName = string.match(line,"^(.*) has been defeated%.$");

	if (initiatorName ~= nil) then
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");

		-- Update
		return UpdateType.Defeat, initiatorName;
	end

	-- 10d) Defeat line 4 (you were killed)
	local match = string.match(line,"^.* incapacitated you%.$");

	if (match ~= nil) then
		initiatorName = player.name;

		-- Update
		return UpdateType.Defeat, initiatorName;
	end

	-- 10e) Defeat line 5 (you died)
	local match = string.match(line,"^You have been incapacitated by misadventure%.$");

	if (match ~= nil) then
		initiatorName = player.name;

		-- Update
		return UpdateType.Defeat, initiatorName;
	end

	-- 10f) Defeat line 6 (you killed a mob)
	local initiatorName = string.match(line,"^Your mighty blow topples (.*)%.$");

	if (initiatorName ~= nil) then
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");

		-- Update
		return UpdateType.Defeat, initiatorName;
	end

    -- ------------------------------------------------------------------------
	-- 11) Revive lines --
    -- ------------------------------------------------------------------------

	-- 11a) Revive line 1 (player revived)
	local initiatorName = string.match(line,"^(.*) has been revived%.$");

	if (initiatorName ~= nil) then
	  initiatorName = string.gsub(initiatorName,"^[Tt]he ","");

		-- Update
	  return UpdateType.Revive, initiatorName;
	end

	-- 11b) Revive line 2 (player succumbed)
	local initiatorName = string.match(line,"^(.*) has succumbed to .* wounds%.$");

	if (initiatorName ~= nil) then
	  initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
  
		-- Update
	  return UpdateType.Revive, initiatorName;
	end

	-- 11c) Revive line 3 (you were revived)
	local match = string.match(line,"^You have been revived%.$");

	if (match ~= nil) then
	  initiatorName = player.name;
  
		-- Update
	  return UpdateType.Revive, initiatorName;
	end

	-- 11d) Revive line 4 (you succumbed)
	local match = string.match(line,"^You succumb to your wounds%.$");

	if (match ~= nil) then
	  initiatorName = player.name;
  
		-- Update
	  return UpdateType.Revive, initiatorName;
	end

	-- if we reach here, we were unable to parse the line
	--  (note there is very little that isn't parsed)

    -- Currently, at least these lines are not parsed:
    -- "xxx has been cured"
    -- "Nothing to cure"

    -- println("WARNING! Unable to parse: " .. line)
    return nil;
end

-- ****************************************************************************
-- ****************************************************************************

function parse(line)
    local updateType, initiatorName, targetName, skillName,
        var1, var2, var3, var4 = _parse(
            string.gsub(
                string.gsub(line,"<rgb=#......>(.*)</rgb>","%1"),
                "^%s*(.-)%s*$", "%1"
            )
        );

    return updateType, initiatorName, targetName, skillName,
        var1, var2, var3, var4
end

