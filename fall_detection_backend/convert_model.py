import tensorflow as tf

# Load the .h5 model
model = tf.keras.models.load_model("action14_10.h5")

# Save it in the SavedModel format
model.save("converted_model", save_format="tf")
