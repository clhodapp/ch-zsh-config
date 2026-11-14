# SPDX-License-Identifier: MIT
{ ... }:
{
  inputs,
  lib,
  ...
}:
{

  imports = [ inputs.flake-parts.flakeModules.partitions ];

  debug = false;
  caisson.modules.homeManager.exported = modules: { inherit (modules) zsh; };

  # The checks of ch-zsh-config, with the pins of tests/dependencies
  # that only the checks need (configs/flake/checks). The caisson top
  # gathers the checks of every configuration declared inside it into
  # its `checks` output. This selector passes the configuration up to
  # nothing, so a flake that reads the exports of ch-zsh-config
  # evaluates neither the configuration nor its pins.
  caisson.flake-parts.configurations.checks = lib.caisson.flake-parts.mkConfiguration {
    inherit (lib.caisson.pins.flake-compat ../../../tests/dependencies) dependencies;
  };
  caisson.flake-parts.exported = _: { };

  partitionedAttrs.formatter = "formatter";

  partitions.formatter = {
    extraInputs = (lib.caisson.pins.flake-compat ../../../tests/dependencies).dependencies;
    module =
      { inputs, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem.treefmt.programs.nixfmt.enable = true;
      };
  };

}
