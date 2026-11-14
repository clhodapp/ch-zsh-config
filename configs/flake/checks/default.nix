# SPDX-License-Identifier: MIT
#
# The checks of ch-zsh-config: a flake-parts configuration declared
# inside the flake-parts caisson top (configs/flake/ch-zsh-config),
# whose dependencies are those of the caisson top with the pins of
# tests/dependencies beside them. The caisson top gathers the checks
# declared here into its `checks` output. A flake that lists
# ch-zsh-config as an input reads nothing of this configuration, so it
# locks none of the pins of tests/dependencies.
{ ... }:
{ inputs, lib, ... }:
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
          lib.caisson.modules.homeManager.zsh
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
      # Duplicated in the formatter partition of
      # configs/flake/ch-zsh-config: the partition and this
      # configuration are separate evaluations.
      treefmt.programs.nixfmt.enable = true;

      caisson.checks = {
        treefmt = {
          category = "format";
          description = "the Nix files are formatted with nixfmt";
        };
        # A syntax error here would otherwise surface as a broken login
        # shell after activation, which is an awkward place to find one.
        zshrc = {
          derivation = pkgs.runCommand "zshrc-syntax" { nativeBuildInputs = [ pkgs.zsh ]; } ''
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
          category = "build";
          description = "the zsh module renders a .zshrc that zsh accepts, with the prompt and globbing settings it is written to have";
        };
      };
    };
}
