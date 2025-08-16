#!/usr/bin/env python3
"""
Simple test script to debug Phi-2 model loading
"""

import os
import json
import time

def test_phi2_loading():
    print("🧪 Testing Phi-2 model loading step by step...")
    
    model_path = "../ai_models/phi-2"
    print(f"🔍 Model path: {os.path.abspath(model_path)}")
    
    # Test 1: Check if directory exists
    print("\n📁 Test 1: Directory check")
    if os.path.exists(model_path):
        print("✅ Directory exists")
    else:
        print("❌ Directory does not exist")
        return
    
    # Test 2: List files
    print("\n📁 Test 2: File listing")
    try:
        files = os.listdir(model_path)
        for file in files:
            file_path = os.path.join(model_path, file)
            if os.path.isfile(file_path):
                size = os.path.getsize(file_path) / (1024 * 1024)  # MB
                print(f"   - {file} ({size:.1f} MB)")
            else:
                print(f"   - {file} (directory)")
    except Exception as e:
        print(f"❌ Error listing files: {e}")
        return
    
    # Test 3: Check config.json
    print("\n📄 Test 3: Config.json check")
    config_path = os.path.join(model_path, "config.json")
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
            print("✅ Config.json loaded successfully")
            print(f"   - Model type: {config.get('model_type', 'Unknown')}")
            print(f"   - Architecture: {config.get('architectures', ['Unknown'])}")
            print(f"   - Hidden size: {config.get('hidden_size', 'Unknown')}")
            print(f"   - Num layers: {config.get('num_hidden_layers', 'Unknown')}")
        except Exception as e:
            print(f"❌ Error loading config.json: {e}")
            return
    else:
        print("❌ Config.json not found")
        return
    
    # Test 4: Check tokenizer
    print("\n🔤 Test 4: Tokenizer check")
    tokenizer_path = os.path.join(model_path, "tokenizer.json")
    if os.path.exists(tokenizer_path):
        try:
            # Try different encodings
            encodings = ['utf-8', 'utf-8-sig', 'latin-1', 'cp1252']
            tokenizer_data = None
            
            for encoding in encodings:
                try:
                    with open(tokenizer_path, 'r', encoding=encoding) as f:
                        tokenizer_data = json.load(f)
                    print(f"✅ Tokenizer.json loaded successfully with {encoding} encoding")
                    break
                except UnicodeDecodeError:
                    continue
                except Exception as e:
                    print(f"   - {encoding} encoding failed: {e}")
                    continue
            
            if tokenizer_data is None:
                print("❌ Could not load tokenizer.json with any encoding")
                return
            else:
                print(f"   - Tokenizer type: {type(tokenizer_data).__name__}")
        except Exception as e:
            print(f"❌ Error loading tokenizer.json: {e}")
            return
    else:
        print("❌ Tokenizer.json not found")
        return
    
    # Test 5: Check model index
    print("\n📋 Test 5: Model index check")
    index_path = os.path.join(model_path, "model.safetensors.index.json")
    if os.path.exists(index_path):
        try:
            with open(index_path, 'r') as f:
                index_data = json.load(f)
            print("✅ Model index loaded successfully")
            print(f"   - Total size: {index_data.get('metadata', {}).get('total_size', 'Unknown')}")
            print(f"   - Weight map keys: {len(index_data.get('weight_map', {}))}")
        except Exception as e:
            print(f"❌ Error loading model index: {e}")
            return
    else:
        print("❌ Model index not found")
        return
    
    print("\n✅ All basic tests passed!")
    print("🔍 The issue is likely in the transformers library model loading")

if __name__ == "__main__":
    test_phi2_loading()
