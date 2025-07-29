import numpy as np
import pandas as pd
import os

# 1. 격자별 8방향 확산 확률 계산
def calculate_farsite_probs(df: pd.DataFrame) -> pd.DataFrame:
    """
    격자별로 8방향(NW~SE)에 대한 확산 확률(P_dir)을 계산하여 DataFrame에 추가.
    누락 데이터가 있는 경우 확산 확률은 None으로 처리하되 원본 행은 유지.
    """
    directions = [(-1, 1), (0, 1), (1, 1), (-1, 0), (1, 0), (-1, -1), (0, -1), (1, -1)]
    dir_labels = ['P_NW', 'P_N', 'P_NE', 'P_W', 'P_E', 'P_SW', 'P_S', 'P_SE']

    sigma = 1.0
    alpha = 0.5
    beta = 0.5
    slope_dir = 135

    result_rows = []

    for _, row in df.iterrows():
        new_row = row.copy()

        if pd.isna(row["wind_deg"]) or pd.isna(row["avg_fuelload_pertree_kg"]):
            print(f"⚠️ 확산 확률 계산 누락: wind_deg={row['wind_deg']}, fuel={row['avg_fuelload_pertree_kg']}")
            for label in dir_labels:
                new_row[label] = None
            result_rows.append(new_row)
            continue

        wind_dir = row["wind_deg"]
        ros = 0.001 * row["avg_fuelload_pertree_kg"]

        P = []
        for dx, dy in directions:
            d_ij = np.sqrt(dx**2 + dy**2)
            theta_ij = np.degrees(np.arctan2(dy, dx))
            if theta_ij < 0:
                theta_ij += 360

            G = alpha * np.cos(np.radians(theta_ij - wind_dir)) + beta * np.cos(np.radians(theta_ij - slope_dir))
            prob = np.exp(-(d_ij**2) / (sigma**2)) * (1 + G) * ros
            P.append(prob)

        P = np.array(P)
        total = P.sum()
        if total == 0 or np.isnan(total):
            P = np.zeros_like(P)
        else:
            P = P / total

        for label, p in zip(dir_labels, P):
            new_row[label] = p

        result_rows.append(new_row)

    return pd.DataFrame(result_rows)


# 2. 평균 확산 확률 기반 가중치 불러오기
def load_correction_weights() -> dict:
    """
    input_data_farsite_Nan.csv에서 방향별 확산 확률 평균을 기반으로 역가중치 계산
    → 각 방향에 대한 정규화된 보정 가중치를 반환
    """
    # 🔹 경로를 내부에서 직접 설정
    base_dir = os.path.dirname(os.path.abspath(__file__))
    data_path = os.path.join(base_dir, '..', 'data', 'input_data_farsite_Nan.csv')

    # 🔹 CSV 읽기
    df = pd.read_csv(data_path)

    # 🔹 방향별 확산 확률 컬럼
    dir_cols = ['P_NW', 'P_N', 'P_NE', 'P_W', 'P_E', 'P_SW', 'P_S', 'P_SE']

    # 🔹 평균 확률 계산
    mean_probs = [df[col].mean(skipna=True) for col in dir_cols]

    # 🔹 역비율 가중치 계산 (0일 경우 0 처리)
    inv_weights = [1 / p if p else 0 for p in mean_probs]

    # 🔹 정규화 (최댓값 기준)
    max_weight = max(inv_weights)
    norm_weights = [w / max_weight for w in inv_weights]

    # 🔹 결과 반환
    return {dir_cols[i]: norm_weights[i] for i in range(8)}

# 3. 확산 확률에 보정 가중치 적용
def apply_directional_correction(df_probs: pd.DataFrame, weights: dict) -> pd.DataFrame:
    """
    보정 가중치를 적용하여 P_dir 열들을 정규화된 확률로 다시 계산
    """
    dir_cols = ['P_NW', 'P_N', 'P_NE', 'P_W', 'P_E', 'P_SW', 'P_S', 'P_SE']
    df_corrected = df_probs.copy()

    for idx, row in df_corrected.iterrows():
        probs = []
        for col in dir_cols:
            val = row[col]
            weight = weights[col]
            probs.append(val * weight if pd.notna(val) else 0.0)  # 🔧 NaN을 0으로 대체

        # 🔹 정규화
        total = np.nansum(probs)
        if total == 0 or np.isnan(total):
            normalized = [0.0] * len(probs)
        else:
            normalized = [p / total for p in probs]

        for i, col in enumerate(dir_cols):
            df_corrected.at[idx, col] = normalized[i]

    return df_corrected

# 4. AI 예측용 JSON 변환
def prepare_ast_input(df: pd.DataFrame) -> list[dict]:
    """
    보정된 확산 확률 DataFrame에서 필요한 21개 항목만 뽑아 JSON 리스트로 구성
    → farsite_prob은 8방향 확산 확률의 평균값
    """
    dir_cols = ['P_NW', 'P_N', 'P_NE', 'P_W', 'P_E', 'P_SW', 'P_S', 'P_SE']

    json_list = []

    for _, row in df.iterrows():
        # 🔧 평균값 계산 시 NaN 제거
        values = [row[dir] for dir in dir_cols if pd.notna(row[dir])]
        farsite_prob = float(np.mean(values)) if values else 0.0  # 🔧 NaN 방지

        # 🔧 모든 값 타입을 명시적으로 float/int로 변환, NaN → None
        grid_data = {
            "grid_id": int(row["grid_id"]),
            "lat_min": float(row["lat_min"]),
            "lat_max": float(row["lat_max"]),
            "lon_min": float(row["lon_min"]),
            "lon_max": float(row["lon_max"]),
            "center_lat": float(row["center_lat"]),
            "center_lon": float(row["center_lon"]),
            "avg_fuelload_pertree_kg": float(row["avg_fuelload_pertree_kg"]),
            "FFMC": float(row["FFMC"]),
            "DMC": float(row["DMC"]),
            "DC": float(row["DC"]),
            "NDVI": float(row["NDVI"]),
            "smap_20250630_filled": float(row["smap_20250630_filled"]),
            "temp_C": float(row["temp_C"]) if pd.notna(row["temp_C"]) else None,
            "humidity": float(row["humidity"]) if pd.notna(row["humidity"]) else None,
            "wind_speed": float(row["wind_speed"]) if pd.notna(row["wind_speed"]) else None,
            "wind_deg": float(row["wind_deg"]) if pd.notna(row["wind_deg"]) else None,
            "precip_mm": float(row["precip_mm"]) if pd.notna(row["precip_mm"]) else None,
            "mean_slope": float(row["mean_slope"]),
            "spei_recent_avg": float(row["spei_recent_avg"]),
            "farsite_prob": farsite_prob
        }

        json_list.append(grid_data)

    return json_list
