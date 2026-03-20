# 보듬(Bodeum) TODO LIST

> PRD v0.0.1 기반 | 작성일: 2026-03-19
> MVP(1단계 P0) → 1단계 P1 → 2단계 → 3단계 순서로 정렬
> 상태: ⬜ 미착수 | 🔲 진행중 | ✅ 완료

---

## Phase 0: 프로젝트 초기 설정

### 인프라 & DevOps

- ⬜ **INF-001** | 모노레포 또는 멀티레포 구조 결정 및 Git 저장소 생성
- ⬜ **INF-002** | Spring Cloud Gateway 프로젝트 스캐폴딩 (Kotlin 2.3.20 / Spring Boot 4.0.3)
- ⬜ **INF-003** | Auth Service 프로젝트 스캐폴딩
- ⬜ **INF-004** | Care Service 프로젝트 스캐폴딩
- ⬜ **INF-005** | AI Pipeline Service 프로젝트 스캐폴딩
- ⬜ **INF-006** | Notification Service 프로젝트 스캐폴딩
- ⬜ **INF-007** | PostgreSQL 17 로컬/Docker 환경 구성
- ⬜ **INF-008** | Flyway 마이그레이션 설정 (서비스별 독립 DB)
- ⬜ **INF-009** | V1 DDL 스크립트 적용 (Auth / Care / Notification)
- ⬜ **INF-010** | Docker Compose 개발 환경 구성 (PostgreSQL + Redis + LocalStack S3)
- ⬜ **INF-011** | GitHub Actions CI 파이프라인 구성 (빌드 + 테스트)
- ⬜ **INF-012** | AWS 계정 설정 + RDS / S3 / SQS 프로비저닝 (1단계)
- ⬜ **INF-013** | 코드 컨벤션 & Lint 설정 (ktlint, ESLint, Prettier)

### 공통 모듈

- ⬜ **COM-001** | JWT 발급·검증 공통 라이브러리 (Access 15분 / Refresh 90일·14일)
- ⬜ **COM-002** | AES-256 암호화·복호화 유틸리티 (개인정보 암호화용)
- ⬜ **COM-003** | API 공통 응답 형식 (ErrorResponse, PageResponse 등)
- ⬜ **COM-004** | Spring Cloud Gateway 라우팅 + 인증 토큰 검증 필터
- ⬜ **COM-005** | RBAC 접근 제어 필터 (CAREGIVER / DIRECTOR / SOCIAL_WORKER / ADMIN)
- ⬜ **COM-006** | 서비스 간 비동기 메시징 설정 (SQS 또는 Spring Cloud Stream)

---

## Phase 1: MVP — 1단계 P0 (2026.04 ~ 2026.10)

### Sprint 1~2 (4월): Auth Service + Care Service 기본 CRUD

#### Auth Service (Kotlin / Spring Boot)

- ⬜ **AUTH-001** | `F-APP-001` SMS OTP 발송 API (`POST /api/v1/auth/otp/send`) — Solapi 연동
- ⬜ **AUTH-002** | `F-APP-001` OTP 검증 + JWT 발급 API (`POST /api/v1/auth/otp/verify`) — 3분 TTL, 최대 5회 시도
- ⬜ **AUTH-003** | `F-APP-001` 기기 신뢰 등록 API (`POST /api/v1/auth/device/register`) — device_id + fingerprint 저장
- ⬜ **AUTH-004** | `F-APP-001` 생체/PIN 인증 후 JWT 갱신 API (`POST /api/v1/auth/refresh`)
- ⬜ **AUTH-005** | `F-APP-001` 등록된 기기 목록 조회 / 해제 API
- ⬜ **AUTH-006** | `F-APP-001` 소속 센터 목록 조회 + 활성 센터 전환 API
- ⬜ **AUTH-007** | `F-BO-001` 웹 로그인 요청 API (`POST /api/v1/auth/web/request`) — 앱 푸시 발송 트리거
- ⬜ **AUTH-008** | `F-BO-001` 앱에서 웹 로그인 승인 API (`POST /api/v1/auth/web/approve`)
- ⬜ **AUTH-009** | `F-BO-001` 웹 승인 상태 폴링/WebSocket API (`GET /api/v1/auth/web/status/{requestId}`)
- ⬜ **AUTH-010** | `F-BO-001` 브라우저 신뢰 등록·조회·해제 API (14일 만료)
- ⬜ **AUTH-011** | `F-BO-001` OTP 폴백 로그인 (앱 미설치/푸시 불가 시)
- ⬜ **AUTH-012** | `F-ADMIN-000` 어드민 2FA 인증 (앱 푸시 + SMS OTP)

#### Care Service (Kotlin / Spring Boot)

- ⬜ **CARE-001** | `F-BO-004` 수급자 CRUD API (등록·조회·수정·비활성화) — AES-256 암호화 적용
- ⬜ **CARE-002** | `F-BO-004` 보호자 CRUD API (수급자별 보호자 등록, 알림톡 수신 동의)
- ⬜ **CARE-003** | `F-BO-005` 요양보호사 등록 API — 기존 User 조회 → UserCenterRole 생성 또는 신규 User + 초대 SMS
- ⬜ **CARE-004** | `F-BO-005` 요양보호사 목록 조회·수정·비활성화 API
- ⬜ **CARE-005** | `F-BO-006` 수급자-요양보호사 배정 CRUD API (Assignment)
- ⬜ **CARE-006** | `F-APP-002` 오늘 방문 목록 조회 API (`GET /api/v1/visits/today`) — 활성 센터 + 로그인 사용자 기준

### Sprint 3~4 (5월): AI Pipeline + Notification Service

#### AI Pipeline Service (Kotlin / Spring Boot)

- ⬜ **AI-001** | `F-AI-001` 음성 파일 수신 + S3 업로드 API (`POST /api/v1/records`)
- ⬜ **AI-002** | `F-AI-001` Whisper STT 연동 — 음성 → 텍스트 변환 (Coroutine 비동기)
- ⬜ **AI-003** | `F-AI-002` GPT-4o-mini 연동 — STT 텍스트 + 수급자 컨텍스트 → 상태변화기록지 초안 생성 (W4C 서식 JSONB)
- ⬜ **AI-004** | `F-AI-002` AI 시스템 프롬프트 작성 (환각 방지 규칙 포함, PRD 7장 참조)
- ⬜ **AI-005** | `F-AI-003` 보호자 알림톡 메시지 자동 생성 (200자 이내, 따뜻한 톤)
- ⬜ **AI-006** | AI 처리 상태 폴링 API (`GET /api/v1/records/{id}/status`) — PROCESSING → DRAFT 상태 전이
- ⬜ **AI-007** | CareRecord 상태 머신 구현 (PROCESSING → DRAFT → SUBMITTED → CONFIRMED / REJECTED)

#### Notification Service (Kotlin / Spring Boot)

- ⬜ **NOTI-001** | `F-AI-004` 카카오 알림톡 발송 연동 (Solapi API) — 템플릿 기반 발송
- ⬜ **NOTI-002** | `F-AI-004` 알림톡 발송 로그 저장 (AlimtalkLog) + 상태 추적 (PENDING → SENT → DELIVERED / FAILED)
- ⬜ **NOTI-003** | FCM 푸시 알림 발송 모듈 — 웹 로그인 승인 요청, 미제출 알림 등
- ⬜ **NOTI-004** | 알림 템플릿 관리 (NotificationTemplate) — 시드 데이터 적용
- ⬜ **NOTI-005** | AI Pipeline → Notification 비동기 메시징 연동 (SQS)

#### 엔드투엔드 파이프라인 통합

- ⬜ **E2E-001** | 음성 업로드 → Whisper STT → GPT-4o-mini → 알림톡 발송 전체 흐름 통합 테스트
- ⬜ **E2E-002** | 성능 검증: 음성 업로드 → AI 초안 반환 15초 이내 목표
- ⬜ **E2E-003** | 알림톡 발송 지연 30초 이내 목표 검증

### Sprint 5~6 (6월): React Native 앱 — 요양보호사

- ⬜ **APP-001** | React Native + Expo 프로젝트 스캐폴딩 (TypeScript)
- ⬜ **APP-002** | `F-APP-001` 로그인 화면 — 전화번호 입력 + OTP 인증 + 기기 등록 플로우
- ⬜ **APP-003** | `F-APP-001` 생체인증/PIN 설정 및 일상 로그인 화면
- ⬜ **APP-004** | `F-APP-001` 복수 센터 선택 화면
- ⬜ **APP-005** | `F-APP-002` 홈 화면 — 오늘 방문 목록 (방문 예정·완료·미제출 카드)
- ⬜ **APP-006** | `F-APP-003` 음성 녹음 화면 — 수급자 선택 → 녹음 시작/중지 → 업로드
- ⬜ **APP-007** | `F-APP-003` 녹음 중 실시간 파형·타이머 UI
- ⬜ **APP-008** | `F-APP-004` AI 초안 확인 화면 — PROCESSING 대기 → DRAFT 결과 표시
- ⬜ **APP-009** | `F-APP-004` AI 초안 텍스트 직접 수정 (터치 수정)
- ⬜ **APP-010** | `F-APP-004a` 보정 기능 — 추가 음성 업로드 / 다시 녹음 (최대 3회)
- ⬜ **APP-011** | `F-APP-004` 제출 버튼 (DRAFT → SUBMITTED)
- ⬜ **APP-012** | 고령 사용자 접근성 적용 — 18sp+ 폰트, 48dp+ 터치 타겟, WCAG AA 색상 대비
- ⬜ **APP-013** | 에러 핸들링 — 네트워크 오류, 서버 오류 등 쉬운 한국어 메시지

### Sprint 7~8 (7월): 앱 마감 + 스토어 제출

- ⬜ **APP-014** | `F-DIR-002` 원장님 앱 — 웹 로그인 푸시 승인 화면 (생체/PIN → 승인 버튼)
- ⬜ **APP-015** | `F-DIR-001` 원장님 앱 — 홈 대시보드 (방문 예정/완료/미제출 카드)
- ⬜ **APP-016** | `F-DIR-003` 원장님 앱 — 기록 현황 조회 (상태별 필터)
- ⬜ **APP-017** | `F-DIR-004` 원장님 앱 — 미제출 알림 + 리마인더 발송 버튼
- ⬜ **APP-018** | 앱 아이콘, 스플래시 스크린, 온보딩 튜토리얼 화면
- ⬜ **APP-019** | 내정보 탭 — 프로필, 센터 정보, 기기 관리, 언어 설정
- ⬜ **APP-020** | iOS TestFlight + Android Internal Testing 배포
- ⬜ **APP-021** | 앱스토어 / 플레이스토어 심사 제출 (개인정보처리방침 포함)

### Sprint 9~10 (8월): React 웹 백오피스

- ⬜ **WEB-001** | React 19 + TypeScript + Vite 프로젝트 스캐폴딩
- ⬜ **WEB-002** | `F-BO-001` 웹 로그인 화면 — 전화번호 입력 → "앱에서 승인해주세요" 대기 (60초 타이머) → WebSocket/폴링
- ⬜ **WEB-003** | `F-BO-001` OTP 폴백 로그인 화면
- ⬜ **WEB-004** | `F-BO-001` 센터 선택 화면 (복수 센터 보유 시)
- ⬜ **WEB-005** | `F-BO-002` 대시보드 — 오늘 현황 (방문 건수, 제출/미제출/확정 대기)
- ⬜ **WEB-006** | `F-BO-003` AI 초안 검토·확정 화면 — 목록 → 상세 (텍스트 + 알림톡 + 음성 재생) → 수정 → 확정/반려
- ⬜ **WEB-007** | `F-BO-004` 수급자 관리 화면 — 목록 + 등록/수정 폼 + 보호자 관리
- ⬜ **WEB-008** | `F-BO-005` 요양보호사 관리 화면 — 목록 + 등록(초대 SMS) + 수정
- ⬜ **WEB-009** | `F-BO-006` 수급자-요양보호사 배정 화면 — 드래그앤드롭 또는 선택 UI
- ⬜ **WEB-010** | `F-BO-007` 기록 보관 및 내보내기 — 날짜/수급자 필터 + PDF 다운로드 + 엑셀 일괄 다운로드

#### Care Service 추가 (PDF/Excel 내보내기)

- ⬜ **CARE-007** | `F-BO-007` PDF 내보내기 API — 공단 상태변화기록지 양식 준수
- ⬜ **CARE-008** | `F-BO-007` 엑셀 내보내기 API — 기간별 일괄 다운로드
- ⬜ **CARE-009** | `F-BO-003` 기록 확정/반려 API (`POST /api/v1/records/{id}/confirm`, `/reject`)

#### 어드민 콘솔 (웹)

- ⬜ **ADMIN-001** | `F-ADMIN-000` 어드민 로그인 화면 — 앱 푸시 승인 + SMS OTP 2FA
- ⬜ **ADMIN-002** | `F-ADMIN-001` 센터 온보딩 승인 화면 — 신청 목록 + 승인/거절 + 원장님 계정 자동 생성

### Sprint 11~12 (9월): 시범 운영

- ⬜ **OPS-001** | 시범 운영 센터 5개소 확보 (MOU 체결)
- ⬜ **OPS-002** | 1:1 온보딩 교육 매뉴얼 작성 (요양보호사 + 원장님)
- ⬜ **OPS-003** | 현장 피드백 수집 체계 구축 (인앱 피드백 / 설문)
- ⬜ **OPS-004** | 카카오 알림톡 템플릿 심사 완료 확인
- ⬜ **OPS-005** | 모니터링 설정 (CloudWatch + Sentry)

### Sprint 13~14 (10월): 피드백 반영 + 정식 런칭 준비

- ⬜ **OPS-006** | 시범 운영 피드백 기반 버그 수정 + UX 개선
- ⬜ **OPS-007** | AI 프롬프트 튜닝 (50건 모의 테스트, 환각률 5% 미만 목표)
- ⬜ **OPS-008** | 성능 최적화 (목표: 파이프라인 95%+ 성공률)
- ⬜ **OPS-009** | 100개소 영업 확장 준비 (영업 자료, 데모 환경)

---

## Phase 1-B: 1단계 P1 기능

- ⬜ **APP-P1-001** | `F-APP-005` 기록 히스토리 화면 — 날짜별 과거 기록 조회 (앱)
- ⬜ **APP-P1-002** | `F-APP-006` 푸시 알림 수신 및 알림 센터 화면 (앱)
- ⬜ **WEB-P1-001** | `F-BO-008` 센터 설정 화면 — 센터 정보 수정 + 카카오 채널 연동 + 솔라피 잔액 확인
- ⬜ **ADMIN-P1-001** | `F-ADMIN-002` 서비스 모니터링 대시보드 — 일별 녹음 건수, AI 성공률, 알림톡 성공률

---

## Phase 2: 성장 (2026.11 ~ 2027.06)

### 2026 Q4: 결제 + 유료 전환

- ⬜ **PAY-001** | `F-PAY-001` Subscription / Payment 엔티티 활성화 (DDL 2단계 테이블)
- ⬜ **PAY-002** | `F-PAY-001` PG 연동 (토스페이먼츠 or 아임포트) — 빌링키 등록 + 월 자동 결제
- ⬜ **PAY-003** | `F-PAY-001` 요금제 선택 UI (Basic / Premium) + 결제 화면
- ⬜ **PAY-004** | `F-PAY-001` 미결제 시 서비스 제한 로직 (조회만 가능)
- ⬜ **PAY-005** | `F-PAY-001` 결제 내역 조회 + 세금계산서 발행

### 2027 Q1: 지오펜싱 + 대시보드 + 정합성 검증

- ⬜ **GEO-001** | `F-GEO-001` Geofence / NudgeLog 엔티티 활성화
- ⬜ **GEO-002** | `F-GEO-001` 수급자 자택 지오펜스 설정 API (반경 200m)
- ⬜ **GEO-003** | `F-GEO-001` 앱 진입 감지 → "오늘 방문 시작" 알림
- ⬜ **GEO-004** | `F-GEO-001` 이탈 후 10분 미기록 시 넛지 발송
- ⬜ **DASH-001** | `F-DASH-001` 누적 데이터 분석 대시보드 — 기록 완료율, 요양보호사별 현황, 상태 변화 추이
- ⬜ **DASH-002** | `F-DASH-001` 차트 시각화 (Bar/Line) + PDF 리포트 다운로드
- ⬜ **AI-P2-001** | `F-AI-005` 정합성 검증 엔진 — STT ↔ AI 초안 의미 일치도 점수 (0~100)
- ⬜ **AI-P2-002** | `F-AI-005` 점수 70 미만 시 경고 표시 UI

### 2027 Q2: 다국어 + 프리미엄 리포트 + 특허

- ⬜ **AI-P2-003** | `F-AI-006` 다국어 STT — 베트남어/중국어/우즈베크어 → 한국어 변환 파이프라인
- ⬜ **RPT-001** | `F-REPORT-001` PremiumReport 엔티티 활성화
- ⬜ **RPT-002** | `F-REPORT-001` 월간 돌봄 종합 PDF 자동 생성 (센터 로고 + 직인)
- ⬜ **RPT-003** | `F-REPORT-001` 프리미엄 리포트 알림톡 발송
- ⬜ **BIZ-001** | 특허 출원 — 음성-텍스트 정합성 검증 기술

---

## Phase 3: 확장 (2027.07 ~)

### 2027 Q3: 공단 연동 + 인프라 확장

- ⬜ **ERP-001** | `F-ERP-001` 공단 장기요양정보시스템 호환 포맷 변환·내보내기
- ⬜ **ERP-002** | `F-ERP-001` 주요 ERP 연동 API (케어닥, 토닥 등)
- ⬜ **INF-P3-001** | Kubernetes 기반 수평 확장 전환 (동시 접속 10,000명)

### 2027 Q4: AI 분석 + 멀티 기관

- ⬜ **TREND-001** | `F-TREND-001` 수급자 건강 트렌드 AI 분석 리포트
- ⬜ **TREND-002** | `F-TREND-001` 급격한 상태 악화 감지 → 자동 알림
- ⬜ **MULTI-001** | `F-MULTI-001` 멀티 기관 유형 지원 — 주야간보호, 방문목욕, 방문간호
- ⬜ **MULTI-002** | `F-MULTI-001` 서비스 유형별 기록 서식 + 알림톡 템플릿 분리

---

## 외부 의존성 체크리스트

| 항목 | 담당 | 시한 | 상태 |
|:---|:---|:---|:---|
| 카카오 비즈니스 채널 개설 | 대표자 | 2026.04 | ⬜ |
| 솔라피(Solapi) 사업자 계정 개설 | 대표자 | 2026.04 | ⬜ |
| 알림톡 템플릿 심사 신청 | 대표자 | 2026.05 | ⬜ |
| 앱스토어 개발자 계정 (Apple/Google) | 대표자 | 2026.06 | ⬜ |
| 시범 운영 센터 MOU 체결 | 대표자 + 자문위원 | 2026.08 | ⬜ |
| 개인정보 처리방침·이용약관 법률 검토 | 외부 자문 | 2026.07 | ⬜ |
| PG사 계약 (토스페이먼츠/아임포트) | 대표자 | 2026.11 | ⬜ |
| 특허 출원 (정합성 검증) | 대표자 + 변리사 | 2027.Q2 | ⬜ |
| 공단 장기요양정보시스템 연동 협의 | 대표자 | 2027.Q3 | ⬜ |

---

## 비기능 요구사항 체크리스트

| 항목 | 목표 | 상태 |
|:---|:---|:---|
| 파이프라인 응답 시간 | 15초 이내 | ⬜ |
| 알림톡 발송 지연 | 30초 이내 | ⬜ |
| 웹 페이지 로드 | 2초 이내 | ⬜ |
| 동시 접속 (시범) | 50명 | ⬜ |
| HTTPS TLS 1.3 | 전체 API | ⬜ |
| 개인정보 AES-256 암호화 | 수급자·보호자 PII | ⬜ |
| 음성 파일 S3 SSE 암호화 | S3 저장소 | ⬜ |
| RBAC 접근 제어 | 역할별 데이터 격리 | ⬜ |
| 앱 접근성 (고령자) | 18sp/48dp/WCAG AA | ⬜ |
| 서비스 가용성 (1단계) | 99.5% | ⬜ |
| RDS 일일 자동 백업 | Multi-AZ | ⬜ |

---

> **총 태스크 수**: ~100개 (Phase 0: 19 / Phase 1 MVP: 62 / Phase 1-B: 4 / Phase 2: 14 / Phase 3: 6)
> **크리티컬 패스**: INF → AUTH + CARE → AI + NOTI → E2E → APP → WEB → 시범운영
