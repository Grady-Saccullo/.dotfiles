package.path = package.path .. ';../?.lua'

local lfs = require('lfs')
local shared = require('scripts.shared')

--- @param local_configs string
--- @param os_configs string
local function loop_configs(local_configs, os_configs)
	for dir in lfs.dir(local_configs) do
		if dir ~= '.' and dir ~= '..' then
			local src = local_configs .. '/' .. dir
			local dest = os_configs .. '/' .. dir
			shared.symlink(src, dest)
		end
	end
end

local function symlink_configs()
	local home = os.getenv('HOME')
	local os_configs = home .. '/.config-temp'

	print('About to sync confis to ' .. os_configs)
	print('Type "yes/(y)" to continue or anything else to exit')

	local response = io.read()

	if not response:upper():gmatch("^(Y|YES)$") then
		print('Exiting...')
		return
	end
	if not shared.check_dir_exists(os_configs) then
		lfs.mkdir(os_configs)
	end

	local local_configs = lfs.currentdir() .. '/../configs'

	loop_configs(local_configs, os_configs)
end

symlink_configs()
