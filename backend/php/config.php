<?php

date_default_timezone_set('Asia/Manila');

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

// ─── HANDLE PREFLIGHT ──────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ─── DATABASE CONNECTION ───────────────────────────────────────────
$host = '127.0.0.1';
$user = 'root';
$password = '';
$database = 'flutter_db';
$port = 3307;

$mysqli = new mysqli($host, $user, $password, $database, $port);
if ($mysqli->connect_errno) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed: ' . $mysqli->connect_error
    ]);
    exit;
}
$mysqli->set_charset('utf8mb4');

// ─── REQUEST BODY PARSER ───────────────────────────────────────────
function requestBody() {
    $json = file_get_contents('php://input');
    
    // Try JSON decode
    $data = json_decode($json, true);
    
    // If JSON fails or empty, fallback to $_POST
    if (!$data || empty($data)) {
        $data = $_POST;
    }
    
    // If still empty, try to parse form data
    if (empty($data)) {
        parse_str(file_get_contents('php://input'), $data);
    }
    
    return $data;
}

// ─── JSON RESPONSE ──────────────────────────────────────────────────
function jsonResponse($data) {
    echo json_encode($data);
    exit;
}

// ─── SANITIZE ───────────────────────────────────────────────────────
function sanitize($value) {
    if ($value === null) return '';
    return htmlspecialchars(trim($value), ENT_QUOTES, 'UTF-8');
}
?>