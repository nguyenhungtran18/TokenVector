with open('universal_context_compressor.tkv', 'r', encoding='utf-8') as f:
    code1 = f.read()
with open('test_universal_compressor.tkv', 'r', encoding='utf-8') as f:
    code2 = f.read()

scope = {}
exec(code1, scope)
exec(code2, scope)

res = scope['main']()
print("==================================================")
print("TOKENVECTOR UNIVERSAL AI COMPRESSOR TEST RESULT:", "PASSED (1)" if res == 1 else "FAILED (0)")
print("==================================================")

sample_prompt = """
# Deep Learning Model Trainer
import os
import torch
import torch.nn as nn

# Unnecessary verbose comments
# Line 1 comment
# Line 2 comment

def train_epoch(model, dataloader, optimizer, criterion):
    # Detailed inner loop comment
    model.train()
    total_loss = 0.0
    for batch_idx, (data, target) in enumerate(dataloader):
        optimizer.zero_grad()
        output = model(data)
        loss = criterion(output, target)
        loss.backward()
        optimizer.step()
        total_loss += loss.item()
    return total_loss
"""

compressed = scope['format_universal_ai_request']("Antigravity-Gemini", sample_prompt)
print("\n--- DEMONSTRATION OF COMPRESSED PROMPT OUTPUT ---")
print(compressed)
