<?php
/**
 * Database connection (PDO + PostgreSQL, for Render deployment).
 *
 * Render injects a DATABASE_URL environment variable when you link a
 * Postgres database to a web service - this reads that automatically.
 * Locally (outside Render), it falls back to the DB_* constants below,
 * so you can still test against a local Postgres install if you want.
 */

$databaseUrl = getenv('DATABASE_URL');

if ($databaseUrl) {
    $parts = parse_url($databaseUrl);

    define('DB_HOST', $parts['host']);
    define('DB_PORT', $parts['port'] ?? 5432);
    define('DB_NAME', ltrim($parts['path'], '/'));
    define('DB_USER', $parts['user']);
    define('DB_PASS', $parts['pass']);
} else {
    // Local fallback values - only used if DATABASE_URL isn't set
    define('DB_HOST', 'localhost');
    define('DB_PORT', 5432);
    define('DB_NAME', 'oabs_db');
    define('DB_USER', 'postgres');
    define('DB_PASS', '');
}

try {
    $pdo = new PDO(
        "pgsql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME,
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]
    );
} catch (PDOException $e) {
    die("Database connection failed: " . $e->getMessage());
}
