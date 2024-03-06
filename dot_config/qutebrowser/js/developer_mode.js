(function () {
  if (window.location.href.indexOf("&developer_mode=true") != -1) {
    window.location = window.location.href.replace("&developer_mode=true", "");
  } else if (window.location.href.indexOf("developer_mode=true&") != -1) {
    window.location = window.location.href.replace("developer_mode=true&", "");
  } else if (window.location.href.indexOf("?developer_mode=true") != -1) {
    window.location = window.location.href.replace("?developer_mode=true", "");
  } else if (window.location.href.indexOf("developer_mode=true") == -1) {
    window.location = window.location.href +
      (window.location.href.indexOf("?") != -1 ? "&" : "?") + "developer_mode=true";
  }
})();
