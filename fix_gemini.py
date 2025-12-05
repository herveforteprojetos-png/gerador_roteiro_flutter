from pathlib import Path
src = Path(r"C:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\gemini_service.corrupted.bak")
dst = Path(r"C:\Users\Guilherme\Desktop\Flutter Gerador\flutter_gerador\lib\data\services\gemini_service.cleaned.dart")
b = src.read_bytes()
try:
    text = b.decode('utf-8')
except Exception:
    text = b.decode('latin-1')
# Try to fix mojibake if UTF-8 bytes were decoded as latin-1
try:
    fixed = text.encode('latin-1').decode('utf-8')
except Exception:
    fixed = text

dst.write_text(fixed, encoding='utf-8')
print('written', dst)
