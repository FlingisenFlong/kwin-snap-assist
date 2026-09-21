# Snap Assist for KWin

A KWin script for Plasma 6 that mimics Windows' "Snap Assist": when you
snap a window to a screen half or quarter (by dragging it to a screen edge
or with `Meta+Arrow`), any leftover empty space shows a small popup listing
your other open windows. Click one to snap it into that space; if more
empty space remains, the popup reappears for the next slot.

## Requirements

- KDE Plasma 6 / KWin 6 (uses the `declarativescript` KWin scripting API
  and the KWin 6 tiling API, so it will not work on Plasma 5).
- The window you're filling space for must be snapped via KWin's own
  quick tiling (edge drag or `Meta+Arrow`), not just moved/resized by hand.

## What it does and doesn't do

- Shows each candidate window's icon and title, not a live thumbnail
  preview - KWin scripts don't have access to the compositor's live
  window-thumbnail rendering the way effects do, only the plain
  window/icon metadata.
- Only offers windows on the current virtual desktop, skipping panels,
  docks, and the desktop window itself.
- Works with any tiling layout KWin considers "the tile tree" for a
  screen, which includes the default quick-tile halves/quarters and any
  custom layout you've set up under System Settings > Window Management
  > Window Tiling.

## Install

From this folder:

```sh
kpackagetool6 --type KWin/Script -i snap-assist
```

(Use `-u` instead of `-i` to reinstall after making changes to the
script.)

Then enable it:

```sh
kwriteconfig6 --file kwinrc --group Plugins --key snap-assistEnabled true
qdbus org.kde.KWin /KWin reconfigure
```

Or enable it via **System Settings > Window Management > KWin Scripts**
and search for "Snap Assist".

## Uninstall

```sh
kpackagetool6 --type KWin/Script -r snap-assist
```

## Tuning

There's no settings UI yet. Two constants near the top of
`contents/ui/main.qml` are easy to hand-edit and take effect after a
reinstall + `qdbus org.kde.KWin /KWin reconfigure`:

- `autoHideMs` - how long the popup stays up before auto-dismissing
  (default 7000ms).
- `maxCandidates` - how many windows to offer at once (default 8).

## Troubleshooting

Run `journalctl --user -f -u plasma-kwin_wayland` (or `_x11`) while
snapping a window to see `console.log`/error output from the script if
it's not behaving as expected.
