# UI audit v11 (2026-10-16)

Method: every screen captured in Studio Play Solo (lobby, Whis tutorial, Story/Raids/Ranked/Radar/Wish/Quests
panels, character select, tournament intro/ending/wish/results, every Saiyan Arrival act). Mobile layout and
the 2-client views were **not** captured (Studio MCP can't emulate devices); they are part of the rebuild checks.

## Root causes (fix these and most symptoms disappear)
1. **No screen ownership.** ~30 independent ScreenGuis with hand-picked DisplayOrders (1 to 60) and no rule
   for what may be on screen together. Cutscenes, toasts, panels and the HUD all draw at once.
2. **No layout zones.** Each script positions itself; nothing reserves space, so elements land on each other.
3. **Two UI kits, neither follows the spec.** `UIKit` (12 scripts) and `UIStyle` (13 scripts) duplicate
   colours and widgets. `POLISH_BIBLE.md` §2.5 (palette, Fredoka One / Bangers / Gotham, motion) is not applied:
   every screen is GothamBold on navy with a gold border.
4. **`TextScaled` everywhere.** Each label picks its own size, so one list mixes 12 px and 20 px rows and long
   strings shrink to unreadable sizes.

## Issues by severity
**Blocker (breaks play or readability)**
- Quests list (Daily/Weekly) has no panel, mixed text sizes, and overlaps the controls list, Stances and panels.
- Controls list and stat labels render around 8 px: unreadable at 1080p, worse on phones.
- `[Q] DASH` / `[F] GUARD` buttons cover the stat panel (Zeni value hidden).
- Gamepad hint "RIGHT STICK TO AIM" shows on PC and sits on prompts, the KO card and the clash prompt.
- Episode toasts ("PARRY!", "You overpowered him!") collide with the boss bar; clash prompt sits on its meter.
- (fixed earlier today) tournament cutscenes drawing over episodes; round banner over the episode title.

**Major (looks broken or confusing)**
- Character select: no portraits, an empty preview panel, tiny stat bars, garbled tier badge, no form ladder.
- Lobby shows everything at once: 5 menu buttons, quests, controls wall, Stances, skill bar, stats.
- Tutorial: area title overlaps the step card; "Spar with Whis" button overlaps the skill bar header.
- Every panel is the same navy box + gold border + red X: no hierarchy between a modal, a panel and a toast.
- Empty states are dead ends ("No wish pending" fills a full panel; Ranked shows "No ranked games yet").
- Episode HUD duplicates information (act counter "Act 4 / 11" counts bridge cinematics; players see 8 beats).

**Minor (polish)**
- Inconsistent capitalisation (STORY MODE / Story Mode / Daily), mixed separators (• · -), emoji in labels.
- Hover/press motion missing on most buttons; no focus state for keyboard/gamepad navigation.
- Reduce Motion is an episode-only toggle instead of a global setting.

## What works and should be kept
Boss bar shape, ground telegraphs, letterbox + speaker-coloured subtitles, the KO and clear card idea,
the episode objective checklist (after today's fix), the skill-card icons and key badges.

## Rebuild progress
- 2026-10-16: **Foundation** in place: `UIStyle` v11 kit (tokens, fixed type scale, plate/chip/action/meter/key badge,
  device-aware key hints) and `ScreenManager` (layers, nine zones, callout queue, viewport text scaling, HUD hidden in
  cinematics, `waitUntilFree` for pop-ups). **Episode HUD + clash/hold rebuilt** on it and verified in Studio
  (training, fight, K.O., clash win/lose, hold win/lose, clear). Legacy quests, nav buttons, Store/Credits, controls
  list and crosshair step aside during episodes; level-up waits for modals; crosshair hint follows the device in use.
- Next: lobby (menu rail, tracker, vitals and skill bar on the kit), Story panel, character select, remaining panels.
- Not verified yet: phone layout (needs device emulation), gamepad navigation.
