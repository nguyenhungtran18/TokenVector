# TokenVector — Release (100% TokenVector)

Ban phat trien **ngon ngu TokenVector**: compiler tu-host, nguon cua no, bo test,
va cac cong cu viet bang TokenVector. Khong co Python nao o day.

## Cay thu muc

| Thu muc | So file | Vai tro |
|---|---:|---|
| `compiler_bootstrap/` | 132 | **NGUON COMPILER TU-HOST.** Day la 132 file ma `compiler_src/ds_gop.txt` tro toi. Gop lai roi tu bien dich chinh no (`tools/vong.exe` -> `IL_IDENTICAL`) |
| `compiler_src/` | 10 | `ds_gop.txt` (manifest 132 dong) + `feature_can.txt` + 8 file seed lich su |
| `dist/` | 2 | `tkvc-tv.exe` (compiler) + `bin/tkv_guide.exe` |
| `tests/` | 162 | 119 test chap nhan + 31 test am + `tkv_test_lib.tkv` |
| `tests_suite/` | 445 | 154 case `.ca` + 203 mau vao |
| `tools/` | 19 | Cong + gate (xem bang duoi) |
| `examples/`, `projects/` | 27 | Chuong trinh TokenVector vi du / thuc te |
| `docs/` | 6 | `REFERENCE.md` la tai lieu tham chieu duy nhat |

## Bien dich mot file

```powershell
cd <duong-dan>\Release
dist\tkvc-tv.exe demo.tkv demo.exe run     # CLI positional: <nguon> <ra> <entry>
.\demo.exe
```

> `run()` tra `"i32"` ⇒ gia tri do la **exit code** cua tien trinh (nhu
> `sys.exit(1)` cua Python). Tra `"str"` hoac tuple thi duoc in ra.

## Cong go

Tu goc ban nay (khong can Python, khong can repo khac):

```powershell
# 1. Gate chinh - 119 test + 31 test am
.\tools\testkit_gate.ps1

# 2. Vong tu-host: bien dich compiler roi bien dich lai chinh no
#    TU DICH TRUOC: dist\tkvc-tv.exe tools\vong.tkv tools\vong.exe main
.\tools\vong.exe

# 3. Quy tac con
.\tools\lint_rules_gate.ps1

# 4. Phan tich nguon (da chuyen sang TokenVector)
.\dist\tkvc-tv.exe tools\dang_ky_gate.tkv build\dk.exe run   ; .\build\dk.exe
.\dist\tkvc-tv.exe tools\gen_builtin_ref.tkv build\gr.exe run; .\build\gr.exe --check
.\dist\tkvc-tv.exe tools\scan_container.tkv build\sc.exe run <thu-muc>
```

### Cong KHONG co trong ban nay (va ly do)

| Cong | Ly do - can thu ben ngoai |
|---|---|
| `ext_smoke.ps1` | Bien dich `D:\TokenVector.Inference` + `D:\TokenVector.Data` bang **compiler Python bootstrap** (`dist\tkvc.exe`). Ban nay khong co compiler do |
| `py2tkv_gate.ps1` | Fixture `.py` nam o repo `TokenVector.TestOracle` |
| `py2tkv_corpus.ps1` | Cong do CHINH file Python |

## Tai lieu (trong `docs/`)

| File | Noi dung |
|---|---|
| `docs/REFERENCE.md` | **Tham chieu duy nhat.** §2 moi builtin kem cu phap + khac biet Python; §7 danh muc ten sinh tu dong |
| `docs/ARCHITECTURE.md` | Cay thu muc + cach compiler tu dung lai chinh no |
| `docs/HANDBOOK.vi.md` | Cam nang lap trinh (tieng Viet) |
| `docs/CLAUDE.md` | Quy tac lam viec trong thu muc nay |
| `docs/llms.txt` | Ban rut gon danh cho LLM |

## Mot diem can biet khi dung

**1. Nguon compiler la TokenVector THUAN — da loai CPython het (2026-10-12).**

132 file trong manifest deu la TokenVector that. Truoc do co 6 khoi
`if __tkv_chi_cpython__:` trong `tkv_compile.tkv` va `tkv_ilasm.tkv` (shim
`os`/`pathlib`/`subprocess`, ham `extract_program`/`transpile_file`/...). Chúng
chi ton tai de mot file `.tkv` chay duoc tren **hai** the gioi: TokenVector
bien dich, CPython chay truc tiep de doi chieu. Nay phia CPython da tach sang
repo `TokenVector.CompilerPy` — noi co **ban `tkv_compile.tkv` rieng** va khong
can co che bo qua (duoi CPython co chi la bien `True`). Nen da xoa ca 320 dong
do, kem ca co che nhan dien `_la_khoi_chi_cpython`.

Con lai `@__tkv_cpython_only__` (27 ham) - van con, vi no danh dau ham CPython
rieng bi giu nguyen de chay khi kiem chung bang CPython.

**2. Compiler tu-host co loi khong on dinh ve duong dan.** `AccessViolationException`
(khong phai loi bao loi sach) khi bien dich nguon gop o mot so duong dan. Da
tai lap, **khong don dep theo do dai** — `...Relea` len 20 crash, `...Releas`
len 21 lai chay. Do do:
- Gate (`testkit_gate.ps1`) chay xanh o day.
- `vong.exe` co the bao loi `LOI dich bang ... (ma -1073741819)`. Neu vay, **doi
  ten thu muc cho ngan hon roi chay lai** — `C:\R` da tao `IL_IDENTICAL` o diem
  do. Day la loi con nghi trong compiler, chua xac dinh nguyen nhan goc.

## De biet them

`docs/REFERENCE.md` — tai lieu tham chieu duy nhat cua ngon ngu.