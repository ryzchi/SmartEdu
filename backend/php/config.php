<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json; charset=utf-8');

$host = '127.0.0.1';
$user = 'root';
$password = '';
$database = 'flutter_db';

$mysqli = new mysqli($host, $user, $password, $database);
if ($mysqli->connect_errno) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $mysqli->connect_error]);
    exit;
}
$mysqli->set_charset('utf8mb4');

function requestBody() {
    $json = file_get_contents('php://input');
    return json_decode($json, true) ?: [];
}

function jsonResponse($data) {
    echo json_encode($data);
    exit;
}

function sanitize($value) {
    return htmlspecialchars(trim($value), ENT_QUOTES, 'UTF-8');
}
