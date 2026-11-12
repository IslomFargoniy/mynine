<?php

namespace App\Models;

use App\Models\Concerns\BelongsToCenterThroughMock;
use Illuminate\Database\Eloquent\Model;

class MockModule extends Model
{
    use BelongsToCenterThroughMock;

    protected $fillable = [
        'mock_id',
        'type_id',
        'test_type_id',
    ];

    public function mock()
    {
        return $this->belongsTo(Mock::class, 'mock_id');
    }

    public function type()
    {
        return $this->belongsTo(Type::class, 'type_id');
    }

    public function testType()
    {
        return $this->belongsTo(TestType::class, 'test_type_id');
    }
}
