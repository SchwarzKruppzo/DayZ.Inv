database = database or {}

// SETTINGS START
	database.module = "sqlite" // sqlite, tmysql4, mysqloo
	database.hostname = "localhost"
	database.username = "root"
	database.password = "password"
	database.database = "nutscript"
	database.port = 3306
// SETTINGS END

local function ThrowQueryFault( query, fault )
	MsgC( Color(255, 0, 0), "* "..query.."\n" )
	MsgC( Color(255, 0, 0), fault.."\n" )
end

local function ThrowConnectionFault( fault )
	MsgC( Color(255, 0, 0), "DayZ.Inv has failed to connect to the database.\n" )
	MsgC( Color(255, 0, 0), fault.."\n" )
end

local modules = {}

-- SQLite for local storage.
modules.sqlite = {
	query = function( query, callback )
		local data = sql.Query( query )
		local fault = sql.LastError()

		if data == false then
			ThrowQueryFault( query, fault )
		end

		if callback then
			local lastID = tonumber( sql.QueryValue("SELECT last_insert_rowid()") )

			callback( data, lastID )
		end
	end,
	escape = function( value )
		return sql.SQLStr( value, true )
	end,
	connect = function( callback )
		if callback then
			callback()
		end
	end
}

-- tmysql4 module for MySQL storage.
modules.tmysql4 = {
	query = function( query, callback )
		if database.object then
			database.object:Query( query, function( data, status, lastID )
				if status == QUERY_SUCCESS then
					if callback then
						callback( data, lastID )
					end
				else
					file.Write( "dayzinv_queryerror.txt", query )
					ThrowQueryFault( query, lastID )
				end
			end, 3 )
		end
	end,
	escape = function( value )
		return tmysql and tmysql.escape( value ) or sql.SQLStr( value, true )
	end,
	connect = function( callback )
		if !pcall( require, "tmysql4" ) then
			return ThrowConnectionFault( system.IsWindows() and "Server is missing VC++ redistributables!" or "Server is missing binaries for tmysql4!")
		end

		local hostname = database.hostname
		local username = database.username
		local password = database.password
		local database = database.database
		local port = database.port
		local object, fault = tmysql.initialize( hostname, username, password, database, port )

		if object then
			database.object = object
			database.Escape = modules.tmysql4.escape
			database.Query = modules.tmysql4.query

			if callback then
				callback()
			end
		else
			ThrowConnectionFault( fault )
		end	
	end
}

-- mysqloo for MySQL storage.
modules.mysqloo = {
	query = function( query, callback )
		if database.object then
			local object = database.object:query( query )

			if callback then
				function object:onSuccess( data )
					callback( data, self:lastInsert() )
				end
			end

			function object:onError( fault )
				ThrowQueryFault( query, fault )
			end

			object:start()
		end
	end,
	escape = function( value )
		local object = database.object

		if object then
			return object:escape( value )
		else
			return sql.SQLStr( value, true )
		end
	end,
	connect = function( callback )
		if !pcall(require, "mysqloo") then
			return ThrowConnectionFault( system.IsWindows() and "Server is missing VC++ redistributables!" or "Server is missing binaries for mysqloo!" )
		end

		local hostname = database.hostname
		local username = database.username
		local password = database.password
		local database = database.database
		local port = database.port
		local object = mysqloo.connect( hostname, username, password, database, port )

		function object:onConnected()
			database.object = self
			database.Escape = modules.mysqloo.escape
			database.Query = modules.mysqloo.query

			if callback then
				callback()
			end
		end

		function object:onConnectionFailed( fault )
			ThrowConnectionFault( fault )
		end

		object:connect()
	end
}

-- Add default values here.
database.Escape = modules.sqlite.escape
database.Query = modules.sqlite.query

function database.Connect( callback )
	local dbModule = modules[ database.module ]

	if dbModule then
		if !database.object then
			dbModule.connect( callback )
		end

		database.Escape = dbModule.escape
		database.Query = dbModule.query
	else
		ErrorNoHalt( "[DayZ.Inv] '" .. ( database.module or "nil" ) .. "' is not a valid data storage method!\n" )
	end
end

local MYSQL_CREATE_TABLES = [[
CREATE TABLE IF NOT EXISTS `dayzinv_containers` (
	`_uniqueID` int(11) unsigned NOT NULL AUTO_INCREMENT,
	`_steamID` varchar(100) DEFAULT NULL,
	`_class` varchar(60) NOT NULL,
	PRIMARY KEY (`_uniqueID`)
);

CREATE TABLE IF NOT EXISTS `dayzinv_items` (
	`_uniqueID` int(11) unsigned NOT NULL AUTO_INCREMENT,
	`_ownerInvID` int(11) unsigned DEFAULT NULL,
	`_invID` int(11) unsigned NOT NULL,
	`_class` varchar(60) NOT NULL,
	`_data` varchar(255) DEFAULT NULL,
	`_x` smallint(4) NOT NULL,
	`_y` smallint(4) NOT NULL,
	PRIMARY KEY (`_uniqueID`)
);
]]

local SQLITE_CREATE_TABLES = [[
CREATE TABLE IF NOT EXISTS `dayzinv_containers` (
	`_uniqueID` INTEGER PRIMARY KEY,
	`_steamID` TEXT,
	`_class` TEXT
);

CREATE TABLE IF NOT EXISTS `dayzinv_items` (
	`_uniqueID` INTEGER PRIMARY KEY,
	`_ownerInvID` INTEGER,
	`_invID` INTEGER,
	`_x` INTEGER,
	`_y` INTEGER,
	`_class` TEXT,
	`_data` TEXT
);
]]

local DROP_QUERY = [[
DROP TABLE IF EXISTS `dayg_containers`;
DROP TABLE IF EXISTS `dayg_items`;
]]

function database.WipeTables()
	local function callback()
		MsgC( Color(255, 0, 0), "[DayZ.Inv] ALL INVENTORY DATA HAS BEEN WIPED\n" )
	end
	
	if database.object then
		local queries = string.Explode( ";", DROP_QUERY )

		for i = 1, 4 do
			database.Query( queries[i], callback )
		end
	else
		database.Query( DROP_QUERY, callback )
	end

	database.LoadTables()
end

local resetCalled = 0
concommand.Add("dayzinv_recreatedb", function( client, cmd, arguments )
	-- this command can be run in RCON or SERVER CONSOLE
	if !IsValid( client ) then
		if resetCalled < RealTime() then
			resetCalled = RealTime() + 3

			MsgC( Color(255, 0, 0), "[DayZ.Inv] TO CONFIRM DATABASE RESET, RUN 'dayzinv_recreatedb' AGAIN in 3 SECONDS.\n" )
		else
			resetCalled = 0
			
			MsgC( Color(255, 0, 0), "[DayZ.Inv] DATABASE WIPE IN PROGRESS.\n" )
			
			hook.Run("OnWipeTables")
			database.WipeTables()
		end
	end
end)

function database.LoadTables()
	if database.object then
		-- This is needed to perform multiple queries since the string is only 1 big query.
		local queries = string.Explode( ";", MYSQL_CREATE_TABLES )

		for i = 1, 4 do
			database.Query( queries[i] )
		end
	else
		database.Query( SQLITE_CREATE_TABLES )
	end

	hook.Run("OnLoadTables")
end

function database.ConvertDataType( value )
	if type(value) == "string" then
		return "'"..database.Escape( value ).."'"
	elseif (type(value) == "table") then
		return "'"..database.Escape( util.TableToJSON(value) ).."'"
	end

	return value
end

function database.InsertTable( value, callback, dbTable )
	local query = "INSERT INTO "..("dayzinv_"..dbTable).." ("
	local keys = {}
	local values = {}

	for k, v in pairs( value ) do
		keys[#keys + 1] = k
		values[#keys] = k:find("steamID") and v or database.ConvertDataType(v)
	end

	query = query..table.concat( keys, ", " )..") VALUES ("..table.concat( values, ", " )..")"
	database.Query( query, callback )
end

function database.UpdateTable( value, callback, dbTable, condition )
	local query = "UPDATE "..("dayzinv_"..dbTable).." SET "
	local changes = {}

	for k, v in pairs(value) do
		changes[#changes + 1] = k.." = "..(k:find("steamID") and v or database.ConvertDataType(v))
	end

	query = query..table.concat( changes, ", " )..(condition and " WHERE "..condition or "")
	database.Query( query, callback )
end


database.Connect(function()
	-- Create the SQL tables if they do not exist.
	database.LoadTables()
	
	MsgC(Color(0, 255, 0), "DayZ.Inv has connected to the database.\n")
end)