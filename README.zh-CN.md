# omarchy-cpu-temperature

[English](README.md)

用户自有的 Omarchy 状态栏插件（`omarchy-cpu-temperature`）。从 Linux hwmon
设备的 `coretemp`、`k10temp` 或 `zenpower` 驱动读取 CPU 封装及核心的当前温度，
并显示其中的最高值。不会读取 GPU、SSD 或芯片组传感器。
AMD 同时提供 Tdie 和 Tctl 时会忽略 Tctl，因为 Tctl 可能包含用于温控的偏移量。
无需 sudo、第三方包或 `sensors` 命令；传感器路径在插件内部自动发现，轮询时不会额外启动进程。

- 默认每 15 秒刷新一次；鼠标左键点击可立即刷新。
- 鼠标悬停时显示所有 CPU 温度读数，单位为 °C。
- 竖向状态栏将单位显示在数值下方；横向状态栏显示为 `50°C`。
- 温度达到 85°C 时使用主题的紧急提示颜色（仅为视觉提醒，并非风扇控制阈值）。
- 读数缺失、为空、格式非法或无法读取时显示 `—`（仍有有效传感器时显示有效读数的最高值）。
- 启动时自动发现传感器；全部读数不可用时每 60 秒重新发现，以恢复延迟加载的驱动或变化的 hwmon 路径。
- 不会修改风扇转速、温控策略或 CPU 电源设置。

## 设置

配置保存在 `~/.config/omarchy/shell.json` 中，可通过以下命令修改：

```sh
omarchy bar set omarchy-cpu-temperature pollInterval 5000
omarchy bar set omarchy-cpu-temperature warningTemperature 90
```

`pollInterval` 的单位为毫秒，限制在 1000–60000；`warningTemperature` 的单位为 °C，限制在 50–110。
直接编辑配置时也会校验：非法值回退默认值，超出范围的值限制到边界，小数取整。

## 启用、定位或禁用

```sh
omarchy-shell shell rescanPlugins
omarchy plugin enable omarchy-cpu-temperature --after omarchy-rime-keyboard-layout
omarchy plugin disable omarchy-cpu-temperature
```

## 开发测试

```sh
python3 -m unittest discover -s tests -v
```

测试需要 Python 3 和 Node.js；插件运行本身不需要这两项依赖。
测试覆盖温度解析、配置边界，以及模拟 hwmon 目录中的 Intel/AMD 传感器发现和非 CPU 设备过滤。

## 查看原始读数

```sh
for h in /sys/class/hwmon/hwmon*; do
  printf '%s (%s)\n' "$h" "$(cat "$h/name")"
  grep -H . "$h"/temp*_input 2>/dev/null
done
```

该命令会列出所有 hwmon 设备及其原始毫摄氏度读数；插件自身只读取
`coretemp`、`k10temp` 和 `zenpower`。
