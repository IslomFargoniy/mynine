<?php

namespace App\Models\User;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use App\Models\Attempt;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
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
        ];
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
        return \Database\Factories\UserFactory::new();
    }
}
