# Material Shell

A [Quickshell](https://quickshell.org) sidebar with a clock, battery level,
quick actions, media controls, and notifications. Colors follow
[Matugen](https://github.com/InioX/matugen).

This needs a Wayland compositor with layer-shell support. Quickshell is included
in the Nix package. Stop your existing notification daemon before starting it.

## Getting started

From a local checkout:

```sh
nix build
./result/bin/material-shell
```

The sidebar starts closed. In another terminal, toggle it with:

```sh
./result/bin/material-shell ipc call sidebar toggle
```

Add that command to a keybinding to open and close the sidebar. Use
`./result/bin/material-shell kill` to quit. If you're using my nix-config, stop
the existing shell with `systemctl --user stop rice-shell.service`; start it
again with `systemctl --user start rice-shell.service` after quitting this one.

## Colors and actions

Colors are read from `~/.cache/quickshell/colors.json`, or
`$XDG_CACHE_HOME/quickshell/colors.json` if set. Changes apply automatically.
The file contains six `#RRGGBB` color strings: `rawBg`, `fg`, `warm`, `fresh`, `accent`,
and `second`. The Matugen template in my
[nix-config](https://github.com/Soliprem/nix-config/blob/main/hjem/templates/quickshell-colors.json)
writes this format.

Quick actions are still set up for my desktop, including scripts from
nix-config. Change them in [qml/shell.qml](qml/shell.qml). The programs they
launch need to be installed separately. Each action stores its command as an
argument array, for example `command: ["foot", "btop"]`; arguments containing
spaces stay intact.

## Development

For live reload while editing QML:

```sh
quickshell --path ./qml
```
From inside the devshell.

`quickshell --path ./qml ipc call sidebar toggle` to open it,
or `quickshell --path ./qml kill` to quit.

Run `nix flake check` to build the package and run the QML checks for palette
validation, action layouts, DND, and media source selection.

## Credits

Most of the original sidebar code comes from
[Ren (@lorediggia)](https://github.com/lorediggia)'s
[Quantum](https://github.com/lorediggia/quantum), adapted here for NixOS and
Matugen. Thanks for sharing it!

Licensed under GPL-3.0; see [LICENSE](LICENSE).
