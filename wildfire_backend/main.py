from fastapi import FastAPI
from api.predict_api import router as predict_router
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# API 라우터 등록 (프론트에서 /input 호출 시 연결
app.include_router(predict_router)

# ORS 설정: 모든 출처 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)



