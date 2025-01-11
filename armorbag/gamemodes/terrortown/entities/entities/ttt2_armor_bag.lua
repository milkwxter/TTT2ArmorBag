if SERVER then
    AddCSLuaFile()
end

DEFINE_BASECLASS("ttt_base_placeable")

if CLIENT then
    ENT.Icon = "vgui/ttt/icon_armor_bag"
    ENT.PrintName = "Deployable Armor Bag"
end

ENT.Base = "ttt_base_placeable"
ENT.Model = "models/johnsheppard44/caliber/military/equipment/armor refill bag.mdl"

ENT.CanHavePrints = true
ENT.MaxStored = 3
ENT.RechargeRate = 1
ENT.RechargeFreq = 2 -- in seconds

ENT.NextHeal = 0
ENT.HealRate = 1
ENT.HealFreq = 0.2

---
-- @realm shared
function ENT:SetupDataTables()
    BaseClass.SetupDataTables(self)

    self:NetworkVar("Int", 0, "StoredHealth")
end

---
-- @realm shared
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
    self:SetStoredHealth(3)

    self.NextHeal = 0
    self.fingerprints = {}
end

---
-- @param number amount
-- @return number
-- @realm shared
function ENT:TakeFromStorage(amount)
    -- if we only have 5 healthpts in store, that is the amount we heal
    amount = math.min(amount, self:GetStoredHealth())

    self:SetStoredHealth(math.max(0, self:GetStoredHealth() - amount))

    return amount
end

local soundHealing = Sound("plate_in.mp3")
local timeLastSound = 0

---
-- This hook that is called on the use of this entity, but only if the player
-- can be healed.
-- @param Player ply The player that is healed
-- @param Entity ent The healthstation entity that is used
-- @param number healed The amount of health receivde in this tick
-- @return boolean Return false to cancel the heal tick
-- @hook
-- @realm server
function GAMEMODE:TTTPlayerUsedHealthStation(ply, ent, healed) end

---
-- @param Player ply
-- @param number healthMax
-- @return boolean
-- @realm shared
function ENT:GiveArmor(ply, healthMax)
    if self:GetStoredHealth() > 0 then
		if ply:GetArmor() > 30 then return false end
        self:TakeFromStorage(1)
        ply:GiveEquipmentItem("item_ttt_armor")
        
        if timeLastSound + 2 < CurTime() then
            self:EmitSound(soundHealing)
            timeLastSound = CurTime()
        end

        if not table.HasValue(self.fingerprints, ply) then
           self.fingerprints[#self.fingerprints + 1] = ply
        end

        return true
    end

    return false
end

if SERVER then
    ---
    -- @param Player ply
    -- @realm server
    function ENT:Use(ply)
        if not IsValid(ply) or not ply:IsPlayer() or not ply:IsActive() then
            return
        end

        local t = CurTime()
        if t < self.NextHeal then
            return
        end

        local healed = self:GiveArmor(ply, self.HealRate)

        self.NextHeal = t + (self.HealFreq * (healed and 1 or 2))
    end

    ---
    -- @realm server
    function ENT:WasDestroyed()
        local originator = self:GetOriginator()

        if not IsValid(originator) then
            return
        end

        LANG.Msg(originator, "Your deployable armor bag was destroyed!", nil, MSG_MSTACK_WARN)
    end
else
    local TryT = LANG.TryTranslation
    local ParT = LANG.GetParamTranslation

    local key_params = {
        usekey = Key("+use", "USE"),
        walkkey = Key("+walk", "WALK"),
    }

    ---
    -- Hook that is called if a player uses their use key while focusing on the entity.
    -- Early check if client can use the health station
    -- @return bool True to prevent pickup
    -- @realm client
    function ENT:ClientUse()
        local client = LocalPlayer()

        if not IsValid(client) or not client:IsPlayer() or not client:IsActive() then
            return true
        end
    end

    -- handle looking at healthstation
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
        tData:SetSubtitle("Press [E] to armor up.")

        local hstation_charge = ent:GetStoredHealth() or 0

        tData:AddDescriptionLine("Armor plates reduce incoming damage.")

        -- Tell player how many armor plates are inside
        if(hstation_charge == 0) then
            tData:AddDescriptionLine("Remaining plates: " .. hstation_charge, COLOR_RED)
        else
            tData:AddDescriptionLine("Remaining plates: " .. hstation_charge, COLOR_BLUE)
        end

        -- If player already has armor
        if client:GetArmor() < 31 then
            tData:AddDescriptionLine(("You have " .. client:GetArmor() .. " armor."), COLOR_ORANGE)
            return
        end
        tData:AddDescriptionLine(("You already have " .. client:GetArmor() .. " reinforced armor. No more for you."), COLOR_ORANGE)
    end)
end