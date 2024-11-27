import cv2
import numpy as np
from tensorflow.keras.models import load_model, Sequential ,model_from_json
from flask import Flask
from flask_socketio import SocketIO, emit
import mediapipe as mp
import h5py
from tensorflow.keras.saving import register_keras_serializable

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")


@register_keras_serializable()
class CustomSequential(Sequential):
    pass

# Function to load model without `time_major` argument
def load_model_without_time_major(h5_path):
    with h5py.File(h5_path, "r") as f:
        model_config = f.attrs["model_config"]
        model_config = model_config.replace('"time_major": false,', '')
        model = model_from_json(model_config, custom_objects={'Sequential': CustomSequential})
        model.load_weights(h5_path)
    return model

# Load the model
model = load_model_without_time_major("action14_10.h5")
model.compile(optimizer="adam", loss="categorical_crossentropy", metrics=["accuracy"])

# Load the model
# model = load_model("action14_10.h5")
# model.compile(optimizer="adam", loss="categorical_crossentropy", metrics=["accuracy"])

# Actions the model can predict
actions = np.array(["FALL", "SITTING", "RUNNING", "STANDING", "WALKING"])

# MediaPipe Pose setup
mp_pose = mp.solutions.pose
pose_estimator = mp_pose.Pose()
mp_drawing = mp.solutions.drawing_utils
pose = mp_pose.Pose()

# Camera setup
cap = cv2.VideoCapture(0)
sequence = []
sequence_length = 30

@socketio.on('connect')
def handle_connect():
    print("Client connected!")
    socketio.emit('new_prediction', {'action': 'Connected to server!'})  # Emit a connection test message

def generate_predictions():
    print("Starting prediction generation...")
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            print("No frame captured from camera.")
            break

        # Example keypoints extraction for testing
        # Replace this with your actual keypoint extraction logic
        results = pose_estimator.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))

        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(rgb_frame)

        if results.pose_landmarks:
            mp_drawing.draw_landmarks(frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)

            keypoints = np.array([[landmark.x, landmark.y, landmark.z, landmark.visibility] for landmark in results.pose_landmarks.landmark]).flatten()
            sequence.append(keypoints)
        
        # if results.pose_landmarks:
        #     keypoints = np.array([[res.x, res.y, res.z] for res in results.pose_landmarks.landmark]).flatten()
        #     sequence.append(keypoints)

        if len(sequence) == sequence_length:
            input_sequence = np.expand_dims(sequence, axis=0)
            res = model.predict(input_sequence)[0]
            predicted_action = actions[np.argmax(res)]

                # Send prediction to the frontend via WebSocket
            socketio.emit('new_prediction', {'action': predicted_action})
            print(f"Predicted action: {predicted_action}")
                
            sequence.pop(0)  # Maintain sequence length
        else:
            print("No landmarks detected.")

@socketio.on('start_prediction')
def start_prediction():
    print("Starting background prediction task...")
    socketio.start_background_task(generate_predictions)

if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=5001)
