# import cv2
# import numpy as np
# from tensorflow.keras.models import Sequential, model_from_json
# from flask import Flask, request, jsonify
# from flask_socketio import SocketIO, emit
# import mediapipe as mp
# import pandas as pd
# from tsfresh import extract_features
# from joblib import load
# import h5py
# from tensorflow.keras.saving import register_keras_serializable
# import time

# app = Flask(__name__)
# socketio = SocketIO(app, cors_allowed_origins="*")

# # Load the ML model for socket-based predictions
# @register_keras_serializable()
# class CustomSequential(Sequential):
#     pass

# def load_model_without_time_major(h5_path):
#     with h5py.File(h5_path, "r") as f:
#         model_config = f.attrs["model_config"]
#         model_config = model_config.replace('"time_major": false,', '')
#         model = model_from_json(model_config, custom_objects={'Sequential': CustomSequential})
#         model.load_weights(h5_path)
#     return model

# # Load the model and define the actions for the socket-based functionality
# action_model = load_model_without_time_major("action14_10.h5")
# action_model.compile(optimizer="adam", loss="categorical_crossentropy", metrics=["accuracy"])
# actions = np.array(["FALL", "SITTING", "RUNNING", "STANDING", "WALKING"])

# # MediaPipe Pose setup
# mp_pose = mp.solutions.pose
# pose_estimator = mp_pose.Pose()
# mp_drawing = mp.solutions.drawing_utils

# # Camera setup for real-time predictions
# cap = cv2.VideoCapture(0)
# sequence = []
# sequence_length = 30

# # Load the accelerometer classifier model
# acc_model_path = "accelerometer_model_new.joblib"
# classifier = load(acc_model_path)

# # SocketIO handler for WebSocket connections
# @socketio.on('connect')
# def handle_connect():
#     print("Client connected!")
#     socketio.emit('new_prediction', {'action': 'Connected to server!'})

# def generate_predictions():
#     print("Starting prediction generation...")
#     while cap.isOpened():
#         ret, frame = cap.read()
#         if not ret:
#             print("No frame captured from camera.")
#             break

#         rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
#         results = pose_estimator.process(rgb_frame)

#         if results.pose_landmarks:
#             mp_drawing.draw_landmarks(frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)
#             keypoints = np.array([[landmark.x, landmark.y, landmark.z, landmark.visibility] for landmark in results.pose_landmarks.landmark]).flatten()
#             sequence.append(keypoints)

#             if len(sequence) == sequence_length:
#                 input_sequence = np.expand_dims(sequence, axis=0)
#                 res = action_model.predict(input_sequence)[0]
#                 predicted_action = actions[np.argmax(res)]
#                 socketio.emit('new_prediction', {'action': predicted_action})
#                 print(f"Predicted action: {predicted_action}")
#                 sequence.pop(0)  # Maintain sequence length
#                 time.sleep(1)
#         else:
#             print("No landmarks detected.")
#             socketio.emit('new_prediction', {'action': 'No human detected'})

# @socketio.on('start_prediction')
# def start_prediction():
#     print("Starting background prediction task...")
#     socketio.start_background_task(generate_predictions)

# # Accelerometer data processing functions
# def add_sequence_id(df, sequence_id):
#     df['sequence_id'] = sequence_id
#     return df

# def extract_tsfresh_features(ts_df):
#     return extract_features(ts_df, column_id="sequence_id", column_sort="time")

# def preprocess_data(df):
#     test_time_series = add_sequence_id(df, 1)
#     test_features = extract_tsfresh_features(test_time_series)
    
#     columns_to_add = [
#         'classification__mean_n_absolute_max__number_of_maxima_7',
#         'Ay__number_crossing_m__m_-1',
#         'Ay__change_quantiles__f_agg_"var"__isabs_False__qh_0.8__ql_0.0',
#         'SV_total__mean_n_absolute_max__number_of_maxima_7',
#         'classification__ar_coefficient__coeff_1__k_10',
#         'SV_total__ratio_beyond_r_sigma__r_0.5',
#         'Az__change_quantiles__f_agg_"mean"__isabs_True__qh_1.0__ql_0.6',
#         'SV_total__energy_ratio_by_chunks__num_segments_10__segment_focus_8',
#         'Ax__autocorrelation__lag_5',
#         'Az__ratio_beyond_r_sigma__r_1'
#     ]

#     missing_columns = [col for col in columns_to_add if col not in test_features.columns]
#     for col in missing_columns:
#         test_features[col] = 0

#     return test_features[columns_to_add]

# # REST API endpoint for accelerometer data predictions
# @app.route('/predict', methods=['POST'])
# def make_prediction():
#     try:
#         data = request.get_json()
        
#         if 'accelerometer_data' not in data:
#             return jsonify({'error': 'Missing accelerometer data'}), 400
        
#         print("Accelerometer Data:", data['accelerometer_data'])
        
#         if len(data['accelerometer_data'][0]) != 5:
#             return jsonify({'error': 'Incorrect data format. Expected 5 columns.'}), 400
        
#         df = pd.DataFrame(data['accelerometer_data'][1:], columns=['time', 'SV_total', 'Ax', 'Ay', 'Az'])
#         df['time'] = pd.to_datetime(df['time'], unit='ms')

#         processed_features = preprocess_data(df)
#         prediction = classifier.predict(processed_features)
        
#         fall_detected = any(pred == 0 for pred in prediction)
        
#         return jsonify({'predictions': ["Fall Detected" if fall_detected else "No Fall Detected"]})
#     except Exception as e:
#         print(e)
#         return jsonify({'error': str(e)}), 500

# if __name__ == "__main__":
#     socketio.run(app, host="0.0.0.0", port=5000)

import cv2
import numpy as np
from tensorflow.keras.models import Sequential, model_from_json
from flask import Flask, request, jsonify
from flask_socketio import SocketIO, emit
import mediapipe as mp
import pandas as pd
from tsfresh import extract_features
from joblib import load
import h5py
from tensorflow.keras.saving import register_keras_serializable
import time
from datetime import datetime, timedelta
import base64

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

# Global variable to track the last alert time
last_alert_time = None
buffer_duration = timedelta(seconds=10)

# Load the ML model for socket-based predictions
@register_keras_serializable()
class CustomSequential(Sequential):
    pass

def load_model_without_time_major(h5_path):
    with h5py.File(h5_path, "r") as f:
        model_config = f.attrs["model_config"]
        model_config = model_config.replace('"time_major": false,', '')
        model = model_from_json(model_config, custom_objects={'Sequential': CustomSequential})
        model.load_weights(h5_path)
    return model

# Load the video model
action_model = load_model_without_time_major("action14_10.h5")
action_model.compile(optimizer="adam", loss="categorical_crossentropy", metrics=["accuracy"])
actions = np.array(["FALL", "SITTING", "RUNNING", "STANDING", "WALKING"])

# MediaPipe Pose setup
mp_pose = mp.solutions.pose
pose_estimator = mp_pose.Pose()
mp_drawing = mp.solutions.drawing_utils

# Camera setup for real-time predictions
cap = cv2.VideoCapture(0)
sequence = []
sequence_length = 30

# Load the accelerometer classifier model
acc_model_path = "accelerometer_model_new.joblib"
classifier = load(acc_model_path)

# SocketIO handler for WebSocket connections
@socketio.on('connect')
def handle_connect():
    print("Client connected!")
    socketio.emit('new_prediction', {'action': 'Connected to server!'})

# Function to send an alert with buffer
def send_alert():
    global last_alert_time
    current_time = datetime.now()
    if last_alert_time is None or (current_time - last_alert_time) > buffer_duration:
        print(f"[{current_time}] Fall detected! Sending alert...")
        socketio.emit('fall_alert', {'message': 'Fall detected!'})
        last_alert_time = current_time
    else:
        print(f"[{current_time}] Alert suppressed (within buffer period).")

# Video-based prediction generation
def generate_predictions():
    print("Starting prediction generation...")
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            print("No frame captured from camera.")
            break

        # Encode the frame to a JPEG image
        _, buffer = cv2.imencode('.jpg', frame)
        frame_base64 = base64.b64encode(buffer).decode('utf-8')

        # Send the frame to the frontend via SocketIO
        socketio.emit('video_frame', {'frame': frame_base64})

        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose_estimator.process(rgb_frame)

        if results.pose_landmarks:
            mp_drawing.draw_landmarks(frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)
            keypoints = np.array([[landmark.x, landmark.y, landmark.z, landmark.visibility] for landmark in results.pose_landmarks.landmark]).flatten()
            sequence.append(keypoints)

            if len(sequence) == sequence_length:
                input_sequence = np.expand_dims(sequence, axis=0)
                res = action_model.predict(input_sequence)[0]
                predicted_action = actions[np.argmax(res)]

                print(f"Predicted action: {predicted_action}")
                if predicted_action == "FALL":
                    send_alert()
                sequence.pop(0)  # Maintain sequence length
                time.sleep(1)
        else:
            print("No landmarks detected.")

@socketio.on('start_prediction')
def start_prediction():
    print("Starting background prediction task...")
    socketio.start_background_task(generate_predictions)

# Accelerometer data processing functions
def add_sequence_id(df, sequence_id):
    df['sequence_id'] = sequence_id
    return df

def extract_tsfresh_features(ts_df):
    return extract_features(ts_df, column_id="sequence_id", column_sort="time")

def preprocess_data(df):
    test_time_series = add_sequence_id(df, 1)
    test_features = extract_tsfresh_features(test_time_series)
    
    columns_to_add = [
        'classification__mean_n_absolute_max__number_of_maxima_7',
        'Ay__number_crossing_m__m_-1',
        'Ay__change_quantiles__f_agg_"var"__isabs_False__qh_0.8__ql_0.0',
        'SV_total__mean_n_absolute_max__number_of_maxima_7',
        'classification__ar_coefficient__coeff_1__k_10',
        'SV_total__ratio_beyond_r_sigma__r_0.5',
        'Az__change_quantiles__f_agg_"mean"__isabs_True__qh_1.0__ql_0.6',
        'SV_total__energy_ratio_by_chunks__num_segments_10__segment_focus_8',
        'Ax__autocorrelation__lag_5',
        'Az__ratio_beyond_r_sigma__r_1'
    ]

    missing_columns = [col for col in columns_to_add if col not in test_features.columns]
    for col in missing_columns:
        test_features[col] = 0

    return test_features[columns_to_add]

# REST API endpoint for accelerometer data predictions
@app.route('/predict', methods=['POST'])
def make_prediction():
    try:
        data = request.get_json()
        
        if 'accelerometer_data' not in data:
            return jsonify({'error': 'Missing accelerometer data'}), 400
        
        print("Accelerometer Data:", data['accelerometer_data'])
        
        if len(data['accelerometer_data'][0]) != 5:
            return jsonify({'error': 'Incorrect data format. Expected 5 columns.'}), 400
        
        df = pd.DataFrame(data['accelerometer_data'][1:], columns=['time', 'SV_total', 'Ax', 'Ay', 'Az'])
        df['time'] = pd.to_datetime(df['time'], unit='ms')

        processed_features = preprocess_data(df)
        prediction = classifier.predict(processed_features)
        
        fall_detected = any(pred == 0 for pred in prediction)
        if fall_detected:
            send_alert()

        return jsonify({'predictions': ["Fall Detected" if fall_detected else "No Fall Detected"]})
    except Exception as e:
        print(e)
        return jsonify({'error': str(e)}), 500

if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=5000)
