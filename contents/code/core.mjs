// Pure helper functions used by ui/main.qml.
// Kept side-effect free so they're easy to reason about from the QML state machine.

// Walk up the tile tree to the screen's root tile.
export function rootTileOf(tile) {
    let t = tile;
    while (t.parent)
        t = t.parent;
    return t;
}

// Recursively collect empty leaf tiles under `tile`. A tile that already
// holds a window is treated as fully occupied and its children are skipped,
// since they're visually covered by that window.
export function collectEmptyLeaves(tile, out) {
    if (!tile)
        return;
    if (tile.windows.length > 0)
        return;
    if (tile.tiles.length === 0) {
        out.push(tile);
        return;
    }
    for (let i = 0; i < tile.tiles.length; i++)
        collectEmptyLeaves(tile.tiles[i], out);
}

export function tileArea(tile) {
    return tile.absoluteGeometry.width * tile.absoluteGeometry.height;
}

// Windows eligible to be recommended as fillers for a leftover zone.
export function candidateWindows(stackingOrder, currentDesktop, exclude) {
    const result = [];
    for (let i = stackingOrder.length - 1; i >= 0; i--) {
        const w = stackingOrder[i];
        if (!w || !w.normalWindow)
            continue;
        if (w.desktopWindow || w.skipTaskbar)
            continue;
        if (w.desktop !== currentDesktop)
            continue;
        if (exclude.indexOf(w) !== -1)
            continue;
        result.push(w);
    }
    return result;
}
