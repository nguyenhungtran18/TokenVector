# 2026-10-16 - TokenVector.Inference: record nam sai kieu container + de nghi chan doan

Trang thai sau khi sua: `compare_rivals.tkv` chay het toan bo scenario
(`ok=500 err=0` o 4/4 lan), `inference_tests` 26/26, `gap_tests` 16/16,
`quickstart` OK, `cli.tkv` bien dich duoc.

Lien quan: `2026-10-16-inference-repo-list-alias-and-overflow-bugs.md`.


## 1. Loi REPO (da sua) - `pool` khai bao `list[i64]` nhung luu record

```tkv
class DynamicBatcher:
    pool: "list[i64]"          # <- sai, chua record InferenceSession
    def __init__(self, session: "InferenceSession", ...):
        self.pool = [session]  # <- ghi record vao container cua i64
```

Trieu chung khi doc lai `self.pool[0]` va dua vao `session.run_single(...)`:

```
System.AccessViolationException: Attempted to read or write protected memory
System.NullReferenceException
```

Da doi thanh `list[InferenceSession]`. Luu y: khai bao sai kieu container rat
de bo qua khi doc nhanh vi `pool` chi duoc dung o vai cho.


## 2. De nghi compiler: bao loi khi ghi record vao container sai kieu

`self.pool = [session]` khong can mot looi nao ca khi bien dich. Bien dich
xong, chay moi hong mem - va dong loi *"doc hoac ghi vung bao ve"* khong chi
ra file/dong nao, phai khoanh vung bang cach tach `run_single` ra chay rieng.

Neu container co `T` la class/record thi nen bat:
- gia tri literal so khong khop voi `T` (`self.pool = [0]`),
- record truyen vao container co phan tu khac `T`,
- container `list[T]`/field kieu scalar nhung duoc gan record.

Neu kho chay do la chu thich nhieu the nao, it nhat nen can bao o compile time
khi khai bao field container co `T` la record (dung de canh bao nham kieu).


## 3. Loi REPO (da sua) - worker thread va duong fallback inline chay trung request

`enqueue()` quay `_BCH_SPIN_LIMIT` (200000) lan roi tu chay request, trong khi
worker thread co the da lay request do roi. Ca hai chay tren **cung mot
session** (pool chi co 1 phien tu, arena dung chung) -> ket qua la
`err=1` rau rac (thay doi giua cac lan chay).

Da them co `_claimed` tren `BatchRequest` de mot ben giu request, va cho co
gioi han neu worker da giu (truong hop worker chua xong ma tra ve `req.result`
rong se ra `err=1` **on dinh**).

Y nghia chung: neu runtime cho phep chay song song tren cung mot object thi
nen co primitive dong bo (mutex/atomic) cho `.tkv`; hien tai chi co `&` va
`thread_spawn`, khong co cach dong bo cap nguon.


## 4. Ton tai o BEN COMPILER (chua duoc xu ly)

- **SIMD chay khong duoc**: `FileNotFoundException: System.Numerics.Vectors,
  Version=4.1.4.0`. Compiler co 13 builtin `simd_*` nhung khong copy
  assembly runtime ve thu muc chay. `Vector<>` se ra thi moi chay duoc.
- **`argv()` tra ve `[]`** - CLI khong nhan duoc tham so.
- Benchmark cua repo in ra `0.0 ms` / `infx` vi `now_ms()`, `now_us()`,
  `gc_allocated_bytes()`, `gc_counts()` dang la stub (`return 0`). Neu runtime
  co san cac ham nay thi nen expose; con khong thi phai noi ro trong tai lieu
  de nguoi dung khong lay so 0 lam ket qua that.
- **Bien dich lazy**: probe `import <module>` khong bat loi trong than ham.
  Mot lan 52/52 module "PASS" nhung ca entry point (`cli.tkv`) van bien dich
  that bai. Neu co co che verify, nen bien dich ca cac entry point chu khong
  chi module.


## VI TRI SUA TRONG SOURCE COMPILER

**Sua file modul trong `compiler_bootstrap/`, KHONG sua `build/selfhost/tv_gop.tkv`**
(`build/selfhost/tv_gop.tkv` la ban merge cua toan bo file duoi
`compiler_bootstrap/compiler/`, nen dong so ghi trong cac ghi chu cu la dong
cua file merge).

| muc                                   | file sua                                          | vi tri                                                  |
|----------------------------------------|---------------------------------------------------|---------------------------------------------------------|
| SIMD: thieu `System.Numerics.Vectors`  | `compiler_bootstrap\compiler\il_features\simd_feature.tkv` | dong **22** (`_VEC_EXTERN`), `_ensure_extern` dong ~536; kiem tra them buoc **dong goi/copy DLL** khi bien dich xong (chua tim thay file lam viec nay) |
| `argv()` tra `[]`                      | `compiler_bootstrap\compiler\il_features\stdlib_sys.tkv` | dong **9** (`sys_argv`) - docstring noi ro phai bo `.exe` o phan tu 0, kiem tra xem codegen co that su cat phan tu 0 hay khong |
| bao loi khi ghi record vao container sai kieu | `compiler_bootstrap\compiler\il_features\record_feature.tkv` | `codegen_attr_assign` dong **110**, nhanh container dong ~**173** - noi duy nhat da biet de chen kiem tra `field_dtype` voi kieu cua gia tri |
| (them) kiem tra kieu general            | `compiler_bootstrap\compiler\il_features\typecheck.tkv` | hien chi phuc vu `isinstance/issubclass/type` (dong 62-163); noi them quy tac container/phan tu deu co the dung bang chung |

Cho BUG 1/BUG 2 cua note `...list-alias-and-overflow-bugs.md` xem bang vi tri
sua o file do.