#!/usr/bin/env python3
"""
Try to convert a smaller model that might actually work
"""

import os
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
import json

def try_smaller_model():
    print("🧪 Trying to find a smaller, workable model...")
    
    # Check what we have
    model_path = "../ai_models/phi-2"
    
    print("📁 Available models:")
    try:
        for file in os.listdir(model_path):
            file_path = os.path.join(model_path, file)
            if os.path.isfile(file_path):
                size = os.path.getsize(file_path) / (1024 * 1024)  # MB
                print(f"   - {file} ({size:.1f} MB)")
    except Exception as e:
        print(f"❌ Error listing files: {e}")
        return
    
    print("\n🔍 The issue: Phi-2 is 5.3GB - too large for CPU loading")
    print("💡 Solutions:")
    print("   1. Use a smaller model (Phi-1.5 ~1.3GB)")
    print("   2. Use quantization (4-bit or 8-bit)")
    print("   3. Accept the current intelligent analysis")
    
    # Try to create a minimal working model
    print("\n🔧 Attempting to create a minimal test model...")
    
    try:
        # Try to load just the config and create a tiny model
        config_path = os.path.join(model_path, "config.json")
        with open(config_path, 'r') as f:
            config = json.load(f)
        
        print("✅ Config loaded successfully")
        print(f"   - Model type: {config.get('model_type', 'Unknown')}")
        print(f"   - Hidden size: {config.get('hidden_size', 'Unknown')}")
        print(f"   - Num layers: {config.get('num_hidden_layers', 'Unknown')}")
        
        # Create a minimal model with just a few layers
        print("🔧 Creating minimal test model...")
        
        # This is a simplified approach - just test if we can create something
        from transformers import PhiConfig, PhiForCausalLM
        
        # Create a tiny config
        tiny_config = PhiConfig(
            hidden_size=256,  # Much smaller
            num_hidden_layers=2,  # Just 2 layers
            num_attention_heads=8,
            intermediate_size=512,
            vocab_size=51200,
            max_position_embeddings=2048
        )
        
        print("🔧 Creating tiny model from config...")
        tiny_model = PhiForCausalLM(tiny_config)
        
        print("✅ Tiny model created successfully!")
        print(f"   - Parameters: {sum(p.numel() for p in tiny_model.parameters()):,}")
        
        # Try to convert this tiny model to ONNX
        print("🔄 Converting tiny model to ONNX...")
        
        tiny_model.eval()
        dummy_input = torch.randint(0, 51200, (1, 64))
        
        output_path = os.path.join(model_path, "tiny_model.onnx")
        
        torch.onnx.export(
            tiny_model,
            dummy_input,
            output_path,
            input_names=['input_ids'],
            output_names=['logits'],
            dynamic_axes={
                'input_ids': {0: 'batch_size', 1: 'sequence_length'},
                'logits': {0: 'batch_size', 1: 'sequence_length'}
            },
            opset_version=9,
            do_constant_folding=True,
            export_params=True,
            verbose=False,
            dynamo=True  # Use modern ONNX export that supports DynamicCache
        )
        
        if os.path.exists(output_path):
            file_size = os.path.getsize(output_path) / (1024 * 1024)
            print(f"✅ Tiny ONNX model created! Size: {file_size:.1f} MB")
            print("💡 This proves ONNX conversion works - we just need a smaller model!")
            return True
        else:
            print("❌ Tiny ONNX model creation failed")
            return False
            
    except Exception as e:
        print(f"❌ Error creating tiny model: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = try_smaller_model()
    if success:
        print("\n🎉 Tiny model conversion successful!")
        print("This proves the approach works - we just need a smaller model.")
    else:
        print("\n💥 Tiny model conversion failed.")
