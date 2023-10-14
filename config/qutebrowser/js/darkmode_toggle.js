(function() {
  const add_style = (color) => {
    let style = document.createElement("style");

    style.innerText = [
      "html {",
      "filter: invert(1) !important;",
      "min-height: 100vh;",
      "background-color: " + color + " !important;",
      "}",
      "img { filter: invert(1); }",
    ].join("");
    style.classList.add("my-darkmode-style");
    document.body.appendChild(style);
  };

  const invert = () => {
    let color = window.getComputedStyle(document.body, null)
      .getPropertyValue('background-color');

    let [r, g, b] = color.replace(/rgb\((.*)\)/, "$1").split(", ");
    [r, g, b] = [+r, +g, +b];

    if (color == "rgba(0, 0, 0, 0)") {
      add_style("rgb(0,0,0)");
    } else {
      let [nr, ng, nb] = [255 - r, 255 - g, 255 - b];
      add_style("rgb(" + nr + "," + ng + "," + nb + ")");
    }
  };

  let styles = document.getElementsByClassName("my-darkmode-style");
  if (styles.length > 0) {
    for (let style of styles) {
      style.remove();
    }
    localStorage.setItem("_my_darkmode", "off");
  } else {
    invert();
    localStorage.setItem("_my_darkmode", "on");
  }
})();
