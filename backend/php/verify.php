<?php
require_once 'config.php';

$input = requestBody();
$email = sanitize($input['email'] ?? '');
$pin = sanitize($input['pin'] ?? '');

if (!$email || !$pin) {
    jsonResponse(['success' => false, 'message' => 'Missing email or PIN']);
}

$stmt = $mysqli->prepare('SELECT id FROM users WHERE email = ? AND pin = ? LIMIT 1');
$stmt->bind_param('ss', $email, $pin);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows === 0) {
    jsonResponse(['success' => false, 'message' => 'Invalid verification code']);
}
$stmt->close();

$stmt = $mysqli->prepare('UPDATE users SET verified = 1, pin = NULL WHERE email = ?');
$stmt->bind_param('s', $email);
$updated = $stmt->execute();
$stmt->close();

if (!$updated) {
    jsonResponse(['success' => false, 'message' => 'Verification failed']);
}

jsonResponse(['success' => true, 'message' => 'Account verified successfully']);
