#########NDVI 평균 데이터를 시각화하는 코드##########
import pandas as pd
import matplotlib.pyplot as plt
import geopandas as gpd
from shapely.geometry import Point

# 1. CSV 불러오기
df = pd.read_csv("NDVI_processed_average.csv")

# 2. NDVI 정규화 (MODIS 기준 NDVI는 10000으로 나눔)
df["NDVI_norm"] = df["NDVI"] * 0.0001

# 3. NaN 제거
df = df.dropna(subset=["NDVI_norm"])

# 4. 격자 중심 좌표를 Point 객체로 변환
geometry = [Point(xy) for xy in zip(df.center_lon, df.center_lat)]
gdf = gpd.GeoDataFrame(df, geometry=geometry)

# 5. 시각화
fig, ax = plt.subplots(figsize=(10, 12))
gdf.plot(column="NDVI_norm", ax=ax, legend=True, cmap="YlGn", markersize=10)
ax.set_title("NDVI Normalized (격자 중심 시각화)", fontsize=14)
ax.set_xlabel("Longitude")
ax.set_ylabel("Latitude")
plt.grid(True)
plt.tight_layout()
plt.show()
