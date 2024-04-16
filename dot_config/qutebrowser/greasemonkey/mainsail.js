// ==UserScript==
// @name         MainSail printer selection from link
// @namespace    https://pbogut.me/
// @version      1.0
// @description  Allows to link directly to specific printer in the mainsail instance
// @include https://mainsail.local/*
// @include http://mainsail.local/*
// @include https://octopi.local/*
// @include http://octopi.local/*
// @include https://192.168.1.107/*
// @include http://192.168.1.107/*
// @noframes
// @grant none
// ==/UserScript==

const selectPrinter = () => {
  let printer = location.hash.replace(/^#/, '');
  if (printer.length) {
    let xpath = "//div[text()='" + printer + "']";
    let matchingElement = document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
    if (matchingElement) {
      location.hash = ''
      matchingElement.click()
    }
  }
}
document.onload = selectPrinter
selectPrinter();
setTimeout(selectPrinter, 500);
setTimeout(selectPrinter, 1000);
setTimeout(selectPrinter, 2000);
setTimeout(selectPrinter, 5000);
