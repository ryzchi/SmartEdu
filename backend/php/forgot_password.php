<?php
require_once 'config.php';

$input = requestBody();
$email = sanitize($input['email'] ?? '');

if (!$email || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonResponse(['success' => false, 'message' => 'Please enter a valid email address']);
}

$stmt = $mysqli->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
$stmt->bind_param('s', $email);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows === 0) {
    jsonResponse(['success' => false, 'message' => 'Email not found']);
}
$stmt->close();

$pin = strval(rand(100000, 999999));
$stmt = $mysqli->prepare('UPDATE users SET pin = ? WHERE email = ?');
$stmt->bind_param('ss', $pin, $email);
$updated = $stmt->execute();
$stmt->close();

if (!$updated) {
    jsonResponse(['success' => false, 'message' => 'Failed to generate reset code']);
}

jsonResponse(['success' => true, 'message' => 'Reset code generated', 'pin' => $pin]);
