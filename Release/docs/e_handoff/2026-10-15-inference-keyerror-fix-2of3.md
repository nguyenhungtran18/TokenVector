# HANDOFF 2026-10-15 (xong) — KeyError `session.tkv`: 3/3 loi da sua, bien dich duoc

Tiep theo `Release/docs/e_handoff/2026-10-15-inference-repo-build-blocker.md`.

## Trang thai

| # | Loi (deu ra `.NET KeyNotFoundException: The given key was not present in the dictionary`) | Trang thai |
|---|---|---|
| 1 | `IL_LDC_OP[dtype]` voi dtype la, khong phai so (`def f() -> "str": return 0`) | DA SUA — bao `SyntaxError` ro rang |
| 2 | `tern_temp_of_id[nid]` — LICM viet lai AST (`_licm_viet_node` tao node MOI qua `mk4`), ternary moi chua tung duoc first-pass dang ky temp (`mask[qi*mskv + min(kj, mskv-1)]` trong vong long) | DA SUA — cap temp theo nhu cau trong `_expr_ternary` |
| 3 | `__slice<nid>_start` chua khai bao — LICM viet lai node `slice` (nid moi), temp cu theo nid cu (`_declare_slice_temps`) | DA SUA — cap temp theo nhu cau trong `compile_slice` (slicing.tkv), giong loi 2 |

## Repro toi gian (da kiem chung)

```python
# Loi 1: bao loi ro (da sua)
def f() -> "str":
    return 0
# -> il_codegen: khong the dung hang so so '0' cho kieu 'str' ...

# Loi 2: bien dich duoc (da sua)
s = s + mask[qi * mskv + min(kj, mskv - 1)]   # trong 2 vong for long nhau
```

File test: `C:\Users\Admin\AppData\Local\Temp\opencode\bsec\*.py`
(`repro.tkv`, `nz.tkv`, `idx*.py`, `nest*.py`, ...), script bisect:
`bisect_class.py`, `keeps*.py`, `shrink*.py`, `ddmin_lines.py`, `bis_method*.py`.

## File da sua (da go het marker `[DBG]`, diff sach)

- `Release/compiler_bootstrap/compiler/il_codegen.tkv`:
  - `_expr_num`: `if dtype not in IL_LDC_OP: raise SyntaxError(...)` (loi 1)
  - `_expr_ternary`: tra `tern_temp_of_id` bang `.get` + cap temp theo nhu cau
    qua `ctx.locals_decl.append(...)` (loi 2, an toan vi `.locals init`
    sinh SAU codegen — giong cach LICM tu cap `__licmN`)
- `Release/compiler_bootstrap/tkv_compile.tkv`: khoi phuc thut le (do marker
  truoc do lam lech 1 dong trong vong `while pending_monomorphize`)
- `Release/compiler_src/tkvc_main.tkv`: da khoi phuc tu backup (bo patch
  `import traceback` / `raise` thu nghiem)
- `Release/compiler_bootstrap/compiler/il_features/control_flow.tkv`: sach
  (bo patch tat LICM / marker `for:` thu nghiem)

Compiler hien tai (`dist/tkvc-tv.exe`) da build tu source tren
(`vong.exe` → `IL_IDENTICAL` 2 vong lien tiep).

## Viec con lai (theo thu tu)

1. ~~Sua loi 3~~ — XONG (2026-10-15). `session.tkv` bien dich duoc:
   `dist\tkvc-tv.exe tv/runtime/session.tkv sess.exe _tv_module_probe`
   → `[tkvc] da dich`. Da sua 2 typo repo phat hien nho loi ro:
   `_imod(rem, sizes)[red[i]]` → `_imod(rem, sizes[red[i]])` (tuong tu
   `_idiv`) va 4 cho `.pop(i + 1)` → gan ra bien tam truoc.
   (Sua truc tiep `D:\TokenVector.Inference\tv\runtime\session.tkv`;
   chu y repo nay con nhieu ban copy session.tkv khac.)
2. Chay `tools\testkit_gate.ps1` — XONG: 125/125, NEG 31/31, khong regression.
   `tools\vong.exe` — `IL_IDENTICAL` (on dinh).
3. Commit + push (chi `compiler_bootstrap/...`, `dist/tkvc-tv.exe`, handoff).
4. Bao repo Inference chay lai `tools\run_cases.ps1`.

## Bai hoc

- `.NET KeyNotFoundException` trong compiler nay ≈ tra dict tho bang `[]`.
  Cach tim nhanh nhat: them `raise` tran tam de .NET in stack trace day du
  (ten ham `TKVApp.*` thay vi mo file 2.9 MB).
- `vong.exe` chi can chay 1 vong; vong 2 chi khi `IL KHAC NHAU`.
- TokenVector khong ho tro `import x as y`, `str(expr)` truc tiep, `pass`
  trong class body; file bootstrap dung LF (git checkout ra CRLF — phai
  chuan hoa truoc khi sua neu khong vong bao loi dong la).
