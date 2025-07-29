from pydantic import BaseModel
class PredictRequest(BaseModel):
    lat: float
    lon: float
