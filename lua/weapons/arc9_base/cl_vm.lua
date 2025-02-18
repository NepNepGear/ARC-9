local vignette = Material("arc9/bgvignette.png", "mips smooth")
-- local vignette2 = Material("arc9/bgvignette2.png", "mips smooth")

function SWEP:PreDrawViewModel()
    if ARC9.PresetCam then
        self:DoBodygroups(false)
        return
    end

    local custdelta = self.CustomizeDelta

    if custdelta > 0 then
        if GetConVar("arc9_cust_blur"):GetBool() then DrawBokehDOF( 10 * custdelta, 1, 0.1 ) end

        cam.Start2D()
            surface.SetDrawColor(0, 0, 0, 180 * custdelta)
            surface.DrawRect(0, 0, ScrW(), ScrH())
            surface.SetDrawColor(0, 0, 0, 255 * custdelta)
            surface.SetMaterial(vignette)
            surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        cam.End2D()
    end

    if GetConVar("arc9_cust_light"):GetBool() and self:GetCustomize() then
        -- render.SuppressEngineLighting( true )
        -- render.ResetModelLighting(0.6, 0.6, 0.6)
        -- render.SetModelLighting(BOX_TOP, 4, 4, 4)
        local light = DynamicLight(self:EntIndex(), true)
        light.pos = EyePos() + (EyeAngles():Up() * 12)
        light.r = 255
        light.g = 255
        light.b = 255
        light.brightness = 0.2 * (GetConVar("arc9_cust_light_brightness"):GetFloat())
        light.Decay = 1000
        light.Size = 500
        light.DieTime = CurTime() + 0.1
    -- else
    --     render.SuppressEngineLighting( false )
    --     render.ResetModelLighting(1,1,1)
    end

    self:DoPoseParams()
    self:DoBodygroups(false)

    local bipodamount = self:GetBipodAmount()

    self:GetVM():SetPoseParameter("sights", math.max(self:GetSightAmount(), bipodamount))
    if self:GetValue("BoneMods") then for i, k in pairs(self:GetValue("BoneMods")) do
        local boneindex = self:GetVM():LookupBone(i)

        if !boneindex then continue end

        self:GetVM():ManipulateBonePosition(boneindex, k.pos or Vector(0, 0, 0))
        self:GetVM():ManipulateBoneAngles(boneindex, k.ang or Angle(0, 0, 0))
        self:GetVM():ManipulateBoneScale(boneindex, k.scale or Vector(0, 0, 0))
    end end
    self:GetVM():InvalidateBoneCache()

    self.ViewModelFOV = self:GetViewModelFOV()

    if !GetConVar("arc9_dev_benchgun"):GetBool() then
        cam.Start3D(nil, nil, self:WidescreenFix(self:GetViewModelFOV()), nil, nil, nil, nil, 0.5, 10000)
    end

    -- self:DrawCustomModel(true, EyePos() + EyeAngles():Forward() * 16, EyeAngles())

    self:GetVM():SetSubMaterial()

    if self:GetHolsterTime() < CurTime() and self.RTScope and self:GetSightAmount() > 0 then
        self:DoRTScope(self:GetVM(), self:GetTable(), self:GetSightAmount() > 0)
    end

    self:GetVM():SetMaterial(self:GetProcessedValue("Material"))

    cam.IgnoreZ(true)

    if self:GetSightAmount() > 0.75 and self:GetSight().FlatScope and !self:GetSight().FlatScopeKeepVM then
        render.SetBlend(0)
    end
end

function SWEP:ViewModelDrawn()
    -- self:DrawLasers(false)
    self:DrawCustomModel(false)
    self:DoRHIK()
    self:PreDrawThirdArm()

    -- cam.Start3D(nil, nil, self:WidescreenFix(self:GetViewModelFOV()), 0, 0, ScrW(), ScrH(), 4, 30000)
    --     cam.IgnoreZ(true)
        self:DrawLasers(false)
    -- cam.End3D()

    -- cam.IgnoreZ(true)
    -- local custdelta = self.CustomizeDelta
    -- cam.Start2D()
    --     surface.SetDrawColor(0, 0, 0, 230 * custdelta)
    --     surface.SetMaterial(vignette2)
    --     surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
    -- cam.End2D()
end

function SWEP:PostDrawViewModel()
    if ARC9.PresetCam then return end

    cam.IgnoreZ(false)
    render.SetBlend(1)

    if !GetConVar("arc9_dev_benchgun"):GetBool() then
        cam.End3D()
    end

    cam.Start3D(nil, nil, self:WidescreenFix(self:GetViewModelFOV()), nil, nil, nil, nil, 1, 10000 )
    for _, model in ipairs(self.VModel) do
        local slottbl = model.slottbl
        local atttbl = self:GetFinalAttTable(slottbl)

        if atttbl.HoloSight then
            -- cam.IgnoreZ(true)
            self:DoHolosight(model, atttbl)
            -- cam.IgnoreZ(false)
        end
    end
    cam.End3D()

    

    -- render.UpdateFullScreenDepthTexture()
end