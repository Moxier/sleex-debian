#!/usr/bin/env bash
# Install Sleex DE (AxOS, Hyprland + Quickshell) on Debian-based distros.
# Usage: sudo ./install-sleex-debian.sh
# Needs: amd64, Hyprland >= 0.55 (Lua config), Quickshell, Qt >= 6.8.
#   Debian 13 trixie -> takes Hyprland/Quickshell from trixie-backports (enabled automatically)
#   Debian testing / sid -> straight from the archive
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
BUILD=/var/tmp/sleex-build
GH=https://github.com
AXOS=$GH/AxOS-project
MATUGEN_VER=4.2.0
BIBATA_VER=2.0.7
ADWGTK_VER=6.5
NERD_VER=3.5.1
HYPRSHOT_VER=1.3.0
PAPIRUS_FOLDERS_VER=1.14.0

say()  { printf '\e[1;34m==>\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m!!\e[0m %s\n' "$*" >&2; }
die()  { printf '\e[1;31mxx\e[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run with sudo: sudo $0"
[[ $(dpkg --print-architecture) == amd64 ]] || die "Sleex supports amd64 (x86_64) only"
. /etc/os-release
[[ $ID == debian || " ${ID_LIKE:-} " == *" debian "* ]] || die "Not a Debian-based distro ($ID)"
MULTIARCH=$(dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null || echo x86_64-linux-gnu)

# --- 1. APT sources ---------------------------------------------------------
HYPR_TARGET=()
if [[ ${VERSION_CODENAME:-} == trixie ]]; then
    if ! grep -rqs 'trixie-backports' /etc/apt/sources.list /etc/apt/sources.list.d/; then
        say "Enabling trixie-backports"
        cat > /etc/apt/sources.list.d/trixie-backports.sources <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie-backports
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
    fi
    HYPR_TARGET=(-t trixie-backports)
fi
say "apt update"
apt-get update

have_pkg() { apt-cache show "$1" >/dev/null 2>&1; }
installed() { dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null | grep -qx installed; }
MISSING=() CONFLICT=()
# install what exists, remember what doesn't (names differ between Debian releases/derivatives).
# Skip any package whose install would remove something already there: derivatives ship their own
# desktop stack (PikaOS: otter-shell, pika-hyprland-*, tuned-ppd vs power-profiles-daemon).
apt_some() {
    local want=() ok=() p i=0
    for p in "$@"; do
        if ! have_pkg "$p"; then MISSING+=("$p")
        elif ! installed "$p"; then want+=("$p"); fi
    done
    ((${#want[@]})) || return 0
    # fast path: one simulation for the whole batch; only hunt per package if it would remove something
    if apt-get -s install --no-remove "${APT_EXTRA[@]}" "${want[@]}" >/dev/null 2>&1; then
        ok=("${want[@]}")
    else
        say "Some packages conflict with what's installed, checking one by one (a few minutes)..."
        for p in "${want[@]}"; do
            printf '\r  [%d/%d] %-40s' $((++i)) ${#want[@]} "$p"
            if apt-get -s install --no-remove "${APT_EXTRA[@]}" "$p" >/dev/null 2>&1; then ok+=("$p")
            else CONFLICT+=("$p"); fi
        done
        echo
        ((${#ok[@]})) || return 0
    fi
    # --no-remove: never let -y silently uninstall the user's packages to resolve a conflict
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-remove "${APT_EXTRA[@]}" "${ok[@]}" ||
        die "apt refused (it would have to remove installed packages, see above). Nothing was removed."
}

# --- 2. Version gates -------------------------------------------------------
cand() { apt-cache "${HYPR_TARGET[@]}" policy "$1" 2>/dev/null | awk '/Candidate:/{print $2}'; }
HV=$(cand hyprland)
[[ -n $HV && $HV != "(none)" ]] || die "No 'hyprland' package available"
dpkg --compare-versions "$HV" ge 0.55 || die "Hyprland $HV is too old; Sleex uses Lua config (needs >= 0.55)"
QSV=$(cand quickshell)
[[ -n $QSV && $QSV != "(none)" ]] || die "No 'quickshell' package available (Debian 13 backports / testing / sid have it)"
say "Hyprland $HV, Quickshell $QSV"

# --- 3. Packages (Arch PKGBUILD depends mapped to Debian names) -------------
say "Installing Hyprland stack"
APT_EXTRA=("${HYPR_TARGET[@]}")
apt_some hyprland quickshell xdg-desktop-portal-hyprland hyprlock hyprpicker hyprsunset \
    hyprland-qt-support hyprcursor-util
APT_EXTRA=()

say "Installing runtime dependencies"
apt_some \
    cava pavucontrol-qt wireplumber pipewire-pulse libdbusmenu-gtk3-4 playerctl pulseaudio-utils easyeffects \
    geoclue-2.0 brightnessctl ddcutil \
    axel bc coreutils cliphist curl rsync wget ripgrep jq xdg-user-dirs foot power-profiles-daemon \
    qt-style-kvantum qt6-style-kvantum inotify-tools lm-sensors qt5ct qt6ct sqlite3 dbus-bin libnotify-bin \
    eza fish fontconfig starship papirus-icon-theme breeze-icon-theme \
    fonts-jetbrains-mono fonts-materialdesignicons-webfont fonts-noto-color-emoji \
    wl-clipboard xdg-desktop-portal xdg-desktop-portal-gtk \
    bluedevil bluez gnome-keyring network-manager network-manager-gnome polkit-kde-agent-1 \
    pcmanfm-qt kwrite kdialog \
    python3 python-is-python3 python3-venv python3-pip python3-pil python3-numpy python3-opencv \
    python3-setproctitle sassc \
    grim slurp wf-recorder swappy ksnip tesseract-ocr tesseract-ocr-eng \
    upower wtype ydotool fprintd khal vdirsyncer \
    fuzzel translate-shell wlogout swww \
    qt6-wayland qt6-svg-plugins qt6-image-formats-plugins qt6-translations-l10n \
    qml6-module-qtquick qml6-module-qtquick-layouts qml6-module-qtquick-controls \
    qml6-module-qtquick-templates qml6-module-qtquick-window qml6-module-qtquick-shapes \
    qml6-module-qtquick-effects qml6-module-qtquick-dialogs qml6-module-qt-labs-platform \
    qml6-module-qt5compat-graphicaleffects qml6-module-qtmultimedia qml6-module-qtqml-models \
    qml6-module-qtqml-workerscript qml6-module-qtpositioning qml6-module-qtsensors \
    qml6-module-qtquick-virtualkeyboard

say "Installing build dependencies"
apt_some git build-essential cmake ninja-build pkg-config meson \
    qt6-base-dev qt6-declarative-dev qt6-tools-dev qt6-connectivity-dev qt6-wayland-dev \
    libsdbus-c++-dev libnm-dev libglib2.0-dev liblayershellqtinterface-dev \
    cargo libudev-dev libwayland-dev libxkbcommon-dev

QTV=$(pkg-config --modversion Qt6Core 2>/dev/null || echo 0)
dpkg --compare-versions "$QTV" ge 6.8 || die "Qt $QTV is too old (needs >= 6.8)"

# --- 4. Fetch sources -------------------------------------------------------
rm -rf "$BUILD"; mkdir -p "$BUILD"; cd "$BUILD"
for r in Sleex sleex-ui-kit sleex-welcome-screen sleex-artworks hypnos; do
    say "Cloning $r"; git clone -q --depth 1 "$AXOS/$r" "$r"
done
fetch() { curl -fL --retry 3 -o "$2" "$1"; }

# --- 5. Build & install Sleex QML plugins ----------------------------------
say "Building Sleex"
S=$BUILD/Sleex/src
# upstream asks for Qt 6.9 policies; Debian 13 ships 6.8
dpkg --compare-versions "$QTV" lt 6.9 &&
    sed -i 's/qt_standard_project_setup(REQUIRES 6.9)/qt_standard_project_setup(REQUIRES 6.8)/' \
        "$S/share/sleex/plugins/src/Sleex/CMakeLists.txt"
cmake -S "$S/share/sleex" -B "$BUILD/sleex-out" -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DDISTRIBUTOR=Debian -DINSTALL_QMLDIR="usr/lib/$MULTIARCH/qt6/qml"
cmake --build "$BUILD/sleex-out"
cmake --install "$BUILD/sleex-out" --prefix /

# Upstream takes the XKB layout from KEYMAP in /etc/vconsole.conf (Arch); on Debian that file
# is often absent or holds a console map path (PikaOS: /etc/pika-console.map) -> "invalid keyboard layout".
# Read Debian's /etc/default/keyboard instead (layout, variant, options e.g. us,th + grp:alt_shift_toggle).
G="$S/etc/sleex/hyprland/general.lua"
sed -i '1,/^end$/c\
local kb = { XKBLAYOUT = "us", XKBVARIANT = "", XKBOPTIONS = "" }\
local file = io.open("/etc/default/keyboard", "r")\
if file then\
    for line in file:lines() do\
        local k, v = line:match([[^%s*(XKB%u+)%s*=%s*"?([^"]*)"?%s*$]])\
        if k and kb[k] ~= nil and v ~= "" then kb[k] = v end\
    end\
    file:close()\
end\
local layout, variant, options = kb.XKBLAYOUT, kb.XKBVARIANT, kb.XKBOPTIONS' "$G"
sed -i -E 's/^([[:space:]]*)kb_layout = layout,/&\n\1kb_variant = variant,\n\1kb_options = options,/' "$G"
grep -q 'kb_options = options' "$G" && ! grep -q vconsole "$G" || die "keyboard patch did not apply to $G"

install -Dm755 -t /usr/bin "$S"/bin/*
cp -r "$S/etc/." /etc/
rsync -a --delete --exclude='.qmlls.ini' --exclude='.qt/' --exclude='.rcc/' --exclude='.vscode' \
    --exclude='build/' --exclude='CMakeFiles/' --exclude='CMakeCache.txt' --exclude='cmake_install.cmake' \
    --exclude='Makefile' --exclude='qml/' --exclude='.venv/' "$S/share/sleex/" /usr/share/sleex/
# tuned-ppd (PikaOS) replaces power-profiles-daemon and has no powerprofilesctl; same D-Bus API though
command -v powerprofilesctl >/dev/null ||
    grep -rl '"powerprofilesctl", "set", "power-saver"' /usr/share/sleex --include=*.qml | xargs -r sed -i \
        's|\["powerprofilesctl", "set", "power-saver"\]|["busctl", "--system", "set-property", "net.hadess.PowerProfiles", "/net/hadess/PowerProfiles", "net.hadess.PowerProfiles", "ActiveProfile", "s", "power-saver"]|'
# switchwall.sh is a bash script but Settings runs it with "sh" - bash on Arch, dash on Debian,
# so palette/static colour changes died silently
grep -rl 'wallpaperSwitchScriptPath' /usr/share/sleex --include=*.qml |
    xargs -r sed -i '/wallpaperSwitchScriptPath/s/\["sh",/["bash",/'
# matugen >= 3 refuses to pick a source colour without a terminal when an image has several
# candidates, so colors.json (what the shell reads) never updated; older matugen defaulted to 0
sed -i 's/matugen_args=(image "\$imgpath")/matugen_args=(image "$imgpath" --source-color-index 0)/' \
    /usr/share/sleex/scripts/colors/switchwall.sh
grep -q 'source-color-index' /usr/share/sleex/scripts/colors/switchwall.sh ||
    warn "Upstream changed switchwall.sh - shell colours may not follow the wallpaper"
# About page asks pacman/flux for the version; no package here, so read a file we write instead
echo "sleex $(sed -n 's/^pkgver="\(.*\)"/\1/p' "$BUILD/Sleex/PKGBUILD")+git.$(git -C "$BUILD/Sleex" rev-parse --short HEAD)" \
    > /usr/share/sleex/VERSION
sed -i '/pacman -Q sleex 2>\/dev\/null/s#"\]$# || cat /usr/share/sleex/VERSION"]#' /usr/share/sleex/services/SystemInfo.qml
# Wallpaper selector: rescan when the folder changes, expand "~", allow spaces (see patches/Wallpapers.qml)
W=/usr/share/sleex/services/Wallpapers.qml
if grep -q 'wallpaperSelectorPath.lenght' "$W"; then
    install -m644 "$HERE/patches/Wallpapers.qml" "$W"
    sed -i -e 's|Config.options.background.wallpaperSelectorPath + "/" + modelData|Wallpapers.wallpaperPath + "/" + modelData|g' \
        -e 's|: (Wallpapers.wallpaperPath + "/" + modelData)|: ("file://" + Wallpapers.wallpaperPath + "/" + modelData)|' \
        /usr/share/sleex/modules/wallpaperSelector/WallpaperSelector.qml
else
    warn "Upstream changed Wallpapers.qml - wallpaper folder fix not applied"
fi
install -Dm644 -t /usr/share/wayland-sessions "$S"/share/wayland-sessions/*
cp -r "$BUILD/Sleex/sleex-user-config/src/." /etc/skel/
install -Dm644 -t /usr/lib/systemd/user \
    "$BUILD/Sleex/sleex-user-config/src/.config/systemd/user/sleex-lock-listener.service"

# Debian admins are in "sudo", not "wheel"
sed -i 's/isInGroup("wheel")/isInGroup("sudo")/' /etc/polkit-1/rules.d/50-papirus-folders.rules
# older Debian hyprland builds may not ship the start-hyprland wrapper
command -v start-hyprland >/dev/null ||
    sed -i 's|^start-hyprland -- --config|exec Hyprland --config|' /usr/bin/sleex

# --- 6. Python env for the colour scripts (materialyoucolor is not in Debian)
say "Python venv for colour generation"
python3 -m venv --system-site-packages /usr/share/sleex/.venv
/usr/share/sleex/.venv/bin/pip install -q materialyoucolor
for f in colors/switchwall.sh colors/applycolor.sh kvantum/materialQT.sh; do
    sed -i -E 's#(^|[[:space:]])python3? "#\1/usr/share/sleex/.venv/bin/python "#' "/usr/share/sleex/scripts/$f"
done

# --- 7. Companion projects --------------------------------------------------
cmake_project() {
    say "Building $1"
    cmake -S "$BUILD/$1/src" -B "$BUILD/$1-out" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr &&
        cmake --build "$BUILD/$1-out" && cmake --install "$BUILD/$1-out"
}
cmake_project sleex-ui-kit   # Sleex QML imports SleexUiKit, so this one must succeed
cmake_project sleex-welcome-screen || warn "welcome screen failed to build (first-run tutorial only)"
install -d /usr/share/pixmaps/sleex /usr/share/backgrounds/sleex
cp -r "$BUILD/sleex-artworks/src/logo/." /usr/share/pixmaps/sleex/
cp -r "$BUILD/sleex-artworks/src/wallpapers/." /usr/share/backgrounds/sleex/

say "Building hypnos (idle daemon)"
# upstream pins nightly via rust-toolchain.toml; Debian's cargo ignores it
if (cd "$BUILD/hypnos/src" && RUSTUP_TOOLCHAIN=stable cargo build --release --locked); then
    install -Dm755 "$BUILD/hypnos/src/target/release/hypnos" /usr/bin/hypnos
else
    warn "hypnos failed to build (Debian's Rust may be too old) - idle/auto-lock settings won't work"
fi

# --- 8. Things Arch gets from AUR -------------------------------------------
say "Downloading matugen, cursor, GTK theme, fonts, helper scripts"
T=$BUILD/dl; mkdir -p "$T"
fetch "$GH/InioX/matugen/releases/download/v$MATUGEN_VER/matugen-$MATUGEN_VER-x86_64.tar.gz" "$T/matugen.tgz"
mkdir -p "$T/matugen" && tar -xzf "$T/matugen.tgz" -C "$T/matugen"
install -Dm755 "$(find "$T/matugen" -type f -name matugen | head -1)" /usr/bin/matugen

fetch "$GH/ful1e5/Bibata_Cursor/releases/download/v$BIBATA_VER/Bibata-Modern-Classic.tar.xz" "$T/bibata.txz"
tar -xJf "$T/bibata.txz" -C /usr/share/icons/

fetch "$GH/lassekongo83/adw-gtk3/releases/download/v$ADWGTK_VER/adw-gtk3v$ADWGTK_VER.tar.xz" "$T/adw.txz"
tar -xJf "$T/adw.txz" -C /usr/share/themes/

F=/usr/local/share/fonts/sleex; mkdir -p "$F"
fetch "$GH/ryanoasis/nerd-fonts/releases/download/v$NERD_VER/JetBrainsMono.tar.xz" "$T/jbm.txz"
tar -xJf "$T/jbm.txz" -C "$F" --wildcards '*.ttf'
fetch "$GH/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf" "$F/MaterialSymbolsRounded.ttf"
fetch "$GH/google/material-design-icons/raw/master/variablefont/MaterialSymbolsOutlined%5BFILL,GRAD,opsz,wght%5D.ttf" "$F/MaterialSymbolsOutlined.ttf"
fetch "$GH/google/fonts/raw/main/ofl/gabarito/Gabarito%5Bwght%5D.ttf" "$F/Gabarito.ttf"
fetch "$GH/google/fonts/raw/main/ofl/rubik/Rubik%5Bwght%5D.ttf" "$F/Rubik.ttf"
fetch "$GH/google/fonts/raw/main/ofl/readexpro/ReadexPro%5BHEXP,wght%5D.ttf" "$F/ReadexPro.ttf"
fc-cache -f >/dev/null

command -v hyprshot >/dev/null || {
    fetch "$GH/Gustash/Hyprshot/raw/$HYPRSHOT_VER/hyprshot" "$T/hyprshot"
    install -Dm755 "$T/hyprshot" /usr/bin/hyprshot; }
[[ -x /usr/bin/papirus-folders ]] || {
    fetch "$GH/PapirusDevelopmentTeam/papirus-folders/raw/v$PAPIRUS_FOLDERS_VER/papirus-folders" "$T/pf"
    install -Dm755 "$T/pf" /usr/bin/papirus-folders; }

# --- 9. Existing user: give them the skel config, never overwrite ----------
if [[ -n ${SUDO_USER:-} && $SUDO_USER != root ]]; then
    H=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    say "Copying default Sleex config into $H (existing files kept)"
    sudo -u "$SUDO_USER" cp -rn /etc/skel/.config /etc/skel/.local "$H/" 2>/dev/null || true
    usermod -aG input "$SUDO_USER"   # ydotool / hypnos read input devices
fi

# --- 10. Self-check ---------------------------------------------------------
say "Checking install"
fail=0
for b in sleex Hyprland qs matugen fuzzel cliphist hyprctl wl-copy wl-paste; do
    command -v "$b" >/dev/null || { warn "missing command: $b"; fail=1; }
done
[[ -f /usr/share/sleex/shell.qml ]] || { warn "missing /usr/share/sleex/shell.qml"; fail=1; }
ls "/usr/lib/$MULTIARCH/qt6/qml/Sleex" >/dev/null 2>&1 || { warn "Sleex QML plugins not installed"; fail=1; }

((${#MISSING[@]})) && warn "Not available in your repos (skipped): ${MISSING[*]}"
((${#CONFLICT[@]})) && warn "Skipped, would remove your installed packages: ${CONFLICT[*]}"
((fail)) && die "Install incomplete - see warnings above"
say "Done. Log out and pick the 'Sleex' session in your display manager (SDDM/GDM/greetd)."
say "First start copies configs; wallpaper colours need one wallpaper pick in Sleex settings."
