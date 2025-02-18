
local ARC9ScreenScale = ARC9.ScreenScale
local clicksound = "ui/panorama/itemtile_click_02.wav"
local mat_default = Material("arc9/arc9_sus.png", "mips smooth")
local nextpreset = 0

function SWEP:CreatePresetMenu(reload)
    if reload and self.CustomizeHUD and self.CustomizeHUD.presetpanel then self.CustomizeHUD.presetpanel:Remove() end
    if !reload and self.CustomizeHUD and self.CustomizeHUD.presetpanel then self:ClosePresetMenu() return end

    self.CustomizeButtons[self.CustomizeTab + 1].func(self)

    local scrw, scrh = ScrW(), ScrH()
    local bg = self.CustomizeHUD

    local presetpanel = vgui.Create("DFrame", bg)
    self.CustomizeHUD.presetpanel = presetpanel
    presetpanel:SetPos(scrw - ARC9ScreenScale(130+19), ARC9ScreenScale(45))
    presetpanel:SetSize(ARC9ScreenScale(130), scrh-ARC9ScreenScale(145))
    presetpanel:SetTitle("")
    -- presetpanel:SetDraggable(false)
    presetpanel:ShowCloseButton(false)
    presetpanel:SetAlpha(0)
    presetpanel:AlphaTo(255, 0.1, 0, nil)

    local cornercut = ARC9ScreenScale(3.5)
    presetpanel.Paint = function(self2, w, h) 
        draw.NoTexture()
        surface.SetDrawColor(ARC9.GetHUDColor("bg"))
        surface.DrawPoly({{x = cornercut, y = h},{x = 0, y = h-cornercut}, {x = 0, y = cornercut},{x = cornercut, y = 0}, {x = w-cornercut, y = 0},{x = w, y = cornercut}, {x = w, y = h-cornercut}, {x = w-cornercut, y = h}})
        -- thingy at bottom
        surface.SetDrawColor(ARC9.GetHUDColor("hi"))
        surface.DrawPoly({{x = cornercut, y = h}, {x = 0, y = h-cornercut}, {x = cornercut, y = h-cornercut*.5}})
        surface.DrawPoly({{x = w, y = h-cornercut}, {x = w-cornercut, y = h}, {x = w-cornercut, y = h-cornercut*.5}})
        surface.DrawPoly({{x = cornercut, y = h-cornercut*.5}, {x = w-cornercut, y = h-cornercut*.5}, {x = w-cornercut, y = h}, {x = cornercut, y = h}, })
        -- same thingy at top
        surface.DrawPoly({{x = 0, y = cornercut}, {x = cornercut, y = 0}, {x = cornercut, y = cornercut*.5}})
        surface.DrawPoly({{x = w-cornercut, y = 0}, {x = w, y = cornercut}, {x = w-cornercut, y = cornercut*.5}})
        surface.DrawPoly({{x = cornercut, y = 0}, {x = w-cornercut, y = 0}, {x = w-cornercut, y = cornercut*.5}, {x = cornercut, y = cornercut*.5}, })
    end

    local presetscroller = vgui.Create("ARC9ScrollPanel", presetpanel)
    presetscroller:SetSize(presetpanel:GetWide() - ARC9ScreenScale(4), presetpanel:GetTall()-ARC9ScreenScale(26))
    presetscroller:SetPos(ARC9ScreenScale(2), ARC9ScreenScale(4))
    -- presetscroller.Paint = function(self2, w, h) 
    --     surface.SetDrawColor(ARC9.GetHUDColor("bg"))
    --     surface.DrawRect(0, 0, w, h)
    -- end
    
    local savebtn = vgui.Create("ARC9TopButton", presetpanel)
    surface.SetFont("ARC9_12")
    local tw = surface.GetTextSize("Save")
    local tw2 = surface.GetTextSize("Import")
    local ih8l18n = (presetpanel:GetWide() - tw - tw2) > ARC9ScreenScale(70) and ARC9ScreenScale(10) or 0

    savebtn:SetPos(ARC9ScreenScale(5)+ih8l18n, presetpanel:GetTall() - ARC9ScreenScale(20))
    savebtn:SetSize(ARC9ScreenScale(22)+tw, ARC9ScreenScale(21*0.75))
    savebtn:SetButtonText("Save", "ARC9_12")
    savebtn:SetIcon(Material("arc9/ui/save.png", "mips smooth"))
    savebtn.DoClick = function(self2)
        surface.PlaySound(clicksound)
        if nextpreset > CurTime() then return end
        nextpreset = CurTime() + 1

        self:CreatePresetName()
    end
    savebtn.Think = function(self2)
        if !IsValid(self) then return end
        if self2:IsHovered() then
            self.CustomizeHints["Select"] = "Save"
            self.CustomizeHints["Deselect"] = "Quicksave"
        end
    end
    savebtn.DoRightClick = function(self2)
        if nextpreset > CurTime() then return end
        nextpreset = CurTime() + 1

        -- local txt = os.date( "%I.%M%p", os.time() )
        -- if txt:Left(1) == "0" then txt = txt:Right( #txt-1 ) end
        local txt = "Preset "
        local num = 0

        for _, preset in ipairs(self:GetPresets()) do
            local psname = self:GetPresetName(preset)
            if string.StartWith(psname, txt) then
                local qsnum = tonumber(string.sub(psname, string.len(txt) + 1))

                // print(string.sub(preset, string.len(txt) + 1))

                if qsnum and qsnum > num then
                    num = qsnum
                end
            end
        end

        txt = txt .. tostring(num + 1)

        self:SavePreset( txt )
        surface.PlaySound("arc9/shutter.ogg")

        timer.Simple(0.5, function()
            if IsValid(self) and IsValid(self:GetOwner()) then
                self:GetOwner():ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 127), 0.5, 0)
                if self:GetCustomize() then
                    self:CreateHUD_Bottom()
                    self:CreatePresetMenu(true)
                end
            end
        end)
    end

    local importbtn = vgui.Create("ARC9TopButton", presetpanel)
    importbtn:SetPos(presetpanel:GetWide()-(ARC9ScreenScale(22)+tw2) - ARC9ScreenScale(5) - ih8l18n , presetpanel:GetTall() - ARC9ScreenScale(20))
    importbtn:SetSize(ARC9ScreenScale(22)+tw2, ARC9ScreenScale(21*0.75))
    importbtn:SetButtonText("Import", "ARC9_12")
    importbtn:SetIcon(Material("arc9/ui/import.png", "mips smooth"))
    importbtn.DoClick = function(self2)
        self:CreateImportPreset()
        surface.PlaySound(clicksound)
    end
    importbtn.Think = function(self2)
        if !IsValid(self) then return end
        if self2:IsHovered() then
            self.CustomizeHints["Select"] = "Import"
        end
    end

    local function createpresetbtn(preset, undeletable)
        local filename = ARC9.PresetPath .. self:GetPresetBase() .. "/" .. preset .. "." .. ARC9.PresetIconFormat

        local presetbtn = vgui.Create("DButton", presetscroller)
        presetbtn:SetTall(ARC9ScreenScale(36))
        presetbtn:Dock(TOP)
        presetbtn:DockMargin(0, 0, 5, 5)
        presetbtn:SetText("")
        presetbtn.DoClick = function(self2)
            self:LoadPreset(preset)
            surface.PlaySound(clicksound)
        end

        presetbtn.preset = preset
        presetbtn.name, presetbtn.attcount = self:GetPresetData(preset)

        if presetbtn.name == "default" then presetbtn.name = "Default" end

        if file.Exists(filename, "DATA") then
            presetbtn.icon = Material("data/" .. filename, "smooth")
        end

        presetbtn.Paint = function(self2, w, h) 
            surface.SetDrawColor(ARC9.GetHUDColor("bg"))
            surface.DrawRect(0, 0, w, h)
            if self2:IsHovered() then
                if self2:IsDown() then 
                    surface.SetDrawColor(ARC9.GetHUDColor("hi", 100))
                end
                self.CustomizeHints["Select"] = "Install"
                surface.DrawRect(0, 0, w, h)
            end
            surface.SetDrawColor(20, 20, 20, 120)
            surface.DrawRect(ARC9ScreenScale(1), ARC9ScreenScale(1), h*1.4, h - ARC9ScreenScale(2))

            surface.SetDrawColor(ARC9.GetHUDColor("fg"))
            surface.SetMaterial(presetbtn.icon or mat_default)
            surface.DrawTexturedRect(0, -h*0.2, h*1.4, h*1.4)
            -- surface.DrawTexturedRectUV(0, 0, h*1.4, h, 0, 0.2, 1, 0.8)

            surface.SetFont("ARC9_12")
            surface.SetTextColor(ARC9.GetHUDColor("fg"))
            surface.SetTextPos(h*1.4 + ARC9ScreenScale(5), 0)
            surface.DrawText(self2.name)
            surface.SetFont("ARC9_8")
            surface.SetTextPos(h*1.4 + ARC9ScreenScale(5), ARC9ScreenScale(11))
            surface.DrawText(tostring(self2.attcount) .. " Attachments")
        end

        -- local preset_apply = vgui.Create("ARC9TopButton", presetbtn)
        -- surface.SetFont("ARC9_10")
        -- local tw3 = surface.GetTextSize("Install")
        -- preset_apply:SetPos(presetpanel:GetWide() - ARC9ScreenScale(22) - tw3 - ARC9ScreenScale(4), presetbtn:GetTall() - ARC9ScreenScale(15))
        -- preset_apply:SetSize(ARC9ScreenScale(17) + tw3, ARC9ScreenScale(21*0.625))
        -- preset_apply:SetButtonText("Install", "ARC9_10")
        -- preset_apply:SetIcon(Material("arc9/ui/apply.png", "mips smooth"))
        -- preset_apply.DoClick = function(self2)
        --     self:LoadPreset(preset)
        --     surface.PlaySound(clicksound)
        -- end
        -- preset_apply.Think = function(self2)
        --     if !IsValid(self) then return end
        --     if self2:IsHovered() then
        --         self.CustomizeHints["Select"] = "Install"
        --     end
        -- end

        if !undeletable then
            local preset_share = vgui.Create("ARC9TopButton", presetbtn)
            preset_share:SetPos(ARC9ScreenScale(69), presetbtn:GetTall() - ARC9ScreenScale(15))
            preset_share:SetSize(ARC9ScreenScale(21*0.625), ARC9ScreenScale(21*0.625))
            preset_share:SetIcon(Material("arc9/ui/share.png", "mips smooth"))
            preset_share.DoClick = function(self2)
                surface.PlaySound(clicksound)

                local f = file.Open(ARC9.PresetPath .. self:GetPresetBase() .. "/" .. preset .. ".txt", "r", "DATA")
                if !f then return end
                local str = f:Read()

                local strs = string.Split(str, "\n")

                self:CreateExportPreset("["..string.Split(strs[1], "=")[2].."]"..strs[2])
                -- self:CreateExportPreset(self:GeneratePresetExportCode())
            end
            preset_share.Think = function(self2)
                if !IsValid(self) then return end
                if self2:IsHovered() then
                    self.CustomizeHints["Select"] = "Export"
                end
            end

            local preset_delete = vgui.Create("ARC9TopButton", presetbtn)
            preset_delete:SetPos(ARC9ScreenScale(54), presetbtn:GetTall() - ARC9ScreenScale(15))
            preset_delete:SetSize(ARC9ScreenScale(21*0.625), ARC9ScreenScale(21*0.625))
            preset_delete:SetIcon(Material("arc9/ui/delete.png", "mips smooth"))
            preset_delete.DoClick = function(self2)
                self:DeletePreset(preset)
                presetbtn:Remove()
                presetbtn = nil
                -- self:CreatePresetMenu()
                surface.PlaySound(clicksound)
            end
            preset_delete.Think = function(self2)
                if !IsValid(self) then return end
                if self2:IsHovered() then
                    self.CustomizeHints["Select"] = "Delete"
                end
            end
        end
    end

    createpresetbtn("default", true) -- i want not only one default preset
    local presetlist = self:GetPresets()

    for _, preset in ipairs(presetlist) do
        if preset == "autosave" or preset == "default" then continue end
        createpresetbtn(preset, false)
    end
end

function SWEP:ClosePresetMenu()
    if self.CustomizeHUD and self.CustomizeHUD.presetpanel then 
        self.CustomizeHUD.topright_panel.topright_presets:SetChecked(false)
        self.CustomizeHUD.presetpanel:AlphaTo(0, 0.1, 0, function()
            if self.CustomizeHUD.presetpanel then
                self.CustomizeHUD.presetpanel:Remove()
            end
            self.CustomizeHUD.presetpanel = nil
        end)
    end
end

local function createPopup(self, title, buttontext, typeable, inside, btnfunc)
    local scrw, scrh = ScrW(), ScrH()

    local bg = vgui.Create("DFrame")
    bg:SetPos(0, 0)
    bg:SetSize(scrw, scrh)
    bg:SetTitle("")
    bg:SetDraggable(false)
    bg:ShowCloseButton(false)
    bg.Paint = function(self2, w, h)
        if !IsValid(self) then return end
        surface.SetDrawColor(31, 31, 31, 235)
        surface.DrawRect(0, 0, scrw, scrh)
        
        surface.SetFont("ARC9_20")
        local tw = surface.GetTextSize(title)
        surface.SetTextColor(ARC9.GetHUDColor("shadow"))
        surface.SetTextPos(w/2-tw/2+ARC9ScreenScale(1), h/2 - ARC9ScreenScale(71))
        surface.DrawText(title)
        surface.SetTextColor(ARC9.GetHUDColor("fg"))
        surface.SetTextPos(w/2-tw/2, h/2 - ARC9ScreenScale(72))
        surface.DrawText(title)
    end
    bg:MakePopup()

    local textentry = vgui.Create("DTextEntry", bg)
    textentry:SetSize(scrw/3, ARC9ScreenScale(24))
    textentry:Center()
    textentry:SetY(scrh/2 - ARC9ScreenScale(48))
    textentry:RequestFocus()
    textentry:SetFont("ARC9_24")
    textentry:SetText("")

    textentry.OnEnter = function(spaa, kc)
        btnfunc(bg, textentry)
    end

    local savebtn = vgui.Create("ARC9TopButton", bg)
    surface.SetFont("ARC9_16")
    local tw = surface.GetTextSize(buttontext)
    local tw2 = surface.GetTextSize("Cancel")
    savebtn:SetPos(scrw/3 + scrw/12 - (ARC9ScreenScale(29)+tw)/2, scrh/2 - ARC9ScreenScale(12))
    savebtn:SetSize(ARC9ScreenScale(29)+tw, ARC9ScreenScale(22))
    savebtn:SetButtonText(buttontext, "ARC9_16")
    savebtn:SetIcon(Material("arc9/ui/apply.png", "mips smooth"))
    savebtn.DoClick = function(self2)
        surface.PlaySound(clicksound)
        btnfunc(bg, textentry)
    end

    if typeable then
        local cancelbtn = vgui.Create("ARC9TopButton", bg)
        cancelbtn:SetPos(scrw/3 + scrw/4.5 - (ARC9ScreenScale(29)+tw2)/2, scrh/2 - ARC9ScreenScale(12))
        cancelbtn:SetSize(ARC9ScreenScale(29)+tw2, ARC9ScreenScale(22))
        cancelbtn:SetButtonText("Cancel", "ARC9_16")
        cancelbtn:SetIcon(Material("arc9/ui/close.png", "mips smooth"))
        cancelbtn.DoClick = function(self2)
            surface.PlaySound(clicksound)
            bg:Remove()
        end
    else
        savebtn:SetPos(scrw/3 + scrw/6 - (ARC9ScreenScale(29)+tw)/2, scrh/2 - ARC9ScreenScale(12))
        textentry:SetText(inside)
        textentry:SetEnabled(false)
        textentry:SelectAll()
        textentry:CopySelected()
        textentry:SelectNone()
    end
end

function SWEP:CreatePresetName()
    createPopup(self, "New Preset Name", "Save", true, nil, function(bg, textentry)
        local txt = textentry:GetText()
        txt = string.sub(txt, 0, 36)
        
        if txt == "" then txt = "Unnamed" end

        if txt != "autosave" and txt != "default" then
            self:SavePreset(txt)
            surface.PlaySound("arc9/shutter.ogg")

            timer.Simple(0.5, function()
                if IsValid(self) and IsValid(self:GetOwner()) then
                    self:GetOwner():ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 127), 0.5, 0)
                    if self:GetCustomize() then
                        self:CreateHUD_Bottom()
                        self:CreatePresetMenu(true)
                    end
                end
            end)

            bg:Remove()
        else
            textentry:SetText("")
            textentry:SetPlaceholderText("You are bad")
        end
    end)
end

function SWEP:CreateExportPreset(string)
    createPopup(self, "Preset Code (Copied to Clipboard)", "Back", false, string, function(bg, textentry)
        bg:Remove()
    end)
end

function SWEP:CreateImportPreset()
    createPopup(self, "Paste Preset Code Here", "Import", true, nil, function(bg, textentry)
        local txt = textentry:GetText()
        
        if self:LoadPresetFromCode(textentry:GetText()) then 
            bg:Remove()
            self:CreatePresetMenu(true)
        else
            textentry:SetText("")
            textentry:SetPlaceholderText("Invalid string!")
        end

        if txt == "" then textentry:SetPlaceholderText("Are you dumb") end
    end)
end