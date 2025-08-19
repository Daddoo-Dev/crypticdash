# AI Implementation Guide for CrypticDash

## Current Status ✅

- **AI Service**: Fully implemented with mock responses
- **UI Integration**: Complete settings and AI insights widgets
- **Model Structure**: Placeholder files created for Phi-2
- **App Size**: Only ~2.7GB when real model is added (not 16GB!)

## What We've Built

### 1. **AI Service Architecture** (`lib/services/ai_service.dart`)
- Provider-based state management
- Local model support (currently Phi-2 only)
- Cloud AI provider support (OpenAI, Anthropic, etc.)
- Mock response generation for development

### 2. **Settings Integration** (`lib/screens/settings_screen.dart`)
- AI enable/disable toggle
- Provider selection (Local, OpenAI, Anthropic, etc.)
- Model selection for local AI
- Configuration settings (tokens, temperature)

### 3. **AI Insights Widget** (`lib/widgets/ai_insights_widget.dart`)
- Project progress analysis
- Next steps suggestions
- Task prioritization
- Project summaries
- Improvement recommendations

## Real Implementation Steps

### Phase 1: Model Acquisition (Current)

1. **✅ Create Model Structure**
   ```
   assets/ai_models/phi-2/
   ├── model.onnx          # Placeholder created
   ├── tokenizer.json      # Placeholder created  
   ├── config.json         # Placeholder created
   └── README.md           # Instructions created
   ```

2. **🔄 Get Real Phi-2 Model**
   - **Option A**: Download from https://huggingface.co/microsoft/phi-2-onnx
   - **Option B**: Convert PyTorch model to ONNX (see README.md)
   - **Option C**: Use smaller alternative (Phi-1.5, TinyLlama)

### Phase 2: ONNX Runtime Integration

1. **Add Platform-Specific Dependencies**

   **Android** (`android/app/build.gradle.kts`):
   ```kotlin
   dependencies {
       implementation 'com.microsoft.onnxruntime:onnxruntime-android:1.16.3'
   }
   ```

   **iOS** (`ios/Podfile`):
   ```ruby
   pod 'onnxruntime-mobile-c', '~> 1.16.3'
   ```

   **Windows** (`windows/CMakeLists.txt`):
   ```cmake
   find_package(onnxruntime REQUIRED)
   target_link_libraries(${BINARY_NAME} PRIVATE onnxruntime)
   ```

2. **Create FFI Bindings** (`lib/services/onnx_service.dart`)
   ```dart
   import 'dart:ffi';
   import 'dart:io';
   
   class ONNXService {
     static late final DynamicLibrary _lib;
     static late final Pointer<Void> Function() _createSession;
     static late final void Function(Pointer<Void>) _destroySession;
     
     static Future<void> initialize() async {
       if (Platform.isAndroid) {
         _lib = Platform.isAndroid
             ? DynamicLibrary.open('libonnxruntime4j_jni.so')
             : DynamicLibrary.process();
       }
       // Load function pointers
     }
   }
   ```

### Phase 3: Tokenization & Inference

1. **Implement Tokenizer** (`lib/services/tokenizer_service.dart`)
   ```dart
   class Phi2Tokenizer {
     late final Map<String, int> _vocab;
     late final Map<int, String> _idToToken;
     
     Future<void> loadTokenizer() async {
       final json = await rootBundle.loadString('assets/ai_models/phi-2/tokenizer.json');
       _vocab = Map<String, int>.from(jsonDecode(json));
       _idToToken = _vocab.map((k, v) => MapEntry(v, k));
     }
     
     List<int> encode(String text) {
       // Implement BPE tokenization
     }
     
     String decode(List<int> ids) {
       // Implement detokenization
     }
   }
   ```

2. **Update AI Service** (`lib/services/ai_service.dart`)
   ```dart
   Future<String> _generateLocalAIResponse(String prompt) async {
     try {
       // Load model if not loaded
       if (!_modelLoaded) {
         await _loadModel();
       }
       
       // Tokenize input
       final inputIds = _tokenizer.encode(prompt);
       
       // Run inference
       final output = await _onnxService.runInference(inputIds);
       
       // Decode output
       return _tokenizer.decode(output);
     } catch (e) {
       debugPrint('Local AI error: $e');
       return 'Error generating local AI response: $e';
     }
   }
   ```

### Phase 4: Performance Optimization

1. **Model Quantization**
   - Convert to INT8 for faster inference
   - Use model pruning for smaller size
   - Implement caching for repeated prompts

2. **Memory Management**
   - Load model on demand
   - Implement model unloading
   - Use streaming responses for long outputs

## Alternative Approaches

### Option 1: TensorFlow Lite
```yaml
dependencies:
  tflite_flutter: ^0.10.4
  tflite_flutter_helper: ^0.3.1
```

### Option 2: Custom FFI + ONNX Runtime
- Direct C++ integration
- Platform-specific implementations
- Maximum performance

### Option 3: Cloud AI Only
- Remove local model complexity
- Focus on API integration
- Smaller app size

## Current App Size Impact

- **Base App**: ~50-100MB
- **Phi-2 Model**: ~2.7GB
- **Total**: ~2.8GB (not 16GB!)

## Testing the Current Implementation

1. **Run the app**: `flutter run`
2. **Go to Settings** → AI Integration
3. **Enable AI Features**
4. **Select Local Provider**
5. **Test AI Insights** on project detail screen

## Next Steps

1. **Choose Implementation Approach** (ONNX, TFLite, or Cloud-only)
2. **Download Real Model** (follow README.md)
3. **Implement Platform Bindings**
4. **Add Tokenization Logic**
5. **Test Real Inference**
6. **Optimize Performance**

## Benefits of Current Architecture

- **Modular Design**: Easy to swap AI providers
- **Mock Responses**: Development can continue without real AI
- **Clean UI**: Professional settings interface
- **Future-Proof**: Ready for real AI integration
- **User Experience**: No complex setup required

## Support & Resources

- **ONNX Runtime**: https://onnxruntime.ai/
- **Phi-2 Model**: https://huggingface.co/microsoft/phi-2
- **Flutter FFI**: https://dart.dev/guides/libraries/c-interop
- **Platform Channels**: https://docs.flutter.dev/development/platform-integration

---

**Status**: ✅ Foundation Complete | 🔄 Ready for Real AI Integration
