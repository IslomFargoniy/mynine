# Mynine.uz — Supervisor sozlamalari

Laravel navbat ishchisi (`queue:work`) va rejalashtiruvchisi (`schedule:work`) fonda to'xtovsiz ishlashi uchun.
**Dasturlar `root` emas, ilova foydalanuvchisi nomidan ishlaydi.**

## 1. Fayllarni nusxalash va moslash
```bash
sudo cp supervisor/mynine-worker.conf /etc/supervisor/conf.d/
sudo cp supervisor/mynine-scheduler.conf /etc/supervisor/conf.d/
sudo sed -i 's/APP_USER/<ilova_foydalanuvchisi>/g' /etc/supervisor/conf.d/mynine-*.conf
```
Yo'l (`/var/www/<user>/data/www/mynine.uz`) va PHP binari (`/opt/php82/bin/php`) serveringizdagi haqiqiy
qiymatlarga mos bo'lishi kerak.

Worker `--timeout=150 --tries=3` bilan ishlaydi: `EvaluateEssayJob` (OpenAI) 120 soniyagacha davom etishi mumkin,
job timeout'i worker timeout'idan kichik bo'lishi shart.

Agar serverda eski `mynine-evaluate-essay.conf` bo'lsa, uni olib tashlang (ikkita worker bir xil navbatni o'qiydi):
```bash
sudo rm /etc/supervisor/conf.d/mynine-evaluate-essay.conf
```

## 2. Ishga tushirish
```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart mynine-worker:* mynine-schedule:*
```

## 3. Holatni tekshirish
```bash
sudo supervisorctl status mynine-worker:* mynine-schedule:*
```

`schedule:work` ishlayotgan bo'lsa, `* * * * * php artisan schedule:run` cron yozuvi kerak emas (ikkalasi bir vaqtda
ishlasa vazifalar ikki marta bajariladi).
