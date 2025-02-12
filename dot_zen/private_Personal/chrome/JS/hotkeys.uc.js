// ==UserScript==
// @name           Tab Navigation and Reordering Hotkeys
// @namespace      tab_navigation_hotkeys
// @version        1.1
// @description    Use alt-j and alt-k to navigate tabs, alt-J and alt-K to move tabs
// ==/UserScript==

function key_move_tabs() {
  UC_API.Hotkeys.define({
    modifiers: "alt",
    key: "J",
    id: "key_move_next",
    command: (win) => {
      gBrowser.tabContainer.advanceSelectedTab(1, true);
    },
  }).autoAttach({ suppressOriginalKey: true });

  UC_API.Hotkeys.define({
    modifiers: "alt",
    key: "K",
    id: "key_move_prev",
    command: (win) => {
      gBrowser.tabContainer.advanceSelectedTab(-1, true);
    },
  }).autoAttach({ suppressOriginalKey: true });

  UC_API.Hotkeys.define({
    modifiers: "ctrl alt",
    key: "K",
    id: "key_move_tab_up",
    command: (win) => {
      gBrowser.moveTabBackward();
    },
  }).autoAttach({ suppressOriginalKey: true });

  UC_API.Hotkeys.define({
    modifiers: "ctrl alt",
    key: "J",
    id: "key_move_tab_down",
    command: (win) => {
      gBrowser.moveTabForward();
    },
  }).autoAttach({ suppressOriginalKey: true });
}

key_move_tabs();
