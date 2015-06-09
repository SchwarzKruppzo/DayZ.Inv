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

		include( path )

		(isBase and inv.baseItems or inv.classItems)[ITEM.uniqueID] = ITEM

		ITEM = nil
	else
		ErrorNoHalt("[DayZInv] Attempt to register item: No such classname found.\n")
	end
end
function inv.RegisterContainerClass( classname, base, isBase, path ) 
	if classname then
		CONTAINER = (isBase and inv.baseContainers or inv.classContainers)[classname] or {})
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

		include( path )

		(isBase and inv.baseContainers or inv.classContainers)[CONTAINER.uniqueID] = CONTAINER

		CONTAINER = nil
	else
		ErrorNoHalt("[DayZInv] Attempt to register container type: No such classname found.\n")
	end
end

function inv.DB_CreateItemObject( inventoryID, classname, data, x, y, callback ) end
function inv.DB_CreateContainerObject( owner, classname, callback ) end

function inv.LoadItemClasses( file, path, base, isBase ) 
	local classname = string.gsub( class:lower(), ".lua", "" )

	if classname then
		classname = (isBase and "base_" or "")..classname
		inv.RegisterItemClass( classname, base, isBase, path )
	end
end
function inv.LoadContainerClasses( file, path, base, isBase ) 
	local classname = string.gsub( class:lower(), ".lua", "" )

	if classname then
		classname = (isBase and "base_" or "")..classname
		inv.RegisterContainerClass( classname, base, isBase, path )
	end
end
function inv.LoadFromDirectory( directory, isItem )
	local loadFunction = isItem and inv.LoadItemClasses or inv.LoadContainerClasses

	local files, folders = file.Find( directory.."/base/*.lua", "LUA" )
	for k, v in ipairs(files) do
		loadFunction( directory.."/base/"..v, nil, true )
	end

	local files, folders = file.Find( directory.."/*", "LUA" )
	for k, v in ipairs( folders ) do
		if v == "base" then continue end
		
		for z, x in ipairs( file.Find( directory.."/"..v.."/*.lua", "LUA" ) ) do
			loadFunction( directory.."/"..v .. "/".. x, "base_"..v )
		end
	end

	for k, v in ipairs( files ) do
		loadFunction( directory.."/"..v )
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
function inv.NewContainerObject( uniqueID, classname ) 
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