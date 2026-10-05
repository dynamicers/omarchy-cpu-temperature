# omarchy-cpu-temperature

[中文说明](README.zh-CN.md)

User-owned Omarchy bar widget (`omarchy-cpu-temperature`). Reads the maximum
current CPU package/core temperature from `coretemp`, `k10temp`, or `zenpower`
Linux hwmon devices. GPU, SSD and chipset sensors are excluded. AMD Tctl is
excluded when Tdie is available because Tctl can include a control offset.
No sudo, third-party Python packages, or `sensors` command is required.

- Refreshes every 3 seconds; left click refreshes immediately.
- Hover shows all CPU readings, in °C.
- Vertical bars stack the unit below the number; horizontal bars show `50°C`.
- Uses the theme's urgent color at 85°C (a visual warning, not a fan threshold).
- Missing/unreadable readings show `—` instead of retaining stale data.
- Does not change fan speed, thermal policy, or CPU power settings.

Settings live inline in `~/.config/omarchy/shell.json` and can be changed with:

```sh
omarchy bar set omarchy-cpu-temperature pollInterval 5000
omarchy bar set omarchy-cpu-temperature warningTemperature 90
```

Enable/place or disable:

```sh
omarchy-shell shell rescanPlugins
omarchy plugin enable omarchy-cpu-temperature --after omarchy-rime-keyboard-layout
omarchy plugin disable omarchy-cpu-temperature
```

Inspect raw readings:

```sh
python3 ~/.config/omarchy/plugins/omarchy-cpu-temperature/read-temperature.py
```
