local _R = debug.getregistry()

local ITEM = _R.Item or {}
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
function ITEM:GetOwner() end
function ITEM:GetData() end
function ITEM:SetData( key, value, receivers, NoSave, NoSetEntity ) end
function ITEM:Call( func, ... ) end
function ITEM:Remove() end

if SERVER then
	function ITEM:Spawn( pos, ang ) end
	function ITEM:Transfer( inventoryID, x, y, player, NoSend ) end
	function ITEM:GetEntity() end
end

_R.Item = ITEM