---
name: Monochrome Neo-Tech
colors:
  surface: '#f9f9ff'
  surface-dim: '#d3daea'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f3ff'
  surface-container: '#e7eefe'
  surface-container-high: '#e2e8f8'
  surface-container-highest: '#dce2f3'
  on-surface: '#151c27'
  on-surface-variant: '#4c4546'
  inverse-surface: '#2a313d'
  inverse-on-surface: '#ebf1ff'
  outline: '#7e7576'
  outline-variant: '#cfc4c5'
  surface-tint: '#5e5e5e'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#1b1b1b'
  on-primary-container: '#848484'
  inverse-primary: '#c6c6c6'
  secondary: '#575e70'
  on-secondary: '#ffffff'
  secondary-container: '#d9dff5'
  on-secondary-container: '#5c6274'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#1b1b1b'
  on-tertiary-container: '#848484'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e2e2e2'
  primary-fixed-dim: '#c6c6c6'
  on-primary-fixed: '#1b1b1b'
  on-primary-fixed-variant: '#474747'
  secondary-fixed: '#dce2f7'
  secondary-fixed-dim: '#c0c6db'
  on-secondary-fixed: '#141b2b'
  on-secondary-fixed-variant: '#404758'
  tertiary-fixed: '#e2e2e2'
  tertiary-fixed-dim: '#c6c6c6'
  on-tertiary-fixed: '#1b1b1b'
  on-tertiary-fixed-variant: '#474747'
  background: '#f9f9ff'
  on-background: '#151c27'
  surface-variant: '#dce2f3'
typography:
  display-hero:
    fontFamily: Inter
    fontSize: 3rem
    fontWeight: '700'
    lineHeight: 3.5rem
    letterSpacing: -0.03em
  display-hero-mobile:
    fontFamily: Inter
    fontSize: 2.25rem
    fontWeight: '700'
    lineHeight: 2.75rem
    letterSpacing: -0.025em
  headline-lg:
    fontFamily: Inter
    fontSize: 2rem
    fontWeight: '700'
    lineHeight: 2.5rem
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 1.5rem
    fontWeight: '700'
    lineHeight: 2rem
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 1.375rem
    fontWeight: '600'
    lineHeight: 1.75rem
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Inter
    fontSize: 1.125rem
    fontWeight: '600'
    lineHeight: 1.5rem
    letterSpacing: -0.01em
  metric-numeral:
    fontFamily: Inter
    fontSize: 1.75rem
    fontWeight: '700'
    lineHeight: 2.25rem
    letterSpacing: -0.02em
  body-lg:
    fontFamily: Inter
    fontSize: 1rem
    fontWeight: '400'
    lineHeight: 1.5rem
  body-md:
    fontFamily: Inter
    fontSize: 0.875rem
    fontWeight: '400'
    lineHeight: 1.25rem
  body-sm:
    fontFamily: Inter
    fontSize: 0.75rem
    fontWeight: '400'
    lineHeight: 1rem
  label-lg:
    fontFamily: Inter
    fontSize: 0.875rem
    fontWeight: '600'
    lineHeight: 1.25rem
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 0.75rem
    fontWeight: '500'
    lineHeight: 1rem
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 0.6875rem
    fontWeight: '600'
    lineHeight: 0.875rem
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.5rem
  gutter-sm: 1rem
  gutter-lg: 2rem
  margin: 1.5rem
  margin-mobile: 1rem
  margin-desktop: 2.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 3rem
---

## Brand & Style

This design system delivers a clinical, high-conviction fintech and Web3 utility experience. Built around a disciplined neo-brutalist and hyper-minimalist philosophy, it pairs stark monochromatic contrast with precise geometry. The aesthetic avoids decorative gradients and saturated accent fills, allowing high-value metrics, dense financial data tables, and transactional workflows to command absolute clarity.

Targeting institutional traders, protocol engineers, and modern DeFi operators, the UI conveys mathematical authority, security, and razor-sharp efficiency. The style blends flat structural layouts, obsidian-black block elements, subtle 1px structural hairpins, and generous border radii (rounded-2xl to rounded-3xl) to synthesize the raw power of neo-brutalism with the refined usability of contemporary high-density SaaS.

## Colors

The system uses a strictly controlled achromatic spectrum to establish strong hierarchy:

- **Primary Canvas & Backgrounds:** Crisp `#FFFFFF` surfaces contrasted against light container tones (`#F9FAFB` and `#F3F4F6`).
- **Obsidian Accent Blocks:** Solid jet `#000000` and midnight `#111827` used for high-impact metric summary cards, primary actions, floating status bars, and active navigation nodes.
- **Hairlines & Boundaries:** `#E5E7EB` applied at 1px width across cards, inputs, tab bars, and dividing rules to delineate space without visual noise.
- **Typography Spectrum:** High-contrast pitch `#000000` for primary headings and hero numbers, deep `#111827` for body copy, `#4B5563` for subheaders, and neutral muted `#6B7280` or `#9CA3AF` for captions and data labels.
- **Semantic Badges:** Strict grayscale indicators, using subtle light gray pills (`#F3F4F6`) or dark contrast pills (`#000000` with `#FFFFFF` text) to communicate state without introducing competing hues.

## Typography

Typography prioritizes legibility, systematic spacing, and stark numerical impact. Inter is leveraged throughout all typographic scales to maintain uniform technical precision.

- **Numerals & Metrics:** Large tabular numbers are tightly tracked with negative letter-spacing to emphasize high volumes, yields, and token balances.
- **Micro-Labels & Metadata:** Captions, column headers, and stat indicators sit in `label-sm` or `label-md` with slight positive tracking, rendered in uppercase or title-case to maintain instant scannability against dense data arrays.
- **Hierarchy Enforcement:** Headline weights favor SemiBold (`600`) and Bold (`700`) to anchor white space and counterbalance dark structural panels.

## Layout & Spacing

The layout is built upon an intentional multi-tier structural canvas:

- **Desktop (1280px+):** A 12-column layout organized around a left-pinned navigation rail (240px fixed width), a flexible central interaction workspace (spanning 7-8 columns), and an obsidian right-hand analytical sidebar (spanning 4-5 columns) that houses key protocol figures, quick earnings ribbons, and system-level telemetry.
- **Tablet (768px - 1024px):** A responsive 8-column layout. The primary navigation compresses to an iconography bar, and secondary summary blocks tuck below the active functional card.
- **Mobile (<768px):** A single-column vertical flow with full-width cards, a sticky header containing wallet connect triggers and a compact hamburger menu, paired with pinned bottom action sheets for critical transactions.
- **Internal Component Spacing:** Strict adherence to 4px and 8px base multiples keeps data listings, table cells, and button padding rhythmically synchronized across light and dark elements.

## Elevation & Depth

This system avoids soft multi-layer drop shadows and glowing neon blurs, relying instead on planar juxtaposition, pure contrast, and crisp borders:

- **Base Elevation:** The primary viewport background sits at pure `#FFFFFF` or subtle off-white `#F9FAFB`.
- **Card Enclosures:** Light mode cards rely on `#FFFFFF` surfaces defined by crisp 1px `#E5E7EB` hairline borders without box shadows.
- **Obsidian Dark Surfaces:** High-contrast `#000000` cards create perceptual depth through tonal weight rather than blur-based elevation.
- **Floating Modals & Snackbars:** Elevated utility bars and modals use solid boundaries with an ultra-subtle offset keyline (`0 4px 20px -2px rgba(0, 0, 0, 0.06)`), retaining a sharp, tactile graphic quality.

## Shapes

The geometry balances the cold, rectilinear discipline of brutalist grids with approachable, ergonomic contours:

- **Primary Cards & Panels:** Generously rounded at `1.25rem` to `1.75rem` (`rounded-2xl` to `rounded-3xl`), creating a modern hardware-like pebble aesthetic.
- **Action Buttons & Inputs:** Form fields, interactive buttons, and segment tabs adopt uniform `0.75rem` (`rounded-xl`) to `1rem` corner rounding.
- **Pills & Badges:** Token tags, status markers, and network pills utilize complete full-radius geometry (`9999px`) for quick peripheral recognition.
- **Outer Shell:** The application container utilizes an outer display viewport border radius on native wrappers and desktop tablet views.

## Components

### Buttons
- **Primary:** Solid jet-black (`#000000`) background, crisp white typography (`#FFFFFF`), `1rem` height padding, subtle hover transitions to `#1F2937`.
- **Secondary / Outlined:** Crisp white background with a 1px `#E5E7EB` border, pitch black text, shifting to a `#F9FAFB` fill on hover.
- **Full Width Actions:** High-priority execution triggers (e.g., "Stake HUMP", "Connect Wallet") span 100% container width with bold typography and full tactile feedback.

### Input Fields & Segmented Controls
- **Data Inputs:** Framed by 1px `#E5E7EB` borders, clear `#F9FAFB` or `#FFFFFF` fills, interior right-aligned max-value action buttons, and large tabular numerals.
- **Tab Switches (Stake / Unstake):** Enclosed inside a shared light-gray track (`#F3F4F6`), using an active white capsule card with a subtle border to indicate current state.

### Data Cards & Metric Displays
- **Light Theme Workspace Cards:** Clean white panels framed with `#E5E7EB` boundaries housing detailed parameter listings and balance breakdowns.
- **Obsidian Metric Cards:** Deep black panels featuring stacked white metrics (`metric-numeral`), subtle gray micro-labels (`#9CA3AF`), circular action glyph buttons (such as arrow breakouts), and integrated sparkline indicators.

### Tables & Data Grids
- **Header:** Uppercase `label-sm` text pinned above a 1px border.
- **Row Elements:** Minimal 1px hairline dividers with token icons, left-aligned asset metadata, right-aligned monetary values, and pill action buttons (`Bond`, `Claim`).

### Chips & Badges
- **Status Pills:** Pill-shaped tags (`rounded-full`) showing network status, verification marks (`KYC Verified`), and token conversion ratios with minimal icon pairings.