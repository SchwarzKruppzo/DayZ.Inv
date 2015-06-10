ITEM.Name = "Backpack"
ITEM.Width = 1
ITEM.Height = 2
ITEM.Model = "228.mdl"
ITEM.ContainerInfo = {
	Width = 3,
	Height = 5
}
ITEM.Data = {
	exampleVar = true
}
ITEM.action.Open = {
	Text = "Open",
	OnRun = function( itemObject, activator, itemEntity )
		// bla bla bla
	end
}

function ITEM:IsContainer()
	return true
end