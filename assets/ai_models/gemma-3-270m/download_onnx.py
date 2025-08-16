#!/usr/bin/env python3
"""
Search for and download pre-converted ONNX models for Gemma 3 270M
"""

from huggingface_hub import HfApi, list_models
import requests
import os

def search_onnx_models():
    """Search for pre-converted ONNX models"""
    
    print("🔍 Searching for pre-converted ONNX models...")
    
    # Search for Gemma 3 270M ONNX models
    api = HfApi()
    
    # Search for models with "gemma" and "onnx" in the name
    models = list(list_models(
        search="gemma-3-270m onnx",
        limit=20
    ))
    
    print(f"Found {len(models)} potential models:")
    
    onnx_models = []
    for model in models:
        if "onnx" in model.modelId.lower():
            print(f"  - {model.modelId}")
            onnx_models.append(model.modelId)
    
    return onnx_models

def check_model_files(model_id):
    """Check what files are available in a model"""
    
    print(f"\n📁 Checking files in {model_id}...")
    
    try:
        api = HfApi()
        files = api.model_info(model_id).siblings
        
        print("Available files:")
        for file in files:
            size_mb = file.size / (1024*1024) if file.size else "Unknown"
            print(f"  - {file.rfilename} ({size_mb} MB)")
            
        # Check if it has ONNX files
        has_onnx = any("onnx" in file.rfilename.lower() for file in files)
        has_tokenizer = any("tokenizer" in file.rfilename.lower() for file in files)
        has_config = any("config" in file.rfilename.lower() for file in files)
        
        if has_onnx and has_tokenizer and has_config:
            print("✅ This model has all required files!")
            return True
        else:
            print("❌ Missing required files")
            return False
            
    except Exception as e:
        print(f"Error checking model: {e}")
        return False

def download_model(model_id, target_dir="."):
    """Download a model to the target directory"""
    
    print(f"\n📥 Downloading {model_id}...")
    
    try:
        from huggingface_hub import snapshot_download
        
        # Download the model
        local_dir = snapshot_download(
            repo_id=model_id,
            local_dir=target_dir,
            local_dir_use_symlinks=False
        )
        
        print(f"✅ Model downloaded to: {local_dir}")
        return True
        
    except Exception as e:
        print(f"❌ Error downloading model: {e}")
        return False

def main():
    """Main function"""
    
    print("=" * 60)
    print("🔍 Gemma 3 270M ONNX Model Finder")
    print("=" * 60)
    
    # Search for ONNX models
    onnx_models = search_onnx_models()
    
    if not onnx_models:
        print("\n❌ No pre-converted ONNX models found")
        print("\n💡 Alternative approaches:")
        print("1. Use the Safetensors model directly (requires different integration)")
        print("2. Try a different model (Phi-2, TinyLlama, etc.)")
        print("3. Use cloud-based AI instead of local models")
        return
    
    # Check each model
    for model_id in onnx_models:
        if check_model_files(model_id):
            print(f"\n🎯 Found suitable model: {model_id}")
            
            # Ask if user wants to download
            response = input(f"\nDownload {model_id}? (y/n): ").lower().strip()
            
            if response in ['y', 'yes']:
                if download_model(model_id):
                    print(f"\n🎉 Successfully downloaded {model_id}")
                    print("You can now use this model in CrypticDash!")
                    break
                else:
                    print(f"Failed to download {model_id}")
            else:
                print(f"Skipping {model_id}")
    
    print("\n" + "=" * 60)
    print("🔍 Search completed!")

if __name__ == "__main__":
    main()
