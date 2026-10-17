"""Run with: python3 -m unittest discover -s tests -v (Node.js required)."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class TemperatureUtilsTests(unittest.TestCase):
    def test_parsing_and_settings(self):
        source = (ROOT / "TemperatureUtils.js").read_text().replace(".pragma library", "")
        checks = r"""
const assert = require('node:assert/strict');
for (const [raw, expected] of [['45000\n', 45], ['0', 0], ['150000', 150], [' 52500 ', 52.5]])
  assert.equal(parseTemperature(raw), expected);
for (const raw of ['', '  \n', 'oops', 'NaN', 'Infinity', '1e3', '0x10', '45000oops', '-1000', '150001'])
  assert.ok(Number.isNaN(parseTemperature(raw)), JSON.stringify(raw));
for (const value of ['', ' ', 'bad', null, undefined, true, {}, [], Infinity, NaN])
  assert.equal(boundedInteger(value, 15000, 1000, 60000), 15000);
assert.equal(boundedInteger('5000', 15000, 1000, 60000), 5000);
assert.equal(boundedInteger(0, 15000, 1000, 60000), 1000);
assert.equal(boundedInteger(999999, 15000, 1000, 60000), 60000);
assert.equal(boundedInteger(85.6, 85, 50, 110), 86);
assert.equal(boundedInteger(-1, 85, 50, 110), 50);
assert.equal(boundedInteger(120, 85, 50, 110), 110);
"""
        subprocess.run(["node", "-e", source + checks], check=True)

    def test_manifest_defaults_match(self):
        manifest = json.loads((ROOT / "manifest.json").read_text())
        self.assertEqual(manifest["barWidget"]["defaults"],
                         {"pollInterval": 15000, "warningTemperature": 85})


class DiscoveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def device(self, index, driver, labels):
        path = self.root / f"hwmon{index}"
        path.mkdir()
        (path / "name").write_text(driver + "\n")
        for number, label in enumerate(labels, 1):
            (path / f"temp{number}_input").write_text("45000\n")
            if label is not None:
                (path / f"temp{number}_label").write_text(label + "\n")
        return path

    def discover(self):
        result = subprocess.run(["sh", str(ROOT / "discover-sensors.sh"), str(self.root)],
                                check=True, text=True, capture_output=True)
        self.assertEqual(result.stderr, "")
        return [line.split("\t") for line in result.stdout.splitlines()]

    def test_empty(self):
        self.assertEqual(self.discover(), [])

    def test_intel_and_excluded_devices(self):
        cpu = self.device(0, "coretemp", ["Package id 0", "Core 0", None])
        self.device(1, "nvme", ["Composite"])
        self.device(2, "amdgpu", ["edge"])
        self.assertEqual(self.discover(), [
            ["coretemp", label, str(cpu / f"temp{i}_input")]
            for i, label in enumerate(["Package id 0", "Core 0", "temp3"], 1)
        ])

    def test_amd_prefers_tdie_on_same_device(self):
        self.device(0, "k10temp", ["Tctl", "Tdie", "Tccd1"])
        self.device(1, "zenpower", ["Tctl"])
        self.assertEqual([(r[0], r[1]) for r in self.discover()],
                         [("k10temp", "Tdie"), ("k10temp", "Tccd1"), ("zenpower", "Tctl")])

    def test_missing_input_and_late_driver(self):
        self.assertEqual(self.discover(), [])
        cpu = self.device(0, "coretemp", ["Core 0", "Core 1"])
        (cpu / "temp1_input").unlink()
        self.assertEqual([r[1] for r in self.discover()], ["Core 1"])
        (cpu / "temp2_input").unlink()
        self.assertEqual(self.discover(), [])


if __name__ == "__main__":
    unittest.main()
