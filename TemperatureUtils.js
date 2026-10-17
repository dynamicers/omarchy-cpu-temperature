.pragma library

function parseTemperature(text) {
  var raw = String(text).trim()
  if (!/^-?\d+$/.test(raw)) return NaN
  var temperature = Number(raw) / 1000
  return isFinite(temperature) && temperature >= 0 && temperature <= 150
    ? temperature : NaN
}

function boundedInteger(value, fallback, minimum, maximum) {
  if (typeof value !== "number" && typeof value !== "string") return fallback
  if (typeof value === "string" && !value.trim()) return fallback
  var number = Number(value)
  if (!isFinite(number)) return fallback
  return Math.max(minimum, Math.min(maximum, Math.round(number)))
}
