<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Unsupported method']);
}

$input = requestBody();
$id = intval($input['id'] ?? 0);
if ($id <= 0) {
    jsonResponse(['success' => false, 'message' => 'Material id is required']);
}

$stmt = $mysqli->prepare('SELECT file_url FROM materials WHERE id = ? LIMIT 1');
$stmt->bind_param('i', $id);
$stmt->execute();
$stmt->bind_result($fileUrl);
if (!$stmt->fetch()) {
    $stmt->close();
    jsonResponse(['success' => false, 'message' => 'Material not found']);
}
$stmt->close();

$parsed = parse_url($fileUrl);
$path = $parsed['path'] ?? '';
$targetFile = $_SERVER['DOCUMENT_ROOT'] . str_replace('\\', '/', $path);
if (file_exists($targetFile)) {
    @unlink($targetFile);
}

$stmt = $mysqli->prepare('DELETE FROM materials WHERE id = ?');
$stmt->bind_param('i', $id);
$deleted = $stmt->execute();
$stmt->close();

if (!$deleted) {
    jsonResponse(['success' => false, 'message' => 'Failed to delete material']);
}

jsonResponse(['success' => true, 'message' => 'Material deleted']);
