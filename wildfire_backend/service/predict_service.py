import pandas as pd
import traceback
import numpy as np
import asyncio
import os

from service.ai_service import send_to_ai_model
from repository.feature_repository import filter_non_weather_features
from service.weather_service import get_weather_data
from util.json_utils import sanitize_json
from service.farsite_service import (
    calculate_farsite_probs,
    apply_directional_correction,
    load_correction_weights,
    prepare_ast_input
)

# 날씨 API를 병렬 호출하여 모든 격자에 날씨 붙이기
async def fetch_weather(lat, lon):
    await asyncio.sleep(0.2)
    return await get_weather_data(lat, lon)

async def append_weather_to_grids_async(grids_df: pd.DataFrame):
    # 각 격자에 대해 fetch_weather 호출 준비
    tasks = [
        fetch_weather(row["center_lat"], row["center_lon"])
        for _, row in grids_df.iterrows()
    ]

    # 병렬로 실행
    weather_data = await asyncio.gather(*tasks)

    # 결과 합치기
    weather_df = pd.DataFrame(weather_data)
    return pd.concat([grids_df.reset_index(drop=True), weather_df], axis=1)


# 전체 예측 흐름 제어 함수
async def process_prediction(lat: float, lon: float):
    print(f"🔥 process_prediction 시작: 위도={lat}, 경도={lon}")

    try:
        # 1️⃣ 반경 15km 이내 격자 추출
        print("📍 [STEP 1] 반경 15km 격자 추출 시도")
        grids_df = load_grids_within_radius(lat, lon)
        print(f"✅ 격자 수: {len(grids_df)}")

        if grids_df.empty:
            print("⚠️ 격자 없음, 종료")
            return {"message": "반경 15km 이내에 격자가 없습니다."}

        # 2️⃣ 지표 필터링
        print("📍 [STEP 2] 지표 필터링 시작")
        grid_ids = grids_df['grid_id'].tolist()
        features_df = filter_non_weather_features(grid_ids)
        print("✅ 지표 필터링 완료")

        # 3️⃣ 날씨 붙이기
        print("📍 [STEP 3] 날씨 붙이기 시작")
        features_with_weather = await append_weather_to_grids_async(features_df)
        print("✅ 날씨 추가 완료")

        # 4️⃣ 확산 확률 계산
        print("📍 [STEP 4] 확산 확률 계산 시작")
        df_probs = calculate_farsite_probs(features_with_weather)
        weights = load_correction_weights()
        df_corrected = apply_directional_correction(df_probs, weights)
        print("✅ 확산 확률 계산 완료")

        # 5️⃣ AI 예측 전송
        print("📍 [STEP 5] AI 예측 JSON 구성 시작")
        final_json = prepare_ast_input(df_corrected)  # 내부에서 sanitize_json 적용됨
        print("📦 전송 JSON 일부:", list(final_json[:1]))

        # 🔒 방어선: 혹시 모를 NaN/inf 유입 방지 (이중 방어)
        final_json = sanitize_json(final_json)

        # ✅ 샘플 데이터도 sanitize 완료된 final_json에서 추출
        sample_data = final_json[:2]

        try:
            print("📡 AI 전송 시도 중...")
            response_code = await send_to_ai_model(final_json)
            print(f"✅ 예측 응답 코드: {response_code}")
        except Exception as send_err:
            print(f"❌ AI 전송 중 예외 발생: {send_err}")

        # 🟢 정상/예외 상관없이 결과 반환
        return {
            "입력 위도": lat,
            "입력 경도": lon,
            "격자 수": len(df_corrected),
            "지표 + 날씨 샘플": sample_data
        }

    except Exception as e:
        print(f"❗ 전체 흐름 중 예외 발생: {e}")
        traceback.print_exc()
        return {"error": str(e)}






