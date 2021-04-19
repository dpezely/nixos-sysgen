sysgen.sh: System Generation for NixOS
======================================

Deploy NixOS configurations for multiple laptops/workstations, with
[Home-Manager](https://github.com/nix-community/home-manager)

This accommodates separation for home use and work machines.

For both system-wide and each user's home directory, deployments are
performed potentially in a progression of *minimal*, *nominal* and
*optimal*.

The rationale is to immediately deploy bare necessities sufficient only for
booting and local trouble-shooting.

Then *when* things break due to future incompatibles, you at least can work
from inside the running operating system.

## work-in-progress

This is a work-in-progress, so please see the
[branch](https://github.com/dpezely/nixos-sysgen/tree/nixos-20.09-with-home-manager)
for anything potentially interesting.

## Current Status

TODO:

- [ ] Forking an existing printer driver needs more work
- [ ] Home-Manager has yet to be configured for dot files
  + Currently only includes full config for a web browser
- [ ] Need examples of working with Rust tool-chain that remains current with upstream
