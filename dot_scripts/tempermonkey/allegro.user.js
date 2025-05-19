// ==UserScript==
// @name         Allegro
// @namespace    https://pbogut.me/
// @version      0.0.1
// @description  Allegro
// @include https://allegro.pl/*
// @include https://www.allegro.pl/*
//
// @noframes
// @grant none
// ==/UserScript==

const interval = setInterval(() => {
  const checkbox = document.querySelector('#invoice-checkbox')
  if (checkbox && !checkbox.checked) {
    checkbox.click();
    if (interval) {
      clearInterval(interval);
    }
  }
}, 500);
