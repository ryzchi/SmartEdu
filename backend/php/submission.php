<?php
require_once 'config.php';

$result = $mysqli->query(
    'SELECT submissions.*, assignments.title AS assignment_title
     FROM submissions
     LEFT JOIN assignments
     ON submissions.assignment_id = assignments.id
     ORDER BY submitted_at DESC'
);

$submissions = [];
while ($row = $result->fetch_assoc()) {
    $submitted = new DateTime($row['submitted_at']);
    $submitted->setTimezone(new DateTimeZone('Asia/Manila'));
    $row['submitted_at_formatted'] = $submitted->format('Y-m-d g:i A');
    $submissions[] = $row;
}

jsonResponse([
    'success' => true,
    'submissions' => $submissions
]);
?>