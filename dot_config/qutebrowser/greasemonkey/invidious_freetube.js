// ==UserScript==
// @name       Invidious open in freetube
// @namespace  https://pbogut.me/
// @version    1.0
// @description  Invidious open in freetube
// @include https://invidious.pbogut.me/*
// @grant none
// ==/UserScript==

const links = document.querySelectorAll('[href*="/watch?v=')
for (let i = 0; i < links.length; i++) {
  links[i].href = links[i].href.replace('https://invidious.pbogut.me', 'freetube://https://youtube.com')
}
