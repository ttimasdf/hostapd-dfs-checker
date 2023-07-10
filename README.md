# hostapd-dfs-checker
Check hostapd managed WLAN DFS status and trigger interface reboot when DFS brings down the interface. Compatible on OpenWrt.

This script write a pid file for checking concurrent running instances, so it's safe to call it from crontab.

# Usage

Modify the code to best suit your needs. Things which you should definitely configure:

1. `send_web_request` function and `URL`, `TOKEN` value to implement your own notification method. The one I am using: [ttimasdf/wework-webhook: Push notification through webhook to Wechat Work application](https://github.com/ttimasdf/wework-webhook)
2. Check the interface name, which is currently hard coded to `wlan0` (and `radio0`), the 802.11a WLAN interface on my router.
3. install `bash` if you are using OpenWrt. Busybox `ash` is untested. If your router has insufficient storage for packages, maybe you should change a router 😉
4. install a crontab entry for this script with `crontab -e`
   ```cron
   * * * * * /root/cron-wlan0-dfs.sh
   ```

It's done!

log messages print out both to stdout and openwrt system log. If you are using other log systems, modify the `log` function as needed.
