ITEM.Name = "Example Item"
ITEM.Width = 1
ITEM.Height = 1
ITEM.Model = "models/props_junk/popcan01a.mdl"
ITEM.Data = {
	exampleVar = true
}
ITEM.actions.Example = {
	Text = "Example Action",
	OnRun = function( itemObject, activator, itemEntity )
		print( "Object: "..itemObject )
		print( "Activator: "..activator )
		print( "Entity: "..itemEntity )
	end
}