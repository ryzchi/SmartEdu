<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Unsupported method']);
}

$input = requestBody();
$id = intval($input['id'] ?? 0);
$title = sanitize($input['title'] ?? '');
$subject = sanitize($input['subject'] ?? '');
$type = sanitize($input['type'] ?? '');

if ($id <= 0 || empty($title) || empty($subject) || empty($type)) {
    jsonResponse(['success' => false, 'message' => 'Material id, title, subject and type are required']);
}

$stmt = $mysqli->prepare('UPDATE materials SET title = ?, subject = ?, type = ? WHERE id = ?');
$stmt->bind_param('sssi', $title, $subject, $type, $id);
$updated = $stmt->execute();
$stmt->close();

if (!$updated) {
    jsonResponse(['success' => false, 'message' => 'Failed to update material']);
}

jsonResponse(['success' => true, 'message' => 'Material updated']);
