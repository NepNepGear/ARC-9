SWEP.StatCache = {}
SWEP.HookCache = {}
SWEP.AffectorsCache = nil
SWEP.HasNoAffectors = {}

SWEP.ExcludeFromRawStats = {
    ["PrintName"] = true,
}

function SWEP:InvalidateCache()
    self.StatCache = {}
    self.HookCache = {}
    self.AffectorsCache = nil
    self.ElementsCache = nil
    self.RecoilPatternCache = {}
    self.ScrollLevels = {}
    self.HasNoAffectors = {}

    self:SetBaseSettings()
end

function SWEP:RunHook(val, data)
    local any = false

    if self.HookCache[val] then
        for _, chook in pairs(self.HookCache[val]) do
            local d = chook(self, data)

            if d != nil then
                data = d
            end

            any = true
        end

        return data, any
    end

    self.HookCache[val] = {}

    for _, tbl in ipairs(self:GetAllAffectors()) do
        if tbl[val] then

            table.insert(self.HookCache[val], tbl[val])

            if !pcall(function()
                local d = tbl[val](self, data)

                if d != nil then
                    data = d
                end

                any = true
            end) then
                print("!!! ARC9 ERROR - \"" .. (tbl["PrintName"] or "Unknown") .. "\" TRIED TO RUN INVALID HOOK ON " .. val .. "!")
            end
        end
    end

    return data, any
end

function SWEP:GetFinalAttTableFromAddress(address)
    return self:GetFinalAttTable(self:LocateSlotFromAddress(address))
end

function SWEP:GetFinalAttTable(slot)
    if !slot then return {} end
    if !slot.Installed then return {} end

    local atttbl = ARC9.GetAttTable(slot.Installed)

    if !atttbl then return {} end

    if atttbl.ToggleStats then
        local tbl = table.Copy(atttbl)
        local toggletbl = atttbl.ToggleStats[slot.ToggleNum or 1] or {}

        table.Merge(tbl, toggletbl)

        return tbl
    else
        return atttbl
    end
end

function SWEP:GetAllAffectors()
    if self.AffectorsCache then return self.AffectorsCache end

    local aff = {}

    table.insert(aff, self:GetTable())

    if !ARC9.Overrun then
        ARC9.Overrun = true
        local sight = self:GetSight()

        if sight.OriginalSightTable then
            table.insert(aff, sight.OriginalSightTable)
        end

        ARC9.Overrun = false
    end

    for _, slot in ipairs(self:GetSubSlotList()) do
        local atttbl = self:GetFinalAttTable(slot)

        if atttbl then
            table.insert(aff, atttbl)
        end
    end

    local config = string.Split( GetConVar("arc9_modifiers"):GetString(), "\\n" )
    local c4 = {}
    for i, v in ipairs(config) do
        local swig = string.Split( v, "\\t" )
        -- local c2 = c4[swig[1]]
        if tonumber(swig[2]) then
            c4[swig[1]] = tonumber(swig[2])
        elseif swig[2] == "true" or swig[2] == "false" then
            c4[swig[1]] = swig[2] == "true"
        else
            c4[swig[1]] = swig[2]
        end
    end
    table.insert(aff, c4)

    if !ARC9.Overrun then
        ARC9.Overrun = true
        table.insert(aff, self:GetCurrentFiremodeTable())
        ARC9.Overrun = false
    end

    self.AffectorsCache = aff

    return aff
end

local Lerp = function(a, v1, v2)
    local d = v2 - v1

    return v1 + (a * d)
end

// local pvtick = 0
// local pv_move = 0
// local pv_shooting = 0
// local pv_melee = 0

SWEP.PV_Tick = 0
SWEP.PV_Move = 0
SWEP.PV_Shooting = 0
SWEP.PV_Melee = 0

SWEP.PV_Cache = {}

function SWEP:GetProcessedValue(val, base)
    if CLIENT and self.PV_Cache[tostring(val) .. tostring(base)] != nil and self.PV_Tick == UnPredictedCurTime() then
        return self.PV_Cache[tostring(val) .. tostring(base)]
    end

    if self.PV_Tick != UnPredictedCurTime() then
        self.PV_Cache = {}
    end

    local stat = self:GetValue(val, base)

    local ubgl = self:GetUBGL()
    local owner = self:GetOwner()

    -- if true then return stat end

    if self:GetJammed() and val == "Malfunction" then
        return true
    end

    if self:GetHeatLockout() and val == "Overheat" then
        return true
    end

    if owner:IsNPC() then
        stat = self:GetValue(val, stat, "NPC")
    end

    if GetConVar("arc9_truenames"):GetBool() then
        stat = self:GetValue(val, stat, "True")
    end

    if owner:IsValid() and !owner:IsNPC() then
        if !owner:OnGround() or owner:GetMoveType() == MOVETYPE_NOCLIP then
            stat = self:GetValue(val, stat, "MidAir")
        end

        if owner:Crouching() and owner:OnGround() then
            stat = self:GetValue(val, stat, "Crouch")
        end
    end

    if self:GetBurstCount() == 0 then
        stat = self:GetValue(val, stat, "FirstShot")
    end

    if self:Clip1() == 0 then
        stat = self:GetValue(val, stat, "Empty")
    end

    if !ubgl and self:GetValue("Silencer") then
        stat = self:GetValue(val, stat, "Silenced")
    end

    if ubgl then
        stat = self:GetValue(val, stat, "UBGL")

        if self:Clip2() == 0 then
            stat = self:GetValue(val, stat, "EmptyUBGL")
        end
    end

    if bit.band(self:GetNthShot(), 1) == 0 then
        stat = self:GetValue(val, stat, "EvenShot")
    else
        stat = self:GetValue(val, stat, "OddShot")
    end

    if bit.band(self:GetNthReload(), 1) == 0  then
        stat = self:GetValue(val, stat, "EvenReload")
    else
        stat = self:GetValue(val, stat, "OddReload")
    end

    if self:GetBlindFire() then
        stat = self:GetValue(val, stat, "BlindFire")
    end

    if self:GetBipod() then
        stat = self:GetValue(val, stat, "Bipod")
    end

    if !self.HasNoAffectors[val .. "Sights"] or !self.HasNoAffectors[val .. "HipFire"] then
        if isnumber(stat) then
            local hipfire = self:GetValue(val, stat, "HipFire")
            local sights = self:GetValue(val, stat, "Sights")

            if isnumber(hipfire) and isnumber(sights) then
                stat = Lerp(self:GetSightAmount(), hipfire, sights)
            end
        else
            if self:GetSightAmount() >= 1 then
                stat = self:GetValue(val, stat, "Sights")
            else
                stat = self:GetValue(val, stat, "HipFire")
            end
        end
    end

    if !self.HasNoAffectors[val .. "Melee"] then
        if self:GetLastMeleeTime() < CurTime() then
            local d = self.PV_Melee

            if self.PV_Tick != UnPredictedCurTime() then
                local pft = CurTime() - self:GetLastMeleeTime()
                d = pft / (self:GetValue("PreBashTime") + self:GetValue("PostBashTime"))

                d = math.Clamp(d, 0, 1)

                d = 1 - d

                self.PV_Melee = d
            end

            if isnumber(stat) then
                stat = Lerp(d, stat, self:GetValue(val, stat, "Melee"))
            else
                if d > 0 then
                    stat = self:GetValue(val, stat, "Melee")
                end
            end
        end
    end

    if !self.HasNoAffectors[val .. "Shooting"] then
        if self:GetNextPrimaryFire() + 0.1 > CurTime() then
            local d = self.PV_Shooting

            if self.PV_Tick != UnPredictedCurTime() then
                local pft = CurTime() - self:GetNextPrimaryFire() + 0.1
                d = pft / 0.1

                d = math.Clamp(d, 0, 1)

                self.PV_Shooting = d
            end

            if isnumber(stat) then
                stat = Lerp(d, stat, self:GetValue(val, stat, "Shooting"))
            else
                if d > 0 then
                    stat = self:GetValue(val, stat, "Shooting")
                end
            end
        end
    end

    if !self.HasNoAffectors[val .. "Recoil"] then
        if self:GetRecoilAmount() > 0 then
            stat = self:GetValue(val, stat, "Recoil", self:GetRecoilAmount())
        end
    end

    if !self.HasNoAffectors[val .. "Move"] then
        if owner:IsValid() then
            local spd = self.PV_Move
            if game.SinglePlayer() or self.PV_Tick != UnPredictedCurTime() then
                spd = math.min(owner:GetAbsVelocity():Length(), 250)

                spd = spd / 250

                self.PV_Move = spd
            end

            if isnumber(stat) then
                stat = Lerp(spd, stat, self:GetValue(val, stat, "Move"))
            else
                if spd > 0 then
                    stat = self:GetValue(val, stat, "Move")
                end
            end
        end
    end

    self.PV_Tick = UnPredictedCurTime()
    self.PV_Cache[tostring(val) .. tostring(base)] = stat

    return stat
end

function SWEP:GetValue(val, base, condition, amount)
    condition = condition or ""
    amount = amount or 1
    local stat = base

    if stat == nil then
        stat = self:GetTable()[val]
    end

    if self.HasNoAffectors[val .. condition] == true then
        return stat
    end

    local unaffected = true

    if istable(stat) then
        stat.BaseClass = nil
    end

    if self.StatCache[tostring(base) .. val .. condition] != nil then
        -- stat = self.StatCache[tostring(base) .. val .. condition]
        stat = self.StatCache[tostring(base) .. val .. condition]

        local oldstat = stat
        stat = self:RunHook(val .. "Hook" .. condition, stat)

        if stat == nil then
            stat = oldstat
        end

        -- if istable(stat) then
        --     stat.BaseClass = nil
        -- end

        return stat
    end

    local priority = 0

    if !self.ExcludeFromRawStats[val] then
        for _, tbl in ipairs(self:GetAllAffectors()) do
            local att_priority = tbl[val .. condition .. "_Priority"] or 1

            if tbl[val .. condition] != nil and att_priority >= priority then
                stat = tbl[val .. condition]
                priority = att_priority
                unaffected = false
            end
        end
    end

    for _, tbl in ipairs(self:GetAllAffectors()) do
        local att_priority = tbl[val .. "Override" .. condition .. "_Priority"] or 1

        if tbl[val .. "Override" .. condition] != nil and att_priority >= priority then
            stat = tbl[val .. "Override" .. condition]
            priority = att_priority
            unaffected = false
        end
    end

    if isnumber(stat) then

        for _, tbl in ipairs(self:GetAllAffectors()) do
            if tbl[val .. "Add" .. condition] != nil then
                -- if !pcall(function() stat = stat + (tbl[val .. "Add" .. condition] * amount) end) then
                --     print("!!! ARC9 ERROR - \"" .. (tbl["PrintName"] or "Unknown") .. "\" TRIED TO ADD INVALID VALUE: (" .. tbl[val .. "Add" .. condition] .. ") TO " .. val .. "!")
                -- end
                if type(tbl[val .. "Add" .. condition]) == type(stat) then
                    stat = stat + (tbl[val .. "Add" .. condition] * amount)
                end
                unaffected = false
            end
        end

        for _, tbl in ipairs(self:GetAllAffectors()) do
            if tbl[val .. "Mult" .. condition] != nil then
                -- if !pcall(function() stat = stat * math.pow(tbl[val .. "Mult" .. condition], amount) end) then
                --     print("!!! ARC9 ERROR - \"" .. (tbl["PrintName"] or "Unknown") .. "\" TRIED TO MULTIPLY INVALID VALUE: (" .. tbl[val .. "Add" .. condition] .. ") TO " .. val .. "!")
                -- end
                if type(tbl[val .. "Mult" .. condition]) == type(stat) then
                    if amount > 1 then
                        stat = stat * (math.pow(tbl[val .. "Mult" .. condition], amount))
                    else
                        stat = stat * tbl[val .. "Mult" .. condition]
                    end
                end
                unaffected = false
            end
        end

    end

    self.StatCache[tostring(base) .. val .. condition] = stat
    -- self.StatCache[tostring(base) .. val .. condition] = stat

    local newstat, any = self:RunHook(val .. "Hook" .. condition, stat)

    stat = newstat or stat

    if any then unaffected = false end

    self.HasNoAffectors[val .. condition] = unaffected

    if istable(stat) then
        stat.BaseClass = nil
    end

    return stat
end