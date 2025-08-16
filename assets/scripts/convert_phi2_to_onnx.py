#!/usr/bin/env python3
"""
Conversion script for Microsoft Phi-2 to ONNX format
Based on the existing Gemma conversion template
"""

import os
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
import json

def convert_phi2_to_onnx():
    """Convert Microsoft Phi-2 from Safetensors to ONNX format"""
    
    print("🚀 Starting Microsoft Phi-2 to ONNX conversion...")
    
    # Model path (phi-2 directory)
    model_path = "../ai_models/phi-2"
    
    # Add verbose logging
    print(f"🔍 Model path: {os.path.abspath(model_path)}")
    print(f"🔍 Current working directory: {os.getcwd()}")
    
    # List all files in the model directory
    print("📁 Files in model directory:")
    try:
        for file in os.listdir(model_path):
            file_path = os.path.join(model_path, file)
            if os.path.isfile(file_path):
                size = os.path.getsize(file_path) / (1024 * 1024)  # MB
                print(f"   - {file} ({size:.1f} MB)")
            else:
                print(f"   - {file} (directory)")
    except Exception as e:
        print(f"   ❌ Error listing directory: {e}")
    
    try:
        print("\n📖 Loading Microsoft Phi-2 model and tokenizer...")
        
        # Load the model and tokenizer from local files
        # Note: The files have different names than expected
        print(f"🔍 Attempting to load model from: {model_path}")
        print(f"🔍 CUDA available: {torch.cuda.is_available()}")
        print(f"🔍 Device map: {'auto' if torch.cuda.is_available() else 'cpu'}")
        
        print("🔍 Loading model...")
        print("🔍 This may take several minutes for large models...")
        
        # Add timeout and progress tracking
        import time
        start_time = time.time()
        
        # Add memory monitoring
        import psutil
        process = psutil.Process()
        initial_memory = process.memory_info().rss / (1024 * 1024)  # MB
        print(f"🔍 Initial memory usage: {initial_memory:.1f} MB")
        
        # Add progress indicator
        print("🔍 Starting model load...")
        
        try:
            print("🔍 About to call AutoModelForCausalLM.from_pretrained...")
            print("🔍 Parameters:")
            print(f"   - model_path: {model_path}")
            print(f"   - torch_dtype: float32")
            print(f"   - device_map: {'auto' if torch.cuda.is_available() else 'cpu'}")
            print(f"   - use_cache: False")
            print(f"   - local_files_only: True")
            print(f"   - low_cpu_mem_usage: True")
            print(f"   - offload_folder: temp_offload")
            
            print("🔍 Calling from_pretrained...")
            
            # Try to add more granular logging by checking what transformers is doing
            print("🔍 Checking if model directory is valid...")
            if not os.path.exists(model_path):
                raise FileNotFoundError(f"Model path does not exist: {model_path}")
            
            print("🔍 Checking config.json...")
            config_path = os.path.join(model_path, "config.json")
            if os.path.exists(config_path):
                with open(config_path, 'r') as f:
                    config_content = f.read()
                print(f"🔍 Config.json content (first 200 chars): {config_content[:200]}...")
            else:
                print("❌ config.json not found!")
            
            print("🔍 About to call from_pretrained - this may hang...")
            
            # Try to add a timeout mechanism using threading
            import threading
            import queue
            
            result_queue = queue.Queue()
            exception_queue = queue.Queue()
            
            def load_model_in_thread():
                try:
                    print("🔍 Starting model load in background thread...")
                    model = AutoModelForCausalLM.from_pretrained(
                        model_path,
                        torch_dtype=torch.float16,  # Use float16 to reduce memory usage
                        device_map="cpu",  # Force CPU to avoid GPU memory issues
                        use_cache=False,  # Disable cache for ONNX export
                        local_files_only=True,  # Only use local files
                        low_cpu_mem_usage=True,  # Reduce memory usage
                        offload_folder="temp_offload",  # Offload to disk if needed
                        max_memory={0: "8GB"},  # Limit memory usage to 8GB
                        load_in_8bit=False,  # Don't use 8-bit quantization
                        load_in_4bit=False,  # Don't use 4-bit quantization
                        attn_implementation="eager"  # Use eager attention for memory efficiency
                    )
                    result_queue.put(model)
                    print("🔍 Model loaded successfully in background thread!")
                except Exception as e:
                    exception_queue.put(e)
                    print(f"❌ Model loading failed in background thread: {e}")
            
            # Start model loading in background thread
            model_thread = threading.Thread(target=load_model_in_thread)
            model_thread.daemon = True
            model_thread.start()
            
            # Wait for result with timeout
            print("🔍 Waiting for model to load (60 second timeout)...")
            try:
                model = result_queue.get(timeout=60)
                print("🔍 Model loaded successfully!")
            except queue.Empty:
                print("❌ Model loading timed out after 60 seconds")
                raise TimeoutError("Model loading timed out after 60 seconds")
            except Exception as e:
                print(f"❌ Model loading failed: {e}")
                raise
            load_time = time.time() - start_time
            print(f"✅ Model loaded successfully in {load_time:.1f} seconds")
        except Exception as e:
            load_time = time.time() - start_time
            print(f"❌ Model loading failed after {load_time:.1f} seconds")
            print(f"❌ Exception type: {type(e).__name__}")
            print(f"❌ Exception message: {str(e)}")
            print(f"❌ Full exception details:")
            import traceback
            traceback.print_exc()
            raise
        
        print("🔍 Loading tokenizer...")
        tokenizer = AutoTokenizer.from_pretrained(
            model_path,
            local_files_only=True  # Only use local files
        )
        
        # Create a simple wrapper for ONNX export
        class SimplePhi2Wrapper(torch.nn.Module):
            def __init__(self, model):
                super().__init__()
                self.model = model
                
            def forward(self, input_ids):
                # Simple forward pass without complex attention mechanisms
                outputs = self.model.model(input_ids=input_ids)
                return outputs.last_hidden_state
        
        print(f"✅ Model loaded successfully!")
        print(f"   - Model type: {type(model).__name__}")
        print(f"   - Tokenizer type: {type(tokenizer).__name__}")
        print(f"   - Model parameters: {sum(p.numel() for p in model.parameters()):,}")
        
        # Create a simplified wrapper model for ONNX export
        print("🔧 Creating simplified wrapper for ONNX export...")
        wrapper_model = SimplePhi2Wrapper(model)
        wrapper_model.eval()
        
        # Create dummy input for ONNX export
        print("🔧 Creating dummy input for ONNX export...")
        
        # Get vocabulary size from tokenizer
        vocab_size = tokenizer.vocab_size
        print(f"   - Vocabulary size: {vocab_size:,}")
        
        # Create dummy input (batch_size=1, sequence_length=128)
        dummy_input = torch.randint(0, vocab_size, (1, 128))
        print(f"   - Input shape: {dummy_input.shape}")
        
        # Convert to ONNX
        print("🔄 Converting to ONNX format...")
        
        output_path = os.path.join(model_path, "model.onnx")
        
        # Use traditional ONNX exporter with simplified wrapper
        torch.onnx.export(
            wrapper_model,
            dummy_input,
            output_path,
            input_names=['input_ids'],
            output_names=['last_hidden_state'],
            dynamic_axes={
                'input_ids': {0: 'batch_size', 1: 'sequence_length'},
                'last_hidden_state': {0: 'batch_size', 1: 'sequence_length'}
            },
            opset_version=9,  # Use ONNX opset 9 for compatibility with ONNX Runtime 1.4.1
            do_constant_folding=True,
            export_params=True,
            verbose=False
        )
        
        print(f"✅ ONNX conversion completed!")
        print(f"   - Output file: {output_path}")
        
        # Verify the ONNX file was created
        if os.path.exists(output_path):
            file_size = os.path.getsize(output_path) / (1024 * 1024)  # Convert to MB
            print(f"   - File size: {file_size:.1f} MB")
        else:
            print("❌ Error: ONNX file was not created!")
            return False
        
        print("✅ Conversion successful! The model should now work with ONNX Runtime 1.4.1")
        return True
        
    except Exception as e:
        print(f"❌ Error during conversion: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = convert_phi2_to_onnx()
    if success:
        print("\n🎉 Phi-2 ONNX conversion completed successfully!")
        print("The model should now work with your app.")
    else:
        print("\n💥 Conversion failed. Check the error messages above.")
