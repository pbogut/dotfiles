(function () {
  var protocol = window.location.protocol === "file:" ? "http:" : "";
  var url =
    protocol + "//www.sprymedia.co.uk/VisualEvent/VisualEvent_Loader.js";
  if (typeof VisualEvent != "undefined") {
    if (VisualEvent.instance !== null) {
      VisualEvent.close();
    } else {
      new VisualEvent();
    }
  } else {
    var n = document.createElement("script");
    n.setAttribute("language", "JavaScript");
    n.setAttribute("src", url + "?rand=" + new Date().getTime());
    document.body.appendChild(n);
  }
})();
