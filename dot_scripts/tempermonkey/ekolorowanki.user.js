// ==UserScript==
// @name         e-kolorowanki
// @namespace    https://pbogut.me/
// @version      0.0.1
// @description  e-kolorowanki
// @include https://www.e-kolorowanki.eu/*
// @include https://e-kolorowanki.eu/*
//
// @noframes
// @grant none
// ==/UserScript==

const interval = setInterval(() => {
  const ads = document.querySelector('.fc-dialog-container')
  ads.remove();
}, 500);
