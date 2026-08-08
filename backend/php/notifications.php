<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $user_id = intval($_GET['user_id'] ?? 0);
    
    if ($user_id <= 0) {
        jsonResponse(['success' => false, 'message' => 'User ID is required']);
    }
    
    $stmt = $mysqli->prepare('SELECT id, user_id, title, message, type, read_status, action_url, created_at FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50');
    $stmt->bind_param('i', $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $notifications = [];
    while ($row = $result->fetch_assoc()) {
        $notifications[] = $row;
    }
    $stmt->close();
    
    jsonResponse(['success' => true, 'notifications' => $notifications]);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = requestBody();
    $action = sanitize($input['action'] ?? 'create');

    if ($action === 'create') {
        $user_id = intval($input['user_id'] ?? 0);
        $title = sanitize($input['title'] ?? '');
        $message = sanitize($input['message'] ?? '');
        $type = sanitize($input['type'] ?? 'info'); 
        $action_url = sanitize($input['action_url'] ?? '');

        if ($user_id <= 0 || empty($title) || empty($message)) {
            jsonResponse(['success' => false, 'message' => 'user_id, title, and message are required']);
        }

        $stmt = $mysqli->prepare('INSERT INTO notifications (user_id, title, message, type, action_url, read_status) VALUES (?, ?, ?, ?, ?, 0)');
        $stmt->bind_param('issss', $user_id, $title, $message, $type, $action_url);
        $saved = $stmt->execute();
        $stmt->close();

        if (!$saved) {
            jsonResponse(['success' => false, 'message' => 'Failed to create notification']);
        }

        jsonResponse(['success' => true, 'message' => 'Notification created']);
    }

    if ($action === 'mark_read') {
        $notification_id = intval($input['notification_id'] ?? 0);

        if ($notification_id <= 0) {
            jsonResponse(['success' => false, 'message' => 'Notification ID is required']);
        }

        $stmt = $mysqli->prepare('UPDATE notifications SET read_status = 1 WHERE id = ?');
        $stmt->bind_param('i', $notification_id);
        $updated = $stmt->execute();
        $stmt->close();

        if (!$updated) {
            jsonResponse(['success' => false, 'message' => 'Failed to mark notification as read']);
        }

        jsonResponse(['success' => true, 'message' => 'Notification marked as read']);
    }

    if ($action === 'mark_all_read') {
        $user_id = intval($input['user_id'] ?? 0);

        if ($user_id <= 0) {
            jsonResponse(['success' => false, 'message' => 'User ID is required']);
        }

        $stmt = $mysqli->prepare('UPDATE notifications SET read_status = 1 WHERE user_id = ? AND read_status = 0');
        $stmt->bind_param('i', $user_id);
        $updated = $stmt->execute();
        $stmt->close();

        if (!$updated) {
            jsonResponse(['success' => false, 'message' => 'Failed to mark all notifications as read']);
        }

        jsonResponse(['success' => true, 'message' => 'All notifications marked as read']);
    }

    if ($action === 'delete') {
        $notification_id = intval($input['notification_id'] ?? 0);

        if ($notification_id <= 0) {
            jsonResponse(['success' => false, 'message' => 'Notification ID is required']);
        }

        $stmt = $mysqli->prepare('DELETE FROM notifications WHERE id = ?');
        $stmt->bind_param('i', $notification_id);
        $deleted = $stmt->execute();
        $stmt->close();

        if (!$deleted) {
            jsonResponse(['success' => false, 'message' => 'Failed to delete notification']);
        }

        jsonResponse(['success' => true, 'message' => 'Notification deleted']);
    }

    jsonResponse(['success' => false, 'message' => 'Invalid action']);
}

jsonResponse(['success' => false, 'message' => 'Invalid request method']);
?>
