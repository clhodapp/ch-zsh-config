# SPDX-License-Identifier: MIT
{ lib }:
{
  zsh = lib.caisson-core.mkModule "homeManager" ./zsh;
}
