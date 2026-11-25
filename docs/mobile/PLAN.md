# 📱 Mynine mobil ilova (Android + iOS) — ishlab chiqish rejasi

**Maqsad:** Mynine talabalari uchun IELTS practice ilovasi (Android va iOS). U web'dagi test bank va practice imtihon xonasi bilan funksional teng bo'ladi.
**Texnologiya (2026-11-25 qaror):** Android — **Kotlin + Jetpack Compose** ([`android/`](../../android)), iOS — **SwiftUI** ([`ios/`](../../ios)), multitest.uz kabi native.
Imtihon matni va savollar (9 tur) ikkala ilovada bitta umumiy sahifa bilan chiziladi: [`shared/exam-room/`](../../shared/exam-room) (Android WebView / iOS WKWebView). Timer, raqamlar paneli, audio va javoblar navbati — native.
**Holat:** backend API deploy qilingan; Android 1.0.0 tayyor (`releases/Mynine_v1.0.0_release.apk`); iOS — keyingi bosqich.

---

## 0. Qabul qilingan qarorlar

| Savol | Qaror |
|---|---|
| Texnologiya | Android **Kotlin/Compose**, iOS **SwiftUI** (foydalanuvchi qarori). Imtihon xonasi renderer'i `shared/exam-room` — bir marta yozilgan, ikkala platformada. |
| To'lov | **Yo'q.** Barcha practice testlar bepul, In-App Purchase kerak emas. |
| Kimlar uchun | **Faqat Mynine markazi talabalari** (Super Admin id 183 markazi). Ijaradagi markazlarning talabalari ilovaga kirmaydi, ilova ichida markaz tanlash yo'q. |
| Rollar | Faqat **Student**. Admin, Reception va Monitor web'da qoladi. |
| Mock imtihon | Markazdagi mock `.exe` da qoladi. Mock natijasi 1-versiyada ilovada ko'rsatilmaydi, qog'ozda qabulxonada beriladi (keyinroq qo'shish mumkin). |
| Speaking practice | 1-versiyada yo'q (web'da ham hali yo'q). |
| Push bildirishnoma | 1-versiyada yo'q. 2-versiyada FCM/APNs. |
| Dizayn | Ilova qobig'i (kirish, bosh sahifa, test bank, natija, profil) **liquid glass** uslubida, web bilan bir xil tokenlar. **Imtihon xonasi** web/desktop'dagi oq rasmiy IELTS uslubida qoladi. |
| Tillar | uz, ru, en |
| Identifikator | `uz.mynine.app` (Android applicationId va iOS bundle ID) |
| Minimal versiya | Android minSdk 26, iOS 17 |

---

## 1. Ilova bo'limlari

| Ekran | Tarkibi |
|---|---|
| Splash | Logo, sessiyani tekshirish |
| Kirish | Google, Telegram OTP (`@MynineUzBot` → 6 xonali kod), Sign in with Apple (faqat iOS, Guideline 4.8), reviewer kodi |
| Bosh sahifa | Salom, oxirgi band, modullar bo'yicha o'rtacha, davom ettirilmagan urinish, tavsiya testlar |
| Test bank | Qidiruv, L/R/W filtr, papkalar, test kartasi (modullar, savollar soni, vaqt) |
| Test tafsiloti | Modullarni tanlash (to'liq test yoki bitta modul), qoidalar, Listening uchun ovoz tekshiruvi |
| Imtihon xonasi | Desktop UI; telefonda Passage/Questions tab + savollar raqam paneli, planshetda split view |
| Natija | Overall band, modul ballari, savollar bo'yicha to'g'ri/xato (faqat topshirgandan keyin), Writing AI izohi |
| Tarix | Barcha urinishlar, filtr, davom ettirish |
| Profil | Ism, avatar, til, mavzu (light/dark), chiqish, **hisobni o'chirish** (Apple 5.1.1(v), Google Play talabi) |

Pastki navigatsiya: **Bosh sahifa · Testlar · Tarix · Profil**.

---

## 2. Backend: `api/v1/student/*`

Hozirgi `api/v1` desktop qurilma va nomzod (`desktop.device`, `desktop.candidate`) uchun. **Unga tegilmaydi.** Yonida yangi guruh ochiladi:

```php
Route::prefix('v1/student')->name('api.v1.student.')->group(function () {
    Route::post('auth/google', ...);        // id_token → tokeninfo tekshiruvi
    Route::post('auth/telegram-otp', ...);  // {otp}
    Route::post('auth/apple', ...);         // identityToken (JWKS), name (faqat birinchi marta)
    Route::post('auth/reviewer', ...);      // REVIEWER_CODE (.env) — App Store / Play review uchun
    Route::get('app/version', ...);         // {latest, min_supported, store_urls}

    Route::middleware(['auth:sanctum', 'ability:student', 'mynine.student'])->group(function () {
        Route::get('me', ...);
        Route::post('auth/logout', ...);
        Route::patch('me', ...);             // ism, til
        Route::delete('me', ...);            // hisobni o'chirish

        Route::get('dashboard', ...);
        Route::get('tests', ...);            // test-bank mantig'i
        Route::get('tests/{test}', ...);

        Route::post('attempts', ...);        // {test_id, type_ids[]}
        Route::get('attempts', ...);         // tarix
        Route::get('attempts/{attempt}', ...);
        Route::get('attempts/{attempt}/parts/{part}', ...);   // answer_text / is_correct YO'Q
        Route::post('attempts/{attempt}/answers', ...);       // autosave (batch, idempotent)
        Route::post('attempts/{attempt}/types/{type}/submit', ...);
        Route::post('attempts/{attempt}/submit', ...);
        Route::get('attempts/{attempt}/result', ...);         // faqat yakunlangandan keyin
        Route::get('media/audio/{file}', ...);                // imzolangan, muddatli URL
    });
});
```

**Vazifalar:**
1. `otps` jadvali va `MynineUzBotService` ichida "🔑 Ilovaga kirish kodi" tugmasi. Kod 6 xonali, 2 daqiqa amal qiladi, bir marta ishlatiladi, throttle qo'yiladi.
2. `users.apple_id` ustuni (migratsiya). iOS OAuth client ID `GOOGLE_ALLOWED_CLIENT_IDS` ga qo'shiladi.
3. `mynine.student` middleware: foydalanuvchi Mynine markaziga tegishli Student bo'lishi shart, aks holda 403 qaytadi va ilova "Faqat Mynine talabalari uchun" deb ko'rsatadi.
   - Google yoki Apple orqali yangi kirgan foydalanuvchi web'dagi kabi Mynine markaziga Student bo'lib yoziladi.
4. Mantiq `PracticeController`, `AttemptAnswerController` va mavjud baholash service'laridan olinadi. Yangi baholash yozilmaydi, kerak bo'lsa service'ga ajratiladi.
5. Savol payload'ida to'g'ri javob yuborilmaydi (2026-10 audit). `drag_and_drop` / `complete_section` variantlari alohida maydondan beriladi.
6. `app/version` yumshoq ishlaydi: imtihon o'rtasida hech qachon bloklamaydi, faqat yangi urinish boshlashdan oldin ogohlantiradi. Desktop'dagi 426 tajribasi takrorlanmasin.
7. Feature testlar: auth (3 provider + reviewer), ownership (boshqa talabaning attempt'i → 403), boshqa markaz foydalanuvchisi → 403, javob sizmasligi, hisobni o'chirish.

---

## 3. Kod tuzilishi

> 2026-11-25 yangilandi: Flutter o'rniga native. Haqiqiy tuzilma: `android/` (Kotlin, Compose; `data/` API, sessiya, javoblar navbati; `ui/` auth, main, tests, exam, result), `shared/exam-room/` (index.html, exam-room.js/css, Inter), `ios/` (SwiftUI). Quyidagi Flutter sxemasi tarix uchun qoldirildi.

```
mynine.uz/
├── desktop/                        # mavjud Windows .exe (lockdown, kiosk) — o'zgarmaydi
├── mobile/                         # YANGI Flutter ilova (android/, ios/, lib/)
│   └── lib/
│       ├── app/        router, root, theme (liquid glass)
│       ├── core/       api (dio + interceptor), session (secure storage), i18n
│       ├── data/       models (freezed), repositories, db (drift: javoblar navbati)
│       └── features/   splash, auth, home, tests, test_detail, exam, result, history, profile
└── packages/
    └── mynine_exam_ui/             # YANGI: desktop va mobil uchun umumiy
        ├── theme/      exam tokenlari, Inter
        ├── passage/    html_document, html_view, passage_pane, passage_slots
        ├── questions/  question_widgets, range
        └── exam/       timer, listening audio interfeysi, javob modeli
```

- `packages/mynine_exam_ui` `desktop/lib` dan **bosqichma-bosqich** ajratiladi. Har qadamdan keyin `flutter test` (desktop) o'tishi shart. Markazlarda ishlayotgan imtihon buzilmasligi birinchi o'rinda.
- Audio uchun interfeys qo'yiladi: desktop'da `media_kit`, mobilda `just_audio`.
- Mobil stek: `flutter_riverpod`, `go_router`, `dio`, `freezed`, `drift`, `flutter_secure_storage`, `just_audio`, `google_sign_in`, `sign_in_with_apple`, `url_launcher` (Telegram bot), `package_info_plus`, `lucide_icons_flutter`.

---

## 4. Imtihon xonasi (mobil)

- **Telefon:** yuqorida IELTS header (timer, modul nomi), o'rtada `Passage | Questions` segment tugmasi (swipe bilan ham o'tiladi), pastda savol raqamlari paneli (web'dagi `practice-number-bar` kabi).
- **Planshet (≥ 840 dp):** web kabi chap passage, o'ng savollar.
- **Listening:** audio faqat bir marta ijro etiladi, pauza yo'q (web kabi), ekran o'chmaydi (`wakelock`).
- **Writing:** to'liq ekranli matn maydoni va so'z hisoblagichi; klaviatura ochilganda topshiriq yig'iladigan panelga o'tadi.
- **Autosave:** har javob avval drift'ga yoziladi, keyin batch qilib serverga yuboriladi. Internet uzilsa navbatda turadi, tiklanganda yuboriladi.
- **Ilovadan chiqish:** practice'da lockdown yo'q. Ilova fonga o'tsa timer server vaqti bo'yicha davom etadi, qaytganda urinish tiklanadi.
- Imtihon xonasining ranglari va shrifti web/desktop bilan bir xil (oq IELTS uslubi), dark mode bu yerga ta'sir qilmaydi.

---

## 5. Bosqichlar

| # | Bosqich | Natija | Vaqt |
|---|---|---|---|
| 0 | Tayyorgarlik | Apple Developer ($99/yil), Google Play akkaunt, `uz.mynine.app`, OAuth client ID'lar (Android, iOS) | 1–2 kun |
| 1 | Backend `student` API | Endpoint'lar, migratsiyalar, OTP bot, testlar yashil | 1 hafta |
| 2 | `packages/mynine_exam_ui` | Umumiy paket, desktop unga o'tgan, desktop testlari yashil | 3–5 kun |
| 3 | Mobil skelet | Auth (Google, Telegram, Apple), session, router, liquid glass tema, i18n | 1 hafta |
| 4 | Testlar va imtihon | Test bank, tafsilot, imtihon xonasi (telefon + planshet), autosave, offline navbat | 1.5–2 hafta |
| 5 | Natija va profil | Natija, tarix, profil, hisobni o'chirish, versiya tekshiruvi | 4–5 kun |
| 6 | Android release | Keystore, AAB va APK → `mynine.uz/releases/`, `/play-release` → Internal testing | 2–3 kun |
| 7 | iOS release | Imzo, TestFlight, App Store sahifasi, reviewer ma'lumotlari, privacy | 3–5 kun |
| 8 | Pilot | 10–20 talaba, xatolar tuzatiladi, Production | 1 hafta |

**Jami:** taxminan 6–8 hafta.

---

## 6. Do'kon talablari (checklist)

- [ ] Privacy policy sahifasi: `mynine.uz/privacy` (mavjud bo'lmasa yaratiladi)
- [ ] Ilova ichida hisobni o'chirish (Apple 5.1.1(v), Google Play)
- [ ] Google kirish bor ekan, iOS'da Sign in with Apple (4.8)
- [ ] Reviewer kirishi (`REVIEWER_CODE`), "App Review Information" va Play "App access" ga yoziladi
- [ ] Data safety (Play) va Privacy Nutrition Label (App Store): email, ism, test natijalari; tracking yo'q
- [ ] Ikonka 1024×1024, skrinshotlar (6.7" iPhone, 6.5" iPhone, 12.9" iPad, Android telefon + planshet)
- [ ] Release fayllari faqat `mynine.uz/releases/` da (har ilovaning faqat oxirgi versiyasi), `.gitignore` da `releases/`
- [ ] Versiya: `mobile/pubspec.yaml` → `version: X.Y.Z+build`, desktop versiyasidan mustaqil

---

## 7. Xavflar

| Xavf | Chora |
|---|---|
| Umumiy paket desktop imtihonini buzadi | Bosqichma-bosqich ajratish, har qadamda desktop testlari; desktop release faqat to'liq regressiyadan keyin |
| Telefonda uzun passage va savollar noqulay | Tab/swipe layout, savol raqamidan passage'dagi joyga sakrash; pilotda tekshiriladi |
| Apple review rad etadi (4.2 "web o'rami") | Native ekranlar, offline autosave, haqiqiy Flutter UI — WebView emas |
| Javob sizishi | Payload'ni test bilan qotirish: `answer_text`, `is_correct` faqat `result` endpoint'ida |
| Boshqa markaz foydalanuvchisi kiradi | `mynine.student` middleware va test |
