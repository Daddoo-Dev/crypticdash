#!/usr/bin/env python3
"""
Mistral AI Local Server
This script runs a local HTTP server that serves the Mistral 7B model for AI inference.
"""

import json
import logging
import os
import sys
from pathlib import Path
from typing import Dict, Any, Optional

try:
    from flask import Flask, request, jsonify
    from transformers import AutoTokenizer, AutoModelForCausalLM
    import torch
except ImportError as e:
    print(f"Missing required packages: {e}")
    print("Please install: pip install flask transformers torch")
    sys.exit(1)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Global variables for the model
model = None
tokenizer = None
model_loaded = False

def load_mistral_model():
    """Load the Mistral 7B model and tokenizer."""
    global model, tokenizer, model_loaded
    
    try:
        logger.info("Loading Mistral 7B model...")
        
        # Model path - adjust this to your actual model location
        model_path = "assets/ai_models/mistral/mistral-7b-instruct-v0.1-q4_k_m.gguf"
        
        if not os.path.exists(model_path):
            # Try alternative paths
            alt_paths = [
                "mistral-7b-instruct-v0.1-q4_k_m.gguf",
                "../assets/ai_models/mistral/mistral-7b-instruct-v0.1-q4_k_m.gguf",
                "./mistral-7b-instruct-v0.1-q4_k_m.gguf"
            ]
            
            for alt_path in alt_paths:
                if os.path.exists(alt_path):
                    model_path = alt_path
                    break
            else:
                raise FileNotFoundError(f"Mistral model not found. Tried: {model_path}")
        
        logger.info(f"Loading model from: {model_path}")
        
        # Load tokenizer and model
        model_name = "mistralai/Mistral-7B-Instruct-v0.1"
        
        logger.info("Loading tokenizer...")
        tokenizer = AutoTokenizer.from_pretrained(model_name)
        
        logger.info("Loading model...")
        model = AutoModelForCausalLM.from_pretrained(
            model_name,
            torch_dtype=torch.float16,
            device_map="auto",
            load_in_4bit=True,  # Use 4-bit quantization to save memory
        )
        
        model_loaded = True
        logger.info("Mistral model loaded successfully!")
        
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        model_loaded = False
        raise

def generate_text(prompt: str, max_tokens: int = 2048, temperature: float = 0.7, top_p: float = 0.9) -> str:
    """Generate text using the Mistral model."""
    if not model_loaded or model is None or tokenizer is None:
        raise RuntimeError("Model not loaded")
    
    try:
        # Format prompt for Mistral
        formatted_prompt = f"<s>[INST] {prompt} [/INST]"
        
        # Tokenize input
        inputs = tokenizer(formatted_prompt, return_tensors="pt")
        
        # Generate text
        with torch.no_grad():
            outputs = model.generate(
                inputs.input_ids,
                max_new_tokens=max_tokens,
                temperature=temperature,
                top_p=top_p,
                do_sample=True,
                pad_token_id=tokenizer.eos_token_id,
            )
        
        # Decode output
        generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # Extract only the generated part (remove input prompt)
        if formatted_prompt in generated_text:
            generated_text = generated_text.split(formatted_prompt)[1]
        
        return generated_text.strip()
        
    except Exception as e:
        logger.error(f"Text generation failed: {e}")
        raise

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model_loaded,
        'model_name': 'Mistral-7B-Instruct-v0.1'
    })

@app.route('/generate', methods=['POST'])
def generate():
    """Generate text using the Mistral model."""
    try:
        if not model_loaded:
            return jsonify({'error': 'Model not loaded'}), 503
        
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        prompt = data.get('prompt', '')
        if not prompt:
            return jsonify({'error': 'No prompt provided'}), 400
        
        max_tokens = data.get('max_tokens', 2048)
        temperature = data.get('temperature', 0.7)
        top_p = data.get('top_p', 0.9)
        
        logger.info(f"Generating text with prompt length: {len(prompt)}")
        
        # Generate text
        generated_text = generate_text(
            prompt=prompt,
            max_tokens=max_tokens,
            temperature=temperature,
            top_p=top_p
        )
        
        logger.info(f"Generated text length: {len(generated_text)}")
        
        return jsonify({
            'text': generated_text,
            'prompt_length': len(prompt),
            'generated_length': len(generated_text)
        })
        
    except Exception as e:
        logger.error(f"Generation endpoint error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/model_info', methods=['GET'])
def model_info():
    """Get information about the loaded model."""
    if not model_loaded:
        return jsonify({'error': 'Model not loaded'}), 503
    
    return jsonify({
        'model_name': 'Mistral-7B-Instruct-v0.1',
        'model_type': 'CausalLM',
        'device': str(next(model.parameters()).device) if model else 'unknown',
        'dtype': str(next(model.parameters()).dtype) if model else 'unknown'
    })

if __name__ == '__main__':
    try:
        # Load the model before starting the server
        load_mistral_model()
        
        if model_loaded:
            logger.info("Starting Mistral AI server on http://localhost:8080")
            app.run(host='0.0.0.0', port=8080, debug=False)
        else:
            logger.error("Failed to load model. Server not started.")
            sys.exit(1)
            
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Server failed to start: {e}")
        sys.exit(1)
