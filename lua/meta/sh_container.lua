local META = invmeta.container or {}
META.__index = META
META.inventory = META.inventory or {}
META.class = META.class or ""
META.w = META.w or 1
META.h = META.h or 1

function META:__tostring()
	return "container["..(self.uniqueID or 0).."]"
end

function META:SetSize( w, h )
	self.w = w
	self.h = h
end

function META:SetOwner( entity, updateDB )
	local steamID = ""
	
	if type( entity ) == "Player" then
		steamID = entity:SteamID()
	elseif type( entity ) == "string" then
		steamID = entity
	end

	if SERVER and updateDB then
		for k, v in ipairs( player.GetAll() ) do
			if v:SteamID() == steamID then
				self:SendInventory( v )
				
				break
			end
		end

		--database.Query( "UPDATE dayzinv_containers SET _steamID = "..steamID.." WHERE _uniqueID = " .. self:GetUniqueID() )
	end

	self.ownerID = steamID
end

function META:GetUniqueID()
	return self.uniqueID
end

function META:GetSize()
	return self.w, self.h
end

function META:GetClass()
	return self.class
end

function META:GetModel()
	if self.class == "_custom" then
		return self.overrideModel
	else
		return inv.GetContainer( self.class ).Model or "models/error.mdl"
	end
end

function META:GetName()
	if self.class == "_custom" then
		return self.overrideName
	else
		return inv.GetContainer( self.class ).Name or "Unnamed"
	end
end

function META:GetOwner()
	for k, v in ipairs(player.GetAll()) do
		if v:SteamID() == self.ownerID then
			return v
		end
	end
end

function META:GetItemAt( x, y )
	if self.inventory and self.inventory[y] then
		local slot = self.inventory[y][x]
		
		if slot then
			--if slot.item then
			--	return slot.item, slot.main
			--end
			return slot
		end
	end
end

function META:GetItemByID( uniqueID )
	for y = 0, self.h - 1 do
		if self.inventory[y] then
			for x = 0, self.w - 1 do
				local slot = self.inventory[y][x]
				
				if slot then
					--if slot.main then
						--if slot.item == uniqueID then
						--	return x, y
						--end
					--end
					if slot.uniqueID == uniqueID then
						return slot
					end
				end
			end
		end
	end
end

function META:GetItems()
	local items = {}

	for y = 0, self.h - 1 do
		if self.inventory[y] then
			for x = 0, self.w - 1 do
				local slot = self.inventory[y][x]
				
				if slot then
					--if slot.main then
					--	local itemInstance = inv.allItems[ slot.item ]
					--	items[ slot.item ] = itemInstance
					--end
					--print(slot.uniqueID,type(slot.uniqueID))
					if !items[slot.uniqueID] then
						items[slot.uniqueID] = slot
					end
				end
			end
		end
	end

	return items
end

function META:RemoveItemByID( uniqueID, NoSend, NoDelete )
	for y = 0, self.h - 1 do
		if self.inventory[y] then
			for x = 0, self.w - 1 do
				local slot = self.inventory[y][x]
				
				if slot then
					if slot.uniqueID == uniqueID then
						self.inventory[y][x] = nil
					end
				end
			end
		end
	end
	
	if SERVER then
		if !NoSend then
			local owner = self:GetOwner()

			--netstream.Start( owner, "DayZInv_net.containerItem.Rm", uniqueID, self:GetUniqueID() )

			if !NoDelete then
				local item = inv.allItems[ uniqueID ]
				
				if item and item.OnRemove then
					item:OnRemove()
				end

				--database.Query("DELETE FROM dayzinv_items WHERE _uniqueID = " .. uniqueID )
				
				inv.allItems[ uniqueID ] = nil
			end
		end
	end
end

function META:HasItem( class )
	local items = self:GetItems()
	
	for k, v in pairs( items ) do
		if v.class == class then
			return v
		end
	end
	return false
end

function META:CanItemFit( x, y, w, h, slot2 )
	local can = true

	for x_Inv = 0, w - 1 do
		for y_Inv = 0, h - 1 do
			local slot = (self.inventory[y + y_Inv] or {})[x + x_Inv]

			if ( ( x + x_Inv ) > self.w or slot ) then
			
				if slot2 then
					if slot then
						--if slot.item.uniqueID == slot2.item.uniqueID then
						--	continue
						--end
						if slot.uniqueID == slot2.uniqueID then
							continue
						end
					end
				end

				can = false
				break
			end
		end

		if !can then
			break
		end
	end

	return can
end

function META:FindEmptySlot( w, h )
	w = w or 1
	h = h or 1

	if w > self.w or h > self.h then
		return
	end
	
	for y = 1, self.h - (h - 1) do
		for x = 1, self.w - (w - 1) do
			if self:CanItemFit( x, y, w, h ) then
				return x, y
			end
		end
	end
end

function META:AddItem( classOrID, data, x, y, NoSend )
	if type( classOrID ) == "number" then
		local item = inv.allItems[ classOrID ]

		if item then
			if !x and !y then
				x, y = self:FindEmptySlot( item.Width, item.Height )
			end

			if x and y then
				self.inventory[y] = self.inventory[y] or {}
				self.inventory[y][x] = {}

				item.posX = x
				item.posY = y
				item.invID = self:GetUniqueID()

				local link = setmetatable( {}, { __index = item } )

				for y2 = 0, item.Height - 1 do
					for x2 = 0, item.Width - 1 do
						self.inventory[y + y2] = self.inventory[y + y2] or {}
						self.inventory[y + y2][x + x2] = link --{}
						--self.inventory[y + y2][x + x2].item = item
					end
				end
				
				--self.inventory[y][x].main = true
				
				if SERVER then
					if !NoSend then
						--self:SendSlot( x, y, item )
						local req = self:GetOwner()
						if req then
							item:Send( req )
						end
					end
				end
		
				--database.Query("UPDATE dayzinv_items SET _invID = "..self:GetUniqueID()..", _ownerInvID = "..item.ownerInvID..", _x = "..x..", _y = "..y..", _data = "..item.data.." WHERE _uniqueID = "..item.uniqueID)

				return x, y, self:GetUniqueID()
			else
				return false, "Attempt to add item: No space found."
			end
		else
			return false, "Attempt to add item: No such instance found."
		end
	else
		local itemTable = inv.classItems[classOrID]

		if !itemTable then
			return false, "Attempt to add item: No such item found with specifed classname."
		end

		if (!x and !y) or !self:CanItemFit( x, y, itemTable.Width, itemTable.Height ) then
			x, y = self:FindEmptySlot( itemTable.Width, itemTable.Height )
		end
			
		if x and y then
			self.inventory[y] = self.inventory[y] or {}
			self.inventory[y][x] = {}

			local item = inv.NewItemObject( nil, classOrID ) 
			item.invID = self:GetUniqueID()

			--inv.DB_CreateItemObject( self:GetUniqueID(), classOrID, data, x, y, function( item )
			if data then
				item.Data = table.Merge( item.Data, data )
			end

			item.posX = x
			item.posY = y

			local link = setmetatable( {}, { __index = item } )

			for y2 = 0, item.Height - 1 do
				for x2 = 0, item.Width - 1 do
					self.inventory[y + y2] = self.inventory[y + y2] or {}
					self.inventory[y + y2][x + x2] = link --{} 
					--self.inventory[y + y2][x + x2].item = item
				end
			end
					
			--self.inventory[y][x].main = true
					
			if SERVER then
				if !NoSend then
					--self:SendSlot( x, y, item )
					local req = self:GetOwner()
					if req then
						item:Send( req )
					end
				end
			end

			--end )
			return x, y, self:GetUniqueID()
		else
			return false, "Attempt to add item: No space found."
		end
	end
end

if SERVER then
	function META:SendSlot( item, receiver )
		receiver = receiver or self:GetOwner()
		if item then
			item:Send( receiver )
		end
	end
	
	function META:SendInventory( receiver )
		--local inventory = {}
		--for y = 0, self.h - 1 do
			--if self.inventory[y] then
				--for x = 0, self.w - 1 do
					--local slot = self.inventory[y][x]
					
					--if slot then
						--local item = inv.allItems[ slot.item ]

						--inventory[y] = inventory[y] or {}
						--inventory[y][x] = { slot.class, slot.uniqueID, slot.Data }
					--end
				--end
			--end
		--end
		local name, w, h, model = nil
		if self:GetClass() == "_custom" then
			name = self.overrideName
			w = self.w
			h = self.h
			model = self.overrideModel
		end

		netstream.Start( receiver, "DayZInv_net.container", self:GetUniqueID(), self:GetClass(), self.ownerID, name, w, h, model )
		
		for k, item in pairs( self:GetItems() ) do
			item:Send( receiver )
		end

		for k, v in pairs( self:GetItems() ) do
			v:Call( "OnSendInventory", receiver )
		end
	end
end

invmeta.container = META