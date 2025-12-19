# 🎯 Final Flutter Project: Endangered Iguana Classifier

My App is a specialized mobile application built with Flutter that utilizes Machine Learning to identify endangered iguana species in real-time. By leveraging a custom-trained TensorFlow Lite model, the app provides instant species recognition directly on your smartphone.

## 📖 Table of Contents
- [About the Project](#-about-the-project)
- [Supported Species](#-supported-species)
- [Key Features](#-key-features)
- [Video Demo](#-video-demo)
- [How it Works](#-how-it-works)

## ✨ About the Project

In a world where biodiversity is under threat, this project demonstrates the power of On-Device AI for conservation education. Unlike cloud-based vision APIs, this Flutter app processes images locally. This ensures:

- **Privacy**: Images never leave the device.
- **Speed**: Near-instant classification without network latency.
- **Accessibility**: Works offline in remote areas where these species might be found.

## 📦 Supported Species

The model is currently trained to recognize the following 10 classes of endangered iguanas:

1. Black spiny
2. Blue Iguana
3. Pink Galapagos Iguana
4. Fiji Banded Iguana
5. Desert Iguana
6. Marine Iguana
7. Rhinoceros Iguana
8. Chuckwalla Iguana
9. Lesser Antillean Iguana
10. Ricords Rock Iguana

## 🚀 Key Features

- **📸 Live Camera Feed**: Point your camera at an iguana (or a photo of one) to identify the species.
- **🖼️ Gallery Picker**: Import saved images to run the classifier.
- **📊 Confidence Scoring**: Displays the percentage of certainty for each prediction.
- **📚 Species Information**: View detailed information about each identified species.
- **🎨 Clean UI**: A minimalist interface focused on user experience with a nature-inspired theme.

## 📺 Video Demo

Check out the app in action! See how it classifies different iguana species with high accuracy.


[![Watch the video](https://img.youtube.com/vi/YOUR_VIDEO_ID/0.jpg)](https://www.youtube.com/watch?v=YOUR_VIDEO_ID)

## 🧠 How it Works

The application uses a Convolutional Neural Network (CNN) optimized for mobile.

1.  **Pre-processing**: The Flutter app captures an image and crops/resizes it to the dimensions required by the model.
2.  **Inference**: The tflite interpreter runs the image data through the model weights.
3.  **Post-processing**: The app maps the resulting index to the corresponding species name (e.g., Index 1 -> Blue Iguana) and updates the UI.
