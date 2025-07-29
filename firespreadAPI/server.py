from fastapi import FastAPI
from pydantic import BaseModel
import matlab.engine

app = FastAPI()
eng = matlab.engine.start_matlab()
eng.cd(r"C:\mat", nargout=0)  # predictSpread.m 위치

class PredictInput(BaseModel):
    grid_id: int
    lat_min: float
    lat_max: float
    lon_min: float
    lon_max: float
    center_lat: float
    center_lon: float
    avg_fuelload_pertree_kg: float
    FFMC: float
    DMC: float
    DC: float
    NDVI: float
    smap_20250630_filled: float
    temp_C: float
    humidity: float
    wind_speed: float
    wind_deg: float
    precip_mm: float
    mean_slope: float
    spei_recent_avg: float
    farsite_prob: float

@app.post("/predict")
def predict(data: PredictInput):
    # Python dict → MATLAB struct로 변환
    matlab_struct = {k: float(v) for k, v in data.dict().items()}
    result = eng.predictSpread(matlab_struct)

    return {
        "grid_id": result["grid_id"],
        "center_lat": result["center_lat"],
        "center_lon": result["center_lon"],
        "pSpread": result["pSpread"],
        "top_features": result["feature_importance_top3"]
    }
