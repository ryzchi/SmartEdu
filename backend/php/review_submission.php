<?php
require_once 'config.php';

$input = requestBody();

$submission_id = intval($input['submission_id'] ?? 0);
$status = sanitize($input['status'] ?? '');
$feedback = sanitize($input['feedback'] ?? ''); 

if ($submission_id <= 0 || empty($status)) {
    jsonResponse(['success' => false, 'message' => 'Invalid data']);
}

$stmt = $mysqli->prepare(
    'UPDATE submissions SET status = ?, feedback = ? WHERE id = ?'
);
$stmt->bind_param('ssi', $status, $feedback, $submission_id);
$updated = $stmt->execute();
$stmt->close();

if ($updated) {
    jsonResponse(['success' => true, 'message' => 'Submission reviewed']);
} else {
    jsonResponse(['success' => false, 'message' => 'Update failed']);
}
?>