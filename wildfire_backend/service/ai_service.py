import httpx

# AI 예측 서버로 전송하는 함수
async def send_to_ai_model(data: list):
    """
        21개 필드 JSON 리스트를 외부 AI 예측 서버로 비동기로 전송
    """
    url = "https://firespread-api.onrender.com/input"
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.post(url, json=data)
            response.raise_for_status()
            return response.status_code
    except httpx.TimeoutException:
        print("AI 서버 응답 시간 초과")
        return 504
    except httpx.RequestError as e:
        print(f"AI 예측 서버 전송 실패: {e}")
        return 502




