# 🔥 FireSpreadAPI – 산불 확산 예측 백엔드

이 프로젝트는 사용자가 지정한 위치에 대해 산불 확산 확률을 예측하고 Firebase에 저장하는 FastAPI 기반의 백엔드입니다.  
예측은 MATLAB의 `predictSpread.m` 모델을 호출하여 수행되며, 입력은 다양한 기상·지형·식생 지표로 구성됩니다.

---

## 📌 프로젝트 흐름

1. 사용자가 예측 대상 격자의 지표 데이터를 `/input` API로 전송  
2. 서버는 입력을 큐에 저장  
3. 외부 MATLAB 시스템이 `/check_input`을 통해 입력을 꺼내 예측 수행  
4. 예측 결과는 `/upload_result`로 다시 서버에 전달되어 Firebase에 저장  
5. 또는 `/predict` API를 통해 직접 MATLAB 모델을 호출하여 예측 가능  

---

## 🗂️ 디렉토리 구조

firespreadAPI/
├── main.py # 입력 큐 관리 및 Firebase 저장 처리
├── server.py # MATLAB 기반 예측 API
├── firebase-key.json # 🔐 Firebase 인증 키 (공개 금지)
├── requirements.txt # Python 패키지 목록
└── README.md # 이 문서

yaml
복사
편집

---

## ⚙️ 기술 스택

- **Python 3.10+**
- **FastAPI** – 비동기 REST API 서버
- **Firebase Admin SDK** – 예측 결과 저장
- **MATLAB Engine API for Python** – `predictSpread.m` 실행
- **JSON + REST API** – 구조화된 데이터 송수신

---

## 📡 주요 API 설명

### ▶ `/input` (POST)

1개 격자에 대해 예측에 필요한 모든 피처 데이터를 받아 입력 큐에 저장합니다.

#### 예시 입력:

```json
{
  "grid_id": 10101,
  "lat_min": 36.94,
  "lat_max": 36.96,
  "lon_min": 128.44,
  "lon_max": 128.46,
  "center_lat": 36.95,
  "center_lon": 128.45,
  "avg_fuelload_pertree_kg": 1.5,
  "FFMC": 89,
  "DMC": 70,
  "DC": 450,
  "NDVI": 0.38,
  "smap_20250630_filled": 0.20,
  "temp_C": 29,
  "humidity": 33,
  "wind_speed": 5.2,
  "wind_deg": 135,
  "precip_mm": 0.0,
  "mean_slope": 25,
  "spei_recent_avg": -1.7,
  "farsite_prob": 0.12
}
```



### ▶ /check_input (GET)
입력 큐에서 데이터를 하나 꺼냅니다. (외부 MATLAB 시스템이 사용)

### ▶ /reset_input (POST)
입력 큐를 초기화합니다.

### ▶ /upload_result (POST)
MATLAB 예측 결과를 받아 Firebase에 저장합니다.

예시 입력:
{
  "grid_results": [
    {
      "grid_id": 10101,
      "center_lat": 36.95,
      "center_lon": 128.45,
      "lat_min": 36.94,
      "lat_max": 36.96,
      "lon_min": 128.44,
      "lon_max": 128.46,
      "pSpread": 0.34
    }
  ],
  "global_top3": ["wind_speed", "FFMC", "humidity"]
}
### ▶ /predict (POST)
MATLAB의 predictSpread.m을 직접 호출해 단일 격자에 대한 예측을 수행합니다.
요청 형식은 /input과 동일합니다.

## 🔐 보안 주의사항
firebase-key.json은 절대 GitHub에 올리지 말고 .gitignore에 포함하세요:
```
firebase-key.json
```

## 📝 requirements.txt 예시
```
fastapi
firebase-admin
uvicorn
python-dotenv
```