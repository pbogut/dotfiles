local active_border = { colors = { "rgba(6c71c4ee)", "rgba(2aa198ee)" }, angle = 45 }

hl.config({
    general = { col = { active_border = active_border } },
    group = { col = { border_active = active_border } },
})
