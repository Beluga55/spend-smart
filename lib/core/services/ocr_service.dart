import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<XFile?> pickImageFromCamera() async {
    return _picker.pickImage(source: ImageSource.camera);
  }

  Future<XFile?> pickImageFromGallery() async {
    return _picker.pickImage(source: ImageSource.gallery);
  }

  Future<String> extractText(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await _recognizer.processImage(
      inputImage,
    );
    return recognizedText.text;
  }

  void dispose() {
    _recognizer.close();
  }
}
