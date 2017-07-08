local debug = false

string.trim = function(str)
	if(debug) then display("DEBUG trim(".. str .. ")") end

	if(not str) then 
		if(debug) then display("DEBUG trim returns nil") end

		return nil
	end

        -- return string.gsub(str,"%s$","")
  	return str:match'^()%s*$' and '' or str:match'^%s*(.*%S)'
end

function string:split(sep)

	if(not sep) then return nil end

        local sep, fields = sep or ":", {}
        local pattern = string.format("([^%s]+)", sep)
        self:gsub(pattern, function(c) fields[#fields+1] = c end)
        return fields
end
