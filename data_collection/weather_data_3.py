import pandas as pd
import xarray as xr
import numpy as np

# ===== 1. 격자 정보 불러오기 =====
grid_df = pd.read_csv('korea_grids_0.01deg.csv')

# ===== 2. ERA5 NetCDF 파일 불러오기 =====
ds_temp = xr.open_dataset('data_stream-oper_stepType-instant.nc')
ds_precip = xr.open_dataset('data_stream-oper_stepType-accum.nc')

# 변수 추출
t2m = ds_temp['t2m'] - 273.15  # 기온: K -> °C
d2m = ds_temp['d2m'] - 273.15  # 이슬점온도: K -> °C
u10 = ds_temp['u10']
v10 = ds_temp['v10']
tp = ds_precip['tp'] * 1000  # 강수량: m -> mm

# 시간 차원 이름 확인
time_dim = 'valid_time'

# ===== 3. 파생 변수 계산 =====
wind_speed = np.sqrt(u10**2 + v10**2)
wind_deg = (180 / np.pi) * np.arctan2(u10, v10) + 180

# 상대습도 계산
rh = 100 * (
    np.exp((17.625 * d2m) / (243.04 + d2m)) /
    np.exp((17.625 * t2m) / (243.04 + t2m))
)

# ===== 4. 시간 평균 또는 누적 =====
mean_temp = t2m.mean(dim=time_dim)
mean_rh = rh.mean(dim=time_dim)
mean_wind_speed = wind_speed.mean(dim=time_dim)
mean_wind_deg = wind_deg.mean(dim=time_dim)
total_precip = tp.sum(dim=time_dim)

# ===== 5. 각 격자 중심 좌표에 대해 최근접 추출 =====
def extract_nearest(lat, lon, data):
    return float(data.sel(latitude=lat, longitude=lon, method='nearest').values)

results = []
for _, row in grid_df.iterrows():
    lat = row['center_lat']
    lon = row['center_lon']
    results.append({
        'grid_id': row['grid_id'],
        'temp_C': extract_nearest(lat, lon, mean_temp),
        'humidity': extract_nearest(lat, lon, mean_rh),
        'wind_speed': extract_nearest(lat, lon, mean_wind_speed),
        'wind_deg': extract_nearest(lat, lon, mean_wind_deg),
        'precip_mm': extract_nearest(lat, lon, total_precip),
    })

# ===== 6. 저장 =====
weather_df = pd.DataFrame(results)
weather_df.to_csv('weather_by_grid_20250630.csv', index=False)
print("✅ 저장 완료: weather_by_grid_20250630.csv")
