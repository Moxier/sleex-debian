#!/usr/bin/env bash
# Remove what install-sleex-debian.sh installed, using the record it keeps in /var/lib/sleex-debian.
# Usage: sudo ./uninstall-sleex-debian.sh
# Your home folder (~/.config/sleex, ~/.local/state/sleex, ...) is left alone.
set -euo pipefail

STATE=${SLEEX_STATE:-/var/lib/sleex-debian}
say()  { printf '\e[1;34m==>\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m!!\e[0m %s\n' "$*" >&2; }
die()  { printf '\e[1;31mxx\e[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run with sudo: sudo $0"
[[ -s $STATE/files ]] || die "No install record in $STATE.
   Installed before uninstall support was added? Run the current install-sleex-debian.sh once, then this."

say "This removes Sleex, puts back the files it replaced, and offers to remove the packages it installed."
say "Log out of the Sleex session first."
if [[ ${1:-} != -y ]]; then
    read -rp "Continue? [y/N] " a
    [[ $a == [yY]* ]] || exit 0
fi

say "Removing Sleex files"
tac "$STATE/files" | while IFS= read -r f; do
    [[ $f == /* && $f != / ]] || continue   # never act on a malformed line
    rm -rf -- "$f"
    # drop directories left empty, but only Sleex's own (never e.g. /usr/share/wayland-sessions)
    d=${f%/*}
    while [[ ${d,,} == *sleex* ]] && rmdir -- "$d" 2>/dev/null; do d=${d%/*}; done
done

if [[ -d $STATE/backup ]] && [[ -n $(ls -A "$STATE/backup") ]]; then
    say "Restoring the original files Sleex replaced"
    cp -a "$STATE/backup/." /
fi

if [[ -s $STATE/input-group ]]; then
    while IFS= read -r u; do gpasswd -d "$u" input >/dev/null 2>&1 || true; done < "$STATE/input-group"
fi
command -v fc-cache >/dev/null && fc-cache -f >/dev/null

mapfile -t PKGS < <(sort -u "$STATE/apt" | while IFS= read -r p; do
    dpkg-query -W -f='${db:Status-Status}' "$p" 2>/dev/null | grep -qx installed && echo "$p"
done)
if ((${#PKGS[@]})); then
    say "The installer added ${#PKGS[@]} packages. apt will now list the ones nothing else needs."
    say "Read the list before answering - say no to keep everything."
    # mark them auto so apt only removes what no other installed package still depends on
    apt-mark auto "${PKGS[@]}" >/dev/null
    apt-get autoremove || warn "Packages kept. Run 'sudo apt autoremove' later to remove them."
fi

rm -rf -- "$STATE" /var/tmp/sleex-build
say "Done. Sleex is removed; pick another session at the login screen."
say "Your own settings stay in ~/.config/sleex and ~/.local/state/sleex - delete them by hand if you want."
