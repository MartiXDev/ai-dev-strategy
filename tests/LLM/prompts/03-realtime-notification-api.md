# Test Prompt 03: Real-time Notification API with SignalR

## Prompt ID

`03-realtime-notification-api`

## Category

Web API, SignalR, Real-time Communication, Notifications

## Description

Generate a real-time notification system using SignalR with proper hub management and message broadcasting.

## Prompt Text

Generate a real-time notification API using SignalR in C# 14 and .NET 10 with the following requirements:

**Notification System Requirements:**

1. Real-time notifications using SignalR
2. Multiple notification types (Info, Warning, Error, Success)
3. User-specific and broadcast notifications
4. Notification history tracking
5. Read/unread status management
6. Notification preferences per user

**Notification Model:**

- Id (Guid)
- UserId (Guid, nullable for broadcast)
- Type (enum: Info, Warning, Error, Success)
- Title (string, required, max 200 characters)
- Message (string, required, max 1000 characters)
- ActionUrl (string, nullable)
- IsRead (bool, default false)
- CreatedAt (DateTime)
- ReadAt (DateTime, nullable)
- ExpiresAt (DateTime, nullable)
- Priority (enum: Low, Normal, High, Urgent)

**API Endpoints Required:**

1. GET /api/notifications - Get user's notifications (with pagination, filtering)
2. GET /api/notifications/{id} - Get specific notification
3. POST /api/notifications/send - Send notification (admin/system only)
4. POST /api/notifications/broadcast - Broadcast to all users (admin only)
5. PUT /api/notifications/{id}/read - Mark as read
6. PUT /api/notifications/mark-all-read - Mark all as read
7. DELETE /api/notifications/{id} - Delete notification
8. GET /api/notifications/unread-count - Get unread count

**SignalR Hub Methods:**

1. SendToUser(userId, notification)
2. SendToGroup(groupName, notification)
3. BroadcastToAll(notification)
4. JoinGroup(groupName)
5. LeaveGroup(groupName)
6. NotifyTyping(userId, isTyping) - bonus feature

**DTOs Required:**

- NotificationDto
- SendNotificationRequest
- BroadcastNotificationRequest
- NotificationFilterRequest (Type, Priority, DateRange, IsRead)
- NotificationResponse (with pagination metadata)
- UnreadCountResponse

**Best Practices:**

1. Use strongly-typed SignalR hubs
2. Implement connection management
3. Handle reconnection logic
4. Implement proper authorization for hub methods
5. Use async/await throughout
6. Proper error handling and logging
7. Input validation
8. Rate limiting for sending notifications
9. Group management for targeted broadcasts
10. Connection ID to User ID mapping
11. Graceful disconnection handling
12. XML documentation
13. Follow C# 14 and .NET 10 best practices
14. Nullable reference types

Generate:

1. Notification entity/model
2. All DTOs
3. NotificationHub (SignalR hub)
4. NotificationController (REST API)
5. ConnectionMappingService (track SignalR connections)
6. Response wrappers
7. Enums (NotificationType, NotificationPriority)
8. INotificationService interface
9. Authorization attributes for admin-only endpoints

Do not include database implementation - provide interfaces for data access.
