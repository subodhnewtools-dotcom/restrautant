<?php
/**
 * POST /api/notifications/send
 * Send FCM push notification to topic
 */

$adminId = Auth::requireAuth();
$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    Response::validationError(['body' => 'Invalid JSON body']);
}

$topic = trim($input['topic'] ?? '');
$title = trim($input['title'] ?? '');
$body = trim($input['body'] ?? '');
$data = $input['data'] ?? null;

$errors = [];
if (empty($topic)) $errors['topic'] = 'Topic is required';
if (empty($title)) $errors['title'] = 'Title is required';
if (empty($body)) $errors['body'] = 'Body is required';

if (!empty($errors)) {
    Response::validationError($errors);
}

// Check if FCM key is configured
if (FCM_SERVER_KEY === 'your-fcm-server-key-here') {
    Response::error('FCM server key not configured on server', 500);
}

// Prepare FCM request
$fcmUrl = 'https://fcm.googleapis.com/fcm/send';
$fcmData = [
    'to' => '/topics/' . $topic,
    'notification' => [
        'title' => $title,
        'body' => $body,
        'sound' => 'default'
    ],
    'data' => $data ?? []
];

$headers = [
    'Authorization: key=' . FCM_SERVER_KEY,
    'Content-Type: application/json'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $fcmUrl);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fcmData));

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

$db = Database::getInstance()->getConnection();

if ($httpCode !== 200 || $error) {
    // Log failed notification
    $stmt = $db->prepare("INSERT INTO notifications_log (topic, title, body, data_json, status, error_message) VALUES (?, ?, ?, ?, 'failed', ?)");
    $stmt->execute([$topic, $title, $body, $data ? json_encode($data) : null, $error ?: 'HTTP ' . $httpCode]);
    
    Response::error('Failed to send notification: ' . ($error ?: 'HTTP ' . $httpCode), 500);
}

$result = json_decode($response, true);

// Log successful notification
$stmt = $db->prepare("INSERT INTO notifications_log (topic, title, body, data_json, status) VALUES (?, ?, ?, ?, 'sent')");
$stmt->execute([$topic, $title, $body, $data ? json_encode($data) : null]);

Response::success([
    'success' => $result['success'] ?? 0,
    'failure' => $result['failure'] ?? 0,
    'message_id' => $result['multicast_id'] ?? null
], 'Notification sent successfully');
