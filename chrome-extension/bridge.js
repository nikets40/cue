// Isolated-world half of the pair: relays what page-reader.js sees in the
// page's realm to the service worker, which owns the socket to Cue Booth.
window.addEventListener("message", (event) => {
  if (event.source !== window) return;
  const message = event.data;
  if (!message || message.source !== "cue-page-reader") return;
  chrome.runtime.sendMessage({ type: "pageMeta", payload: message.payload }).catch(() => {
    // Service worker asleep or reloading; the next poll will retry.
  });
});
