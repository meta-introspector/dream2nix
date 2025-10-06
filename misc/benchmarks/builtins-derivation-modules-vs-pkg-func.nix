{dream2nixSource ? ../..}: let
  dream2nix = import dream2nixSource;
  nixpkgs = import dream2nix.inputs.nixpkgs {};
  inherit (nixpkgs) lib;

  _callModule = module:
    nixpkgs.lib.evalModules {
      specialArgs.dream2nix = dream2nix;
      specialArgs.packageSets.nixpkgs = nixpkgs;
      modules = [module dream2nix.modules.dream2nix.core];
    };

  # like callPackage for modules
  callModule = module: (_callModule module).config.public;

  numPkgs = lib.toInt (builtins.getEnv "NUM_PKGS");
  numVars = lib.toInt (builtins.getEnv "NUM_VARS");

  pkg-funcs = lib.genAttrs (map toString (lib.range 0 numPkgs)) (
    num:
      derivation (
        {
          name = "hello-${num}";
          version = "2.12.1";
          system = "x86_64-linux";
          builder = "/bin/sh";
          args = ["sh" "-c" "echo hello-${num} > $out"];
        }
        # generate env variables
        // (
          lib.genAttrs (map toString (lib.range 0 numVars)) (
            num: "value-${num}"
          )
        )
      )
  );

  modules = lib.genAttrs (map toString (lib.range 0 numPkgs)) (
    num:
      callModule {
        imports = [
          dream2nix.modules.dream2nix.builtins-derivation
        ];
        name = "hello-${num}";
        version = "2.12.1";
        builtins-derivation = {
          system = "x86_64-linux";
          builder = "/bin/sh";
          args = ["sh" "-c" "echo hello-${num} > $out"];
        };
        # generate env variables
        env = lib.genAttrs (map toString (lib.range 0 numVars)) (
          num: "value-${num}"
        );
      }
  );
in {
  inherit
    pkg-funcs
    modules
    ;
}
