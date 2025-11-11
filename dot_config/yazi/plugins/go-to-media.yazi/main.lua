return {
  entry = function()
    ya.emit("cd", {"/run/media/" .. os.getenv('USER')})
  end
}
