.pragma library

function pad(n) { return n < 10 ? "0" + n : String(n) }

// Hela sekunder som "MM:SS", eller "H:MM:SS" från en timme.
function clock(totalSeconds) {
  var s = Math.max(0, Math.floor(totalSeconds))
  var h = Math.floor(s / 3600)
  var m = Math.floor((s % 3600) / 60)
  var sec = s % 60
  return (h > 0 ? h + ":" + pad(m) : pad(m)) + ":" + pad(sec)
}

// Kvarvarande tid avrundas uppåt: 05:00 vid start, 00:00 när den slår.
function remaining(ms) { return clock(Math.ceil(Math.max(0, ms) / 1000)) }

function label(ms) {
  var s = Math.round(ms / 1000)
  var h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), sec = s % 60
  var parts = []
  if (h) parts.push(h + " h")
  if (m) parts.push(m + " min")
  if (sec) parts.push(sec + " s")
  return parts.length ? parts.join(" ") : "0 s"
}

// Tolkar "25", "25:00", "1:30:00", "90s", "1h30m", "10m". Returnerar sekunder eller -1.
function parse(text) {
  var t = String(text || "").trim().toLowerCase().replace(/\s+/g, "")
  if (t === "") return -1
  if (/^\d+$/.test(t)) return parseInt(t, 10) * 60
  if (/^\d+(:\d{1,2}){1,2}$/.test(t)) {
    var p = t.split(":").map(function(x) { return parseInt(x, 10) })
    return p.length === 2 ? p[0] * 60 + p[1] : p[0] * 3600 + p[1] * 60 + p[2]
  }
  var m = t.match(/^(?:(\d+)h)?(?:(\d+)m(?:in)?)?(?:(\d+)s)?$/)
  if (m && (m[1] || m[2] || m[3]))
    return (parseInt(m[1] || 0, 10) * 3600) + (parseInt(m[2] || 0, 10) * 60) + parseInt(m[3] || 0, 10)
  return -1
}
