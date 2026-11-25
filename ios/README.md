# Mynine iOS (SwiftUI)

Android ilovasi (`../android`) bilan funksional teng nativ iOS ilova. Reja: [`../docs/mobile/PLAN.md`](../docs/mobile/PLAN.md).

- Minimal iOS **17.0**, Bundle ID `uz.mynine.app`, uchinchi tomon kutubxonasi yo'q.
- Xcode loyihasi `PBXFileSystemSynchronizedRootGroup` bilan: `Mynine/` ga qo'shilgan fayl avtomatik target'ga kiradi.
- Imtihon xonasi sahifasi `../shared/exam-room/` (Android bilan umumiy) — build vaqtida "Copy exam room" bosqichi uni bundle'ga nusxalaydi.
- Versiya: `version.xcconfig` (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION` — har TestFlight yuklashda +1).

## Tuzilma

```
Mynine/
├── App/        MynineApp (RootView, Router: test / natija / imtihon full screen)
├── Core/       API (modellar, URLSession), Session (Keychain), AnswerQueue (Application Support), Theme (liquid glass)
├── Features/   Auth (Telegram kodi, parol, Google PKCE, Sign in with Apple), Main (Bosh, Tarix, Profil),
│               Tests (ro'yxat, tafsilot), Exam (ViewModel, WKWebView ko'prigi, xona), Result
└── Resources/  Assets (AppIcon, LogoMark), Info.plist (Google redirect sxemasi), entitlements, PrivacyInfo
```

## Kirish

- **Telegram:** `@MynineUzBot` → `/start app` → 6 xonali kod.
- **Google:** SDK'siz — `ASWebAuthenticationSession` + PKCE, iOS OAuth klienti (`younine` loyihasi, `Info.plist` `GIDClientID`).
  Server `.env` da `GOOGLE_MOBILE_CLIENT_IDS` ga shu klient ID qo'shilishi kerak.
- **Apple:** `com.apple.developer.applesignin`; server `users.apple_id` migratsiyasini talab qiladi.

## Build

```bash
cd ios
xcodebuild -project Mynine.xcodeproj -scheme Mynine \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

Lokal server bilan sinash (faqat DEBUG): `SIMCTL_CHILD_MYNINE_BASE_URL=http://127.0.0.1:8000 xcrun simctl launch <device> uz.mynine.app -e2eToken <token> -e2eRoute exam:<id> -e2eAutoStart YES`.

## Reliz (TestFlight / App Store)

Apple Developer akkaunti kerak: Xcode → Signing & Capabilities → Team tanlang (`DEVELOPMENT_TEAM`), "Sign in with Apple"
capability. Keyin Product → Archive → Distribute App → App Store Connect.
