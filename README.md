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

# LLM prompts used to assist in making this project

The raw result from LLM is omitted for conciseness. I've also add some minor changes before final releasing.

> Write a bash script for a cron job following these requirements:
> 1. The script check the output of `hostapd_cli -i wlan0 status` and check for its `state`. store the state in `/var/run/wlan0-last-state` file.
> 2. read the last state before storing state, if state is changing, notify the state change by `curl -v https://webhook.com/wework/appid/text -H "X-WW-Auth: $token" -d 'msg content'`
> 3. if the state changes from `ENABLED` something else, like `DFS` or `DISABLED`, restart the WiFi by `/sbin/wifi up radio0`. and monitor the state once per second for 2 minutes, notify state changes inside this time period.
> 4. Since this script is a one-shot running once a minute. if any previous script is still running, the subsequent script running should be skipped. the running state is maintained by a pid file `/var/run/cron-wlan0-dfs.pid` and the running check is done through checking the pid number. no additional lock file is needed.
> 5. log output should be wrapped by a helper function like:
> ```bash
> log() {
>   echo "$1"
>   logger -t "wlan_checker" "$1"
> }
> ```
>
> ---
>
> Request for changes.
>
> 1. In `restart_and_monitor_wifi`, the send_web_request should be called only when there's state change in wlan0 interface, like maintain a variable `previous_state` and check with current `state`.
> 2. In `send_web_request`, the function should log the message content to `log` function.
> 3. In `send_web_request`, curl should use `$HOME/root_vm.crt` as trusted root certificate, and remove `-v` flag
> 4. abstract the `hostapd_cli` call for wlan0 check to a new function and return the state string like `ENABLED` `DFS`, and add a condition where `hostapd_cli -i wlan0 status` contains string like `wpa_ctrl_open: No such file or directory` in stderr. In this case, return the case `DISABLED`.


