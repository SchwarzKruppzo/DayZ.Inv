inv = {}
inv.allItems = {}
inv.allContainers = {}

inv.baseItems = {}
inv.baseContainers = {}
inv.classItems = {}
inv.classContainers = {}

function inv.RegisterItemClass( classname, base, isBase, path ) 
	local meta = FindMetaTable("Item")

	if classname then
		ITEM = (isBase and inv.baseItems or inv.classItems)[classname] or setmetatable({}, meta)
		ITEM.class = classname
		ITEM.base = base
		ITEM.Data = ITEM.Data or {}
		ITEM.actions = ITEM.actions or {}
		// TODO: Add Drop and Take actions

		function ITEM:IsBase()
			return isBase
		end

		ITEM.Width = ITEM.Width or 1
		ITEM.Height = ITEM.Height or 1

		local cache_base = ITEM.base

		if ITEM.base then
			local baseClass = inv.baseItems[ITEM.base]
			if baseClass then
				for k, v in pairs( baseClass ) do
					if !ITEM[k] then
						ITEM[k] = v
					end
					ITEM.baseClass = baseClass
				end
				local cache_table = table.Copy( baseClass )
				ITEM = table.Merge( cache_table, ITEM )
			else
				ErrorNoHalt("[DayZInv] Attempt to register item: No such base found. ("..ITEM.base..")\n")
			end
		end

		if ITEM.base and cache_base != ITEM.base then
			local baseClass = inv.baseItems[ITEM.base]
			if baseClass then
				for k, v in pairs( baseClass ) do
					if !ITEM[k] then
						ITEM[k] = v
					end
					ITEM.baseClass = baseClass
				end
				local cache_table = table.Copy( baseClass )
				ITEM = table.Merge( cache_table, ITEM )
			else
				ErrorNoHalt("[DayZInv] Attempt to register item: No such base found. ("..ITEM.base..")\n")
			end
		end

		load.Include( path )

		if isBase then
			inv.baseItems[ITEM.class] = ITEM
		else
			inv.classItems[ITEM.class] = ITEM
		end
		
		ITEM = nil
	else
		ErrorNoHalt("[DayZInv] Attempt to register item: No such classname found.\n")
	end
end
function inv.RegisterContainerClass( classname, base, isBase, path )
	if classname then
		CONTAINER = ((isBase and inv.baseContainers or inv.classContainers)[classname]) or {}
		CONTAINER.class = classname
		CONTAINER.base = base
		function CONTAINER:IsBase()
			return isBase
		end
		CONTAINER.Name = CONTAINER.Name or ""
		CONTAINER.Width = CONTAINER.Width or 1
		CONTAINER.Height = CONTAINER.Height or 1
		CONTAINER.Model = CONTAINER.Model or ""

		local cache_base = CONTAINER.base

		if CONTAINER.base then
			local baseClass = inv.baseContainers[CONTAINER.base]
			if baseClass then
				for k, v in pairs( baseClass ) do
					if !CONTAINER[k] then
						CONTAINER[k] = v
					end
					CONTAINER.baseClass = baseClass
				end
				local cache_table = table.Copy( baseClass )
				CONTAINER = table.Merge( cache_table, CONTAINER )
			else
				ErrorNoHalt("[DayZInv] Attempt to register container type: No such base found. ("..CONTAINER.base..")\n")
			end
		end

		if CONTAINER.base and cache_base != CONTAINER.base then
			local baseClass = inv.baseContainers[CONTAINER.base]
			if baseClass then
				for k, v in pairs( baseClass ) do
					if !CONTAINER[k] then
						CONTAINER[k] = v
					end
					CONTAINER.baseClass = baseClass
				end
				local cache_table = table.Copy( baseClass )
				CONTAINER = table.Merge( cache_table, CONTAINER )
			else
				ErrorNoHalt("[DayZInv] Attempt to register container type: No such base found. ("..CONTAINER.base..")\n")
			end
		end

		load.Include( path )
		
		if isBase then
			inv.baseContainers[CONTAINER.class] = CONTAINER
		else
			inv.classContainers[CONTAINER.class] = CONTAINER
		end

		CONTAINER = nil
	else
		ErrorNoHalt("[DayZInv] Attempt to register container type: No such classname found.\n")
	end
end

function inv.DB_CreateItemObject( inventoryID, classname, data, x, y, callback ) 
	if !classname or inv.classItems[classname] then
		local containerID = nil
		if inv.classItems[classname]:IsContainer() then
			local owner = 0
			local containerOwned = inv.allContainers[inventoryID]
			if containerOwned then
				owner = (containerOwned.GetOwner and containerOwned:GetOwner() or 0)
			end
			local containerInfo = { Name = "unknown", Model = "", Width = 1, Height = 1 }
			if inv.classItems[classname].ContainerInfo then
				containerInfo.Name = inv.classItems[classname].Name
				containerInfo.Model = inv.classItems[classname].Model
				containerInfo.Width = inv.classItems[classname].Width
				containerInfo.Height = inv.classItems[classname].Height
			end
			containerID = inv.DB_CreateContainerObject( owner, containerInfo )
		end
		database.InsertTable( {
			_invID = inventoryID,
			_ownerInvID = containerID,
			_class = classname,
			_data = data,
			_x = x,
			_y = y
		}, function( data, uniqueID )
			local item = inv.NewItemObject( uniqueID, classname )

			if item then
				item.Data = ( data or {} )
				item.invID = inventoryID

				if containerID then
					if inv.allContainers[containerID] then
						item.ownerInvID = containerID
						inv.allContainers[containerID].ownedItemID = uniqueID
					end
				end

				if callback then
					callback( item )
				end

				if item.OnInstanced then
					item:OnInstanced(index, x, y, item)
				end
			end
		end, "items" )
	else
		ErrorNoHalt("[DayZInv] Attempt to give item: Invalid item specifed. ("..( classname or "nil" )..")\n")
	end
end

function inv.DB_CreateContainerObject( owner, classname, containerItemID, callback ) 
	local containerInfo = nil

	if type( classname ) == "table" then
		containerInfo = classname
	else
		containerInfo = inv.classContainers[classname] or { Name = "unknown", Model = "", Width = 1, Height = 1 }
	end

	database.InsertTable( {
		_steamID = (owner > 0) and ( (type( owner ) == "Player") and owner:SteamID() or tostring( owner ) ) or nil,
		_ownerItemID = containerItemID,
		_class = classname
	}, function( data, uniqueID )
		local container = inv.NewContainerObject( uniqueID, containerInfo, containerItemID )

		if owner and owner > 0 then
			for k, v in pairs( player.GetAll() ) do
				if v == owner then
					container:SetOwner( v )
					container:SendInventory( v )

					break
				end
			end
		end

		if callback then
			callback( container )
		end
	end, "containers" )
end

function inv.LoadItemClasses( file, path, base, isBase ) 
	local classname = string.gsub( file:lower(), ".lua", "" )

	if classname then
		if SERVER then AddCSLuaFile( path ) end
		
		classname = (isBase and "base_" or "")..classname
		inv.RegisterItemClass( classname, base, isBase, path )
	end
end
function inv.LoadContainerClasses( file, path, base, isBase ) 
	local classname = string.gsub( file:lower(), ".lua", "" )

	if classname then
		if SERVER then AddCSLuaFile( path ) end
		
		classname = (isBase and "base_" or "")..classname
		inv.RegisterContainerClass( classname, base, isBase, path )
	end
end
function inv.LoadFromDirectory( directory, isItem )
	local loadFunction = isItem and inv.LoadItemClasses or inv.LoadContainerClasses

	local files, folders = file.Find( directory.."/base/*.lua", "LUA" )
	for k, v in ipairs(files) do
		loadFunction( v, directory.."/base/"..v, nil, true )
	end

	local files, folders = file.Find( directory.."/*", "LUA" )
	for k, v in ipairs( folders ) do
		if v == "base" then continue end
		
		for z, x in ipairs( file.Find( directory.."/"..v.."/*.lua", "LUA" ) ) do
			loadFunction( x, directory.."/"..v .. "/".. x, "base_"..v )
		end
	end

	for k, v in ipairs( files ) do
		loadFunction( v, directory.."/"..v )
	end 
end

function inv.NewItemObject( uniqueID, classname ) 
	if inv.allItems[uniqueID] then
		return inv.allItems[uniqueID]
	end

	local itemClass = inv.classItems[classname]

	if itemClass then
		local ITEM = setmetatable( {}, { __index = itemClass } )
		ITEM.uniqueID = uniqueID
		ITEM.Data = {}

		inv.allItems[uniqueID] = ITEM

		return ITEM
	else
		ErrorNoHalt("[DayZInv] Attempt to index unknown item. ("..classname..")\n")
	end
end
function inv.NewContainerObject( uniqueID, classname, containerItemID ) 
	if inv.allContainers[uniqueID] then
		return inv.allContainers[uniqueID]
	end

	local containerType = inv.classContainers[classname]

	if containerType then
		local container = setmetatable( {}, FindMetaTable("Container") )
		container.inventory = {}
		container.class = classname
		container.w = containerType.Width
		container.h = containerType.Height
		container.ownedItemID = containerItemID

		inv.allContainers[uniqueID] = container

		return container
	else
		ErrorNoHalt("[DayZInv] Attempt to index unknown container type. ("..classname..")\n")
	end
end

function inv.DB_LoadContainerObject( uniqueID, classname, callback ) end
function inv.DB_LoadItemObject( uniqueID ) end

if CLIENT then
	netstream.Hook("DayZInv_net.container", function( inventoryTable, inventoryID, inventoryClass, inventoryOwnerID ) end)
	netstream.Hook("DayZInv_net.containerItem.Set", function( inventoryID, x, y, itemClassname, itemUniqueID, inventoryOwnerID, itemData ) end)
	netstream.Hook("DayZInv_net.containerItem.Rm", function( itemUniqueID, inventoryID ) end)
else
	function inv.SpawnItem( classname, pos, ang, data, callback ) end
end