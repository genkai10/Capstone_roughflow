from flask import Flask, jsonify
import cv2
import numpy as np
import mediapipe as mp
import h5py
from tensorflow.keras.models import model_from_json
from tensorflow.keras.models import Sequential
from tensorflow.keras.saving import register_keras_serializable

# Register the Sequential class
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

# Actions the model can predict
actions = np.array(["FALL", "SITTING", "RUNNING", "STANDING", "WALKING"])

# Initialize Mediapipe Pose
mp_pose = mp.solutions.pose
mp_drawing = mp.solutions.drawing_utils
pose = mp_pose.Pose()

app = Flask(__name__)

@app.route('/predict', methods=['GET'])
def predict():
    # Open a webcam feed
    cap = cv2.VideoCapture(0)

    sequence = []
    sequence_length = 30  # As used in training
    predictions = []

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Convert the frame to RGB as required by Mediapipe
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(rgb_frame)

        if results.pose_landmarks:
            mp_drawing.draw_landmarks(frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)

            keypoints = np.array([[landmark.x, landmark.y, landmark.z, landmark.visibility] for landmark in results.pose_landmarks.landmark]).flatten()
            sequence.append(keypoints)

        if len(sequence) == sequence_length:
            input_sequence = np.expand_dims(sequence, axis=0)
            res = model.predict(input_sequence)[0]
            predicted_action = actions[np.argmax(res)]
            predictions.append(predicted_action)

            # Remove the oldest frame from the sequence
            sequence = sequence[1:]

        # You can add a condition to break out of the loop for testing purposes
        # For example, if a certain number of predictions have been made
        if len(predictions) >= 10:  # Change 10 to however many predictions you want to collect
            break

    cap.release()

    # Return predictions in JSON format
    return jsonify(predictions)

if __name__ == '__main__':
    app.run(host ="0.0.0.0", port=5000, debug=True)
