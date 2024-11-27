from flask import Flask, request, jsonify
import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.preprocessing import MinMaxScaler
import joblib
from tensorflow.keras.models import load_model

# Load the trained model and scalers
try:
    model = load_model('trained_lstm_model.h5')
    scaler_X = joblib.load('scaler_X.pkl')
    scaler_y = joblib.load('scaler_y.pkl')
    print("Model and scalers loaded successfully")
except Exception as e:
    print(f"Error loading model or scalers: {e}")
    raise e

# Define thresholds for anomalies
thresholds = {
    'HR': 2,
    'PULSE': 0.1,
    '%SpO2': 2,
    'RESP': 2,
}

# Initialize Flask app
app = Flask(__name__)

@app.route('/predict_anomaly', methods=['POST'])
def predict_anomaly():
    try:
        # Parse JSON data from the request
        data = request.get_json()
        print("Received data:", data)

        # Extracting values from the JSON request
        hr = data['HR'][0]
        pulse = data['PULSE'][0]
        spo2 = data['%SpO2'][0]
        resp = data['RESP'][0]
        timestamp = data.get('timestamp', 'N/A')

        # Convert the input data to a DataFrame
        input_data = pd.DataFrame(
            [[hr, pulse, spo2, resp, 6, 15]],
            columns=['HR', 'PULSE', '%SpO2', 'RESP', 'hour', 'minute']
        )
        print("DataFrame created:\n", input_data)

        # Normalize the input data
        input_data_scaled = scaler_X.transform(input_data)
        input_data_scaled = input_data_scaled.reshape(1, 1, -1)
        print("input scaled:", input_data_scaled)
        # Make a prediction using the loaded model
        predicted_scaled = model.predict(input_data_scaled)
        predicted_rescaled = scaler_y.inverse_transform(predicted_scaled)[0]

        # Calculate the reconstruction error
        actual_values = input_data.iloc[0][['HR', 'PULSE', '%SpO2', 'RESP']].values
        reconstruction_error = np.abs(predicted_rescaled - actual_values)
        print(actual_values)
        print(predicted_rescaled)
        # Check for anomalies
        anomalies = {
            feature: bool(reconstruction_error[i] > thresholds[feature])
            for i, feature in enumerate(['HR', 'PULSE', '%SpO2', 'RESP'])
        }
        is_anomaly = any(anomalies.values())

        # Prepare the response
        response = {
            'timestamp': timestamp,
            'is_anomaly': bool(is_anomaly),
            'anomalies': {
                feature: anomalies[feature]
                for feature, anomaly in anomalies.items() if anomaly
            }
        }

        return jsonify(response)

    except Exception as e:
        print(f"Error in prediction: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5002, debug=True)
