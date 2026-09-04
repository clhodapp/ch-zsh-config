# SPDX-License-Identifier: MIT
{ ... }:
{
  inputs,
  lib,
  ...
}:
{

  debug = false;
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  caisson.configInfo.configName = "ch-zsh-config";
  caisson.modules.homeManager.exported = modules: { inherit (modules) zsh; };

  caisson.nixpkgs.pkgSets.pkgs.pkgFunction = import inputs.nixpkgs;

  partitionedAttrs.checks = "checks";
  partitionedAttrs.formatter = "formatter";

  partitions.formatter = {
    extraInputs = lib.caisson-core.partitionExtraInputs ../../../tests/dependencies;
    module =
      { inputs, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem.treefmt.programs.nixfmt.enable = true;
      };
  };

  partitions.checks = {
    extraInputs = lib.caisson-core.partitionExtraInputs ../../../tests/dependencies;
    module =
      { inputs, self, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem =
          { pkgs, ... }:
          let
            # Evaluate the module end to end and take the rendered
            # .zshrc out of the built configuration, so the checks below
            # read what a real activation would write.
            configuration = inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                self.modules.homeManager.zsh
                {
                  home.username = "tester";
                  home.homeDirectory = "/home/tester";
                  home.stateVersion = "25.05";
                  ch-zsh-config.zsh.enable = true;
                }
              ];
            };

            # Found by suffix rather than by a hardcoded key: the module
            # puts .zshrc under xdg.configHome, so the attribute name
            # moves with a consumer's XDG settings.
            zshrcFile =
              (lib.findSingle (f: lib.hasSuffix "/.zshrc" f.target) null null (
                lib.attrValues configuration.config.home.file
              )).source;
          in
          {
            checks = {
              # The module renders a .zshrc that zsh accepts. A syntax
              # error here would otherwise surface as a broken login
              # shell after activation, which is an awkward place to
              # find one.
              zshrc = pkgs.runCommand "zshrc-syntax" { nativeBuildInputs = [ pkgs.zsh ]; } ''
                rc=${zshrcFile}
                zsh -n "$rc"

                # Drop the prompt's trailing space and the cursor sits
                # flush against the `$` (`$ls` for `$ ls`), because
                # ghostel appends OSC 133 mark B to PROMPT.
                grep -q "%~ \$ '" "$rc"

                # Nix installable refs contain `#`, which extended_glob
                # treats as syntax; no_match would then error on zero
                # matches instead of passing the token through.
                grep -q 'unsetopt no_match' "$rc"

                touch $out
              '';
            };
            treefmt.programs.nixfmt.enable = true;
          };
      };
  };

}
