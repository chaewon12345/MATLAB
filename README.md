"# 산불 전이 확률 예측 시스템" 

## SPEI 데이터 수집

SPEI 데이터를 아래 플랫폼에서 수집하였습니다.
[Global SPEI database](https://spei.csic.es/spei_database/#map_name=spei06#map_position=1475)

📁 사용하는 데이터가 **1km 격자 기반으로 한반도 지역 분석**이고, 목적이 **단기/중기 가뭄 모니터링 또는 위험 예측**이기에 **`SPEI-06`** 로  결정하였고 `.nc` 형태의 파일을 로컬에 다운로드하였습니다.
<img width="1564" height="1534" alt="image (47)" src="https://github.com/user-attachments/assets/aaf25e13-a00c-4b2a-82e4-3b7eaf6edd41" />

---

## **`SPEI_data.m` - SPEI 최근 6개월 평균 계산**

이 스크립트는 **SPEI 6개월 지수(SPEI06)** 데이터를 기반으로 한반도 전역 격자에 대해 **최근 6개월 평균값**을 계산하여 CSV로 저장합니다. 계산 중간에 끊겨도 **체크포인트 기능을 통해 이어서 실행**이 가능합니다.

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `korea_grids_0.01deg.csv` | 한반도 격자 정보 (`grid_id`, 위·경도 범위 포함) |
| `spei06.nc` | SPEI NetCDF 파일 (변수: `lon`, `lat`, `time`, `spei`) |

## ⚙️ 실행 흐름

### 1. 격자 및 NetCDF 데이터 불러오기

- 기준이 되는 한반도 격자(`grid_id`, `lat_min`, `lat_max`, `lon_min`, `lon_max`)를 불러옵니다.
- SPEI06 NetCDF 파일로부터 위도, 경도, 시간, SPEI 값을 읽어옵니다.

### 2. 최근 6개월 인덱스 선택

- 전체 시간 중에서 **가장 최근 6개 시점**의 인덱스를 선택합니다.
- 이 6개 시점의 평균값을 계산하여 저장하게 됩니다.

### 3. 체크포인트 확인 및 이어서 실행

- `checkpoint.mat` 파일이 존재하는 경우, 이전 계산 중단 위치(`start_idx`)부터 이어서 계산합니다.
- 존재하지 않으면 처음부터 시작합니다.

### 4. 격자별 평균 SPEI 계산

- 각 격자 중심 좌표에 가장 가까운 NetCDF 좌표 인덱스를 찾아 SPEI 값을 추출합니다.
- 최근 6개월의 평균값을 계산하여 저장합니다.
- 결측값(`>1e30`)은 `NaN`으로 처리합니다.

### 5. 주기적 중간 저장

- 5,000개 격자마다 계산 결과를 `checkpoint.mat`에 저장합니다.
- 강제 종료나 오류 발생 시 이어서 재시작 가능하도록 합니다.

### 6. 최종 결과 저장

- 모든 격자에 대한 평균값 계산이 완료되면 결과를 `korea_spei06_recent_avg_all.csv`로 저장합니다.

### 7. 체크포인트 파일 삭제

- 모든 계산이 완료되면 `checkpoint.mat`는 삭제되어 초기화됩니다.

## 💾 출력 파일

| 파일명 | 설명 |
| --- | --- |
| `korea_spei06_recent_avg_all.csv` | 각 격자별 최근 6개월 SPEI 평균값 (`grid_id`, `spei_recent_avg`) |
| `checkpoint.mat` | 중간 계산 상태 저장 파일 (자동 생성 및 최종 삭제됨) |

---

## **`SPEI_data_2.m` - 격자-SPEI 병합**

이 스크립트는 **한반도 전역의 격자 정보**와 **최근 6개월간 SPEI 평균값**을 `grid_id` 기준으로 병합하여 통합된 CSV 파일로 저장합니다. 병합 방식은 **Left Join**에 해당하며, 격자 정보는 모두 유지됩니다.

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `korea_grids_0.01deg.csv` | 한반도 기준 격자 정보 (`grid_id`, 위·경도 경계 포함) |
| `korea_spei06_recent_avg_all.csv` | 각 격자별 최근 6개월 SPEI 평균값 (`grid_id`, `spei_recent_avg`) |

## ⚙️ 실행 흐름

### 1. 파일 불러오기

- 기준 격자 정보와, 해당 격자에 대한 최근 6개월 SPEI 평균값을 각각 불러옵니다.

### 2. `grid_id` 기준 병합

- 두 테이블을 `grid_id`를 기준으로 병합합니다.
- 병합 방식은 **Left Join**으로, 기준 격자에 포함된 모든 `grid_id`는 유지되며, 해당하는 SPEI 값이 있을 경우에만 병합됩니다.
- 격자는 그대로 유지되며, SPEI 값이 없는 경우는 `NaN`으로 표시됩니다.

### 3. 결과 확인 및 저장

- 병합이 완료되면 상위 6개 행(`head`)을 출력하여 미리보기를 제공합니다.
- 최종 결과는 `korea_grids_with_spei.csv` 파일로 저장됩니다.

## 💾 출력 파일

| 파일명 | 설명 |
| --- | --- |
| `korea_grids_with_spei.csv` | 격자 정보에 최근 6개월 평균 SPEI 값이 병합된 최종 결과 파일 |

### 📁 출력 파일 구조 (`korea_grids_with_spei.csv`)

| grid_id | lat_min | lat_max | lon_min | lon_max | center_lat | center_lon | spei_recent_avg |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | ... | ... | ... | ... | … | … | NaN |
| 1 | ... | ... | ... | ... | … | … | -0.231 |
| ... | ... | ... | ... | ... | … | … | ... |

---

## **`SPEI_data_3.m` - SPEI 평균값 지도 시각화**

이 스크립트는 `korea_grids_with_spei.csv` 파일을 기반으로, **최근 6개월간의 SPEI 평균값**을 **한반도 지도 위에 색상 격자 형태로 시각화**합니다. 시각화는 `geoscatter`를 사용해 각 격자의 중심 좌표를 기준으로 색상 점으로 표시됩니다.

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `korea_grids_with_spei.csv` | 격자별 위·경도 경계 및 최근 6개월 SPEI 평균값 포함 파일 |

## ✅ 시각화 그래프
<img width="1536" height="964" alt="image (48)" src="https://github.com/user-attachments/assets/636604cf-2271-4513-bbf8-614e37585748" />


## 지형 데이터 수집 - Slope Extraction by Grid (평균 경사도 계산)

지형 분석도 (지형 경사도)  데이터를 아래 플랫폼에서 수집하였습니다.

[환경 빅데이터 플랫폼- 데이터 검색](https://www.bigdata-environment.kr/user/data_market/detail.do?id=c0a2e080-313c-11ea-adf5-336b13359c97#!)


📁  다양한 데이터 형식 중 GEOTIFF `Slope_All.tif`데이터 파일을 사용하였습니다.
→ 아래는 지형 데이터 파일을 시각화한 사진
<img width="950" height="1112" alt="image (45)" src="https://github.com/user-attachments/assets/70b595ce-7106-4c62-b95f-a0c55bd0f422" />

---

먼저 파이썬으로 **대용량 GeoTIFF**`Slope_All.tif`데이터 파일에서 **한 줄씩 위도/경도 변환을 수행하여 메모리 문제 없이 `lat_grid`와 `lon_grid`를 만드는 작업을 수행하였습니다.**
이는 한반도 영역의 33만개의 대용량 격자 데이터를 다루기 위해 해당 과정을 진행하였습니다.
따라서  각 위도, 경도 격자 정보에 대하여 `"lat_grid.npy"`, `"lon_grid.npy"` 이름으로 저장하였습니다.

---

## **`slope_data_2.m`**
<aside>
👩🏼

앞서 파이썬으로 수집한 각 위도, 경도 격자 정보 `"lat_grid.npy"`, `"lon_grid.npy"` 파일을 MATLAB에서 사용하기 위해  `.mat` 파일로 합쳐 저장해두었습니다. 

그리고 해당 파일을 불러와  `slope` 값을 기반으로 각 격자마다 평균 경사도(mean slope)를 계산하는 작업을 진행했습니다.

다만 데이터 수집 시간을 줄이기 위해서 지형 데이터가 일반적으로 해양 영역이 `NoData`로 처리하는 것을 파악해 육지에 해당하는 격자만 데이터를 수집하고자 하였습니다.

앞서 수집했던 `SPEI` 데이터의 특성을 사용하여 지형 데이터를 추출하고자 하였고 해당 특성은 이와 같습니다.

- `SPEI` 데이터(`korea_spei06_recent_avg_all.csv`)는 **육지 격자만 유효값**, 바다는 `NaN`
- 따라서 `slope_by_grid` 계산 시:
    - 해당 격자의 `SPEI`가 `NaN`이면 → **경사도도 `NaN` 처리 후 skip**
</aside>

따라서 이 코드는 **한반도 1km 격자 기반의 평균 지형 경사도**(`mean_slope`)를 계산하여 각 격자별로 저장하는 MATLAB 스크립트입니다. 특히 **육지 격자만 대상으로 처리**하며, 장시간 연산에 대비해 **체크포인트 기능과 주기적 저장 기능**을 포함합니다.

### 📁 데이터 구성

### 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `latlon_grids.mat` | 전체 지역의 위도(lat) / 경도(lon) 매트릭스 |
| `Slope_All.tif` | 전체 경사도 지형 데이터 (GeoTIFF 형식) |
| `korea_grids_0.01deg.csv` | 한반도 격자 정보 (위/경도 경계 포함) |
| `korea_spei06_recent_avg_all.csv` | SPEI 기반 육지 여부 판단용 데이터 (`spei_recent_avg` 사용) |

## ⚙️ 실행 흐름

### 1. 데이터 불러오기

- 위도/경도 그리드 및 GeoTIFF 형식의 경사도 데이터(`Z`)를 불러옵니다.
- 전체 격자 정보와 육지 마스크로 사용할 SPEI 데이터를 로드합니다.

### 2. 육지 격자 필터링

- `spei_recent_avg` 값이 `NaN`이 아닌 경우를 육지로 간주하여 `is_land` 벡터 생성
- 이를 기준으로 `grid_id`를 필터링하여 육지 격자만 선별합니다.

### 3. 설정값 정의

- `saveStep`: 주기적으로 중간 결과를 저장할 간격 (기본 5,000개 단위)
- `checkpoint.mat`: 중간 상태 저장 파일 (이전 중단 지점부터 이어서 실행 가능)
- 결과 저장용 `meanSlope` 배열 초기화

### 4. 체크포인트 불러오기 (재실행 지원)

- 이전에 중단된 계산이 있다면 `checkpoint.mat`에서 상태를 불러와 이어서 실행합니다.
- 없으면 새로 시작합니다.

### 5. 평균 경사도 계산 (Main Loop)

- 각 육지 격자에 대해:
    - 격자의 위/경도 범위 내에 포함되는 경사도 값을 추출
    - NaN을 제외한 값들의 평균을 `meanSlope[i]`에 저장
- 100개 단위로 진행률을 출력하고, `saveStep` 단위로 중간 결과를 CSV 파일로 저장합니다.
- `checkpoint.mat`도 함께 저장하여 중단 시 이어서 실행 가능

### 6. 최종 결과 저장 및 마무리

- 전체 결과를 `slope_by_grid.csv`로 저장
- 중간 상태 파일 `checkpoint.mat`는 최종 완료 후 삭제됩니다.

---

### 💾 출력 결과

| 파일명 | 설명 |
| --- | --- |
| `slope_by_grid.csv` | 전체 육지 격자에 대한 평균 경사도 결과 |
| `slope_partial_XXXX.csv` | 중간 저장된 경사도 결과 (XXXX는 index 수) |
| `checkpoint.mat` | 계산 중단 시 재실행을 위한 체크포인트 (최종 저장 후 삭제됨) |

### ✅ 최종 데이터 구조

| grid_id | lat_min | lat_max | lon_min | lon_max | mean_slope |
| --- | --- | --- | --- | --- | --- |
| 1 | 33.00 | 33.01 | 126.00 | 126.01 | 4.21 |
| ... | ... | ... | ... | ... | ... |

---

## **`slope_data_3.m` - Grid-Slope Merge Script**

이 스크립트는 한반도 0.01° 간격의 격자 정보(`korea_grids_0.01deg.csv`)에 각 격자의 평균 경사도(`mean_slope`)를 병합하여 새로운 파일(`korea_grids_with_slope.csv`)로 저장합니다.

---

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `korea_grids_0.01deg.csv` | 전체 기준 격자 정보 (위도, 경도 경계 포함) |
| `slope_by_grid.csv` | 격자별 평균 경사도 (`grid_id`, `mean_slope`) |

## ⚙️ 실행 흐름

### 1. 두 파일 불러오기

- 기준이 되는 격자 정보와, 해당 격자에 대한 평균 경사도 값을 저장한 두 개의 CSV 파일을 불러옵니다.

### 2. `grid_id`를 기준으로 병합

- 두 파일을 `grid_id` 기준으로 병합합니다.
- 모든 기준 격자 정보는 유지되며, 경사도 값이 존재하는 경우 해당 값이 병합되어 포함됩니다.
- 경사도 정보가 존재하지 않는 격자의 경우, `mean_slope` 값은 `NaN`으로 표시됩니다.

### 3. 병합 결과 저장

- 병합된 결과는 `korea_grids_with_slope.csv` 파일로 저장되며, 각 격자의 위·경도 경계와 평균 경사도 값이 함께 포함됩니다.

### 💾 출력 파일

| 파일명 | 설명 |
| --- | --- |
| `korea_grids_with_slope.csv` | 기준 격자 정보에 평균 경사도가 병합된 최종 결과 파일 |

---
## **`slope_data_4.m` - 평균 경사도 시각화 스크립트**

이 스크립트는 `korea_grids_with_slope.csv` 파일을 기반으로 **한반도 육지 격자별 평균 지형 경사도**를 색상 단계별로 시각화하는 MATLAB 코드입니다.

---

### 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `korea_grids_with_slope.csv` | 기준 격자 정보 + 평균 경사도(`mean_slope`)가 포함된 병합 파일 |

### ✅ 시각화 그래프
<img width="1068" height="1026" alt="image (46)" src="https://github.com/user-attachments/assets/1f6afc2f-5e19-411b-8a20-5e45ce96a58b" />

