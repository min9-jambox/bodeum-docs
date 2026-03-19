-- ============================================================
-- V3: Notification Service Tables
-- 보듬(Bodeum) - AI 돌봄 기록 SaaS
-- Entities: NotificationTemplate
-- DB: PostgreSQL 17 | Encoding: UTF-8 | Timezone: UTC (TIMESTAMPTZ)
-- ============================================================

-- ------------------------------------------------------------
-- 1. NotificationTemplate (알림 템플릿)
-- 다국어 알림/시스템 메시지 템플릿.
-- 사용자 preferred_locale에 따라 번역된 메시지 제공.
-- 1단계: ko 단일 언어 시드. 2단계: en/vi 번역 추가.
-- ------------------------------------------------------------
CREATE TABLE notification_template (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    template_key    VARCHAR(50)   NOT NULL,
    content         JSONB         NOT NULL,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- 템플릿 키 유니크
CREATE UNIQUE INDEX uidx_notification_template_key ON notification_template (template_key);

COMMENT ON TABLE notification_template IS '다국어 알림 템플릿 - content: {"ko":"...", "en":"...", "vi":"..."}';
COMMENT ON COLUMN notification_template.template_key IS '템플릿 키 (예: otp_message, record_submitted, push_web_auth)';

-- ------------------------------------------------------------
-- Seed Data: 1단계 기본 템플릿 (ko only)
-- ------------------------------------------------------------
INSERT INTO notification_template (template_key, content) VALUES
    ('otp_message',          '{"ko": "[보듬] 인증번호 {{code}}를 입력해주세요. 3분 내 유효합니다."}'),
    ('record_submitted',     '{"ko": "{{caregiver_name}} 요양보호사가 {{client_name}}님의 돌봄 기록을 제출했습니다."}'),
    ('record_confirmed',     '{"ko": "{{client_name}}님의 돌봄 기록이 확정되었습니다."}'),
    ('record_rejected',      '{"ko": "{{client_name}}님의 돌봄 기록이 반려되었습니다. 사유: {{reason}}"}'),
    ('push_web_auth',        '{"ko": "웹 로그인 요청이 있습니다. 본인이 맞으면 승인해주세요."}'),
    ('push_record_ready',    '{"ko": "{{client_name}}님의 돌봄 기록이 준비되었습니다. 확인해주세요."}'),
    ('alimtalk_care_report', '{"ko": "안녕하세요, {{guardian_name}}님.\n{{client_name}}님의 오늘 돌봄 기록을 안내드립니다.\n\n{{care_summary}}\n\n보듬 드림"}');
