# ch-zsh-config

A zsh configuration as a Home Manager module: shell options, history,
the prompt, and direnv, built from Nix.

It is deliberately small, and most of what it contains is there because
something once went wrong without it:

**The keymap is set explicitly.** zsh picks vi or emacs bindings by
sniffing `$EDITOR` for the substring `vi`, and `$EDITOR` here is a store
path whose hash can contain those two letters. It has.

**`no_match` is off.** Nix installable references contain `#`
(`nixpkgs#qemu`, `.#checks.foo`), and with `extended_glob` on, `#` is
glob syntax. With `no_match` set, a reference matching nothing is an
error rather than a literal argument, so unquoted refs fail.

**The prompt ends with a literal space.** ghostel, the terminal emulator
that runs inside Emacs, appends an OSC 133 mark B to `PROMPT`. Drop the
space and the cursor sits flush against the `$`, rendering `$ls` where
`$ ls` belongs. `prompt_sp` alone does not fix it.

History is kept large (100,000 entries) under the XDG data directory,
with duplicates dropped and space-prefixed commands excluded.

## Use it

```nix
{
  inputs.ch-zsh-config.url = "github:clhodapp/ch-zsh-config";

  # in a Home Manager configuration:
  #   ch-zsh-config.zsh.enable = true;
}
```

Set `enableGhostelIntegration` if you run ghostel; it adds
`update_emacs_env`, which pulls the live Emacs environment into the
shell. It defaults off because it is useful only alongside an Emacs
configured to run ghostel, and this module cannot tell whether you have
one.

## Development

`nix flake check` evaluates the module into a Home Manager
configuration, takes the rendered `.zshrc` out of it, and checks that
zsh parses it. A syntax error would otherwise surface as a broken login
shell after activation, which is an awkward place to find one. The
prompt's trailing space and the `no_match` setting are asserted too,
since both are easy to lose in a refactor and neither fails loudly.

`nix fmt` formats.

## License

MIT, see [`LICENSE`](LICENSE).
