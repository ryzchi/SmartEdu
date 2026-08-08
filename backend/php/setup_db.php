<?php
/**
 * ADET System - Database Setup Script
 * Run this once to initialize the database
 * Access via: http://localhost/adet/backend/php/setup_db.php
 */

header('Content-Type: application/json; charset=utf-8');

$host = '127.0.0.1';
$user = 'root';
$password = '';
$database = 'flutter_db';

// Connect without database first to create it
$mysqli = new mysqli($host, $user, $password);
if ($mysqli->connect_errno) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $mysqli->connect_error]);
    exit;
}

// Create database
$createDb = $mysqli->query("CREATE DATABASE IF NOT EXISTS $database");
if (!$createDb) {
    echo json_encode(['success' => false, 'message' => 'Failed to create database: ' . $mysqli->error]);
    exit;
}

// Select database
if (!$mysqli->select_db($database)) {
    echo json_encode(['success' => false, 'message' => 'Failed to select database: ' . $mysqli->error]);
    exit;
}

$mysqli->set_charset('utf8mb4');

// Define table schemas
$tables = [
    'users' => "
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            email VARCHAR(150) UNIQUE NOT NULL,
            password VARCHAR(255) NOT NULL,
            role ENUM('student', 'teacher') NOT NULL DEFAULT 'student',
            verified BOOLEAN DEFAULT 0,
            pin VARCHAR(6),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_email (email),
            INDEX idx_role (role)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ",
    'assignments' => "
        CREATE TABLE IF NOT EXISTS assignments (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            description LONGTEXT,
            deadline DATETIME NOT NULL,
            created_by INT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_deadline (deadline),
            INDEX idx_created_at (created_at),
            FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ",
    'materials' => "
        CREATE TABLE IF NOT EXISTS materials (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            subject VARCHAR(150),
            description LONGTEXT,
            file_url VARCHAR(500),
            file_path VARCHAR(500),
            type ENUM('pdf', 'document', 'video', 'image', 'other') DEFAULT 'other',
            uploaded_by INT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_subject (subject),
            INDEX idx_type (type),
            INDEX idx_created_at (created_at),
            FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ",
    'submissions' => "
        CREATE TABLE IF NOT EXISTS submissions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            assignment_id INT NOT NULL,
            student_email VARCHAR(150) NOT NULL,
            student_id INT,
            file_url VARCHAR(500),
            file_path VARCHAR(500),
            status ENUM('Pending', 'Reviewed', 'Graded', 'Late') DEFAULT 'Pending',
            grade DECIMAL(5, 2),
            feedback LONGTEXT,
            submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            reviewed_at TIMESTAMP NULL,
            INDEX idx_assignment (assignment_id),
            INDEX idx_student_email (student_email),
            INDEX idx_status (status),
            INDEX idx_submitted_at (submitted_at),
            FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE,
            FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ",
    'announcements' => "
        CREATE TABLE IF NOT EXISTS announcements (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            content LONGTEXT,
            author_id INT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            visibility ENUM('public', 'students', 'teachers', 'all') DEFAULT 'public',
            INDEX idx_created_at (created_at),
            FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ",
    'events' => "
        CREATE TABLE IF NOT EXISTS events (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            description LONGTEXT,
            event_date DATETIME NOT NULL,
            event_end DATETIME,
            created_by INT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_event_date (event_date),
            FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ",
    'password_reset_tokens' => "
        CREATE TABLE IF NOT EXISTS password_reset_tokens (
            id INT AUTO_INCREMENT PRIMARY KEY,
            email VARCHAR(150) NOT NULL,
            token VARCHAR(255) UNIQUE NOT NULL,
            expires_at TIMESTAMP NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            used BOOLEAN DEFAULT 0,
            INDEX idx_email (email),
            INDEX idx_token (token),
            INDEX idx_expires_at (expires_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ",
    'quizzes' => "
        CREATE TABLE IF NOT EXISTS quizzes (
            id VARCHAR(100) PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            description LONGTEXT,
            questions LONGTEXT,
            teacher_id INT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_teacher_id (teacher_id),
            INDEX idx_created_at (created_at),
            FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ",
    'attendance' => "
        CREATE TABLE IF NOT EXISTS attendance (
            id INT AUTO_INCREMENT PRIMARY KEY,
            date VARCHAR(50) NOT NULL,
            display_date VARCHAR(100),
            statuses LONGTEXT,
            teacher_id INT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY unique_date_teacher (date, teacher_id),
            INDEX idx_teacher_id (teacher_id),
            INDEX idx_date (date),
            FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ",
    'notifications' => "
        CREATE TABLE IF NOT EXISTS notifications (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            title VARCHAR(255) NOT NULL,
            message LONGTEXT,
            type ENUM('info', 'warning', 'error', 'success') DEFAULT 'info',
            read_status BOOLEAN DEFAULT 0,
            action_url VARCHAR(500),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_user_id (user_id),
            INDEX idx_read_status (read_status),
            INDEX idx_created_at (created_at),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    "
];

$createdTables = [];
$errors = [];

// Create all tables
foreach ($tables as $tableName => $sql) {
    if ($mysqli->query($sql)) {
        $createdTables[] = $tableName;
    } else {
        $errors[] = "Failed to create $tableName: " . $mysqli->error;
    }
}

// Insert sample data
$sampleInserts = [
    "INSERT IGNORE INTO users (name, email, password, role, verified, pin) VALUES 
     ('Admin User', 'admin@adet.com', '\$2y\$10\$PLACEHOLDER_HASH', 'teacher', 1, '000000'),
     ('Test Student', 'student@adet.com', '\$2y\$10\$PLACEHOLDER_HASH', 'student', 1, '000000'),
     ('Test Teacher', 'teacher@adet.com', '\$2y\$10\$PLACEHOLDER_HASH', 'teacher', 1, '000000')"
];

foreach ($sampleInserts as $insert) {
    if (!$mysqli->query($insert)) {
        $errors[] = "Failed to insert sample data: " . $mysqli->error;
    }
}

$mysqli->close();

// Return response
$response = [
    'success' => count($errors) === 0,
    'database' => $database,
    'created_tables' => $createdTables,
    'total_tables' => count($createdTables),
    'errors' => $errors,
    'message' => count($errors) === 0 
        ? 'Database setup completed successfully!' 
        : 'Database setup completed with errors'
];

echo json_encode($response, JSON_PRETTY_PRINT);
?>
