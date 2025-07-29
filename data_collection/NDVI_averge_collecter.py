#######NDVI 데이터를 설정한 격자에서의 평균값으로 저장하는 코드#######
import pandas as pd
import rasterio
import numpy as np

# 파일 경로
grid_csv = "korea_grids_0.01deg.csv"
ndvi_tif = "NDVI_LATEST_250m_fixed.tif"

# 격자 불러오기
grid = pd.read_csv(grid_csv)

# NDVI 이미지 열기
with rasterio.open(ndvi_tif) as src:
    ndvi = src.read(1)  # 첫 번째 밴드
    transform = src.transform

    ndvi_avg = []
    for i, row in grid.iterrows():
        lat1 = row['lat_min']
        lat2 = row['lat_max']
        lon1 = row['lon_min']
        lon2 = row['lon_max']

        try:
            # 각 꼭짓점 좌표를 이미지 인덱스로 변환
            col1, row1 = ~transform * (lon1, lat1)
            col2, row2 = ~transform * (lon2, lat2)

            r1 = int(np.floor(min(row1, row2)))
            r2 = int(np.ceil(max(row1, row2)))
            c1 = int(np.floor(min(col1, col2)))
            c2 = int(np.ceil(max(col1, col2)))

            # NDVI 배열 경계 안으로 클리핑
            r1 = max(0, r1)
            r2 = min(ndvi.shape[0]-1, r2)
            c1 = max(0, c1)
            c2 = min(ndvi.shape[1]-1, c2)

            patch = ndvi[r1:r2+1, c1:c2+1]
            valid = patch[patch > 0]

            if len(valid) == 0:
                ndvi_avg.append(None)
            else:
                ndvi_avg.append(np.mean(valid))
        except:
            ndvi_avg.append(None)

# 결과 저장
grid["NDVI"] = ndvi_avg
grid.to_csv("NDVI_processed_average.csv", index=False)
print("✅ 격자별 NDVI 평균 추출 완료")
