# Building the HTML explorer

Copy `assets/template.html` and fill the two content regions. The template already
carries the theme system, the tree behavior, and the highlight. Do not rebuild them.

## Layout contract

```
.shell  grid  340px | minmax(0,1fr)     full viewport height, no page scroll
  aside.tree     left, own scroll, sticky header
  main.pane      right, own scroll, holds every section
```

`minmax(0,1fr)` on the second column is required. Plain `1fr` gives grid children a
default `min-width:auto`, and one long unbreakable path then pushes the pane wider
than the viewport.

## Left tree

Mirror the real navigation, not your document outline. A reader should recognize the
menu they clicked in the product.

```html
<a class="d1" href="#t-menu"><span class="g">▾</span> 학생 &gt; 학급 분석<span class="tag t">교사</span></a>
<a class="d2" href="#m1"><span class="g">├─</span> 학급 단원별 학습 현황</a>
<a class="d3" href="#m1-avg"><span class="g">│&nbsp;&nbsp;├─</span> 평균 점수<span class="tag b">배치</span></a>
<a class="d3" href="#m1-list"><span class="g">│&nbsp;&nbsp;└─</span> 평가 목록<span class="tag l">실시간</span></a>
```

- `d1` `d2` `d3` are depth. Indentation comes from the box-drawing glyph, not padding,
  so the rail stays aligned at every depth.
- `.tag` on a leaf carries its data origin. This makes batch-vs-live readable from the
  tree alone, before the reader opens anything.
- A module that exists for one role and not the other still gets a tree entry, dimmed,
  with an `없음` tag. Absence is information.

## Right pane targets

Two granularities, both handled by the template's script:

- **section target** — `href="#batch"` points at `<section id="batch">`
- **row target** — `href="#m1-avg"` points at `<tr id="m1-avg">` inside a table

Row targets are how one tree leaf lights one line of a comparison table. Use them
whenever a module splits into parts that differ in data origin.

## Highlight rules

Emphasis is **additive only**. Never recolor or fade body text to create focus.
Dimming text destroys the contrast ratios you verified for both themes.

The template lights a target with:

- a neon rail on the section's left edge, with layered glow falloff
- a directional wash gradient spilling off that rail
- a tinted field plus inset glow on a lit table row
- `text-shadow` on the section's crumb label

Non-lit regions give up only their card shadow. Their text color does not change.

One authored motion moment: the rail strikes in, the target settles under it.
Everything is suppressed under `prefers-reduced-motion`.

## Theming

Both themes are required. Dark is default; light is the daylight scene.

Every color is a custom property defined twice, on `:root,[data-theme="dark"]` and on
`[data-theme="light"]`. Nothing in the body hardcodes a hex. That includes the inline
SVG diagram, which uses `fill="var(--card2)"` and `stroke="var(--live)"` so it themes
for free.

Verify each text token against **its own surface** before writing:

```python
def lum(h):
    h=h.lstrip('#'); c=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    c=[(x/12.92 if x<=0.03928 else ((x+0.055)/1.055)**2.4) for x in c]
    return 0.2126*c[0]+0.7152*c[1]+0.0722*c[2]
def cr(a,b):
    l1,l2=sorted([lum(a),lum(b)],reverse=True); return (l1+0.05)/(l2+0.05)
```

Body text ≥4.5:1. The faint token must clear it on the page background **and** on the
card background, which are different surfaces. In light mode a warm paper background
beats pure white for long reading under office light.

`<meta name="color-scheme" content="dark light">` plus the `color-scheme` property
makes form controls and native scrollbars follow the theme.

Theme choice persists in `localStorage` and falls back to the OS preference. An OS
change only takes effect when the user has not chosen explicitly.

## Browser surfaces

Theme the parts you did not draw. These ship with browser defaults that belong to no
design system, and skipping them is the clearest tell that a page was assembled
rather than built:

`::selection`, `scrollbar-color` and the `::-webkit-scrollbar` thumb,
`:focus-visible` rings, `text-underline-offset`, and `font-variant-numeric:tabular-nums`
for the numeric tables.

## Long paths

`file:line` references have no natural break opportunity and will force overflow.

```css
.src{overflow-wrap:anywhere;word-break:break-word}
dl.kv{grid-template-columns:104px minmax(0,1fr)}
dl.kv dd{min-width:0}
.grid2 > *{min-width:0}
```

Give the pane a wide `max-width` (~1560px). Tables and code paths are the payload and
deserve the width; only running prose stays bounded, at `max-width:72ch` on `p.lead`.

Let the card pair reflow on its own:
`grid-template-columns:repeat(auto-fit,minmax(min(100%,340px),1fr))`. A floor above
~380px collapses the pair to one column on a 1280px viewport.

## Callouts

`.note` variants: default warning, `.ok`, `.bad`, `.info`.

Use a 1px rule plus a tinted field, never a thick colored bar. A colored `border-left`
above 1px is a stock pattern that reads as decoration.

## Print

Tree and theme button hide. The pane stops being a scroll container. Cards drop their
shadow and get `break-inside:avoid`. Highlight dimming is neutralized.
