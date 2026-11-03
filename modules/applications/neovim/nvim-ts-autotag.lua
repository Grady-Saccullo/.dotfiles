-- [START] nvim-ts-autotag.lua --
-- Core linkedEditingRange (nvim-lspconfig.lua) already renames the closing tag.
require("nvim-ts-autotag").setup({ opts = { enable_rename = false } })
-- [END] nvim-ts-autotag.lua --
