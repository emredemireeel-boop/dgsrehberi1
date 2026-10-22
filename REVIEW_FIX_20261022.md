# DGS iOS ATT review correction

Prepared version 1.1.4 (9), code changes in 0601400 and 158efca. The rejected App Store binary 1.1.0 (5) contained NSUserTrackingUsageDescription according to App Store Connect. The current source Info.plist has no such key or ATT dependency. Detaching old build 5 from the version draft unblocked the last privacy-label correction; the replacement IPA is still required before submission.

## Changes

- iOS banner and interstitial requests use non-personalized ads.
- Native AppDelegate disables publisher first-party ID before plugin registration using Google's documented request configuration API.
- Wait for the current UMP consent form callback before ads initialization; SDK startup failures do not propagate into study flows.
- SDK technical collection remains disclosed. Non-personalized ads do not mean no data collection.
- Public/in-app privacy copy updated; ATT is intentionally not requested for the contextual-ad path.

## Verification

22 October 2026: `flutter analyze --no-pub` clean; `flutter test --reporter expanded` 1 passed (compact timer layout). This does not verify Swift compilation, the signed IPA or physical-iPad ad behavior. These require the Codemagic build and subsequent artifact verification.

## External state

Apple App Privacy: all tracking flags are now No, including Advertising Data. Other Diagnostic Data was added, bringing the disclosed SDK types to seven. Diagnostics are not linked to identity; the SDK's other identity-linked technical data remains disclosed. The last tracking edit initially failed while old build 5 was selected, then succeeded after that build was detached. This is a published label correction, not an approved application.

Codemagic personal application created: `6ada1afd2a0c2094c2015302`, repository dgsrehberi1. Initial branch-loader UI errors were recovered by connecting the same public repository through its direct Git URL and allowing configuration loading to complete. First build `6ada1bc08a524d15d6a60cfe` failed preflight because no matching signing profile was stored.

The existing invalid Apple profile `67NH4PHNYP` was renewed with the already-used distribution certificate `C726PJ97KF` (expires 15 October 2027), without creating or revoking any certificate. Codemagic confirmed storage as `dgs_app_store_oct2026`.

The Podfile now uses Flutter's standard static pod integration, matching the Google Ads header correction verified in the KPSS project's 29006e7 build. App Store version draft is 1.1.4 with the old build detached and English review notes explaining the contextual-ad path. The Codemagic account reports 145/500 free macOS minutes used; no subscription or payment was enabled.

Build 2 was cancelled before execution to include the Podfile correction. Latest build **6ada1d488a524d15d6a60dad** (index 3, main, commit 158efca) was accepted and remains **queued**. No IPA, TestFlight upload, successful Swift compile or App Review resubmission is claimed yet.

Next: wait for this build, inspect signed IPA Info.plist/privacy manifests, resolve any compile/upload error, select build 9 in the 1.1.4 draft, send the contextual-ad explanation to the existing review conversation, and submit the replacement version. No ATT video is requested from the user for this non-tracking path.

Official configuration reference: https://developers.google.com/admob/ios/privacy/strategies
