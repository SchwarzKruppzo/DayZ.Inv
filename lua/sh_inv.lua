inv = {}
inv.allItems = {}
inv.allContainers = {}

inv.baseItems = {}
inv.baseContainers = {}
inv.classItems = {}
inv.classContainers = {}

function inv.RegisterItemClass( classname, base, isBase, path, isCalledLocal ) end
function inv.RegisterContainerClass( classname, base, isBase, path, isCalledLocal ) end

function inv.DB_CreateItemObject( inventoryID, classname, data, x, y, callback ) end
function inv.DB_CreateContainerObject( owner, classname, callback ) end

function inv.LoadItemClasses( path, base, isBase ) end
function inv.LoadContainerClasses( path, base, isBase ) end
function inv.LoadFromDirectory( directory, type ) end

function inv.NewItemObject( uniqueID, classname ) end
function inv.NewContainerObject( uniqueID, classname ) end

function inv.DB_LoadContainerObject( uniqueID, classname, callback ) end
function inv.DB_LoadItemObject( uniqueID ) end

if CLIENT then
	netstream.Hook("DayZInv_net.container", function( inventoryTable, inventoryID, inventoryClass, inventoryOwnerID ) end)
	netstream.Hook("DayZInv_net.containerItem.Set", function( inventoryID, x, y, itemClassname, itemUniqueID, inventoryOwnerID, itemData ) end)
	netstream.Hook("DayZInv_net.containerItem.Rm", function( itemUniqueID, inventoryID ) end)
else
	function inv.SpawnItem( classname, pos, ang, data, callback ) end
end