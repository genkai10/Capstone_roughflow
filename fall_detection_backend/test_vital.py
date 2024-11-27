import requests
import json


url = "http://192.168.1.18:5002/predict_anomaly"

data = {
  "HR": [109.8],
  "PULSE": [75],
  "%SpO2": [96.8],
  "RESP": [12],
  "timestamp": ["2024-06-19T06:15:00"]
}


response = requests.post(url, json=data)


print(response)
print(response.json())