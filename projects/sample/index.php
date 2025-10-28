<?php
// YADS Sample Project - Shared Web Server Demo
echo "<h1>Welcome to " . $_SERVER['HTTP_HOST'] . "</h1>";
echo "<p>This is a sample project running on the shared YADS web server.</p>";
echo "<p>PHP Version: " . phpversion() . "</p>";
echo "<p>Server: " . $_SERVER['SERVER_SOFTWARE'] . "</p>";
echo "<p>Document Root: " . $_SERVER['DOCUMENT_ROOT'] . "</p>";
echo "<p>Project Subdomain: " . ($_SERVER['HTTP_HOST'] ?? 'Unknown') . "</p>";

// Show project information
echo "<h2>Project Information</h2>";
echo "<p>✅ YADS Docker shared web server is working correctly!</p>";
echo "<p>This project is served from: " . __DIR__ . "</p>";

// Test database connections
echo "<h2>Database Tests</h2>";

// MySQL test
try {
    $mysql = new PDO('mysql:host=mysql;dbname=yads', 'yads', 'yads123');
    echo "<p>✅ MySQL connection: OK</p>";
} catch (PDOException $e) {
    echo "<p>❌ MySQL connection: " . $e->getMessage() . "</p>";
}

// PostgreSQL test
try {
    $postgres = new PDO('pgsql:host=postgres;dbname=yads', 'yads', 'yads123');
    echo "<p>✅ PostgreSQL connection: OK</p>";
} catch (PDOException $e) {
    echo "<p>❌ PostgreSQL connection: " . $e->getMessage() . "</p>";
}

// Redis test
try {
    $redis = new Redis();
    $redis->connect('redis', 6379);
    $redis->auth('yads123');
    $redis->set('test', 'YADS Shared Web Server Test');
    echo "<p>✅ Redis connection: OK</p>";
} catch (Exception $e) {
    echo "<p>❌ Redis connection: " . $e->getMessage() . "</p>";
}

// Show environment variables
echo "<h2>Environment</h2>";
echo "<p>PROJECT_SUBDOMAIN: " . ($_SERVER['PROJECT_SUBDOMAIN'] ?? 'Not set') . "</p>";
echo "<p>DOCUMENT_ROOT: " . ($_SERVER['DOCUMENT_ROOT'] ?? 'Not set') . "</p>";

// Show available projects
echo "<h2>Available Projects</h2>";
$projects_dir = dirname(__DIR__);
if (is_dir($projects_dir)) {
    $projects = array_diff(scandir($projects_dir), ['.', '..']);
    echo "<ul>";
    foreach ($projects as $project) {
        if (is_dir($projects_dir . '/' . $project)) {
            echo "<li><a href='https://$project." . ($_SERVER['HTTP_HOST'] ?? 'localhost') . "'>$project</a></li>";
        }
    }
    echo "</ul>";
}

// Show PHP info if requested
if (isset($_GET['info'])) {
    echo "<h2>PHP Information</h2>";
    phpinfo();
}
?>
