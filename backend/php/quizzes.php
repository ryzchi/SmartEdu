<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $mysqli->query("ALTER TABLE quizzes ADD COLUMN IF NOT EXISTS subject VARCHAR(100) DEFAULT 'Mathematics'");

    $result = $mysqli->query("
        SELECT id, title, description, subject, questions, created_by as teacher_id, created_at 
        FROM quizzes 
        ORDER BY created_at DESC
    ");

    if (!$result) {
        jsonResponse(['success' => false, 'message' => 'Database error: ' . $mysqli->error]);
    }

    $quizzes = [];
    while ($row = $result->fetch_assoc()) {
        $row['questions'] = json_decode($row['questions'], true) ?: [];
        $quizzes[] = $row;
    }
    $result->close();

    jsonResponse(['success' => true, 'quizzes' => $quizzes]);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = requestBody();
    $action = $input['action'] ?? 'create';

    if ($action === 'create') {
        $id = sanitize($input['id'] ?? '');
        $title = sanitize($input['title'] ?? '');
        $description = sanitize($input['description'] ?? '');
        $subject = sanitize($input['subject'] ?? 'Mathematics');
        $created_by = intval($input['teacher_id'] ?? 0);

        if (empty($id) || empty($title) || $created_by <= 0) {
            jsonResponse(['success' => false, 'message' => 'ID, title, and teacher_id are required']);
        }

        $questions_json = '[]';
        $stmt = $mysqli->prepare('INSERT INTO quizzes (id, title, description, subject, questions, created_by) VALUES (?, ?, ?, ?, ?, ?)');
        $stmt->bind_param('sssssi', $id, $title, $description, $subject, $questions_json, $created_by);
        $saved = $stmt->execute();
        $stmt->close();

        if (!$saved) {
            jsonResponse(['success' => false, 'message' => 'Failed to create quiz: ' . $mysqli->error]);
        }
        jsonResponse(['success' => true, 'message' => 'Quiz created']);
    }

    if ($action === 'save') {
        $id = sanitize($input['id'] ?? '');
        $title = sanitize($input['title'] ?? '');
        $description = sanitize($input['description'] ?? '');
        $subject = sanitize($input['subject'] ?? 'Mathematics');
        $questions = json_encode($input['questions'] ?? []);
        $created_by = intval($input['teacher_id'] ?? 0);

        if (empty($id) || $created_by <= 0) {
            jsonResponse(['success' => false, 'message' => 'ID and teacher_id are required']);
        }

        $checkStmt = $mysqli->prepare('SELECT id FROM quizzes WHERE id = ?');
        $checkStmt->bind_param('s', $id);
        $checkStmt->execute();
        $exists = $checkStmt->get_result()->num_rows > 0;
        $checkStmt->close();

        if ($exists) {
            $stmt = $mysqli->prepare('UPDATE quizzes SET title = ?, description = ?, subject = ?, questions = ? WHERE id = ?');
            $stmt->bind_param('sssss', $title, $description, $subject, $questions, $id);
            $updated = $stmt->execute();
            $stmt->close();
            if (!$updated) {
                jsonResponse(['success' => false, 'message' => 'Failed to update quiz: ' . $mysqli->error]);
            }
            jsonResponse(['success' => true, 'message' => 'Quiz updated']);
        } else {
            $stmt = $mysqli->prepare('INSERT INTO quizzes (id, title, description, subject, questions, created_by) VALUES (?, ?, ?, ?, ?, ?)');
            $stmt->bind_param('sssssi', $id, $title, $description, $subject, $questions, $created_by);
            $saved = $stmt->execute();
            $stmt->close();
            if (!$saved) {
                jsonResponse(['success' => false, 'message' => 'Failed to save quiz: ' . $mysqli->error]);
            }
            jsonResponse(['success' => true, 'message' => 'Quiz saved']);
        }
    }

    if ($action === 'delete') {
        $id = sanitize($input['id'] ?? '');
        if (empty($id)) {
            jsonResponse(['success' => false, 'message' => 'Quiz id is required']);
        }
        $stmt = $mysqli->prepare('DELETE FROM quizzes WHERE id = ?');
        $stmt->bind_param('s', $id);
        $deleted = $stmt->execute();
        $stmt->close();
        if (!$deleted) {
            jsonResponse(['success' => false, 'message' => 'Failed to delete quiz: ' . $mysqli->error]);
        }
        jsonResponse(['success' => true, 'message' => 'Quiz deleted']);
    }

    jsonResponse(['success' => false, 'message' => 'Invalid action']);
}

jsonResponse(['success' => false, 'message' => 'Invalid request method']);
?>