-- ============================================================
-- V1: Care Service Tables
-- 보듬(Bodeum) - AI 돌봄 기록 SaaS
-- Entities: Center, Client, Guardian, Assignment, CareRecord, AlimtalkLog,
--           Subscription, Payment, Geofence, NudgeLog, ConsistencyCheck, PremiumReport
-- DB: PostgreSQL 17 | Encoding: UTF-8 | Timezone: UTC (TIMESTAMPTZ)
-- ============================================================

-- ------------------------------------------------------------
-- ENUM Types
-- ------------------------------------------------------------
CREATE TYPE center_status AS ENUM ('PENDING_APPROVAL', 'ACTIVE', 'SUSPENDED');
CREATE TYPE facility_type_code AS ENUM ('HOME_VISIT', 'NURSING_HOME', 'DAY_NIGHT', 'HOME_BATH', 'HOME_NURSE');
CREATE TYPE gender AS ENUM ('M', 'F');
CREATE TYPE assignment_status AS ENUM ('ACTIVE', 'ENDED');
CREATE TYPE care_record_status AS ENUM ('PROCESSING', 'DRAFT', 'SUBMITTED', 'CONFIRMED', 'REJECTED');
CREATE TYPE client_status AS ENUM ('ACTIVE', 'INACTIVE');
CREATE TYPE alimtalk_status AS ENUM ('PENDING', 'SENT', 'DELIVERED', 'FAILED');

-- ------------------------------------------------------------
-- 1. Center (센터)
-- 장기요양기관. 모든 비즈니스 데이터의 테넌트 루트.
-- ------------------------------------------------------------
CREATE TABLE center (
    id                  UUID                PRIMARY KEY DEFAULT uuid_generate_v7(),
    name                VARCHAR(200)        NOT NULL,
    business_number     VARCHAR(12)         NOT NULL,
    address             VARCHAR(500)        NOT NULL,
    phone               VARCHAR(20)         NOT NULL,
    facility_type       facility_type_code  NOT NULL DEFAULT 'HOME_VISIT',
    kakao_channel_id    VARCHAR(100),
    solapi_api_key      TEXT,               -- AES-256 암호화 저장
    solapi_api_secret   TEXT,               -- AES-256 암호화 저장
    status              center_status       NOT NULL DEFAULT 'ACTIVE',
    created_at          TIMESTAMPTZ         NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ         NOT NULL DEFAULT now()
);

-- 사업자등록번호 유니크
CREATE UNIQUE INDEX uidx_center_business_number ON center (business_number);
-- 상태별 조회
CREATE INDEX idx_center_status ON center (status);
-- 기관 유형별 조회
CREATE INDEX idx_center_facility_type ON center (facility_type);

COMMENT ON TABLE center IS '장기요양기관 - 테넌트 루트. 1단계 HOME_VISIT 기본, 2단계 NURSING_HOME 활성화';
COMMENT ON COLUMN center.name IS '기관명 (다국어 표기 대응 200자)';
COMMENT ON COLUMN center.solapi_api_key IS '솔라피 API 키 (AES-256 암호화)';
COMMENT ON COLUMN center.solapi_api_secret IS '솔라피 API 시크릿 (AES-256 암호화)';

-- V1의 user_center_role.center_id FK 추가
ALTER TABLE user_center_role
    ADD CONSTRAINT fk_ucr_center_id FOREIGN KEY (center_id) REFERENCES center (id);

-- ------------------------------------------------------------
-- 2. Client (수급자)
-- 장기요양서비스를 이용하는 대상자.
-- ------------------------------------------------------------
CREATE TABLE client (
    id              UUID              PRIMARY KEY DEFAULT uuid_generate_v7(),
    center_id       UUID              NOT NULL REFERENCES center (id),
    name            VARCHAR(100)      NOT NULL,       -- AES-256 암호화. 다국어 이름 대응 100자
    birth_date      DATE              NOT NULL,
    gender          gender            NOT NULL,
    care_grade      VARCHAR(10)       NOT NULL,
    address         VARCHAR(500),                     -- AES-256 암호화
    medical_notes   TEXT,
    status          client_status     NOT NULL DEFAULT 'ACTIVE',
    created_at      TIMESTAMPTZ       NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ       NOT NULL DEFAULT now()
);

-- 센터별 수급자 목록
CREATE INDEX idx_client_center_id ON client (center_id);
-- 센터별 활성 수급자
CREATE INDEX idx_client_center_status ON client (center_id, status);

COMMENT ON TABLE client IS '수급자 - 장기요양서비스 이용 대상자';
COMMENT ON COLUMN client.name IS '이름 (AES-256 암호화). 다국어 이름 대응 100자';
COMMENT ON COLUMN client.care_grade IS '장기요양등급 (1~5, 인지지원)';
COMMENT ON COLUMN client.medical_notes IS '주요 질환·특이사항 (AI 프롬프트 컨텍스트)';

-- ------------------------------------------------------------
-- 3. Guardian (보호자)
-- 수급자의 가족 또는 법정 대리인. 알림톡 수신 대상.
-- ------------------------------------------------------------
CREATE TABLE guardian (
    id                  UUID          PRIMARY KEY DEFAULT uuid_generate_v7(),
    client_id           UUID          NOT NULL REFERENCES client (id),
    name                VARCHAR(100)  NOT NULL,     -- AES-256 암호화. 다국어 이름 대응 100자
    phone               VARCHAR(20)   NOT NULL,     -- AES-256 암호화. E.164 국제 포맷
    relation            VARCHAR(20)   NOT NULL,
    is_primary          BOOLEAN       NOT NULL DEFAULT true,
    alimtalk_consent    BOOLEAN       NOT NULL DEFAULT false,
    alimtalk_consent_at TIMESTAMPTZ,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- 수급자별 보호자 목록
CREATE INDEX idx_guardian_client_id ON guardian (client_id);

COMMENT ON TABLE guardian IS '보호자 - 알림톡 수신 대상. 암호화된 phone은 복호화 후 E.164 검증';
COMMENT ON COLUMN guardian.phone IS '알림톡 수신 번호 (AES-256). E.164 국제 포맷 (예: +821012345678)';
COMMENT ON COLUMN guardian.alimtalk_consent_at IS '알림톡 수신 동의 일시 (개인정보보호법 동의 이력)';

-- ------------------------------------------------------------
-- 4. Assignment (배정)
-- 수급자와 담당 요양보호사의 연결 관계.
-- ------------------------------------------------------------
CREATE TABLE assignment (
    id                  UUID                PRIMARY KEY DEFAULT uuid_generate_v7(),
    user_center_role_id UUID                NOT NULL REFERENCES user_center_role (id),
    client_id           UUID                NOT NULL REFERENCES client (id),
    visit_days          VARCHAR(20),
    visit_time          TIME,
    start_date          DATE                NOT NULL,
    end_date            DATE,
    status              assignment_status   NOT NULL DEFAULT 'ACTIVE',
    created_at          TIMESTAMPTZ         NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ         NOT NULL DEFAULT now()
);

-- 요양보호사별 배정 목록
CREATE INDEX idx_assign_ucr_id ON assignment (user_center_role_id);
-- 수급자별 배정 이력
CREATE INDEX idx_assign_client_id ON assignment (client_id);
-- 활성 배정의 방문일 기준 조회
CREATE INDEX idx_assign_status_visit ON assignment (status, visit_days);

COMMENT ON TABLE assignment IS '배정 - 수급자 ↔ 요양보호사 연결';
COMMENT ON COLUMN assignment.visit_days IS '방문 요일 (예: MON,WED,FRI)';

-- ------------------------------------------------------------
-- 5. CareRecord (돌봄 기록)
-- 하나의 방문에 대한 전체 기록 라이프사이클 핵심 엔티티.
-- 상태 머신: PROCESSING → DRAFT → SUBMITTED → CONFIRMED / REJECTED
-- ------------------------------------------------------------
CREATE TABLE care_record (
    id                      UUID                PRIMARY KEY DEFAULT uuid_generate_v7(),
    center_id               UUID                NOT NULL REFERENCES center (id),
    caregiver_id            UUID                NOT NULL REFERENCES "user" (id),
    client_id               UUID                NOT NULL REFERENCES client (id),
    visit_date              DATE                NOT NULL,
    audio_file_url          VARCHAR(1000)       NOT NULL,
    audio_duration_seconds  INT                 NOT NULL,
    stt_text                TEXT,
    record_draft            JSONB,
    record_final            JSONB,
    alimtalk_message        TEXT,
    alimtalk_status         alimtalk_status     NOT NULL DEFAULT 'PENDING',
    alimtalk_sent_at        TIMESTAMPTZ,
    status                  care_record_status  NOT NULL DEFAULT 'PROCESSING',
    revision_count          INT                 NOT NULL DEFAULT 0,
    submitted_at            TIMESTAMPTZ,
    confirmed_at            TIMESTAMPTZ,
    confirmed_by            UUID                REFERENCES "user" (id),
    rejected_at             TIMESTAMPTZ,
    rejected_reason         TEXT,
    created_at              TIMESTAMPTZ         NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ         NOT NULL DEFAULT now()
);

-- 센터별 날짜별 기록 목록
CREATE INDEX idx_cr_center_visit_date ON care_record (center_id, visit_date);
-- 요양보호사별 날짜별 기록
CREATE INDEX idx_cr_caregiver_visit_date ON care_record (caregiver_id, visit_date);
-- 센터별 상태별 기록
CREATE INDEX idx_cr_center_status ON care_record (center_id, status);
-- 수급자별 기록 이력
CREATE INDEX idx_cr_client_visit_date ON care_record (client_id, visit_date);

COMMENT ON TABLE care_record IS '돌봄 기록 - 음성→STT→AI초안→확정 라이프사이클';
COMMENT ON COLUMN care_record.record_draft IS 'AI 생성 초안 JSONB: {physical, cognitive, emotional, special_notes}';
COMMENT ON COLUMN care_record.revision_count IS '보정 횟수 (최대 3회)';

-- ------------------------------------------------------------
-- 6. AlimtalkLog (알림톡 발송 로그)
-- 알림톡 발송 이력 추적.
-- ------------------------------------------------------------
CREATE TABLE alimtalk_log (
    id                  UUID              PRIMARY KEY DEFAULT uuid_generate_v7(),
    care_record_id      UUID              NOT NULL REFERENCES care_record (id),
    guardian_id         UUID              NOT NULL REFERENCES guardian (id),
    message             TEXT              NOT NULL,
    solapi_message_id   VARCHAR(100),
    status              alimtalk_status   NOT NULL,
    error_message       TEXT,
    sent_at             TIMESTAMPTZ,
    delivered_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ       NOT NULL DEFAULT now()
);

-- 기록별 발송 이력
CREATE INDEX idx_al_care_record_id ON alimtalk_log (care_record_id);
-- 실패 건 재처리
CREATE INDEX idx_al_status ON alimtalk_log (status);

COMMENT ON TABLE alimtalk_log IS '알림톡 발송 로그 - 솔라피 연동 이력 추적';

-- ============================================================
-- 2단계 (성장) 테이블
-- ============================================================

-- ------------------------------------------------------------
-- ENUM Types (Stage 2)
-- ------------------------------------------------------------
CREATE TYPE subscription_plan AS ENUM ('TRIAL', 'BASIC', 'PREMIUM');
CREATE TYPE subscription_status AS ENUM ('ACTIVE', 'PAST_DUE', 'CANCELLED', 'SUSPENDED');
CREATE TYPE payment_status AS ENUM ('PENDING', 'PAID', 'FAILED', 'REFUNDED');
CREATE TYPE pg_provider AS ENUM ('TOSS_PAYMENTS', 'IAMPORT');
CREATE TYPE nudge_type AS ENUM ('ENTER_REMINDER', 'EXIT_RECORD_NUDGE');

-- ------------------------------------------------------------
-- 7. Subscription (구독)
-- 센터별 구독 과금 정보. 센터와 1:1.
-- ------------------------------------------------------------
CREATE TABLE subscription (
    id                      UUID                  PRIMARY KEY DEFAULT uuid_generate_v7(),
    center_id               UUID                  NOT NULL REFERENCES center (id),
    plan                    subscription_plan     NOT NULL,
    status                  subscription_status   NOT NULL DEFAULT 'ACTIVE',
    billing_key             TEXT,                 -- AES-256 암호화. PG 빌링키
    pg_provider             pg_provider           NOT NULL,
    current_period_start    DATE                  NOT NULL,
    current_period_end      DATE                  NOT NULL,
    trial_ends_at           DATE,
    cancelled_at            TIMESTAMPTZ,
    created_at              TIMESTAMPTZ           NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ           NOT NULL DEFAULT now()
);

-- 센터당 구독 1건
CREATE UNIQUE INDEX uidx_subscription_center ON subscription (center_id);

COMMENT ON TABLE subscription IS '구독 - 센터 1:1. PAST_DUE: 결제 실패 시 조회만 가능';
COMMENT ON COLUMN subscription.billing_key IS 'PG 빌링키 (AES-256 암호화)';

-- ------------------------------------------------------------
-- 8. Payment (결제 내역)
-- 구독 결제 내역.
-- ------------------------------------------------------------
CREATE TABLE payment (
    id                  UUID              PRIMARY KEY DEFAULT uuid_generate_v7(),
    subscription_id     UUID              NOT NULL REFERENCES subscription (id),
    amount              INT               NOT NULL,
    currency            VARCHAR(3)        NOT NULL DEFAULT 'KRW',
    status              payment_status    NOT NULL,
    pg_transaction_id   VARCHAR(100),
    paid_at             TIMESTAMPTZ,
    period_start        DATE              NOT NULL,
    period_end          DATE              NOT NULL,
    invoice_url         VARCHAR(1000),
    created_at          TIMESTAMPTZ       NOT NULL DEFAULT now()
);

COMMENT ON TABLE payment IS '결제 내역 - 금액은 원 단위 INT';
COMMENT ON COLUMN payment.amount IS '결제 금액 (원)';

-- ------------------------------------------------------------
-- 9. Geofence (지오펜스)
-- 수급자 자택 기반 가상 경계.
-- ------------------------------------------------------------
CREATE TABLE geofence (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v7(),
    client_id       UUID            NOT NULL REFERENCES client (id),
    latitude        DECIMAL(10,7)   NOT NULL,
    longitude       DECIMAL(10,7)   NOT NULL,
    radius_meters   INT             NOT NULL DEFAULT 200,
    is_active       BOOLEAN         NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE geofence IS '지오펜스 - 수급자 자택 기반 가상 경계 (반경 기본 200m)';

-- ------------------------------------------------------------
-- 10. NudgeLog (넛지 로그)
-- 지오펜싱 기반 자동 알림 이력.
-- ------------------------------------------------------------
CREATE TABLE nudge_log (
    id              UUID          PRIMARY KEY DEFAULT uuid_generate_v7(),
    user_id         UUID          NOT NULL REFERENCES "user" (id),
    client_id       UUID          NOT NULL REFERENCES client (id),
    geofence_id     UUID          NOT NULL REFERENCES geofence (id),
    type            nudge_type    NOT NULL,
    triggered_at    TIMESTAMPTZ   NOT NULL,
    acknowledged    BOOLEAN       NOT NULL DEFAULT false
);

COMMENT ON TABLE nudge_log IS '넛지 로그 - 지오펜싱 기반 ENTER/EXIT 자동 알림';

-- ------------------------------------------------------------
-- 11. ConsistencyCheck (정합성 검증)
-- STT 원문과 AI 초안 간 의미 일치도 검증 결과. care_record와 1:1.
-- ------------------------------------------------------------
CREATE TABLE consistency_check (
    id              UUID          PRIMARY KEY DEFAULT uuid_generate_v7(),
    care_record_id  UUID          NOT NULL REFERENCES care_record (id),
    score           INT           NOT NULL,
    details         JSONB,
    warning_shown   BOOLEAN       NOT NULL DEFAULT false,
    model_version   VARCHAR(50)   NOT NULL,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- care_record와 1:1
CREATE UNIQUE INDEX uidx_cc_care_record ON consistency_check (care_record_id);

COMMENT ON TABLE consistency_check IS '정합성 검증 - STT↔AI초안 일치도 (score 0~100, <70 경고)';

-- ------------------------------------------------------------
-- 12. PremiumReport (프리미엄 리포트)
-- 보호자에게 발송하는 월간 돌봄 종합 리포트.
-- ------------------------------------------------------------
CREATE TABLE premium_report (
    id              UUID              PRIMARY KEY DEFAULT uuid_generate_v7(),
    center_id       UUID              NOT NULL REFERENCES center (id),
    client_id       UUID              NOT NULL REFERENCES client (id),
    report_month    DATE              NOT NULL,
    pdf_url         VARCHAR(1000)     NOT NULL,
    summary         JSONB             NOT NULL,
    vital_trends    JSONB,
    sent_status     alimtalk_status   NOT NULL DEFAULT 'PENDING',
    sent_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ       NOT NULL DEFAULT now()
);

-- 수급자+월 유니크
CREATE UNIQUE INDEX uidx_pr_client_month ON premium_report (client_id, report_month);

COMMENT ON TABLE premium_report IS '프리미엄 리포트 - 월간 돌봄 종합 리포트 (PDF)';
