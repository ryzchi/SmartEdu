<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $result = $mysqli->query('SELECT id, title, description, deadline, created_at FROM assignments ORDER BY created_at DESC');
    $assignments = [];
    while ($row = $result->fetch_assoc()) {
        $assignments[] = $row;
    }
    jsonResponse(['success' => true, 'assignments' => $assignments]);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = requestBody();
    $title = sanitize($input['title'] ?? '');
    $description = sanitize($input['description'] ?? '');
    $deadline = sanitize($input['deadline'] ?? '');

    if (empty($title) || empty($deadline)) {
        jsonResponse(['success' => false, 'message' => 'Title and deadline are required']);
    }

    $stmt = $mysqli->prepare('INSERT INTO assignments (title, description, deadline) VALUES (?, ?, ?)');
    $stmt->bind_param('sss', $title, $description, $deadline);
    $saved = $stmt->execute();
    $stmt->close();

    if (!$saved) {
        jsonResponse(['success' => false, 'message' => 'Failed to create assignment']);
    }

    jsonResponse(['success' => true, 'message' => 'Assignment created']);
}

jsonResponse(['success' => false, 'message' => 'Unsupported method']);
