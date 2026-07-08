# WAP Landing Page — Design Spec

Date: 2026-07-08

---

## Overview

A marketing/brand landing page for The W App (WAP), living inside the `wingme-copy` repo. No single hard CTA — the page explains WAP to two audiences (attendees and event/venue organizers) and captures leads segmented by role for business-development purposes. Built to evolve later into a lightweight web-based demo/onboarding surface, without that build happening now.

---

## 1. Location & Stack

- New subfolder: `wingme-copy/landing/`
- **Framework**: Vite + React + TypeScript
- **Styling**: Tailwind CSS + shadcn/ui components where useful
- **Animation**: GSAP (core, timeline, ScrollTrigger, Draggable as needed) — used for the hero drag interactions and the sponsor-logo cursor trail
- **Data**: New, standalone Supabase project (separate from the WAP app's production Supabase project) — used only for landing-page lead capture
- This introduces a build step (`npm run dev`, `npm run build`), a deliberate departure from a zero-build static site, justified by the interactive hero

---

## 2. Visual Language

Matches the app's own design system (see `docs/superpowers/specs/2026-07-02-wap-design.md` and the WAP design-system memory) so the site reads as WAP, not a generic template:

- **Background**: pure black
- **Accent**: cyan/teal (borders, highlights, active states)
- **Type**: bold, white, high-contrast
- **Brand mark**: the geometric two-dot "W" mark (from `wap logo/8.png` / `9.png`) used in nav, footer, and as a recurring motif — distinct from the old winged Wingme.app logo
- **Imagery**: no real app screenshots yet (still being finalized) — use icon-driven graphics and the interactive hero itself to represent product value. Swap in real screens later without changing layout.

---

## 3. Page Structure

Single scrolling page, sections top to bottom:

### 3.1 Nav
- W mark (left)
- Minimal links jumping to the Attendees and Organizers sections

### 3.2 Hero — Interactive Crowd
- 13 draggable stick figures scattered across the top of the hero, like an event mixer crowd
  - Mixed attire: roughly half wearing a tie, half in a business dress
  - Idle animation: gentle bob/sway (GSAP) so the crowd feels alive at rest
- Below the crowd: 4 labeled drop zones, side by side — **WHO** · **QR Connect** · **Live Feed** · **Rewards**
- Interaction: dragging a figure into a zone (GSAP Draggable)
  - Zone lights up (cyan border/glow)
  - A short value-prop line fades in under the zone title:
    - WHO → "See who's already in the room"
    - QR Connect → "Trade contacts in one tap"
    - Live Feed → "Post and see what's happening live"
    - Rewards → "Unlock perks as you engage"
  - The dropped figure plays a short built-in gesture animation tied to that zone:
    - WHO → raises a hand, "!" pops above its head
    - QR Connect → holds up a phone with a QR glyph
    - Live Feed → a speech bubble pops from the figure
    - Rewards → holds up a trophy/coin
- Figures can be re-dragged to a different zone (swaps that zone's demo state); multiple figures can occupy the same zone; reloading the page resets the crowd to its starting scatter

### 3.3 Sponsors
- Full-bleed black section
- Large centered headline: "Engage sponsors like never before."
- As the visitor moves the mouse across the section, placeholder sponsor logos spawn near the cursor and trail briefly behind it (GSAP-driven), fading out after ~1 second. Pure `mousemove`-driven, no drag/click required.

### 3.4 For Attendees
- Pitch copy covering the WHO mechanic, QR contact exchange, live feed, and gamified rewards from the attendee's point of view
- Email capture form: single email field + "Get early access" button
- On submit: writes a lead row with `track: "attendee"`, `role: null`

### 3.5 For Organizers
- Pitch copy covering venue/event hosting: check-ins, engagement analytics, admin portal, rewards administration
- Form: email field + role selector (**Event Owner / Location Owner / Organizer / Other**) + "Talk to us about your event" button
- On submit: writes a lead row with `track: "organizer"`, `role: <selected>`

### 3.6 Footer
- W mark
- Tagline: "Life Worth Living Well"
- Minimal links, copyright

---

## 4. Data Capture

New standalone Supabase project (not the WAP app's production project). Single table:

| Table | Columns |
|---|---|
| `leads` | id, email, track (attendee/organizer), role (event_owner/location_owner/organizer/other, nullable), source, created_at |

Both forms validate client-side (valid email required; role required for the organizer form) and insert directly into `leads` via the Supabase JS client. On success, show an inline "thanks, we'll be in touch" state in place of the form.

---

## 5. Future Path (not built now)

The app should use basic client-side routing (React Router or equivalent) from the start, even though it serves one page today, so that a future `/demo` or `/app` route can host a lightweight web-based version of WAP for limited-use demo/onboarding — without restructuring the landing page. That build-out is explicitly out of scope for this project; this spec only ensures the current architecture doesn't preclude it.

---

## 6. Out of Scope

- The actual webview/demo app build-out
- Real app screenshots (placeholder/graphic treatments only, for now)
- Wiring the landing page's Supabase project to the WAP app's production Supabase project (kept separate per this spec)
- Payment/billing flows
- CMS or multi-page content management — this is a single static page
