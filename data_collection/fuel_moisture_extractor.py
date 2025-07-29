import pandas as pd
import numpy as np
import xarray as xr

# 1. 파일 경로 지정
grid_path = "korea_grids_0.01deg.csv"
nc_path = "FWI.GEOS-5.Daily.Default.2025062800.20250701.nc"

# 2. 데이터 로드
grids_df = pd.read_csv(grid_path)
ds = xr.open_dataset(nc_path)

# 3. 필요한 변수 추출
ffmc = ds["GEOS-5_FFMC"].squeeze().values
dmc = ds["GEOS-5_DMC"].squeeze().values
dc = ds["GEOS-5_DC"].squeeze().values
lat_vals = ds["lat"].values
lon_vals = ds["lon"].values

# 4. 격자 기준 최근접 포인트로 매핑
results = []

for _, row in grids_df.iterrows():
    lat_c = row["center_lat"]
    lon_c = row["center_lon"]

    # 위경도 거리 계산 후 최근접 인덱스
    lat_diff = np.abs(lat_vals - lat_c)
    lon_diff = np.abs(lon_vals - lon_c)
    lat_idx = np.argmin(lat_diff)
    lon_idx = np.argmin(lon_diff)

    # 값 추출
    ffmc_val = ffmc[lat_idx, lon_idx]
    dmc_val = dmc[lat_idx, lon_idx]
    dc_val = dc[lat_idx, lon_idx]

    # NaN 있는 경우 그대로 표시
    ffmc_val = round(ffmc_val, 2) if not np.isnan(ffmc_val) else np.nan
    dmc_val = round(dmc_val, 2) if not np.isnan(dmc_val) else np.nan
    dc_val  = round(dc_val, 2)  if not np.isnan(dc_val)  else np.nan

    results.append({
        "grid_id": row["grid_id"],
        "min_lat": row["lat_min"],
        "max_lat": row["lat_max"],
        "min_lon": row["lon_min"],
        "max_lon": row["lon_max"],
        "FFMC": ffmc_val,
        "DMC": dmc_val,
        "DC": dc_val
    })

# 5. 결과 저장
fuel_df = pd.DataFrame(results)
fuel_df.to_csv("fuel_moisture_nearest.csv", index=False)
print("✅ fuel_moisture_nearest.csv 파일 생성 완료! (NaN 포함)")
