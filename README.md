# omarchy-cpu-temperature

[中文说明](README.zh-CN.md)

User-owned Omarchy bar widget (`omarchy-cpu-temperature`). Reads the maximum
current CPU package/core temperature from `coretemp`, `k10temp`, or `zenpower`
Linux hwmon devices. GPU, SSD and chipset sensors are excluded. AMD Tctl is
excluded when Tdie is available because Tctl can include a control offset.
No sudo, third-party packages, or `sensors` command is required; sensor paths are
discovered internally, so polling spawns no subprocess.

- Refreshes every 15 seconds by default; left click refreshes immediately.
- Hover shows all CPU readings, in °C.
- Vertical bars stack the unit below the number; horizontal bars show `50°C`.
- Uses the theme's urgent color at 85°C (a visual warning, not a fan threshold).
- Missing, empty, malformed or unreadable readings are excluded; shows `—` if none remain valid.
- Discovers sensors at startup and retries discovery every 60 seconds while all readings are unavailable, recovering from late driver loads or changed hwmon paths.
- Does not change fan speed, thermal policy, or CPU power settings.

Settings live inline in `~/.config/omarchy/shell.json` and can be changed with:

```sh
omarchy bar set omarchy-cpu-temperature pollInterval 5000
omarchy bar set omarchy-cpu-temperature warningTemperature 90
```

`pollInterval` is clamped to 1000–60000 ms; `warningTemperature` to 50–110°C.
Runtime validation also applies to manually edited settings: invalid values fall back to defaults,
out-of-range values are clamped, and fractions are rounded.

Enable/place or disable:

```sh
omarchy-shell shell rescanPlugins
omarchy plugin enable omarchy-cpu-temperature --after omarchy-rime-keyboard-layout
omarchy plugin disable omarchy-cpu-temperature
```

Development tests (require Python 3 and Node.js, neither is needed to run the plugin):

```sh
python3 -m unittest discover -s tests -v
```

Covers temperature parsing, settings bounds, and discovery in synthetic Intel/AMD hwmon trees,
including non-CPU filtering.

Inspect raw readings:

```sh
for h in /sys/class/hwmon/hwmon*; do
  printf '%s (%s)\n' "$h" "$(cat "$h/name")"
  grep -H . "$h"/temp*_input 2>/dev/null
done
```

This lists every hwmon device and its raw millidegree inputs; the widget itself
only consumes `coretemp`, `k10temp` and `zenpower`.
