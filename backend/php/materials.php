<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $result = $mysqli->query('SELECT id, title, subject, file_url, type, created_at FROM materials ORDER BY created_at DESC');
    $materials = [];
    while ($row = $result->fetch_assoc()) {
        $materials[] = $row;
    }
    jsonResponse(['success' => true, 'materials' => $materials]);
}

jsonResponse(['success' => false, 'message' => 'Unsupported method']);
