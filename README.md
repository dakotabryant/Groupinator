# Groupinator

A World of Warcraft addon that gives you full control over the LFG Premade Groups listing. Groupinator adds a filtering panel alongside the default group browser, letting you narrow results by difficulty, group composition, rating, lockouts, and more. Power users can write Lua filter expressions to define exactly which groups appear.

### What You Can Do

* Find Mythic+ groups that still need your role and match your rating range
* Show only fresh raid listings with specific boss progression
* Filter arena groups by leader rating bracket
* Hide groups that previously declined you
* Sign up to groups with a single click

### Standard Filters

* **Difficulty** — Normal, Heroic, Mythic, Mythic+, Arena 2v2/3v3
* **Composition** — Number of tanks, healers, and DPS already in the group
* **Member Count** — Minimum and maximum group size
* **Rating** — Mythic+ score or PvP rating of the group leader
* **Raid Progress** — Number of bosses defeated
* **Dungeon & Raid Selection** — Filter to a specific instance
* **Playstyle** — Standard, Casual, or Hardcore tags
* **Delve Tier** — Filter delve groups by tier

### Advanced Expression Engine

For cases where the standard filters aren't enough, Groupinator provides an expression box that accepts Lua filter expressions evaluated against 150+ group properties.

```
mythic and tanks >= 1 and heals >= 1 and members < 5
```

```
heroic and defeated == 0 and members >= 10
```

Expressions support all Lua operators (`and`, `or`, `not`, `>=`, `==`, etc.) and can reference any keyword — difficulty flags, role counts, ratings, activity IDs, instance abbreviations, and more.

### UI Enhancements

| Feature | Description |
|---------|-------------|
| **Class Names in Tooltip** | Role-grouped class list in the group tooltip |
| **Colored Group Names** | Green for new groups, red for declined, orange for soft-declined |
| **Freshness Indicators** | Green dot for groups posted < 2 min ago, yellow for < 10 min |
| **Class Color Bars** | Thin class-colored bar under each role icon |
| **Leader Crown** | Small crown icon above the group leader's role |
| **Leader Rating** | M+ or PvP rating displayed inline in the group list |
| **Raider.IO Colors** | Rating text colored using Raider.IO's color scheme (requires Raider.IO) |
| **Specialization Icons** | Spec icon for each group member |
| **Missing Role Slots** | Empty role icons showing what the group still needs |

### Sign-Up Options

| Feature | Description |
|---------|-------------|
| **One Click Sign Up** | Click a group to apply immediately |
| **Skip Sign Up Dialog** | Bypass the role/note prompt (hold Shift to override) |
| **Persist Sign Up Note** | Keep your note across different applications |
| **Sign Up On Enter** | Auto-focus the note field and confirm with Enter |
| **Cancel Oldest Application** | Auto-cancel your oldest pending app when at the cap |
| **Apply to Declined Groups** | Re-apply to groups that previously declined you |

### Optional Plugin Support

* **Raider.IO** — Displays M+ ratings, key levels, and Raider.IO color coding when the addon is loaded.
* **PremadeRegions** — Adds region and language information (US/EU/etc.) to group data.

### Testing

Groupinator includes an automated test suite using [Busted](https://lunarmodules.github.io/busted/) and LuaJIT. Tests cover the expression engine, all utility functions, and string matching logic.

```bash
# Install dependencies (one time)
brew install luajit luarocks
luarocks install --lua-dir=$(brew --prefix luajit) busted

# Run tests
eval "$(luarocks path --lua-version 5.1)"
busted --verbose
```

### Installation

Install from your preferred addon manager, or copy the `Groupinator` folder into your WoW addons directory:

```
World of Warcraft/_retail_/Interface/AddOns/Groupinator/
```

### License

Released under the GNU General Public License, Version 2. See the `LICENSE` file for details.
