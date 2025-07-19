# 🌍 지진 정보 모니터링 앱

일본기상청(JMA) API를 활용한 실시간 지진 정보 모니터링 Flutter 앱입니다.

## 📱 주요 기능

### ✅ 완성된 기능
- 🔍 **일본기상청 실시간 지진 데이터 수집**
- 📊 **지진 강도별 색상 구분** (노란색: <5.0, 주황색: 5.0-6.9, 빨간색: ≥7.0)
- 📱 **직관적인 지진 목록 UI**
- 💾 **Supabase 데이터베이스 연동**
- 🔄 **실시간 자동 업데이트** (2분 간격)
- 🎯 **중복 데이터 방지**
- 🔍 **상세 정보 조회**

### 📊 표시 정보
- 지진탐지일시
- 진앙지역명 (일본어)
- 지진강도 (Magnitude)
- 최대진도 (0-7 스케일)
- 발표일시

## 🛠️ 기술 스택

- **Frontend**: Flutter
- **Backend**: Supabase (PostgreSQL)
- **API**: 일본기상청 (JMA) 공개 API
- **상태관리**: Provider
- **HTTP 통신**: Dio, HTTP

## 🚀 설치 및 실행

### 1. 의존성 설치
```bash
flutter pub get
```

### 2. Supabase 설정

#### 2.1 Supabase 프로젝트 생성
1. [Supabase](https://supabase.com) 방문
2. 새 프로젝트 생성
3. 데이터베이스 비밀번호 설정
4. 리전 선택 (권장: Northeast Asia - Seoul)

#### 2.2 데이터베이스 스키마 설정
1. Supabase Dashboard → SQL Editor
2. `supabase_schema.sql` 파일 내용 복사하여 실행

#### 2.3 API 키 설정
1. Supabase Dashboard → Settings → API
2. `lib/config/supabase_config.dart` 파일 수정:
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
}
```

### 3. 앱 실행
```bash
flutter run
```

## 📁 프로젝트 구조

```
lib/
├── config/
│   └── supabase_config.dart      # Supabase 설정
├── models/
│   └── earthquake_model.dart     # 지진 데이터 모델
├── services/
│   ├── jma_api_service.dart      # JMA API 서비스
│   ├── supabase_service.dart     # Supabase 서비스
│   └── earthquake_sync_service.dart # 동기화 서비스
├── screens/
│   └── home_screen.dart          # 메인 화면
├── widgets/
│   └── earthquake_card.dart      # 지진 카드 위젯
├── utils/
│   └── color_utils.dart          # 색상 유틸리티
└── main.dart                     # 메인 앱
```

## 🔧 주요 서비스

### JmaApiService
- 일본기상청 API 호출
- 지진 데이터 파싱
- 최신 지진 정보 조회

### SupabaseService
- 데이터베이스 CRUD 작업
- 중복 데이터 방지
- 실시간 데이터 스트리밍

### EarthquakeSyncService
- 자동 데이터 동기화
- 실시간 업데이트 스트림
- 백그라운드 데이터 수집

## 📊 데이터베이스 스키마

### earthquakes 테이블
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID | 기본 키 |
| event_id | TEXT | JMA 이벤트 ID (유니크) |
| detected_at | TIMESTAMP | 지진 탐지 시간 |
| region_name | TEXT | 진앙 지역명 |
| magnitude | DECIMAL(3,1) | 지진 강도 |
| max_intensity | INTEGER | 최대 진도 |
| announced_at | TIMESTAMP | 발표 시간 |
| created_at | TIMESTAMP | 생성 시간 |
| updated_at | TIMESTAMP | 업데이트 시간 |

## 🎨 UI 특징

### 색상 구분 시스템
- 🟡 **노란색**: 진도 5.0 미만
- 🟠 **주황색**: 진도 5.0 - 6.9
- 🔴 **빨간색**: 진도 7.0 이상

### 반응형 디자인
- Material Design 3.0 적용
- 다크/라이트 모드 지원
- 다양한 화면 크기 지원

## 🔄 실시간 업데이트

- **자동 동기화**: 2분마다 JMA API 호출
- **실시간 스트림**: 새로운 지진 발생 시 즉시 업데이트
- **중복 방지**: 동일한 지진 이벤트 중복 저장 방지
- **오프라인 지원**: 로컬 데이터베이스 캐싱

## 🔒 보안 설정

### Row Level Security (RLS)
- 읽기: 모든 사용자 허용
- 쓰기: 인증된 사용자만 허용

### 데이터 정책
- 중복 데이터 자동 병합
- 자동 타임스탬프 업데이트
- 인덱스 최적화

## 🚀 향후 개선 사항

- [ ] 푸시 알림 기능
- [ ] 지진 위치 지도 표시
- [ ] 즐겨찾기 지역 설정
- [ ] 히스토리 차트 표시
- [ ] 다국어 지원 (한국어, 영어)
- [ ] 위젯 지원
- [ ] 백그라운드 알림

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 🤝 기여

버그 리포트, 기능 요청, 풀 리퀘스트를 환영합니다!