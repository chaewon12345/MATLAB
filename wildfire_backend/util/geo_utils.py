from math import radians, cos, sin, asin, sqrt

# 위도·경도 간 거리 계산 함수 (Haversine 공식)
def haversine(lat1, lon1, lat2, lon2):
    # 지구 반지름 (단위: km)
    R = 6371.0
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])

    dlat = lat2 - lat1
    dlon = lon2 - lon1

    a = sin(dlat / 2)**2 + cos(lat1) * cos(lat2) * sin(dlon / 2)**2
    c = 2 * asin(sqrt(a))

    return R * c
