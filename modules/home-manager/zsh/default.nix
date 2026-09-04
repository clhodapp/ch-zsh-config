# SPDX-License-Identifier: MIT
{ ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ch-zsh-config.zsh;
  ghostelIntegrationEnabled = cfg.enableGhostelIntegration;

  # PROMPT uses $(command) expansions for prompt_subst. Home Manager now escapes
  # backslashes in localVariables, so assign PROMPT here in single quotes instead.
  # Trailing space after `$' is required for ghostel: OSC 133 mark B (input
  # boundary) is appended to PROMPT, so without a literal space the cursor sits
  # flush against `$' (`$ls' instead of `$ ls'). `prompt_sp' alone is not enough.
  promptInitContent = ''
    PROMPT='
    %n@%m$(direnv_dir)
    %~ $ '
  '';

  baseInitContent = ''
    setopt auto_continue
    setopt auto_pushd
    setopt extended_glob
    setopt inc_append_history
    setopt interactive_comments
    setopt local_loops
    unsetopt no_match
    setopt print_exit_value
    setopt rc_quotes
    setopt prompt_cr
    setopt prompt_sp
    setopt prompt_subst
    setopt histignorespace
    unsetopt beep
    unsetopt notify

    export function direnv_dir() {
      if [[ -n "$DIRENV_DIR" ]]; then
        echo " (direnv: $DIRENV_DIR)"
      fi
    }

    # Nix installable refs contain `#` (`.#checks.foo`, `nixpkgs#qemu`). With extended_glob,
    # `#` is glob syntax; no_match errors on zero matches. NO_NOMATCH leaves the token
    # literal when nothing matches (bash-like) so unquoted refs work under sudo too.
  '';

  ghostelInitContent = ''
    update_emacs_env() {
      ghostel_cmd "ch/ghostel-send-buffer-env"
      local cmd
      read -r -s cmd
      eval "$cmd"
    }
  '';

  defaultInitContent =
    baseInitContent
    + lib.optionalString ghostelIntegrationEnabled ghostelInitContent
    + promptInitContent
    + cfg.extraInitContent;
in
{
  options.ch-zsh-config.zsh = {
    enable = lib.mkEnableOption "shared zsh configuration";

    enableDirenv = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable direnv integration for zsh sessions.";
    };

    enableGhostelIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Shell helpers for ghostel, the terminal emulator that runs
        inside Emacs: `update_emacs_env` pulls the live Emacs
        environment into the shell.

        Off by default because it is useful only when Emacs is
        configured to run ghostel. This module used to detect that by
        reading the Emacs module's options, which worked while both
        lived in one flake; now that they do not, asking is the honest
        alternative to guessing.
      '';
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages to install alongside zsh.";
    };

    extraInitContent = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional zsh init content appended after module defaults.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.zsh-completions ] ++ cfg.extraPackages;

    programs.direnv = {
      enable = lib.mkDefault cfg.enableDirenv;
      silent = lib.mkDefault true;
    };

    programs.zsh = {
      enable = lib.mkDefault true;
      autocd = lib.mkDefault true;
      # Explicit keymap: zsh otherwise sniffs $EDITOR for the substring "vi",
      # and EDITOR is a raw store path whose hash can (and did) contain it.
      defaultKeymap = lib.mkDefault "emacs";
      dotDir = lib.mkDefault "${config.xdg.configHome}/zsh";
      history = {
        size = lib.mkDefault 100000;
        save = lib.mkDefault 10000;
        path = lib.mkDefault "${config.xdg.dataHome}/zsh/.history";
        ignoreDups = lib.mkDefault true;
      };
      localVariables = {
        RPS1 = "";
        TIMEFMT = "\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P";
      };
      initContent = lib.mkOrder 1000 defaultInitContent;
    };
  };
}
