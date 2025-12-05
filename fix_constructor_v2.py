file_path = r"c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\gemini_service.dart"

with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

# We want to replace lines 130 to 176 (0-indexed: 130 to 176)
# Line 131 in file is index 130.
# Line 176 in file is index 175.

# Let's verify the content to be sure.
start_idx = 130
end_idx = 176 # This will be the line AFTER the last line to remove if we use slice [start:end]

# Check if line 130 starts with "  GeminiService"
if "GeminiService" not in lines[start_idx]:
    print(f"Line {start_idx+1} does not look like GeminiService: {lines[start_idx]}")
    # Search for it
    for i, line in enumerate(lines):
        if "GeminiService({String? instanceId})" in line:
            start_idx = i
            break

# Search for the end of the old constructor.
# It ends before "  // ===================== API PÚBLICA ====================="
for i in range(start_idx, len(lines)):
    if "API PÚBLICA" in lines[i]:
        end_idx = i
        break

# The line before "API PÚBLICA" should be empty or contain "  }"
# We want to keep the empty line if possible, or just ensure the constructor closes.

print(f"Replacing from line {start_idx+1} to {end_idx}")

new_constructor = """  GeminiService({String? instanceId})
    : _instanceId = instanceId ?? _genId() {
    // ??? v7.6.64: Inicializar módulos refatorados
    _llmClient = LlmClient(instanceId: _instanceId);
    _worldStateManager = WorldStateManager(llmClient: _llmClient);
    _scriptValidator = ScriptValidator(llmClient: _llmClient);
  }

"""

new_lines = lines[:start_idx] + [new_constructor] + lines[end_idx:]

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
