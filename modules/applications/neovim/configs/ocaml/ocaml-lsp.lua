vim.filetype.add({ extension = { mli = "ocamlinterface", mll = "ocamllex", mly = "menhir" } })
-- reason is dropped from the default list: no grammar or ftplugin ships for it.
addLspServer("ocamllsp", { filetypes = { "ocaml", "ocamlinterface", "ocamllex", "menhir", "dune" } })
