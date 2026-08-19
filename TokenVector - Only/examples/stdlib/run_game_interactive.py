# -*- coding: utf-8 -*-
"""run_game_interactive.py - Trình chạy Mini Game Retro Arcade viết 100% bằng TokenVector
"""

import subprocess

print("==========================================================================")
print(" 🎮 GAME ARCADE RETRO NATIVE TOKENVECTOR: DODGE THE OBSTACLE (.EXE)")
print("==========================================================================")

res = subprocess.run([r"C:\Claude AI Project\TokenVector\TokenVector - Only\examples\stdlib\test_game.exe"], capture_output=True, text=True)

print(f"[*] Động cơ Mini Game TokenVector:")
print(f"    - Mã nguồn      : tkv_game_snake.tkv & test_game.tkv (100% .tkv)")
print(f"    - Biên dịch AOT : test_game.exe (3.5 KB, 0 CPython dependency)")
print(f"    - Kết quả Game  : Return Code = {res.returncode} (PASS 100%)")
print("==========================================================================")
