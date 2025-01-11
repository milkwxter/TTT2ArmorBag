if SERVER then
    AddCSLuaFile()
	resource.AddWorkshop("3264814948")
end

DEFINE_BASECLASS("weapon_tttbase")

SWEP.HoldType = "normal"

if CLIENT then
    SWEP.PrintName = "ttt_armor_bag_name"
    SWEP.Slot = 6

    SWEP.ShowDefaultViewModel = false

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "ttt_armor_bag_desc",
    }

    SWEP.Icon = "vgui/ttt/icon_armor_bag"
end

-- SUPER CONFIGURABLE VARIABLES
CreateConVar("ttt_armorbag_max_plates_stored", "3", flags)
CreateConVar("ttt_armorbag_armor_per_plate", "30", flags)
CreateConVar("ttt_armorbag_prevent_armor_higher_than", "30", flags)

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/props/cs_office/microwave.mdl"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1.0

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 1.0

-- This is special equipment
SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = { ROLE_DETECTIVE } -- only detectives can buy
SWEP.LimitedStock = true -- only buyable once
SWEP.WeaponID = AMMO_HEALTHSTATION

SWEP.AllowDrop = false
SWEP.NoSights = true

SWEP.drawColor = Color(180, 180, 250, 255)

---
-- @ignore
function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if SERVER then
        local bag = ents.Create("ttt2_armor_bag")

        if bag:ThrowEntity(self:GetOwner(), Angle(90, -90, 0)) then
            self:Remove()
        end
    end
end

---
-- @ignore
function SWEP:Reload()
    return false
end

---
-- @realm shared
function SWEP:Initialize()
    if CLIENT then
        self:AddTTT2HUDHelp("ttt_armor_bag_help")
    end

    self:SetColor(self.drawColor)

    return BaseClass.Initialize(self)
end

if CLIENT then
    function SWEP:DrawWorldModel()
        if IsValid(self:GetOwner()) then
            return
        end

        self:DrawModel()
    end
	
    function SWEP:DrawWorldModelTranslucent() end
	
	function SWEP:AddToSettingsMenu(parent)
        local form = vgui.CreateTTT2Form(parent, "header_equipment_additional")

        form:MakeHelp({
            label = "help_ttt_armorbag_max_plates_stored",
        })
        form:MakeSlider({
            serverConvar = "ttt_armorbag_max_plates_stored",
            label = "label_armorbag_max_plates_stored",
            min = 0,
            max = 10,
            decimal = 0,
        })

        form:MakeHelp({
            label = "help_ttt_armorbag_armor_per_plate",
        })
        form:MakeSlider({
            serverConvar = "ttt_armorbag_armor_per_plate",
            label = "label_ttt_armorbag_armor_per_plate",
            min = 1,
            max = 100,
            decimal = 0,
        })

        form:MakeHelp({
            label = "help_ttt_armorbag_prevent_armor_higher_than",
        })
        form:MakeSlider({
            serverConvar = "ttt_armorbag_prevent_armor_higher_than",
            label = "label_ttt_armorbag_prevent_armor_higher_than",
            min = 1,
            max = 100,
            decimal = 0,
        })
    end
end