import traceback
from dto.predict_dto import PredictRequest
from service.predict_service import process_prediction

# 예측 컨트롤러: 서비스 계층 호출 및 예외 처리
async def predict_fire(req):
    print(f"🔥 predict_fire 함수 호출됨: lat={req.lat}, lon={req.lon}")
    try:
        print("✅ [predict_controller] 요청 도착!")
        result = await process_prediction(req.lat, req.lon)
        print("✅ [predict_controller] 결과 생성 완료")
        return result
    except Exception as e:
        print("❌ [predict_controller] 예외 발생:", e)
        traceback.print_exc()
        return {"error": str(e)}





