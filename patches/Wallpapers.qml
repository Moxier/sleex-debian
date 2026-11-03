// Replaces upstream services/Wallpapers.qml (Sleex). Fixes the wallpaper selector after the
// folder is changed in Settings:
//  - the list was scanned once at startup, so a new folder showed old filenames -> broken previews
//  - "~" was expanded by bash for the scan but not by Image/switchwall.sh -> images never loaded
//  - folders with spaces broke the unquoted find command
import qs.modules.common
import SleexUiKit.Functions
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property var wallpaperList: []

    // absolute folder, no "~", no trailing slash; used for scanning, previews and applying
    property string wallpaperPath: {
        const p = Config.options.background.wallpaperSelectorPath;
        const home = FileUtils.trimFileProtocol(Directories.home);
        return (p && p.length ? p : Directories.wallpaperPath)
            .replace(/^~(?=\/|$)/, home).replace(/(.)\/+$/, "$1");
    }

    // the Settings field writes on every keystroke: wait until typing stops before rescanning
    onWallpaperPathChanged: rescan.restart()
    Timer {
        id: rescan
        interval: 400
        onTriggered: {
            listWallpapers.running = false;
            root.wallpaperList = [];
            listWallpapers.running = true;
        }
    }

    Process {
        id: listWallpapers
        running: true
        command: ["find", root.wallpaperPath, "-type", "f", "(",
            "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o",
            "-iname", "*.gif", "-o", "-iname", "*.webp", ")", "-printf", "%P\\n"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wallpaperList = text.split('\n').filter(function(item) { return item.length > 0; });
            }
        }
    }
}
