// ==UserScript==
// @name         Youtube
// @namespace    https://pbogut.me/
// @version      0.0.3
// @description  Youtube helper
// @include https://youtube.com/*
// @include https://www.youtube.com/*
//
// @noframes
// @grant none
// ==/UserScript==

let timestamp = 0;
setInterval(() => {
  console.log("check skip")
  const skip = document.querySelector('.ytp-skip-ad-button');
  const enforcement = document.querySelector('.ytd-enforcement-message-view-model button');
  const iframe = document.querySelector('#fc-whitelist-iframe');
  const vid = document.querySelector('video');
  localStorage.setItem('x-vid-time-', '0');

  if (vid) {
    if (vid.currentTime > 10) {
      timestamp = vid.currentTime;
    }
  }
  if (skip) {
    skip.click();
  }
  if (enforcement) {
    enforcement.click();
  }
  if (iframe) {
    const current = window.location.href;
    window.location.href = current.replace(/\&t=\d+/, '') + '&t=' + parseInt(timestamp);
  }

}, 500);
