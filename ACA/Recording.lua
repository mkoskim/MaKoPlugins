-- ****************************************************************************
-- ****************************************************************************
--
-- Alternative Combat Analyzer: Event recording
--
-- ****************************************************************************
-- ****************************************************************************

import "MaKoPlugins.Utils";
import "MaKoPlugins.ACA.Parser";

local println = MaKoPlugins.Utils.println

-- ****************************************************************************
-- ****************************************************************************
--
-- Recorded damage:
--
-- ****************************************************************************
-- ****************************************************************************

local DamageRecord = class()

function DamageRecord:Constructor(dealer, skill, target)

    self.dealer = dealer
    self.skill = skill
    self.target = target
    self.count = 0

    -- ------------------------------------------------------------------------

    self.hits  = { }
    for name, key in pairs(HitType) do
        self.hits[key] = { ["count"] = 0, ["sum"] = 0 }
    end

    -- ------------------------------------------------------------------------

    self.dmgtypes = { }
    for name, key in pairs(DamageType) do
        self.dmgtypes[key] = 0
    end

    -- ------------------------------------------------------------------------

    self.derived = nil

end

-- ----------------------------------------------------------------------------

function DamageRecord:UpdateEntry(key, amount, dmgtype)
    self.hits[key].count = self.hits[key].count + 1
    self.hits[key].sum   = self.hits[key].sum + amount

    self.dmgtypes[dmgtype] = self.dmgtypes[dmgtype] + amount
end

-- ----------------------------------------------------------------------------

function DamageRecord:HitCount(key)
    return self.hits[key].count
end

function DamageRecord:HitTotal(key)
    return self.hits[key].sum
end

function DamageRecord:HitAverage(key)
    return self:EntryTotal(key) / self:EntryCount(key)
end

-- ----------------------------------------------------------------------------

function DamageRecord:Summary(...)
    count = 0
    sum   = 0
    estimate = 0

    for i, key in ipairs(arg) do
        count = count + self:HitCount(key)
        sum   = sum   + self:HitTotal(key)
        if self.derived ~= nil and self.derived[key] ~= nil then
            estimate = estimate + self.derived[key].estimate
        end
    end
    return {
        ["count"] = count,
        ["sum"] = sum,
        ["average"] = (count > 0) and (sum / count) or 0,
        ["estimate"] = estimate,
    }
end

function DamageRecord:Hits()
    return self:Summary(
        HitType.Regular, HitType.Critical, HitType.Devastate
    )
end

function DamageRecord:Partials()
    return self:Summary(
        HitType.PartialEvade, HitType.PartialParry, HitType.PartialBlock
    )
end

function DamageRecord:BPEd()
    return self:Summary(HitType.Block, HitType.Parry, HitType.Evade)
end

function DamageRecord:Resists()
    return self:Summary(HitType.Resist)
end

function DamageRecord:Other()
    return self:Summary(HitType.Immune, HitType.Miss, HitType.Deflect)
end

function DamageRecord:Avoids()
    return self:Summary(
        HitType.Block, HitType.Parry, HitType.Evade,
        HitType.Resist,
        HitType.Immune, HitType.Miss, HitType.Deflect
    )
end

-- ----------------------------------------------------------------------------

function DamageRecord:Update(amount, hittype, dmgtype)
    self.count = self.count + 1
    self:UpdateEntry(hittype, amount, dmgtype)
end

-- ----------------------------------------------------------------------------
--
-- Merge: This is meant to be used to gather summary info from single records.
-- Thus, we calculate derived fields here. Don't merge actual records to each
-- other, make a temporary object to hold merged data.
--
-- ----------------------------------------------------------------------------

function DamageRecord:Merge(record)

    if self.dealer ~= nil and self.dealer ~= record.dealer then self.dealer = nil end
    if self.target ~= nil and self.target ~= record.target then self.target = nil end
    if self.skill ~= nil  and self.skill  ~= record.skill  then self.skill = nil end

    self.count = self.count + record.count

    for key,_ in pairs(self.hits) do
        self.hits[key].count = self.hits[key].count + record.hits[key].count
        self.hits[key].sum   = self.hits[key].sum   + record.hits[key].sum
    end

    for key,_ in pairs(self.dmgtypes) do
        self.dmgtypes[key] = self.dmgtypes[key] + record.dmgtypes[key]
    end

    if self.derived == nil then
        self.derived = {
            [HitType.PartialBlock] = { ["estimate"] = 0 },
            [HitType.PartialParry] = { ["estimate"] = 0 },
            [HitType.PartialEvade] = { ["estimate"] = 0 },

            [HitType.Block]  = { ["estimate"] = 0 },
            [HitType.Parry]  = { ["estimate"] = 0 },
            [HitType.Evade]  = { ["estimate"] = 0 },
            [HitType.Resist] = { ["estimate"] = 0 },

            [HitType.Immune]  = { ["estimate"] = 0 },
            [HitType.Miss]    = { ["estimate"] = 0 },
            [HitType.Deflect] = { ["estimate"] = 0 },
        }
    end

    local success = record:Hits();
    for key, _ in pairs(self.derived) do
        self.derived[key].estimate =
            self.derived[key].estimate + record.hits[key].count * success.average
    end
end

-- ****************************************************************************
-- ****************************************************************************
--
-- Analyzer database management
--
-- ****************************************************************************
-- ****************************************************************************

damageDealt = { }
damageTaken = { }

local function ProcessEventLine(line)

	local eventtype, actor, target, skill, var1, var2, var3 = parse(line)

    if eventtype == UpdateType.Damage then

        local records = nil
        if actor == player:GetName() then
            records = damageDealt
        else
            records = damageTaken
        end
    
        if records[actor] == nil then records[actor] = { } end
        if records[actor][skill] == nil then records[actor][skill] = { } end
        if records[actor][skill][target] == nil then
            records[actor][skill][target] = DamageRecord(actor, skill, target, var3)
        end
        records[actor][skill][target]:Update(var1, var2, var3)
    end
end

-- ----------------------------------------------------------------------------

local function MessageReceived(sender, args)
    if  args.ChatType ~= Turbine.ChatType.PlayerCombat and
        args.ChatType ~= Turbine.ChatType.EnemyCombat then
        return
    end

    if Settings.Logging.Enabled then
        table.insert(Settings.Logging.Events, args.Message)
    end

    ProcessEventLine(args.Message)
end

-- ----------------------------------------------------------------------------

function ProcessLog(events)
    for k, line in ipairs(events) do
        ProcessEventLine(line)
    end
end

function Merge(tbl, dealers, skills, targets)
    totals = DamageRecord()

    for dealer, skills in pairs(tbl) do
        if dealers == nil or dealers[dealer] ~= nil then
            for skill, targets in pairs(skills) do
                if skills == nil or skills[skill] ~= nil then
                    for target, record in pairs(targets) do
                        if targets == nil or targets[target] ~= nil then
                            totals:Merge(record)
                        end
                    end
                end
            end
        end
    end
    return totals
end

