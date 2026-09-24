# Style vs position — property reference

**Rule of thumb:** if it only changes what is inside the element's border box, it is **style**. If it changes how the element sits relative to siblings or the viewport, or how children are arranged, it is **position** (belongs on the parent via `> child`).

## Style (apply on the element itself)

| Category         | Properties                                                                                                            |
| ---------------- | --------------------------------------------------------------------------------------------------------------------- |
| Typography       | `font-*`, `line-height`, `letter-spacing`, `text-*` (except where noted), `color`, `white-space`, `word-*`            |
| Box (inward)     | `padding`, `padding-*`, `border`, `border-*`, `border-radius`, `outline`, `outline-offset`, `box-shadow` (decorative) |
| Background       | `background`, `background-*`                                                                                          |
| Appearance       | `opacity`, `visibility`, `cursor`, `filter`, `backdrop-filter`, `mix-blend-mode`                                      |
| Intrinsic sizing | `box-sizing`, `object-fit`, `object-position` (on replaced elements)                                                  |
| Display (inside) | `flex`, `grid`, `inline-flex`, `inline-grid` and their longhands when laying out **children**                         |

## Position (apply on parent, target `> child`)

| Category           | Properties                                                                                                                                                            |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| External spacing   | `margin`, `margin-*`                                                                                                                                                  |
| Sizing in context  | `width`, `height`, `min-*`, `max-*`, `aspect-ratio` (when imposed by layout, not intrinsic content)                                                                   |
| Flow / placement   | `position`, `top`, `right`, `bottom`, `left`, `inset`, `z-index`, `float`, `clear`                                                                                    |
| Flex/grid child    | `flex`, `flex-grow`, `flex-shrink`, `flex-basis`, `align-self`, `justify-self`, `order`, `grid-column`, `grid-row`, `grid-area`                                       |
| Parent layout      | `display: block \| inline \| inline-block \| none`, `gap` (between siblings), `justify-content`, `align-items`, `align-content`, `place-*` on flex/grid **container** |
| Transform (layout) | `transform` when used for positioning (translate); decorative transforms on self can be style                                                                         |

## Ambiguous — decide by intent

| Property               | Guidance                                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------------------------- |
| `overflow`             | Usually **style** (clips own content); if it creates a scroll region for layout, parent may own               |
| `gap`                  | On flex/grid **container** → style on that container (it lays out its children). Not on arbitrary descendants |
| `width: 100%`          | **Position** if filling parent; intrinsic width on a button/input may be **style**                            |
| `transform: translate` | **Position** if nudging in layout; **style** if animation-only                                                |
| `vertical-align`       | **Position** (sibling alignment in line box)                                                                  |

## Anti-patterns

| Pattern                                      | Why                    | Fix                                                                    |
| -------------------------------------------- | ---------------------- | ---------------------------------------------------------------------- |
| `.btn { margin: 1rem; }` in shared button    | Assumes parent spacing | Parent: `> .btn { margin: 1rem; }` or use `gap`                        |
| `.page .widget { width: 320px; }`            | Couples widget to page | Parent: `> .widget { width: 320px; }` or let widget size intrinsically |
| Wrapper `<div class="flex">` only for layout | Layout belongs in CSS  | Parent component SCSS with `display: flex` and `> child` rules         |
