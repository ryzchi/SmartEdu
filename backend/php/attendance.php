<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $result = $mysqli->query('SELECT id, date, display_date, statuses, teacher_id, created_at FROM attendance ORDER BY date DESC');
    if (!$result) {
        jsonResponse(['success' => false, 'message' => 'Database error: ' . $mysqli->error]);
    }
    $attendance_records = [];
    while ($row = $result->fetch_assoc()) {
        $row['statuses'] = json_decode($row['statuses'], true) ?: [];
        $attendance_records[] = $row;
    }
        jsonResponse(['success' => true, 'attendance_records' => $attendance_records]);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = requestBody();
    $action = $input['action'] ?? 'create';

    if ($action === 'create') {
        $date = sanitize($input['date'] ?? '');
        $display_date = sanitize($input['display_date'] ?? '');
        $statuses = json_encode($input['statuses'] ?? []);
        $teacher_id = intval($input['teacher_id'] ?? 0);

        if (empty($date) || $teacher_id <= 0) {
            jsonResponse(['success' => false, 'message' => 'Date and teacher_id are required']);
        }

        $checkStmt = $mysqli->prepare('SELECT id FROM attendance WHERE date = ? AND teacher_id = ?');
        $checkStmt->bind_param('si', $date, $teacher_id);
        $checkStmt->execute();
        $exists = $checkStmt->get_result()->num_rows > 0;
        $checkStmt->close();

        if ($exists) {
            jsonResponse(['success' => false, 'message' => 'Attendance already exists for this date']);
        }

        $stmt = $mysqli->prepare('INSERT INTO attendance (date, display_date, statuses, teacher_id) VALUES (?, ?, ?, ?)');
        $stmt->bind_param('sssi', $date, $display_date, $statuses, $teacher_id);
        $saved = $stmt->execute();
        $stmt->close();

        if (!$saved) {
            jsonResponse(['success' => false, 'message' => 'Failed to create attendance record: ' . $mysqli->error]);
        }
        jsonResponse(['success' => true, 'message' => 'Attendance record created']);
    }

    if ($action === 'save') {
        $date = sanitize($input['date'] ?? '');
        $display_date = sanitize($input['display_date'] ?? '');
        $statuses = json_encode($input['statuses'] ?? []);
        $teacher_id = intval($input['teacher_id'] ?? 0);

        if (empty($date) || $teacher_id <= 0) {
            jsonResponse(['success' => false, 'message' => 'Date and teacher_id are required']);
        }

        $checkStmt = $mysqli->prepare('SELECT id FROM attendance WHERE date = ? AND teacher_id = ?');
        $checkStmt->bind_param('si', $date, $teacher_id);
        $checkStmt->execute();
        $exists = $checkStmt->get_result()->num_rows > 0;
        $checkStmt->close();

        if ($exists) {
            $stmt = $mysqli->prepare('UPDATE attendance SET display_date = ?, statuses = ? WHERE date = ? AND teacher_id = ?');
            $stmt->bind_param('sssi', $display_date, $statuses, $date, $teacher_id);
            $updated = $stmt->execute();
            $stmt->close();
            if (!$updated) {
                jsonResponse(['success' => false, 'message' => 'Failed to update attendance: ' . $mysqli->error]);
            }
            jsonResponse(['success' => true, 'message' => 'Attendance updated']);
        } else {
            $stmt = $mysqli->prepare('INSERT INTO attendance (date, display_date, statuses, teacher_id) VALUES (?, ?, ?, ?)');
            $stmt->bind_param('sssi', $date, $display_date, $statuses, $teacher_id);
            $saved = $stmt->execute();
            $stmt->close();
            if (!$saved) {
                jsonResponse(['success' => false, 'message' => 'Failed to save attendance: ' . $mysqli->error]);
            }
            jsonResponse(['success' => true, 'message' => 'Attendance saved']);
        }
    }

    jsonResponse(['success' => false, 'message' => 'Invalid action']);
}

jsonResponse(['success' => false, 'message' => 'Invalid request method']);
?>