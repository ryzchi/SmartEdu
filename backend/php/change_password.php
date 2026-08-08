<?php
require_once 'config.php';

$input = requestBody();
$email = sanitize($input['email'] ?? '');
$oldPassword = $input['old_password'] ?? '';
$newPassword = $input['new_password'] ?? '';
$confirmPassword = $input['confirm_password'] ?? '';

if (!$email || !$oldPassword || !$newPassword || !$confirmPassword) {
    jsonResponse(['success' => false, 'message' => 'Missing required fields']);
}
if ($newPassword !== $confirmPassword) {
    jsonResponse(['success' => false, 'message' => 'Passwords do not match']);
}
if (strlen($newPassword) < 6) {
    jsonResponse(['success' => false, 'message' => 'Password must be at least 6 characters']);
}

$stmt = $mysqli->prepare('SELECT password FROM users WHERE email = ? LIMIT 1');
$stmt->bind_param('s', $email);
$stmt->execute();
$stmt->bind_result($dbPassword);
if (!$stmt->fetch()) {
    jsonResponse(['success' => false, 'message' => 'User not found']);
}
$stmt->close();

if (!password_verify($oldPassword, $dbPassword)) {
    jsonResponse(['success' => false, 'message' => 'Incorrect current password']);
}

$hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
$stmt = $mysqli->prepare('UPDATE users SET password = ? WHERE email = ?');
$stmt->bind_param('ss', $hashedPassword, $email);
$updated = $stmt->execute();
$stmt->close();

if (!$updated) {
    jsonResponse(['success' => false, 'message' => 'Failed to update password']);
}

jsonResponse(['success' => true, 'message' => 'Password changed successfully']);
