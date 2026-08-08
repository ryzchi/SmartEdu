<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['success' => false, 'message' => 'Unsupported method']);
}

$stmt = $mysqli->prepare("SELECT id, name, email FROM users WHERE role = 'student' AND verified = 1 ORDER BY name ASC");
$stmt->execute();
$result = $stmt->get_result();
$students = [];
while ($row = $result->fetch_assoc()) {
    $students[] = $row;
}
$stmt->close();

jsonResponse(['success' => true, 'students' => $students]);