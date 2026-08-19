# `__tkv_extern_class__` Phase 4 — Property get/set Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cho code `.tkv` đọc/ghi property của 1 handle type .NET ngoài
qua cú pháp giống hệt field record (`obj.Prop`, `obj.Prop = x`), route
sang `callvirt get_Prop()`/`callvirt set_Prop(value)`.

**Architecture:** Thêm key tùy chọn `"properties"` vào entry
`__tkv_extern_class__` hiện có. Đọc property tái dùng registry
`EXPR_METHOD_CODEGEN` khoá `('extern_class', 'get_Prop')` (y hệt cơ chế
method Phase 3) nhưng gọi từ 1 nhánh MỚI trong `compile_attr` (tag
`'attr'`, KHÔNG phải `'method_call'`). Ghi property là đường dispatch
HOÀN TOÀN MỚI trong `codegen_attr_assign` (hiện hardcode chỉ cho record),
có kiểm tra `readonly`.

**Tech Stack:** Python 3 (compiler nguồn), CIL text, `ilasm.exe`
(.NET Framework mscorlib v4.0.30319, Windows-only).

## Global Constraints

- `dtype` property: scalar (`i32/i64/f32/f64/str`) HOẶC tên 1 handle type
  ĐÃ khai trong CÙNG `__tkv_extern_class__`.
- `readonly` mặc định `true` nếu vắng — CHỈ sinh setter khi khai rõ
  `"readonly": false`.
- Registry `EXPR_METHOD_CODEGEN` khoá `('extern_class', method_name)` —
  KHÔNG phải per-class — property pseudo-method `get_X`/`set_X` PHẢI tuân
  thủ CÙNG quy tắc idempotent-theo-tên (đăng ký 1 lần, dynamic-dispatch
  theo `obj_ta.dtype` lúc gọi, KHÔNG theo tên class lúc đăng ký).
- `get_X`/`set_X` sinh ra KHÔNG được trùng tên với 1 method THẬT đã khai
  trong CÙNG entry `methods` (và ngược lại).
- Handle type's property KHÔNG tham gia duck-typing-inference (kế thừa
  guard đã có ở Phase 3 Task 5 — XÁC NHẬN LẠI, không phải viết mới, xem
  Task 4).
- KHÔNG static property, KHÔNG indexer, KHÔNG property kiểu container,
  KHÔNG auto-detect qua reflection.
- Đăng ký động PHẢI tự gỡ (`finally`-pop) sau mỗi lượt `compile_tkv_cli`.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`. Mirror tree `.tkv` tự-host
  ĐÃ XÁC NHẬN (Phase 3 Task 5) chưa có nền tảng Phase 1/2/3 — Phase 4 này
  CŨNG KHÔNG port sang mirror tree, chỉ ghi chú lại trong docs.
- KHÔNG chạm `compiler/il_features/operators.py`.

---

## Bối cảnh code đã xác nhận (đọc trước Task 1)

**`tkv_compile.py`**:
- `_EXTERN_CLASS_KEYS/_EXTERN_CLASS_REQUIRED/_EXTERN_CLASS_METHOD_KEYS/_EXTERN_CLASS_METHOD_REQUIRED`:
  dòng 856-859. `properties` PHẢI thêm vào `_EXTERN_CLASS_KEYS`, KHÔNG
  thêm vào `_EXTERN_CLASS_REQUIRED` (tùy chọn).
- `_parse_extern_class_method_dict_literal`: dòng 873-894 — mẫu cho hàm
  parse property mới.
- `_parse_extern_class_dict_literal`: dòng 897-928, nhánh `methods` dòng
  917-920 — mẫu cho nhánh `properties` mới, cần `result.setdefault('properties', [])`
  sau vòng lặp vì đây là key TÙY CHỌN (khác `methods`/`ctor` bắt buộc).
- Validation/registration block trong `compile_tkv_cli`: dòng 2317-2660.
  - Build `extern_class_defs` + name-collision guard: dòng 2332-2339.
  - Validate cấp decl (name/assembly/class/ctor dtype): dòng 2383-2404.
  - Validate method + guard trùng tên trong CÙNG decl
    (`_seen_method_names`): dòng 2411-2445. **Guard `returns == 'void'`
    bị CHẶN CỨNG ở đây (dòng 2429-2440)** — setter LÀ void, nên logic
    validate property PHẢI đi đường RIÊNG, không tái dùng thẳng vòng lặp
    validate method (xem Task 1).
  - Đăng ký `EXPR_METHOD_CODEGEN[('extern_class', method_name)]`: dòng
    2447-2468 (idempotent theo tên, `continue` nếu đã có).
  - `il_codegen._EXTERN_CLASS_DEFS = extern_class_defs`: dòng 2473.
  - `finally`-pop: dòng 2647-2660 — PHẢI mở rộng để pop cả
    `get_X`/`set_X` đã đăng ký.
- Factory (`compiler/il_codegen.py`, không phải `tkv_compile.py` — xác
  nhận lại): `_extern_class_method_lookup`, `_make_extern_class_method_return_ta`,
  `_make_extern_class_method_codegen`: dòng 1069-1132 (đọc kỹ trước khi
  viết factory setter — setter KHÔNG dùng `widen_if_needed` vì không có
  giá trị trả về để widen).

**`compiler/il_codegen.py`**:
- `_EXTERN_CLASS_DEFS` module-level: dòng 115-128.
- `il_type_str`'s nhánh `extern_class`: dòng 178-183.
- `_il_ctor_param_type`: dòng 1690-1699 — TÁI DÙNG cho dtype property.
- `_expr_call`'s nhánh constructor: dòng 1702-1726 (mẫu tham khảo cách
  gate `if name in _EXTERN_CLASS_DEFS:`).

**`compiler/il_features/record_feature.py`**:
- `compile_attr` (đọc `obj.field`, tag `'attr'`): dòng 159-204, đăng ký
  dòng 319. Điểm chèn CHÍNH XÁC: SAU nhánh `dict_kvpair` (dòng 168-185,
  kết thúc bằng `return`), TRƯỚC guard `if obj_ta.shape != 'record':`
  (dòng 186-189).
- `codegen_attr_assign` (ghi `obj.field = x`, statement): dòng 127-152,
  đăng ký dòng 317. Điểm chèn CHÍNH XÁC: NGAY TRƯỚC guard
  `if obj_ta.shape != 'record':` (dòng 130-133). `try_parse_attr_assign`
  (dòng 115-124) chỉ regex-parse `(\w+)\.(\w+)\s*=\s*(.+)`, KHÔNG phân
  biệt record/extern-class — việc đó hoàn toàn ở `codegen_attr_assign`.
- `compile_method_call` (gọi `obj.Method(...)`, tag `'method_call'`):
  dòng 207-312, tra `EXPR_METHOD_CODEGEN.get((obj_ta.shape or obj_ta.dtype, method_name))`
  dòng 231-237. **XÁC NHẬN QUAN TRỌNG**: đây là đường HOÀN TOÀN RIÊNG với
  `compile_attr` — `EXPR_METHOD_CODEGEN` KHÔNG được `compile_attr` tra
  cứu hiện tại, nên property-read cần 1 LỜI GỌI MỚI vào registry này từ
  BÊN TRONG `compile_attr`, không phải sửa `compile_method_call`.
- `_field_owner_class`/`_method_owner_class`: dòng 42-78/81-92 — XÁC
  NHẬN KHÔNG liên quan (handle type không có inheritance, method codegen
  hardcode `[assembly]Class` trực tiếp từ decl).
- `try_expand_compound_attr` (dòng 102-112): desugar `obj.field += expr`
  thành `obj.field = obj.field + (expr)` TRƯỚC khi biết kiểu — tự động
  hoạt động ĐÚNG cho property 1 khi Task 2+3 xong, KHÔNG cần việc riêng.

**Test mẫu**: `test/verify/extern_class_method_test.py` (180 dòng, 11
case) — cấu trúc tham khảo cho `test/verify/extern_class_property_test.py`
mới: `compile_tkv_cli` + `subprocess.run` + assert stdout, case lỗi dtype,
case isolation 2-lần-compile (đặc biệt quan trọng — PHẢI xác nhận
`('extern_class', 'get_Prop')`/`('extern_class', 'set_Prop')` được pop
đúng).

**Không có sẵn**: check trùng tên `get_X`/`set_X` với method thật khai
CÙNG tên — đây là logic MỚI hoàn toàn (Task 1).

---

### Task 1: Parse key `"properties"` + validate (bao gồm collision guard + readonly)

**Files:**
- Modify: `tkv_compile.py`
- Test: `test/verify/extern_class_property_parse_test.py` (mới)

**Interfaces:**
- Consumes: pattern `_parse_extern_class_method_dict_literal` (dòng
  873-894), `_EXTERN_CLASS_KEYS` (dòng 856-859).
- Produces: mỗi entry `extern_classes[i]` có thêm key `'properties':
  list[dict]`, mỗi phần tử shape:
  ```python
  {'name': str, 'dtype': str, 'readonly': bool}  # readonly LUON co mat sau parse (fill default True)
  ```
  Task 2/3/4 tiêu thụ TRỰC TIẾP shape này — KHÔNG đổi ở task sau.

- [ ] **Step 1: Viết test thất bại cho parse shape hợp lệ**

Tạo `test/verify/extern_class_property_parse_test.py`:
```python
import sys, ast
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tkv_compile import _parse_extern_class_dict_literal, TranspileError

fails = []
def check(label, cond, detail=''):
    if not cond:
        fails.append(f'{label}: {detail}')

def _dict_node(src):
    return ast.parse(src, mode='eval').body

# Test 1: properties day du, co readonly ro
node = _dict_node("""{
    "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
    "ctor": [], "methods": [],
    "properties": [
        {"name": "Length", "dtype": "i32", "readonly": True},
        {"name": "Capacity", "dtype": "i32", "readonly": False},
    ],
}""")
decl = _parse_extern_class_dict_literal(node)
check('props_len', len(decl['properties']) == 2, decl)
check('prop0_name', decl['properties'][0]['name'] == 'Length', decl)
check('prop0_readonly', decl['properties'][0]['readonly'] is True, decl)
check('prop1_readonly', decl['properties'][1]['readonly'] is False, decl)

# Test 2: properties vang readonly -> mac dinh True
node2 = _dict_node("""{
    "name": "Sb2", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
    "ctor": [], "methods": [],
    "properties": [{"name": "Length", "dtype": "i32"}],
}""")
decl2 = _parse_extern_class_dict_literal(node2)
check('prop_default_readonly', decl2['properties'][0]['readonly'] is True, decl2)

# Test 3: khong khai 'properties' -> tu dien vao [] (tuong thich nguoc)
node3 = _dict_node("""{
    "name": "Sb3", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
    "ctor": [], "methods": [],
}""")
decl3 = _parse_extern_class_dict_literal(node3)
check('props_absent_defaults_empty', decl3['properties'] == [], decl3)

# Test 4: key la trong property dict -> TranspileError
node4 = _dict_node("""{
    "name": "Sb4", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
    "ctor": [], "methods": [],
    "properties": [{"name": "X", "dtype": "i32", "bad_key": 1}],
}""")
try:
    _parse_extern_class_dict_literal(node4)
    check('prop_bad_key_raises', False, 'khong raise')
except TranspileError:
    check('prop_bad_key_raises', True)

if fails:
    print(f'FAILED {len(fails)}/6:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print('OK 6/6')
```

- [ ] **Step 2: Chạy test, xác nhận FAIL**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_property_parse_test.py`
Expected: `KeyError: 'properties'` hoặc `TranspileError` do key `'properties'`
chưa được `_EXTERN_CLASS_KEYS` chấp nhận.

- [ ] **Step 3: Thêm parse cho `"properties"` trong `tkv_compile.py`**

Sửa `_EXTERN_CLASS_KEYS` (dòng 856-859), thêm `'properties'` (KHÔNG thêm
vào `_EXTERN_CLASS_REQUIRED`):
```python
_EXTERN_CLASS_KEYS = {'name', 'assembly', 'class', 'ctor', 'methods', 'properties'}
_EXTERN_CLASS_PROPERTY_KEYS = {'name', 'dtype', 'readonly'}
_EXTERN_CLASS_PROPERTY_REQUIRED = {'name', 'dtype'}
```
Thêm hàm mới cạnh `_parse_extern_class_method_dict_literal` (sau dòng 894):
```python
def _parse_extern_class_property_dict_literal(node):
    if not isinstance(node, ast.Dict):
        raise TranspileError("__tkv_extern_class__'s 'properties': moi phan tu phai la 1 dict-literal")
    result = {}
    for k_node, v_node in zip(node.keys, node.values):
        if not (isinstance(k_node, ast.Constant) and isinstance(k_node.value, str)):
            raise TranspileError("__tkv_extern_class__'s property dict: key phai la string literal")
        key = k_node.value
        if key not in _EXTERN_CLASS_PROPERTY_KEYS:
            raise TranspileError(
                f"__tkv_extern_class__'s property dict: key {key!r} khong hop le, "
                f"chi chap nhan {sorted(_EXTERN_CLASS_PROPERTY_KEYS)}")
        if key == 'readonly':
            if not (isinstance(v_node, ast.Constant) and isinstance(v_node.value, bool)):
                raise TranspileError("__tkv_extern_class__'s property 'readonly' phai la True/False")
            result[key] = v_node.value
        else:
            if not (isinstance(v_node, ast.Constant) and isinstance(v_node.value, str)):
                raise TranspileError(f"__tkv_extern_class__'s property dict: key {key!r} phai la string literal")
            result[key] = v_node.value
    missing = _EXTERN_CLASS_PROPERTY_REQUIRED - set(result.keys())
    if missing:
        raise TranspileError(f"__tkv_extern_class__'s property dict thieu key bat buoc: {sorted(missing)}")
    result.setdefault('readonly', True)
    return result
```
Trong `_parse_extern_class_dict_literal` (dòng 897-928), thêm nhánh SAU
nhánh `methods` (sau dòng 920):
```python
        elif key == 'properties':
            if not isinstance(v_node, ast.List):
                raise TranspileError("__tkv_extern_class__'s 'properties' phai la 1 list")
            result[key] = [_parse_extern_class_property_dict_literal(p) for p in v_node.elts]
```
Sau vòng lặp `for k_node, v_node in ...` (trước phần check `missing`),
thêm:
```python
    result.setdefault('properties', [])
```

- [ ] **Step 4: Chạy lại, xác nhận PASS**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_property_parse_test.py`
Expected: `OK 6/6`

- [ ] **Step 5: Validate + collision guard trong `compile_tkv_cli`**

Ngay sau vòng lặp validate method hiện có (sau dòng 2445, TRƯỚC đoạn
đăng ký `EXPR_METHOD_CODEGEN` dòng 2447), thêm:
```python
for _decl in extern_classes:
    _seen_method_names = set(m['name'] for m in _decl['methods'])
    _seen_prop_names = set()
    for _p in _decl['properties']:
        if _p['name'] in _seen_prop_names:
            raise TranspileError(
                f"__tkv_extern_class__: property {_p['name']!r} khai TRUNG LAP "
                f"trong {_decl['name']!r}")
        _seen_prop_names.add(_p['name'])
        if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', _p['name']):
            raise TranspileError(f"__tkv_extern_class__: property name {_p['name']!r} sai dinh dang")
        if _p['dtype'] not in _EXTERN_DTYPE_TO_IL and _p['dtype'] not in extern_class_defs:
            raise TranspileError(
                f"__tkv_extern_class__: property {_p['name']!r} cua {_decl['name']!r} "
                f"dung dtype {_p['dtype']!r} khong ho tro")
        _get_name = f"get_{_p['name']}"
        _set_name = f"set_{_p['name']}"
        if _get_name in _seen_method_names or _set_name in _seen_method_names:
            raise TranspileError(
                f"__tkv_extern_class__: property {_p['name']!r} cua {_decl['name']!r} "
                f"sinh ten pseudo-method {_get_name!r}/{_set_name!r} TRUNG voi 1 method "
                f"THAT da khai trong 'methods' - doi ten method hoac property")
```
(Xác nhận `re` đã import sẵn trong `tkv_compile.py` — dùng nguyên, không
import lại. `_EXTERN_DTYPE_TO_IL` đã tồn tại sẵn từ Phase 3 Task 1/3.)

- [ ] **Step 6: Regression toàn bộ Phase 1-3**

Run:
```bash
cd "D:\Claude AI Project\TokenVector"
python test/verify/extern_class_property_parse_test.py
python test/verify/extern_class_parse_test.py
python test/verify/extern_class_typesystem_test.py
python test/verify/extern_class_ctor_test.py
python test/verify/extern_class_method_test.py
python test/verify/extern_class_test.py
python test/verify/extern_method_test.py
python test/verify/extern_pinvoke_test.py
python test/verify/duck_typing_infer_test.py
```
Expected: tất cả PASS.

- [ ] **Step 7: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add tkv_compile.py test/verify/extern_class_property_parse_test.py
git commit -m "feat(compiler): parse+validate 'properties' key cho __tkv_extern_class__ (Task 1, extern-class-property)"
```

---

### Task 2: Property READ codegen (`get_X` qua `compile_attr`)

**Files:**
- Modify: `compiler/il_codegen.py` (factory `_make_extern_class_property_getter_codegen`,
  hoặc tái dùng trực tiếp `_make_extern_class_method_codegen` bằng cách
  đóng gói property thành method-dict giả `{'name': f'get_{name}', 'params': [], 'returns': dtype}`
  — xác nhận cách nào đơn giản hơn lúc implement, KHÔNG bắt buộc viết
  factory mới nếu tái dùng an toàn được)
- Modify: `tkv_compile.py` (đăng ký `EXPR_METHOD_CODEGEN[('extern_class', 'get_X')]`
  + finally-pop)
- Modify: `compiler/il_features/record_feature.py` (`compile_attr` —
  nhánh mới)
- Test: `test/verify/extern_class_property_test.py` (mới)

**Interfaces:**
- Consumes: `_decl['properties']` (Task 1's output shape).
- Produces: `obj.Prop` (đọc, biểu thức) emit
  `callvirt instance <T> [assembly]Class::get_Prop()`.

- [ ] **Step 1: Viết test thất bại — đọc property thật, build+chạy**

Tạo `test/verify/extern_class_property_test.py`:
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

# Test 1: doc property scalar
src = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"], "methods": [],
        "properties": [{"name": "Length", "dtype": "i32", "readonly": True}],
    },
]

def main() -> "i32":
    s = Sb("hello")
    n = s.Length
    print(n)
    return 0
'''
tmp = HERE / '_extern_class_prop_read.tkv'
tmp.write_text(src, encoding='utf-8')
exe = compile_tkv_cli(str(tmp), out_exe=str(HERE / '_extern_class_prop_read.exe'), entry_name='main')
r = subprocess.run([str(exe)], capture_output=True, text=True)
check('prop_read_returncode', r.returncode == 0, r.stderr)
check('prop_read_output', r.stdout.splitlines()[0].strip() == '5', repr(r.stdout))

# Test 2: doc property tren ket qua bieu thuc goi method (chaining voi property)
src2 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"],
        "methods": [{"name": "Append", "params": ["str"], "returns": "Sb"}],
        "properties": [{"name": "Length", "dtype": "i32", "readonly": True}],
    },
]

def main() -> "i32":
    s = Sb("ab")
    t = s.Append("cd")
    n = t.Length
    print(n)
    return 0
'''
tmp2 = HERE / '_extern_class_prop_chain.tkv'
tmp2.write_text(src2, encoding='utf-8')
exe2 = compile_tkv_cli(str(tmp2), out_exe=str(HERE / '_extern_class_prop_chain.exe'), entry_name='main')
r2 = subprocess.run([str(exe2)], capture_output=True, text=True)
check('prop_chain_returncode', r2.returncode == 0, r2.stderr)
check('prop_chain_output', r2.stdout.splitlines()[0].strip() == '4', repr(r2.stdout))

# Test 3: loi - doc property khong ton tai
src3 = '''
__tkv_extern_class__ = [
    {"name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": [], "methods": [], "properties": []},
]
def main() -> "i32":
    s = Sb()
    n = s.NotAProp
    return 0
'''
tmp3 = HERE / '_extern_class_prop_missing.tkv'
tmp3.write_text(src3, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp3), out_exe=str(HERE / '_extern_class_prop_missing.exe'), entry_name='main')
    check('prop_missing_raises', False, 'khong raise')
except (TranspileError, SyntaxError):
    check('prop_missing_raises', True)

for p in HERE.glob('_extern_class_prop_*'):
    if p.suffix == '.tkv':
        p.unlink()
    else:
        try:
            p.unlink()
        except OSError:
            pass

if fails:
    print(f'FAILED {len(fails)}/5:')
    for f in fails:
        print(f'  - {f}')
    sys.exit(1)
print('OK 5/5')
```

- [ ] **Step 2: Chạy, xác nhận FAIL**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_property_test.py`
Expected: FAIL ở `prop_read_returncode` — `compile_attr`'s guard
`if obj_ta.shape != 'record':` raise `SyntaxError` vì `Sb` có
`shape='extern_class'`.

- [ ] **Step 3: Đăng ký `get_X` trong `compile_tkv_cli`**

Ngay sau vòng lặp đăng ký method hiện có (sau dòng 2468), thêm:
```python
registered_extern_class_property_names = []
for _decl in extern_classes:
    for _p in _decl['properties']:
        _getter_key = ('extern_class', f"get_{_p['name']}")
        if _getter_key not in EXPR_METHOD_CODEGEN:
            _getter_method_dict = {'name': f"get_{_p['name']}", 'params': [], 'returns': _p['dtype']}
            register_expr_method(
                'extern_class', _getter_method_dict['name'],
                _make_extern_class_method_codegen(_getter_method_dict['name']),
                return_ta_fn=_make_extern_class_method_return_ta(_getter_method_dict['name']),
                result_shape='extern_class')
            registered_extern_class_property_names.append(_getter_method_dict['name'])
```
**LƯU Ý implementer**: `_make_extern_class_method_codegen`/`_extern_class_method_lookup`
tra CHỮ KÝ method từ `decl['methods']` theo tên — với `get_X` KHÔNG nằm
trong `decl['methods']` thật, PHẢI xác nhận (đọc lại `_extern_class_method_lookup`,
dòng 1069+) cơ chế tra cứu chữ ký hiện tại có tự động tìm được `get_X`
hay không. Nếu KHÔNG (nhiều khả năng — vì `decl['methods']` không chứa
`get_X`), 2 lựa chọn:
(a) SỬA `_extern_class_method_lookup` để khi không tìm thấy trong
`methods`, thử tra `properties` (map `get_{name}`/`set_{name}` → tổng
hợp method-dict tương đương `{'name':..., 'params': [] hoặc [dtype], 'returns': dtype hoặc 'void'}`),
HOẶC
(b) TIỀN XỬ LÝ: trước khi validate/đăng ký, tự động APPEND vào
`_decl['methods']` (bản sao cục bộ, KHÔNG sửa `extern_classes` gốc nếu
điều đó ảnh hưởng validate ở Step 5 Task 1) các method-dict giả
`get_X`/`set_X` tương ứng — cách này tái dùng TOÀN BỘ pipeline method
sẵn có mà không sửa `_extern_class_method_lookup`.
Chọn hướng (b) nếu đơn giản hơn — ưu tiên ít sửa code lõi. Đọc kỹ
`_extern_class_method_lookup`'s implementation thật trước khi quyết
định, không đoán.

- [ ] **Step 4: Nhánh mới trong `compile_attr`**

Trong `compiler/il_features/record_feature.py::compile_attr`, chèn NGAY
SAU nhánh `dict_kvpair` (sau dòng 185's `return`), TRƯỚC dòng 186's guard:
```python
    if obj_ta.shape == 'extern_class':
        decl = ctx.get('extern_class_defs_lookup', {}).get(obj_ta.dtype) \
            if ctx else None
        # Neu ctx khong mang extern_class_defs, tra il_codegen._EXTERN_CLASS_DEFS
        from compiler import il_codegen as _ilc
        decl = decl or _ilc._EXTERN_CLASS_DEFS.get(obj_ta.dtype)
        prop = next((p for p in (decl.get('properties') or []) if p['name'] == field_name), None) if decl else None
        if prop is None:
            raise SyntaxError(
                f"il_codegen: '.{field_name}' khong phai property da khai cua "
                f"handle type {obj_ta.dtype!r}")
        registered = EXPR_METHOD_CODEGEN.get(('extern_class', f'get_{field_name}'))
        if registered is None:
            raise SyntaxError(
                f"il_codegen: getter cho property {field_name!r} chua duoc dang ky")
        fake_node = ('method_call', obj_name, f'get_{field_name}', [])
        return registered(fake_node, scope, out, dtype, ctx)
```
**LƯU Ý implementer**: cấu trúc `node` thật mà `registered(...)` (tức
`_make_extern_class_method_codegen`'s closure) mong đợi PHẢI xác nhận
bằng cách đọc `compile_method_call` (dòng 207-237) — cách nó destructure
`node` (`node[1]`/`node[2]`/`node[3]` hay tên khác) TRƯỚC khi viết
`fake_node` ở trên; sửa shape `fake_node` cho khớp CHÍNH XÁC, không theo
đoán ở bản nháp này.

- [ ] **Step 5: `finally`-pop mở rộng**

Trong khối `finally` (dòng ~2647-2660), thêm:
```python
        for _nm in registered_extern_class_property_names:
            EXPR_METHOD_CODEGEN.pop(('extern_class', _nm), None)
```

- [ ] **Step 6: Chạy lại, xác nhận PASS**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_property_test.py`
Expected: `OK 5/5`

- [ ] **Step 7: Regression Task 1 + Phase 1-3**

Run:
```bash
cd "D:\Claude AI Project\TokenVector"
python test/verify/extern_class_property_parse_test.py
python test/verify/extern_class_property_test.py
python test/verify/extern_class_parse_test.py
python test/verify/extern_class_typesystem_test.py
python test/verify/extern_class_ctor_test.py
python test/verify/extern_class_method_test.py
python test/verify/extern_class_test.py
python test/verify/extern_method_test.py
python test/verify/extern_pinvoke_test.py
python test/verify/duck_typing_infer_test.py
python test/verify/record_test.py
python test/verify/record_method_test.py
```
Expected: tất cả PASS — ĐẶC BIỆT `record_test.py`/`record_method_test.py`
xác nhận nhánh `compile_attr` mới không đụng đường code field-record cũ.

- [ ] **Step 8: Commit**

```bash
git add compiler/il_codegen.py compiler/il_features/record_feature.py tkv_compile.py test/verify/extern_class_property_test.py
git commit -m "feat(compiler): doc property (get_X qua callvirt) cho extern-class (Task 2, extern-class-property)"
```

---

### Task 3: Property WRITE codegen (`set_X` qua `codegen_attr_assign`) + readonly enforcement

**Files:**
- Modify: `tkv_compile.py` (đăng ký `set_X` cho property `readonly=false`
  + finally-pop)
- Modify: `compiler/il_features/record_feature.py` (`codegen_attr_assign`
  — nhánh mới, kiểm `readonly`)
- Test: mở rộng `test/verify/extern_class_property_test.py`

**Interfaces:**
- Consumes: `_decl['properties']` (Task 1), registry pattern (Task 2).
- Produces: `obj.Prop = expr` (statement) emit
  `callvirt instance void [assembly]Class::set_Prop(<T>)` NẾU
  `readonly=false`; `TranspileError` NẾU `readonly=true`.

- [ ] **Step 1: Thêm test thất bại — ghi property + readonly reject**

Thêm vào cuối `test/verify/extern_class_property_test.py` (TRƯỚC dòng
dọn file `for p in HERE.glob(...)`, cần chuyển đoạn dọn xuống cuối cùng):
```python
# Test 4: ghi property co the ghi (readonly=false)
src4 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["str"], "methods": [],
        "properties": [{"name": "Length", "dtype": "i32", "readonly": False}],
    },
]

def main() -> "i32":
    s = Sb("hello world")
    s.Length = 5
    print(s.Length)
    return 0
'''
tmp4 = HERE / '_extern_class_prop_write.tkv'
tmp4.write_text(src4, encoding='utf-8')
exe4 = compile_tkv_cli(str(tmp4), out_exe=str(HERE / '_extern_class_prop_write.exe'), entry_name='main')
r4 = subprocess.run([str(exe4)], capture_output=True, text=True)
check('prop_write_returncode', r4.returncode == 0, r4.stderr)
check('prop_write_output', r4.stdout.splitlines()[0].strip() == '5', repr(r4.stdout))

# Test 5: ghi property readonly=true -> TranspileError
src5 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [],
        "properties": [{"name": "Length", "dtype": "i32", "readonly": True}],
    },
]
def main() -> "i32":
    s = Sb()
    s.Length = 5
    return 0
'''
tmp5 = HERE / '_extern_class_prop_readonly_err.tkv'
tmp5.write_text(src5, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp5), out_exe=str(HERE / '_extern_class_prop_readonly_err.exe'), entry_name='main')
    check('prop_readonly_raises', False, 'khong raise')
except (TranspileError, SyntaxError):
    check('prop_readonly_raises', True)

# Test 6: isolation - dang ky get_X/set_X 2 lan lien tiep cung process, khac file
from compiler.il_dispatch import EXPR_METHOD_CODEGEN
src_iso = '''
__tkv_extern_class__ = [
    {"name": "H", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": [], "methods": [], "properties": [{"name": "Length", "dtype": "i32", "readonly": False}]},
]
def main() -> "i32":
    h = H()
    h.Length = 0
    print(h.Length)
    return 0
'''
tmp_iso1 = HERE / '_extern_class_prop_iso1.tkv'
tmp_iso2 = HERE / '_extern_class_prop_iso2.tkv'
tmp_iso1.write_text(src_iso, encoding='utf-8')
tmp_iso2.write_text(src_iso, encoding='utf-8')
check('iso_pre_clean', ('extern_class', 'get_Length') not in EXPR_METHOD_CODEGEN, 'da dang ky truoc khi test')
compile_tkv_cli(str(tmp_iso1), out_exe=str(HERE / '_extern_class_prop_iso1.exe'), entry_name='main')
check('iso_post1_clean', ('extern_class', 'get_Length') not in EXPR_METHOD_CODEGEN, 'khong pop sau lan 1')
check('iso_post1_set_clean', ('extern_class', 'set_Length') not in EXPR_METHOD_CODEGEN, 'khong pop set sau lan 1')
exe_iso2 = compile_tkv_cli(str(tmp_iso2), out_exe=str(HERE / '_extern_class_prop_iso2.exe'), entry_name='main')
check('iso2_builds', exe_iso2 is not None, 'lan 2 that bai')
check('iso_post2_clean', ('extern_class', 'get_Length') not in EXPR_METHOD_CODEGEN, 'khong pop sau lan 2')
```
Sửa đoạn dọn file cuối bài để cover cả file mới:
```python
for p in HERE.glob('_extern_class_prop_*'):
    if p.suffix == '.tkv':
        p.unlink()
    else:
        try:
            p.unlink()
        except OSError:
            pass
```
Cập nhật số lượng check tổng ở cuối file (`FAILED N/N` / `OK N/N`) cho
khớp tổng số check thật (5 cũ + số check mới ở Test 4/5/6 — đếm chính
xác lúc implement).

- [ ] **Step 2: Chạy, xác nhận FAIL**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_property_test.py`
Expected: FAIL ở `prop_write_returncode` — `codegen_attr_assign`'s guard
raise `SyntaxError` vì `Sb` có `shape='extern_class'`.

- [ ] **Step 3: Đăng ký `set_X` trong `compile_tkv_cli`** (chỉ property `readonly=false`)

Ngay sau đoạn đăng ký `get_X` (Task 2 Step 3), thêm:
```python
        if not _p['readonly']:
            _setter_key = ('extern_class', f"set_{_p['name']}")
            if _setter_key not in EXPR_METHOD_CODEGEN:
                register_expr_method(
                    'extern_class', f"set_{_p['name']}",
                    _make_extern_class_property_setter_codegen(f"set_{_p['name']}", _p['dtype']),
                    return_ta_fn=None,
                    result_shape=None)
                registered_extern_class_property_names.append(f"set_{_p['name']}")
```
Viết factory mới `_make_extern_class_property_setter_codegen` (đặt cạnh
`_make_extern_class_method_codegen` trong `compiler/il_codegen.py`) —
KHÁC method codegen ở điểm KHÔNG gọi `widen_if_needed` (không có giá trị
trả về):
```python
def _make_extern_class_property_setter_codegen(method_name, param_dtype):
    def _codegen(node, scope, out, dtype, ctx):
        obj_name = node[1]
        args = node[3] if len(node) > 3 else [node[2]] if len(node) > 2 else []
        # LUU Y: xac nhan CHINH XAC vi tri arg (RHS cua phep gan) trong
        # node duoc truyen vao tu codegen_attr_assign (Step 4) - dieu
        # chinh unpack cho dung, khong theo doan o day.
        obj_ta = scope[obj_name][2]
        decl = _EXTERN_CLASS_DEFS[obj_ta.dtype]
        ctx['load_var_ref'](obj_name, scope, out, ctx)
        il_param = _il_ctor_param_type(param_dtype, _EXTERN_CLASS_DEFS, ctx)
        ctx['compile_expr'](args[0], scope, out, param_dtype, ctx)
        class_ref = f"[{decl['assembly']}]{decl['class']}"
        out.append(f"    callvirt instance void {class_ref}::{method_name}({il_param})")
    return _codegen
```

- [ ] **Step 4: Nhánh mới trong `codegen_attr_assign`**

Trong `compiler/il_features/record_feature.py::codegen_attr_assign`,
chèn NGAY TRƯỚC guard hiện có (trước dòng 130):
```python
    obj_name, field_name = stmt['obj_name'], stmt['field_name']
    _, _, obj_ta = scope[obj_name]
    if obj_ta.shape == 'extern_class':
        from compiler import il_codegen as _ilc
        decl = _ilc._EXTERN_CLASS_DEFS.get(obj_ta.dtype)
        prop = next((p for p in (decl.get('properties') or []) if p['name'] == field_name), None) if decl else None
        if prop is None:
            raise SyntaxError(
                f"il_codegen: '.{field_name}' khong phai property da khai cua "
                f"handle type {obj_ta.dtype!r}")
        if prop['readonly']:
            raise TranspileError(
                f"il_codegen: property {field_name!r} cua {obj_ta.dtype!r} la "
                f"readonly, khong the gan gia tri")
        registered = EXPR_METHOD_CODEGEN.get(('extern_class', f'set_{field_name}'))
        if registered is None:
            raise SyntaxError(f"il_codegen: setter cho property {field_name!r} chua duoc dang ky")
        rhs_expr_node = stmt['value_node']  # XAC NHAN ten key that trong stmt dict, doc lai try_parse_attr_assign
        fake_node = ('attr_assign', obj_name, f'set_{field_name}', [rhs_expr_node])
        registered(fake_node, scope, out, None, ctx)
        return
```
**LƯU Ý implementer**: `stmt` dict's field chứa RHS expression (tên key
CHÍNH XÁC — có thể là `'value_node'`, `'rhs'`, hoặc tương tự) PHẢI xác
nhận bằng cách đọc `try_parse_attr_assign` (dòng 115-124) VÀ
`codegen_attr_assign`'s phần record hiện có (dòng 134-152, cách nó dùng
RHS để compile giá trị gán) — sửa `fake_node`/truy cập `stmt[...]` cho
khớp THẬT, không theo tên đoán ở bản nháp trên.

- [ ] **Step 5: `finally`-pop mở rộng cho `set_X`**

`registered_extern_class_property_names` (Task 2 Step 5's list) ĐÃ chứa
cả `get_X` và `set_X` nếu Step 3 append đúng cách — xác nhận vòng
`finally`-pop hiện có (Task 2 Step 5) pop ĐÚNG cả 2, không cần code
riêng nếu dùng chung 1 list.

- [ ] **Step 6: Chạy lại, xác nhận PASS**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_property_test.py`
Expected: `OK <N>/<N>` (toàn bộ, số lượng xác nhận đúng theo Step 1).

- [ ] **Step 7: Regression toàn bộ**

Run:
```bash
cd "D:\Claude AI Project\TokenVector"
python test/verify/extern_class_property_parse_test.py
python test/verify/extern_class_property_test.py
python test/verify/extern_class_parse_test.py
python test/verify/extern_class_typesystem_test.py
python test/verify/extern_class_ctor_test.py
python test/verify/extern_class_method_test.py
python test/verify/extern_class_test.py
python test/verify/extern_method_test.py
python test/verify/extern_pinvoke_test.py
python test/verify/duck_typing_infer_test.py
python test/verify/record_test.py
python test/verify/record_method_test.py
```
Expected: tất cả PASS.

- [ ] **Step 8: Commit**

```bash
git add compiler/il_codegen.py compiler/il_features/record_feature.py tkv_compile.py test/verify/extern_class_property_test.py
git commit -m "feat(compiler): ghi property (set_X qua callvirt) + readonly enforcement cho extern-class (Task 3, extern-class-property)"
```

---

### Task 4: Duck-typing reject xác nhận + `+=` compound-assign + docs + commit cuối

**Files:**
- Modify: `test/verify/extern_class_test.py` (thêm case duck-typing +
  compound-assign vào file test tổng hợp hiện có)
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`
- Test: chạy toàn bộ regression cuối cùng

**Interfaces:**
- Consumes: Task 1-3.
- Produces: xác nhận (không code mới trừ khi phát hiện gap thật) property
  của handle type bị chặn trong duck-typing-inference, và `obj.Prop += x`
  hoạt động đúng qua `try_expand_compound_attr` (đã xác nhận tự động
  hoạt động, chỉ cần TEST xác nhận thật).

- [ ] **Step 1: Viết test thất bại — property trong duck-typing + compound-assign**

Thêm vào `test/verify/extern_class_test.py`:
```python
def test_duck_typing_rejects_handle_type_property():
    src = '''
__tkv_extern_class__ = [
    {"name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": [], "methods": [], "properties": [{"name": "Length", "dtype": "i32", "readonly": True}]},
]

def f(x) -> "i32":
    return x.Length

def main() -> "i32":
    s = Sb()
    return f(s)
'''
    tmp = HERE / '_extern_class_prop_ducktyping.tkv'
    tmp.write_text(src, encoding='utf-8')
    try:
        compile_tkv_cli(str(tmp), out_exe=str(HERE / '_extern_class_prop_ducktyping.exe'), entry_name='main')
        check('prop_ducktyping_reject_raises', False, 'khong raise - property handle type LOT qua duck-typing!')
    except TranspileError:
        check('prop_ducktyping_reject_raises', True)
    finally:
        tmp.unlink()

def test_compound_assign_on_property():
    src = '''
__tkv_extern_class__ = [
    {"name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder", "ctor": ["str"], "methods": [], "properties": [{"name": "Length", "dtype": "i32", "readonly": False}]},
]

def main() -> "i32":
    s = Sb("hello")
    s.Length += 1
    print(s.Length)
    return 0
'''
    tmp = HERE / '_extern_class_prop_compound.tkv'
    tmp.write_text(src, encoding='utf-8')
    exe = compile_tkv_cli(str(tmp), out_exe=str(HERE / '_extern_class_prop_compound.exe'), entry_name='main')
    r = subprocess.run([str(exe)], capture_output=True, text=True)
    check('compound_returncode', r.returncode == 0, r.stderr)
    check('compound_output', r.stdout.splitlines()[0].strip() == '6', repr(r.stdout))
    tmp.unlink()
```
(Điều chỉnh cách gọi 2 hàm này vào đúng luồng chạy chính của
`extern_class_test.py` — file này dùng style hàm rời hay chạy tuần tự
top-level, xác nhận cấu trúc thật của file trước khi thêm, gọi 2 hàm này
ở đúng chỗ trong file.)

- [ ] **Step 2: Chạy, xác nhận PASS (hoặc phát hiện gap thật)**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_test.py`
Kỳ vọng: PASS cả 2. Nếu `test_duck_typing_rejects_handle_type_property`
FAIL — đọc lại guard đã thêm ở Phase 3 Task 5 (`compiler/il_features/duck_typing.py::_check_constraint`)
để xác nhận nó có bắt được `FieldConstraint` sinh từ `x.Length` (property
đọc dùng CÙNG cú pháp attribute-access với field record, nên duck-typing's
constraint-collector RẤT CÓ THỂ đã coi nó là `FieldConstraint` từ trước,
guard hiện có PHẢI đã bắt đúng) — nếu THẬT SỰ có gap (guard không bắt),
sửa TRỰC TIẾP theo đúng pattern guard hiện có, không viết cơ chế mới.
Nếu `test_compound_assign_on_property` FAIL — đọc lại `try_expand_compound_attr`
(dòng 102-112) để xác nhận macro có áp dụng ĐÚNG cho property (không chỉ
record field) — sửa nếu có gap thật, macro là text-level nên rất có khả
năng đã tự hoạt động đúng.

- [ ] **Step 3: Regression CUỐI toàn bộ (cổng chấp nhận toàn plan)**

Run:
```bash
cd "D:\Claude AI Project\TokenVector"
python test/verify/extern_class_property_parse_test.py
python test/verify/extern_class_property_test.py
python test/verify/extern_class_parse_test.py
python test/verify/extern_class_typesystem_test.py
python test/verify/extern_class_ctor_test.py
python test/verify/extern_class_method_test.py
python test/verify/extern_class_test.py
python test/verify/extern_method_test.py
python test/verify/extern_pinvoke_test.py
python test/verify/duck_typing_infer_test.py
python test/verify/record_test.py
python test/verify/record_method_test.py
python test/verify/string_test.py
python test/verify/expr_method_compose_test.py
```
Expected: tất cả PASS.

- [ ] **Step 4: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Trong mục "#1 Package ecosystem"'s đoạn `__tkv_extern_class__` (Phase 3),
thêm đoạn Phase 4 ĐÃ XONG theo văn phong hiện có — link tới plan/spec
này, liệt kê "Đã làm" (property get/set qua `properties` key, readonly
mặc định true, tái dùng callvirt dispatch của Phase 3) và "CHƯA làm"
(copy nguyên mục "Giới hạn KHÔNG làm" từ spec: static property, indexer,
container dtype, reflection auto-detect). Ghi chú lại mirror tree VẪN
CHƯA port (kế thừa từ Phase 3, không phải gap mới).

- [ ] **Step 5: Cập nhật ledger SDD**

```bash
cd "D:\Claude AI Project"
echo "PLAN THUC SU DONG: extern-class-property (#1 Phase 4) - 4 task xong, review sach." >> .superpowers/sdd/progress.md
```

- [ ] **Step 6: Commit cuối**

```bash
cd "D:\Claude AI Project\TokenVector"
git add test/verify/extern_class_test.py docs/PYTHON_GAP_CHECKLIST.md
git commit -m "feat(compiler): extern-class Phase 4 hoan tat - duck-typing reject xac nhan + compound-assign + docs (Task 4, extern-class-property)"
```

---

## Self-Review

**Spec coverage**: khai báo `properties` key (Task 1) → đọc `get_X`
(Task 2) → ghi `set_X` + readonly (Task 3) → duck-typing reject xác
nhận + compound-assign + docs (Task 4). Mọi mục "Kiểm chứng" của spec có
task/step tương ứng: đọc property (Task 2), ghi property (Task 3), lỗi
readonly (Task 3), lỗi trùng tên get_X/set_X với method thật (Task 1),
property trả về handle type khác (Task 2 Step 1 Test 2 dùng chaining —
mở rộng thêm nếu cần property TRẢ VỀ handle type thay vì chỉ scalar, xác
nhận lúc implement có cần thêm case này không), tương thích Phase 1-3
(regression mọi task), duck-typing reject (Task 4), mirror tree ghi chú
lại (Task 4 Step 4).

**Điểm KHÔNG chắc chắn 100% cần implementer tự xác nhận lúc thực thi**
(đã ghi rõ trong từng Step, không phải placeholder mà là rủi ro thật do
không đọc được TOÀN BỘ file trong lúc viết plan): cơ chế `_extern_class_method_lookup`
có tự tra được `get_X`/`set_X` hay cần tiền xử lý bổ sung methods giả
(Task 2 Step 3), cấu trúc CHÍNH XÁC của `node`/`stmt` mà closure codegen
nhận (Task 2 Step 4, Task 3 Step 3-4) — mỗi điểm đều có hướng dẫn "đọc
code X trước, xác nhận rồi mới viết".
