<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $quiz_id = $_GET['quiz_id'] ?? '';
    $student_email = $_GET['student_email'] ?? '';

    if (empty($quiz_id) && empty($student_email)) {
        jsonResponse(['success' => false, 'message' => 'quiz_id or student_email is required']);
    }

    if (!empty($quiz_id) && !empty($student_email)) {
        $stmt = $mysqli->prepare("SELECT * FROM quiz_attempts WHERE quiz_id = ? AND student_email = ? ORDER BY submitted_at DESC LIMIT 1");
        $stmt->bind_param('ss', $quiz_id, $student_email);
    } elseif (!empty($quiz_id)) {
        $stmt = $mysqli->prepare("SELECT * FROM quiz_attempts WHERE quiz_id = ? ORDER BY submitted_at DESC");
        $stmt->bind_param('s', $quiz_id);
    } else {
        $stmt = $mysqli->prepare("SELECT * FROM quiz_attempts WHERE student_email = ? ORDER BY submitted_at DESC");
        $stmt->bind_param('s', $student_email);
    }

    $stmt->execute();
    $result = $stmt->get_result();
    $attempts = [];
while ($row = $result->fetch_assoc()) {
    $decoded = json_decode($row['answers'], true);
    if (!is_array($decoded) || isset($decoded[0])) {
        $decoded = [
            'multiple_choice' => [],
            'identification'  => [],
            'essay'           => [],
        ];
    }
    $row['answers'] = $decoded;

    $esStmt = $mysqli->prepare("SELECT question_key, score FROM essay_scores WHERE quiz_id = ? AND student_email = ?");
    $esStmt->bind_param('ss', $row['quiz_id'], $row['student_email']);
    $esStmt->execute();
    $esResult = $esStmt->get_result();
    $essayScores = [];
    while ($esRow = $esResult->fetch_assoc()) {
        $essayScores[$esRow['question_key']] = intval($esRow['score']);
    }
    $esStmt->close();
    $row['essay_scores']      = $essayScores;
    $row['essay_score_total'] = array_sum($essayScores);

    $attempts[] = $row;
}
    $stmt->close();

    jsonResponse(['success' => true, 'attempts' => $attempts]);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = requestBody();
    $action = $input['action'] ?? 'save';

    if ($action === 'save') {
        $quiz_id       = sanitize($input['quiz_id'] ?? '');
        $student_email = sanitize($input['student_email'] ?? '');
        $student_name  = sanitize($input['student_name'] ?? '');
        $score_correct = intval($input['score_correct'] ?? 0);
        $score_total   = intval($input['score_total'] ?? 0);
        $score_percent = floatval($input['score_percent'] ?? 0);

        $answersRaw = $input['answers'] ?? [];
        if (is_string($answersRaw)) {
            $decoded = json_decode($answersRaw, true);
            if (is_array($decoded) && !isset($decoded[0])) {
                $answers = $answersRaw; 
            } else {
                $answers = json_encode([
                    'multiple_choice' => [],
                    'identification'  => [],
                    'essay'           => [],
                ]);
            }
        } elseif (is_array($answersRaw) && !isset($answersRaw[0])) {
            $answers = json_encode($answersRaw);
        } else {
            $answers = json_encode([
                'multiple_choice' => [],
                'identification'  => [],
                'essay'           => [],
            ]);
        }

        if (empty($quiz_id) || empty($student_email)) {
            jsonResponse(['success' => false, 'message' => 'quiz_id and student_email are required']);
        }

        $checkStmt = $mysqli->prepare("SELECT id FROM quiz_attempts WHERE quiz_id = ? AND student_email = ?");
        $checkStmt->bind_param('ss', $quiz_id, $student_email);
        $checkStmt->execute();
        $exists = $checkStmt->get_result()->num_rows > 0;
        $checkStmt->close();

        if ($exists) {
            $stmt = $mysqli->prepare("UPDATE quiz_attempts SET answers = ?, score_correct = ?, score_total = ?, score_percent = ?, student_name = ?, submitted_at = NOW() WHERE quiz_id = ? AND student_email = ?");
            $stmt->bind_param('siidsss', $answers, $score_correct, $score_total, $score_percent, $student_name, $quiz_id, $student_email);
        } else {
            $stmt = $mysqli->prepare("INSERT INTO quiz_attempts (quiz_id, student_email, student_name, answers, score_correct, score_total, score_percent) VALUES (?, ?, ?, ?, ?, ?, ?)");
            $stmt->bind_param('ssssiid', $quiz_id, $student_email, $student_name, $answers, $score_correct, $score_total, $score_percent);
        }

        $saved = $stmt->execute();
        $stmt->close();

        if ($saved) {
            jsonResponse(['success' => true, 'message' => 'Quiz attempt saved']);
        } else {
            jsonResponse(['success' => false, 'message' => 'Failed to save: ' . $mysqli->error]);
        }
    }

    jsonResponse(['success' => false, 'message' => 'Invalid action']);
}

jsonResponse(['success' => false, 'message' => 'Invalid request method']);
?>