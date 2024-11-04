from flask import Flask, render_template
from flask_socketio import SocketIO, emit
import cv2
import numpy as np
from tensorflow.keras.models import load_model
from pose_media import mediapipe_pose

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")  # Allow connections from any origin

# Load the trained model
model = load_model('action14_10.h5')

# Actions the model can predict
actions = np.array(["FALL", "SITTING", "RUNNING", "STANDING", "WALKING"])

# Initialize MediaPipe Pose detection
pose_estimator = mediapipe_pose()

# Set up the camera and prediction buffer
cap = cv2.VideoCapture(0)
sequence = []
sequence_length = 30  # Sequence length used in training

@socketio.on('connect')
def handle_connect():
    print("Client connected!")

def generate_predictions():
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Detect keypoints using MediaPipe
        image, results = pose_estimator.mediapipe_detection(frame)
        pose_estimator.draw_styled_landmarks(image, results)
        keypoints = pose_estimator.extract_keypoints(results)
        sequence.append(keypoints)

        # Keep the sequence length consistent
        if len(sequence) == sequence_length:
            input_sequence = np.expand_dims(sequence, axis=0)
            res = model.predict(input_sequence)[0]
            predicted_action = actions[np.argmax(res)]

            # Send prediction to the frontend via WebSocket
            socketio.emit('new_prediction', {'action': predicted_action})

            # Remove the oldest frame from the sequence
            sequence.pop(0)

# Start the prediction loop in a background thread
@socketio.on('start_prediction')
def start_prediction():
    socketio.start_background_task(generate_predictions)

if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=5000)
