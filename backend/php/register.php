<?php
require_once 'config.php';

$input = requestBody();
$name = sanitize($input['name'] ?? '');
$email = sanitize($input['email'] ?? '');
$password = $input['password'] ?? '';
$role = strtolower(sanitize($input['role'] ?? 'student'));
if ($role === 'faculty') {
    $role = 'teacher';
}

if (!$name || !$email || !$password || !$role) {
    jsonResponse(['success' => false, 'message' => 'Missing required fields']);
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonResponse(['success' => false, 'message' => 'Invalid email address']);
}
if (strlen($password) < 6) {
    jsonResponse(['success' => false, 'message' => 'Password must be at least 6 characters']);
}
if (!in_array($role, ['student', 'teacher'], true)) {
    jsonResponse(['success' => false, 'message' => 'Invalid role']);
}

$stmt = $mysqli->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
$stmt->bind_param('s', $email);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows > 0) {
    jsonResponse(['success' => false, 'message' => 'Email already registered']);
}
$stmt->close();

$pin = strval(rand(100000, 999999));
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);

$stmt = $mysqli->prepare('INSERT INTO users (name, email, password, role, verified, pin) VALUES (?, ?, ?, ?, 0, ?)');
$stmt->bind_param('sssss', $name, $email, $hashedPassword, $role, $pin);
$inserted = $stmt->execute();
$stmt->close();

if (!$inserted) {
    jsonResponse(['success' => false, 'message' => 'Registration failed']);
}

jsonResponse(['success' => true, 'message' => 'Registration successful', 'email' => $email, 'pin' => $pin]);
