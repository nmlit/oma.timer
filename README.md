# oma.timer

Nedräkningstimer för Omarchy-baren. Du ställer in tiden själv, ingen tidtagning/stoppur.
När tiden är ute kommer en signal: ljud (spelas 3 gånger), en notis och ikonen blinkar i baren tills du kvitterar.

## Installation

```bash
git clone https://github.com/nmlit/oma.timer
mkdir -p ~/.config/omarchy/plugins/oma.timer
cp -a oma.timer/* ~/.config/omarchy/plugins/oma.timer/
omarchy plugin enable oma.timer
omarchy-restart-shell
```

## Användning

- **Vänsterklick** på ikonen: öppnar panelen.
- **Högerklick**: start / paus. **Mittenklick**: nollställ.
- I panelen: snabbval (1–60 min), −1m/−10s/+10s/+1m, scrollhjul på siffrorna (±1 min),
  eller skriv en egen tid i fältet och tryck Enter: `25` (minuter), `7:30`, `1:15:00`, `1h30m`, `90s`.
- Tangenter: mellanslag start/paus · r nollställ · j/k ±1 min · h/l ±10 s · e egen tid · Esc stäng.

## Kommandon (IPC)

```bash
omarchy-shell -q oma.timer start 25    # starta 25 min
omarchy-shell -q oma.timer set 1h30m   # starta med valfri tid
omarchy-shell -q oma.timer pause       # start / paus
omarchy-shell -q oma.timer reset       # nollställ
omarchy-shell -q oma.timer toggle      # öppna / stäng panelen
```

Ljud: `/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga` (paketet `sound-theme-freedesktop`), spelas med `pw-play`/`paplay`.

Inspirerad av [Tick](https://github.com/ivanvan08) av ivanvan08.

## Licens

MIT
