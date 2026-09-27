import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File(r'C:\Users\SALVIYA\.gemini\antigravity-ide\brain\aeb3eac3-2e67-4bba-a619-348725959143\drosophila_adult_1790508194754.png');
  if (!file.existsSync()) {
    print("File not found");
    return;
  }
  
  final image = img.decodeImage(file.readAsBytesSync());
  if (image == null) return;
  
  // Create a new image to hold the output (supports transparency by default)
  final outImg = img.Image(width: image.width, height: image.height, numChannels: 4);
  
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.r > 230 && pixel.g > 230 && pixel.b > 230) {
        // Transparent
        outImg.setPixelRgba(x, y, 255, 255, 255, 0);
      } else {
        outImg.setPixel(x, y, pixel);
      }
    }
  }
  
  final resized = img.copyResize(outImg, width: 256);
  
  final outFile = File(r'C:\Users\SALVIYA\Documents\Brain Fly\assets\flies\drosophila_adult.png');
  outFile.createSync(recursive: true);
  outFile.writeAsBytesSync(img.encodePng(resized));
  print("Done processing image");
}
