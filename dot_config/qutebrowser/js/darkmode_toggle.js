(function() {
  const is_light = (color) => {
    if (color == 'rgba(0, 0, 0, 0)') {
      return true;
    }
    let [r, g, b] = color.replace(/rgb\((.*)\)/, "$1").split(", ");

    hsp = Math.sqrt(
      0.299 * (r * r) +
      0.587 * (g * g) +
      0.114 * (b * b)
    );

    return hsp > 127.5;
  };

  const is_tag_light = (tag_name) => {
    if (document.getElementsByTagName(tag_name).length) {
      let pre_color = window.getComputedStyle(document.getElementsByTagName(tag_name)[0] , null)
      .getPropertyValue('background-color');
      return is_light(pre_color);
    }
    return true;
  };

  const add_style = () => {
    let style = document.createElement("style");
    let pre = is_tag_light("pre");
    let nav = is_tag_light("nav");

    style.innerText = [
      "html {",
      "filter: invert(1) !important;",
      "min-height: 100vh;",
      'background-color: #dfdfdf;',
      "}",
      "img { filter: invert(1); }",
      (pre ? "" : "pre { filter: invert(1); }"),
      (nav ? "" : "nav { filter: invert(1); }"),
    ].join("");
    style.classList.add("my-darkmode-style");
    document.body.appendChild(style);
  };

  const invert = () => {
    let color = window.getComputedStyle(document.body, null)
      .getPropertyValue('background-color');

    let [r, g, b] = color.replace(/rgb\((.*)\)/, "$1").split(", ");
    [r, g, b] = [+r, +g, +b];

    add_style();
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
