import tensorflow as tf

# Load the Keras model
model = tf.keras.models.load_model(r"C:\Users\mthan\swan_model.h5")

# Convert the model to TensorFlow Serving format
export_path = r'C:\Users\mthan'  # Set the desired export path
tf.saved_model.save(model, export_path)
