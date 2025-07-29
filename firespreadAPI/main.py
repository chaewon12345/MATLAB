from fastapi import FastAPI, Request
from firebase_admin import credentials, firestore, initialize_app
from fastapi.responses import JSONResponse
import firebase_admin
import os
import json

# 🔐 Firebase 초기화
if not firebase_admin._apps:
    firebase_json = os.environ.get("FIREBASE_KEY")
    cred_dict = json.loads(firebase_json)
    cred = credentials.Certificate(cred_dict)
    initialize_app(cred)

db = firestore.client()
app = FastAPI()

input_queue = []

@app.post("/input")
async def receive_input(request: Request):
    data = await request.json()
    print("📥 [receive_input] 수신한 데이터:", data)  # 🔧 디버깅 출력 추가
    input_queue.append(data)
    print("📥 [receive_input] 현재 input_queue 길이:", len(input_queue))
    return {"status": "input received"}

@app.get("/check_input")
def check_input():
    print("🔎 [check_input] 호출됨. 현재 queue 길이:", len(input_queue))
    if input_queue:
        data = input_queue.pop(0)
        print("🔎 [check_input] 반환하는 데이터:", data)  # 🔧 디버깅 출력 추가
        return data
    else:
        print("🔎 [check_input] 반환할 데이터 없음.")
        return {}

@app.post("/reset_input")
def reset_input():
    input_queue.clear()
    return {"status": "queue reset", "length": len(input_queue)}

from datetime import datetime

@app.post("/upload_result")
async def upload_result(request: Request):
    try:
        data = await request.json()

        print("📥 [upload_result] 데이터 수신:", type(data))
        print("📥 내용:", data)

        if not isinstance(data, dict):
            print("❌ 잘못된 데이터 형식:", type(data))
            return JSONResponse(
                status_code=400,
                content={
                    "status": "error",
                    "message": "Expected JSON object (dict), but received something else.",
                    "received_type": str(type(data)),
                    "hint": "loop.m에서 struct 형태로 JSON을 보내야 함"
                }
            )

        grid_results = data.get("grid_results", [])
        global_top3 = data.get("global_top3", [])

        print("🧩 격자 수:", len(grid_results))
        print("📊 중요 피처 Top3:", global_top3)

        # 🔄 grids 변환
        grids_map = {
            f"grid_{g['grid_id']}": {
                "grid_id": g["grid_id"],
                "center_lat": g["center_lat"],
                "center_lon": g["center_lon"],
                "lat_min": g["lat_min"],
                "lat_max": g["lat_max"],
                "lon_min": g["lon_min"],
                "lon_max": g["lon_max"],
                "pSpread": g["pSpread"]
            }
            for g in grid_results
        }

        print("🗺️ 변환된 grids_map preview:")
        for k in list(grids_map.keys())[:3]:  # 상위 3개만 프린트
            print(f"  {k}: {grids_map[k]}")

        # ⏰ 문서 ID 및 timestamp
        doc_id = datetime.now().strftime("%Y%m%d_%H%M%S")
        print("📌 생성된 문서 ID (시간 기반):", doc_id)

        # 📝 Firestore 저장
        db.collection("fire_results").document(doc_id).set({
            "timestamp": doc_id,
            "grids": grids_map,
            "global_feature_importance_top3": global_top3
        })
        global input_queue
        input_queue.clear()
        print("🧹 input_queue 초기화 완료")

        print(f"✅ Firestore 저장 완료 (문서 ID: {doc_id})")

        return {
            "status": "saved",
            "doc_id": doc_id,
            "grids_saved": len(grids_map),
            "global_top3": global_top3
        }

    except Exception as e:
        print("❗ 예외 발생:", str(e))
        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "message": str(e),
                "hint": "FastAPI 로그를 확인하세요"
            }
        )
