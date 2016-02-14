local ITEM = invmeta.item or {}
ITEM.__index = ITEM
ITEM.Name = "Unknown"
ITEM.Width = ITEM.Width or 1
ITEM.Height = ITEM.Height or 1
ITEM.Model = ITEM.Model or ""
ITEM.Icon = ITEM.Icon or {
	pos = Vector(),
	ang = Angle(),
	fov = 5
}

ITEM.class = "unknown_item"
ITEM.uniqueID = ITEM.uniqueID or 0
ITEM.invID = ITEM.invID or nil
ITEM.ownerInvID = ITEM.ownerInvID or nil
ITEM.posX = ITEM.posX or 0
ITEM.posY = ITEM.posY or 0

function ITEM:__eq( item )
	return self:GetUniqueID() == item:GetUniqueID()
end
function ITEM:__tostring()
	local container = self:IsContainer() and "[container]" or ""
	return "item["..self.class.."]["..self.uniqueID.."]"..container
end

function ITEM:IsContainer()
	return false
end
function ITEM:GetUniqueID()
	return self.uniqueID
end
function ITEM:GetContainer() 
	return inv.allContainers[ self.ownerInvID ]
end
function ITEM:GetOwner() 
	local container = inv.allContainers[self.invID]

	if container then
		return container.GetOwner and container:GetOwner()
	end
end
function ITEM:GetData( key, default ) 
	if self.Data then
		if key == true then
			return self.Data
		end

		local value = self.Data[key]

		if value == nil then
			if IsValid( self.entity ) then
				local data = self.entity:GetNetItemData() or {}
				local value = data[key]

				if value != nil then
					return value
				end
			end

			return default
		else
			return value
		end
	else
		self.Data = {}
		return default
	end
end
function ITEM:SetData( key, value, receivers, NoSave, NoSetEntity ) 
	self.Data = self.Data or {}
	self.Data[key] = value

	if SERVER then
		if !NoSetEntity then
			local ent = self:GetEntity()

			if IsValid( ent ) then
				local data = ent:GetNetItemData() or {}
				data[key] = value

				ent:SetNetItemData( data )
			end
		end
	end

	if receivers != false then
		if receivers or self:GetOwner() then
			--netstream.Start( receivers or self:GetOwner(), "DayZInv_net.containerItem.Data", self:GetUniqueID(), key, value )
		end
	end

	if !NoSave then
		--database.UpdateTable( { _data = self.Data }, nil, "items", "_uniqueID = "..self:GetUniqueID() )
	end	
end
function ITEM:Call( func, player, entity, ... ) 
	if type(self[func]) == "function" then
		local result = { self[func]( self, player, entity, ... ) }

		return unpack( result )
	end
end
function ITEM:Remove( NoSend, NoDeleteEntity, NoDelete, NoDestroyContainer ) 
	local container = inv.allItems[self.invID]

	for y = self.posY, self.posY + (self.Height - 1) do
		if container.inventory[y] then
			for x = self.posX, self.posX + (self.Width - 1) do
				local slot = container.inventory[y][x]

				if slot.item then
					if slot.item == self.uniqueID then
						container.inventory[y][x] = nil
					else
						return false
					end
				end
			end
		end
	end

	if SERVER then
		if !NoDeleteEntity then
			local ent = self:GetEntity()
			if IsValid( ent ) then
				ent:Remove()
			end
		end
		if !NoDestroyContainer then
			if self:IsContainer() then
				local linkedContainer = self:GetContainer()

				if linkedContainer then
					inv.allContainers[self.ownerInvID] = nil

					--database.Query("DELETE FROM dayzinv_items WHERE _invID = "..self.ownerInvID)
					--database.Query("DELETE FROM dayzinv_containers WHERE _invID = "..self.ownerInvID)

					// TO DO: Send a refresh signal to the client that we want to delete the specifed container and item(s)?
				end
			end
		end
		if !NoSend then
			local receiver = container.GetOwner and container:GetOwner()

			--netstream.Start( receiver, "DayZInv_net.containerItem.Rm", self.uniqueID, container:GetUniqueID() )
		end
		if !NoDelete then
			local item = inv.allItems[self.uniqueID]

			if item and item.OnRemove then
				item:OnRemove()
			end
			
			--database.Query("DELETE FROM dayzinv_items WHERE _uniqueID = "..self.uniqueID)
			inv.allItems[self.uniqueID] = nil
		end
	end
end

if SERVER then
	function ITEM:Send( receiver )
		local invID = self.invID or 0
		local x = self.posX or 0
		local y = self.posY or 0
		local id = self.uniqueID or 0
		local class = self.class or "tretiy_class))"
		local ownerInvID = self.ownerInvID or nil
		local data = self.Data and pon.encode( self.Data ) or "[]"
		netstream.Start( receiver, "DayZInv_net.container.Item", invID, x, y, id, class, ownerInvID, data )

		if !receiver or type( receiver ) == "table" then
			for k, v in pairs( receiver ) do
				self:Call( "OnSend", v )
			end
		elseif IsValid( receiver ) then
			self:Call( "OnSend", receiver )
		end
	end
	function ITEM:Spawn( pos, ang ) 
		if inv.allItems[self:GetUniqueID()] then
			local entity = ents.Create("dayzinv_item")
			entity:SetPos( pos )
			entity:SetAngles( ang or Angle() )
			entity:SetItem(self:GetUniqueID())
			return entity
		end
	end
	function ITEM:Transfer( inventoryID, x, y, player, NoSend ) 
		if !inventoryID then
			return false, "Attempt to transfer item: No inventoryID specifed."
		end

		if inventoryID == self.invID then
			return false, "Attempt to transfer item: Same inventoryID specifed."
		end

		local containerTo = inv.allContainers[inventoryID]
		local containerFrom = inv.allContainers[self.invID]

		if hook.Run( "CanItemTransfer", self, containerFrom, containerTo ) == false then
			return false, "Attempt to transfer item: Not allowed."
		end

		if containerFrom and !IsValid( player ) then
			player = containerFrom.GetOwner and containerFrom:GetOwner()
		end

		if containerFrom then
			if inventoryID and containerTo then
				if !x and !y then
					x, y = containerTo:FindEmptySlot( self.Width, self.Height )
				end
				if !x or !y then
					return false, "Attempt to transfer item: No space found."
				end

				local prevID = self.invID
				local result, err = containerTo:AddItem( self.uniqueID, nil, nil, x, y, NoSend )

				if result then
					containerFrom:RemoveItemByID( self.uniqueID, false, true )
					self.invID = inventoryID

					return true
				else
					return false, err
				end
			else
				return false, "Attempt to transfer item: Unforseen consequences."
			end
		else
			return false, "Attempt to transfer item: Invalid item's inventory."
		end
	end
	function ITEM:GetEntity() 
		for k, v in pairs( ents.FindByClass("dayzinv_item") ) do
			if v.ItemID == self:GetUniqueID() then
				return v
			end
		end
	end
end

invmeta.item = ITEM