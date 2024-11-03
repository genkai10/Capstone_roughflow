import cv2
import numpy as np
from tensorflow.keras.models import load_model
import mediapipe as mp

# Load the trained model
model = load_model('action14_10.h5')

# Actions the model can predict
actions = np.array(["FALL", "SITTING", "RUNNING", "STANDING", "WALKING"])

# Initialize Mediapipe Pose
mp_pose = mp.solutions.pose
mp_drawing = mp.solutions.drawing_utils
pose = mp_pose.Pose()

# Open a webcam feed
cap = cv2.VideoCapture(0)

# Set a buffer for storing keypoints
sequence = []
sequence_length = 30  # As used in training

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # Convert the frame to RGB as required by Mediapipe
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = pose.process(rgb_frame)

    # Draw pose landmarks
    if results.pose_landmarks:
        mp_drawing.draw_landmarks(frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)

    # Extract keypoints if results are available
    if results.pose_landmarks:
        keypoints = np.array([[landmark.x, landmark.y, landmark.z, landmark.visibility] for landmark in results.pose_landmarks.landmark]).flatten()
        sequence.append(keypoints)

    # Keep the sequence length consistent
    if len(sequence) == sequence_length:
        # Convert the sequence into the correct shape for the model
        input_sequence = np.expand_dims(sequence, axis=0)

        # Predict action
        res = model.predict(input_sequence)[0]
        predicted_action = actions[np.argmax(res)]

        # Display the prediction on the video feed
        cv2.putText(frame, predicted_action, (10, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2, cv2.LINE_AA)

        # Remove the oldest frame from the sequence
        sequence = sequence[1:]

    # Show the video frame
    cv2.imshow('Pose Estimation & Action Recognition', frame)

    # Press 'q' to quit
    if cv2.waitKey(10) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
