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

---
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

---
## SMAP 데이터

SMAP 데이터는 아래 플랫폼에서 수집했습니다. 
[Earthdata Login](https://urs.earthdata.nasa.gov/oauth/authorize?client_id=_JLuwMHxb2xX6NwYTb4dRA&response_type=code&redirect_uri=https%3A%2F%2Fn5eil01u.ecs.nsidc.org%2FOPS%2Fredirect&state=aHR0cHM6Ly9uNWVpbDAxdS5lY3MubnNpZGMub3JnL1NNQVAvU1BMM1NNUC4wMDkvMjAyNS4wNi4zMC8)

📁 해당 플랫폼에서 **전체 SMAP .h5 파일을 직접 다운로드하고 해당 파일에서 한반도 영역만 MATLAB에서 부분 추출**하였습니다.

NASA의 **SMAP L3 SPL3SMP** 데이터는 기본적으로 육지(land surface)의 토양 수분만 포함하고 **해양(바다) 영역은 `NaN` (결측값)** 으로 표시하기 때문에 지형  데이터 수집 과정에서 진행했던 것처럼 spei 데이터의 특성(데이터가 육지에서만 적용)을 활용해  육지 격자만 수집하였습니다.

다만 SMAP 데이터 일부에 아래와 같은 문제가 있었습니다.
<aside>
👩🏼

**원인**

1. **위성 수신 품질 문제**
    - 강수, 눈, 구름, RFI, 지형 등으로 품질 저하 시 NaN 발생
    - `retrieval_qual_flag`가 나쁠 경우 NaN
    - 해안 근처 픽셀도 품질 불안정
2. **SMAP 픽셀 중심과 격자 중심 거리 문제**
    - SMAP 해상도는 약 36km
    - 1km 격자 중 일부는 가까운 SMAP 픽셀이 없어 매핑 실패

---

**✅ 최종 처리 방식**

- **SPEI 값 기준**으로 바다/육지 격자 구분
- **육지 격자만 SMAP 수분값 수집**
- **NaN인 육지 격자**는 **보간(interpolation)** 적용
</aside>

---

## **`SMAP_data_4.m` - SMAP 토양 수분 격자 매핑 및 보간**

이 스크립트는 **SMAP  데이터(HDF5 포맷)**를 한반도 0.01도 격자에 매핑하여, **육지 격자에 수분값을 할당하고, 결측값에 대해 최근접 보간**을 수행한 후 최종 파일로 저장하는 작업을 수행합니다.

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `korea_grids_0.01deg.csv` | 전체 한반도 격자 정보 (`grid_id`, 위·경도 경계 포함) |
| `korea_spei06_recent_avg_all.csv` | 육지 여부 판단을 위한 SPEI 평균값 (`NaN` 여부로 육지 판단) |
| `SMAP_L3_SM_P_20250630_R19240_001.h5` | SMAP 토양 수분 데이터 (.h5 형식) |

## ⚙️ 실행 흐름

### 1. 데이터 불러오기

- 전체 격자 정보(`grid_id`, `lat_min`, `lat_max`, `lon_min`, `lon_max`)와 육지 여부 판단용 SPEI 데이터를 불러옵니다.
- 육지 격자만 추출하기 위해 SPEI 값이 `NaN`이 아닌 격자를 필터링합니다.
- SMAP HDF5 파일에서 위도, 경도, 수분값 데이터를 불러옵니다.

### 2. SMAP 한반도 영역 필터링

- 위도 33~~39도, 경도 124~~132도 범위로 한반도 영역만 선택합니다.
- 선택된 영역의 위·경도 및 수분값(`soil_moisture`)을 별도로 저장합니다.

### 3. SMAP 수분값 격자 매핑

- 각 육지 격자 중심 좌표에 대해 가장 가까운 SMAP 포인트를 찾아 수분값을 할당합니다.
- 이때 유클리드 거리 제곱을 기준으로 최근접 점을 선택합니다.

### 4. 최근접 보간기 생성

- 수분값이 없는 육지 격자에 대해서는 **`scatteredInterpolant` 객체**를 사용하여 최근접 보간법으로 대체값을 생성할 준비를 합니다.
- 보간 대상은 육지 격자 중심 좌표 기준으로 설정합니다.

### 5. 전체 격자에 최종 수분값 생성

- 전체 격자(육지 + 바다)에 대해:
    - 육지인 경우: 수분값이 있으면 그대로 사용, 없으면 보간값 사용
    - 바다인 경우: `NaN` 유지

### 6. 결과 저장

- 최종 수분값(`smap_20250630_filled`)을 `grids` 테이블에 추가한 뒤, `smap_20250630_all_grids_with_interpolated_land.csv`로 저장합니다.

## 💾 출력 파일

| 파일명 | 설명 |
| --- | --- |
| `smap_20250630_all_grids_with_interpolated_land.csv` | 전체 격자에 대해 보간 포함 최종 SMAP 수분값 추가된 결과 파일 (`smap_20250630_filled`) |

---

## **`SMAP_data_5.m` - SMAP 토양 수분 시각화**

이 스크립트는 `smap_20250630_all_grids_with_interpolated_land.csv` 파일을 사용하여, **육지 격자의 수분값을 한반도 지도 위에 색상 점 형태로 시각화**합니다. 보간 포함 수분값(`smap_20250630_filled`)을 바탕으로, 지리적 공간 해석을 위한 시각적 자료를 생성합니다.

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `smap_20250630_all_grids_with_interpolated_land.csv` | 전체 격자에 대해 보간 포함 SMAP 수분값이 포함된 결과 파일 (`center_lat`, `center_lon`, `smap_20250630_filled`) |

### ✅ 시각화 그래프
<img width="1610" height="986" alt="image (49)" src="https://github.com/user-attachments/assets/1a59b581-c1ab-40c2-8724-de14e035d582" />

---

# 기상 데이터

기상 데이터는 아래 플랫폼에서 수집하였습니다.
[ERA5 hourly data on single levels from 1940 to present](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=overview)

📁 위의 링크에서2025년 6월 26일 하루치의 시간대별(0:00 ~ 24:00) 기상 지표 5개를 NetCDF 데이터 파일로 수동 다운로드하였습니다.

---

## **`weather_data_3.py` - ERA5 기반 기상 변수 격자 추출**

**(2025년 6월 30일 기준)**

이 스크립트는 ECMWF ERA5 재분석 데이터를 활용하여, **한반도 0.01도 격자 중심 좌표 기준으로 주요 기상 요소(기온, 습도, 바람, 강수량)**를 추출하여 저장합니다. 각 격자마다 가장 가까운 ERA5 지점의 값을 선택하며, 하루치 데이터를 평균 또는 누적 방식으로 계산합니다.

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `korea_grids_0.01deg.csv` | 격자 중심 좌표 및 grid_id 포함한 기준 격자 정보 |
| `data_stream-oper_stepType-instant.nc` | ERA5 순간값 데이터 (기온, 이슬점, 바람 등) |
| `data_stream-oper_stepType-accum.nc` | ERA5 누적값 데이터 (강수량) |

## ⚙️ 실행 흐름

### 1. 격자 정보 불러오기

- 기준 격자 CSV에서 각 셀의 중심 위도(`center_lat`) 및 경도(`center_lon`)와 `grid_id`를 읽어옵니다.

### 2. ERA5 NetCDF 파일 불러오기

- `instant.nc` 파일에서 기온(`t2m`), 이슬점(`d2m`), 10m 바람(`u10`, `v10`)을 불러옵니다.
- `accum.nc` 파일에서 누적 강수량(`tp`)을 불러옵니다.
- 단위 변환:
    - 기온: K → °C
    - 강수량: m → mm

### 3. 파생 변수 계산

- 풍속(`wind_speed`)과 풍향(`wind_deg`)을 계산합니다.
- 기온과 이슬점 온도를 활용해 상대습도(`rh`)를 계산합니다 (Tetens 공식 기반).

### 4. 시간 평균 및 누적

- 하루치 데이터를 시간 축(`valid_time`) 기준으로 평균(`mean`) 또는 합계(`sum`)로 집계합니다.
    - 예: 기온, 풍속, 습도 → 평균값
    - 강수량 → 누적값

### 5. 최근접 좌표 추출

- 각 격자 중심 좌표에 대해 ERA5 데이터의 최근접 격자값을 추출합니다.
- 변수별로 `extract_nearest()` 함수로 최근접 `latitude`, `longitude`의 값을 가져옵니다.

### 6. 결과 저장

- 각 격자에 대해 추출된 기상 요소를 하나의 테이블로 정리합니다.
- `weather_by_grid_20250630.csv` 파일로 저장합니다.

## 💾 출력 파일

| 파일명 | 설명 |
| --- | --- |
| `weather_by_grid_20250630.csv` | 각 `grid_id`에 대해 추출된 5개 기상 변수 포함 (`temp_C`, `humidity`, `wind_speed`, `wind_deg`, `precip_mm`) |

---

## **`weather_data_3.m` - ERA5 기상 변수 시각화**

이 스크립트는 `weather_by_grid_20250624.csv`의 ERA5 기반 기상 요소를 **한반도 육지 격자 중심 좌표**에 매핑하여 지도 위에 시각화합니다. 5가지 변수(기온, 상대습도, 풍속, 풍향, 강수량)에 대해 **색상 점 시각화(scatter map)**를 제공합니다.

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `korea_grids_0.01deg.csv` | 격자 중심 좌표 및 grid_id 포함 기준 격자 정보 |
| `weather_by_grid_20250624.csv` | 각 격자의 ERA5 기반 기상 변수 (기온, 습도, 바람, 강수량 등) |

### ✅ 시각화 그래프

1️⃣ 기온
<img width="1118" height="1040" alt="image (50)" src="https://github.com/user-attachments/assets/825910ac-59ea-4270-9268-0d4aba19df25" />

2️⃣ 습도
<img width="1096" height="1042" alt="image (51)" src="https://github.com/user-attachments/assets/f1be206a-9745-4dd8-9bd8-4acc07224a36" />

3️⃣ 풍속
<img width="1072" height="1022" alt="image (52)" src="https://github.com/user-attachments/assets/7a32d2b2-aaf7-471b-a33b-e1dbca651ad3" />

4️⃣ 풍향
<img width="1116" height="1038" alt="image (53)" src="https://github.com/user-attachments/assets/2a8f7da2-602f-4921-a072-e4990cfdca32" />

5️⃣ 강수량
<img width="1120" height="1022" alt="image (54)" src="https://github.com/user-attachments/assets/b20a91b1-6954-4237-b1c5-4c94226185e8" />

---

# CFIS 기반 시뮬레이션 정답 데이터 수집

> MATLAB에서 **총 33만 개 격자**에 대해 **CFIS 기반 시뮬레이션을 100회 수행**해 각 셀의 **발화확률 Pignite** 및 **확산확률 Pspread**를 계산하고 **중간 자동 저장과 체크포인트 기능을 포함한 스크립트**
> 
> 
> 를 구현하였습니다.
> 

### ✅ 전체 시뮬레이션 개요 구조

| 단계 | 설명 |
| --- | --- |
| ① 입력 불러오기 | 격자별 기상·지형·식생 등 지표 (`input_data_set.csv`) |
| ② 발화확률 계산 | 각 셀의 Pignite 계산 |
| ③ 시뮬레이션 N회 반복 | 각 격자마다 CFIS 모델 기반 확산 진행 |
| ④ 결과 누적 | 셀별 번짐 횟수 누적 (spread_count) |
| ⑤ 확산확률 계산 | Pspread=번진횟수/ N |
| ⑥ 자동 저장 | 1만 개 단위 저장, checkpoint 기능 포함 |

### ✅ 발화확률, 확산 확률 계산 공식

> CFIS에서 **발화확률(Pₐₙᵢₜₑ)** 와 **확산확률(Pₛₚᵣₑₐ𝒹)** 은 확정된 고정 공식이 없습니다.
> 

→  이에 실제 논문과 시뮬레이션 연구에서 자주 쓰이는 **간단하면서도 대표적인 공식 형태을 채택해 적용했습니다.**
<aside>
⚙

1. **발화 확률 Pignite** : 단순화된 sigmoid 회귀식

<img width="1134" height="110" alt="image (55)" src="https://github.com/user-attachments/assets/52834c88-bf1d-44aa-9ff3-25e200eaa608" />

| 변수 | 의미 |
| --- | --- |
| NDVI | 식생량 (많을수록 발화↑) |
| SPEI | 가뭄 정도 (건조할수록 발화↑) |
| T | 기온 (높을수록 발화↑) |
| SMAP | 토양 수분 (많을수록 발화↓) |
| H | 상대 습도 |
| P | 강수량 |

2. **확산 확률 Pspread** : 방향성 없이 간단히 가중합 형태

<img width="666" height="118" alt="image (56)" src="https://github.com/user-attachments/assets/f54c2b39-8209-4765-a135-7faefc664abd" />

| 변수 | 의미 | 정규화 기준 |
| --- | --- | --- |
| 풍속 | 셀의 풍속 (m/s) | Vmax=10 (예시) |
| 경사도 | 셀의 경사 (%) | Smax=45 (예시) |
| F | 연료 인자 (0~1 범위로 정규화된 값) | 직접 정규화 필요 |
| α\alpha | 스케일 조정 상수 (ex. 0.8~1.2) | 전체 확산 강도 조절 |
</aside>
---

### ✅ 최종 저장되는 `Pspread`와 `Pignite` 의미

### 🔹 `Pignite` (발화 확률) → 실제 모델 학습에는 사용하지 않음

- **시뮬레이션과 무관하게 처음부터 계산된 정적인 값**
- 즉, 입력 지표 기반으로 계산된 **각 격자의 발화 확률**
- `N_SIM = 300` 반복과는 **무관하게 한 번만 계산**되어 저장

### 🔹 `Pspread` (확산 확률)

- 시뮬레이션을 3**00번 반복한 후**, 실제로 **해당 셀이 몇 번 번졌는지에 대한 비율**

---

### ✅ 시뮬레이션 구성 코드 (MATLAB)

<aside>
🗒️

### 파일 구성 (3개)

1. `cfis_simulation.m`
    
    → 저장된 이웃 정보 불러와 CFIS 시뮬레이션 실행
    
2. `getNeighbors.m`
    
    →중심 위경도 기반 2km 이내 이웃 추출 함수
    
3. `generate_neighbors_cache.m`
    
    → 육지 격자에 대해 이웃 계산 → 중간 저장 포함
    
4. `NDVI_land_only.csv`, `input_data_set.csv`
    
    → 입력 데이터
    
</aside>

<aside>
🛠

### 사용 순서

1. `generate_neighbors_cache.m` 실행 → `neighbors_cache_land.mat` 생성됨
2. `cfis_land_simulation_per_cell_3.m` 실행 → `cfis_land_result_percell_6.csv` 출력됨
</aside>

---
## `generate_neighbors_cache.m` - 육지 격자 이웃 계산 및 캐싱

이 스크립트는 한반도 **육지 격자에 대해 인접 격자(이웃)를 계산**하고, 중간 저장 및 체크포인트 기능을 통해 **대규모 처리에서도 안정적으로 재시작이 가능**하도록 구성되어 있습니다. 진행률 바가 포함되어 있어 대규모 실행 시 처리 상황을 실시간으로 확인할 수 있습니다.

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `NDVI_land_only.csv` | 육지로 판단된 격자 ID 목록 (`grid_id`) |
| `input_data_set.csv` | 전체 격자 정보 (`grid_id`, `center_lat`, `center_lon`) 포함 |

## ⚙️ 실행 흐름

### 1. 육지 격자 필터링

- `NDVI_land_only.csv` 파일에서 육지 격자 ID만 추출
- `input_data_set.csv`에서 `grid_id` 기준으로 육지 격자만 필터링

### 2. 중간 캐시(체크포인트) 불러오기

- 이전 실행 시 저장된 `neighbors_10000.mat`, `neighbors_20000.mat` 등 중간 블록 파일이 존재할 경우, 해당 블록의 결과를 메모리에 불러오고 이어서 계산을 재개함

### 3. 이웃 계산 시작

- 각 격자에 대해 사용자 정의 함수 `getNeighbors(i, lat, lon)`을 호출하여 이웃 격자 리스트를 생성
    
    (일반적으로 거리 기반 또는 인접 위경도 기반 계산)
    

### 4. 진행률 바 표시

- 40칸의 ASCII 진행 바를 활용하여 현재 진행률(%)과 계산 중인 격자 개수를 실시간으로 출력

### 5. 주기적 저장

- `BLOCK_SIZE = 10000` 단위로 계산이 완료될 때마다 `neighbors_XXXX.mat` 형식으로 중간 결과 저장
- 저장된 파일에는 `block_neighbors` 리스트가 포함되며, 다음 실행 시 체크포인트로 활용 가능

### 6. 전체 결과 저장

- 전체 계산 완료 후, 전체 이웃 정보(`neighbors`)를 `neighbors_cache_land.mat`에 최종 저장

## 💾 출력 파일

| 파일명 | 설명 |
| --- | --- |
| `neighbors_10000.mat`, `neighbors_20000.mat`, ... | 각 블록 단위로 계산된 이웃 정보 중간 저장 파일 |
| `neighbors_cache_land.mat` | 전체 육지 격자에 대한 이웃 정보가 포함된 최종 캐시 파일 |

---

## `getNeighbors.m`

(Haversine 거리 기반 이웃 격자 탐색)

`getNeighbors`  함수는 **특정 격자(`idx`)를 기준으로 반경 2km 이내에 있는 이웃 격자의 인덱스를 반환**합니다. 지구 곡률을 고려한 **Haversine 공식을 사용**하여 위경도 기반 거리 계산을 수행합니다.

## 📥 입력 인자

| 인자명 | 설명 |
| --- | --- |
| `idx` | 기준이 되는 격자의 인덱스 (1부터 시작하는 정수) |
| `center_lat` | 모든 격자의 중심 위도 배열 (벡터) |
| `center_lon` | 모든 격자의 중심 경도 배열 (벡터) |

## 📤 출력 값

| 이름 | 설명 |
| --- | --- |
| `neighbors` | 기준 격자 `idx`로부터 2.0km 이내에 존재하는 **이웃 격자의 인덱스 배열** (자기 자신 제외) |

## 계산 방식

- **Haversine 공식**을 사용해 격자 간 거리 계산 (단위: km)
- 기준 격자와 모든 다른 격자 간의 거리 계산
- 거리 `d ≤ 2.0km`인 격자의 인덱스를 `neighbors` 배열에 추가

## 🌐 Haversine 공식 요약

```
d = 2R * asin( sqrt( sin²(Δφ/2) + cos(φ₁)·cos(φ₂)·sin²(Δλ/2) ) )
```

| 기호 | 설명 |
| --- | --- |
| `R` | 지구 반지름 (6371 km) |
| `φ` | 위도 (라디안) |
| `λ` | 경도 (라디안) |
| `Δφ` | 위도 차 |
| `Δλ` | 경도 차 |

---

## `cfis_simulation.m` - CFIS 산불 확산 시뮬레이션

**(이웃 캐시 + 진행률 표시 + 중간 저장 포함)**

이 스크립트는 CFIS(Cellular Fire Ignition and Spread) 모델을 기반으로, 한반도 육지 격자에 대해 **산불 발생 및 확산 시뮬레이션을 N회 반복**하고, 격자별 확산 확률(`Pspread`)을 계산하여 저장합니다.

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `input_data_set.csv` | 격자별 기상·환경 입력 변수 포함 |
| `NDVI_land_only.csv` | 육지로 판단된 격자의 ID 목록 (`grid_id`) |
| `neighbors_cache_land.mat` | 각 육지 격자별 이웃 인덱스 리스트 캐시 파일 |

## ⚙️ 실행 흐름

### 1. 입력 데이터 불러오기

- 전체 격자 중 **육지 격자만 필터링**하여 시뮬레이션 대상 설정
- 육지 격자의 수(`nGrids`)를 기준으로 시뮬레이션 반복

### 2. 발화 확률(`Pignite`) 계산

- 다양한 기상·지형 변수 기반 로지스틱 회귀 형태로 계산
- 사용 변수: `NDVI`, `spei_recent_avg`, `temp_C`, `smap_20250630_filled`, `humidity`, `precip_mm`

### 3. 확산 확률(`Pspread`) 계산

- 단순 가중 평균으로 계산
    
    `Pspread = α × (0.4 × 풍속정규화 + 0.4 × 경사정규화 + 0.2 × 연료량정규화)`
    

### 4. 이웃 캐시 불러오기

- `neighbors_cache_land.mat`에서 각 격자별 인접 격자 리스트(`neighbors{i}`) 불러오기

### 5. 시뮬레이션 반복 (N회)

- 격자별 발화 여부 무작위 결정
- 불이 난 격자에서 이웃 격자에 `Pspread(i)` 확률로 전이
- `burned` 배열에 확산 여부 저장 → 누적 횟수 `spread_count`에 기록

### 6. 진행률 표시 및 중간 저장

- 매 시뮬레이션마다 ASCII 진행률 바 및 평균 확산률 출력
- `sim % 10 == 0`일 때 체크포인트 저장(`cfis_land_checkpoint.mat`) 및 중간 결과 CSV 저장(`cfis_land_XXXX.csv`)

### 7. 최종 결과 저장

- 전체 시뮬레이션 종료 후 `cfis_land_result.csv`에 저장
- 저장 항목:
    - `grid_id`
    - `Pignite`: 발화 확률
    - `BurnedCount`: 불이 붙은 횟수
    - `SimTotal`: 시뮬레이션 총 횟수
    - `Pspread`: `BurnedCount / SimTotal` (확산 확률)

## 💾 출력 파일

| 파일명 | 설명 |
| --- | --- |
| `cfis_land_result.csv` | 전체 육지 격자의 발화 및 확산 확률 결과 |
| `cfis_land_XXXX.csv` | N시뮬레이션마다 저장되는 중간 결과 (10회 단위) |
| `cfis_land_checkpoint.mat` | 중간 저장 체크포인트 파일 (강제 종료 대비) |

---

## 정답 데이터 분할 과정

## **`final_data_1.m` - CFIS 시뮬레이션 결과 + 위치 정보 병합**

**(위경도 정보 포함 최종 결과 생성)**

이 스크립트는 CFIS 산불 시뮬레이션 결과(`cfis_land_result_percell_6.csv`)에 **각 격자의 위경도 정보**를 병합하여 최종적으로 공간 기반 분석에 활용 가능한 결과 파일을 생성합니다.

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `only_land_grid.csv` | 육지로 간주되는 격자의 `grid_id` 목록 |
| `cfis_land_result_percell_6.csv` | CFIS 시뮬레이션 결과 (격자별 발화/확산 확률 등 포함) |
| `input_data_set.csv` | 격자별 지리정보 및 전체 입력 지표 포함 원본 파일 |

## ⚙️ 실행 흐름

### 1. 데이터 불러오기

- 세 개의 주요 데이터 파일(`land`, `cfis`, `input`)을 `readtable`로 불러옵니다.

### 2. 육지 격자 필터링

- CFIS 결과에서 육지로 간주되는 격자(`grid_id`)만 필터링하여 `cfis_land` 생성

### 3. 위치 정보 추출

- `input_data_set.csv`에서 다음 위치 관련 열만 추출:
    - `lat_min`, `lat_max`, `lon_min`, `lon_max`, `center_lat`, `center_lon`

### 4. 병합 수행

- `grid_id`를 기준으로 `cfis_land`와 위치 정보(`input_coords`)를 병합
- 병합 방식은 Left Join(`Type = 'left'`)으로, CFIS 결과 기준으로 위치 정보 매핑

### 5. 열 순서 정리

- 최종 결과 파일에서 `grid_id` 바로 다음에 위치 정보 6개 열을 배치
- 나머지 열은 기존 순서를 유지한 채 뒤에 위치시킴

### 6. 결과 저장

- 병합 및 열 정렬이 완료된 최종 테이블을 `cfis_land_result_percell_6_with_coords.csv`로 저장

## 💾 출력 파일

| 파일명 | 설명 |
| --- | --- |
| `cfis_land_result_percell_6_with_coords.csv` | CFIS 결과 + 격자 위치 정보가 포함된 최종 분석용 파일 |

---

## **`final_data_2.m` - CFIS 시뮬레이션 데이터 분할**

**(학습/테스트용 7:3 비율로 CSV 저장)**

이 스크립트는 CFIS 기반 산불 확산 결과 데이터(`cfis_land_result_percell_6_with_coords.csv`)를 **머신러닝 학습을 위한 입력으로 사용하기 위해 전처리 및 분할**하는 과정을 수행합니다.

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `cfis_land_result_percell_6_with_coords.csv` | 각 격자의 CFIS 시뮬레이션 결과 + 위치 정보 포함된 최종 데이터 |

## ⚙️ 실행 흐름

### 1. 데이터 불러오기

- 전체 CFIS 결과 데이터를 `readtable`로 불러옵니다.

### 2. NaN 처리

- `Pignite` 열에서 NaN 값은 발화 가능성 없음으로 간주하여 **0으로 대체**합니다.
- `Pspread` 열에 존재하는 NaN의 개수를 출력하여 이상치 여부를 확인합니다.

### 3. 무작위 섞기 (Shuffle)

- 데이터 분할의 편향을 방지하기 위해 **seed 고정 후 랜덤 셔플링**을 수행합니다 (`rng(42)`).

### 4. 7:3 비율로 데이터 분할

- 전체 데이터를 70% 학습용, 30% 테스트용으로 인덱스 기반 분할합니다.

### 5. 결과 저장

- 학습 데이터는 `cfis_train_label.csv`로, 테스트 데이터는 `cfis_test_label.csv`로 저장합니다.
- 저장된 두 파일은 이후 머신러닝 모델 학습/검증에 사용됩니다.

## 💾 출력 파일

| 파일명 | 설명 |
| --- | --- |
| `cfis_train_label.csv` | 전체의 70%로 구성된 학습용 데이터 |
| `cfis_test_label.csv` | 전체의 30%로 구성된 테스트용 데이터 |

---

# Random_forest 모델 기반 학습 과정

> 🎯 목표:
> 
- 입력: 7가지 지표 +  FARSITE 방향성 데이터(8방향) = 총 21개 피처
- 출력: `pSpread` (연속값, 회귀 문제)
- 파일: `farsite_train_label.csv`, `cfis_train_label.csv`
    
    
    | 파일명 | 내용 |
    | --- | --- |
    | `farsite_train_label.csv` | 👉 **입력 피처 21개** 포함 (8개 FARSITE 방향 + 13개 지표 추정) |
    | `cfis_train_label.csv` | 👉 **정답 값 (`pSpread`) 포함** |
- 진행률 출력
- 모델 저장
- 트리 갯수는 일단 300개로 진행하고 성능을 확인해가며 조절하였습니다.

---

## **`model_train.m` - Random Forest 기반 Pspread 예측 모델 학습**

**(21개 입력 지표 기반, 300 트리 구성)**

이 스크립트는 CFIS 시뮬레이션 결과를 정답(label)으로 사용하고, FARSITE 기반의 21개 환경·기상 지표를 입력 피처로 활용하여 **Random Forest 회귀 모델을 학습**합니다. 학습이 완료되면 모델과 `grid_id` 매핑 정보를 함께 저장합니다.

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `farsite_train_label.csv` | 격자별 21개 입력 지표 포함 학습용 피처 데이터 |
| `cfis_train_label.csv` | CFIS 기반 확산 확률(`Pspread`)이 포함된 정답 데이터 |

### 🔹 1. 데이터 불러오기

- 입력 피처(`X_raw`)와 정답 벡터(`Y`)를 각각의 CSV 파일에서 불러옵니다.
- `cfis_train_label.csv`에 `Pspread` 열이 존재하는지 검증하고 없으면 오류를 발생시킵니다.

### 🔹 2. 입력 피처 구성

- 예측 대상인 `grid_id`, `lat_min`, `lat_max`, `center_lat` 등 **공간 좌표 관련 열은 제거**
- 최종적으로 **21개 지표만 추출**하여 `X`로 저장
- 향후 결과 매핑을 위해 `grid_id`는 별도 저장

### 🔹 3. 모델 학습 설정

- **Random Forest 회귀 모델(TreeBagger)** 사용
- 트리 수는 기본 300개(`nTrees = 300`)
- **OOB(Out-Of-Bag) 예측과 변수 중요도 측정 기능** 활성화
- 병렬 연산은 비활성화(`UseParallel = false`)

### 🔹 4. 모델 학습 수행

- `TreeBagger`를 통해 회귀 모델 학습
- 진행 중 10개 단위로 학습 상황을 출력
- 학습 시간 측정을 위해 `tic`/`toc` 사용

### 🔹 5. 모델 저장

- 학습 완료 후 타임스탬프 기반의 고유 이름으로 `.mat` 파일로 저장
- 모델(`Mdl`)과 함께 `grid_ids`도 저장하여 추후 결과 매핑에 활용 가능

## 💾 출력 파일

| 파일명 예시 | 설명 |
| --- | --- |
| `random_forest_pspread_model_300trees_YYYYMMDD_HHMMSS.mat` | 학습된 모델과 grid_id 정보가 저장된 결과 파일 |

---

## **`moder_test_1.m` - CFIS Pspread 예측 모델 성능 평가 및 시각화**

**(Random Forest 기반 모델 결과 확인 및 중요 변수 분석)**

이 스크립트는 학습된 **Random Forest 회귀 모델**을 불러와 테스트 데이터를 예측한 후, 예측 결과를 **지도에 시각화**하고, **RMSE/MAE 등의 정량적 지표**, 그리고 **변수 중요도(Feature Importance)** 분석을 수행합니다.

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `random_forest_pspread_model_*.mat` | 학습 완료된 Random Forest 모델 (`Mdl`)과 grid_id 저장된 `.mat` 파일 |
| `farsite_test_label.csv` | 테스트용 입력 피처 (21개 지표 + 위치 정보 포함) |
| `cfis_test_label.csv` | 테스트용 정답 확산 확률(`Pspread`) 벡터 |

## ⚙️ 실행 흐름

### 1. 모델 및 테스트 데이터 불러오기

- `.mat` 파일로 저장된 모델(`Mdl`)을 로드
- 테스트 데이터의 `grid_id`, 중심 위경도(`center_lat`, `center_lon`) 저장
- 학습 제외 대상(`grid_id`, 위치 정보 등)을 제거하고 **21개 입력 피처만 추출**

### 2. 예측 및 성능 평가

- `predict()` 함수로 예측 수행 → `Y_pred`
- 정답(`Y_true`)과 비교하여 성능 지표 계산:
    - **RMSE (Root Mean Squared Error)**
    - **MAE (Mean Absolute Error)**

### 📍모델 성능 평가 결과

```matlab
[RESULT] RMSE: 0.0947
[RESULT] MAE : 0.0225
```
### ▶️ 이 수치가 의미하는 바

| 지표 | 값 | 해석 |
| --- | --- | --- |
| **RMSE** | 0.0947 | 평균적으로 약 **±0.095** 정도 예측 오차가 발생 |
| **MAE** | 0.0225 | 평균 절대 오차는 약 **2.25%** 수준의 오차를 가짐 |
- `pSpread` 값이 **[0, 1] 범위의 확률 값**이라는 걸 감안하면, **오차 0.0225는 2% 수준의 예측 오차**
- **RMSE 0.095는 모델이 꽤 안정적으로 예측하고 있다는 뜻입니다.**

### 🔹 2.  지도 위 시각화 (예측 vs 정답)
📊 모델 예측 결과값 시각화
<img width="1532" height="1014" alt="image (57)" src="https://github.com/user-attachments/assets/eeef00d0-fa69-4476-a08f-ac2d858c6b8e" />
📊 정답 결과값 시각화
<img width="1534" height="990" alt="image (58)" src="https://github.com/user-attachments/assets/c9ba794a-58bc-466e-b500-0e8601bd8d1b" />

### 🔹 3.  OOB Error 그래프 출력
> 오차가 빠르게 줄고 수렴하면 모델이 잘 학습된 것을 의미합니다.
>
> <img width="1610" height="1022" alt="image (59)" src="https://github.com/user-attachments/assets/c50db0f5-4db3-4acb-8ea0-83fc2d064d73" />

### ▶️ OOB Error 그래프 해석

<aside>

### 🔍 그래프 특징

- **초반 0~50개 트리 사이에 급격한 감소**
    
    → 모델이 빠르게 학습하면서 예측력을 키우고 있다는 뜻입니다.
    
- **이후 100개 트리 이후에는 거의 평평하게 수렴**
    
    → 성능이 안정화되고 더 많은 트리를 추가해도 성능 향상이 미미합니다.
    

---

### ✅ 결론

> 트리 수 300개는 충분히 안정적인 상태이고  트리 수를 더 늘려도 오차 감소 효과는 거의 없기 때문에 300개는 적절한 설정 갯수였습니다.
> 
</aside>

---
학습시킨 Random Forest 기반 Pspread 예측 모델의 성능이 위의 평가처럼 안정적이기 때문에 학습 모델을 통한 격자별 산불 전이 예측 결과 출력 코드를 최종적으로 구현하였습니다.

## **`model_result.m` - Pspread 예측 결과 생성**

**(위경도 포함 예측 CSV 생성용)**

이 스크립트는 학습된 **Random Forest 모델을 불러와** 테스트 데이터에 대해 **산불 확산 확률(Pspread)을 예측**하고, 각 격자의 위치 정보와 함께 **결과 테이블을 구성 및 저장**합니다.

## 📁 입력 파일

| 파일명 | 설명 |
| --- | --- |
| `farsite_test_label.csv` | 테스트용 입력 피처 및 격자 위치 정보 포함 |
| `cfis_test_label.csv` *(선택)* | 실제 `Pspread` 값 (성능 평가용 비교 가능) |
| `random_forest_pspread_model_*.mat` | 학습된 Random Forest 모델(`Mdl`)과 `grid_id` 포함된 `.mat` 파일 |

## ⚙️ 실행 흐름

### 1. 테스트 데이터 불러오기

- 격자의 `grid_id`, 위경도(`lat_min`, `lat_max`, `lon_min`, `lon_max`, `center_lat`, `center_lon`) 정보를 포함한 전체 데이터 로드
- 예측에 사용할 **21개 입력 피처만 추출**하여 `X_test`로 구성

### 2. 모델 로드

- 저장된 `.mat` 파일에서 학습된 모델(`Mdl`)을 불러옵니다
    
    *(이미 메모리에 있다면 생략 가능)*
    

### 3. 예측 수행

- `predict(Mdl, X_test)`로 `pSpread_pred` 예측 수행

### 4. 결과 테이블 구성

- 다음 항목을 포함한 테이블을 생성:
    - `grid_id`, `lat_min`, `lat_max`, `lon_min`, `lon_max`
    - `center_lat`, `center_lon`
    - `pSpread_pred` (예측 확산 확률)

### 5. 결과 저장

- 타임스탬프(`yyyymmdd_HHMMSS`)를 포함한 파일명으로 CSV 저장
    
    예: `predicted_pspread_with_coords_20250729_152010.csv`
    

### ✅ 요약: 예측 결과 예시 테이블

| grid_id | lat_min | lat_max | lon_min | lon_max | center_lat | center_lon | pSpread_pred |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 12345 | 37.1 | 37.2 | 127.3 | 127.4 | 37.15 | 127.35 | 0.783 |
| ... | ... | ... | ... | ... | ... | ... | … |
