<?php
require_once 'config.php';

// ─── DEBUG LOG (temporary - remove in production) ───
file_put_contents('debug.log', '=== ' . date('Y-m-d H:i:s') . ' ===' . PHP_EOL, FILE_APPEND);
file_put_contents('debug.log', 'RAW INPUT: ' . file_get_contents('php://input') . PHP_EOL, FILE_APPEND);
file_put_contents('debug.log', 'POST: ' . print_r($_POST, true) . PHP_EOL, FILE_APPEND);
file_put_contents('debug.log', 'SERVER REQUEST_METHOD: ' . $_SERVER['REQUEST_METHOD'] . PHP_EOL, FILE_APPEND);

// ─── GET REQUEST BODY ────────────────────────────────────────────────
$input = requestBody();

// Debug: log parsed data
file_put_contents('debug.log', 'PARSED INPUT: ' . print_r($input, true) . PHP_EOL, FILE_APPEND);

// ─── SANITIZE INPUTS ────────────────────────────────────────────────
$email = isset($input['email']) ? sanitize($input['email']) : '';
$password = isset($input['password']) ? $input['password'] : '';
$role = isset($input['role']) ? sanitize($input['role']) : 'student';

file_put_contents('debug.log', 'EMAIL: ' . $email . PHP_EOL, FILE_APPEND);
file_put_contents('debug.log', 'ROLE: ' . $role . PHP_EOL, FILE_APPEND);

// ─── VALIDATE REQUIRED FIELDS ──────────────────────────────────────
if (empty($email) || empty($password)) {
    file_put_contents('debug.log', 'ERROR: Missing email or password' . PHP_EOL, FILE_APPEND);
    jsonResponse([
        'success' => false,
        'message' => 'Missing email or password'
    ]);
}

// ─── CHECK DATABASE CONNECTION ─────────────────────────────────────
if (!$mysqli || $mysqli->connect_errno) {
    file_put_contents('debug.log', 'ERROR: Database connection failed' . PHP_EOL, FILE_APPEND);
    jsonResponse([
        'success' => false,
        'message' => 'Database connection failed'
    ]);
}

// ─── QUERY USER ─────────────────────────────────────────────────────
$stmt = $mysqli->prepare('SELECT id, name, email, password, role, verified FROM users WHERE email = ? LIMIT 1');
if (!$stmt) {
    file_put_contents('debug.log', 'ERROR: Prepare failed: ' . $mysqli->error . PHP_EOL, FILE_APPEND);
    jsonResponse([
        'success' => false,
        'message' => 'Database error'
    ]);
}

$stmt->bind_param('s', $email);
$stmt->execute();
$stmt->bind_result($id, $name, $dbEmail, $dbPassword, $dbRole, $verified);

if (!$stmt->fetch()) {
    $stmt->close();
    file_put_contents('debug.log', 'ERROR: User not found: ' . $email . PHP_EOL, FILE_APPEND);
    jsonResponse([
        'success' => false,
        'message' => 'Invalid credentials'
    ]);
}
$stmt->close();

file_put_contents('debug.log', 'USER FOUND: ' . $dbEmail . ' | Role: ' . $dbRole . ' | Verified: ' . ($verified ? 'Yes' : 'No') . PHP_EOL, FILE_APPEND);

// ─── VERIFY PASSWORD ────────────────────────────────────────────────
$passwordValid = false;

// Check if password is hashed or plain text
if (password_verify($password, $dbPassword)) {
    $passwordValid = true;
} elseif ($password === $dbPassword) {
    // Legacy plain text password - rehash and update
    $passwordValid = true;
    $newHash = password_hash($password, PASSWORD_DEFAULT);
    $rehashStmt = $mysqli->prepare('UPDATE users SET password = ? WHERE id = ?');
    if ($rehashStmt) {
        $rehashStmt->bind_param('si', $newHash, $id);
        $rehashStmt->execute();
        $rehashStmt->close();
        file_put_contents('debug.log', 'PASSWORD REHASHED for user: ' . $dbEmail . PHP_EOL, FILE_APPEND);
    }
}

if (!$passwordValid) {
    file_put_contents('debug.log', 'ERROR: Invalid password for: ' . $dbEmail . PHP_EOL, FILE_APPEND);
    jsonResponse([
        'success' => false,
        'message' => 'Invalid credentials'
    ]);
}

// ─── CHECK ROLE ─────────────────────────────────────────────────────
if ($role !== $dbRole) {
    file_put_contents('debug.log', 'ERROR: Role mismatch. Expected: ' . $dbRole . ', Got: ' . $role . PHP_EOL, FILE_APPEND);
    jsonResponse([
        'success' => false,
        'message' => 'Role does not match. Please select correct role.'
    ]);
}

// ─── CHECK VERIFICATION ─────────────────────────────────────────────
if (!$verified) {
    file_put_contents('debug.log', 'ERROR: Account not verified: ' . $dbEmail . PHP_EOL, FILE_APPEND);
    jsonResponse([
        'success' => false,
        'message' => 'Please verify your account first.',
        'needsVerification' => true,
        'email' => $dbEmail
    ]);
}

// ─── LOGIN SUCCESS ──────────────────────────────────────────────────
file_put_contents('debug.log', '✅ LOGIN SUCCESS: ' . $dbEmail . PHP_EOL, FILE_APPEND);

jsonResponse([
    'success' => true,
    'message' => 'Login successful',
    'user' => [
        'id' => $id,
        'name' => $name,
        'email' => $dbEmail,
        'role' => $dbRole
    ]
]);
?>