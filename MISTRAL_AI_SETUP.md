# Mistral AI Local Setup Guide

This guide explains how to set up and run the Mistral 7B AI model locally for the crypticdash application.

## Prerequisites

1. **Python 3.8+** installed on your system
2. **Git** for cloning repositories
3. **At least 8GB RAM** (16GB+ recommended)
4. **GPU with CUDA support** (optional but recommended for speed)

## Quick Setup

### 1. Install Python Dependencies

```bash
cd assets/scripts
pip install -r requirements.txt
```

### 2. Download the Mistral Model

The application expects the Mistral model file at:
```
assets/ai_models/mistral/mistral-7b-instruct-v0.1-q4_k_m.gguf
```

**Option A: Download from Hugging Face (Recommended)**
```bash
# Create the directory
mkdir -p assets/ai_models/mistral

# Download the model (this will take some time)
python -c "
from huggingface_hub import hf_hub_download
hf_hub_download(
    repo_id='TheBloke/Mistral-7B-Instruct-v0.1-GGUF',
    filename='mistral-7b-instruct-v0.1-q4_k_m.gguf',
    local_dir='assets/ai_models/mistral'
)
"
```

**Option B: Manual Download**
1. Visit: https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.1-GGUF
2. Download `mistral-7b-instruct-v0.1-q4_k_m.gguf`
3. Place it in `assets/ai_models/mistral/`

### 3. Test the Server

```bash
cd assets/scripts
python run_mistral_server.py
```

You should see:
```
Loading Mistral 7B model...
Loading tokenizer...
Loading model...
Mistral model loaded successfully!
Starting Mistral AI server on http://localhost:8080
```

### 4. Verify the Server

Open a new terminal and test:
```bash
curl http://localhost:8080/health
```

Expected response:
```json
{
  "status": "healthy",
  "model_loaded": true,
  "model_name": "Mistral-7B-Instruct-v0.1"
}
```

## Running the Flutter App

Once the Python server is running:

1. **Start the Flutter app**: `flutter run`
2. **The app will automatically connect** to the local Mistral server
3. **Use the AI features** in the app - they will now use REAL Mistral AI inference!

## Troubleshooting

### Common Issues

**1. "Python not found"**
- Ensure Python is installed and in your PATH
- Try `python3` instead of `python` on some systems

**2. "Required packages not found"**
```bash
pip install flask transformers torch accelerate bitsandbytes sentencepiece
```

**3. "Model file not found"**
- Verify the model file exists at the correct path
- Check file permissions

**4. "Out of memory"**
- Close other applications
- Use a smaller model variant
- Ensure you have at least 8GB RAM available

**5. "CUDA out of memory" (GPU users)**
- Reduce batch size in the Python script
- Use CPU-only mode by modifying the script

### Performance Optimization

**For CPU-only systems:**
- The model will run slower but still work
- Consider using a smaller model variant

**For GPU systems:**
- Ensure CUDA is properly installed
- The model will automatically use GPU acceleration

### Model Variants

If the default model is too large, try these alternatives:

- `mistral-7b-instruct-v0.1-q4_k_m.gguf` (4.37 GB) - **Default**
- `mistral-7b-instruct-v0.1-q5_k_m.gguf` (5.43 GB) - Better quality
- `mistral-7b-instruct-v0.1-q3_k_m.gguf` (3.31 GB) - Smaller, faster

## Advanced Configuration

### Custom Server Port

Edit `run_mistral_server.py` and change:
```python
app.run(host='0.0.0.0', port=8080, debug=False)
```

### Model Parameters

Adjust generation parameters in the Flutter app:
- `temperature`: Controls randomness (0.0 = deterministic, 1.0 = very random)
- `max_tokens`: Maximum length of generated text
- `top_p`: Nucleus sampling parameter

### Memory Optimization

For systems with limited RAM:
1. Use smaller model variants
2. Enable 4-bit quantization (already enabled by default)
3. Close unnecessary applications

## Security Notes

- The server runs on `localhost` only (not accessible from external networks)
- No authentication is implemented - only use on trusted networks
- The model files are large - ensure you have sufficient storage space

## Support

If you encounter issues:

1. Check the Python server logs for error messages
2. Verify all prerequisites are met
3. Ensure sufficient system resources
4. Check the troubleshooting section above

The Mistral AI integration provides **real AI inference** - no fallbacks, no fake data. Your app will now generate actual intelligent TODO lists and project analysis using the Mistral 7B model!
