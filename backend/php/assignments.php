<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $now = new DateTime();
    
    $result = $mysqli->query("
        SELECT 
            id, 
            title, 
            description, 
            deadline, 
            subject, 
            created_at
        FROM assignments 
        ORDER BY created_at DESC"
    );
    
    $assignments = [];
    while ($row = $result->fetch_assoc()) {
        $deadline = new DateTime($row['deadline']);
        $created = new DateTime($row['created_at']);
        
        $deadline->setTimezone(new DateTimeZone('Asia/Manila'));
        $created->setTimezone(new DateTimeZone('Asia/Manila'));
        
        $isActive = ($deadline > $now) ? 1 : 0;
        
        $row['deadline_formatted'] = $deadline->format('Y-m-d g:i A');
        $row['created_at_formatted'] = $created->format('Y-m-d g:i A');
        $row['is_active'] = $isActive;
        $assignments[] = $row;
    }
    jsonResponse(['success' => true, 'assignments' => $assignments]);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = requestBody();
    $action = $input['action'] ?? 'create';

    if ($action === 'create') {
        $title = sanitize($input['title'] ?? '');
        $description = sanitize($input['description'] ?? '');
        $deadline = sanitize($input['deadline'] ?? '');
        $subject = sanitize($input['subject'] ?? 'No Subject');

        if (empty($title) || empty($deadline)) {
            jsonResponse(['success' => false, 'message' => 'Title and deadline are required']);
        }

        $stmt = $mysqli->prepare('INSERT INTO assignments (title, description, deadline, subject) VALUES (?, ?, ?, ?)');
        $stmt->bind_param('ssss', $title, $description, $deadline, $subject);
        $saved = $stmt->execute();
        $stmt->close();

        if (!$saved) {
            jsonResponse(['success' => false, 'message' => 'Failed to create assignment']);
        }
        jsonResponse(['success' => true, 'message' => 'Assignment created']);
    }

    if ($action === 'edit') {
        $id = intval($input['id'] ?? 0);
        $title = sanitize($input['title'] ?? '');
        $description = sanitize($input['description'] ?? '');
        $deadline = sanitize($input['deadline'] ?? '');
        $subject = sanitize($input['subject'] ?? 'No Subject');

        if ($id <= 0 || empty($title) || empty($deadline)) {
            jsonResponse(['success' => false, 'message' => 'Assignment id, title and deadline are required']);
        }

        $stmt = $mysqli->prepare('UPDATE assignments SET title = ?, description = ?, deadline = ?, subject = ? WHERE id = ?');
        $stmt->bind_param('ssssi', $title, $description, $deadline, $subject, $id);
        $updated = $stmt->execute();
        $stmt->close();

        if (!$updated) {
            jsonResponse(['success' => false, 'message' => 'Failed to update assignment']);
        }
        jsonResponse(['success' => true, 'message' => 'Assignment updated']);
    }

    if ($action === 'delete') {
        $id = intval($input['id'] ?? 0);
        if ($id <= 0) {
            jsonResponse(['success' => false, 'message' => 'Assignment id is required']);
        }
        $stmt = $mysqli->prepare('DELETE FROM assignments WHERE id = ?');
        $stmt->bind_param('i', $id);
        $deleted = $stmt->execute();
        $stmt->close();

        if (!$deleted) {
            jsonResponse(['success' => false, 'message' => 'Failed to delete assignment']);
        }
        jsonResponse(['success' => true, 'message' => 'Assignment deleted']);
    }
}

jsonResponse(['success' => false, 'message' => 'Unsupported method']);
?>