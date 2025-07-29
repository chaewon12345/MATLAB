# Wildfire_backend

---

## 프로젝트 구성 흐름

1. 사용자 위도·경도 입력
2. 반경 15km 이내 격자 필터링 (`korea_grids_0.01deg.csv`)
3. 각 격자에 실시간 날씨 데이터 추가 (Open-Meteo API)
4. FARSITE 기반 확산 확률 계산 (8방향 확률)
5. 방향별 가중치 적용 → 보정 확률 계산
6. 21개 지표로 구성된 JSON 생성
7. 외부 AI 예측 서버로 전송

---

## 디렉토리 구조

```
.
├── api/
│   └── predict_api.py              # API 라우터
├── controller/
│   └── predict_controller.py       # 요청 제어
├── service/
│   ├── farsite_service.py          # 확산 계산
│   ├── predict_service.py          # 전체 파이프라인
│   ├── weather_service.py          # 날씨 데이터
│   └── ai_service.py               # AI 전송
├── repository/
│   ├── grid_repository.py          # 격자 필터링
│   └── feature_repository.py       # 지표 조회
├── util/
│   ├── geo_utils.py                # 거리 계산
│   └── json_utils.py               # NaN 제거
├── dto/
│   └── predict_dto.py              # 입력 객체
├── main.py                         # FastAPI 실행
└── requirements.txt                # 패키지 목록
```

---

## 기술 스택

- **Python 3.10+**
- **FastAPI** – 비동기 API 서버
- **NumPy, Pandas** – 데이터 처리
- **httpx** – 비동기 HTTP 요청
- **Open-Meteo API** – 실시간 날씨
- **Render** – 배포 플랫폼

---

## 예시 입력 & 응답

### ▶ 예시 입력 (POST `/input`)
```json
{
  "lat": 37.123,
  "lon": 127.456
}
```

### ▶ 예시 응답
```json
{
  "입력 위도": 37.123,
  "입력 경도": 127.456,
  "격자 수": 85,
  "지표 + 날씨 샘플": [
    {
      "grid_id": 10102,
      "center_lat": 37.12,
      "center_lon": 127.45,
      "farsite_prob": 0.021
      ...
    }
  ]
}
```