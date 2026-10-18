# Mynine.uz — Deploy qo'llanmasi

Ishlab chiqarish (production) serveriga yuklash, yangilash va fon xizmatlarini boshqarish.

> Server manzili, foydalanuvchi nomi va papka yo'llari bu hujjatda ataylab yozilmagan. Quyida
> `<server>`, `<ilova_foydalanuvchisi>` va `<loyiha_papkasi>` o'rnini o'zingizning qiymatlaringiz bilan to'ldiring
> (ularni repoga yozmang).

## Talablar (serverda)
- PHP 8.2+ (`mbstring`, `pdo_mysql`, `fileinfo`, `gd`, `zip`, `bcmath`), Composer 2
- Node 22+ va npm
- MySQL 8
- Supervisor (`queue:work` va `schedule:work` uchun)
- Veb-server `public/storage` ichida PHP ni **bajarmasligi** kerak
- Audio fayllar `storage/app/private/audio` da saqlanadi va `/media/audio/{fayl}` route orqali faqat
  tizimga kirgan foydalanuvchi yoki nomzod kodi bilan kirganlarga uzatiladi. Nginx `client_max_body_size`
  kamida `30m` bo'lsin (audio yuklash limiti 24 MB).

## Birinchi marta sozlash
```bash
cd <loyiha_papkasi>
cp .env.example .env            # ichini to'ldiring (pastga qarang)
composer install --no-dev --optimize-autoloader
npm ci && npm run build
php artisan key:generate
php artisan storage:link
php artisan migrate --force
php artisan db:seed --force     # rollar, Admin, Type va QuestionType yozuvlari
php artisan optimize
```

Muhim `.env` qiymatlari:

| Kalit | Izoh |
|---|---|
| `APP_ENV=production`, `APP_DEBUG=false`, `APP_URL=https://...` | `APP_URL` imzolangan PDF havolalari uchun to'g'ri bo'lishi shart |
| `DB_*` | MySQL ulanishi |
| `QUEUE_CONNECTION=database`, `CACHE_STORE=database`, `SESSION_DRIVER=database` | jadvallar migratsiyada yaratiladi |
| `MynineUzBot_TOKEN` | asosiy bot: WebApp login, Login Widget, natija yuborish |
| `TELEGRAM_BOT_TOKEN` | eski bot (faqat @MynineUzBot ga yo'naltiradi), ixtiyoriy |
| `OPENAI_API_KEY` | insho baholash va AI import |
| `GOOGLE_*`, `GITHUB_*` | ijtimoiy login (callback URL lari domen bilan mos bo'lsin) |
| `MAIL_*` | natija xatlari |
| `TELESCOPE_ENABLED=false` | production'da o'chirilgan bo'lsin |

Barcha kalitlar `config/services.php` orqali o'qiladi, shuning uchun `php artisan optimize` (config cache) bilan ham ishlaydi.
`UserSeeder` yaratadigan standart admin parolini (`admin@gmail.com / 123456`) birinchi kirishdan keyin **darhol o'zgartiring**.

## Yangilash (har deploy)
Barcha buyruqlar **ilova foydalanuvchisi** nomidan bajariladi (`sudo` kerak emas; faqat `supervisorctl` uchun kerak).

```bash
ssh <ilova_foydalanuvchisi>@<server>
cd <loyiha_papkasi>

php artisan down --retry=30
git pull origin main
composer install --no-dev --optimize-autoloader --no-interaction
npm ci && npm run build
php artisan migrate --force
php artisan optimize           # config, route, view keshlari
php artisan queue:restart      # worker yangi kod bilan qayta ishga tushadi
php artisan up
```

Shu ketma-ketlik `.gitlab-ci.yml` dagi `deploy_production` job'ida ham bor (qo'lda ishga tushiriladi, `manual`).

> Migratsiyadan oldin **ma'lumotlar bazasidan zaxira nusxa** oling:
> `mysqldump -u <user> -p <db> | gzip > ~/backups/mynine-$(date +%F).sql.gz`

### Audio fayllarni yopiq diskga o'tkazish (bir martalik)
2026-10 dan oldin yuklangan audio `storage/app/public/audio` da (ochiq URL) saqlangan. Yangilashdan keyin bir marta:
```bash
php artisan audio:privatize --dry-run   # nima o'zgarishini ko'rsatadi
php artisan audio:privatize             # fayllarni ko'chiradi, DB dagi yo'llarni media/audio/... ga yozadi
```
Buyruq fayllarni `rename` bilan ko'chiradi (xotiraga yuklamaydi), qayta ishga tushirish xavfsiz.

### Telegram webhook (birinchi marta yoki token o'zgarganda)
```bash
curl -s "https://api.telegram.org/bot<MynineUzBot_TOKEN>/setWebhook?url=https://<domen>/bot/MynineUzBot/webhook"
```
Login Widget uchun BotFather'da `/setdomain` → `<domen>`.

## Supervisor
Konfiguratsiyalar va o'rnatish: [`supervisor/README.md`](supervisor/README.md).
1. **`mynine-worker`** — navbat: AI insho baholash (`EvaluateEssayJob`), natija email/Telegram xabarlari.
2. **`mynine-schedule`** — `attempts:close-old` har soatda 3 soatdan eski tugallanmagan urinishlarni yopadi.

```bash
sudo supervisorctl reread && sudo supervisorctl update
sudo supervisorctl restart mynine-worker:* mynine-schedule:*
sudo supervisorctl status mynine-worker:* mynine-schedule:*
```

## Foydali buyruqlar
```bash
php artisan attempts:close-old              # eski tugallanmagan urinishlarni qo'lda yopish
php artisan attempt-types:recalculate       # barcha modullar uchun is_correct_count ni qayta hisoblash
php artisan audio:privatize --dry-run       # ochiq diskda qolgan audio fayllarni ko'rish
php artisan queue:failed                    # muvaffaqiyatsiz job'lar; qayta: php artisan queue:retry all
```

## Loglar
```bash
tail -f <loyiha_papkasi>/storage/logs/laravel.log
tail -f <loyiha_papkasi>/storage/logs/worker.log
tail -f <loyiha_papkasi>/storage/logs/schedule.log
```

## Tekshirish ro'yxati (deploydan keyin)
- `https://<domen>/up` → 200
- Admin bilan kirish, `/attempt` ro'yxati ochiladi
- Nomzod kodi bilan imtihon ochiladi, audio yuklanadi (`/media/audio/...` → 200, chiqib ketganda 302/403)
- `php artisan queue:work --once` xatosiz; `sudo supervisorctl status` da ikkala dastur `RUNNING`
