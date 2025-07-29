########우리나라를 위도 경도 0.01도씩 격자로 나누는 코드(위도 경도가 파일에 저장됨)########

import pandas as pd

lat_min, lat_max = 33.0, 38.5
lon_min, lon_max = 124.5, 130.5
res = 0.01

grid_data = []
gid = 0

for i in range(int((lat_max - lat_min) / res)):
    for j in range(int((lon_max - lon_min) / res)):
        lat1 = lat_min + i * res
        lat2 = lat1 + res
        lon1 = lon_min + j * res
        lon2 = lon1 + res
        grid_data.append({
            "grid_id": gid,
            "lat_min": round(lat1, 4),
            "lat_max": round(lat2, 4),
            "lon_min": round(lon1, 4),
            "lon_max": round(lon2, 4),
            "center_lat": round((lat1 + lat2) / 2, 4),
            "center_lon": round((lon1 + lon2) / 2, 4),
        })
        gid += 1

df = pd.DataFrame(grid_data)
df.to_csv("korea_grids_0.01deg.csv", index=False)
