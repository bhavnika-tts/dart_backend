# 🚀 Classicale Backend: Full Dart Frog Rewrite Workflow & Execution Blueprint

This document serves as the master engineering blueprint and execution checklist for completely rewriting the **Classicale Backend** (`new_backend`, Node.js/Express) into **Dart Frog (AOT Native)** as a **100% drop-in replacement**.

---

## 🎯 Architectural Goal & Constraints

1. **🔒 Strict 100% Exact Response Parity (Zero Client Breaking Changes)**:
   - The Flutter mobile app (`products_purchase_sell`) and Flutter web admin panel (`admin_panel`) must function with **ZERO code changes** (only the base URL changes).
   - **Identical JSON Envelopes**: Every success (`{ "status": true, "message": "...", "data": ... }`) and error response (`{ "status": false, "message": "..." }`) must match Node.js byte-for-byte in structure and data types.
   - **MongoDB `_id` & Date Formats**: `_id` must always serialize as a 24-character hex string (e.g. `"65a8e..."`), and dates must serialize as exact ISO-8601 strings (matching JavaScript `toISOString()`).
   - **Status Codes**: Return the exact same HTTP status codes (`200`, `201`, `206`, `400`, `401`, `403`, `404`, `500`).
   - **Field-Level Projections**: Exact field projections (`LIST_PROJECTION` for feeds/search, `DETAIL_PROJECTION` for single product screens).
2. **Database & Data Continuity**:
   - Connect directly to the existing MongoDB database and Redis instance without altering existing collections, indexes, or document fields.
3. **Security & Session Preservation**:
   - Use the exact same `JWT_SECRET`, AES-256-GCM `ENCRYPTION_KEY`, and Argon2id `PASSWORD_PEPPER` so existing logged-in user tokens remain valid and existing passwords authenticate without resets.
4. **Socket.IO v4 Wire Protocol Compatibility**:
   - Replicate the exact Socket.IO v4 / Engine.IO framing and event names (`join_chat`, `send_message`, `receive_message`, `typing`, `message_read`, `user_status`) so `socket_io_client` on Flutter connects seamlessly.
5. **Clean 3-Tier Architecture**:
   - `routes/**`: HTTP routing, headers, status codes.
   - `lib/services/**`: Pure business logic, validations.
   - `lib/repositories/**`: `mongo_dart` data queries, BSON mappers.
   - `lib/models/**`: Strongly-typed Dart DTOs with JSON serialization.
   - `lib/core/**`: Database clients, Redis, crypto, ImageKit, and middleware.

---

## 🏗️ Target Project Structure

```
dart_frog_backend/
├── routes/                           # File-based HTTP routes
│   ├── index.dart                    # Health / Root endpoint (Hello, World!)
│   ├── _middleware.dart              # Global CORS, error handling & DI
│   └── api/
│       ├── _middleware.dart          # API Rate Limiter & Auth Injection
│       ├── app_version/index.dart
│       ├── location/
│       │   ├── index.dart
│       │   └── pincode/[pin].dart
│       ├── about_us/index.dart
│       ├── brands/index.dart
│       ├── form_metadata/index.dart
│       ├── home/index.dart
│       ├── otp/
│       │   ├── send.dart
│       │   └── verify.dart
│       ├── user/
│       │   ├── register.dart
│       │   ├── login.dart
│       │   ├── profile.dart
│       │   └── permissions.dart
│       ├── products/
│       │   ├── index.dart
│       │   ├── [id].dart
│       │   └── filter.dart
│       ├── chat/
│       │   ├── index.dart
│       │   ├── [chatId].dart
│       │   └── ws.dart               # Socket.IO v4 / WebSocket Handler
│       ├── admin/
│       │   ├── login.dart
│       │   ├── users.dart
│       │   └── products.dart
│       └── media/
│           ├── upload.dart
│           └── stream/[videoName].dart
├── lib/
│   ├── core/
│   │   ├── config/env.dart           # Validated environment config
│   │   ├── db/mongo_client.dart      # MongoDB connection pool
│   │   ├── redis/redis_client.dart   # Redis client & TTL caching
│   │   ├── security/
│   │   │   ├── crypto.dart           # AES-256-GCM & Argon2id
│   │   │   └── jwt.dart              # JWT verification & claims
│   │   ├── media/
│   │   │   ├── imagekit.dart         # ImageKit HMAC-SHA1 URL signing
│   │   │   └── s3_uploader.dart      # S3 / Multipart handler
│   │   └── sockets/
│   │       ├── socket_io_protocol.dart# Engine.IO/Socket.IO v4 wire parser
│   │       └── socket_manager.dart   # Presence, rooms, typing indicators
│   ├── models/                       # 29 Data Model DTOs
│   │   ├── user.dart
│   │   ├── product.dart
│   │   ├── brand_model.dart
│   │   ├── form_metadata.dart
│   │   ├── chat.dart
│   │   └── ...
│   ├── repositories/                 # Data access layer (mongo_dart)
│   │   ├── user_repository.dart
│   │   ├── product_repository.dart
│   │   ├── chat_repository.dart
│   │   └── ...
│   └── services/                     # Business logic layer
│       ├── auth_service.dart
│       ├── product_service.dart
│       ├── chat_service.dart
│       ├── otp_service.dart
│       └── ...
├── test/                             # Unit and API integration tests
├── Dockerfile                        # Multi-stage AOT native container build
├── pubspec.yaml                      # Project dependencies
└── FULL_REWRITE_WORKFLOW.md          # This blueprint
```

---

## 📋 Phase-by-Phase Execution Plan

### 🟢 Phase 1: Environment, Database & Security Core
- [ ] **1.1 Validated Config (`lib/core/config/env.dart`)**:
  - Load and validate `PORT`, `MONGO_URI`, `REDIS_URL`, `JWT_SECRET`, `ENCRYPTION_KEY`, `PASSWORD_PEPPER`, `IMAGEKIT_*`, `AWS_*`.
- [ ] **1.2 MongoDB Connection Pool (`lib/core/db/mongo_client.dart`)**:
  - Implement resilient `mongo_dart` connection pool with auto-reconnect.
- [ ] **1.3 Redis Client (`lib/core/redis/redis_client.dart`)**:
  - Redis connection wrapper supporting `GET`, `SETEX` (mandatory TTL), `DEL`, and `SCAN`.
- [ ] **1.4 Cryptography & Security Engine (`lib/core/security/crypto.dart`)**:
  - **AES-256-GCM**: Support encrypt/decrypt with format `<iv_hex>:<authTag_hex>:<ciphertext_hex>`.
  - **Argon2id**: Password hashing & verification with server-side pepper matching Node.js.
  - **JWT Middleware**: Token decoding and auth context injection (`RequestContext.provide<UserAuth>()`).

---

### 🟢 Phase 2: Data Models & BSON Mappers (29 Collections)
- [ ] **2.1 Entity Models**:
  - Create strongly-typed DTOs for `User`, `Product`, `Category`, `SubProductType`, `BrandModel`, `FormMetadata`, `Chat`, `Conversation`, `Location`, `Admin`, `Banner`, `Feedback`, etc.
- [ ] **2.2 JSON & BSON Serialization**:
  - Add `toJson()`, `fromJson()`, `toBson()`, and `fromBson()` with null-safety and default fallbacks.

---

### 🟢 Phase 3: Public Metadata & Read-Heavy APIs
- [ ] **3.1 `/api/location`**: Pincode lookup, city/state resolution, in-memory JSON cache fallback.
- [ ] **3.2 `/api/app-version`**: Version check, force-update checks, maintenance mode.
- [ ] **3.3 `/api/about-us`**: Mission, values, stats.
- [ ] **3.4 `/api/brands`**: Brand & model cascading hierarchies.
- [ ] **3.5 `/api/form-metadata`**: Dynamic form fields per category.
- [ ] **3.6 `/api/home`**: Home banner feed with timezone scheduling.

---

### 🟢 Phase 4: Auth, OTP (Email SMTP), User Profiles & Permissions
- [ ] **4.1 `/api/otp/forgot-password`, `/api/otp/verify-otp`, `/api/otp/change-password`**:
  - Email SMTP gateway (`package:mailer` with branded HTML templates), Redis rate limiting & cooldown, 6-digit OTP verification.
- [ ] **4.2 `/api/user` Profile System**:
  - Registration, Login, Profile updates, Referral code generation, Category restrictions & permissions.
- [ ] **4.3 Verification & Aadhaar Pipeline**:
  - Aadhaar image upload and sensitive data AES encryption.

---

### 🟢 Phase 5: Product Marketplace Engine
- [ ] **5.1 Product CRUD (`/api/products`)**:
  - Create, update, soft-delete, activate/deactivate listings.
- [ ] **5.2 Dynamic Specifications & Category Attributes**:
  - Dynamic validation based on category form metadata (e.g. Car year, brand, fuel type).
- [ ] **5.3 Search & Geo-Spatial Queries**:
  - Multi-parameter search, text search tags, `$nearSphere` 2dsphere location sorting, pagination (`page`, `limit`).
- [ ] **5.4 Lean Field Projections**:
  - `LIST_PROJECTION` for fast card feeds, `DETAIL_PROJECTION` for full product screens.

---

### 🟢 Phase 6: Media Pipeline & Video Streaming
- [ ] **6.1 ImageKit Dynamic URL Signing Middleware**:
  - Intercept outbound JSON responses to generate HMAC-SHA1 signed ImageKit URLs in-place.
- [ ] **6.2 S3 & Multipart File Uploads**:
  - Streamed multipart uploads for product images, user avatars, and chat media.
- [ ] **6.3 Video Streaming Handler (`/public/videos/app-guide/:name`)**:
  - HTTP 206 Partial Content range requests (`Accept-Ranges: bytes`) for smooth video playback.

---

### 🟢 Phase 7: Real-Time Chat & Socket.IO v4 Protocol Bridge
- [ ] **7.1 Socket.IO / Engine.IO v4 Framing Engine**:
  - Handle Socket.IO handshake (`0{...}`), connect packet (`40`), ping/pong (`2`/`3`), and event packets (`42[...]`).
- [ ] **7.2 Real-Time Event Handlers**:
  - `join_chat`, `send_message`, `receive_message`, `message_delivered`, `message_read`, `typing`, `stop_typing`, `user_status`.
- [ ] **7.3 Multi-Instance Scaling**:
  - Redis Pub/Sub adapter for distributed socket broadcasting across multiple backend replicas.
- [ ] **7.4 Push Notifications (FCM v1)**:
  - Firebase Cloud Messaging HTTP v1 with Google Service Account OAuth2 token caching.

---

### 🟢 Phase 8: Admin Panel Management & Audit Logging
- [ ] **8.1 Admin Auth & RBAC**:
  - Admin login, role verification (`superadmin`, `admin`, `moderator`).
- [ ] **8.2 Moderation & Audit Logging**:
  - Product approval/rejection, user verification status, structured audit logs.

---

### 🟢 Phase 9: Automated Dual-Server Parity Testing & Docker AOT Build
- [ ] **9.1 Automated Live Parity Test Suite (`test/parity/`)**:
  - Run side-by-side automated HTTP comparisons between Node.js (`localhost:5001`) and Dart Frog (`localhost:8080`).
  - Compare response status code, headers, JSON keys, data types, and array lengths for all endpoints.
  - Assert zero discrepancy across public feeds, auth flows, product searches, and admin endpoints.
- [ ] **9.2 Multi-Stage Production Dockerfile**:
  - Standalone native binary compilation (`dart compile exe`) packaged in a lightweight distroless/scratch container (`~25MB`).

---

## 🛠️ Essential Development Commands

```bash
# Navigate to Dart Frog backend
cd /Users/bhavnika/Desktop/classical/dart_frog_backend

# Run local development server with hot reload
dart_frog dev --port 8080

# Run all unit and route tests
dart test

# Build production standalone AOT executable
dart_frog build
dart compile exe build/bin/server.dart -o build/bin/server

# Run production binary
./build/bin/server
```
