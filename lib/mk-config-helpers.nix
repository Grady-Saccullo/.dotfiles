{ nixpkgs }:
let
	makeSystemConfig = p: a: c: u: 
		let 
			# Technically could make this dynamic by reading dirs but too much effort right now
			allowed-platforms = [ "darwin" "generic-linux" "nixos" ];
			valid-platform = builtins.elem p allowed-platforms;
			allowed-aarchs = [ "aarch64" ];
			valid-aarch = builtins.elem a allowed-aarchs;
		in 
			if !valid-platform then 
				throw "Invalid platform: ${p}. Allowed values are: ${builtins.concatStringsSep ", " allowed-platforms}."
			else if !valid-aarch then
				throw "Invalid architecture: ${a}. Allowed values are: ${builtins.concatStringsSep ", " allowed-aarchs}."
			else
		{
			platform = p;
			architecture = a;
			type = p;
			user = u;
		};

	systemFromConfig = cfg: let
		p = if cfg.platform == "generic-linux" then "linux" else cfg.platform;
	in
		"${cfg.architecture}-${p}";

	hashSystemConfig = cfg: "${cfg.platform}-${cfg.architecture}-${cfg.type}-${cfg.user}";

	genSystemConfig = systems: make: nixpkgs.lib.genAttrs (map (s: s.type) systems) (config:
		let 
			cfg = builtins.elemAt (builtins.filter (c: hashSystemConfig c == hashSystemConfig config) systems) 0;
		in
		  make cfg
	);
in {
	inherit makeSystemConfig systemFromConfig hashSystemConfig genSystemConfig;
}
