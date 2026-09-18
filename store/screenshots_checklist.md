# Screenshot Checklist

**Honesty note:** this build environment has no Flutter SDK, so no
screenshots could be captured from a real running instance of the
app — anything generated here would be a mockup, not an accurate
representation of the actual UI, which would be misleading to include
in a store listing. Once you've run the app locally (see the main
README's "Running it" section), capture real screenshots yourself
using this checklist.

## Required sizes

- **Google Play**: at least 2 screenshots, 16:9 or 9:16, minimum
  320px on the short side, maximum 3840px on the long side.
- **Apple App Store**: at least 1 screenshot per required device size
  (currently 6.7" and 6.5" iPhone displays are mandatory; iPad if you
  support tablets).

## Recommended screens to capture (in this order)

1. **Home screen** — shows the Popular/New game grid; this is the
   first thing users see and should showcase variety.
2. **A game in progress** — pick a visually distinctive one (Tetris
   Lite, 2048, or Alien Shooter all read well at thumbnail size).
3. **Profile screen** — shows the level/XP bar and achievements list,
   demonstrating the progression system.
4. **Games screen with search/category filter** — shows the breadth
   of the 50-game catalog.
5. **A second game in progress** — ideally from a different category
   than screenshot #2 (e.g. Sudoku or Wordle if #2 was arcade).
6. *(Optional)* **Downloads screen** — shows the download-manager
   flow if you want to highlight extensibility.

## Tips

- Use a real device or the Flutter/Android/iOS simulator at native
  resolution — don't upscale.
- Turn on dark OR light mode consistently across all shots (pick
  whichever looks better in your generated icon/splash).
- Avoid capturing the Admin Panel or Settings screen as a primary
  screenshot — they're functional, not visually compelling for a
  store listing.
- If you add device-frame chrome or marketing text overlays, keep the
  actual app UI area accurate — stores reject screenshots that
  misrepresent the app.
