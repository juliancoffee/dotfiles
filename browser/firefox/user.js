/*
 * Fuck background processes
 */
user_pref("dom.serviceWorkers.enabled", false);

/*
 * Disable pocket
 */
user_pref("extensions.pocket.enabled", false);

/*
 * Cache settings
 */
user_pref("browser.cache.memory.enable", false);
user_pref("browser.cache.offline.enable", false);
user_pref("browser.sessionhistory.max_total_viewers", 0);
user_pref('browser.cache.disk.enable', true); // Enable disk cache
user_pref("browser.cache.disk_cache_ssl", false);
user_pref('browser.cache.disk.capacity', 1000000); // Disk cache capacity: -1 = determine dynamically (default), 0 = none, n = memory capacity in kilobytes
//user_pref('browser.cache.disk.parent_directory', '/run/user/1000/firefox-cache'); // Write cache to RAM (tmpfs) instead of SSD / HDD

/*
 * Disable middlemouse paste leaking clipboard content on Linux after autoscroll
 */
user_pref('middlemouse.paste', false);

/*
 * Disable Mega bar
 */
user_pref('browser.urlbar.openViewOnFocus', false);
user_pref('browser.urlbar.suggest.topsites', false);

/*
 * Downloads settings
 */
user_pref('browser.download.useDownloadDir', false); // Always asking where to download
user_pref('browser.download.hide_plugins_without_extensions', false); // Disable hiding mime types not associated with a plugin

/*
 * Appearance
 */
user_pref('browser.download.autohideButton', false); // Always display Downloads button
user_pref('toolkit.legacyUserProfileCustomizations.stylesheets', true); // Allow userChrome/userContent
