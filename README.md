# oma.timer

Nedräkningstimer för Omarchy-baren. Du ställer in tiden själv, ingen tidtagning/stoppur.
När tiden är ute kommer en signal: ljud (upprepas tills du kvitterar, max 6 gånger), en notis och ikonen blinkar i baren tills du kvitterar. Klicka på notisen eller "Kvittera" i panelen så tystnar ljudet direkt.

## Installation

### Installera från GitHub

```bash
omarchy plugin add https://github.com/nmlit/oma.timer.git --enable
```

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
- Snabbvalen (+1m, +3m, +5m, +10m, +15m, +25m, +45m, +60m) **lägger till** tid på den inställda tiden,
  så du kan klicka flera gånger: t.ex. 2 × 60m + 10m + 5m = 135 minuter (2:15:00). Max 24 timmar.
  Timern börjar på 00:00. **Nollställ** (eller `r`) när timern är stoppad sätter tiden till 0 igen;
  när den går/är pausad avbryter Nollställ nedräkningen och behåller den inställda tiden.
- **Ändra tiden medan timern går (1.0.3):** snabbvalen (+1m … +60m), −1m/−10s/+10s/+1m,
  j/k, h/l och scrollhjulet fungerar även när timern räknar ner eller är pausad. Tiden läggs till
  (eller dras av) på den kvarvarande tiden direkt, utan att nedräkningen stannar eller nollställs.
  Minus kan som lägst ta ner kvarvarande tid till 0 – då slår timern som vanligt (ljud + notis).
  Max 24 timmar kvar. När timern har slagit måste du kvittera innan du kan ställa in ny tid.
- Tangenter: mellanslag start/paus · r nollställ · j/k ±1 min · h/l ±10 s · e egen tid · Esc stäng.

## Kommandon (IPC)

```bash
omarchy-shell -q oma.timer start 25    # starta 25 min
omarchy-shell -q oma.timer set 1h30m   # starta med valfri tid
omarchy-shell -q oma.timer pause       # start / paus
omarchy-shell -q oma.timer reset       # nollställ
omarchy-shell -q oma.timer toggle      # öppna / stäng panelen
```

Ljud: `omatimer.ogg` i pluginmappen, spelas med `pw-play`/`paplay`.

Inspirerad av [Tick](https://github.com/ivanvan08) av ivanvan08.

## Licens

MIT
