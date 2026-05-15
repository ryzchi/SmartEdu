<?php
require_once 'config.php';

$input = requestBody();
$email = sanitize($input['email'] ?? '');
$pin = sanitize($input['pin'] ?? '');
$newPassword = $input['new_password'] ?? '';
$confirmPassword = $input['confirm_password'] ?? '';

if (!$email || !$pin || !$newPassword || !$confirmPassword) {
    jsonResponse(['success' => false, 'message' => 'Missing required fields']);
}
if ($newPassword !== $confirmPassword) {
    jsonResponse(['success' => false, 'message' => 'Passwords do not match']);
}
if (strlen($newPassword) < 6) {
    jsonResponse(['success' => false, 'message' => 'Password must be at least 6 characters']);
}

$stmt = $mysqli->prepare('SELECT id FROM users WHERE email = ? AND pin = ? LIMIT 1');
$stmt->bind_param('ss', $email, $pin);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows === 0) {
    jsonResponse(['success' => false, 'message' => 'Invalid reset code']);
}
$stmt->close();

$hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
$stmt = $mysqli->prepare('UPDATE users SET password = ?, pin = NULL WHERE email = ?');
$stmt->bind_param('ss', $hashedPassword, $email);
$updated = $stmt->execute();
$stmt->close();

if (!$updated) {
    jsonResponse(['success' => false, 'message' => 'Failed to reset password']);
}

jsonResponse(['success' => true, 'message' => 'Password reset successfully']);
