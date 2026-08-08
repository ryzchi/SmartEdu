<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $assignment_id = $_POST['assignment_id'] ?? '';
    $student_email = $_POST['student_email'] ?? '';
    $comment = $_POST['comment'] ?? '';
    $file_name = $_POST['file_name'] ?? '';

    error_log("POST data: assignment_id=$assignment_id, student_email=$student_email, comment=$comment, file_name=$file_name");

    if (empty($assignment_id) || empty($student_email)) {
        jsonResponse(['success' => false, 'message' => 'Assignment ID and student email are required']);
    }

    if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
        jsonResponse(['success' => false, 'message' => 'No file uploaded']);
    }

    $uploadDir = '../uploads/';
    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    $fileName = time() . '_' . basename($_FILES['file']['name']);
    $targetFile = $uploadDir . $fileName;
    $fileSize = $_FILES['file']['size'];

    if (move_uploaded_file($_FILES['file']['tmp_name'], $targetFile)) {
        $fileUrl = 'uploads/' . $fileName;

        $comment = !empty($comment) ? $comment : '';

        $stmt = $mysqli->prepare(
            'INSERT INTO submissions (assignment_id, student_email, file_url, file_name, file_size, comment, status, feedback, submitted_at) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())'
        );
        $status = 'Pending';
        $feedback = '';
        $stmt->bind_param('isssisss', $assignment_id, $student_email, $fileUrl, $fileName, $fileSize, $comment, $status, $feedback);
        $saved = $stmt->execute();
        $stmt->close();

        if ($saved) {
            jsonResponse(['success' => true, 'message' => 'Assignment submitted successfully']);
        } else {
            jsonResponse(['success' => false, 'message' => 'Database error: ' . $mysqli->error]);
        }
    } else {
        jsonResponse(['success' => false, 'message' => 'Failed to upload file']);
    }
} else {
    jsonResponse(['success' => false, 'message' => 'Invalid request method']);
}
?>