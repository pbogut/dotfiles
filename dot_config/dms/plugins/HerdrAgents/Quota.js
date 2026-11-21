function mergeProviders(previous, incoming) {
    if (!incoming || typeof incoming !== "object" || Array.isArray(incoming))
        return previous;

    const merged = Object.assign({}, previous);
    let changed = false;
    for (const providerId of Object.keys(incoming)) {
        const provider = incoming[providerId];
        if (!provider || (provider.status !== "ok" && provider.status !== "partial"))
            continue;
        const fetchedAt = provider.fetchedAt;
        if (!Number.isFinite(fetchedAt) || fetchedAt <= 0 || fetchedAt > Date.now() / 1000)
            continue;
        // Export time advances even when another instance replays an old cache.
        if (previous[providerId] && fetchedAt <= previous[providerId].fetchedAt)
            continue;
        if (!Array.isArray(provider.entries))
            continue;

        const entries = [];
        for (const entry of provider.entries) {
            if (!entry || entry.renderType !== "percent" || !Number.isFinite(entry.percentRemaining))
                continue;
            entries.push({
                name: String(entry.name || providerId),
                window: String(entry.window || ""),
                renderType: "percent",
                percentRemaining: Math.max(0, Math.min(100, entry.percentRemaining)),
                resetAt: Number.isFinite(entry.resetAt) ? entry.resetAt : 0
            });
        }
        if (!entries.length)
            continue;
        merged[providerId] = {status: provider.status, fetchedAt: fetchedAt, entries: entries};
        changed = true;
    }
    return changed ? merged : previous;
}

function render(providers) {
    const rows = [];
    let updatedAt = 0;
    for (const providerId of Object.keys(providers)) {
        const provider = providers[providerId];
        updatedAt = updatedAt ? Math.min(updatedAt, provider.fetchedAt) : provider.fetchedAt;
        for (const entry of provider.entries) {
            rows.push({
                providerId: providerId,
                label: entry.name,
                window: entry.window,
                percentRemaining: entry.percentRemaining,
                resetAt: entry.resetAt,
                fetchedAt: provider.fetchedAt
            });
        }
    }
    const windowOrder = {"5h": 0, "Weekly": 1, "Monthly": 2};
    rows.sort(function(a, b) {
        if (a.providerId < b.providerId)
            return -1;
        if (a.providerId > b.providerId)
            return 1;
        const aRank = windowOrder[a.window] ?? 99;
        const bRank = windowOrder[b.window] ?? 99;
        if (aRank !== bRank)
            return aRank - bRank;
        if (a.label < b.label)
            return -1;
        if (a.label > b.label)
            return 1;
        return 0;
    });
    return {updatedAt: updatedAt, rows: rows};
}
