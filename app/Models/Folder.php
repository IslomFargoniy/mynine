<?php

namespace App\Models;

use App\Models\User\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Folder extends Model
{
    /** @use HasFactory<\Database\Factories\FolderFactory> */
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'comment',
        'active',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function tests()
    {
        return $this->hasMany(Test::class, 'folder_id');
    }
}
