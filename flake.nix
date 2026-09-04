# SPDX-License-Identifier: MIT
{

  description = "A zsh configuration, as a Home Manager module";

  inputs = {
    caisson.url = "github:nix-caisson/caisson";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ caisson, ... }:
    let
      lib = caisson.lib.caisson-core.mkLib {
        inherit inputs;

        projects = {
          inherit caisson;
        };

        modules = lib: {
          homeManager = import ./modules/home-manager {
            inherit lib;
          };
        };
      };
    in
    lib.caisson.mkFlake {
      name = "ch-zsh-config";
      configModule = lib.caisson.mkFlakeModule ./configs/flake-parts/default;
    };

}
