if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("external/sh_netstream2.lua")
	AddCSLuaFile("external/sh_pon.lua")
	AddCSLuaFile("meta/container.lua")
	AddCSLuaFile("meta/item.lua")
	AddCSLuaFile("sh_inv.lua")
	
	include("external/sv_database.lua")
end
include("external/sh_netstream2.lua")
include("external/sh_pon.lua")
include("meta/container.lua")
include("meta/item.lua")
include("sh_inv.lua")