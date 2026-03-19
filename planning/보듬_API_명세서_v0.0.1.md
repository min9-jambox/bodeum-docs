# 보듬(Bodeum) API 명세서

> **문서 버전**: 0.0.1
> **작성일**: 2026-03-18
> **기반 문서**: 보듬_PRD_v0.0.1.md, 보듬_엔티티_명세서_v0.0.1.md
> **대상 범위**: 전체 시스템 (1단계 핵심 ~ 3단계 확장)
> **Base URL**: `https://api.bodeum.kr/api/v1`
> **인증**: Bearer JWT (Authorization 헤더)

---

## 1. 공통 규약

### 1.1 요청/응답 형식

- Content-Type: `application/json` (파일 업로드 시 `multipart/form-data`)
- 문자 인코딩: UTF-8
- 날짜: ISO 8601 (서버 저장: UTC, 응답: UTC offset 포함 — `2026-03-18T05:30:00Z` 또는 `2026-03-18T14:30:00+09:00`)
- 페이징: `?page=0&size=20&sort=createdAt,desc`

### 1.2 공통 응답 구조

```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "timestamp": "2026-03-18T14:30:00+09:00"
}
```

### 1.3 에러 응답 구조

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "AUTH_001",
    "message": "인증에 실패했습니다.",
    "messageKey": "error.auth.failed",
    "details": null
  },
  "timestamp": "2026-03-18T14:30:00+09:00"
}
```

### 1.4 공통 에러 코드

| HTTP | 에러 코드 | 설명 |
|:---|:---|:---|
| 400 | `VALIDATION_001` | 요청 데이터 검증 실패 |
| 401 | `AUTH_001` | 인증 토큰 없음 또는 만료 |
| 401 | `AUTH_002` | OTP 검증 실패 |
| 403 | `AUTH_003` | 권한 부족 (RBAC) |
| 403 | `AUTH_004` | 기기 신뢰 없음 |
| 404 | `RESOURCE_001` | 리소스 없음 |
| 409 | `CONFLICT_001` | 상태 전이 불가 |
| 429 | `RATE_001` | 요청 제한 초과 |
| 500 | `INTERNAL_001` | 서버 내부 오류 |

**Care Service 에러 코드**:

| HTTP | 에러 코드 | 설명 |
|:---|:---|:---|
| 400 | `CARE_001` | 음성 파일 형식 미지원 (m4a, wav, mp3만 허용) |
| 400 | `CARE_002` | 음성 파일 크기 초과 (최대 50MB) |
| 400 | `CARE_003` | 음성 녹음 시간 초과 (최대 10분) |
| 404 | `CARE_004` | 돌봄 기록 없음 |
| 409 | `CARE_005` | 기록 상태 전환 불가 (현재 상태에서 허용되지 않는 전환) |
| 409 | `CARE_006` | 이미 확정된 기록 (수정 불가) |
| 422 | `CARE_007` | 배정되지 않은 수급자 (해당 요양보호사에게 배정되지 않음) |

**AI Pipeline Service 에러 코드**:

| HTTP | 에러 코드 | 설명 |
|:---|:---|:---|
| 502 | `AI_001` | Whisper STT API 호출 실패 |
| 502 | `AI_002` | GPT-4o-mini API 호출 실패 |
| 504 | `AI_003` | AI 파이프라인 타임아웃 (30초 초과) |
| 422 | `AI_004` | 음성 인식 결과 비어있음 (무음 또는 인식 불가) |
| 429 | `AI_005` | AI API 호출 한도 초과 (Rate Limit) |

**Notification Service 에러 코드**:

| HTTP | 에러 코드 | 설명 |
|:---|:---|:---|
| 502 | `NOTI_001` | 카카오 알림톡 API 호출 실패 |
| 400 | `NOTI_002` | 알림톡 템플릿 미등록 |
| 400 | `NOTI_003` | 수신자 전화번호 유효하지 않음 |
| 429 | `NOTI_004` | 알림톡 발송 한도 초과 |
| 502 | `NOTI_005` | FCM 푸시 알림 발송 실패 |

**Admin 에러 코드**:

| HTTP | 에러 코드 | 설명 |
|:---|:---|:---|
| 403 | `ADM_001` | 어드민 2FA 미완료 |
| 404 | `ADM_002` | 센터 승인 요청 없음 |
| 409 | `ADM_003` | 이미 처리된 승인 요청 |

### 1.5 JWT 페이로드

```json
{
  "sub": "user-uuid",
  "phone": "+821012345678",
  "active_center_id": "center-uuid",
  "role": "CAREGIVER",
  "device_trusted": true,
  "mfa_verified": false,
  "preferred_locale": "ko",
  "iat": 1711000000,
  "exp": 1711000900
}
```

| 필드 | 설명 |
|:---|:---|
| `active_center_id` | 현재 활성 센터 (센터 전환 시 변경) |
| `role` | 활성 센터에서의 역할 |
| `device_trusted` | 신뢰 기기 여부 |
| `mfa_verified` | 2FA 완료 여부 (어드민만 `true` 필요) |
| `preferred_locale` | 사용자 선호 언어 (ko, en, vi, zh-CN) |

### 1.6 인증 레벨별 접근 권한

| 엔드포인트 그룹 | CAREGIVER | DIRECTOR | SOCIAL_WORKER | ADMIN |
|:---|:---:|:---:|:---:|:---:|
| 인증 (Auth) | ✅ | ✅ | ✅ | ✅ |
| 방문/기록 (Records) | 본인 기록 | 센터 전체 | 센터 전체 | 전체 |
| 수급자/배정 (Clients) | 조회 | 전체 CRUD | 전체 CRUD | 전체 |
| 센터 설정 (Center) | — | ✅ | 조회 | 전체 |
| 어드민 (Admin) | — | — | — | ✅ |

---

## 2. Auth Service API

### 2.1 SMS OTP 인증

#### `POST /auth/otp/send`

SMS OTP 발송 요청.

**접근**: Public (인증 불필요)

**Request Body**:
```json
{
  "phone": "+821012345678",
  "purpose": "DEVICE_REGISTER"
}
```

| 필드 | 타입 | 필수 | 설명 |
|:---|:---|:---:|:---|
| `phone` | String | ✅ | E.164 국제 전화번호 포맷 |
| `purpose` | Enum | ✅ | `DEVICE_REGISTER`, `WEB_LOGIN_FALLBACK`, `ADMIN_2FA` |

**Response** (200):
```json
{
  "success": true,
  "data": {
    "expiresInSeconds": 180,
    "retryAfterSeconds": 60
  }
}
```

**에러**:
| HTTP | 코드 | 조건 |
|:---|:---|:---|
| 429 | `RATE_001` | 1분 내 재발송 시도 |
| 404 | `AUTH_005` | 등록되지 않은 전화번호 (ADMIN_2FA) |

---

#### `POST /auth/otp/verify`

OTP 검증 + JWT 발급.

**접근**: Public

**Request Body**:
```json
{
  "phone": "+821012345678",
  "code": "123456",
  "purpose": "DEVICE_REGISTER"
}
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "expiresIn": 900,
    "user": {
      "id": "uuid",
      "name": "김순자",
      "phone": "01012345678",
      "centers": [
        {
          "centerId": "uuid",
          "centerName": "행복한돌봄센터",
          "role": "CAREGIVER"
        }
      ]
    }
  }
}
```

**에러**:
| HTTP | 코드 | 조건 |
|:---|:---|:---|
| 401 | `AUTH_002` | OTP 불일치 |
| 401 | `AUTH_006` | OTP 만료 |
| 401 | `AUTH_007` | 시도 횟수 초과 (5회) |

---

### 2.2 기기 관리

#### `POST /auth/device/register`

OTP 검증 완료 후 현재 기기를 신뢰 기기로 등록.

**접근**: Bearer JWT 필수

**Request Body**:
```json
{
  "deviceId": "device-unique-id",
  "deviceName": "iPhone 14",
  "deviceFingerprint": "hash-string",
  "platform": "IOS",
  "fcmToken": "fcm-token-string",
  "authMethod": "BIOMETRIC"
}
```

**Response** (201):
```json
{
  "success": true,
  "data": {
    "trustedDeviceId": "uuid",
    "expiresAt": "2026-06-16T14:30:00+09:00"
  }
}
```

**비즈니스 규칙**:
- 사용자당 최대 3대. 초과 시 `last_used_at` 가장 오래된 기기 자동 해제
- 90일 유효

---

#### `GET /auth/devices`

등록된 신뢰 기기 목록 조회.

**접근**: Bearer JWT 필수

**Response** (200):
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "deviceName": "iPhone 14",
      "platform": "IOS",
      "authMethod": "BIOMETRIC",
      "lastUsedAt": "2026-03-18T10:00:00+09:00",
      "expiresAt": "2026-06-16T14:30:00+09:00",
      "isCurrent": true
    }
  ]
}
```

---

#### `DELETE /auth/device/{deviceId}`

기기 신뢰 해제 (분실·교체 시).

**접근**: Bearer JWT 필수

**Response** (204): No Content

---

### 2.3 웹 인증 (앱 푸시 승인)

#### `POST /auth/web/request`

웹 로그인 요청 → 앱에 FCM 푸시 발송.

**접근**: Public

**Request Body**:
```json
{
  "phone": "+821012345678"
}
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "requestId": "uuid",
    "expiresInSeconds": 60,
    "wsEndpoint": "wss://api.bodeum.kr/ws/auth/{requestId}"
  }
}
```

---

#### `POST /auth/web/approve`

앱에서 푸시 승인 처리 (생체/PIN 검증 후 호출).

**접근**: Bearer JWT 필수 (앱 토큰)

**Request Body**:
```json
{
  "requestId": "uuid",
  "approved": true
}
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "status": "APPROVED"
  }
}
```

**부수 효과**: WebSocket을 통해 웹 클라이언트에 JWT 자동 발급

---

#### `GET /auth/web/status/{requestId}`

웹에서 승인 상태 폴링 (WebSocket 대체용).

**접근**: Public

**Response** (200):
```json
{
  "success": true,
  "data": {
    "status": "APPROVED",
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

| status | 설명 |
|:---|:---|
| `PENDING` | 대기 중 (토큰 없음) |
| `APPROVED` | 승인 완료 (토큰 포함) |
| `REJECTED` | 거부됨 |
| `EXPIRED` | 60초 타임아웃 |

> **어드민 2FA 흐름**: 어드민은 `POST /auth/web/request` → `POST /auth/web/approve`(앱 푸시 1단계) 후, 웹에서 `status: APPROVED, step: "NEED_OTP"`를 수신한다. 이어서 `POST /auth/otp/send {purpose: ADMIN_2FA}` → `POST /auth/otp/verify`를 완료하면 `mfa_verified: true`가 포함된 JWT가 발급된다. 어드민 전용 API는 Gateway에서 `mfa_verified` 클레임을 필수로 검증한다.

---

### 2.4 브라우저 신뢰

#### `GET /auth/web/trust`

현재 브라우저 신뢰 상태 확인.

**접근**: Bearer JWT 필수

**Response** (200):
```json
{
  "success": true,
  "data": {
    "trusted": true,
    "expiresAt": "2026-04-01T14:30:00+09:00"
  }
}
```

---

#### `DELETE /auth/web/trust`

브라우저 신뢰 해제 (로그아웃 시).

**접근**: Bearer JWT 필수

**Response** (204): No Content

---

### 2.5 센터 전환

#### `GET /auth/centers`

로그인 사용자의 소속 센터 목록.

**접근**: Bearer JWT 필수

**Response** (200):
```json
{
  "success": true,
  "data": [
    {
      "centerId": "uuid",
      "centerName": "행복한돌봄센터",
      "role": "CAREGIVER",
      "status": "ACTIVE"
    },
    {
      "centerId": "uuid-2",
      "centerName": "사랑돌봄센터",
      "role": "CAREGIVER",
      "status": "ACTIVE"
    }
  ]
}
```

---

#### `POST /auth/centers/{centerId}/select`

활성 센터 전환 → 새 JWT 발급.

**접근**: Bearer JWT 필수

**Response** (200):
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "activeCenterId": "uuid",
    "role": "CAREGIVER"
  }
}
```

---

#### `POST /auth/refresh`

토큰 갱신.

**접근**: Refresh Token 필수

**Request Body**:
```json
{
  "refreshToken": "eyJ..."
}
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "expiresIn": 900
  }
}
```

---

### 2.6 사용자 언어 설정

#### `GET /users/me`

현재 사용자 프로필 조회.

**접근**: Bearer JWT 필수

**Response** (200):
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "김순자",
    "phone": "+821012345678",
    "preferredLocale": "ko",
    "centers": [
      {
        "centerId": "uuid",
        "centerName": "행복한돌봄센터",
        "role": "CAREGIVER"
      }
    ]
  }
}
```

---

#### `PATCH /users/me/locale`

사용자 선호 언어 변경.

**접근**: Bearer JWT 필수

**Request Body**:
```json
{
  "locale": "en"
}
```

| 필드 | 타입 | 필수 | 설명 |
|:---|:---|:---:|:---|
| `locale` | Enum | ✅ | `ko`, `en`, `vi`, `zh-CN` |

**Response** (200):
```json
{
  "success": true,
  "data": {
    "preferredLocale": "en"
  }
}
```

**부수 효과**: 이후 서버 발 메시지(푸시, 에러)가 해당 언어로 발송.

---

## 3. Care Service API

### 3.1 방문 목록

#### `GET /visits/today`

오늘 방문 예정 수급자 목록 (활성 센터 기준).

**접근**: CAREGIVER

**Response** (200):
```json
{
  "success": true,
  "data": [
    {
      "assignmentId": "uuid",
      "client": {
        "id": "uuid",
        "name": "박할머니",
        "careGrade": "3",
        "address": "서울시 강남구..."
      },
      "visitTime": "09:00",
      "hasRecordToday": false,
      "lastRecordDate": "2026-03-17"
    }
  ]
}
```

---

### 3.2 돌봄 기록

#### `POST /records`

음성 파일 업로드 + AI 처리 요청.

**접근**: CAREGIVER

**Content-Type**: `multipart/form-data`

| 필드 | 타입 | 필수 | 설명 |
|:---|:---|:---:|:---|
| `clientId` | UUID | ✅ | 수급자 ID |
| `visitDate` | Date | ✅ | 방문 일자 (yyyy-MM-dd) |
| `audioFile` | File | ✅ | 음성 파일 (m4a/wav, 최대 10MB) |

**Response** (202 Accepted):
```json
{
  "success": true,
  "data": {
    "recordId": "uuid",
    "status": "PROCESSING",
    "estimatedSeconds": 15
  }
}
```

---

#### `GET /records/{id}/status`

AI 처리 상태 폴링.

**접근**: CAREGIVER (본인 기록), DIRECTOR/SOCIAL_WORKER (센터 기록)

**Response** (200):
```json
{
  "success": true,
  "data": {
    "recordId": "uuid",
    "status": "DRAFT",
    "progress": 100
  }
}
```

---

#### `GET /records/{id}`

돌봄 기록 상세 조회.

**접근**: CAREGIVER (본인), DIRECTOR/SOCIAL_WORKER (센터), ADMIN (전체)

**Response** (200):
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "client": {
      "id": "uuid",
      "name": "박할머니"
    },
    "visitDate": "2026-03-18",
    "audioFileUrl": "https://s3.../audio.m4a",
    "audioDurationSeconds": 90,
    "sttText": "오늘 박할머니 컨디션 좋으셨어요...",
    "recordDraft": {
      "physical": "식사를 잘 하셨으며...",
      "cognitive": "특이사항 없음",
      "emotional": "기분이 좋으셨으며...",
      "specialNotes": "혈압 130/85mmHg"
    },
    "recordFinal": null,
    "alimtalkMessage": "오늘 어머님께서는 식사를 잘 하셨고...",
    "alimtalkStatus": "PENDING",
    "status": "DRAFT",
    "revisionCount": 0,
    "submittedAt": null,
    "confirmedAt": null,
    "confirmedBy": null,
    "createdAt": "2026-03-18T14:30:00+09:00"
  }
}
```

---

#### `PUT /records/{id}/draft`

AI 초안 텍스트 직접 수정 (보정 방식 3: 텍스트 편집).

**접근**: CAREGIVER (본인, status=DRAFT, revisionCount < 3)

**Request Body**:
```json
{
  "recordDraft": {
    "physical": "수정된 신체 상태 기록",
    "cognitive": "수정된 인지 상태 기록",
    "emotional": "수정된 정서 상태 기록",
    "specialNotes": "수정된 특이사항"
  },
  "alimtalkMessage": "수정된 알림톡 메시지"
}
```

**Response** (200): 수정된 기록 상세

---

#### `POST /records/{id}/supplement`

추가 음성 업로드 → AI 초안 보정 재생성 (보정 방식 2).

**접근**: CAREGIVER (본인, status=DRAFT, revisionCount < 3)

**Content-Type**: `multipart/form-data`

| 필드 | 타입 | 필수 | 설명 |
|:---|:---|:---:|:---|
| `audioFile` | File | ✅ | 추가 음성 파일 |

**Response** (202 Accepted): status → `PROCESSING`

---

#### `POST /records/{id}/regenerate`

다시 녹음 → AI 초안 재생성 (보정 방식 1).

**접근**: CAREGIVER (본인, status=DRAFT, revisionCount < 3)

**Content-Type**: `multipart/form-data`

| 필드 | 타입 | 필수 | 설명 |
|:---|:---|:---:|:---|
| `audioFile` | File | ✅ | 새 음성 파일 |

**Response** (202 Accepted): 기존 음성 교체, status → `PROCESSING`

---

#### `POST /records/{id}/submit`

요양보호사가 초안을 확인 후 원장님 검토 큐로 제출.

**접근**: CAREGIVER (본인, status=DRAFT)

**Response** (200):
```json
{
  "success": true,
  "data": {
    "recordId": "uuid",
    "status": "SUBMITTED",
    "submittedAt": "2026-03-18T15:00:00+09:00"
  }
}
```

**부수 효과**: 보호자 알림톡 자동 발송 트리거

---

#### `GET /records`

기록 목록 조회 (필터링).

**접근**: CAREGIVER (본인), DIRECTOR/SOCIAL_WORKER (센터), ADMIN (전체)

**Query Parameters**:

| 파라미터 | 타입 | 설명 |
|:---|:---|:---|
| `date` | Date | 특정 날짜 (yyyy-MM-dd) |
| `from` | Date | 시작일 |
| `to` | Date | 종료일 |
| `clientId` | UUID | 수급자 필터 |
| `caregiverId` | UUID | 요양보호사 필터 (DIRECTOR 이상) |
| `status` | Enum | 상태 필터 |
| `page` | Int | 페이지 번호 (0부터) |
| `size` | Int | 페이지 크기 (기본 20) |

---

#### `GET /records/pending`

확정 대기 목록 (원장님/사회복지사 검토 큐).

**접근**: DIRECTOR, SOCIAL_WORKER

**Response** (200):
```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": "uuid",
        "client": { "id": "uuid", "name": "박할머니" },
        "caregiver": { "id": "uuid", "name": "김순자" },
        "visitDate": "2026-03-18",
        "submittedAt": "2026-03-18T15:00:00+09:00",
        "status": "SUBMITTED"
      }
    ],
    "totalElements": 5,
    "totalPages": 1
  }
}
```

---

#### `PUT /records/{id}`

원장님/사회복지사가 초안 내용 수정.

**접근**: DIRECTOR, SOCIAL_WORKER (센터 내 기록, status=SUBMITTED)

**Request Body**: `recordDraft` + `alimtalkMessage` (PUT /records/{id}/draft 와 동일)

---

#### `POST /records/{id}/confirm`

기록 확정.

**접근**: DIRECTOR, SOCIAL_WORKER (센터 내 기록, status=SUBMITTED)

**Request Body** (optional):
```json
{
  "recordFinal": {
    "physical": "최종 확정 내용 (수정 시)",
    "cognitive": "...",
    "emotional": "...",
    "specialNotes": "..."
  }
}
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "recordId": "uuid",
    "status": "CONFIRMED",
    "confirmedAt": "2026-03-18T16:00:00+09:00",
    "confirmedBy": "uuid"
  }
}
```

---

#### `POST /records/{id}/reject`

기록 반려 (재검토 요청).

**접근**: DIRECTOR, SOCIAL_WORKER (status=SUBMITTED 또는 CONFIRMED)

**Request Body**:
```json
{
  "reason": "식사 관련 내용을 좀 더 구체적으로 기록해 주세요."
}
```

**Response** (200): status → `REJECTED`

---

### 3.3 수급자 관리

#### `GET /clients`

수급자 목록 (활성 센터 기준).

**접근**: CAREGIVER (배정된 수급자), DIRECTOR/SOCIAL_WORKER (센터 전체)

**Query Parameters**: `status`, `page`, `size`

---

#### `POST /clients`

수급자 등록.

**접근**: DIRECTOR, SOCIAL_WORKER

**Request Body**:
```json
{
  "name": "박할머니",
  "birthDate": "1940-05-15",
  "gender": "F",
  "careGrade": "3",
  "address": "서울시 강남구...",
  "medicalNotes": "고혈압, 당뇨",
  "guardians": [
    {
      "name": "박영수",
      "phone": "01098765432",
      "relation": "아들",
      "isPrimary": true
    }
  ]
}
```

**Response** (201): 생성된 수급자 상세

---

#### `PUT /clients/{id}`

수급자 정보 수정.

**접근**: DIRECTOR, SOCIAL_WORKER

---

#### `GET /clients/{id}`

수급자 상세 (보호자 포함).

**접근**: CAREGIVER (배정된 수급자), DIRECTOR/SOCIAL_WORKER

---

### 3.4 요양보호사 관리

#### `GET /caregivers`

요양보호사 목록 (활성 센터 기준).

**접근**: DIRECTOR, SOCIAL_WORKER

---

#### `POST /caregivers`

요양보호사 등록 + 초대 SMS 발송.

**접근**: DIRECTOR, SOCIAL_WORKER

**Request Body**:
```json
{
  "name": "김순자",
  "phone": "01012345678"
}
```

**부수 효과**: 앱 다운로드 링크 포함 SMS 발송, User(INVITED) + UserCenterRole 생성

---

#### `PUT /caregivers/{id}`

요양보호사 정보 수정.

**접근**: DIRECTOR, SOCIAL_WORKER

---

### 3.5 배정 관리

#### `GET /assignments`

배정 현황 (활성 센터 기준).

**접근**: DIRECTOR, SOCIAL_WORKER

**Query Parameters**: `caregiverId`, `clientId`, `status`

---

#### `POST /assignments`

배정 생성/변경.

**접근**: DIRECTOR, SOCIAL_WORKER

**Request Body**:
```json
{
  "caregiverId": "uuid",
  "clientId": "uuid",
  "visitDays": "MON,WED,FRI",
  "visitTime": "09:00",
  "startDate": "2026-04-01"
}
```

---

#### `PUT /assignments/{id}`

배정 수정.

**접근**: DIRECTOR, SOCIAL_WORKER

---

#### `DELETE /assignments/{id}`

배정 종료 (status → ENDED).

**접근**: DIRECTOR, SOCIAL_WORKER

---

### 3.6 내보내기

#### `GET /records/export/pdf`

돌봄 기록 PDF 내보내기.

**접근**: DIRECTOR, SOCIAL_WORKER

**Query Parameters**:
| 파라미터 | 타입 | 필수 | 설명 |
|:---|:---|:---:|:---|
| `clientId` | UUID | ✅ | 수급자 |
| `from` | Date | ✅ | 시작일 |
| `to` | Date | ✅ | 종료일 |

**Response**: `application/pdf` (Content-Disposition: attachment)

---

#### `GET /records/export/excel`

돌봄 기록 엑셀 내보내기.

**접근**: DIRECTOR, SOCIAL_WORKER

**Query Parameters**: `from`, `to`, `clientId` (optional)

**Response**: `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`

---

### 3.7 대시보드

#### `GET /dashboard/today`

백오피스 오늘 현황 요약.

**접근**: DIRECTOR, SOCIAL_WORKER

**Response** (200):
```json
{
  "success": true,
  "data": {
    "totalVisitsToday": 15,
    "recordsCompleted": 10,
    "recordsPending": 3,
    "recordsProcessing": 2,
    "pendingConfirmation": 5,
    "alimtalkSentToday": 10,
    "alimtalkFailedToday": 0
  }
}
```

> **참고**: 원장님 보듬 앱의 홈 화면에서도 이 API를 간략화하여 사용. 앱에서는 `totalVisitsToday`, `recordsPending`, `pendingConfirmation` 세 항목만 카드 형태로 표시한다.

---

#### `GET /dashboard/summary`

원장님 모바일 앱 홈 화면용 간소 대시보드.

**접근**: DIRECTOR, SOCIAL_WORKER

**Response** (200):
```json
{
  "success": true,
  "data": {
    "todayVisitCount": 12,
    "recordSubmitted": 10,
    "recordPending": 2,
    "recordProcessing": 0,
    "unreadAlertCount": 3,
    "activeCaregiversCount": 5,
    "lastUpdatedAt": "2026-04-15T09:30:00Z"
  }
}
```

> 웹 대시보드(`GET /dashboard/today`)의 상세 데이터와 달리, 앱 홈 카드에 필요한 최소 집계 정보만 반환. 네트워크 효율을 위해 단일 호출로 전체 현황 파악 가능.

---

#### `POST /dashboard/send-reminder`

미제출 요양보호사에게 녹음 리마인더 푸시 발송 (F-APP-006).

**접근**: DIRECTOR, SOCIAL_WORKER

**Request Body**:
```json
{
  "caregiverIds": ["uuid-1", "uuid-2"],
  "message": "오늘 방문 기록을 아직 남기지 않으셨어요. 기록을 남겨주세요."
}
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "sentCount": 2,
    "failedCount": 0
  }
}
```

**비즈니스 규칙**: `caregiverIds`가 빈 배열이면 오늘 방문이 있으나 기록이 없는 전체 요양보호사에게 발송.

---

### 3.8 센터 설정

#### `GET /center`

현재 활성 센터 정보.

**접근**: DIRECTOR, SOCIAL_WORKER

**Response** (200):
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "행복한돌봄센터",
    "address": "서울시 강남구...",
    "phone": "02-1234-5678",
    "facilityType": "HOME_VISIT",
    "kakaoChannelId": "channel-id",
    "status": "ACTIVE"
  }
}
```

---

#### `PUT /center`

센터 정보 수정.

**접근**: DIRECTOR

**Request Body**:
```json
{
  "name": "행복한돌봄센터",
  "address": "서울시 강남구...",
  "phone": "02-1234-5678",
  "facilityType": "HOME_VISIT",
  "kakaoChannelId": "channel-id"
}
```

> **참고**: `facilityType`은 1단계에서 `HOME_VISIT`만 허용. 2단계에서 `NURSING_HOME` 추가.

---

## 4. AI Pipeline Service API

### 4.1 내부 서비스 간 통신

> AI Pipeline은 직접 클라이언트 호출을 받지 않고, Care Service에서 내부 호출(Service-to-Service)한다.
> 메시지 큐(SQS)를 통한 비동기 처리 구조.

#### 내부 이벤트: `RecordCreated`

Care Service → AI Pipeline (SQS 메시지).

```json
{
  "eventType": "RECORD_CREATED",
  "recordId": "uuid",
  "audioFileUrl": "s3://bodeum-audio/...",
  "clientContext": {
    "name": "박할머니",
    "age": 86,
    "careGrade": "3",
    "medicalNotes": "고혈압, 당뇨"
  }
}
```

---

#### 내부 이벤트: `RecordProcessed`

AI Pipeline → Care Service (SQS 콜백).

```json
{
  "eventType": "RECORD_PROCESSED",
  "recordId": "uuid",
  "success": true,
  "sttText": "오늘 박할머니 컨디션 좋으셨어요...",
  "recordDraft": {
    "physical": "...",
    "cognitive": "...",
    "emotional": "...",
    "specialNotes": "..."
  },
  "alimtalkMessage": "오늘 어머님께서는...",
  "audioDurationSeconds": 90,
  "processingTimeMs": 12500
}
```

---

## 5. Notification Service API

### 5.1 내부 서비스 간 통신

#### 내부 이벤트: `AlimtalkRequested`

Care Service → Notification Service (SQS).

```json
{
  "eventType": "ALIMTALK_REQUESTED",
  "careRecordId": "uuid",
  "guardians": [
    {
      "guardianId": "uuid",
      "phone": "01098765432",
      "name": "박영수"
    }
  ],
  "message": "오늘 어머님께서는...",
  "centerKakaoChannelId": "channel-id"
}
```

---

#### 내부 이벤트: `PushRequested`

Auth Service / Care Service → Notification Service (SQS).

```json
{
  "eventType": "PUSH_REQUESTED",
  "userId": "uuid",
  "type": "WEB_AUTH_REQUEST",
  "title": "웹 로그인 승인 요청",
  "body": "PC에서 로그인을 시도하고 있습니다. 승인하시겠습니까?",
  "data": {
    "requestId": "uuid",
    "action": "WEB_AUTH_APPROVE"
  }
}
```

---

## 6. Admin Service API

> 어드민 콘솔 전용 API. ADMIN 역할 + `mfa_verified=true` 필수.

#### `GET /admin/centers`

전체 센터 목록 (검색, 페이징).

**Query Parameters**: `search`, `status`, `page`, `size`

---

#### `POST /admin/centers/{id}/approve`

센터 가입 승인 (PENDING_APPROVAL → ACTIVE).

---

#### `POST /admin/centers/{id}/suspend`

센터 정지 (ACTIVE → SUSPENDED).

---

#### `GET /admin/monitoring/dashboard`

시스템 모니터링 대시보드.

**Response** (200):
```json
{
  "success": true,
  "data": {
    "totalCenters": 45,
    "activeCenters": 42,
    "totalUsers": 520,
    "totalRecordsToday": 180,
    "pipelineSuccessRate": 97.5,
    "alimtalkSuccessRate": 99.2,
    "avgProcessingTimeMs": 11500,
    "errorCount24h": 3
  }
}
```

---

#### `GET /admin/monitoring/errors`

최근 오류 목록.

---

#### `GET /admin/users`

전체 사용자 목록 (역할별 필터, 검색).

---

#### `PUT /admin/users/{id}/role`

사용자 역할 변경.

---

#### `GET /admin/notification-templates`

알림 템플릿 목록 조회.

**Query Parameters**: `page`, `size`

---

#### `POST /admin/notification-templates`

알림 템플릿 생성.

**Request Body**:
```json
{
  "templateKey": "record_submitted",
  "content": {
    "ko": "기록이 제출되었습니다.",
    "en": "Record has been submitted.",
    "vi": "Hồ sơ đã được gửi."
  }
}
```

---

#### `PUT /admin/notification-templates/{id}`

알림 템플릿 수정.

---

#### `DELETE /admin/notification-templates/{id}`

알림 템플릿 삭제.

---

## 7. 2단계 API (성장)

### 7.1 결제 (F-PAY-001)

| Method | Path | 설명 |
|:---|:---|:---|
| `GET` | `/subscriptions/current` | 현재 구독 정보 조회 |
| `POST` | `/subscriptions` | 구독 생성 (플랜 선택 + 카드 등록) |
| `PUT` | `/subscriptions/plan` | 플랜 변경 (Basic ↔ Premium) |
| `POST` | `/subscriptions/cancel` | 구독 해지 |
| `GET` | `/payments` | 결제 내역 조회 |
| `GET` | `/payments/{id}/invoice` | 세금계산서 다운로드 |

---

### 7.2 지오펜싱 (F-GEO-001)

| Method | Path | 설명 |
|:---|:---|:---|
| `GET` | `/geofences` | 수급자별 지오펜스 목록 |
| `POST` | `/geofences` | 지오펜스 생성 (수급자 주소 기반) |
| `PUT` | `/geofences/{id}` | 지오펜스 수정 (반경 조정) |
| `POST` | `/geofences/events` | 앱에서 진입/이탈 이벤트 전송 |

---

### 7.3 분석 대시보드 (F-DASH-001)

| Method | Path | 설명 |
|:---|:---|:---|
| `GET` | `/analytics/records/completion` | 기록 완료율 추이 (일/주/월) |
| `GET` | `/analytics/caregivers/performance` | 요양보호사별 기록 현황 |
| `GET` | `/analytics/clients/trends` | 수급자별 상태 변화 추이 |
| `GET` | `/analytics/ai/revision-rate` | AI 초안 수정률 통계 |
| `GET` | `/analytics/export/pdf` | 분석 리포트 PDF 다운로드 |

---

### 7.4 프리미엄 리포트 (F-REPORT-001)

| Method | Path | 설명 |
|:---|:---|:---|
| `GET` | `/reports/premium` | 프리미엄 리포트 목록 |
| `GET` | `/reports/premium/{id}` | 리포트 상세 (PDF URL 포함) |
| `POST` | `/reports/premium/generate` | 수동 리포트 생성 요청 |

---

### 7.5 정합성 검증 (F-AI-005)

| Method | Path | 설명 |
|:---|:---|:---|
| `GET` | `/records/{id}/consistency` | 기록별 정합성 검증 결과 조회 |
| `GET` | `/analytics/consistency/overview` | 전체 정합성 통계 |

> 정합성 검증은 AI Pipeline에서 자동 수행. API는 결과 조회 전용.

---

### 7.6 다국어 (F-AI-006)

> 기존 `POST /records` API 확장. 추가 파라미터:

| 필드 | 타입 | 설명 |
|:---|:---|:---|
| `sourceLanguage` | Enum | `KO`, `VI`, `ZH`, `UZ` (기본 `KO`) |

---

## 8. 3단계 API (확장)

### 8.1 공단/ERP 연동 (F-ERP-001)

| Method | Path | 설명 |
|:---|:---|:---|
| `GET` | `/integrations/erp` | 연동 설정 조회 |
| `POST` | `/integrations/erp` | 연동 설정 생성 |
| `PUT` | `/integrations/erp/{id}` | 연동 설정 수정 |
| `POST` | `/integrations/erp/{id}/sync` | 수동 동기화 트리거 |
| `GET` | `/integrations/erp/{id}/logs` | 동기화 로그 조회 |

---

### 8.2 건강 트렌드 (F-TREND-001)

| Method | Path | 설명 |
|:---|:---|:---|
| `GET` | `/clients/{id}/health-trends` | 수급자별 건강 트렌드 조회 |
| `GET` | `/health-trends/alerts` | 이상 징후 알림 목록 |

---

### 8.3 멀티 기관 유형 (F-MULTI-001)

| Method | Path | 설명 |
|:---|:---|:---|
| `GET` | `/facility-types` | 지원 서비스 유형 목록 |
| `PUT` | `/center/facility-type` | 센터 서비스 유형 설정 |

---

## 부록 A: WebSocket 엔드포인트

| Path | 설명 | 메시지 형식 |
|:---|:---|:---|
| `wss://api.bodeum.kr/ws/auth/{requestId}` | 웹 로그인 승인 상태 실시간 전달 | `{ "status": "APPROVED", "accessToken": "..." }` |
| `wss://api.bodeum.kr/ws/records/{recordId}` | AI 처리 상태 실시간 전달 | `{ "status": "DRAFT", "progress": 100 }` |

---

## 부록 B: Rate Limiting 정책

| 엔드포인트 | 제한 | 비고 |
|:---|:---|:---|
| `POST /auth/otp/send` | 동일 번호 1회/분, 5회/시간 | SMS 비용 최적화 |
| `POST /auth/web/request` | 동일 번호 3회/분 | 푸시 스팸 방지 |
| `POST /records` | 사용자당 10회/시간 | 음성 업로드 과부하 방지 |
| 기타 API | 사용자당 100회/분 | 일반 보호 |

---

## 부록 C: 참고 문서

- 보듬_PRD_v0.0.1.md
- 보듬_엔티티_명세서_v0.0.1.md
- 보듬_도메인_용어사전_v0.0.1.md
- 보듬_설계보강_v0.0.1.md
- 보듐_브랜드_가이드라인_v0.0.1.md
- 보듬_기술스택_v0.0.1.md
- 보듬_코드컨벤션_v0.0.1.md
