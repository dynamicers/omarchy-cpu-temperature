#!/usr/bin/env python3
"""Read CPU-only hwmon temperatures without privileges or extra packages."""
import json
from pathlib import Path


def read_temperatures(hwmon_root=Path('/sys/class/hwmon')):
    readings = []
    for device in sorted(hwmon_root.glob('hwmon*')):
        try:
            driver = (device / 'name').read_text().strip()
        except OSError:
            continue
        if driver not in {'coretemp', 'k10temp', 'zenpower'}:
            continue
        for sensor in sorted(device.glob('temp*_input')):
            try:
                temperature = int(sensor.read_text().strip()) / 1000
                # Invalid firmware sentinel values are not temperatures.
                if not 0 <= temperature <= 150:
                    continue
                label_path = sensor.with_name(sensor.name.replace('_input', '_label'))
                try:
                    label = label_path.read_text().strip()
                except OSError:
                    label = sensor.stem.replace('_input', '')
                # Tctl can include an artificial fan-control offset on AMD.
                if driver in {'k10temp', 'zenpower'} and label == 'Tctl':
                    if any(p.read_text().strip() == 'Tdie' for p in device.glob('temp*_label')):
                        continue
                readings.append({'label': f'{driver}: {label}', 'temperature': temperature})
            except (OSError, ValueError):
                continue
    return {'temperature': max((r['temperature'] for r in readings), default=None),
            'sensors': readings}


if __name__ == '__main__':
    print(json.dumps(read_temperatures(), ensure_ascii=False))
