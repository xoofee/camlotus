# Image Edge Extractor

A Flutter application for extracting edges from images using various edge detection algorithms. Optimized for Windows.

note: the print is buggy in windows

![](./app.png)

## Features

1. **Open Images**: Load JPG/PNG images from file system
2. **Paste Images**: Paste images directly from clipboard
3. **Edge Detection**: Apply edge detection algorithms:
   - **Canny**: Advanced edge detection with adjustable thresholds
   - **Sobel**: Gradient-based edge detection
   - **Laplacian**: Second derivative edge detection
4. **Parameter Adjustment**: Modify algorithm parameters in real-time:
   - Low threshold (for Canny)
   - High threshold (for Canny)
   - Algorithm selection
5. **Print Support**: Print processed edge-detected images

## Requirements

- Flutter SDK 3.5.4 or higher
- Windows 10/11 (primary platform)

## Installation

1. Clone the repository
2. Install dependencies:
```bash
flutter pub get
```

## Running the App

```bash
flutter run -d windows
```

## Usage

1. **Open an Image**:
   - Click the "Open Image" button
   - Select a JPG or PNG image file

2. **Paste an Image**:
   - Copy an image to your clipboard (Ctrl+C)
   - Click the "Paste Image" button

3. **Adjust Parameters**:
   - Select an algorithm from the dropdown (Canny, Sobel, or Laplacian)
   - Adjust the low and high threshold sliders (for Canny algorithm)
   - The processed image updates automatically

4. **Print**:
   - After processing an image, click the print icon in the app bar
   - Select your printer and print settings

## Edge Detection Algorithms

### Canny Edge Detection
- Most advanced algorithm
- Uses double thresholding and edge tracking
- Parameters: Low threshold (0-255), High threshold (0-255)
- Best for: General purpose edge detection

### Sobel Edge Detection
- Gradient-based detection
- Faster than Canny
- No parameters needed
- Best for: Quick edge detection

### Laplacian Edge Detection
- Second derivative method
- Detects zero crossings
- No parameters needed
- Best for: Fine detail detection

## Technical Details

- Built with Flutter
- Uses `image` package for image processing
- Uses `printing` package for print functionality
- Uses `pasteboard` package for clipboard access
- Uses `file_picker` for file selection

## Project Structure

```
lib/
  ├── main.dart                    # Main application entry point
  ├── services/
  │   └── edge_detection_service.dart  # Edge detection algorithms
  └── widgets/
      ├── image_viewer.dart        # Image display widget
      └── parameter_controls.dart  # Parameter adjustment UI
```

## Development

### Adding New Algorithms

To add a new edge detection algorithm:

1. Add the algorithm method to `EdgeDetectionService`
2. Add the algorithm name to the dropdown in `ParameterControls`
3. Update the `detectEdges` method to handle the new algorithm
