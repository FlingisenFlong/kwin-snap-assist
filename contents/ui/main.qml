import QtQuick
import org.kde.kwin
import "../code/core.mjs" as Core

// Entry point (X-Plasma-MainScript). Watches for windows being quick-tiled
// (drag-to-edge or Meta+Arrow) and, when that leaves empty space on the
// screen, offers the user's other open windows as one-click fillers for it
// - the same idea as Snap Assist on Windows.
Item {
    id: root

    // How many seconds the recommendation popup stays up before it
    // auto-dismisses if the user ignores it.
    readonly property int autoHideMs: 7000
    readonly property int maxCandidates: 8

    property var pendingTiles: []
    property var snappedWindow: null
    property var usedWindows: []
    property var lastSnapTile: null

    function startSnapAssist(window, tile) {
        if (tile === lastSnapTile)
            return;

        const top = Core.rootTileOf(tile);
        if (tile === top)
            return; // fully maximized via tiling - nothing left to fill

        const empty = [];
        Core.collectEmptyLeaves(top, empty);
        const filtered = empty.filter(t => t !== tile && t.windows.length === 0);
        if (filtered.length === 0)
            return;

        filtered.sort((a, b) => Core.tileArea(b) - Core.tileArea(a));

        lastSnapTile = tile;
        snappedWindow = window;
        usedWindows = [window];
        pendingTiles = filtered;
        showNextPrompt();
    }

    function showNextPrompt() {
        if (pendingTiles.length === 0) {
            endSession();
            return;
        }

        const tile = pendingTiles[0];
        const candidates = Core.candidateWindows(Workspace.stackingOrder, Workspace.currentDesktop, usedWindows).slice(0, maxCandidates);
        if (candidates.length === 0) {
            endSession();
            return;
        }

        panelLoader.item.showFor(tile, candidates);
    }

    function pickWindow(window) {
        const tile = pendingTiles.shift();
        if (window && tile) {
            if (window.minimized)
                window.minimized = false;
            window.setMaximize(false, false);
            window.tile = tile;
            usedWindows.push(window);
        }
        showNextPrompt();
    }

    function endSession() {
        if (panelLoader.item)
            panelLoader.item.visible = false;
        pendingTiles = [];
        snappedWindow = null;
        usedWindows = [];
        lastSnapTile = null;
    }

    function connectWindow(window) {
        function onTileChanged() {
            // Ignore live updates while the user is still dragging; the
            // interactiveMoveResizeFinished handler below deals with that
            // case once the gesture actually completes.
            if (window.move || window.resize)
                return;

            if (window.tile)
                startSnapAssist(window, window.tile);
            else if (window === snappedWindow)
                endSession();
        }

        function onInteractiveMoveResizeFinished() {
            if (window.tile)
                startSnapAssist(window, window.tile);
        }

        window.tileChanged.connect(onTileChanged);
        window.interactiveMoveResizeFinished.connect(onInteractiveMoveResizeFinished);
    }

    Loader {
        id: panelLoader
        active: true
        source: "SnapAssistPanel.qml"

        onLoaded: {
            item.windowPicked.connect(root.pickWindow);
            item.dismissed.connect(root.endSession);
            item.autoHideMs = root.autoHideMs;
        }
    }

    Connections {
        target: Workspace
        function onWindowAdded(window) {
            connectWindow(window);
        }
        function onWindowRemoved(window) {
            if (window === snappedWindow)
                endSession();
        }
    }

    Component.onCompleted: {
        for (let i = 0; i < Workspace.stackingOrder.length; i++)
            connectWindow(Workspace.stackingOrder[i]);
    }
}
