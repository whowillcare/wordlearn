
# Design Overhaul & Fixes Plan

This plan addresses the user's feedback regarding broken category selection and "off" design.

## User Review Required
> [!IMPORTANT]
> The design will be significantly upgraded to a "Premium Gamified" aesthetic, using a Glassmorphism theme with vibrant gradients.

## Proposed Changes

### Logic Fixes
#### [MODIFY] [home_screen.dart](file:///home/sam/Projects/wordlearn/flutter/lib/ui/home_screen.dart)
- **Category Selection**: Fix `ChoiceChip` logic to correctly handle boolean selection states.
- **Data Loading**: Ensure `_loadCategories` correctly populates the list. If list is empty, trigger a re-check or show a "Loading..." state that actually retries.

### Design Upgrades ("Showcase Standard")
#### [MODIFY] [home_screen.dart](file:///home/sam/Projects/wordlearn/flutter/lib/ui/home_screen.dart)
- **Background**: Replace simple linear gradient with a dynamic **Mesh Gradient** (using `CustomPainter` or complex `BoxDecoration`).
- **Glassmorphism**: Implement a reusable `GlassContainer` widget for cards (Daily Challenge, Stats).
- **Category Selector**: Replace standard `ChoiceChip` with custom **"Neon Capsule"** selectors (gradient borders, glow effects).
- **Play Button**: Redesign as a large, 3D "Hero" button with pulsing animation.
- **Typography**: Apply "Rounded" font styles for a friendly, game-like feel.

### Category & Level Refactoring
#### [MODIFY] [settings_repository.dart](file:///home/sam/Projects/wordlearn/flutter/lib/data/settings_repository.dart)
- **Game Level**: Add persistence for `game_level` (store as int index or string key).

#### [MODIFY] [settings_screen.dart](file:///home/sam/Projects/wordlearn/flutter/lib/ui/settings_screen.dart)
- **Category Selector**: Replace single-select with **Searchable Multi-Select Dialog**.
    - Search field at top.
    - Checkbox list for categories.
    - "Select All" / "Deselect All" options.
- **Level Selector**: Add persistence-backed Level selector.

#### [MODIFY] [home_screen.dart](file:///home/sam/Projects/wordlearn/flutter/lib/ui/home_screen.dart)
- **Read-Only Display**: Replace interactive toggles with read-only chips/text that display current settings.
- **Navigation**: Tapping these areas navigates to `SettingsScreen`.
