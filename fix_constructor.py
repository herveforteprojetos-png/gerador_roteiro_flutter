import re

file_path = r"c:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\gemini_service.dart"

with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# Regex to match the constructor
# It starts with GeminiService({String? instanceId})
# And ends with the closing brace of the constructor body.
# The body contains _dio.interceptors.add(...) which we want to remove.

pattern = r'GeminiService\(\{String\? instanceId\}\)\s*:\s*_instanceId\s*=\s*instanceId\s*\?\?\s*_genId\(\),\s*_dio\s*=\s*Dio\(\s*BaseOptions\([^)]+\),\s*\)\s*\{[^}]*?_dio\.interceptors\.add\([^;]+;\s*\s*\}'

# This regex is getting complicated and might fail due to newlines/formatting.
# Let's try to find the start and end indices manually.

start_marker = "GeminiService({String? instanceId})"
end_marker = "_dio.interceptors.add("

start_idx = content.find(start_marker)
if start_idx == -1:
    print("Could not find constructor start")
    exit(1)

# Find the end of the constructor. It ends after the interceptors block.
# The interceptors block ends with ); and then a closing brace } for the constructor.
# Let's look for the closing brace of the constructor.

# We can just replace the whole chunk from start_marker to the end of the interceptors block.
# But we need to be careful about where the constructor ends.

# Let's look at the file content again.
# The constructor body starts with {
# Then initializes modules.
# Then _dio.interceptors.add(...);
# Then }

# I'll search for the start, and then find the next "}" after "_dio.interceptors.add".

dio_marker = "_dio.interceptors.add"
dio_idx = content.find(dio_marker, start_idx)

if dio_idx == -1:
    print("Could not find _dio.interceptors.add")
    # Maybe it's already gone?
    # Let's check if we can just replace the initialization list.
    pass

# Let's try a simpler replacement: replace the initialization list and the body start.

new_constructor = """GeminiService({String? instanceId})
    : _instanceId = instanceId ?? _genId() {
    // ??? v7.6.64: Inicializar módulos refatorados
    _llmClient = LlmClient(instanceId: _instanceId);
    _worldStateManager = WorldStateManager(llmClient: _llmClient);
    _scriptValidator = ScriptValidator(llmClient: _llmClient);
  }"""

# We need to identify the range to replace.
# From "GeminiService({String? instanceId})"
# To the closing brace "}" of the constructor.

# Let's find the closing brace.
# It should be the first "}" after the start, but we have nested braces in Dio options and interceptors.
# So we need to count braces.

def find_closing_brace(text, start_pos):
    brace_count = 0
    found_start = False
    for i in range(start_pos, len(text)):
        if text[i] == '{':
            brace_count += 1
            found_start = True
        elif text[i] == '}':
            brace_count -= 1
            if found_start and brace_count == 0:
                return i + 1
    return -1

constructor_end = find_closing_brace(content, start_idx)

if constructor_end != -1:
    print(f"Replacing constructor from {start_idx} to {constructor_end}")
    new_content = content[:start_idx] + new_constructor + content[constructor_end:]
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
else:
    print("Could not find constructor end")
