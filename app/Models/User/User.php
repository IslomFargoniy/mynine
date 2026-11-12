<?php

namespace App\Models\User;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use App\Models\Attempt;
use App\Models\CenterSetting;
use App\Support\CurrentCenter;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, HasRoles, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'user_id',
        'name',
        'username',
        'phone',
        'email',
        'password',
        'avatar',
        'google_id',
        'telegram_id',
        'ref_telegram_id',
        'github_id',
        'create_test_limit',
    ];

    protected $with = [
        'roles',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'google_id',
        'github_id',
        'ref_telegram_id',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'suspended_at' => 'datetime',
        ];
    }

    /*
    |--------------------------------------------------------------------------
    | Centers: an Admin user IS a center; Reception staff belong to one (owner_id).
    |--------------------------------------------------------------------------
    */

    public function isSuperAdmin(): bool
    {
        return $this->hasRole('SuperAdmin');
    }

    /**
     * The Admin of a center (the SuperAdmin is the Admin of the Mynine center).
     */
    public function isCenterAdmin(): bool
    {
        return $this->hasRole('Admin') || $this->isSuperAdmin();
    }

    public function isReception(): bool
    {
        return ! $this->isCenterAdmin() && $this->hasRole('Reception');
    }

    public function isStaff(): bool
    {
        return $this->isCenterAdmin() || $this->hasRole('Reception');
    }

    /**
     * The user's own center (Admin: themself, Reception: their Admin), ignoring the SuperAdmin's switch.
     */
    public function homeCenterId(): ?int
    {
        if ($this->isCenterAdmin()) {
            return (int) $this->id;
        }

        return $this->hasRole('Reception') && $this->owner_id ? (int) $this->owner_id : null;
    }

    /**
     * The center the user works for right now (the SuperAdmin may switch it on the Centers page).
     */
    public function centerId(): ?int
    {
        return app(CurrentCenter::class)->forUser($this);
    }

    public function centerSetting(): HasOne
    {
        return $this->hasOne(CenterSetting::class, 'owner_id');
    }

    /**
     * The Admin (center) a Reception user works for.
     */
    public function centerOwner(): BelongsTo
    {
        return $this->belongsTo(self::class, 'owner_id');
    }

    public function staff(): HasMany
    {
        return $this->hasMany(self::class, 'owner_id');
    }

    public function isSuspended(): bool
    {
        return $this->suspended_at !== null;
    }

    public function attempts()
    {
        return $this->hasMany(Attempt::class, 'user_id');
    }

    public function last_attempt()
    {
        return $this->hasOne(Attempt::class, 'user_id')->latestOfMany('created_at');
    }

    protected static function newFactory()
    {
        return UserFactory::new();
    }
}
