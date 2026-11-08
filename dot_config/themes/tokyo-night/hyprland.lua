local active_border = { colors = { "rgba(ad8ee6ee)", "rgba(bb9af7ee)" }, angle = 45 }

hl.config({
    general = { col = { active_border = active_border } },
    group = { col = { border_active = active_border } },
})
