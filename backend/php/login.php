<?php
require_once 'config.php';

$input = requestBody();
$email = sanitize($input['email'] ?? '');
$password = $input['password'] ?? '';
$role = sanitize($input['role'] ?? 'student');

if (!$email || !$password) {
    jsonResponse(['success' => false, 'message' => 'Missing email or password']);
}

$stmt = $mysqli->prepare('SELECT id, name, email, password, role, verified FROM users WHERE email = ? LIMIT 1');
$stmt->bind_param('s', $email);
$stmt->execute();
$stmt->bind_result($id, $name, $dbEmail, $dbPassword, $dbRole, $verified);
if (!$stmt->fetch()) {
    jsonResponse(['success' => false, 'message' => 'Invalid credentials']);
}
$stmt->close();

if (!password_verify($password, $dbPassword) && $password !== $dbPassword) {
    jsonResponse(['success' => false, 'message' => 'Invalid credentials']);
}

if ($password === $dbPassword && !str_starts_with($dbPassword, '$2y$')) {
    $newHash = password_hash($password, PASSWORD_DEFAULT);
    $rehashStmt = $mysqli->prepare('UPDATE users SET password = ? WHERE id = ?');
    $rehashStmt->bind_param('si', $newHash, $id);
    $rehashStmt->execute();
    $rehashStmt->close();
}

if ($role !== $dbRole) {
    jsonResponse(['success' => false, 'message' => 'Role does not match']);
}
if (!$verified) {
    jsonResponse(['success' => false, 'message' => 'Please verify your account first.', 'needsVerification' => true, 'email' => $email]);
}

jsonResponse(['success' => true, 'message' => 'Login successful', 'user' => ['id' => $id, 'name' => $name, 'email' => $dbEmail, 'role' => $dbRole]]);
