from fastapi import APIRouter, Request
from dto.predict_dto import PredictRequest
from controller.predict_controller import predict_fire
from util.json_utils import sanitize_json

router = APIRouter()

# /input: 위도/경도를 받아 예측 수행
@router.post("/input")
async def predict_endpoint(request: Request):
    print("✅ /input 엔드포인트 호출됨")
    try:
        data = await request.json()
        lat = data.get('lat')
        lon = data.get('lon')
        print("👉 프론트에서 받은 값:", lat, lon)

        if lat is None or lon is None:
            return {"error": "lat 또는 lon 값이 누락되었습니다."}

        req_obj = PredictRequest(lat=lat, lon=lon)
        result = await predict_fire(req_obj)
        return sanitize_json(result)

    except Exception as e:
        print(f"❌ 예측 처리 중 에러 발생: {e}")
        return {"error": str(e)}

# 기본 헬스 체크 엔드포인트 (GET /)
@router.get("/")
def root():
    return {"message": "Wildfire backend is running"}





