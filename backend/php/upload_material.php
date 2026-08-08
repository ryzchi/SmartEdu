<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$host = '127.0.0.1';
$user = 'root';
$password = '';
$database = 'flutter_db';
$port = 3307;

$conn = new mysqli($host, $user, $password, $database, $port);
if ($conn->connect_error) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $conn->connect_error]);
    exit;
}
$conn->set_charset('utf8mb4');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get form data
    $title = $_POST['title'] ?? '';
    $subject = $_POST['subject'] ?? '';
    $uploaded_by = intval($_POST['uploaded_by'] ?? 0);
    
    if (empty($title) || empty($subject)) {
        echo json_encode(['success' => false, 'message' => 'Title and subject required']);
        $conn->close();
        exit;
    }
    
    if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
        $errorMessage = 'File upload failed';
        if (isset($_FILES['file']['error'])) {
            $errorMessage .= ': ' . $_FILES['file']['error'];
        }
        echo json_encode(['success' => false, 'message' => $errorMessage]);
        $conn->close();
        exit;
    }
    
    // Create upload directory if not exists
    $uploadDir = '../uploads/materials/';
    if (!file_exists($uploadDir)) {
        if (!mkdir($uploadDir, 0777, true)) {
            echo json_encode(['success' => false, 'message' => 'Failed to create upload directory']);
            $conn->close();
            exit;
        }
    }
    
    // Generate safe filename
    $originalName = basename($_FILES['file']['name']);
    $fileExt = pathinfo($originalName, PATHINFO_EXTENSION);
    $safeName = time() . '_' . preg_replace('/[^a-zA-Z0-9]/', '_', pathinfo($originalName, PATHINFO_FILENAME)) . '.' . $fileExt;
    $targetFile = $uploadDir . $safeName;
    $fileUrl = '/ADET/backend/uploads/materials/' . $safeName;
    
    // Move uploaded file
    if (move_uploaded_file($_FILES['file']['tmp_name'], $targetFile)) {
        $type = strtoupper($fileExt);
        
        // Save to database
        $stmt = $conn->prepare("INSERT INTO materials (title, subject, type, file_url, uploaded_by) VALUES (?, ?, ?, ?, ?)");
        if (!$stmt) {
            echo json_encode(['success' => false, 'message' => 'Database prepare failed: ' . $conn->error]);
            $conn->close();
            exit;
        }
        
        $stmt->bind_param('ssssi', $title, $subject, $type, $fileUrl, $uploaded_by);
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Upload successful',
                'file_url' => $fileUrl,
                'id' => $conn->insert_id,
                'title' => $title,
                'subject' => $subject,
                'type' => $type
            ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Database insert failed: ' . $stmt->error]);
        }
        $stmt->close();
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to save file to server']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method. Use POST.']);
}

$conn->close();
?>
