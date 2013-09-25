local luaqub, Compile = {}, {}

local function Trim( sInput )
	local x = sInput:match( "^[%s]*(.-)[%s]*$" )
	return x
end

local function ParseString( sInput )
	local tReturn = {}
	for sMatch in sInput:gmatch( "[^,]+" ) do
		table.insert( tReturn, Trim(sMatch) )
	end
	return tReturn
end

local function ParseTable( tInput )
	local tReturn = {}
	for Key, Value in pairs( tInput ) do
		if tonumber( Key ) then
			table.insert( tReturn, Trim(Value) )
		else
			table.insert( tReturn, ("%s `%s`"):format(Trim(Key), Trim(Value)) )
		end
	end
	return tReturn
end

local function ParseJoins( sInput, Object )
	if #(Object._join) <= 0 then
		return sInput
	end
	for Key, tValue in pairs( Object._join ) do
		sInput = sInput.."\n"..tValue.condition.." "..tValue.tbl.."\n\tON "..tValue.on
	end
	return sInput
end

local function ParseOrder( sInput, Object )
	if #(Object._order) <= 0 then
		return sInput
	end
	for Key, tValue in pairs( Object._order ) do
		sInput = sInput.."\nORDER BY "..tValue.col.." "..tValue.dir
	end
	return sInput
end

function Compile.SELECT( Object )
	local sReturn, colNames, tbls = "SELECT ", table.concat( Object._select, ",\n\t" ), table.concat( Object._from, ",\n\t" )
	sReturn = sReturn..colNames
	if #(Object._from) > 0 then
		sReturn = sReturn.."\nFROM "..tbls
	end
	sReturn = ParseJoins( sReturn, Object )
	if #(Object._where) > 0 then
		sReturn = sReturn.."\nWHERE "..table.concat( Object._where, "\n\tAND " )
	end
	sReturn = ParseOrder( sReturn, Object )
	if Object._limit > 0 then
		sReturn = sReturn.."\nLIMIT "..tostring( Object._limit )
	end
	if Object._offset > 0 then
		sReturn = sReturn.."\nOFFSET "..tostring( Object._offset )
	end
	return sReturn
end

luaqub.__index = luaqub

function luaqub:__tostring()
	return Compile[self._flag:upper()]( self )
end

function luaqub:select( cols )
	if not cols then
		error( "Argument to select function expected" )
		return false
	end
	if type( cols ) == "string" then
		if Trim( cols ) == "*" then
			self._select = { '*' }
		else
			self._select, cols = ParseString( cols ), nil
		end
	elseif type( cols ) == "table" then
		self._select, cols = ParseTable( cols ), nil
	end
	self._flag = "select"
	return self
end

function luaqub:from( tbls )
	if not tbls then
		error( "Argument to from function expected" )
		return false
	end
	if type( tbls ) == "string" then
		self._from, tbls = ParseString( tbls ), nil
	elseif type( tbls ) == "table" then
		self._from, tbls = ParseTable( tbls ), nil
	end
	return self
end

function luaqub:where( clauses )
	if not clauses then
		error( "Matching clauses to where function expected" )
		return false
	end
	if type( clauses ) == "string" then
		table.insert( self._where, clauses )
		clauses = nil
	elseif type( clauses ) == "table" then
		for Key, Value in pairs( clauses ) do
			if tonumber( Key ) then
				table.insert( self._where, Value )
			else
				table.insert( self._where, ("%s = %s"):format(Trim(Key), Trim(Value)) )
			end
		end
		clauses = nil
	end
	return self
end

function luaqub:join( tbl, clause, cond )
	if not cond then
		cond = "JOIN"
	else
		cond = Trim( cond:upper() ).." JOIN"
	end
	if type( clause ) == "string" then
		clause = Trim( clause )
	end
	table.insert( self._join, { condition = cond, tbl = tbl, on = clause } )
	return self
end

function luaqub:limit( lim, off )
	if not tonumber( lim ) then
		error( "Limit argument should be a number" )
		return false
	end
	if off then
		if not tonumber( off ) then
			error( "Offset argument should be a number" )
			return false
		end
		self._offset = tonumber( off )
	end
	self._limit = tonumber( lim )
	return self
end

function luaqub:order( col, dir )
	if not col then
		error( "Blank call of order function is not allowed" )
		return false
	end
	if type( col ) == "string" then
		dir = ( dir and dir:upper() ) or "ASC"
		table.insert( self._order, { col = col, dir = dir } )
	elseif type( col ) == "table" then
		for Key, Value in pairs( col ) do
			if tonumber( Key ) then
				table.insert( self._order, { col = Value, dir = "ASC" } )
			else
				table.insert( self._order, { col = Key, dir = Value:upper() } )
			end
		end
	end
	return self
end

function luaqub.new()
	local tNew = {
		_select = {},
		_from = {},
		_where = {},
		_join = {},
		_order = {},
		_limit = 0,
		_offset = 0,
		_flag = '',
	}
	setmetatable( tNew, luaqub )
	return tNew
end

return luaqub