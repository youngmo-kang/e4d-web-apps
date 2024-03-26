from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi.encoders import jsonable_encoder
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict
import requests

app = FastAPI()

origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/blockgen")
async def blockgen(item: Dict):
    print(item)
    endpoint = "http://35.223.0.29:8080/predictions/blockgen"
    response = requests.post(endpoint, json=item)
    return JSONResponse(content=jsonable_encoder(response.json()))
