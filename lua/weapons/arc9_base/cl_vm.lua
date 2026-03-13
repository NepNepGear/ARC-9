local vignette = Material("arc9/bgvignette.png", "mips smooth")
-- local vignette2 = Material("arc9/bgvignette2.png", "mips smooth")


local adsblur = Material("pp/arc9/adsblur")
local function arc9toytown(amount) -- cool ass blur
    local camera = cam
	if amount > 0 then
        local scrw, scrh = ScrW(), ScrH()
        camera.Start2D()
            surface.SetMaterial(adsblur)
            surface.SetDrawColor(255, 255, 255, 255)

            for i = 1, 5 * amount do -- 5 looking pretty cool
                render.CopyRenderTargetToTexture(render.GetScreenEffectTexture())
                surface.DrawTexturedRect(scrw*.5-scrh*.5, scrh*.58, scrh, scrh*0.42)
            end
        camera.End2D()
    end
end

local bluramt = 0
-- please cache fucking convars
local arc9_fx_rtblur = GetConVar("arc9_fx_rtblur")
local arc9_fx_animblur = GetConVar("arc9_fx_animblur")
local arc9_fx_reloadblur = GetConVar("arc9_fx_reloadblur")
local arc9_fx_inspectblur = GetConVar("arc9_fx_inspectblur")
local arc9_cust_blur = GetConVar("arc9_cust_blur")
local arc9_hud_lightmode = GetConVar("arc9_hud_lightmode")
local arc9_dev_greenscreen = GetConVar("arc9_dev_greenscreen")
local arc9_cust_light = GetConVar("arc9_cust_light")
local arc9_cust_light_brightness = GetConVar("arc9_cust_light_brightness")
local arc9_dev_benchgun = GetConVar("arc9_dev_benchgun")
local arc9_fx_adsblur = GetConVar("arc9_fx_adsblur")


function SWEP:PreDrawViewModel(vm, weapon, ply, flags)
    local camera = cam
	local Rendering = render
	if ARC9.RTScopeRender then -- basically a copy of code in that func for rt barrels but without useless stuff and bad stuff, and also offset of cam in scope
        self:DoBodygroups(false)
        local vm = self:GetVM()
        if self.HasSightsPoseparam then
            vm:SetPoseParameter("sights", self:GetSightAmount())
        end
        self:SetFiremodePose()
        vm:InvalidateBoneCache()

        local vmpso, vmagn, spso = self.LastViewModelPos, self.LastViewModelAng, self:GetSightPositions()
        
        vmpso = vmpso - vmagn:Forward() * (spso.y - 15) -- i sure do hope fixed number will be good (clueless)
        vmpso = vmpso - vmagn:Up() * spso.z
        vmpso = vmpso - vmagn:Right() * spso.x

        camera.Start3D(vmpso, nil, ARC9.RTScopeRenderFOV * 0.85, nil, nil, nil, nil, 3, 100040)
        Rendering.DepthRange( 0.1, 0.1 )

        return
    end

    if ARC9.PresetCam then
        self:DoBodygroups(false)
        return
    end

    local getsights = self:GetSight()
    local sightamount = self:GetSightAmount()
	

	flags = flags or STUDIO_RENDER
    local isDepthPass = ( bit.band( flags, STUDIO_SSAODEPTHTEXTURE ) != 0 || bit.band( flags, STUDIO_SHADOWDEPTHTEXTURE ) != 0 )
    local custdelta = self.CustomizeDelta

	if !isDepthPass then
    	local blurtarget = 0

    	local blurenable = arc9_fx_rtblur:GetBool()

    	local shouldrtblur = sightamount > 0 and blurenable and !self.Peeking and getsights.atttbl and getsights.atttbl.RTScope and !getsights.Disassociate and !getsights.atttbl.RTCollimator and !getsights.atttbl.RTScopeNoBlur

    	if shouldrtblur then
    	    blurtarget = 2 * sightamount
    	end

    	if (arc9_fx_reloadblur:GetBool() and self:GetReloading() and sightamount < 0.99) or (arc9_fx_animblur:GetBool() and self:GetReadyTime() >= CurTime()) or (arc9_fx_inspectblur:GetBool() and self:GetInspecting() and sightamount < 0.01) then
    	    blurtarget = 1.5
    	    shouldrtblur = true
    	end

    	if custdelta > 0 then
    	    if arc9_cust_blur:GetBool() then
    	        blurtarget = 5 * custdelta
    	    end

    	    local scrw, scrh = ScrW(), ScrH()
			local SurfaceTemp = surface
    	    camera.Start2D()
            	SurfaceTemp.SetDrawColor(15, 15, 15, 180 * custdelta)
            	SurfaceTemp.DrawRect(0, 0, scrw, scrh)
            	SurfaceTemp.SetDrawColor(0, 0, 0, 255 * custdelta)
            	if arc9_hud_lightmode:GetBool() then
                	SurfaceTemp.SetMaterial(vignette)
                	SurfaceTemp.DrawTexturedRect(0, 0, scrw, scrh)
            	end

            	if arc9_dev_greenscreen:GetBool() then
                	-- print(GetConVar("mat_bloom_scalefactor_scalar"):SetFloat())
                	SurfaceTemp.SetDrawColor(0, 255, 0, 255 * custdelta)
                	SurfaceTemp.DrawRect(0, 0, scrw, scrh)
            	end
        	camera.End2D()
    	end

    	if ((shouldrtblur and blurenable) or (custdelta > 0 and blurtarget > 0)) and system.HasFocus() then
        	DrawBokehDOF(bluramt, 1, 0)
    	end

    	bluramt = math.Approach(bluramt, blurtarget, FrameTime() * 10)

    	if arc9_cust_light:GetBool() and self:GetCustomize() then
        	-- render.SuppressEngineLighting(true)
        	-- render.ResetModelLighting(0.6, 0.6, 0.6)
        	-- render.SetModelLighting(BOX_TOP, 4, 4, 4)
        	local light = DynamicLight(self:EntIndex(), true)
        	light.pos = EyePos() + (EyeAngles():Up() * 12)
        	light.r = 255
        	light.g = 255
        	light.b = 255
        	light.brightness = 0.2 * (arc9_cust_light_brightness:GetFloat())
        	light.Decay = 1000
        	light.Size = 500
        	light.DieTime = CurTime() + 0.1
    	-- else
    	--     render.SuppressEngineLighting(false)
    	--     render.ResetModelLighting(1,1,1)
    	end
	end

    self:DoPoseParams()
    self:DoBodygroups(false)

    local bipodamount = self:GetBipodAmount()
    local vm = self:GetVM()
    if !IsValid(vm) then return end

    if self.HasSightsPoseparam then
        vm:SetPoseParameter("sights", math.max(sightamount, bipodamount, custdelta))
    end

    local bonemods = self:GetValue("BoneMods")

    if bonemods then for _, k in pairs(bonemods) do
        local boneindex = vm:LookupBone(i)

        if !boneindex then continue end

        vm:ManipulateBonePosition(boneindex, k.pos or vector_origin)
        vm:ManipulateBoneAngles(boneindex, k.ang or angle_zero)
        vm:ManipulateBoneScale(boneindex, k.scale or vector_origin)
    end end
    

    local vmfov = self:GetViewModelFOV()

    self.ViewModelFOV = vmfov

    if !arc9_dev_benchgun:GetBool() then
        camera.Start3D(nil, nil, self:WidescreenFix(vmfov), nil, nil, nil, nil, 0.5, 10000)
    end

    -- self:DrawCustomModel(true, EyePos() + EyeAngles():Forward() * 16, EyeAngles())

	self.RenderingRTScope = false 
	if !isDepthPass then
    	vm:SetSubMaterial()

    	for ind = 0, 31 do
    	    local val = self:GetProcessedValue("SubMaterial" .. ind, true)
    	    if val then
    	        vm:SetSubMaterial(ind, val)
    	    end
    	end

    	if self:GetHolsterTime() < CurTime() and self.RTScope and sightamount > 0 then
    	    self:DoRTScope(vm, self:GetTable(), sightamount > 0)
    	end

    	vm:SetMaterial(self:GetProcessedValue("Material", true))
	end

    Rendering.DepthRange( 0.0, 0.1 )
    if ARC9.PresetCam or custdelta > 0 then camera.IgnoreZ(true) end

    self:SetFiremodePose()
    
    if self.HasSightsPoseparam then
        vm:SetPoseParameter("sights", math.max(sightamount, bipodamount, custdelta))
    end

    vm:InvalidateBoneCache()
    
    if sightamount > 0.75 and getsights.FlatScope and !getsights.FlatScopeKeepVM then
        Rendering.SetBlend(0)
    end
end

function SWEP:ViewModelDrawn(ent, flags)
	flags = flags or STUDIO_RENDER
    local isDepthPass = ( bit.band( flags, STUDIO_SSAODEPTHTEXTURE ) != 0 || bit.band( flags, STUDIO_SHADOWDEPTHTEXTURE ) != 0 )
	local Rendering = render
	
    self.StoredVMAngles = self:GetCameraControl()
    self:DrawCustomModel(false)
    Rendering.DepthRange( 0.0, 0.1 )
    self:DoRHIK()
    if ARC9.RTScopeRender then return end
    self:PreDrawThirdArm()

	if !isDepthPass then
    	self:DrawFlashlightsVM()

    	self:DrawLasers(false)
	end
		
    local vm = self:GetVM()
    if !IsValid(vm) then return end
    vm:SetMaterial("")
	for ind = 0, 31 do
		vm:SetSubMaterial(ind, "")
	end

    if !isDepthPass then
	    local newpcfs = {}
		local pcfs = self.PCFs
		for i = 1 , #pcfs do
			if IsValid(pcfs[i]) then
	            pcfs[i]:Render()
				newpcfs[#newpcfs+1] = pcfs[i]
	        end
		end
	
	
	    if !inrt then pcfs = newpcfs end
	end

    local newfx = {}
	local activeEffects = self.ActiveEffects
	for i = 1, #activeEffects do
		if IsValid(activeEffects[i]) then
            if !activeEffects[i].VMContext then continue end
            activeEffects[i]:DrawModel()
			newfx[#newfx + 1] = activeEffects[i]:DrawModel()
        end
	end

    if !inrt then activeEffects = newfx end
end

function SWEP:PostDrawViewModel(vm, weapon, ply, flags)
    if !IsValid(self:GetVM()) then return end
	flags = flags or STUDIO_RENDER
    local isDepthPass = ( bit.band( flags, STUDIO_SSAODEPTHTEXTURE ) != 0 || bit.band( flags, STUDIO_SHADOWDEPTHTEXTURE ) != 0 )
	local camera = cam
	local Rendering = render
    local inrt = ARC9.RTScopeRender

    self:DrawTranslucentPass()

	if !isDepthPass then
    	local newmzpcfs = {}
		local MuzzleParticles = self.MuzzPCFs
		
		for i = 0, #MuzzleParticles do
			if IsValid(MuzzleParticles[i]) then
    	        MuzzleParticles[i]:Render()
				newmzpcfs[#newmzpcfs + 1] = MuzzleParticles[i]
    	    end
		end
		

    	if !inrt then MuzzleParticles = newmzpcfs end
	end

    if ARC9.PresetCam then return end

    camera.IgnoreZ(false)
    Rendering.SetBlend(1)

    if !arc9_dev_benchgun:GetBool() then
        camera.End3D()
    end

	if isDepthPass then return end
    if inrt then return end

    self.RenderingHolosight = false
    camera.Start3D(nil, nil, self:WidescreenFix(self:GetViewModelFOV()), nil, nil, nil, nil, 1, 10000)
    if self.VModel then
        for _, model in ipairs(self.VModel) do
            local slottbl = model.slottbl
            local atttbl = self:GetFinalAttTable(slottbl)

            if atttbl.HoloSight then
                -- cam.IgnoreZ(true)
                self:DoHolosight(model, atttbl)
                -- cam.IgnoreZ(false)
            end
        end
    end
    camera.End3D()

    if arc9_fx_adsblur:GetBool() and self:GetSight().Blur != false and !self.Peeking then arc9toytown(self:GetSightAmount()) end -- cool ass blur
    -- render.UpdateFullScreenDepthTexture()
end
