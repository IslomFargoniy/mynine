<p align="center">
  <a href="https://laravel.com" target="_blank">
    <img src="https://raw.githubusercontent.com/laravel/art/master/logo-lockup/5%20SVG/2%20CMYK/1%20Full%20Color/laravel-logolockup-cmyk-red.svg" width="400" alt="Laravel Logo" />
  </a>
</p>

<p align="center">
  <a href="https://laravel.com"><img src="https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white" alt="Laravel 12" /></a>
  <a href="https://react.dev"><img src="https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB" alt="React 19" /></a>
  <a href="https://tailwindcss.com"><img src="https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white" alt="Tailwind 4" /></a>
  <a href="https://inertiajs.com"><img src="https://img.shields.io/badge/Inertia.js-9553E9?style=for-the-badge&logo=inertia&logoColor=white" alt="Inertia" /></a>
  <a href="https://www.typescriptlang.org/"><img src="https://img.shields.io/badge/TypeScript-007ACC?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript" /></a>
</p>

# 🚀 Ultimate Laravel 12 & React 19 Starter Kit

A robust, feature-rich starter kit built on top of **Laravel 12** and **React 19** using **Inertia.js**. It comes pre-configured with modern tools, UI components, payment gateways (specifically for Uzbekistan), role-based access control, and API documentation out of the box.

This template is perfect for building SaaS applications, ERPs, CRMs, or any complex web application rapidly. It is ready to be published on GitHub!

---

## ✨ Features

- **⚡ Latest Tech Stack:** Laravel 12, React 19 (Hooks & Modern Context), Inertia.js 2 (SSR supported), Vite, and TypeScript.
- **🎨 Modern UI/UX:** Styled with **Tailwind CSS v4**, featuring Radix UI primitives, Flowbite React, and beautiful icons (Lucide, Framer Motion).
- **🔐 Authentication & Authorization:** Laravel Sanctum for auth, and Spatie Permission for seamless Role/Permission management.
- **💳 Payment Integrations:** Pre-configured with `goodoneuz/pay-uz` supporting **Payme, Click, Oson, Uzcard, Paynet, and Stripe**.
- **🌍 Multi-language Support:** Ready for Uzbek (Cyrillic/Latin), Russian, English, Spanish, Italian, and German.
- **📱 PWA Ready:** Integrated with Laravel PWA for offline capabilities and mobile installation.
- **🤖 Telegram Bot API:** Includes `irazasyed/telegram-bot-sdk` for instant Telegram integrations.
- **📊 Charts & Datatables:** Packed with ApexCharts, ECharts, Chart.js, and ExcelJS for rich admin dashboards.
- **📝 Media & Content:** Includes TinyMCE editor, WaveSurfer.js for audio, and drag-and-drop toolkit (`@dnd-kit`).
- **📖 API Documentation:** Auto-generated interactive API docs via L5-Swagger.
- **🛠️ DX Tools:** Laravel Telescope for debugging, Pest for testing, Pint & ESLint/Prettier for code styling.

---

## 🛠️ Prerequisites

Make sure you have the following installed on your local machine:
- **PHP** >= 8.2
- **Composer** 
- **Node.js** >= 18.x
- **NPM** or **Yarn**

---

## 🚀 Installation & Setup

**1. Clone the repository**
```bash
git clone https://github.com/USERNAME/REPO_NAME.git
cd REPO_NAME
```

**2. Install PHP and Node dependencies**
```bash
composer install
npm install
```

**3. Configure Environment**
```bash
cp .env.example .env
php artisan key:generate
```
*Don't forget to update your `.env` file with your database credentials and other necessary environment variables.*

**4. Link Storage**
```bash
php artisan storage:link
```

**5. Run Migrations & Seeders**
```bash
php artisan migrate --seed
php artisan db:seed --class="Goodoneuz\PayUz\database\seeds\PayUzSeeder"
```

**6. Start Development Servers**
This starter kit uses a powerful concurrency script to run everything you need in one command:
```bash
npm run dev
```
*(This command boots up the Vite dev server, Laravel dev server, Queue listener, and Pail logs concurrently using `concurrently`).*

---

## 🔑 Default Credentials

After running the seeders, you can log in with:
- **Email:** `admin@gmail.com`
- **Password:** `123456`

---

## 📖 API Documentation (Swagger)

Generate and update the OpenAPI documentation:
```bash
php artisan l5-swagger:generate
```
Access the Swagger UI at: `http://localhost:8000/api/documentation`

---

## 💳 Payment Gateway Setup (Pay-Uz)

Handling payments in Uzbekistan is a breeze. The routes are ready in `routes/web.php`:

**Webhook Handler:**
```php
Route::any('/handle/{paysys}', function($paysys){
    (new Goodoneuz\PayUz\PayUz)->driver($paysys)->handle();
});
```

**Redirect to Payment System:**
```php
Route::any('/pay/{paysys}/{key}/{amount}', function($paysys, $key, $amount){
    $model = Goodoneuz\PayUz\Services\PaymentService::convertKeyToModel($key);
    $url = request('redirect_url', '/'); // Callback URL after successful payment
    
    $pay_uz = new Goodoneuz\PayUz\PayUz;
    $pay_uz->driver($paysys)->redirect($model, $amount, 860, $url);
});
```

---

## 🛠️ Useful Links

- **Main App:** [http://localhost:8000](http://localhost:8000)
- **Telescope Debugger:** [http://localhost:8000/telescope](http://localhost:8000/telescope)
- **Swagger Docs:** [http://localhost:8000/api/documentation](http://localhost:8000/api/documentation)

---

## ⚙️ Queue Configuration (Supervisor)

For production environments, it is highly recommended to use **Supervisor** to manage your Laravel queue workers. Supervisor will automatically restart your `queue:work` processes if they fail.

**1. Create a Supervisor configuration file**
Create a new file at `/etc/supervisor/conf.d/mynine-worker.conf`:

```ini
[program:mynine-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/mynine/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/mynine/storage/logs/worker.log
stopwaitsecs=3600
```

*Note: Update `/var/www/mynine` to your actual project path and `user=www-data` to your system user.*

**2. Start the worker**
Run the following commands to update and start the supervisor process:

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start mynine-worker:*
```

---

## 🔐 File Permissions (Production)

If you encounter "Permission denied" errors in logs or while running queues, ensure the `storage` and `bootstrap/cache` directories have the correct ownership and permissions:

```bash
# Set ownership to the web server user (e.g., www-data or your system user)
sudo chown -R $USER:$USER storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache

# If issues persist, ensure the folders exist
mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache storage/logs
```

---

## 🤝 Support & Contribution

- **YouTube:** [IslomFargniy](https://www.youtube.com/@IslomFargniy)
- **Telegram Community:** [IslomFargniy](https://t.me/IslomFargniy)
- **Email:** [abdurahmanislam304@gmail.com](mailto:abdurahmanislam304@gmail.com)

---

## 🛡️ Security Vulnerabilities

If you discover a security vulnerability within this project, please send an e-mail directly to [abdurahmanislam304@gmail.com](mailto:abdurahmanislam304@gmail.com).

## 📄 License

This starter kit is open-sourced software licensed under the [MIT license](LICENSE.md).
