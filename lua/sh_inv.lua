inv = {}
inv.allItems = {}
inv.allContainers = {}
inv.baseItems = {}
inv.baseContainers = {}
inv.classItems = {}
inv.classContainers = {}

function inv.GetStoredContainers()
	return inv.allContainers
end
function inv.GetStoredContainer( uniqueID )
	for k, v in pairs( inv.allContainers ) do
		if k == uniqueID then
			return inv.allContainers[k]
		end
	end
end
function inv.GetStoredItems()
	return inv.allItems
end
function inv.GetStoredItem( uniqueID )
	for k, v in pairs( inv.allItems ) do
		if k == uniqueID then
			return inv.allItems[k]
		end
	end
end
function inv.GetBaseContainers()
	return inv.baseContainers
end
function inv.GetBaseContainer( uniqueID )
	for k, v in pairs( inv.baseContainers ) do
		if k == uniqueID then
			return inv.baseContainers[k]
		end
	end
end
function inv.GetBaseItems()
	return inv.baseItems
end
function inv.GetBaseItem( uniqueID )
	for k, v in pairs( inv.baseItems ) do
		if k == uniqueID then
			return inv.baseItems[k]
		end
	end
end
function inv.GetContainers()
	return inv.classContainers
end
function inv.GetContainer( uniqueID )
	for k, v in pairs( inv.classContainers ) do
		if k == uniqueID then
			return inv.classContainers[k]
		end
	end
end
function inv.GetItems()
	return inv.classItems
end
function inv.GetItem( uniqueID )
	for k, v in pairs( inv.classItems ) do
		if k == uniqueID then
			return inv.classItems[k]
		end
	end
end

function inv.RegisterItemClass( classname, base, isBase, path ) 
	local meta = invmeta.item

	if classname then
		ITEM = (isBase and inv.baseItems or inv.classItems)[classname] or setmetatable({}, meta)
		ITEM.class = classname
		ITEM.base = base
		ITEM.Data = ITEM.Data or {}
		ITEM.actions = ITEM.actions or {}
		// TODO: Add Drop and Take actions

		ITEM.IsContainer = ITEM.IsContainer or function( self ) return false end

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
	local meta = invmeta.container

	if classname then
		CONTAINER = ((isBase and inv.baseContainers or inv.classContainers)[classname]) or setmetatable({}, meta)
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
		_steamID = type( owner ) == "Player" and tostring(owner:SteamID()) or ( type( owner ) == "string" and tostring(owner) or ( type( owner ) == "Number" and tostring(owner) or tostring(owner) ) ),
		_ownerItemID = containerItemID,
		_class = classname
	}, function( data, uniqueID )
		local container = inv.NewContainerObject( uniqueID, classname, containerItemID )
		container:SetOwner( owner )
		if owner then
			for k, v in pairs( player.GetAll() ) do
				if v == owner then
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
	if !uniqueID then
		uniqueID = #inv.allItems + 1
	end

	if inv.allItems[uniqueID] then
		return inv.allItems[uniqueID]
	end

	local itemClass = inv.classItems[classname]

	if itemClass then
		local ITEM = setmetatable( {}, { __index = itemClass } )
		ITEM.uniqueID = uniqueID
		ITEM.class = classname
		ITEM.Data = {}

		if ITEM:IsContainer() then
			local containerInfo = { Name = "unknown", Model = "", Width = 1, Height = 1 }
			if ITEM.ContainerInfo then
				containerInfo.Name = ITEM.ContainerInfo.Name or ""
				containerInfo.Model = ITEM.ContainerInfo.Model or ""
				containerInfo.Width = ITEM.ContainerInfo.Width or 1
				containerInfo.Height = ITEM.ContainerInfo.Height or 1
			end
			local container, containerID = inv.NewContainerObject( nil, containerInfo, uniqueID ) 

			if containerID then
				ITEM.ownerInvID = containerID
			end
		end

		inv.allItems[uniqueID] = ITEM
		return ITEM
	else
		ErrorNoHalt("[DayZInv] Attempt to index unknown item. ("..classname..")\n")
	end
end
function inv.NewContainerObject( uniqueID, classname, containerItemID ) 
	if !uniqueID then
		uniqueID = #inv.allContainers + 1
	end

	if inv.allContainers[uniqueID] then
		return inv.allContainers[uniqueID]
	end

	if type(classname) == "table" then
		local meta = invmeta.container
		
		local container = setmetatable( { inventory = {}, class = "_custom", w = classname.Width, h = classname.Height, ownedItemID = containerItemID, overrideName = classname.Name, overrideModel = classname.Model }, meta )
		container.uniqueID = uniqueID
		inv.allContainers[uniqueID] = container

		return container, uniqueID
	else
		local meta = invmeta.container
		local containerType = inv.classContainers[classname]

		if containerType then
			local container = setmetatable( { inventory = {}, class = classname, w = containerType.Width, h = containerType.Height, ownedItemID = containerItemID }, meta )
			container.uniqueID = uniqueID
			inv.allContainers[uniqueID] = container

			return container, uniqueID
		else
			ErrorNoHalt("[DayZInv] Attempt to index unknown container type. ("..classname..")\n")
		end
	end
end

if SERVER then
	function inv.DB_SaveContainers()
		for k, v in pairs( inv.GetStoredContainers() ) do
		    local query = "SELECT _uniqueID, _steamID, _class, _ownedItemID FROM dayzinv_containers WHERE _uniqueID = "..tostring(k)
		    database.Query( query, function( data )
		    	local class = v.class
		    	if type( class ) == "table" then
		    		v.class = pon.encode( class )
		    	end

		        if !data then
		            database.InsertTable( {
						_steamID = v.ownerID,
						_ownerItemID = v.ownedItemID or nil,
						_class = v.class
					}, function() end, "containers" )
		       	else
		       		database.UpdateTable( {
						_steamID = v.ownerID,
						_ownerItemID = v.ownedItemID or nil,
						_class = v.class
					}, function() end, "containers", "_uniqueID = "..tostring(k) )
		       	end
		    end )
		end
	end

	function inv.DB_SaveItems()
		for k, v in pairs( inv.GetStoredItems() ) do
		    local query = "SELECT _uniqueID, _ownerInvID, _invID, _x, _y, _class, _data FROM dayzinv_items WHERE _uniqueID = "..tostring(k)
		    database.Query( query, function( data )
		        if !data then
		            database.InsertTable( {
						_invID = v.invID,
						_ownerInvID = v.ownerInvID,
						_class = v.class,
						_data = v.Data,
						_x = v.posX,
						_y = v.posY
					}, function() end, "items" )
		       	else
		       		database.UpdateTable( {
						_invID = v.invID,
						_ownerInvID = v.ownerInvID,
						_class = v.class,
						_data = v.Data,
						_x = v.posX,
						_y = v.posY
					}, function() end, "items", "_uniqueID = "..tostring(k) )
		       	end
		    end )
		end
	end

	function inv.DB_LoadContainers() 
		local query = "SELECT _uniqueID, _steamID, _class, _ownedItemID FROM dayzinv_containers"
		database.Query( query, function( data )
			if data then
				for k, v in pairs( data ) do
					local class = v._class

					if !inv.classContainers[class] then
						if pcall( pon.decode, class ) then
							class = pon.decode( class )
						end
					end
					--print("top",v._uniqueID)
					--local containerInfo = nil

					--if type( v._class ) == "table" then
					--	containerInfo = v._class
					--else
					--	containerInfo = inv.classContainers[v._class] or { Name = "unknown", Model = "", Width = 1, Height = 1 }
					--end

					local container = inv.NewContainerObject( tonumber(v._uniqueID), class, tonumber(v._ownedItemID) )
					if container then
						container:SetOwner( v._steamID )
					end
				end
			end
		end )
	end

	function inv.DB_LoadItems() 
		local query = "SELECT _uniqueID, _ownerInvID, _invID, _x, _y, _class, _data FROM dayzinv_items"
		database.Query( query, function( data )
			if data then
				for k, v in pairs( data ) do
					v._uniqueID = tonumber( v._uniqueID )
					v._ownerInvID = tonumber( v._ownerInvID )
					v._invID = tonumber( v._invID )

					local item = inv.NewItemObject( v._uniqueID, v._class )

					if item then
						item.invID = v._invID

						if v._ownerInvID then
							if inv.allContainers[v._ownerInvID] then
								item.ownerInvID = v._ownerInvID
								inv.allContainers[v._ownerInvID].ownedItemID = v._uniqueID
							end
						end
						if inv.allContainers[item.invID] then
							inv.allContainers[item.invID]:AddItem( item:GetUniqueID(), item.Data, item.posX, item.posY, false )
						end
					end
				end
			end
		end )
	end

	hook.Add( "OnLoadTables", "DayZInv.LoadTables", function()
		inv.DB_LoadContainers() 
		inv.DB_LoadItems()
	end )

	hook.Add( "PlayerInitialSpawn", "DayZInv.PlayerInitialSpawn", function( client )
		local main_inventory = nil
		for k, v in pairs( inv.GetStoredContainers() ) do
			if v:GetOwner() == client then
				if v.class == "player_inventory" then
					main_inventory = v
				end
				v:SendInventory( client )
			end
		end
		if main_inventory then
			client:SetNWInt( "InventoryID", main_inventory:GetUniqueID() )
			print(1)
		else
			local container, uniqueID = inv.NewContainerObject( nil, { Name = "PizdecSykaGavnoEbanoe", Model = "shit.mdl", Width = 5, Height = 5}, nil ) 
			container:SetOwner( client )
			container:SendInventory( client )
			client:SetNWInt( "InventoryID", uniqueID )
			print(2)
			--inv.DB_CreateContainerObject( client:SteamID(), "player_inventory", nil, function( container ) 
			--	client.GetInventoryID = function()
			--		return container:GetUniqueID()
			--	end
			--end ) 
		end
	end )
end

if CLIENT then
	--Receiving an inventory from server
	netstream.Hook("DayZInv_net.container", function( inventoryID, inventoryClass, inventoryOwnerID, customName, customWidth, customHeight, customModel ) 
		local classname = inventoryClass

		if inventoryClass == "_custom" then
			classname = { Name = customName, Width = customWidth, Height = customHeight, Model = customModel }
		end

		local container = inv.NewContainerObject( inventoryID, classname, nil ) 
		container:SetOwner( inventoryOwnerID )
	end)

	--Receiving an item from server
	netstream.Hook("DayZInv_net.container.Item", function( inventoryID, itemX, itemY, itemID, itemClass, itemOwnerInvID, itemData ) 
		inventoryID = inventoryID and tonumber(inventoryID) or 0
		itemX = itemX and tonumber(itemX) or 0
		itemY = itemY and tonumber(itemY) or 0
		itemID = itemID and tonumber(itemID) or nil
		itemOwnerInvID = itemOwnerInvID and tonumber(itemOwnerInvID) or nil
		itemData = itemData and pon.decode( itemData ) or {}

		local item = inv.NewItemObject( itemID, itemClass )
		if item then
			item.invID = inventoryID

			if itemOwnerInvID then
				if inv.allContainers[itemOwnerInvID] then
					item.ownerInvID = itemOwnerInvID
					inv.allContainers[itemOwnerInvID].ownedItemID = itemID
				end
			end
			if inv.allContainers[item.invID] then
				inv.allContainers[item.invID]:AddItem( itemID, item.Data, item.posX, item.posY, false )
			end
		end
	end)

	--Receiving a signal from server that item must be removed
	netstream.Hook("DayZInv_net.container.Item.Remove", function( itemID ) 
		
	end)


	--netstream.Hook("DayZInv_net.containerItem.Set", function( inventoryID, x, y, itemClassname, itemUniqueID, inventoryOwnerID, itemData ) end)
else
	function inv.SpawnItem( classname, pos, ang, data, callback ) end
end


local playerMeta = FindMetaTable("Player")

function playerMeta:GetInventoryID()
	return self:GetNWInt( "InventoryID" ) or nil
end
function playerMeta:GetInventory()
	local id = self:GetNWInt( "InventoryID" )
	return inv.allContainers[id]
end