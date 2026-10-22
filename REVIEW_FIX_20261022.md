# DGS iOS ATT review correction

Prepared version 1.1.4 (9), source commit 0601400. The rejected App Store binary 1.1.0 (5) still contains NSUserTrackingUsageDescription according to App Store Connect. The current source Info.plist has no such key or ATT dependency. Consequently the remaining Advertising Data tracking declaration cannot be published until a replacement binary is uploaded/selected; do not claim the correction is complete before then.

## Changes

- iOS banner and interstitial requests use non-personalized ads.
- Native AppDelegate disables publisher first-party ID before plugin registration using Google's documented request configuration API.
- Wait for the current UMP consent form callback before ads initialization; SDK startup failures do not propagate into study flows.
- SDK technical collection remains disclosed. Non-personalized ads do not mean no data collection.
- Public/in-app privacy copy updated; ATT is intentionally not requested for the contextual-ad path.

## Verification

22 October 2026: `flutter analyze --no-pub` clean; `flutter test --reporter expanded` 1 passed (compact timer layout). This does not verify Swift compilation, the signed IPA or physical-iPad ad behavior. These require the Codemagic build and subsequent artifact verification.

## External state

Apple App Privacy: Coarse Location, Device ID and Product Interaction tracking flags changed to No. Advertising Data flag still Yes because Apple rejects No while the currently selected old binary contains the ATT usage string. A replacement IPA is required to complete that last change and the review submission.

Codemagic personal application created: `6ada1afd2a0c2094c2015302`, repository dgsrehberi1. Initial branch-loader UI errors were recovered by connecting the same public repository through its direct Git URL and allowing configuration loading to complete. First build `6ada1bc08a524d15d6a60cfe` failed preflight because no matching signing profile was stored.

The existing invalid Apple profile `67NH4PHNYP` was renewed with the already-used distribution certificate `C726PJ97KF` (expires 15 October 2027), without creating or revoking any certificate. Codemagic confirmed storage as `dgs_app_store_oct2026`. A signed build is being retried; no completed IPA is claimed in this report yet.

The Podfile now uses Flutter's standard static pod integration, matching the Google Ads header correction verified in the KPSS project's 29006e7 build. App Store version draft is 1.1.4 with the old build detached and English review notes explaining the contextual-ad path. The Codemagic account reports 145/500 free macOS minutes used; no subscription or payment was enabled.

Official configuration reference: https://developers.google.com/admob/ios/privacy/strategies
