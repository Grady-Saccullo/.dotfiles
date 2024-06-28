{ nixpkgs }:
let
	makeSystemConfig = { platform, arch, type, user }:
		let 
			# Technically could make this dynamic by reading dirs but too much effort right now
			allowed-platforms = [ "darwin" "generic-linux" "nixos" ];
			valid-platform = builtins.elem platform allowed-platforms;
			allowed-aarchs = [ "aarch64" ];
			valid-aarch = builtins.elem arch allowed-aarchs;
		in 
			if !valid-platform then 
				throw "Invalid platform: ${platform}. Allowed values are: ${builtins.concatStringsSep ", " allowed-platforms}."
			else if !valid-aarch then
				throw "Invalid architecture: ${arch}. Allowed values are: ${builtins.concatStringsSep ", " allowed-aarchs}."
			else
		{
			platform = platform;
			architecture = arch;
			type = type;
			user = user;
		};

	systemFromConfig = cfg: let
		p = if cfg.platform == "darwin" then "darwin" else "linux";
	in
		"${cfg.architecture}-${p}";

	hashSystemConfig = cfg: "${cfg.platform}-${cfg.architecture}-${cfg.type}-${cfg.user}";

	genSystemConfig = systems: make: nixpkgs.lib.genAttrs (map (s: s.type) systems) (type:
		let 
			cfg = builtins.elemAt (
				# builtins.filter (c: hashSystemConfig c == hashSystemConfig config)
				builtins.filter (c: c.type == type)
				systems) 0;
		in
		  make cfg
	);
in {
	inherit makeSystemConfig systemFromConfig hashSystemConfig genSystemConfig;
}
