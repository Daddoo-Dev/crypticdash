---
license: gemma
base_model:
- google/gemma-3-270m-it
library_name: transformers.js
tags:
- gemma3
- gemma
- google
pipeline_tag: text-generation
---

# Gemma 3 270M-IT ONNX Model for CrypticDash

## Model Information

- **Model**: Google Gemma 3 270M-IT (Instruction Tuned)
- **Size**: 426MB (model_q4f16.onnx - recommended)
- **Format**: ONNX (pre-converted)
- **Context**: 32K tokens
- **License**: Gemma license (open for commercial use)
- **Source**: onnx-community/gemma-3-270m-it-ONNX

## Features

- **Instruction Following**: Specifically trained for following instructions
- **Text Generation**: Optimized for structured text output
- **Efficiency**: 90% smaller than Phi-2 (2.7GB → 426MB)
- **Modern**: Latest Google model (August 2024 knowledge cutoff)
- **Pre-converted**: Ready to use without conversion

## File Structure

```
gemma-3-270m/
├── onnx/
│   ├── model.onnx              # Full precision (1.14GB)
│   ├── model_fp16.onnx         # Half precision (570MB)
│   ├── model_q4.onnx           # Quantized (801MB)
│   ├── model_q4f16.onnx        # Quantized + Half precision (426MB) ⭐ RECOMMENDED
│   └── [corresponding .onnx_data files]
├── tokenizer.json               # Tokenizer configuration
├── tokenizer_config.json        # Tokenizer settings
├── config.json                  # Model configuration
├── generation_config.json       # Generation settings
├── chat_template.jinja          # Chat template
└── README.md                    # This file
```

## Usage in CrypticDash

The SimpleAIService now uses this model for:
- **Repository analysis and insights**
- **Intelligent TODO.md generation** with proper formatting
- **Project recommendations** based on actual code analysis
- **Code structure understanding**
- **Multi-language support** (140+ languages)

## Performance Benefits

- **App Size Reduction**: From 2.7GB to 426MB (84% smaller!)
- **Faster Inference**: Smaller model = faster responses
- **Better Instruction Following**: Specifically designed for structured tasks
- **Energy Efficient**: Lower power consumption
- **Mobile Optimized**: Perfect for mobile and desktop apps

## Model Capabilities

- Repository content analysis
- TODO.md generation with exact template formatting
- Project insights and recommendations
- Code structure understanding
- Multi-language support (140+ languages)
- Instruction following for complex tasks

## Integration Status

✅ **Fully Integrated** - The SimpleAIService has been updated to use this model
✅ **Model Path**: `assets/ai_models/gemma-3-270m`
✅ **ONNX Ready**: Pre-converted and optimized for CrypticDash
✅ **Settings Updated**: App settings now display Gemma model information

## Next Steps

1. **Test the integration** by enabling AI features in settings
2. **Generate TODO.md** for a repository to see the improved results
3. **Enjoy faster, more intelligent** AI-powered insights

---

*Model integrated on: 2025-08-15*
*Source: https://huggingface.co/onnx-community/gemma-3-270m-it-ONNX*
*CrypticDash Integration: Complete* 🎉
