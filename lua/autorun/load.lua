if SERVER then AddCSLuaFile() end

load = {}

function load.Include( path, side )
	if !path then
		return
	end
	if ( side == "server" or path:find( "sv_" ) ) and SERVER then
		include( path )
	elseif side == "shared" or path:find( "sh_" ) then
		if (SERVER) then
			AddCSLuaFile( path )
		end
		include(path)
	elseif side == "client" or path:find( "cl_" ) then
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

load.IncludeDir( "external" )
load.IncludeDir( "meta" )
load.Include( "sh_inv.lua" )

inv.LoadFromDirectory( "classes/containers", false )
inv.LoadFromDirectory( "classes/items", true )