local function PaintScrollBar(panel, w, h)
    surface.SetDrawColor(ARC9.GetHUDColor("shadow"))
    surface.DrawRect(ScreenScale(3), 0 + ScreenScale(1), w - ScreenScale(3), h)

    surface.SetDrawColor(ARC9.GetHUDColor("fg"))
    surface.DrawRect(ScreenScale(2), 0, w - ScreenScale(3), h - ScreenScale(1))
end

-- given fov and distance solve apparent size
local function solvetriangle(angle, dist)
    local a = angle / 2
    local b = dist
    return b * math.tan(a) * 2
end

local hits_1 = {}
local hits_3 = {}

local function rollhit(radius)
    local anglerand = math.Rand(0, 360)
    local dist = math.Rand(0, radius)

    local hit_x = math.sin(anglerand) * dist
    local hit_y = math.cos(anglerand) * dist

    return {x = hit_x, y = hit_y}
end

local function rollallhits(self, range_3, range_1)

    hits_1 = {}
    hits_3 = {}

    local ang = self:GetValue("Spread") * 10 / 360

    local radius_1 = solvetriangle(ang, range_1)
    local radius_3 = solvetriangle(ang, range_3)

    local hitcount = math.Clamp(math.max(math.Round(self:GetCapacity(self:GetUBGL()) / 4), math.Round(self:GetValue("Num") * 2)), 10, 20)

    for i = 1, hitcount do
        table.insert(hits_1, rollhit(radius_1))
    end

    for i = 1, hitcount do
        table.insert(hits_3, rollhit(radius_3))
    end
end

local recoil_hits = {}

function SWEP:RollRecoilHit(shot, lastx, lasty)
    local dir = self:GetRecoilPatternDirection(shot)

    dir = math.rad(dir)

    recoilup = math.sin(dir)
    recoilside = math.cos(dir)

    local randomrecoilup = math.Rand(-1, 0)
    local randomrecoilside = math.Rand(-1, 1)

    recoilup = recoilup * self:GetProcessedValue("RecoilUp")
    recoilside = recoilside * self:GetProcessedValue("RecoilSide")

    randomrecoilup = randomrecoilup * self:GetProcessedValue("RecoilRandomUp")
    randomrecoilside = randomrecoilside * self:GetProcessedValue("RecoilRandomSide")

    recoilup = recoilup + randomrecoilup
    recoilside = recoilside + randomrecoilside

    recoilup = recoilup * self:GetProcessedValue("Recoil")
    recoilside = recoilside * self:GetProcessedValue("Recoil")

    recoil_hits[shot] = {
        x = recoilup + randomrecoilup + lastx,
        y = recoilside + randomrecoilside + lasty
    }
end

function SWEP:RollRecoil()
    recoil_hits = {}

    recoil_hits[1] = {
        x = 0,
        y = 0,
    }

    for i = 2, math.min(self:GetMaxClip1(), 100) do
        local lastx = recoil_hits[i - 1].x
        local lasty = recoil_hits[i - 1].y

        self:RollRecoilHit(i, lastx, lasty)
    end
end

local bullseye = Material("arc9/bullseye.png", "mips smooth")
local target_ipsc = Material("arc9/target_ipsc.png", "mips smooth")
local mat_hit = Material("arc9/hit.png", "mips smooth")
local mat_hit_dot = Material("arc9/hit_dot.png", "mips smooth")
local ranger_range = 0

local mat_body = Material("arc9/body.png", "mips smooth")
local mat_body_arms = Material("arc9/body_arms.png", "mips smooth")
local mat_body_head = Material("arc9/body_head.png", "mips smooth")
local mat_body_chest = Material("arc9/body_chest.png", "mips smooth")
local mat_body_stomach = Material("arc9/body_stomach.png", "mips smooth")
local mat_body_legs = Material("arc9/body_legs.png", "mips smooth")

local stk_clr = {
    [1] = Color(75, 25, 25),
    [2] = Color(40, 20, 20),
    [3] = Color(50, 50, 50),
    [4] = Color(75, 75, 75),
    [5] = Color(100, 100, 100),
    [6] = Color(120, 120, 120),
    [7] =  Color(140, 140, 140),
    [8] = Color(160, 160, 160),
    [9] = Color(200, 200, 200),
}

local function getstkcolor(stk)
    if stk_clr[stk] then
        return stk_clr[stk]
    else
        return stk_clr[9]
    end
end

function SWEP:CreateHUD_Bench()
    local bg = self.CustomizeHUD

    self:ClearTabPanel()

    local tp = vgui.Create("DScrollPanel", bg)
    tp:SetSize(ScreenScale(550), ScrH() - ScreenScale(126))
    tp:SetPos(ScrW() - ScreenScale(550 + 12), ScreenScale(76))
    // tp.Paint = function(self2, w, h)
    //     surface.SetDrawColor(255, 255, 255)
    //     surface.DrawRect(0, 0, w, h)
    // end

    local scroll_preset = tp:GetVBar()
    scroll_preset.Paint = function() end
    scroll_preset.btnUp.Paint = function(span, w, h)
    end
    scroll_preset.btnDown.Paint = function(span, w, h)
    end
    scroll_preset.btnGrip.Paint = PaintScrollBar

    self.TabPanel = tp

    self:RollRecoil()

    local recoilchart = vgui.Create("DButton", tp)
    recoilchart:SetSize(ScreenScale(220), ScreenScale(220))
    recoilchart:SetPos(ScreenScale(310), ScreenScale(0))
    recoilchart:SetText("")
    recoilchart.DoClick = function(self2)
        self:RollRecoil()
    end
    recoilchart.Paint = function(self2, w, h)
        surface.SetDrawColor(ARC9.GetHUDColor("bg", 50))
        surface.DrawRect(0, 0, w, h)

        surface.SetMaterial(target_ipsc)
        surface.SetDrawColor(ARC9.GetHUDColor("fg", 75))
        surface.DrawTexturedRect(0, 0, w, h)

        local scale = ScreenScale(8)

        for i = 1, math.min(self:GetMaxClip1(), 100) do
            local hit = recoil_hits[i]
            local x = -hit.x * scale + (w / 2)
            local y = -hit.y * scale + (h / 2)

            local s = ScreenScale(12)

            surface.SetMaterial(mat_hit)
            surface.SetDrawColor(ARC9.GetHUDColor("fg", 75))
            if i == 1 then
                surface.SetDrawColor(Color(255, 0, 0, 75))
            end
            surface.DrawTexturedRect(x - (s / 2), y - (s / 2), s, s)

            if i < math.min(self:GetMaxClip1(), 100) then
                local hit2 = recoil_hits[i + 1]
                local x2 = -hit2.x * scale + (w / 2)
                local y2 = -hit2.y * scale + (h / 2)

                surface.DrawLine(x, y, x2, y2)
            end
        end

        local txt_bottom = "ARCTIC SYSTEMS RECOIL TEST"
        surface.SetFont("ARC9_6")
        local tbw = surface.GetTextSize(txt_bottom)
        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.SetTextPos((w - tbw) / 2, h - ScreenScale(12))
        surface.DrawText(txt_bottom)
    end

    local dmgpanel = vgui.Create("DPanel", tp)
    dmgpanel:SetSize(ScreenScale(80), ScreenScale(100))
    dmgpanel:SetPos(ScreenScale(10), 0)
    dmgpanel.Paint = function(span, w, h)
        if !IsValid(self) then return end

        surface.SetDrawColor(ARC9.GetHUDColor("bg", 50))
        surface.DrawRect(0, 0, w, h)

        local dmgv = self:GetDamageAtRange(ranger_range)
        local bodydamage = self:GetProcessedValue("BodyDamageMults")

        local dmg_head = dmgv * self:GetProcessedValue("HeadshotDamage") * (bodydamage[HITGROUP_HEAD] or 2)
        local dmg_chest = dmgv * self:GetProcessedValue("ChestDamage") * (bodydamage[HITGROUP_CHEST] or 1)
        local dmg_stomach = dmgv * self:GetProcessedValue("StomachDamage") * (bodydamage[HITGROUP_STOMACH] or 1)
        local dmg_legs = dmgv * self:GetProcessedValue("LegDamage") * ((bodydamage[HITGROUP_LEFTLEG] or 0.25) + (bodydamage[HITGROUP_RIGHTLEG] or 0.25)) / 2
        local dmg_arms = dmgv * self:GetProcessedValue("ArmDamage") * ((bodydamage[HITGROUP_LEFTARM] or 0.25) + (bodydamage[HITGROUP_RIGHTARM] or 0.25)) / 2

        local stk_head = math.ceil(100 / dmg_head)
        local stk_chest = math.ceil(100 / dmg_chest)
        local stk_stomach = math.ceil(100 / dmg_stomach)
        local stk_legs = math.ceil(100 / dmg_legs)
        local stk_arms = math.ceil(100 / dmg_arms)
 
        // draw the body

        local body_w = ScreenScale(30)
        local body_h = ScreenScale(80)
        local body_x = (w - body_w) / 2
        local body_y = (h - body_h) / 2

        surface.SetDrawColor(Color(150, 150, 150, 255))
        surface.SetMaterial(mat_body)
        surface.DrawTexturedRect(body_x, body_y, body_w, body_h)

        local txt_dmg_head = tostring(math.Round(dmg_head, 0)) .. "DMG"
        local txt_dmg_chest = tostring(math.Round(dmg_chest, 0)) .. "DMG"
        local txt_dmg_stomach = tostring(math.Round(dmg_stomach, 0)) .. "DMG"
        local txt_dmg_legs = tostring(math.Round(dmg_legs, 0)) .. "DMG"
        local txt_dmg_arms = tostring(math.Round(dmg_arms, 0)) .. "DMG"

        surface.SetDrawColor(getstkcolor(stk_head))
        surface.SetMaterial(mat_body_head)
        surface.DrawTexturedRect(body_x, body_y, body_w, body_h)

        surface.SetDrawColor(getstkcolor(stk_chest))
        surface.SetMaterial(mat_body_chest)
        surface.DrawTexturedRect(body_x, body_y, body_w, body_h)

        surface.SetDrawColor(getstkcolor(stk_stomach))
        surface.SetMaterial(mat_body_stomach)
        surface.DrawTexturedRect(body_x, body_y, body_w, body_h)

        surface.SetDrawColor(getstkcolor(stk_legs))
        surface.SetMaterial(mat_body_legs)
        surface.DrawTexturedRect(body_x, body_y, body_w, body_h)

        surface.SetDrawColor(getstkcolor(stk_arms))
        surface.SetMaterial(mat_body_arms)
        surface.DrawTexturedRect(body_x, body_y, body_w, body_h)

        surface.SetFont("ARC9_6")
        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.SetTextPos(ScreenScale(4), ScreenScale(12))
        surface.DrawText(txt_dmg_head)

        surface.SetDrawColor(ARC9.GetHUDColor("fg"))
        surface.DrawLine(ScreenScale(4), ScreenScale(18), ScreenScale(38), ScreenScale(18))

        surface.SetFont("ARC9_6")
        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.SetTextPos(ScreenScale(4), ScreenScale(25))
        surface.DrawText(txt_dmg_chest)

        surface.SetDrawColor(ARC9.GetHUDColor("fg"))
        surface.DrawLine(ScreenScale(4), ScreenScale(25 + 6), ScreenScale(35), ScreenScale(25 + 6))

        surface.SetFont("ARC9_6")
        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.SetTextPos(ScreenScale(4), ScreenScale(35))
        surface.DrawText(txt_dmg_stomach)

        surface.SetDrawColor(ARC9.GetHUDColor("fg"))
        surface.DrawLine(ScreenScale(4), ScreenScale(35 + 6), ScreenScale(40), ScreenScale(35 + 6))

        surface.SetFont("ARC9_6")
        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.SetTextPos(ScreenScale(4), ScreenScale(50))
        surface.DrawText(txt_dmg_arms)

        surface.SetDrawColor(ARC9.GetHUDColor("fg"))
        surface.DrawLine(ScreenScale(4), ScreenScale(50 + 6), ScreenScale(27), ScreenScale(50 + 6))

        surface.SetFont("ARC9_6")
        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.SetTextPos(ScreenScale(4), ScreenScale(70))
        surface.DrawText(txt_dmg_legs)

        surface.SetDrawColor(ARC9.GetHUDColor("fg"))
        surface.DrawLine(ScreenScale(4), ScreenScale(70 + 6), ScreenScale(30), ScreenScale(70 + 6))

        local txt_tr = tostring(self:GetProcessedValue("Num")) .. "x PROJ"
        surface.SetFont("ARC9_6")
        local trw = surface.GetTextSize(txt_tr)
        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.SetTextPos(w - trw - ScreenScale(2), ScreenScale(10))
        surface.DrawText(txt_tr)

        local txt_corner = "BALLISTICS DUMMY TEST"
        surface.SetFont("ARC9_6")
        local tw = surface.GetTextSize(txt_corner)
        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.SetTextPos((w - tw) / 2, ScreenScale(1))
        surface.DrawText(txt_corner)

        local txt_bottom = "EFFECT AT RANGE " .. tostring(math.Round(ARC9.HUToM * ranger_range, 0)) .. "m"
        surface.SetFont("ARC9_6")
        local tbw = surface.GetTextSize(txt_bottom)
        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.SetTextPos((w - tbw) / 2, h - ScreenScale(8))
        surface.DrawText(txt_bottom)
    end

    local ranger = vgui.Create("DPanel", tp)
    ranger:SetPos(ScreenScale(100), 0)
    ranger:SetSize(ScreenScale(200), ScreenScale(100))
    ranger.Paint = function(self2, w, h)
        if !IsValid(self) then return end

        surface.SetDrawColor(ARC9.GetHUDColor("bg", 50))
        surface.DrawRect(0, 0, w, h)

        local dmg_max = self:GetValue("DamageMax")
        local dmg_min = self:GetValue("DamageMin")

        local range_min = self:GetValue("RangeMin")
        local range_max = self:GetValue("RangeMax")

        surface.SetDrawColor(ARC9.GetHUDColor("fg", 75))

        ranger_range = range_min

        local range_1_y = 2 * (h / 5)
        local range_2_y = 4 * (h / 5)

        local range_1_x = 0
        local range_2_x = (w / 3)
        local range_3_x = 2 * (w / 3)

        if dmg_max < dmg_min then
            range_1_y = 4 * (h / 5)
            range_2_y = 2 * (h / 5)
        elseif dmg_max == dmg_min then
            range_1_y = 3 * (h / 5)
            range_2_y = 3 * (h / 5)
        end

        if range_min == 0 then
            range_2_x = 0
            range_3_x = w / 2
        end

        surface.DrawLine(range_2_x, 0, range_2_x, h)
        surface.DrawLine(range_3_x, 0, range_3_x, h)

        surface.SetDrawColor(ARC9.GetHUDColor("fg"))

        for i = 0, 1 do
            surface.DrawLine(range_1_x, range_1_y + i, range_2_x, range_1_y + i)
            surface.DrawLine(range_2_x, range_1_y + i, range_3_x, range_2_y + i)
            surface.DrawLine(range_3_x, range_2_y + i, w, range_2_y + i)
        end

        local mouse_x, mouse_y = input.GetCursorPos()
        mouse_x, mouse_y = self2:ScreenToLocal(mouse_x, mouse_y)

        local draw_rangetext = true

        if mouse_x > 0 and mouse_x < w then
            if mouse_y > 0 and mouse_y < h then
                local range = 0

                local range_m_x = 0

                if mouse_x < range_2_x then
                    range = range_min
                    range_m_x = range_2_x
                elseif mouse_x > range_3_x then
                    range = range_max
                    range_m_x = range_3_x
                else
                    local d = (mouse_x - range_2_x) / (range_3_x - range_2_x)
                    range = Lerp(d, range_min, range_max)
                    range_m_x = mouse_x
                end

                ranger_range = range

                local dmg = self:GetDamageAtRange(range)

                local txt_dmg1 = tostring(math.Round(dmg)) .. " DAMAGE"

                if self:GetValue("Num") > 1 then
                    txt_dmg1 = math.Round(dmg * self:GetValue("Num")) .. "-" .. txt_dmg1
                end

                surface.SetTextColor(ARC9.GetHUDColor("fg"))
                surface.DrawLine(range_m_x, 0, range_m_x, h)

                surface.SetFont("ARC9_8")
                surface.SetTextColor(ARC9.GetHUDColor("fg"))
                local txt_dmg1_w = surface.GetTextSize(txt_dmg1)
                surface.SetTextPos((w / 3) - txt_dmg1_w - (ScreenScale(2)), ScreenScale(1))
                surface.DrawText(txt_dmg1)

                local txt_range1 = self:RangeUnitize(range)

                surface.SetFont("ARC9_8")
                surface.SetTextColor(ARC9.GetHUDColor("fg"))
                local txt_range1_w = surface.GetTextSize(txt_range1)
                surface.SetTextPos((w / 3) - txt_range1_w - (ScreenScale(2)), ScreenScale(1 + 8))
                surface.DrawText(txt_range1)

                draw_rangetext = false
            end
        end


        if draw_rangetext then
            local txt_dmg1 = tostring(math.Round(dmg_max)) .. " DAMAGE"

            if self:GetValue("Num") > 1 then
                txt_dmg1 = math.Round(dmg_max * self:GetValue("Num")) .. "-" .. txt_dmg1
            end

            surface.SetFont("ARC9_8")
            surface.SetTextColor(ARC9.GetHUDColor("fg"))
            local txt_dmg1_w = surface.GetTextSize(txt_dmg1)
            surface.SetTextPos((w / 3) - txt_dmg1_w - (ScreenScale(2)), ScreenScale(1))
            surface.DrawText(txt_dmg1)

            local txt_range1 = self:RangeUnitize(range_min)

            surface.SetFont("ARC9_8")
            surface.SetTextColor(ARC9.GetHUDColor("fg"))
            local txt_range1_w = surface.GetTextSize(txt_range1)
            surface.SetTextPos((w / 3) - txt_range1_w - (ScreenScale(2)), ScreenScale(1 + 8))
            surface.DrawText(txt_range1)

            local txt_dmg2 = tostring(math.Round(dmg_min)) .. " DAMAGE"

            if self:GetValue("Num") > 1 then
                txt_dmg2 = math.Round(dmg_min * self:GetValue("Num")) .. "-" .. txt_dmg2
            end

            surface.SetFont("ARC9_8")
            surface.SetTextColor(ARC9.GetHUDColor("fg"))
            surface.SetTextPos(2 * (w / 3) + (ScreenScale(2)), ScreenScale(1))
            surface.DrawText(txt_dmg2)

            local txt_range2 = self:RangeUnitize(range_max)

            surface.SetFont("ARC9_8")
            surface.SetTextColor(ARC9.GetHUDColor("fg"))
            surface.SetTextPos(2 * (w / 3) + (ScreenScale(2)), ScreenScale(1 + 8))
            surface.DrawText(txt_range2)
        end

        local txt_corner = "TERMINAL BALLISTICS PERFORMANCE EVALUATION"
        surface.SetFont("ARC9_6")
        local tw = surface.GetTextSize(txt_corner)
        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.SetTextPos((w - tw) / 2, h - ScreenScale(8))
        surface.DrawText(txt_corner)
    end

    local range_3 = math.max(math.Round(self:GetValue("RangeMax") / 25) * 25, 50) --self.Range * self:GetBuff_Mult("Mult_Range")
    local range_1 = math.max(math.Round(range_3 / 3 / 25) * 25, 15) --(self.RangeMin or 0) * self:GetBuff_Mult("Mult_RangeMin")

    if range_1 == 0 then
        range_1 = range_3 * 0.5
    end

    rollallhits(self, range_3, range_1)

    local ballisticchart = vgui.Create("DButton", tp)
    ballisticchart:SetSize(ScreenScale(200), ScreenScale(110))
    ballisticchart:SetPos(ScreenScale(100), ScreenScale(110))
    ballisticchart:SetText("")
    ballisticchart.DoClick = function(self2)
        rollallhits(self, range_3, range_1)
    end
    ballisticchart.Paint = function(self2, w, h)
        if !IsValid(self) then return end

        local col = ARC9.GetHUDColor("bg", 50)
        if self2:IsHovered() then
            self.CustomizeHints["Select"] = "Recalculate"
            col = ARC9.GetHUDColor("hi", 50)
        end

        if self:GetValue("PrimaryBash") then
            surface.SetDrawColor(col)
            surface.DrawRect(0, 0, w, h)

            local txt = "No Data"

            surface.SetTextColor(ARC9.GetHUDColor("fg"))
            surface.SetFont("ARC9_24")
            local tw, th = surface.GetTextSize(txt)
            surface.SetTextPos((w - tw) / 2, (h - th) / 2)
            surface.DrawText(txt)
            return
        end

        surface.SetDrawColor(col)
        surface.DrawRect(0, 0, w, h)

        local s = w / 2
        local s2 = ScreenScale(10)

        local range_1_txt = self:RangeUnitize(range_1)
        local range_3_txt = self:RangeUnitize(range_3)

        surface.SetMaterial(bullseye)
        surface.SetDrawColor(ARC9.GetHUDColor("fg", 50))
        surface.DrawTexturedRect(0, 0, s, s)

        local r_1_x, r_1_y = self2:LocalToScreen(0, 0)

        render.SetScissorRect(r_1_x, r_1_y, r_1_x + s, r_1_y + s, true)

        for _, hit in ipairs(hits_1) do
            if self:GetValue("Num") > 1 then
                surface.SetMaterial(mat_hit_dot)
            else
                surface.SetMaterial(mat_hit)
            end
            surface.SetDrawColor(ARC9.GetHUDColor("fg"))
            surface.DrawTexturedRect((s / 2) + (hit.x * s) - (s2 / 2), (s / 2) + (hit.y * s) - (s2 / 2), s2, s2)
        end

        render.SetScissorRect(r_1_x, r_1_y, r_1_x + s, r_1_y + s, false)

        surface.SetFont("ARC9_10")
        -- local range_1_txtw = surface.GetTextSize(range_1_txt)

        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.SetTextPos(ScreenScale(2), h - ScreenScale(16))
        surface.DrawText(range_1_txt)

        surface.SetMaterial(bullseye)
        surface.SetDrawColor(ARC9.GetHUDColor("fg", 50))
        surface.DrawTexturedRect(s, 0, s, s)

        render.SetScissorRect(r_1_x + s, r_1_y, r_1_x + (s * 2), r_1_y + s, true)

        for _, hit in ipairs(hits_3) do
            if self:GetValue("Num") > 1 then
                surface.SetMaterial(mat_hit_dot)
            else
                surface.SetMaterial(mat_hit)
            end
            surface.SetDrawColor(ARC9.GetHUDColor("fg"))
            surface.DrawTexturedRect(s + (s / 2) + (hit.x * s) - (s2 / 2), (s / 2) + (hit.y * s) - (s2 / 2), s2, s2)
        end

        render.SetScissorRect(r_1_x, r_1_y, r_1_x + s, r_1_y + s, false)

        surface.SetFont("ARC9_10")
        local range_3_txtw = surface.GetTextSize(range_3_txt)

        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.SetTextPos(w - range_3_txtw - ScreenScale(2), h - ScreenScale(16))
        surface.DrawText(range_3_txt)

        local txt_corner = "MECHANICAL PRECISION TEST"
        surface.SetFont("ARC9_6")
        local tw = surface.GetTextSize(txt_corner)
        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.SetTextPos((w - tw) / 2, h - ScreenScale(8))
        surface.DrawText(txt_corner)
    end
end