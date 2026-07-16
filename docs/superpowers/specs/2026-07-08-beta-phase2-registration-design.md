# Beta Phase 2 — Registration Screen Rebuild

## Context

Phase 2 of the beta roadmap. `RegisterVC` is still the original storyboard-based dating-app registration form (photo, name, email, country-code phone, gender buttons, birthdate picker, password/confirm, terms, plus Apple and Facebook sign-in buttons). This spec covers converting it to a programmatic WAP-styled screen (matching `OTPVerifyVC`'s pattern — dark pill fields, `Colors.black` background, `WPillButton`), collecting only what's functionally required for a minimal-friction signup. Affiliation/Industry/Role and Email are explicitly deferred to a future profile-edit screen — not collected at registration at all.

Apple Sign-In (already working, wired to `WAPAuth.signInWithApple`) and Facebook Sign-In (known-broken/deferred per earlier plans — `signInWithFacebook` passes an access token as an OIDC ID token, a runtime error) both live as buttons on this same screen today. Neither's underlying auth logic changes in this phase — Apple's flow is preserved as-is, Facebook's button stays visible-but-broken exactly as previously decided. Only the phone/OTP path's field set and the screen's visual construction change.

## Fields

**Kept (functionally required or already working):**
- Avatar/photo picker (existing `UIImagePickerController` flow via `RegisterPicker.swift` — unchanged)
- Name (required)
- Country code + phone (required — phone is the actual OTP auth credential)
- Terms switch (required, gates registration)
- Apple Sign-In button (unchanged logic)
- Facebook Sign-In button (unchanged logic, known-broken, stays visible)

**Removed from the UI (and from validation, some already removed there in an earlier plan):**
- Gender selection buttons
- Birthdate picker
- Password / confirm password fields
- Email field

## Data Model Impact

`WAPRegistrationProfile` (`The W App/Classes/WAPSupabase.swift`) currently requires non-optional `gender: String` and `date_of_birth: String`. Since the phone-OTP path (`RegisterVC` → `OTPVerifyVC`) will no longer collect either, both become optional (`String?`). This is a minimal-blast-radius change: `FcbRegisterPicker.swift` (Facebook path, untouched in this phase, still has its own gender/birthdate storyboard UI) keeps passing its existing non-optional values unchanged — non-optional values assign fine to optional parameters, so it keeps compiling and behaving exactly as before.

`OTPVerifyVC`'s `gender`/`birthDate` properties (currently `String`, set by `RegisterVC.openOTPVerify`) become optional too, defaulting to `nil` since `RegisterVC` no longer collects them. `OTPVerifyVC.upsertProfile()` passes them straight through as `nil` to the now-optional `WAPRegistrationProfile` fields.

## Architecture

`RegisterVC` converts fully to programmatic UI (no `@IBOutlet`/`@IBAction`, no storyboard scene), matching `OTPVerifyVC`'s construction style: dark pill fields (`WPillButton`/`Colors.back_gray`-style text fields), `Colors.black` background, `icon_watermark` logo. All existing working logic is preserved as-is and re-wired to the new views:
- `showPicker`/`imagePickerController` (avatar picking) — unchanged logic, from `RegisterPicker.swift`
- `countryCode` → presents the existing storyboard `PickerVC` (single-select wheel picker) — unchanged, out of scope
- `terms` → presents the existing storyboard `AboutVC` — unchanged, out of scope
- `appleRegister`/`authorizationController(...)`/nonce generation — unchanged logic
- `facebookRegister`/`request`/`facebookSuccess` etc. — unchanged logic (still broken, as already accepted)
- `register()` — validates Name + Phone + Terms (drops the removed fields from the guard), calls `WAPAuth.signInWithPhone`, opens `OTPVerifyVC`
- `openOTPVerify(phone:)` — no longer passes `gender`/`birthDate` (or passes `nil`)

## Non-Goals

- No Affiliation/Industry/Role fields or the multi-select UI component they'd need — deferred to a future profile-edit phase.
- No Email field.
- No changes to Apple/Facebook auth *logic* — only how their buttons are laid out on the new programmatic screen.
- No changes to `FcbRegisterVC`/`FcbRegisterPicker` (the Facebook-path screen) beyond what's forced by `WAPRegistrationProfile`'s field types becoming optional.
- No changes to `PickerVC` (country code) or `AboutVC` (terms) — both stay storyboard-based, unaffected.
