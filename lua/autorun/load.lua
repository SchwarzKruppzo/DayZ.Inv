if SERVER then AddCSLuaFile() end

load = {}
invmeta = {}

function load.Include( path )
	if !path then
		return
	end
	if path:find( "sv_" ) and SERVER then
		include( path )
	elseif path:find( "sh_" ) then
		if (SERVER) then
			AddCSLuaFile( path )
		end
		include(path)
	elseif path:find( "cl_" ) then
		if SERVER then
			AddCSLuaFile( path )
		else
			include( path )
		end
	end
end
function load.IncludeDir( dir )
	local gamemodeDir = "abdul_bomz/gamemode/" // for future using

	for k, v in ipairs( file.Find( dir.."/*.lua", "LUA") ) do
		load.Include( dir.."/"..v )
	end
end

load.Include( "external/sh_netstream2.lua" )
load.Include( "external/sh_pon.lua" )
load.Include( "external/sv_database.lua" )
load.Include( "meta/sh_container.lua" )
load.Include( "meta/sh_item.lua" )
load.Include( "sh_inv.lua" )

inv.LoadFromDirectory( "classes/containers", false )
inv.LoadFromDirectory( "classes/items", true )

if SERVER then
	database.Connect(function()
		database.LoadTables()
			
		MsgC( Color(0, 255, 0), "DayZ.Inv has connected to the database.\n" )
	end)
end