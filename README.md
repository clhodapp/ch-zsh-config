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

Beyond `enable`, the module has `enableDirenv` (on by default),
`extraPackages` for packages to install alongside zsh, and
`extraInitContent` for init lines appended after the module's own.
Everything it sets is a default, so a consumer's own `programs.zsh`
settings win.

## Development

`nix flake check` evaluates the module into a Home Manager
configuration, takes the rendered `.zshrc` out of it, and checks that
zsh parses it. A syntax error would otherwise surface as a broken login
shell after activation, which is an awkward place to find one. The
prompt's trailing space and the `no_match` setting are asserted too,
since both are easy to lose in a refactor and neither fails loudly.

`nix fmt` formats.

In CI the same `nix flake check` runs with the Nix store cached between
runs. A pull request that leaves `.github/` alone is checked by `main`'s
copy of the workflow, in `main`'s context once its own check completes,
and adds its build to the shared cache; one that changes the pipeline is
checked by its own copy, under a cache only it can see. The comments at
the top of the two workflow files say why that split is what makes the
cache safe to write from a pull request.

## Binary cache

What `main` builds is pushed to the `clhodapp` cachix cache, signed with
its key. That cache skips paths its upstreams already hold, so using it
means using them too:

| Substituter | Public key |
|---|---|
| `https://clhodapp.cachix.org` | `clhodapp.cachix.org-1:EW/0conxH0OQyo0o4ub/grdkFspholmQMSnQyj0vrZI=` |
| `https://nix-community.cachix.org` | `nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=` |
| `https://numtide.cachix.org` | `numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=` |

Add all three to `extra-substituters` and `extra-trusted-public-keys`.

## License

MIT, see [`LICENSE`](LICENSE).
