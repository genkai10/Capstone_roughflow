from flask import Flask, request, jsonify
import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.preprocessing import MinMaxScaler
import joblib

# Load the trained model and scalers
model = tf.keras.models.load_model('trained_lstm_model.h5')
scaler_X = joblib.load('scaler_X.pkl')
scaler_y = joblib.load('scaler_y.pkl')

app = Flask(__name__)

# Define thresholds for anomalies
thresholds = {
    'HR': 2,
    'PULSE': 0.1,
    '%SpO2': 0.1,
    'RESP': 2,
}

# Define a route for anomaly detection
@app.route('/predict_anomaly', methods=['POST'])
def predict_anomaly():
    # Parse JSON data from the request
    data = request.get_json()
    vital_signs = data['vital_signs']  # Assume format is [[HR, PULSE, %SpO2, RESP, hour, minute], ...]
    timestamp = data['timestamp']

    # Convert the input data to a DataFrame and add necessary columns
    input_data = pd.DataFrame(vital_signs, columns=['HR', 'PULSE', '%SpO2', 'RESP', 'hour', 'minute'])
    
    # Normalize the input data
    input_data_scaled = scaler_X.transform(input_data)
    input_data_scaled = input_data_scaled.reshape((1, len(vital_signs), input_data.shape[1]))

    # Make a prediction
    predicted_scaled = model.predict(input_data_scaled)
    predicted_rescaled = scaler_y.inverse_transform(predicted_scaled)

    # Calculate the reconstruction error
    actual_values = input_data.iloc[-1][['HR', 'PULSE', '%SpO2', 'RESP']].values
    reconstruction_error = np.abs(predicted_rescaled[0] - actual_values)

    # Check for anomalies
    anomalies = {feature: reconstruction_error[i] > thresholds[feature] for i, feature in enumerate(['HR', 'PULSE', '%SpO2', 'RESP'])}
    is_anomaly = any(anomalies.values())

    # Prepare response
    response = {
        'timestamp': timestamp,
        'is_anomaly': is_anomaly,
        'anomalies': {feature: anomalies[feature] for feature, anomaly in anomalies.items() if anomaly}
    }

    return jsonify(response)

if __name__ == '__main__':
    app.run(debug=True)
