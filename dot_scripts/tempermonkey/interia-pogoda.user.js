// ==UserScript==
// @name         Pogoda Interia
// @namespace    https://pbogut.me/
// @version      0.0.1
// @description  Pogoda Interia
// @include https://pogoda.interia.pl/*
//
// @noframes
// @grant none
// ==/UserScript==

var body = document.getElementsByTagName("body")[0];
var style = document.createElement("style");

style.innerText =
  "#WeatherVideoPlayer { display: none !important; }" +
  "#videoPlayer { display: none !important; }" +
  ".brief-list { display: none !important; }" +
  ".most-read { display: none !important; }" +
  ""
;

body.appendChild(style);

