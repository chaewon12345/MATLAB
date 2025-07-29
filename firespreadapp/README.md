# firespreadapp

## 주요 기능

1. 실시간 산불 예측

입력한 위도경도 중심으로 반경 15km 이내의 예측 데이터를 자동 검색합니다.

2. Top3 영향 요인 표시

사용자가 선택한 위치의 격자에서 산불 확산에 영향을 미치는 주요 3가지 요인을 텍스트로 제공합니다.

3. 위험도 시각화

반경 15km 이내의 확산확률에 따라 위험도를 색상으로 시각화하여 직관적으로 표현합니다.


## 사용 기술

- Googlemaps API
- Flutter(Dart)
- Firebase Firestore


## 입력-출력 데이터 흐름

### 입력
fire_locations 컬렉션에 위도(lat)와 경도(lon) 정보를 포함한 JSON 데이터를 업로드하여 입력 데이터를 Firestore에 저장합니다.

### 출력
fire_results 컬렉션에서 예측 결과를 가져와(top 3 영향 요인 텍스트 포함), 각 grid_id에 대해 lat_min, lat_max, lon_min, lon_max 값을 기반으로 폴리곤 격자를 생성합니다.
각 격자는 해당 grid_id의 pSpread 값(확산 확률 범위)에 따라 색상을 달리하여 위험도를 시각화합니다.

### 시연 이미지
<img width="398" height="835" alt="스크린샷 2025-07-29 오후 1 30 03" src="https://github.com/user-attachments/assets/4055b9e9-a843-4387-a0db-429f46f1eea7" />
<img width="399" height="837" alt="스크린샷 2025-07-29 오후 1 30 51" src="https://github.com/user-attachments/assets/e7547874-ad1a-4d0e-9701-391e146bf1d1" />
<img width="399" height="839" alt="스크린샷 2025-07-29 오후 1 31 38" src="https://github.com/user-attachments/assets/f4cba3b8-e30d-4ea7-a0f4-04a8b198698a" />
<img width="398" height="842" alt="스크린샷 2025-07-29 오후 1 32 23" src="https://github.com/user-attachments/assets/49c36126-3adb-4c9c-a687-a3808de0677b" />


