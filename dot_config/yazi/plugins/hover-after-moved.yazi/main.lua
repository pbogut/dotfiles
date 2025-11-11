--- @since 25.5.31

local PackageName = "hover-after-moved"

local M = {}

function M:setup()
	ps.sub("@yank", function(_)
		ps.unsub("move")
		ps.sub("move", function(payload)
			if not payload then
				ps.unsub("move")
				return
			end

			if payload.items and #payload.items > 0 then
				if cx.active.current.cwd and cx.active.current.cwd == payload.items[1].to.parent then
					ya.emit("reveal", {
						payload.items[1].to,
						no_dummy = true,
						raw = true,
						tab = cx.active.id.value,
					})
					return
				end
			end
			ps.unsub("move")
		end)
	end)
end

return M
