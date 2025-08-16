# Phi-2 Model for CrypticDash

## Download Instructions

The Phi-2 model is not directly available as an ONNX file from HuggingFace.
You have several options:

### Option 1: Convert from PyTorch (Recommended)
1. Install PyTorch: `pip install torch transformers`
2. Download Phi-2: `python -c "from transformers import AutoModel; AutoModel.from_pretrained('microsoft/phi-2')"`
3. Convert to ONNX using the conversion script below

### Option 2: Use Pre-converted Model
Download from: https://huggingface.co/microsoft/phi-2-onnx

### Option 3: Use Smaller Alternative
Consider using a smaller model like:
- Microsoft Phi-1.5 (1.3GB)
- TinyLlama (1.1GB)
- GPT-2 Small (500MB)

## File Structure Required
- model.onnx (the actual model file)
- tokenizer.json (tokenizer configuration)
- config.json (model configuration)

## Conversion Script
```python
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

# Load model and tokenizer
model = AutoModelForCausalLM.from_pretrained("microsoft/phi-2", torch_dtype=torch.float16)
tokenizer = AutoTokenizer.from_pretrained("microsoft/phi-2")

# Convert to ONNX (simplified example)
dummy_input = torch.randint(0, 51200, (1, 128))
torch.onnx.export(model, dummy_input, "model.onnx", 
                  input_names=['input_ids'], 
                  output_names=['logits'],
                  dynamic_axes={'input_ids': {0: 'batch_size', 1: 'sequence_length'},
                               'logits': {0: 'batch_size', 1: 'sequence_length'}})
```
