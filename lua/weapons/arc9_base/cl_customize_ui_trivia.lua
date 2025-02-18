local function PaintScrollBar(panel, w, h)
    surface.SetDrawColor(ARC9.GetHUDColor("shadow"))
    surface.DrawRect(ScreenScale(3), 0 + ScreenScale(1), w - ScreenScale(3), h)

    surface.SetDrawColor(ARC9.GetHUDColor("fg"))
    surface.DrawRect(ScreenScale(2), 0, w - ScreenScale(3), h - ScreenScale(1))
end

local ARC9ScreenScale = ARC9.ScreenScale

function SWEP:CreateHUD_Trivia()
    local lowerpanel = self.CustomizeHUD.lowerpanel

    self:ClearTabPanel()

    local descbg = vgui.Create("DPanel", lowerpanel)
    descbg:SetPos(ARC9ScreenScale(4), ARC9ScreenScale(20))
    descbg:SetSize(lowerpanel:GetWide(), ARC9ScreenScale(98))
    descbg.Paint = function(self2, w, h)
    end

    self.BottomBar = descbg

    local desc = vgui.Create("DScrollPanel", descbg)
    desc:SetPos(0, 0)
    desc:SetSize(descbg:GetWide() * 0.666, descbg:GetTall())
    desc.Paint = function(self2, w, h)
        // surface.SetDrawColor(255, 255, 255)
        // surface.DrawRect(0, 0, w, h)
    end

    local newbtn = desc:Add("DPanel")
    newbtn:SetSize(desc:GetWide(), ScreenScale(9))
    newbtn:Dock(TOP)
    newbtn.title = "Description"
    newbtn.Paint = function(self2, w, h)
        if !IsValid(self) then return end

        surface.SetFont("ARC9_6")
        surface.SetTextPos(ScreenScale(2), ScreenScale(0))
        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.DrawText(self2.title)
    end

    local multiline = {}

    multiline = self:MultiLineText(self.Description, desc:GetWide(), "ARC9_8")

    for i, text in ipairs(multiline) do
        local desc_line = vgui.Create("DPanel", desc)
        desc_line:SetSize(desc:GetWide(), ARC9ScreenScale(9))
        desc_line:Dock(TOP)
        desc_line.Paint = function(self2, w, h)
            if !IsValid(self) then return end
            surface.SetFont("ARC9_8")
            surface.SetTextColor(ARC9.GetHUDColor("fg"))
            surface.SetTextPos(ARC9ScreenScale(2), 0)
            surface.DrawText(text)
        end
    end

    local desc2 = vgui.Create("DScrollPanel", descbg)
    desc2:SetPos(descbg:GetWide() * 0.667, 0)
    desc2:SetSize(descbg:GetWide() * 0.333, descbg:GetTall())
    desc2.Paint = function(self2, w, h)
        // surface.SetDrawColor(255, 255, 255)
        // surface.DrawRect(0, 0, w, h)
    end

    for title, trivia in pairs(self:GetValue("Trivia")) do
        if title == "BaseClass" then continue end
        local newbtn2 = desc2:Add("DPanel")
        newbtn2:SetSize(desc2:GetWide(), ARC9ScreenScale(16))
        newbtn2:Dock(TOP)
        newbtn2.title = title
        newbtn2.trivia = trivia
        newbtn2.Paint = function(self2, w, h)
            if !IsValid(self) then return end
            -- title

            surface.SetFont("ARC9_6")
            surface.SetTextPos(ScreenScale(0), 0)
            surface.SetTextColor(ARC9.GetHUDColor("fg"))
            surface.DrawText(self2.title)

            local major = self2.trivia

            surface.SetFont("ARC9_8")
            surface.SetTextPos(ScreenScale(2), ScreenScale(6))
            surface.SetTextColor(ARC9.GetHUDColor("fg"))
            self:DrawTextRot(self2, major, 0, 0, math.max(ScreenScale(1), 0), ScreenScale(6), w, true)
        end
    end

    // local tp = vgui.Create("DScrollPanel", lowerpanel)
    // tp:SetSize(ScreenScale(400), ScrH() - ScreenScale(76 + 4))
    // tp:SetPos(ScrW() - ScreenScale(400 + 12), ScreenScale(76))
    // tp.Paint = function(self2, w, h)
    // end

    // local scroll_preset = tp:GetVBar()
    // scroll_preset.Paint = function() end
    // scroll_preset.btnUp.Paint = function(span, w, h)
    // end
    // scroll_preset.btnDown.Paint = function(span, w, h)
    // end
    // scroll_preset.btnGrip.Paint = PaintScrollBar

    // self.TabPanel = tp

    // local newbtn = tp:Add("DPanel")
    // newbtn:SetSize(ScreenScale(400), ScreenScale(9))
    // newbtn:Dock(TOP)
    // newbtn.title = "Description"
    // newbtn.Paint = function(self2, w, h)
    //     if !IsValid(self) then return end
    //     -- title
    //     surface.SetFont("ARC9_6")
    //     local tw = surface.GetTextSize(self2.title)

    //     surface.SetFont("ARC9_6")
    //     surface.SetTextPos(w - tw - ScreenScale(1), ScreenScale(2 + 1))
    //     surface.SetTextColor(ARC9.GetHUDColor("shadow"))
    //     surface.DrawText(self2.title)

    //     surface.SetFont("ARC9_6")
    //     surface.SetTextPos(w - tw - ScreenScale(2), ScreenScale(2))
    //     surface.SetTextColor(ARC9.GetHUDColor("fg"))
    //     surface.DrawText(self2.title)
    // end

    // local multiline = {}
    // local desc = self.Description

    // multiline = self:MultiLineText(desc, tp:GetWide() - (ScreenScale(4)), "ARC9_8")

    // for i, text in ipairs(multiline) do
    //     local desc_line = vgui.Create("DPanel", tp)
    //     desc_line:SetSize(tp:GetWide(), ScreenScale(9))
    //     desc_line:Dock(TOP)
    //     desc_line.Paint = function(self2, w, h)
    //         if !IsValid(self) then return end
    //         surface.SetFont("ARC9_8")
    //         local tw = surface.GetTextSize(text)

    //         surface.SetFont("ARC9_8")
    //         surface.SetTextColor(ARC9.GetHUDColor("shadow"))
    //         surface.SetTextPos(w - tw - ScreenScale(1), ScreenScale(1))
    //         surface.DrawText(text)

    //         surface.SetFont("ARC9_8")
    //         surface.SetTextColor(ARC9.GetHUDColor("fg"))
    //         surface.SetTextPos(w - tw - ScreenScale(2), 0)
    //         surface.DrawText(text)
    //     end
    // end
end