local lfs = require('lfs')

M = {}

--- @param dir string
--- @return boolean
M.check_dir_exists  = function(dir)
	return lfs.attributes(dir, 'mode') == 'directory'
end


--- @param src string
--- @param dest string
--- @return nil
M.symlink = function(src, dest)
	print('Symlinking ' .. src .. '  -->  ' .. dest)
	local cmd = string.format('ln -sfn %s %s', src, dest)
	os.execute(cmd)
end

return M
