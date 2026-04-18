/*
 * Limit background web push without disabling service workers entirely.
 */
user_pref("dom.push.enabled", false);

/*
 * Disable pocket
 */
user_pref("extensions.pocket.enabled", false);

/*
 * Cache settings
 */
user_pref("browser.cache.memory.enable", false);
user_pref("browser.sessionhistory.max_total_viewers", 0);
// Enable disk cache
user_pref('browser.cache.disk.enable', true);
user_pref("browser.cache.disk_cache_ssl", false);
// Disk cache capacity:
// -1 = determine dynamically (default),
// 0 = none,
// n = memory capacity in kilobytes
user_pref('browser.cache.disk.capacity', 1000000);
// Write cache to RAM (tmpfs) instead of SSD / HDD
//user_pref('browser.cache.disk.parent_directory', '/run/user/1000/firefox-cache'); 

/*
 * Disable middlemouse paste leaking clipboard content on Linux after autoscroll
 */
user_pref('middlemouse.paste', false);

/*
 * Disable Mega bar
 */
user_pref('browser.urlbar.suggest.topsites', false);

/*
 * Downloads settings
 */
// Always asking where to download
user_pref('browser.download.useDownloadDir', false);

/*
 * Tab unloading
 */
// Cap the web content process pool on this 8 GB machine.
user_pref('dom.ipc.processCount', 5);
// Keep a small cache of recent tab layers for snappier switching.
user_pref('browser.tabs.remote.tabCacheSize', 3);
// Optional: disable tab warmup if Firefox still feels too heavy.
// user_pref('browser.tabs.remote.warmup.enabled', false);
// Start unloading earlier on macOS memory-pressure warnings.
user_pref('browser.lowMemoryResponseOnWarn', true);
// Let Firefox unload inactive tabs under memory pressure.
user_pref('browser.tabs.unloadOnLowMemory', true);
// Make tabs eligible for unloading after 5 minutes of inactivity.
user_pref('browser.tabs.min_inactive_duration_before_unload', 300000);
// Expose the "Unload Tab" right-click action.
user_pref('browser.tabs.unloadTabInContextMenu', true);

/*
 * Appearance
 */
// Always display Downloads button
user_pref('browser.download.autohideButton', false);
// Allow userChrome/userContent
user_pref('toolkit.legacyUserProfileCustomizations.stylesheets', true);
// Enable Container Tabs
user_pref('privacy.userContext.enabled', true);
// Enable Container Tabs setting in preferences
user_pref('privacy.userContext.ui.enabled', true);

// Disable it, if sites (like google docs break)
user_pref('gfx.canvas.accelerated', true);
