# omarchy-cpu-temperature

[English](README.md)

用户自有的 Omarchy 状态栏插件（`omarchy-cpu-temperature`）。从 Linux hwmon
设备的 `coretemp`、`k10temp` 或 `zenpower` 驱动读取 CPU 封装及核心的当前温度，
并显示其中的最高值。不会读取 GPU、SSD 或芯片组传感器。
AMD 同时提供 Tdie 和 Tctl 时会忽略 Tctl，因为 Tctl 可能包含用于温控的偏移量。
无需 sudo、第三方 Python 包或 `sensors` 命令。

- 默认每 3 秒刷新一次；鼠标左键点击可立即刷新。
- 鼠标悬停时显示所有 CPU 温度读数，单位为 °C。
- 竖向状态栏将单位显示在数值下方；横向状态栏显示为 `50°C`。
- 温度达到 85°C 时使用主题的紧急提示颜色（仅为视觉提醒，并非风扇控制阈值）。
- 读数缺失或无法读取时显示 `—`，不会保留过期数据。
- 不会修改风扇转速、温控策略或 CPU 电源设置。

## 设置

配置保存在 `~/.config/omarchy/shell.json` 中，可通过以下命令修改：

```sh
omarchy bar set omarchy-cpu-temperature pollInterval 5000
omarchy bar set omarchy-cpu-temperature warningTemperature 90
```

`pollInterval` 的单位为毫秒，`warningTemperature` 的单位为 °C。

## 启用、定位或禁用

```sh
omarchy-shell shell rescanPlugins
omarchy plugin enable omarchy-cpu-temperature --after omarchy-rime-keyboard-layout
omarchy plugin disable omarchy-cpu-temperature
```

## 查看原始读数

```sh
python3 ~/.config/omarchy/plugins/omarchy-cpu-temperature/read-temperature.py
```
