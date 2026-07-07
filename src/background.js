// Knockoff background service worker. The toolbar button toggles the
// in-page control panel on Amazon tabs; anywhere else (no content script to
// answer the message) it opens the settings page instead.

var runtimeApi = typeof browser !== "undefined" ? browser : chrome;

function openOptionsPage() {
  var opened = runtimeApi.runtime.openOptionsPage();
  if (opened && typeof opened.catch === "function") opened.catch(function () {});
}

runtimeApi.action.onClicked.addListener(function (tab) {
  if (!tab || typeof tab.id === "undefined") {
    openOptionsPage();
    return;
  }

  try {
    var sent = runtimeApi.tabs.sendMessage(tab.id, { type: "ko-toggle-panel" });
    if (sent && typeof sent.catch === "function") sent.catch(openOptionsPage);
  } catch (e) {
    openOptionsPage();
  }
});

// Content scripts can't open the options page themselves.
runtimeApi.runtime.onMessage.addListener(function (msg) {
  if (msg && msg.type === "ko-open-options") openOptionsPage();
});
