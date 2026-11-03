# Sleex on Debian

<h3>Attention : This is for fun, there is no guaranteed it will work on your device, PLEASE USE AT YOUR OWN RISK</h3>

<img alt="image" src="https://github.com/Moxier/sleex-debian/blob/main/cover.png?raw=true" />

**English** | [ภาษาไทย](README_TH.md)

Installer for the [Sleex](https://github.com/AxOS-project/Sleex) desktop (AxOS, Hyprland + Quickshell) on Debian-based distros.

> [!NOTE]
> Tested on real hardware: **PikaOS 4** (Debian sid, Hyprland 0.57), installed side by side with PikaOS's own desktop without removing anything.
>
> Plain Debian 13 / testing / sid has not been tested yet.

## Requirements

- amd64 (x86_64)
- Hyprland **≥ 0.55** (Sleex uses the Lua config format)
- Quickshell and Qt ≥ 6.8

| Distro | Status |
|---|---|
| PikaOS 4 | ✅ Tested |
| Debian 13 (trixie) | ⚠️ Untested (`trixie-backports` is enabled automatically) |
| Debian testing / sid | ⚠️ Untested |
| Ubuntu / Mint | ❌ Repo Hyprland is older than 0.55 (the script stops early) |

## Usage

```bash
git clone https://github.com/Moxier/sleex-debian
cd sleex-debian
sudo ./install-sleex-debian.sh 2>&1 | tee install.log
```

Then log out and choose the **Sleex** session in your display manager.

If something goes wrong, attach `install.log` when you open an issue.

## Updating

The script always installs the latest Sleex from GitHub, so updating means running it again:

```bash
cd ~/sleex-debian && git pull
sudo ./install-sleex-debian.sh 2>&1 | tee install.log
```

- **Overwritten:** Sleex's own files in `/usr/share/sleex`, `/etc/sleex` and `/usr/bin/sleex`
- **Kept:** everything in your home, including `~/.config/sleex/custom/*.lua` (your own Hyprland settings, e.g. keyboard layout), wallpapers and colours
- Hyprland, Quickshell and other packages update through apt as usual

If upstream Sleex changes the code a patch targets, that patch may stop applying. The keyboard patch stops the script with an error; the others skip silently and only that feature stops working.

## Uninstalling

```bash
cd ~/sleex-debian
sudo ./uninstall-sleex-debian.sh
```

Log out of Sleex first. The installer keeps a record in `/var/lib/sleex-debian` of every file it wrote, the original of every file it replaced, and the packages it installed. The uninstaller uses that record to:

- remove the Sleex files and put the replaced originals back (e.g. `/etc/skel`, `/etc/xdg/mimeapps.list`)
- remove you from the `input` group if the installer added you
- mark the installed packages as no longer wanted and run `apt autoremove`, which only removes what nothing else needs. apt shows the list first — answer **no** to keep them all

Your home folder is left alone (`~/.config/sleex`, `~/.local/state/sleex`, the Sleex configs copied into `~/.config`). Delete those by hand if you want.

> [!IMPORTANT]
> Installed before the uninstaller existed (before November 3, 2026)? There is no record yet: run the current `install-sleex-debian.sh` once, then uninstall. The originals that first install replaced (`/etc/skel`, `/etc/xdg/mimeapps.list`) can't be restored, and packages from that first run aren't in the record.

## What the script does

1. Checks the Hyprland / Quickshell / Qt versions first and stops if they are too old
2. Installs the dependencies from the Arch PKGBUILD, mapped to Debian package names
   - Packages missing from your repos are skipped
   - **Packages that would remove something you already have are skipped** (e.g. on PikaOS, `power-profiles-daemon` conflicts with `tuned-ppd`)
   - Everything skipped is listed at the end
3. Builds from source: the Sleex QML plugins, `sleex-ui-kit`, `sleex-welcome-screen`, `hypnos`
4. Downloads what Arch gets from the AUR: matugen, Bibata cursor, adw-gtk3 theme, fonts (Material Symbols, Gabarito, Rubik, Readex Pro, JetBrains Mono Nerd), hyprshot, papirus-folders
5. Debian patches:
   - Reads the keyboard layout from `/etc/default/keyboard` instead of Arch's `/etc/vconsole.conf`
   - `qt_standard_project_setup(REQUIRES 6.9)` → 6.8 (only when Qt < 6.9)
   - polkit group `wheel` → `sudo`
   - A separate venv for `materialyoucolor` (no system-wide pip)
   - The power saver button uses `busctl` instead of `powerprofilesctl` when the system uses `tuned-ppd`
   - Runs `Hyprland` directly if `start-hyprland` is missing
   - Colour scripts are run with `bash` (Debian's `sh` is dash), so changing the Material Palette works
   - matugen gets `--source-color-index 0`, so shell colours follow the wallpaper (newer matugen refuses to pick a colour without a terminal)
   - Wallpaper picker rescans when its folder changes, and accepts `~` and spaces in the path
   - Settings › About shows the Sleex version (written to `/usr/share/sleex/VERSION`) and the distro buttons use the links from `/etc/os-release`
6. Copies the default config into the sudo user's home **without overwriting existing files**

## Troubleshooting

**Icons/theme missing in the file manager** — if `~/.config/qt6ct/qt6ct.conf` already existed (e.g. from PikaOS), the script leaves it alone, so Qt apps keep an icon theme Sleex may not find. Fix it with the commands below. This also changes your other desktop, since both share the file:

```bash
cp ~/.config/qt6ct/qt6ct.conf ~/.config/qt6ct/qt6ct.conf.bak
sed -i 's/^icon_theme=.*/icon_theme=Papirus-Dark/; s/^style=.*/style=kvantum/' ~/.config/qt6ct/qt6ct.conf
```

**Flatpak apps not in the launcher** — if you installed a Flatpak app while Sleex was running, log out and back in.

## Known limitations

- If the Sleex plugins use Qt 6.9-only APIs, they won't build on Debian 13 (testing/sid are fine)
- The Lua config API in Hyprland 0.55 (backports) may differ from the version AxOS targets
- `hypnos` may fail to build if Debian's Rust is too old → idle/auto-lock won't work (the script warns and continues)
- Not included: Howdy (face unlock), Mission Center, breeze-plus

## License

GPL-3.0, same as upstream Sleex.
