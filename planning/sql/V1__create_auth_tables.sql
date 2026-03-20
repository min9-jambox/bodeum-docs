-- ============================================================
-- V1: Auth Service Tables
-- 보듬(Bodeum) - AI 돌봄 기록 SaaS
-- Entities: User, UserCenterRole, TrustedDevice, WebAuthRequest,
--           OtpVerification, BrowserTrust
-- DB: PostgreSQL 17 | Encoding: UTF-8 | Timezone: UTC (TIMESTAMPTZ)
-- ============================================================

-- ------------------------------------------------------------
-- UUID v7 생성 함수 (RFC 9562, 2024-05)
-- 상위 48비트 = Unix 타임스탬프(ms) → B-tree 순차 삽입 보장
-- PostgreSQL 17 네이티브 미지원 시 아래 함수 사용
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION uuid_generate_v7() RETURNS uuid AS $$
DECLARE
    unix_ts_ms bytea;
    uuid_bytes bytea;
BEGIN
    unix_ts_ms = substring(int8send(floor(extract(epoch FROM clock_timestamp()) * 1000)::bigint) FROM 3);
    uuid_bytes = unix_ts_ms || gen_random_bytes(10);
    -- version 7
    uuid_bytes = set_byte(uuid_bytes, 6, (get_byte(uuid_bytes, 6) & 15) | 112);
    -- variant 2
    uuid_bytes = set_byte(uuid_bytes, 8, (get_byte(uuid_bytes, 8) & 63) | 128);
    RETURN encode(uuid_bytes, 'hex')::uuid;
END
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION uuid_generate_v7() IS 'UUID v7: 시간순 정렬 보장, B-tree 인덱스 최적화';

-- ------------------------------------------------------------
-- ENUM Types
-- ------------------------------------------------------------
CREATE TYPE user_status AS ENUM ('ACTIVE', 'INVITED', 'INACTIVE');
CREATE TYPE role_type AS ENUM ('CAREGIVER', 'DIRECTOR', 'SOCIAL_WORKER', 'ADMIN');
CREATE TYPE role_status AS ENUM ('ACTIVE', 'INACTIVE');
CREATE TYPE platform_type AS ENUM ('IOS', 'ANDROID');
CREATE TYPE auth_method AS ENUM ('BIOMETRIC', 'PIN');
CREATE TYPE web_auth_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED');
CREATE TYPE otp_purpose AS ENUM ('DEVICE_REGISTER', 'WEB_LOGIN_FALLBACK', 'ADMIN_2FA');
CREATE TYPE otp_status AS ENUM ('PENDING', 'VERIFIED', 'EXPIRED', 'FAILED');

-- ------------------------------------------------------------
-- 1. User (통합 사용자)
-- 전체 역할 공통의 인증 주체. 역할·센터 소속은 UserCenterRole로 분리.
-- ------------------------------------------------------------
CREATE TABLE "user" (
    id                UUID            PRIMARY KEY DEFAULT uuid_generate_v7(),
    phone             VARCHAR(20)     NOT NULL,
    name              VARCHAR(100)    NOT NULL,
    preferred_locale  VARCHAR(10)     NOT NULL DEFAULT 'ko',
    status            user_status     NOT NULL DEFAULT 'INVITED',
    last_login_at     TIMESTAMPTZ,
    created_at        TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ     NOT NULL DEFAULT now(),

    -- E.164 국제 전화번호 형식 검증
    CONSTRAINT chk_user_phone_e164 CHECK (phone ~ '^\+[1-9]\d{6,14}$')
);

-- 전화번호 유니크 (로그인 키)
CREATE UNIQUE INDEX uidx_user_phone ON "user" (phone);

COMMENT ON TABLE "user" IS '통합 사용자 - 인증 주체 (역할·센터는 UserCenterRole로 분리)';
COMMENT ON COLUMN "user".phone IS 'E.164 국제 포맷 (예: +821012345678)';
COMMENT ON COLUMN "user".preferred_locale IS '앱 UI 언어: ko, en, vi, zh-CN';

-- ------------------------------------------------------------
-- 2. UserCenterRole (사용자-센터 역할)
-- User와 Center의 N:M 매핑 + 역할. ADMIN은 center_id NULL.
-- ------------------------------------------------------------
CREATE TABLE user_center_role (
    id                UUID            PRIMARY KEY DEFAULT uuid_generate_v7(),
    user_id           UUID            NOT NULL REFERENCES "user" (id),
    center_id         UUID,           -- FK → center.id (V2에서 생성), ADMIN은 NULL
    role              role_type       NOT NULL,
    status            role_status     NOT NULL DEFAULT 'ACTIVE',
    created_at        TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ     NOT NULL DEFAULT now()
);

-- 동일 센터에 동일 역할 중복 방지
CREATE UNIQUE INDEX uidx_ucr_user_center_role ON user_center_role (user_id, center_id, role);
-- 사용자별 역할 목록
CREATE INDEX idx_ucr_user_id ON user_center_role (user_id);
-- 센터별 역할별 사용자 목록
CREATE INDEX idx_ucr_center_id_role ON user_center_role (center_id, role);

COMMENT ON TABLE user_center_role IS '사용자-센터 역할 매핑 (N:M + role). ADMIN은 center_id = NULL';

-- ------------------------------------------------------------
-- 3. TrustedDevice (신뢰 기기)
-- SMS OTP로 검증 완료 후 등록된 모바일 디바이스.
-- ------------------------------------------------------------
CREATE TABLE trusted_device (
    id                  UUID            PRIMARY KEY DEFAULT uuid_generate_v7(),
    user_id             UUID            NOT NULL REFERENCES "user" (id),
    device_id           VARCHAR(255)    NOT NULL,
    device_name         VARCHAR(100)    NOT NULL,
    device_fingerprint  VARCHAR(500)    NOT NULL,
    platform            platform_type   NOT NULL,
    fcm_token           TEXT,
    auth_method         auth_method     NOT NULL,
    last_used_at        TIMESTAMPTZ     NOT NULL DEFAULT now(),
    expires_at          TIMESTAMPTZ     NOT NULL,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now()
);

-- 사용자별 기기 목록
CREATE INDEX idx_td_user_id ON trusted_device (user_id);
-- 사용자+디바이스 유니크
CREATE UNIQUE INDEX uidx_td_user_device ON trusted_device (user_id, device_id);

COMMENT ON TABLE trusted_device IS '신뢰 기기 - 사용자당 최대 3대, 90일 만료';
COMMENT ON COLUMN trusted_device.expires_at IS '만료 일시 (등록 후 90일)';

-- ------------------------------------------------------------
-- 4. WebAuthRequest (웹 인증 요청)
-- 웹 로그인 시 생성되는 앱 푸시 승인 요청. 60초 TTL.
-- ------------------------------------------------------------
CREATE TABLE web_auth_request (
    id                  UUID              PRIMARY KEY DEFAULT uuid_generate_v7(),
    user_id             UUID              NOT NULL REFERENCES "user" (id),
    status              web_auth_status   NOT NULL DEFAULT 'PENDING',
    client_ip           VARCHAR(45)       NOT NULL,
    user_agent          TEXT              NOT NULL,
    requested_at        TIMESTAMPTZ       NOT NULL DEFAULT now(),
    expires_at          TIMESTAMPTZ       NOT NULL,
    approved_at         TIMESTAMPTZ,
    approved_device_id  UUID              REFERENCES trusted_device (id)
);

-- 사용자별 대기 중 요청 조회
CREATE INDEX idx_war_user_status ON web_auth_request (user_id, status);
-- 만료 요청 정리 배치
CREATE INDEX idx_war_expires_at ON web_auth_request (expires_at);

COMMENT ON TABLE web_auth_request IS '웹 인증 요청 - 60초 TTL, 동시 PENDING 1건만 허용';

-- ------------------------------------------------------------
-- 5. OtpVerification (OTP 검증 기록)
-- SMS OTP 발송 및 검증 이력.
-- ------------------------------------------------------------
CREATE TABLE otp_verification (
    id              UUID          PRIMARY KEY DEFAULT uuid_generate_v7(),
    phone           VARCHAR(20)   NOT NULL,
    code            VARCHAR(6)    NOT NULL,
    purpose         otp_purpose   NOT NULL,
    status          otp_status    NOT NULL DEFAULT 'PENDING',
    attempt_count   INT           NOT NULL DEFAULT 0,
    expires_at      TIMESTAMPTZ   NOT NULL,
    verified_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- 전화번호별 활성 OTP 조회
CREATE INDEX idx_otp_phone_status ON otp_verification (phone, status);

COMMENT ON TABLE otp_verification IS 'OTP 검증 - 3분 TTL, 최대 5회 시도';
COMMENT ON COLUMN otp_verification.code IS 'OTP 코드 (해시 저장)';

-- ------------------------------------------------------------
-- 6. BrowserTrust (브라우저 신뢰)
-- 웹 로그인 완료 후 14일간 간편 재인증 허용.
-- ------------------------------------------------------------
CREATE TABLE browser_trust (
    id                    UUID          PRIMARY KEY DEFAULT uuid_generate_v7(),
    user_id               UUID          NOT NULL REFERENCES "user" (id),
    browser_fingerprint   VARCHAR(500)  NOT NULL,
    user_agent            TEXT          NOT NULL,
    ip_address            VARCHAR(45)   NOT NULL,
    last_used_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    expires_at            TIMESTAMPTZ   NOT NULL,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- 사용자별 브라우저 조회
CREATE INDEX idx_bt_user_fingerprint ON browser_trust (user_id, browser_fingerprint);

COMMENT ON TABLE browser_trust IS '브라우저 신뢰 - 14일 만료, 간편 재인증 허용';
