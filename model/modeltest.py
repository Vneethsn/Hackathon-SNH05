from flask import Flask, request, jsonify, render_template
import tensorflow as tf
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
import numpy as np
from PIL import Image
import os
import tempfile

app = Flask(__name__)

# Load the trained model
model = load_model("swan_model.h5")  # Update with the correct model file

# Parameters
img_width, img_height = 150, 150  # Adjusted to match the model's input size
categories = ['Bird', 'Animal', 'Math', 'Insect']  # Define the origami categories

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Receive the image 
        file = request.files['image']
        
        # Save the received image to a temporary file
        temp_img_path = r"C:\Users\mthan\test.jpg"  # Update with the desired path
        file.save(temp_img_path)

        # Load and preprocess the image
        img = image.load_img(temp_img_path, target_size=(img_width, img_height))
        img_array = image.img_to_array(img)
        img_array = np.expand_dims(img_array, axis=0)
        img_array /= 255.0  # Rescale to [0,1]

        # Make predictions
        predictions = model.predict(img_array)

        # Get the predicted category
        predicted_category = categories[np.argmax(predictions)]

        # Return the prediction result
        result = {"prediction": f"This is an {predicted_category} origami"}
        return jsonify(result)

    except Exception as e:
        return jsonify({"error": str(e)})

@app.route('/')
def index():
    return render_template('index.html')  # Update with your HTML template path

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
