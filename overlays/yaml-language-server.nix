final: prev: {
  yaml-language-server = prev.yaml-language-server.overrideAttrs (oldAttrs: {
    version = "1.20.0-main";

    src = prev.fetchFromGitHub {
      owner = "redhat-developer";
      repo = "yaml-language-server";
      rev = "main";
      hash = "sha256-ICWoZtNFj20Cv7B7r5FqP/EC/kP7eXLk5seJ1y0vy5E=";
    };

    # Add environment variables to handle certificates and set up node environment
    configurePhase = ''
      runHook preConfigure

      export HOME=$(mktemp -d)
      export NODE_TLS_REJECT_UNAUTHORIZED=0
      export SSL_CERT_FILE=${prev.cacert}/etc/ssl/certs/ca-bundle.crt
      export npm_config_ca=${prev.cacert}/etc/ssl/certs/ca-bundle.crt
      export npm_config_cafile=${prev.cacert}/etc/ssl/certs/ca-bundle.crt

      yarn install --network-timeout 300000 --ignore-platform --ignore-scripts --no-progress --non-interactive
      patchShebangs node_modules

      runHook postConfigure
    '';

    buildPhase = ''
      export NODE_TLS_REJECT_UNAUTHORIZED=0
      export SSL_CERT_FILE=${prev.cacert}/etc/ssl/certs/ca-bundle.crt

      runHook preBuild
      yarn --network-timeout 300000 compile
      yarn --network-timeout 300000 build:libs
      runHook postBuild
    '';

    installPhase = ''
      export NODE_TLS_REJECT_UNAUTHORIZED=0
      export SSL_CERT_FILE=${prev.cacert}/etc/ssl/certs/ca-bundle.crt

      runHook preInstall
      yarn --network-timeout 300000 --production install
      mkdir -p $out/bin $out/lib/node_modules/yaml-language-server
      cp -r . $out/lib/node_modules/yaml-language-server
      ln -s $out/lib/node_modules/yaml-language-server/bin/yaml-language-server $out/bin/
      runHook postInstall
    '';

    # Remove the offlineCache to avoid conflicts
    offlineCache = null;
  });
}
