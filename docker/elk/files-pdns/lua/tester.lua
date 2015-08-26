options = { "redis-servers" }

function file_exists( file )
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end

function get_lines( file )
	if not file_exists(file) then return {} end
	lines = {}
	for line in io.lines(file) do
		local option, value = line:match("^(%S+)=(%S+)$")
			assert(option, "empty value in line: " .. line)
			lines[option] = value
	end
	return lines
end

function get_options()
	local file = "/etc/powerdns/lua-options.conf"
	lines = get_lines(file)

	-- conf file check
	for k,opt in ipairs(options) do
		assert(lines[opt], opt .. " missing from config file")
	end

	-- replace the comma separated value strings with an array
	for k,v in pairs(lines) do
		arr = {}
		for i in string.gmatch(v, "[^,]+") do
			table.insert(arr,i)
		end
		lines[k] = arr
	end
	return lines
end
