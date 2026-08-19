# `__tkv_extern_class__` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cho code `.tkv` khai báo 1 class .NET ngoài qua pragma
`__tkv_extern_class__` — tạo object bằng constructor (`newobj`), gọi
instance method (`callvirt`), method có thể trả về scalar HOẶC handle
type khác (kể cả chính nó, cho phép fluent chaining) — không cần sửa file
compiler cho mỗi class .NET mới.

**Architecture:** Mở rộng ĐÚNG kiến trúc đã có của `__tkv_extern_method__`
(Phase 1)/`__tkv_extern_pinvoke__` (Phase 2): pragma dict-literal → parse
shape → validate → đăng ký ĐỘNG lúc `compile_tkv_cli`, tự gỡ (`finally`)
sau mỗi lượt build. Điểm khác biệt cốt lõi: constructor route qua
`_expr_call` (`il_codegen.py`, nhánh mới trước/cùng nhánh `if name in
records`), method route qua registry `EXPR_METHOD_CODEGEN[(handle_class,
method_name)]` sẵn có trong `record_feature.py::compile_method_call`
(KHÔNG sửa thân hàm đó) — cả 2 tái dùng type-checking pipeline hiện có qua
1 `TypeAnn` shape mới `'extern_class'`.

**Tech Stack:** Python 3 (compiler nguồn), CIL text (output), `ilasm.exe`
(.NET Framework mscorlib v4.0.30319, Windows-only toolchain).

## Global Constraints

- Chỉ **static-shaped** scope: instance method + constructor. KHÔNG
  property/generic/container/static field trên handle type (spec §"Giới
  hạn KHÔNG làm").
- Tham số/return của constructor VÀ method: scalar
  (`i32/i64/f32/f64/str`) HOẶC tên 1 handle type ĐÃ khai trong CÙNG
  `__tkv_extern_class__` (kể cả chính entry đang khai).
- Handle type KHÔNG tham gia duck-typing-inference (`dtype='inferred'`)
  — dùng làm tham số hàm top-level thiếu annotation phải raise
  `TranspileError` rõ ràng.
- Handle type KHÔNG có inheritance phía `.tkv` — không đụng
  `_field_owner_class`/`_method_owner_class`/`record_bases`.
- `is None`/`is not None` trên biến handle PHẢI hoạt động — đã xác nhận
  (Investigation §6) `_expr_null`/`ldnull` generic cho MỌI kiểu tham
  chiếu, KHÔNG cần sửa gì.
- Đăng ký động PHẢI tự gỡ (`finally`-pop) sau mỗi lượt `compile_tkv_cli`
  — không rò rỉ giữa các lần compile trong CÙNG process (nguyên tắc xuyên
  suốt Phase 1/2, đã có tiền lệ `EXPR_BUILTIN_CODEGEN`/`EXPR_BUILTIN_DTYPE`
  pop).
- Cả 2 cây (`tkv_compile.py`/`il_codegen.py`/`il_dispatch.py` gốc VÀ
  mirror `release/3.code/build/pyinstaller_src/`) sửa đồng bộ. **KHÔNG**
  rebuild `release/3.code/dist/tkvc.exe` trừ khi được yêu cầu rõ ràng.
- KHÔNG dịch riêng exception .NET, KHÔNG tự dò chữ ký qua reflection —
  người dùng tự xác minh đúng chữ ký CIL trước khi khai (nguyên tắc dự án).

---

## Bối cảnh code đã xác nhận (đọc trước khi bắt đầu Task 1)

**`tkv_compile.py`** (file gốc, 2330+ dòng):
- `_parse_extern_method_dict_literal` (parse SHAPE dict-literal, không
  validate nghiệp vụ): dòng 809-851. Key set
  `_EXTERN_METHOD_KEYS = {'name','assembly','class','method','params','returns'}`.
- Nhánh `elif` trong `_parse_program_ast` gọi hàm trên: dòng 1312-1324
  (branch `__tkv_extern_method__`), pinvoke sibling ngay sau, dòng
  1325-1337.
- `extern_assemblies`/`extern_methods`/`extern_pinvokes` khởi tạo local:
  dòng 1189-1191, threading qua `extract_program_file`/`extract_program`,
  destructure lại trong `compile_tkv_cli` dòng 2112-2114.
- `_EXTERN_DTYPE_TO_IL = {'i32':'int32','i64':'int64','f32':'float32','f64':'float64','str':'string'}`:
  dòng 903-904 (bảng dtype SCALAR — extern-class cần bảng RIÊNG cho phép
  cả handle-type name, xem Task 1).
- `_validate_and_register_extern_method`: dòng 1086-1147.
- `_make_extern_static_call_codegen`: dòng 928-958 — factory trả về
  `_codegen(args, scope, out, dtype, ctx)`, arity-check, compile từng arg
  qua `ctx['compile_expr'](arg_node, scope, out, want_dtype, ctx)` ép
  ĐÚNG dtype khai vị trí đó, emit 1 dòng
  `f'    call {il_ret_type} [{assembly}]{dotnet_class}::{method_name}({params_joined})'`.
- Setup + `finally`-pop trong `compile_tkv_cli`: dòng 2145-2160 (loop
  validate/register `extern_methods`/`extern_pinvokes`), `gen_il_program`
  call dòng 2201-2227, `finally` block dòng 2323-2330 (pop
  `EXPR_BUILTIN_CODEGEN`/`EXPR_BUILTIN_DTYPE`/`EXTERN_VOID_BUILTIN_NAMES`
  theo `registered_extern_names`/`registered_pinvoke_names`).

**`compiler/il_dispatch.py`**:
- `register_expr_builtin(name, codegen_fn, return_dtype, ...)`: dòng
  105-139. Guard trùng tên raise `ValueError` NGAY (dòng 108-118) —
  KHÔNG sửa hàm này, tái dùng nguyên.
- `EXPR_METHOD_CODEGEN` — registry `(shape_or_dtype, method_name) ->
  codegen_fn` dùng bởi `compile_method_call` (xem dưới) — tồn tại SẴN,
  KHÔNG cần tạo mới, chỉ cần đăng ký entry vào đó cho handle type.

**Record type registration** (`tkv_compile.py`):
- `record_defs: dict[record_name -> list[(field_name, dtype)]]` — chính
  là `ctx['records']`.
- `_build_record_methods(record_defs, record_methods_raw, record_bases)`:
  dòng 1652-1740, trả `(record_methods, record_method_bodies,
  record_methods_own)`.
- `Signature` object (mỗi entry `record_methods[cls][method]`): có
  `.name`, `.params` (list, mỗi phần tử có `.type_ann` là `TypeAnn`),
  `.return_type` (`TypeAnn` hoặc `None`), `.is_static`, `.is_async`.

**`compiler/il_codegen.py`**:
- `il_type_str`, nhánh `shape == 'record'`: dòng 157-161, emit
  `f'class {type_ann.dtype}'` (KHÔNG assembly-qualify — chỉ đúng cho
  class DO COMPILER TỰ SINH). Handle type cần shape MỚI
  (`'extern_class'`) để emit dạng assembly-qualified
  `f'class [{assembly}]{dotnet_class}'`.
- `_expr_call`, dòng 1668-1691 — nhánh ĐẦU TIÊN kiểm `if name in
  records:` để phát hiện constructor-call record, emit
  `f'    newobj instance void {name}::.ctor({ctor_params})'`. Nhánh
  handle-type constructor PHẢI chèn TRƯỚC hoặc CÙNG mức nhánh này (kiểm
  `name in extern_classes` trước `name in records` — 2 namespace tên
  PHẢI validate không trùng nhau lúc đăng ký, xem Task 1).

**`compiler/il_features/record_feature.py`**:
- `compile_method_call`, dòng 207-311. Dòng 231:
  `_, _, obj_ta = scope[obj_name]`. Dòng 232-237: tra
  `EXPR_METHOD_CODEGEN.get((obj_ta.shape or obj_ta.dtype, method_name))`
  — nếu KHỚP, gọi thẳng codegen đó, KHÔNG chạm phần còn lại của hàm. Đây
  là điểm cắm handle-type method — KHÔNG cần sửa `record_feature.py`.
- `_field_owner_class` (dòng 42-78) / `_method_owner_class` (dòng 81-92):
  chỉ đọc `ctx['record_bases']`/`ctx['record_methods_own']` — handle
  type KHÔNG đăng ký vào 2 dict này nên 2 hàm này KHÔNG bao giờ được gọi
  cho handle type (route qua `EXPR_METHOD_CODEGEN` bắt trước khi tới
  logic dùng 2 hàm này).

**`('null',)` / `is None`**: `compiler/il_core.py:553-556` (parser),
`compiler/il_codegen.py:1084-1087` + đăng ký dòng 2009 (`_expr_null`,
luôn emit `ldnull` bất kể `dtype`) — **đã generic cho mọi kiểu tham
chiếu, KHÔNG cần sửa gì cho task này**.

**Mirror tree**: `release/3.code/build/pyinstaller_src/tkv_compile.py`
(1670 dòng, KHÔNG đồng bộ tuyệt đối với gốc — cây tự-host riêng biệt,
đã xác nhận trôi trước đó ở phiên khác) + `compiler/il_codegen.py` +
`compiler/il_dispatch.py` cùng thư mục — PHẢI port tương ứng cuối plan
(Task 5), theo đúng cấu trúc/pattern của cây đó (không giả định giống hệt
byte-for-byte cây gốc).

**Test template**: `test/verify/extern_method_test.py`/
`extern_pinvoke_test.py` — plain script (không pytest), `fails = []` +
`check(label, cond, detail)`, compile qua `compile_tkv_cli(...)` +
`subprocess.run([exe, ...])` đối chiếu output CPython thật,
`expect_raise(label, src_text, name, exc_type)` cho case lỗi, bước
isolation (2 lần compile liên tiếp CÙNG process, khác file, CÙNG tên) là
bước **QUAN TRỌNG NHẤT**, bước compatibility (trộn với pragma khác cùng
file), dọn file `_`-prefix cuối bài.

---

### Task 1: Parse pragma shape `__tkv_extern_class__` + bảng dtype mở rộng

**Files:**
- Modify: `tkv_compile.py` (thêm hàm parse shape, khởi tạo `extern_classes`,
  thêm nhánh trong `_parse_program_ast`, thread qua các hàm
  `extract_program`/`extract_program_file`/`compile_tkv_cli` giống
  `extern_methods`)
- Test: `test/verify/extern_class_parse_test.py` (mới)

**Interfaces:**
- Consumes: pattern `_parse_extern_method_dict_literal` (dòng 809-851)
  làm mẫu.
- Produces: `extern_classes: list[dict]` — mỗi dict có shape:
  ```python
  {
      'name': str,               # tên dtype DSL mới
      'assembly': str,
      'class': str,               # tên .NET đầy đủ
      'ctor': list[str],          # list tên dtype tham số (scalar hoặc tên handle-type CÙNG pragma)
      'methods': list[dict],      # mỗi dict: {'name': str, 'params': list[str], 'returns': str}
  }
  ```
  Được các Task sau (2, 3, 4) tiêu thụ trực tiếp — KHÔNG đổi shape này ở
  các task sau.

- [ ] **Step 1: Viết test thất bại cho parse shape hợp lệ**

Tạo `test/verify/extern_class_parse_test.py`:
```python
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tkv_compile import _parse_extern_class_dict_literal, TranspileError
import ast

fails = []
def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: {detail}')

def _dict_node(src):
    tree = ast.parse(src, mode='eval')
    return tree.body

# Test 1: shape hop le, day du field
node = _dict_node("""{
    "name": "Matrix",
    "assembly": "MathNet.Numerics",
    "class": "MathNet.Numerics.LinearAlgebra.Matrix",
    "ctor": ["i32", "i32"],
    "methods": [
        {"name": "Determinant", "params": [], "returns": "f64"},
        {"name": "Transpose", "params": [], "returns": "Matrix"},
    ],
}""")
decl = _parse_extern_class_dict_literal(node)
check('parse_ok_name', decl['name'] == 'Matrix', decl)
check('parse_ok_ctor', decl['ctor'] == ['i32', 'i32'], decl)
check('parse_ok_methods_len', len(decl['methods']) == 2, decl)
check('parse_ok_method0_name', decl['methods'][0]['name'] == 'Determinant', decl)
check('parse_ok_method1_returns', decl['methods'][1]['returns'] == 'Matrix', decl)

# Test 2: ctor rong hop le
node2 = _dict_node("""{
    "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
    "ctor": [], "methods": [],
}""")
decl2 = _parse_extern_class_dict_literal(node2)
check('parse_ok_empty_ctor', decl2['ctor'] == [], decl2)
check('parse_ok_empty_methods', decl2['methods'] == [], decl2)

# Test 3: thieu key bat buoc -> TranspileError
node3 = _dict_node("""{"name": "X", "assembly": "mscorlib", "class": "System.Object"}""")
try:
    _parse_extern_class_dict_literal(node3)
    check('parse_missing_key_raises', False, 'khong raise')
except TranspileError:
    check('parse_missing_key_raises', True)

# Test 4: key la khong hop le
node4 = _dict_node("""{
    "name": "X", "assembly": "mscorlib", "class": "System.Object",
    "ctor": [], "methods": [], "bad_key": 1,
}""")
try:
    _parse_extern_class_dict_literal(node4)
    check('parse_bad_key_raises', False, 'khong raise')
except TranspileError:
    check('parse_bad_key_raises', True)

if fails:
    print(f'FAILED {len(fails)}/8:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print('OK 8/8')
```

- [ ] **Step 2: Chạy test, xác nhận FAIL vì `_parse_extern_class_dict_literal` chưa tồn tại**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_parse_test.py`
Expected: `ImportError: cannot import name '_parse_extern_class_dict_literal'`

- [ ] **Step 3: Viết `_parse_extern_class_dict_literal` trong `tkv_compile.py`**

Chèn NGAY SAU `_parse_extern_method_dict_literal` (sau dòng 851), theo
đúng style parse-shape-only (không validate nghiệp vụ ở đây — validate
nghiệp vụ là Task 3):

```python
_EXTERN_CLASS_KEYS = {'name', 'assembly', 'class', 'ctor', 'methods'}
_EXTERN_CLASS_REQUIRED = {'name', 'assembly', 'class', 'ctor', 'methods'}
_EXTERN_CLASS_METHOD_KEYS = {'name', 'params', 'returns'}
_EXTERN_CLASS_METHOD_REQUIRED = {'name', 'params', 'returns'}


def _parse_str_list_literal(node, ctx_label):
    if not isinstance(node, ast.List):
        raise TranspileError(f"{ctx_label} phai la 1 list")
    out = []
    for elt in node.elts:
        if not (isinstance(elt, ast.Constant) and isinstance(elt.value, str)):
            raise TranspileError(f"{ctx_label}: moi phan tu phai la string literal")
        out.append(elt.value)
    return out


def _parse_extern_class_method_dict_literal(node):
    if not isinstance(node, ast.Dict):
        raise TranspileError("__tkv_extern_class__'s 'methods': moi phan tu phai la 1 dict-literal")
    result = {}
    for k_node, v_node in zip(node.keys, node.values):
        if not (isinstance(k_node, ast.Constant) and isinstance(k_node.value, str)):
            raise TranspileError("__tkv_extern_class__'s method dict: key phai la string literal")
        key = k_node.value
        if key not in _EXTERN_CLASS_METHOD_KEYS:
            raise TranspileError(
                f"__tkv_extern_class__'s method dict: key {key!r} khong hop le, "
                f"chi chap nhan {sorted(_EXTERN_CLASS_METHOD_KEYS)}")
        if key == 'params':
            result[key] = _parse_str_list_literal(v_node, "__tkv_extern_class__'s method 'params'")
        else:
            if not (isinstance(v_node, ast.Constant) and isinstance(v_node.value, str)):
                raise TranspileError(f"__tkv_extern_class__'s method dict: key {key!r} phai la string literal")
            result[key] = v_node.value
    missing = _EXTERN_CLASS_METHOD_REQUIRED - set(result.keys())
    if missing:
        raise TranspileError(f"__tkv_extern_class__'s method dict thieu key bat buoc: {sorted(missing)}")
    return result


def _parse_extern_class_dict_literal(node):
    if not isinstance(node, ast.Dict):
        raise TranspileError("__tkv_extern_class__ phai la 1 list cac dict-literal")
    result = {}
    for k_node, v_node in zip(node.keys, node.values):
        if not (isinstance(k_node, ast.Constant) and isinstance(k_node.value, str)):
            raise TranspileError("__tkv_extern_class__: key phai la string literal")
        key = k_node.value
        if key not in _EXTERN_CLASS_KEYS:
            raise TranspileError(
                f"__tkv_extern_class__: key {key!r} khong hop le, "
                f"chi chap nhan {sorted(_EXTERN_CLASS_KEYS)}")
        if key == 'ctor':
            result[key] = _parse_str_list_literal(v_node, "__tkv_extern_class__'s 'ctor'")
        elif key == 'methods':
            if not isinstance(v_node, ast.List):
                raise TranspileError("__tkv_extern_class__'s 'methods' phai la 1 list")
            result[key] = [_parse_extern_class_method_dict_literal(m) for m in v_node.elts]
        else:
            if not (isinstance(v_node, ast.Constant) and isinstance(v_node.value, str)):
                raise TranspileError(f"__tkv_extern_class__: key {key!r} phai la string literal")
            result[key] = v_node.value
    missing = _EXTERN_CLASS_REQUIRED - set(result.keys())
    if missing:
        raise TranspileError(f"__tkv_extern_class__ thieu key bat buoc: {sorted(missing)}")
    return result
```

- [ ] **Step 4: Thêm nhánh parse trong `_parse_program_ast` + threading `extern_classes`**

Trong `_parse_program_ast`:
1. Dòng 1189-1191, thêm khởi tạo:
   ```python
   extern_classes = []
   ```
2. Sau nhánh `__tkv_extern_pinvoke__` (sau dòng 1337), thêm nhánh mới:
   ```python
   elif isinstance(node, ast.Assign) and len(node.targets) == 1 and \
           isinstance(node.targets[0], ast.Name) and node.targets[0].id == '__tkv_extern_class__':
       v = node.value
       if not isinstance(v, ast.List):
           raise TranspileError("__tkv_extern_class__ phai la 1 list cac dict")
       for elt in v.elts:
           extern_classes.append(_parse_extern_class_dict_literal(elt))
   ```
3. Thread `extern_classes` qua MỌI điểm mà `extern_methods` hiện đang
   được thread: return tuple của `_parse_program_ast`, các hàm gọi nó
   (`extract_program_file`/`extract_program`), và destructure lại trong
   `compile_tkv_cli` (đọc lại chính xác các dòng hiện thread
   `extern_methods` — dòng 1465, 1510, 1520, 1588/1603/1631-1632/1648,
   2112-2114 theo báo cáo investigate — và thêm `extern_classes` vào
   ĐÚNG VỊ TRÍ TƯƠNG ỨNG ở từng chỗ đó, giữ nguyên thứ tự tham số nếu là
   tuple).

- [ ] **Step 5: Chạy lại test parse, xác nhận PASS**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_parse_test.py`
Expected: `OK 8/8`

- [ ] **Step 6: Chạy regression nhanh (import-level) đảm bảo không vỡ threading cũ**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_method_test.py && python test/verify/extern_pinvoke_test.py`
Expected: cả 2 vẫn PASS y hệt như trước (không đổi hành vi `extern_methods`/`extern_pinvokes`).

- [ ] **Step 7: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add tkv_compile.py test/verify/extern_class_parse_test.py
git commit -m "feat(compiler): parse __tkv_extern_class__ pragma shape (Task 1, extern-class)"
```

---

### Task 2: Tích hợp type-system — `TypeAnn` shape `'extern_class'`

**Files:**
- Modify: `compiler/il_codegen.py` (`il_type_str`, `_infer_dtype`, biến
  ctx `extern_classes`/`extern_class_defs`)
- Modify: `tkv_compile.py` (`compile_tkv_cli` — build `extern_class_defs`
  dict từ `extern_classes` list, đưa vào `ctx`)
- Test: `test/verify/extern_class_typesystem_test.py` (mới)

**Interfaces:**
- Consumes: `extern_classes: list[dict]` (Task 1's output shape).
- Produces:
  - `ctx['extern_class_defs']: dict[handle_name -> decl_dict]` — decl_dict
    là chính dict gốc từ pragma (`{'name','assembly','class','ctor','methods'}`),
    dùng bởi Task 3/4 để tra `assembly`/`class`/`ctor`/`methods` theo tên
    handle type.
  - `il_type_str` nhánh mới: khi `type_ann.shape == 'extern_class'`, emit
    `f'class [{assembly}]{dotnet_class}'` (tra `assembly`/`dotnet_class`
    từ `ctx['extern_class_defs'][type_ann.dtype]` — cần truyền `ctx`
    xuống `il_type_str` nếu hàm hiện tại chưa nhận `ctx`, xác nhận chữ ký
    thật của `il_type_str` lúc implement và điều chỉnh call site tương
    ứng nếu cần thêm tham số).
  - `_infer_dtype` nhận diện: khi 1 tên biến/biểu thức có
    `TypeAnn(shape='extern_class', dtype=handle_name)`, trả về đúng
    `TypeAnn` đó (không rơi về `None`/lỗi) — tương tự cách `_infer_dtype`
    đã xử lý `shape='record'` hiện có (đọc code hiện tại quanh nhánh
    `shape == 'record'` trong `_infer_dtype` làm mẫu, áp dụng pattern y
    hệt cho `'extern_class'`).

- [ ] **Step 1: Viết test thất bại — khai biến kiểu handle type qua annotation phải parse đúng dtype**

Tạo `test/verify/extern_class_typesystem_test.py`:
```python
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tkv_compile import compile_tkv_cli, TranspileError

fails = []
def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: {detail}')

HERE = Path(__file__).parent

src = '''
__tkv_extern_class__ = [
    {
        "name": "Sb",
        "assembly": "mscorlib",
        "class": "System.Text.StringBuilder",
        "ctor": [],
        "methods": [],
    },
]

def make() -> Sb:
    s: Sb = Sb()
    return s

def main() -> None:
    x: Sb = make()
    print("ok")
'''

tmp = HERE / '_extern_class_types_pos.tkv'
tmp.write_text(src, encoding='utf-8')
try:
    exe = compile_tkv_cli(str(tmp), out_exe=str(HERE / '_extern_class_types_pos.exe'), entry_name='run_x')
    check('typesystem_build_ok', exe is not None, 'compile khong tra ve exe path')
except Exception as e:
    check('typesystem_build_ok', False, f'{type(e).__name__}: {e}')

# Reject: dung ten Sb chua khai
src_bad = '''
def f(x: Sb) -> None:
    pass
'''
tmp_bad = HERE / '_extern_class_types_bad.tkv'
tmp_bad.write_text(src_bad, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp_bad), out_exe=str(HERE / '_extern_class_types_bad.exe'), entry_name='run_x')
    check('typesystem_unknown_type_raises', False, 'khong raise')
except TranspileError:
    check('typesystem_unknown_type_raises', True)
except Exception as e:
    check('typesystem_unknown_type_raises', False, f'raise sai loai: {type(e).__name__}')

for p in HERE.glob('_extern_class_types_*'):
    p.unlink()

if fails:
    print(f'FAILED {len(fails)}/2:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print('OK 2/2')
```

- [ ] **Step 2: Chạy test, xác nhận FAIL** (annotation `Sb` chưa được compiler nhận diện là kiểu hợp lệ)

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_typesystem_test.py`
Expected: FAIL ở `typesystem_build_ok` (lỗi kiểu "kieu Sb khong xac dinh" hoặc tương tự)

- [ ] **Step 3: Trong `compile_tkv_cli`, build `extern_class_defs` và đưa vào `ctx`**

Ngay sau đoạn destructure `extern_classes` (Task 1 Step 4), thêm:
```python
extern_class_defs = {}
for _decl in extern_classes:
    if _decl['name'] in extern_class_defs:
        raise TranspileError(
            f"__tkv_extern_class__: ten {_decl['name']!r} khai bao TRUNG LAP "
            f"trong cung 1 pragma")
    extern_class_defs[_decl['name']] = _decl
```
Đưa `extern_class_defs` vào `ctx` dict truyền cho `gen_il_program` (đọc
lại chính xác cách `ctx` được xây dựng trong `compile_tkv_cli` hiện tại —
tìm điểm tạo `ctx = {...}` hoặc `ctx.update({...})` trước lời gọi
`gen_il_program`, thêm key `'extern_class_defs': extern_class_defs` vào
đó).

- [ ] **Step 4: Đọc annotation kiểu — nới lỏng parser kiểu để chấp nhận tên handle type**

Nơi compiler hiện phân giải 1 annotation kiểu (chuỗi tên) thành
`TypeAnn` — thường là nơi kiểm tra "tên này có trong `record_defs` không,
nếu có thì `TypeAnn(shape='record', dtype=tên)`". Thêm 1 nhánh SONG SONG:
nếu tên KHÔNG có trong `record_defs` NHƯNG CÓ trong `extern_class_defs`
→ `TypeAnn(shape='extern_class', dtype=tên)`. Đọc kỹ hàm phân giải
annotation hiện tại (tìm nơi raise lỗi "kieu X khong xac dinh" hoặc tương
tự để xác định đúng điểm chèn) trước khi sửa — giữ nguyên thứ tự ưu tiên
(scalar builtin trước, rồi record, rồi extern_class, rồi lỗi).

- [ ] **Step 5: `il_type_str` — nhánh `shape == 'extern_class'`**

Trong `compiler/il_codegen.py`, cạnh nhánh `shape == 'record'` (dòng
157-161), thêm:
```python
    if type_ann.shape == 'extern_class':
        decl = ctx['extern_class_defs'][type_ann.dtype]
        return f"class [{decl['assembly']}]{decl['class']}"
```
Nếu `il_type_str` hiện KHÔNG nhận `ctx` làm tham số, thêm tham số
`ctx=None` vào chữ ký và cập nhật MỌI call site để truyền `ctx` qua (xác
nhận số lượng call site thật trước khi sửa — nếu quá nhiều, cân nhắc
truyền qua 1 biến module-level tạm thời được set/reset trong
`compile_tkv_cli` giống pattern `EXPR_BUILTIN_CODEGEN`, ghi rõ trong báo
cáo implementer nếu chọn hướng này).

- [ ] **Step 6: `_infer_dtype` — nhận diện handle type**

Tìm nhánh xử lý `shape == 'record'` trong `_infer_dtype`
(`compiler/il_codegen.py`), thêm xử lý tương tự cho `shape ==
'extern_class'` — copy đúng pattern (record hiện tại trả `TypeAnn` gốc
khi biến/biểu thức có shape đó, không suy diễn thêm gì khác).

- [ ] **Step 7: Chạy lại test, xác nhận PASS**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_typesystem_test.py`
Expected: `OK 2/2`

- [ ] **Step 8: Regression Task 1 + extern_method + extern_pinvoke + duck-typing**

Run:
```bash
cd "D:\Claude AI Project\TokenVector"
python test/verify/extern_class_parse_test.py
python test/verify/extern_method_test.py
python test/verify/extern_pinvoke_test.py
python test/verify/duck_typing_infer_test.py
```
Expected: tất cả PASS, không hồi quy.

- [ ] **Step 9: Commit**

```bash
git add compiler/il_codegen.py tkv_compile.py test/verify/extern_class_typesystem_test.py
git commit -m "feat(compiler): TypeAnn shape 'extern_class' - tich hop type-system (Task 2, extern-class)"
```

---

### Task 3: Constructor codegen (`newobj`) + đăng ký động + finally-pop

**Files:**
- Modify: `tkv_compile.py` (`_validate_and_register_extern_class_ctor`,
  đoạn setup/finally-pop trong `compile_tkv_cli`)
- Modify: `compiler/il_codegen.py` (`_expr_call` — nhánh mới TRƯỚC/CÙNG
  nhánh `if name in records`)
- Test: `test/verify/extern_class_ctor_test.py` (mới)

**Interfaces:**
- Consumes: `ctx['extern_class_defs']` (Task 2).
- Produces: `_expr_call` route được `ClassName(args)` khi `ClassName` là
  1 handle type đã đăng ký, emit `newobj instance void
  [assembly]Namespace.Class::.ctor(params...)`. Không đổi hành vi
  `if name in records:` hiện có.

- [ ] **Step 1: Viết test thất bại — gọi constructor thật, build+chạy .exe**

Tạo `test/verify/extern_class_ctor_test.py`:
```python
import sys, subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tkv_compile import compile_tkv_cli, TranspileError

fails = []
def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: {detail}')

HERE = Path(__file__).parent

src = '''
__tkv_extern_class__ = [
    {
        "name": "Sb",
        "assembly": "mscorlib",
        "class": "System.Text.StringBuilder",
        "ctor": [],
        "methods": [
            {"name": "ToString", "params": [], "returns": "str"},
        ],
    },
]

def main() -> None:
    s: Sb = Sb()
    print(s.ToString())
'''
tmp = HERE / '_extern_class_ctor_pos.tkv'
tmp.write_text(src, encoding='utf-8')
exe = compile_tkv_cli(str(tmp), out_exe=str(HERE / '_extern_class_ctor_pos.exe'), entry_name='run_x')
r = subprocess.run([str(exe)], capture_output=True, text=True)
check('ctor_pos_returncode', r.returncode == 0, r.stderr)
check('ctor_pos_output', r.stdout.strip() == '', repr(r.stdout))
# StringBuilder() rong -> ToString() la chuoi rong

# Test: ctor voi tham so
src2 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb",
        "assembly": "mscorlib",
        "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [
            {"name": "ToString", "params": [], "returns": "str"},
        ],
    },
]

def main() -> None:
    s: Sb = Sb("hello")
    print(s.ToString())
'''
tmp2 = HERE / '_extern_class_ctor_arg.tkv'
tmp2.write_text(src2, encoding='utf-8')
exe2 = compile_tkv_cli(str(tmp2), out_exe=str(HERE / '_extern_class_ctor_arg.exe'), entry_name='run_x')
r2 = subprocess.run([str(exe2)], capture_output=True, text=True)
check('ctor_arg_returncode', r2.returncode == 0, r2.stderr)
check('ctor_arg_output', r2.stdout.strip() == 'hello', repr(r2.stdout))

# Test loi: arity sai
src3 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"], "methods": [],
    },
]

def main() -> None:
    s: Sb = Sb()
'''
tmp3 = HERE / '_extern_class_ctor_arity_err.tkv'
tmp3.write_text(src3, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp3), out_exe=str(HERE / '_extern_class_ctor_arity_err.exe'), entry_name='run_x')
    check('ctor_arity_err_raises', False, 'khong raise')
except (TranspileError, SyntaxError):
    check('ctor_arity_err_raises', True)

for p in HERE.glob('_extern_class_ctor_*'):
    if p.suffix != '.tkv':
        try:
            p.unlink()
        except OSError:
            pass
    else:
        p.unlink()

if fails:
    print(f'FAILED {len(fails)}/5:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print('OK 5/5')
```

- [ ] **Step 2: Chạy test, xác nhận FAIL** (constructor call chưa route đúng — build lỗi hoặc `newobj` sai class)

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_ctor_test.py`
Expected: FAIL — build lỗi (`Sb` bị hiểu nhầm thành tên hàm/record không tồn tại) hoặc `ilasm` lỗi.

- [ ] **Step 3: `_expr_call` — nhánh constructor cho handle type**

Trong `compiler/il_codegen.py::_expr_call`, NGAY TRƯỚC nhánh `if name in
records:` (dòng 1668 trở đi), thêm:
```python
    extern_class_defs = (ctx or {}).get('extern_class_defs') or {}
    if name in extern_class_defs:
        decl = extern_class_defs[name]
        ctor_dtypes = decl['ctor']
        if len(args) != len(ctor_dtypes):
            raise SyntaxError(
                f"il_codegen: constructor {name!r} ky vong {len(ctor_dtypes)} "
                f"tham so, nhan duoc {len(args)}")
        il_params = []
        for arg_node, want_dtype in zip(args, ctor_dtypes):
            il_params.append(_il_ctor_param_type(want_dtype, extern_class_defs, ctx))
            ctx['compile_expr'](arg_node, scope, out, want_dtype, ctx)
        class_ref = f"[{decl['assembly']}]{decl['class']}"
        out.append(f"    newobj instance void {class_ref}::.ctor({', '.join(il_params)})")
        return
```
Thêm helper (đặt cạnh `_expr_call` hoặc ở đầu file, chỗ có sẵn các helper
tương tự):
```python
def _il_ctor_param_type(dtype_name, extern_class_defs, ctx):
    if dtype_name in extern_class_defs:
        d = extern_class_defs[dtype_name]
        return f"class [{d['assembly']}]{d['class']}"
    return _EXTERN_DTYPE_TO_IL_FOR_CODEGEN.get(dtype_name, dtype_name)
```
Nếu `il_codegen.py` đã có 1 bảng scalar-dtype-to-CIL-type tương đương
`_EXTERN_DTYPE_TO_IL` (tìm bằng cách grep `int32.*int64.*float32` hoặc
tương tự trong file này trước khi viết bảng MỚI trùng lặp) — TÁI DÙNG
bảng đó thay vì định nghĩa `_EXTERN_DTYPE_TO_IL_FOR_CODEGEN` mới; chỉ
định nghĩa mới nếu xác nhận chưa có.

- [ ] **Step 4: `_validate_and_register_extern_class_ctor` trong `tkv_compile.py`**

Validate mỗi entry `extern_classes` (tái dùng các helper validate
assembly/class-regex đã có từ `_validate_and_register_extern_method`,
đọc lại chữ ký chính xác của các helper đó — vd nếu có sẵn hàm riêng
kiểm tra assembly-đã-khai hoặc class-name-regex, gọi thẳng, KHÔNG viết
lại logic). Thêm ngay sau đoạn build `extern_class_defs` (Task 2 Step 3)
trong `compile_tkv_cli`, TRƯỚC `gen_il_program`:
```python
for _decl in extern_classes:
    if not _decl['name'].isidentifier():
        raise TranspileError(f"__tkv_extern_class__: 'name' {_decl['name']!r} khong phai identifier hop le")
    if _decl['name'] in EXPR_BUILTIN_CODEGEN or _decl['name'] in record_defs:
        raise ValueError(
            f"__tkv_extern_class__: ten {_decl['name']!r} DA duoc dang ky truoc do "
            f"(trung voi builtin hoac record co san) - doi ten khac")
    if _decl['assembly'] not in declared_assembly_names:
        raise TranspileError(
            f"__tkv_extern_class__: assembly {_decl['assembly']!r} chua duoc khai qua "
            f"__tkv_extern_assembly__")
    if not re.match(r'^[A-Za-z_][A-Za-z0-9_.]*$', _decl['class']):
        raise TranspileError(f"__tkv_extern_class__: 'class' {_decl['class']!r} khong dung dinh dang ten class .NET")
    for _pdtype in _decl['ctor']:
        if _pdtype not in _EXTERN_DTYPE_TO_IL and _pdtype not in extern_class_defs:
            raise TranspileError(
                f"__tkv_extern_class__: 'ctor' cua {_decl['name']!r} dung dtype "
                f"{_pdtype!r} khong ho tro (chi {sorted(_EXTERN_DTYPE_TO_IL)} hoac 1 "
                f"handle type da khai)")
```
(Đọc lại biến `declared_assembly_names`/`record_defs` đã tồn tại sẵn ở
đúng scope này trong `compile_tkv_cli` — TÁI DÙNG, không tạo lại.)

- [ ] **Step 5: Chạy lại test, xác nhận PASS**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_ctor_test.py`
Expected: `OK 5/5`

- [ ] **Step 6: Regression toàn bộ**

Run:
```bash
cd "D:\Claude AI Project\TokenVector"
python test/verify/extern_class_parse_test.py
python test/verify/extern_class_typesystem_test.py
python test/verify/extern_method_test.py
python test/verify/extern_pinvoke_test.py
python test/verify/duck_typing_infer_test.py
```
Expected: tất cả PASS.

- [ ] **Step 7: Commit**

```bash
git add tkv_compile.py compiler/il_codegen.py test/verify/extern_class_ctor_test.py
git commit -m "feat(compiler): newobj constructor cho extern-class handle type (Task 3, extern-class)"
```

---

### Task 4: Instance method codegen (`callvirt`) qua `EXPR_METHOD_CODEGEN` + finally-pop

**Files:**
- Modify: `tkv_compile.py` (`_validate_and_register_extern_class_methods`,
  factory `_make_extern_class_method_codegen`, đăng ký vào
  `EXPR_METHOD_CODEGEN`, `finally`-pop)
- Test: `test/verify/extern_class_method_test.py` (mới)

**Interfaces:**
- Consumes: `ctx['extern_class_defs']` (Task 2), route sẵn có trong
  `record_feature.py::compile_method_call` dòng 232-237 (tra
  `EXPR_METHOD_CODEGEN.get((obj_ta.shape or obj_ta.dtype, method_name))`
  — KHÔNG sửa file này).
- Produces: `handle_var.MethodName(args)` emit đúng
  `callvirt instance <ret_il> [assembly]Class::MethodName(params_il)`,
  hỗ trợ return là scalar HOẶC handle type (kể cả chính nó — chaining).

- [ ] **Step 1: Viết test thất bại — method scalar-return + method self-return (chaining)**

Tạo `test/verify/extern_class_method_test.py`:
```python
import sys, subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tkv_compile import compile_tkv_cli, TranspileError

fails = []
def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: {detail}')

HERE = Path(__file__).parent

# Test 1: method scalar-return
src = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [
            {"name": "ToString", "params": [], "returns": "str"},
        ],
    },
]

def main() -> None:
    s: Sb = Sb("abc")
    print(s.ToString())
'''
tmp = HERE / '_extern_class_method_scalar.tkv'
tmp.write_text(src, encoding='utf-8')
exe = compile_tkv_cli(str(tmp), out_exe=str(HERE / '_extern_class_method_scalar.exe'), entry_name='run_x')
r = subprocess.run([str(exe)], capture_output=True, text=True)
check('method_scalar_returncode', r.returncode == 0, r.stderr)
check('method_scalar_output', r.stdout.strip() == 'abc', repr(r.stdout))

# Test 2: method tra ve CHINH handle type (fluent chaining) - StringBuilder.Append that su co chu ky nay
src2 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [
            {"name": "Append", "params": ["str"], "returns": "Sb"},
            {"name": "ToString", "params": [], "returns": "str"},
        ],
    },
]

def main() -> None:
    s: Sb = Sb("a")
    t: Sb = s.Append("b")
    print(t.ToString())
'''
tmp2 = HERE / '_extern_class_method_chain.tkv'
tmp2.write_text(src2, encoding='utf-8')
exe2 = compile_tkv_cli(str(tmp2), out_exe=str(HERE / '_extern_class_method_chain.exe'), entry_name='run_x')
r2 = subprocess.run([str(exe2)], capture_output=True, text=True)
check('method_chain_returncode', r2.returncode == 0, r2.stderr)
check('method_chain_output', r2.stdout.strip() == 'ab', repr(r2.stdout))

# Test 3: goi method tren KET QUA bieu thuc truc tiep (khong qua bien trung gian)
src3 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [
            {"name": "Append", "params": ["str"], "returns": "Sb"},
            {"name": "ToString", "params": [], "returns": "str"},
        ],
    },
]

def main() -> None:
    s: Sb = Sb("x")
    print(s.Append("y").ToString())
'''
tmp3 = HERE / '_extern_class_method_direct_chain.tkv'
tmp3.write_text(src3, encoding='utf-8')
exe3 = compile_tkv_cli(str(tmp3), out_exe=str(HERE / '_extern_class_method_direct_chain.exe'), entry_name='run_x')
r3 = subprocess.run([str(exe3)], capture_output=True, text=True)
check('method_direct_chain_returncode', r3.returncode == 0, r3.stderr)
check('method_direct_chain_output', r3.stdout.strip() == 'xy', repr(r3.stdout))

# Test 4: is None tren bien handle
src4 = '''
__tkv_extern_class__ = [
    {"name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": [], "methods": []},
]

def main() -> None:
    s: Sb = Sb()
    if s is None:
        print("null")
    else:
        print("notnull")
'''
tmp4 = HERE / '_extern_class_method_isnone.tkv'
tmp4.write_text(src4, encoding='utf-8')
exe4 = compile_tkv_cli(str(tmp4), out_exe=str(HERE / '_extern_class_method_isnone.exe'), entry_name='run_x')
r4 = subprocess.run([str(exe4)], capture_output=True, text=True)
check('method_isnone_returncode', r4.returncode == 0, r4.stderr)
check('method_isnone_output', r4.stdout.strip() == 'notnull', repr(r4.stdout))

# Test 5: loi validate - method dung dtype tham so khong ho tro
src5 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [{"name": "Foo", "params": ["bignum"], "returns": "str"}],
    },
]
def main() -> None: pass
'''
tmp5 = HERE / '_extern_class_method_baddtype.tkv'
tmp5.write_text(src5, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp5), out_exe=str(HERE / '_extern_class_method_baddtype.exe'), entry_name='run_x')
    check('method_baddtype_raises', False, 'khong raise')
except TranspileError:
    check('method_baddtype_raises', True)

# Test 6: isolation - 2 lan compile lien tiep CUNG process, khac file, CUNG ten handle type
src_iso_a = '''
__tkv_extern_class__ = [
    {"name": "H", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": [], "methods": [{"name": "ToString", "params": [], "returns": "str"}]},
]
def main() -> None:
    h: H = H()
    print(h.ToString())
'''
src_iso_b = '''
__tkv_extern_class__ = [
    {"name": "H", "assembly": "mscorlib", "class": "System.Object", "ctor": [], "methods": [{"name": "ToString", "params": [], "returns": "str"}]},
]
def main() -> None:
    h: H = H()
    print(h.ToString())
'''
tmp_iso_a = HERE / '_extern_class_iso_a.tkv'
tmp_iso_b = HERE / '_extern_class_iso_b.tkv'
tmp_iso_a.write_text(src_iso_a, encoding='utf-8')
tmp_iso_b.write_text(src_iso_b, encoding='utf-8')
from compiler.il_dispatch import EXPR_METHOD_CODEGEN
check('iso_pre_clean', ('H', 'ToString') not in EXPR_METHOD_CODEGEN, 'H.ToString da dang ky truoc khi test chay')
compile_tkv_cli(str(tmp_iso_a), out_exe=str(HERE / '_extern_class_iso_a.exe'), entry_name='run_x')
check('iso_post_a_clean', ('H', 'ToString') not in EXPR_METHOD_CODEGEN, 'khong pop sau compile A')
exe_iso_b = compile_tkv_cli(str(tmp_iso_b), out_exe=str(HERE / '_extern_class_iso_b.exe'), entry_name='run_x')
check('iso_b_builds', exe_iso_b is not None, 'compile B (cung ten H, class khac) that bai')
check('iso_post_b_clean', ('H', 'ToString') not in EXPR_METHOD_CODEGEN, 'khong pop sau compile B')

for p in HERE.glob('_extern_class_method_*'):
    p.unlink()
for p in HERE.glob('_extern_class_iso_*'):
    p.unlink()

if fails:
    print(f'FAILED {len(fails)}/11:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print('OK 11/11')
```

- [ ] **Step 2: Chạy test, xác nhận FAIL** (method call trên handle chưa route đúng — `compile_method_call` raise "obj_ta.shape != record")

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_method_test.py`
Expected: FAIL — `SyntaxError` từ `compile_method_call`'s guard (dòng
255-260 theo investigate report).

- [ ] **Step 3: Factory `_make_extern_class_method_codegen` trong `tkv_compile.py`**

Đặt cạnh `_make_extern_static_call_codegen` (dòng 928-958):
```python
def _make_extern_class_method_codegen(assembly, dotnet_class, method_name,
                                       param_dtypes, return_dtype_name,
                                       extern_class_defs):
    il_ret_type = _il_ctor_param_type(return_dtype_name, extern_class_defs, None) \
        if return_dtype_name in extern_class_defs \
        else _EXTERN_DTYPE_TO_IL[return_dtype_name]
    call_target = f"[{assembly}]{dotnet_class}"

    def _codegen(obj_name, args, scope, out, dtype, ctx):
        if len(args) != len(param_dtypes):
            raise SyntaxError(
                f"il_codegen: method {method_name!r} tren {dotnet_class!r} ky vong "
                f"{len(param_dtypes)} tham so, nhan duoc {len(args)}")
        ctx['compile_expr']((('name', obj_name)), scope, out, None, ctx) \
            if isinstance(obj_name, str) else ctx['compile_expr'](obj_name, scope, out, None, ctx)
        il_params = []
        for arg_node, want_dtype in zip(args, param_dtypes):
            il_params.append(_il_ctor_param_type(want_dtype, extern_class_defs, ctx))
            ctx['compile_expr'](arg_node, scope, out, want_dtype, ctx)
        out.append(
            f"    callvirt instance {il_ret_type} {call_target}::{method_name}"
            f"({', '.join(il_params)})")
    return _codegen
```

**LƯU Ý QUAN TRỌNG cho implementer**: chữ ký thực tế của codegen closure
trong `EXPR_METHOD_CODEGEN` (tham số nào, thứ tự nào, cách "object đã
đứng trên stack sẵn hay closure phải tự load nó") PHẢI xác nhận bằng
cách đọc 1 entry CÓ SẴN trong `EXPR_METHOD_CODEGEN` (string/list/dict
method nào đó đã đăng ký qua registry này — grep
`EXPR_METHOD_CODEGEN\[` trong toàn repo để tìm ít nhất 1 ví dụ thật) và
đọc đúng cách `compile_method_call` (dòng 232-237) GỌI closure đó (bao
nhiêu tham số, ai chịu trách nhiệm load `obj` lên stack trước —
`compile_method_call` có thể ĐÃ load `obj` trước khi gọi registry, auto
codegen ở trên chỉ là bản NHÁP minh hoạ luồng, KHÔNG phải chữ ký cuối
cùng chắc chắn đúng). Sửa `_codegen` theo ĐÚNG chữ ký thật tìm được,
không theo bản nháp trên nếu lệch.

- [ ] **Step 4: Validate + đăng ký động trong `compile_tkv_cli`**

Ngay sau validate ctor (Task 3 Step 4), thêm:
```python
registered_extern_class_method_keys = []
for _decl in extern_classes:
    _seen_method_names = set()
    for _m in _decl['methods']:
        if _m['name'] in _seen_method_names:
            raise TranspileError(
                f"__tkv_extern_class__: method {_m['name']!r} khai TRUNG LAP "
                f"trong {_decl['name']!r}")
        _seen_method_names.add(_m['name'])
        if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', _m['name']):
            raise TranspileError(f"__tkv_extern_class__: method name {_m['name']!r} sai dinh dang")
        for _pdtype in _m['params']:
            if _pdtype not in _EXTERN_DTYPE_TO_IL and _pdtype not in extern_class_defs:
                raise TranspileError(
                    f"__tkv_extern_class__: method {_m['name']!r} cua {_decl['name']!r} "
                    f"dung dtype tham so {_pdtype!r} khong ho tro")
        if _m['returns'] != 'void' and _m['returns'] not in _EXTERN_DTYPE_TO_IL \
                and _m['returns'] not in extern_class_defs:
            raise TranspileError(
                f"__tkv_extern_class__: method {_m['name']!r} cua {_decl['name']!r} "
                f"returns {_m['returns']!r} khong ho tro")
        if _m['returns'] == 'void':
            raise TranspileError(
                f"__tkv_extern_class__: method {_m['name']!r} - 'returns':'void' "
                f"CHUA duoc ho tro o Phase 3 nay (chi ham co gia tri tra ve)")
        _key = (_decl['name'], _m['name'])
        if _key in EXPR_METHOD_CODEGEN:
            raise ValueError(
                f"__tkv_extern_class__: ({_decl['name']!r}, {_m['name']!r}) DA duoc "
                f"dang ky truoc do")
        EXPR_METHOD_CODEGEN[_key] = _make_extern_class_method_codegen(
            _decl['assembly'], _decl['class'], _m['name'], _m['params'],
            _m['returns'], extern_class_defs)
        registered_extern_class_method_keys.append(_key)
```
(`re` đã import sẵn ở đầu `tkv_compile.py` — xác nhận trước khi dùng,
không import lại nếu đã có.)

- [ ] **Step 5: `finally`-pop cho `EXPR_METHOD_CODEGEN`**

Trong khối `finally` hiện có (dòng 2323-2330), thêm:
```python
        for _key in registered_extern_class_method_keys:
            EXPR_METHOD_CODEGEN.pop(_key, None)
```

- [ ] **Step 6: Chạy lại test, xác nhận PASS**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_method_test.py`
Expected: `OK 11/11`

- [ ] **Step 7: Quyết định 'void' methods — cập nhật spec/checklist nếu chưa hỗ trợ**

Nếu Step 4 chặn `returns:'void'` như bản trên: xác nhận đây ĐÚNG phạm vi
spec (spec không nói rõ void method — coi như CHƯA làm ở Phase 3 này,
tương tự Phase 1 ban đầu chặn void trước khi Phase 2 mở ra). Ghi chú lại
trong docstring/comment tại điểm raise lỗi này để phiên sau biết đây là
giới hạn có chủ đích, không phải bug.

- [ ] **Step 8: Regression toàn bộ**

Run:
```bash
cd "D:\Claude AI Project\TokenVector"
python test/verify/extern_class_parse_test.py
python test/verify/extern_class_typesystem_test.py
python test/verify/extern_class_ctor_test.py
python test/verify/extern_class_method_test.py
python test/verify/extern_method_test.py
python test/verify/extern_pinvoke_test.py
python test/verify/duck_typing_infer_test.py
```
Expected: tất cả PASS.

- [ ] **Step 9: Commit**

```bash
git add tkv_compile.py test/verify/extern_class_method_test.py
git commit -m "feat(compiler): callvirt instance method cho extern-class qua EXPR_METHOD_CODEGEN (Task 4, extern-class)"
```

---

### Task 5: Duck-typing rejection + test tổng hợp + mirror tree + docs + commit cuối

**Files:**
- Modify: `compiler/il_features/duck_typing.py` (chặn handle type làm
  tham số `inferred`)
- Create: `test/sample_extern_class.tkv` (fixture mẫu)
- Create: `test/verify/extern_class_test.py` (test tổng hợp, theo đúng
  template `extern_method_test.py`/`extern_pinvoke_test.py`)
- Modify: `release/3.code/build/pyinstaller_src/tkv_compile.py`,
  `compiler/il_codegen.py`, `compiler/il_dispatch.py` (port toàn bộ
  Task 1-4 sang mirror tree)
- Modify: `docs/PYTHON_GAP_CHECKLIST.md` (đánh dấu Phase 3 xong)
- Test: chạy toàn bộ 4 file test mới (Task 1-4) + test tổng hợp mới

**Interfaces:**
- Consumes: toàn bộ Task 1-4.
- Produces: checklist cập nhật, mirror tree đồng bộ, `docs/BUGS_TODO.md`
  (nếu phát sinh follow-up nhỏ trong quá trình test).

- [ ] **Step 1: Viết test thất bại — handle type làm tham số `inferred` phải raise lỗi rõ ràng**

Thêm vào cuối `test/verify/extern_class_test.py` (file MỚI, viết từ đầu
theo template — xem Step 4):
```python
def test_duck_typing_rejects_handle_type():
    src = '''
__tkv_extern_class__ = [
    {"name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": [], "methods": [{"name": "ToString", "params": [], "returns": "str"}]},
]

def f(x) -> str:
    return x.ToString()

def main() -> None:
    s: Sb = Sb()
    print(f(s))
'''
    tmp = HERE / '_extern_class_ducktyping_reject.tkv'
    tmp.write_text(src, encoding='utf-8')
    try:
        compile_tkv_cli(str(tmp), out_exe=str(HERE / '_extern_class_ducktyping_reject.exe'), entry_name='run_x')
        check('ducktyping_reject_raises', False, 'khong raise - handle type LOT qua duck-typing!')
    except TranspileError:
        check('ducktyping_reject_raises', True)
    except Exception as e:
        check('ducktyping_reject_raises', False, f'raise sai loai: {type(e).__name__}: {e}')
    finally:
        tmp.unlink()
```

- [ ] **Step 2: Chạy, xác nhận FAIL hoặc PASS bất ngờ (kiểm tra hành vi hiện tại)**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_test.py`
Expected: xác nhận HÀNH VI THẬT hiện tại — nếu `collect_inferred_constraints`
(`compiler/il_features/duck_typing.py`) hiện đang cố suy `MethodConstraint`
cho `x.ToString()` mà không phân biệt record/handle-type, có thể build
"thành công" nhưng sinh CIL SAI (tra `record_methods` không thấy `Sb`,
lỗi `KeyError` hoặc tệ hơn — silent-wrong). Đọc kỹ output thật trước khi
viết fix Step 3 — đây là bug-class "build OK nhưng sai" đã bị phát hiện
nhiều lần trong các plan trước (xem `duck_typing_infer_test.py`'s Task 4
Critical fixes), PHẢI xác nhận thật, không đoán.

- [ ] **Step 3: Chặn handle type trong `collect_inferred_constraints`**

Trong `compiler/il_features/duck_typing.py`, tại điểm hàm này resolve
kiểu của biến/tham số CÓ SẴN (tìm nơi nó tra `ctx['records']` hoặc tương
đương để biết field/method của 1 kiểu record) — thêm kiểm tra: nếu kiểu
suy được (từ resolve call-site, xem `resolve_call_site`) là 1
`extern_class` handle type, raise `TranspileError` rõ ràng:
```python
raise TranspileError(
    f"duck-typing: tham so 'inferred' khong the la extern-class handle type "
    f"{concrete_type!r} - handle type khong tham gia co che suy kieu nay, "
    f"khai annotation tuong minh")
```
(Đọc kỹ code hiện tại của `resolve_call_site`/`collect_inferred_constraints`
trước khi sửa — xác định CHÍNH XÁC điểm nào cần thêm guard này, tái dùng
`ctx['extern_class_defs']` để kiểm tra tên kiểu có phải handle type hay
không.)

- [ ] **Step 4: Chạy lại, xác nhận PASS**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_test.py`
Expected: `test_duck_typing_rejects_handle_type` PASS.

- [ ] **Step 5: Hoàn thiện `test/verify/extern_class_test.py` đầy đủ theo template Phase 1/2**

Viết file HOÀN CHỈNH (không chỉ hàm ở Step 1) theo cấu trúc
`extern_method_test.py`: dùng fixture `test/sample_extern_class.tkv`
(tạo file này — 1 chương trình mẫu dùng `System.Text.StringBuilder` với
constructor, method scalar-return, method chaining-return, và `is None`)
+ test positive build/run đối chiếu Python string concat làm oracle +
test compatibility (trộn `__tkv_extern_class__` với `__tkv_extern_method__`
Phase 1 VÀ `__tkv_extern_pinvoke__` Phase 2 trong CÙNG 1 file — vd class
handle gọi `net_pow` static method Phase 1 để tính giá trị rồi
`ToString()` in ra) + dọn file `_`-prefix cuối bài theo đúng pattern.
Gộp CẢ 4 test file của Task 1-4 (`extern_class_parse_test.py`,
`extern_class_typesystem_test.py`, `extern_class_ctor_test.py`,
`extern_class_method_test.py`) làm tài liệu tham khảo case đã có — file
MỚI này KHÔNG cần lặp lại case đã test, chỉ thêm case TỔNG HỢP/compatibility/
duck-typing-reject/fixture-mẫu.

- [ ] **Step 6: Chạy toàn bộ test mới + regression suite**

Run:
```bash
cd "D:\Claude AI Project\TokenVector"
python test/verify/extern_class_parse_test.py
python test/verify/extern_class_typesystem_test.py
python test/verify/extern_class_ctor_test.py
python test/verify/extern_class_method_test.py
python test/verify/extern_class_test.py
python test/verify/extern_method_test.py
python test/verify/extern_pinvoke_test.py
python test/verify/duck_typing_infer_test.py
python test/verify/aggregates_variadic_py_tree_test.tkv 2>/dev/null || true
```
Expected: tất cả PASS. (Dòng cuối là ví dụ tham khảo format cũ, bỏ nếu
không áp dụng — chạy ĐẦY ĐỦ bộ regression hiện có theo cách dự án thường
chạy, xác nhận lệnh chính xác bằng cách đọc `test/README.md` hoặc tương
đương nếu tồn tại.)

- [ ] **Step 7: Port sang mirror tree `release/3.code/build/pyinstaller_src/`**

Đọc kỹ cấu trúc THẬT của mirror tree trước khi port (đã xác nhận KHÔNG
đồng bộ tuyệt đối với cây gốc — không copy-paste mù). Áp dụng CÙNG các
thay đổi logic của Task 1-4 (parse pragma, type-system, ctor codegen,
method codegen) vào:
- `release/3.code/build/pyinstaller_src/tkv_compile.py`
- `release/3.code/build/pyinstaller_src/compiler/il_codegen.py`
- `release/3.code/build/pyinstaller_src/compiler/il_dispatch.py` (nếu
  `EXPR_METHOD_CODEGEN` tồn tại ở đây — xác nhận, có thể mirror tree cấu
  trúc registry khác đi do đã trôi trước đó).

Nếu mirror tree ĐÃ trôi đáng kể (không có `_make_extern_static_call_codegen`
tương ứng, hoặc thiếu cả `__tkv_extern_method__`/`__tkv_extern_pinvoke__`)
— DỪNG LẠI, không cố ép port, mà ghi rõ trong báo cáo: mirror tree hiện
KHÔNG có nền tảng Phase 1/2 để port Phase 3 lên, đề xuất port riêng
Phase 1+2 trước hoặc bỏ qua đồng bộ mirror cho tính năng này (giống tiền
lệ đã ghi nhận ở project memory `tokenvector-release-session-2026-08-11`:
cây `.tkv` tự-host có drift đáng kể so với `.py`, KHÔNG phải lỗi của task
này).

**KHÔNG rebuild `release/3.code/dist/tkvc.exe`** — chỉ sửa source, không
build binary trừ khi có yêu cầu rõ ràng khác.

- [ ] **Step 8: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Trong mục `#1 Package ecosystem`, thêm đoạn mô tả Phase 3 ĐÃ XONG (theo
đúng văn phong các đoạn Phase 1/2 hiện có — link tới
`docs/superpowers/plans/2026-08-18-extern-class.md` +
`docs/superpowers/specs/2026-08-18-extern-class-design.md`), liệt kê rõ
"Đã làm" (constructor + instance method qua khai báo, method trả về
handle type kể cả chính nó) và "CHƯA làm" (copy nguyên phần "Giới hạn
KHÔNG làm" từ spec: property, generic, container, static field trên
handle, void method, multi-ctor overload, duck-typing không tham gia).

- [ ] **Step 9: Cập nhật ledger SDD**

```bash
cd "D:\Claude AI Project"
echo "Task 5: complete (extern-class Phase 3, #1 Package ecosystem)" >> .superpowers/sdd/progress.md
```
(Chạy lệnh tương đương PowerShell nếu môi trường thực thi không hỗ trợ
`echo >>` kiểu bash — xác nhận shell thật lúc thực thi.)

- [ ] **Step 10: Commit cuối**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_features/duck_typing.py test/sample_extern_class.tkv test/verify/extern_class_test.py docs/PYTHON_GAP_CHECKLIST.md release/3.code/build/pyinstaller_src/tkv_compile.py release/3.code/build/pyinstaller_src/compiler/il_codegen.py release/3.code/build/pyinstaller_src/compiler/il_dispatch.py
git commit -m "feat(compiler): extern-class Phase 3 hoan tat - duck-typing reject + test tong hop + mirror tree + docs (Task 5, extern-class)"
```

---

## Self-Review (đã chạy trước khi giao plan)

**Spec coverage**: pragma shape (Task 1) → type-system (Task 2) →
constructor `newobj` (Task 3) → instance method `callvirt` + chaining
(Task 4) → duck-typing reject + test tổng hợp + mirror + docs (Task 5).
Mọi mục "Kiểm chứng" của spec có task/step tương ứng: test tích cực
(Task 3-5), chaining (Task 4 Step 1 test 2-3), `is None` (Task 4 Step 1
test 4), lỗi validate (Task 1/3/4 mỗi task có case lỗi riêng), isolation
(Task 4 Step 1 test 6), tương thích với Phase 1/2 (Task 5 Step 5),
duck-typing reject (Task 5 Step 1-4), regression toàn suite (mọi task
Step cuối), mirror tree (Task 5 Step 7), docs (Task 5 Step 8).

**Điểm KHÔNG chắc chắn 100% cần implementer tự xác nhận lúc thực thi**
(đã ghi rõ trong từng Step liên quan, không phải placeholder mà là rủi
ro thật do không đọc được TOÀN BỘ file gốc trong lúc viết plan này):
chữ ký chính xác `il_type_str` có nhận `ctx` hay không (Task 2 Step 5),
chữ ký chính xác của closure trong `EXPR_METHOD_CODEGEN` (Task 4 Step 3
— có ví dụ thật cần đọc trước khi tin code mẫu), mức độ trôi của mirror
tree (Task 5 Step 7). Mỗi điểm đều có hướng dẫn cụ thể "đọc code X trước,
áp dụng pattern Y" — không phải "TODO" mơ hồ.
