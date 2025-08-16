#!/usr/bin/env python3
"""
Fix the tokenizer.json encoding issue
"""

import os
import json
import shutil

def fix_tokenizer_encoding():
    print("🔧 Fixing tokenizer.json encoding issue...")
    
    model_path = "../ai_models/phi-2"
    tokenizer_path = os.path.join(model_path, "tokenizer.json")
    
    # Backup original file
    backup_path = tokenizer_path + ".backup"
    print(f"📋 Creating backup: {backup_path}")
    shutil.copy2(tokenizer_path, backup_path)
    
    # Read with correct encoding and rewrite
    print("📖 Reading tokenizer with UTF-8 encoding...")
    try:
        with open(tokenizer_path, 'r', encoding='utf-8') as f:
            tokenizer_data = json.load(f)
        print("✅ Tokenizer data loaded successfully")
        
        # Write back with proper encoding
        print("💾 Writing tokenizer with proper encoding...")
        with open(tokenizer_path, 'w', encoding='utf-8') as f:
            json.dump(tokenizer_data, f, ensure_ascii=False, indent=2)
        
        print("✅ Tokenizer encoding fixed!")
        print(f"   - Original backed up to: {backup_path}")
        print(f"   - Fixed file: {tokenizer_path}")
        
    except Exception as e:
        print(f"❌ Error fixing tokenizer: {e}")
        # Restore backup
        print("🔄 Restoring backup...")
        shutil.copy2(backup_path, tokenizer_path)
        return False
    
    return True

if __name__ == "__main__":
    success = fix_tokenizer_encoding()
    if success:
        print("\n🎉 Tokenizer encoding fixed successfully!")
        print("Now try running the conversion script again.")
    else:
        print("\n💥 Failed to fix tokenizer encoding.")
