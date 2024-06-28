{ nixpkgs }:
let
	mkSystemConfig = { system, configType, configName, user }: {
		system = system;
		configType = configType;
		configName = configName;
		user = user;
	};

	hashSystemConfig = cfg: "${cfg.system}-${cfg.configType}-${cfg.configName}-${cfg.user}";

	configShortName = cfg: "${cfg.configType}-${cfg.configName}";

	genSystemConfig = systems: make: nixpkgs.lib.genAttrs (map (s: s.configType) systems) (configType:
		let 
			cfg = builtins.elemAt (
				# builtins.filter (c: hashSystemConfig c == hashSystemConfig config)
				builtins.filter (c: c.configType == configType)
				systems) 0;
		in
		  make cfg
	);
in {
	inherit mkSystemConfig hashSystemConfig genSystemConfig;
}
