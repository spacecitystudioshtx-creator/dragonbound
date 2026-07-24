## Dragonbound 60/30/10 fire-red master palette. Autoloaded as ThemeColors.
##
## 60% — volcanic earth (world backgrounds, field ground, shadows)
## 30% — fire red (UI panels, borders, buildings, structural elements)
## 10% — hot accents (HP/XP bars, text highlights, type indicators)

extends Node

# ── 60% Volcanic earth ────────────────────────────────────────────────────────
const EARTH_DEEP     := Color(0.10, 0.06, 0.02)  ## #1a0f05 deep ash black
const EARTH_VOLCANIC := Color(0.24, 0.11, 0.03)  ## #3d1c08 volcanic brown
const EARTH_WARM     := Color(0.48, 0.25, 0.13)  ## #7a4020 warm stone
const EARTH_AMBER    := Color(0.77, 0.47, 0.25)  ## #c47840 dusty amber

# ── 30% Fire red ─────────────────────────────────────────────────────────────
const RED_DEEP       := Color(0.55, 0.08, 0.00)  ## #8b1400 deep crimson
const RED_TRUE       := Color(0.80, 0.19, 0.06)  ## #cc3010 fire red
const RED_EMBER      := Color(0.91, 0.38, 0.19)  ## #e86030 ember orange
const GRAY_IRON      := Color(0.31, 0.38, 0.38)  ## #4f6161 iron gray

# ── 10% Hot accents ───────────────────────────────────────────────────────────
const GOLD_FIRE      := Color(1.00, 0.63, 0.19)  ## #ffa030 fire gold (HP/EXP)
const GOLD_BRIGHT    := Color(1.00, 0.82, 0.38)  ## #ffd060 bright ember
const WHITE          := Color(1.00, 1.00, 1.00)  ## pure white
const BLUE_SKY       := Color(0.31, 0.56, 0.82)  ## #5090d0 water type / sky
const GREEN_NATURE   := Color(0.25, 0.75, 0.38)  ## #40c060 nature type

# ── Battle field ──────────────────────────────────────────────────────────────
const FIELD_SKY := [
	Color(0.12, 0.05, 0.02),  ## band 0 — near-black top
	Color(0.20, 0.08, 0.03),  ## band 1
	Color(0.33, 0.13, 0.05),  ## band 2
	Color(0.52, 0.20, 0.06),  ## band 3 — ember horizon
]
const FIELD_GROUND   := Color(0.20, 0.08, 0.03)  ## volcanic ash ground
const FIELD_PLATFORM := Color(0.42, 0.18, 0.07)  ## slightly lighter rock

# ── UI surfaces ───────────────────────────────────────────────────────────────
const UI_PANEL       := Color(0.11, 0.05, 0.02)  ## dark panel background
const UI_BORDER      := Color(0.55, 0.08, 0.00)  ## RED_DEEP border
const UI_TEXT        := Color(1.00, 0.92, 0.78)  ## warm cream text
const UI_TEXT_DIM    := Color(0.70, 0.55, 0.38)  ## dimmed label text
const UI_DIVIDER     := Color(0.42, 0.06, 0.00)  ## subtle inner divider

const UI_BTN         := Color(0.18, 0.08, 0.03)  ## button default bg
const UI_BTN_BORDER  := Color(0.65, 0.10, 0.01)  ## button border
const UI_BTN_HOVER   := Color(0.35, 0.14, 0.05)  ## hover bg
const UI_BTN_PRESS   := Color(0.55, 0.22, 0.08)  ## pressed bg (ember glow)

# ── HP / XP bars ─────────────────────────────────────────────────────────────
const HP_HIGH        := Color(0.30, 0.90, 0.30)  ## bright green
const HP_MED         := Color(0.95, 0.85, 0.10)  ## yellow
const HP_LOW         := Color(0.95, 0.18, 0.08)  ## danger red
const HP_BG          := Color(0.07, 0.03, 0.01)  ## very dark track

const XP_BAR         := Color(0.25, 0.50, 0.95)  ## blue XP (FireRed style)
const XP_BG          := Color(0.07, 0.03, 0.01)  ## same dark track

# ── Move button type backgrounds (dark tints) ─────────────────────────────────
const MOVE_BG := {
	"fire":   Color(0.42, 0.12, 0.04),
	"water":  Color(0.07, 0.15, 0.40),
	"nature": Color(0.08, 0.26, 0.08),
	"normal": Color(0.16, 0.08, 0.03),
}
const MOVE_HOVER := {
	"fire":   Color(0.58, 0.18, 0.06),
	"water":  Color(0.10, 0.22, 0.55),
	"nature": Color(0.12, 0.36, 0.12),
	"normal": Color(0.26, 0.12, 0.05),
}
const MOVE_PRESS := {
	"fire":   Color(0.78, 0.28, 0.10),
	"water":  Color(0.15, 0.32, 0.72),
	"nature": Color(0.18, 0.52, 0.18),
	"normal": Color(0.38, 0.18, 0.07),
}

# ── Drake sprite placeholder tints ───────────────────────────────────────────
const DRAKE_FIRE   := Color(0.90, 0.35, 0.10)
const DRAKE_WATER  := Color(0.15, 0.45, 0.90)
const DRAKE_NATURE := Color(0.20, 0.75, 0.25)
