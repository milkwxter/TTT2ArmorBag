if SERVER then
    AddCSLuaFile()
	resource.AddFile( "sound/plate_in.wav" )
	resource.AddFile( "materials/vgui/ttt/icon_armor_bag.vmt" )
	resource.AddFile( "materials/johnsheppard44/caliber/military/equipment/t_wp_i_armorrefill_a.vmt" )
	resource.AddFile( "models/johnsheppard44/caliber/military/equipment/armor plate.mdl" )
	resource.AddFile( "models/johnsheppard44/caliber/military/equipment/armor refill bag.mdl" )
end

DEFINE_BASECLASS("ttt_base_placeable")

if CLIENT then
    ENT.Icon = "vgui/ttt/icon_armor_bag"
    ENT.PrintName = "ttt_armor_bag_name"
end

ENT.Base = "ttt_base_placeable"
ENT.Model = "models/johnsheppard44/caliber/military/equipment/armor refill bag.mdl"

ENT.CanHavePrints = true
ENT.MaxStored = GetConVar("ttt_armorbag_max_plates_stored"):GetInt()
ENT.NextUse = 0

function ENT:SetupDataTables()
    BaseClass.SetupDataTables(self)

    self:NetworkVar("Int", 0, "StoredHealth")
end

function ENT:Initialize()
    self:SetModel(self.Model)

    BaseClass.Initialize(self)

    local b = 32

    self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b, b, b))

    if SERVER then
        self:SetMaxHealth(100)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(200)
        end

        self:SetUseType(SIMPLE_USE)
    end

    self:SetHealth(100)
    self:SetColor(Color(250, 250, 250, 255))
    self:SetStoredHealth(GetConVar("ttt_armorbag_max_plates_stored"):GetInt())

    self.NextUse = 0
    self.fingerprints = {}
end

function ENT:TakeFromStorage(amount)
    amount = math.min(amount, self:GetStoredHealth())

    self:SetStoredHealth(math.max(0, self:GetStoredHealth() - amount))

    return amount
end

local soundArmoring = Sound("plate_in.mp3")

function ENT:GiveArmor(ply)
	-- if there is armor left in the bag
    if self:GetStoredHealth() > 0 then
	
		-- make sure he doesnt go over the prevention threshold cvar
		if ply:GetArmor() >= GetConVar("ttt_armorbag_prevent_armor_higher_than"):GetInt() then return false end
		
        self:TakeFromStorage(1)
        ply:GiveArmor(GetConVar("ttt_armorbag_armor_per_plate"):GetInt())
        
		self:EmitSound(soundArmoring)

        if not table.HasValue(self.fingerprints, ply) then
           self.fingerprints[#self.fingerprints + 1] = ply
        end

        return true
    end

    return false
end

if SERVER then
    function ENT:Use(ply)
        if not IsValid(ply) or not ply:IsPlayer() or not ply:IsActive() then
            return
        end

        local t = CurTime()
        if t < self.NextUse then
            return
        end

        local armoringUser = self:GiveArmor(ply)

        self.NextUse = t + 1
    end
else
    local TryT = LANG.TryTranslation
    local ParT = LANG.GetParamTranslation

    local key_params = {
        usekey = Key("+use", "USE"),
        walkkey = Key("+walk", "WALK"),
    }
	
    function ENT:ClientUse()
        local client = LocalPlayer()

        if not IsValid(client) or not client:IsPlayer() or not client:IsActive() then
            return true
        end
    end

    -- handle looking at armor bag
    hook.Add("TTTRenderEntityInfo", "HUDDrawTargetIDArmorBag", function(tData)
        local client = LocalPlayer()
        local ent = tData:GetEntity()

        if
            not IsValid(client)
            or not client:IsTerror()
            or not client:Alive()
            or not IsValid(ent)
            or tData:GetEntityDistance() > 100
            or ent:GetClass() ~= "ttt2_armor_bag"
        then
            return
        end

        -- enable targetID rendering
        tData:EnableText()
        tData:EnableOutline()
        tData:SetOutlineColor(client:GetRoleColor())

        tData:SetTitle(TryT(ent.PrintName))
        tData:SetSubtitle(TryT("ttt_armor_bag_directions"))

        local armor_charges = ent:GetStoredHealth() or 0

        tData:AddDescriptionLine(TryT("ttt_armor_bag_explanation"))

        -- Tell player how many armor plates are inside
        if(armor_charges == 0) then
            tData:AddDescriptionLine(TryT("ttt_armor_bag_subtitle_amount_left") .. "EMPTY", COLOR_RED)
        else
            tData:AddDescriptionLine(TryT("ttt_armor_bag_subtitle_amount_left") .. armor_charges, COLOR_BLUE)
        end

        -- If player does not have enough armor to trigger the threshold
        if client:GetArmor() < GetConVar("ttt_armorbag_prevent_armor_higher_than"):GetInt() then
            tData:AddDescriptionLine(ParT("ttt_armor_bag_armor_readout", {
                    armorAmount = client:GetArmor(),
                }), COLOR_ORANGE)
            return
        end
		
		-- If player HAS ENOUGH to trigger the threshold
        tData:AddDescriptionLine(ParT("ttt_armor_bag_armor_readout_bad", {
                    armorAmount = client:GetArmor(),
                }), COLOR_ORANGE)
    end)
end