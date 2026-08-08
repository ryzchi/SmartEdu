<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$host     = '127.0.0.1';
$user     = 'root';
$password = '';
$database = 'flutter_db';
$port     = 3307;

$conn = new mysqli($host, $user, $password, $database, $port);
if ($conn->connect_error) {
    echo json_encode(['success' => false, 'message' => 'Connection failed: ' . $conn->connect_error]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $quizId       = $_GET['quiz_id'] ?? '';
    $studentEmail = $_GET['student_email'] ?? '';

    if (empty($quizId) || empty($studentEmail)) {
        echo json_encode(['success' => false, 'message' => 'quiz_id and student_email are required']);
        exit;
    }

    $stmt = $conn->prepare("SELECT question_key, score FROM essay_scores WHERE quiz_id = ? AND student_email = ?");
    $stmt->bind_param('ss', $quizId, $studentEmail);
    $stmt->execute();
    $result = $stmt->get_result();

    $scores = new stdClass();
    while ($row = $result->fetch_assoc()) {
        $key = $row['question_key'];
        $scores->$key = intval($row['score']);
    }
    $stmt->close();
    $conn->close();

    echo json_encode(['success' => true, 'scores' => $scores]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data         = json_decode(file_get_contents('php://input'), true);
    $quizId       = $data['quiz_id'] ?? '';
    $studentEmail = $data['student_email'] ?? '';
    $questionKey  = $data['question_key'] ?? '';
    $score        = intval($data['score'] ?? 0);

    if (empty($quizId) || empty($studentEmail) || $questionKey === '') {
        echo json_encode(['success' => false, 'message' => 'Missing required fields']);
        exit;
    }

    if ($score < 5 || $score > 10) {
        echo json_encode(['success' => false, 'message' => 'Score must be between 5 and 10']);
        exit;
    }

    $stmt = $conn->prepare("
        INSERT INTO essay_scores (quiz_id, student_email, question_key, score)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE score = ?
    ");
    $stmt->bind_param('sssii', $quizId, $studentEmail, $questionKey, $score, $score);

    if ($stmt->execute()) {
        $totStmt = $conn->prepare("SELECT SUM(score) as total FROM essay_scores WHERE quiz_id = ? AND student_email = ?");
        $totStmt->bind_param('ss', $quizId, $studentEmail);
        $totStmt->execute();
        $totRow = $totStmt->get_result()->fetch_assoc();
        $totStmt->close();
        $total = intval($totRow['total'] ?? 0);

        echo json_encode(['success' => true, 'message' => 'Score saved', 'essay_total' => $total]);
    } else {
        echo json_encode(['success' => false, 'message' => $conn->error]);
    }

    $stmt->close();
    $conn->close();
    exit;
}

echo json_encode(['success' => false, 'message' => 'Invalid request method']);
?>