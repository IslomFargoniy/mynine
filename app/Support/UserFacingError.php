<?php

namespace App\Support;

use Illuminate\Database\QueryException;
use PDOException;
use Throwable;

/**
 * The text of an error that may be shown to a user. Our own messages pass through; a database error never shows its
 * SQL (table names, keys, host): it is reported and replaced by a plain sentence (record in use, duplicate, …).
 */
final class UserFacingError
{
    public static function message(Throwable $e): string
    {
        if (! self::isDatabase($e)) {
            return $e->getMessage();
        }

        report($e);

        return __(self::databaseKey($e));
    }

    public static function isDatabase(Throwable $e): bool
    {
        return $e instanceof QueryException || $e instanceof PDOException || str_contains($e->getMessage(), 'SQLSTATE');
    }

    /** Translation key for a database error (MySQL codes, and SQLite's wording in tests). */
    public static function databaseKey(Throwable $e): string
    {
        $code = $e instanceof QueryException ? (int) ($e->errorInfo[1] ?? 0) : 0;
        $text = $e->getMessage();

        return match (true) {
            $code === 1451 || str_contains($text, 'Cannot delete or update a parent row'),
            str_contains($text, 'FOREIGN KEY constraint failed') && preg_match('/\bdelete\b/i', $text) === 1 => 'error_record_in_use',
            $code === 1452 || str_contains($text, 'FOREIGN KEY constraint failed') => 'error_related_record_missing',
            $code === 1062 || str_contains($text, 'UNIQUE constraint failed') => 'error_duplicate_record',
            default => 'error_database',
        };
    }
}
