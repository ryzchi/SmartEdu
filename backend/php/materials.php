<?php
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

$host = '127.0.0.1';
$user = 'root';
$password = '';
$database = 'flutter_db';
$port = 3307;

$mysqli = new mysqli($host, $user, $password, $database, $port);

if ($method === 'GET') {

    // ===== DOWNLOAD HANDLER =====
    if (isset($_GET['download'])) {
        $fileUrl = trim($_GET['file_url'] ?? '');
        $userTitle = trim($_GET['title'] ?? 'download');

        if (empty($fileUrl)) {
            http_response_code(400);
            exit;
        }

        $filePath = $_SERVER['DOCUMENT_ROOT'] . $fileUrl;

        if (!file_exists($filePath)) {
            http_response_code(404);
            exit;
        }

        $ext = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
        $safeTitle = preg_replace('/[<>:"\/\\\\|?*]/', '', $userTitle);
        $filename = $safeTitle . '.' . $ext;

        // Remove the JSON header set by default and force download
        header_remove('Content-Type');
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . $filename . '"');
        header('Content-Length: ' . filesize($filePath));
        header('Cache-Control: no-cache, must-revalidate');
        header('Pragma: public');
        ob_clean();
        flush();
        readfile($filePath);
        exit;
    }
    // ===== END DOWNLOAD HANDLER =====

    header('Content-Type: application/json; charset=utf-8');
    $stmt = $mysqli->prepare("SELECT id, title, subject, type, file_url, created_at FROM materials ORDER BY created_at DESC");
    $stmt->execute();
    $result = $stmt->get_result();
    $materials = [];
    while ($row = $result->fetch_assoc()) {
        $created = new DateTime($row['created_at']);
        $created->setTimezone(new DateTimeZone('Asia/Manila'));
        $row['created_at_formatted'] = $created->format('Y-m-d g:i A');
        $materials[] = $row;
    }
    $stmt->close();
    jsonResponse(['success' => true, 'materials' => $materials]);

} elseif ($method === 'POST') {

    header('Content-Type: application/json; charset=utf-8');
    $input = requestBody();
    $action = $input['action'] ?? 'create';

    if ($action === 'create') {
        $title = trim($input['title'] ?? '');
        $subject = trim($input['subject'] ?? '');
        $type = trim($input['type'] ?? '');
        $fileUrl = trim($input['file_url'] ?? '');
        $uploadedBy = intval($input['uploaded_by'] ?? 0);

        if (empty($title) || empty($subject)) {
            jsonResponse(['success' => false, 'message' => 'Title and subject are required']);
        }

        $checkColumn = $mysqli->query("SHOW COLUMNS FROM materials LIKE 'uploaded_by'");
        $hasUploadedBy = $checkColumn && $checkColumn->num_rows > 0;

        if ($hasUploadedBy) {
            $stmt = $mysqli->prepare("INSERT INTO materials (title, subject, type, file_url, uploaded_by) VALUES (?, ?, ?, ?, ?)");
            $stmt->bind_param('ssssi', $title, $subject, $type, $fileUrl, $uploadedBy);
        } else {
            $stmt = $mysqli->prepare("INSERT INTO materials (title, subject, type, file_url) VALUES (?, ?, ?, ?)");
            $stmt->bind_param('ssss', $title, $subject, $type, $fileUrl);
        }

        $saved = $stmt->execute();
        $stmt->close();

        if ($saved) {
            jsonResponse(['success' => true, 'message' => 'Material created']);
        } else {
            jsonResponse(['success' => false, 'message' => 'Database insert failed: ' . $mysqli->error]);
        }

    } elseif ($action === 'edit') {
        $id = intval($input['id'] ?? 0);
        $title = trim($input['title'] ?? '');
        $subject = trim($input['subject'] ?? '');
        $type = trim($input['type'] ?? '');

        if ($id <= 0 || empty($title) || empty($subject)) {
            jsonResponse(['success' => false, 'message' => 'Invalid input']);
        }

        $stmt = $mysqli->prepare("UPDATE materials SET title = ?, subject = ?, type = ? WHERE id = ?");
        $stmt->bind_param('sssi', $title, $subject, $type, $id);
        $updated = $stmt->execute();
        $stmt->close();

        jsonResponse(['success' => $updated, 'message' => $updated ? 'Updated' : 'Update failed']);

    } elseif ($action === 'delete') {
        $id = intval($input['id'] ?? 0);
        if ($id <= 0) {
            jsonResponse(['success' => false, 'message' => 'Invalid ID']);
        }

        $stmt = $mysqli->prepare("DELETE FROM materials WHERE id = ?");
        $stmt->bind_param('i', $id);
        $deleted = $stmt->execute();
        $stmt->close();

        jsonResponse(['success' => $deleted, 'message' => $deleted ? 'Deleted' : 'Delete failed']);

    } else {
        jsonResponse(['success' => false, 'message' => 'Unsupported action: ' . $action]);
    }

} else {
    header('Content-Type: application/json; charset=utf-8');
    jsonResponse(['success' => false, 'message' => 'Unsupported method: ' . $method]);
}
?>