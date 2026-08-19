# `__tkv_extern_class__` Phase 5 — `list[T]` Container Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cho `params`/`returns` (ctor, method, property) của
`__tkv_extern_class__` chấp nhận dtype dạng `"list[T]"` (T là scalar hoặc
1 handle type đã khai), sinh đúng CIL `class
[mscorlib]System.Collections.Generic.List\`1<T_il>`, tương thích trực
tiếp với biến `list[...]` DSL đã có.

**Architecture:** TÁI DÙNG NGUYÊN parser `parse_type_ann_str` (đã hỗ trợ
SẴN cả `list[scalar]` VÀ `list[extern_class_name]` — xác nhận qua đọc
code thật) cho việc validate; mở rộng `_il_ctor_param_type` (và
`il_list_elem_ilstr`) để sinh đúng CIL type-string cho phần tử là handle
type. Không viết parser mới, không viết cơ chế generic mới — CHỈ nối 2
hệ thống sẵn có (extern-class dtype validation ↔ `list[...]` type-ann
parser ↔ `List<T>` CIL codegen).

**Tech Stack:** Python 3, CIL text, `ilasm.exe` (.NET Framework mscorlib
v4.0.30319, Windows-only).

## Global Constraints

- CHỈ `System.Collections.Generic.List\`1<T>` cụ thể — KHÔNG
  `Dictionary<K,V>`, KHÔNG `IEnumerable<T>`/`IList<T>`/mảng `T[]`. Sai
  chữ ký (API .NET thật trả interface thay vì `List<T>` cụ thể) → build
  OK nhưng `InvalidCastException` lúc chạy — PHẢI ghi cảnh báo rõ trong
  docs.
- `T` (phần tử): scalar (`i32/i64/f32/f64/str`) HOẶC 1 handle type ĐÃ
  khai trong CÙNG `__tkv_extern_class__`.
- KHÔNG container-của-container (`list[list[i32]]`).
- KHÔNG tự dò chữ ký .NET qua reflection tự động — người dùng tự xác
  minh (nguyên tắc dự án xuyên suốt). NHƯNG plan này (Task 1) PHẢI tự xác
  minh chữ ký dùng cho TEST bằng PowerShell reflection thật trước khi
  chốt — KHÔNG đoán 1 API .NET có tồn tại.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`. Mirror tree
  `release/3.code/build/pyinstaller_src/` ĐÃ XÁC NHẬN (nhiều lần) chưa có
  nền tảng `__tkv_extern_class__` — Phase 5 này CŨNG không port, chỉ ghi
  chú lại.
- KHÔNG chạm `compiler/il_features/operators.py`.

---

## Bối cảnh code đã xác nhận (đọc trước Task 1)

**`compiler/il_codegen.py`**:
- `_il_ctor_param_type(dtype_name, extern_class_defs)`: dòng 1690-1699.
  Hiện CHỈ xử lý handle-type (`dtype_name in extern_class_defs`) hoặc
  scalar (`IL_SCALAR[dtype_name]`) — KHÔNG có nhánh `list[...]`, sẽ
  `KeyError` nếu gặp `'list[i32]'`.
- `_EXTERN_CLASS_DEFS = {}` module-level: dòng 128. Lưu dtype string
  NGUYÊN VĂN từ pragma (KHÔNG parse/normalize lúc đăng ký) — vd
  `'list[i32]'` lưu y hệt chuỗi gốc.
- Gọi `_il_ctor_param_type` từ `tkv_compile.py` dòng 1184/1186/1223 (qua
  `il_codegen._il_ctor_param_type(...)`), và nội bộ dòng 1722.

**`tkv_compile.py`** — 4 điểm validate dtype RIÊNG BIỆT (không có helper
dùng chung, mỗi điểm viết lặp lại pattern giống nhau qua các Task trước):
| # | Vị trí | Dòng | Code hiện tại |
|---|--------|------|------|
| 1 | ctor params | ~2499 | `if _pdtype not in _EXTERN_DTYPE_TO_IL and _pdtype not in extern_class_defs:` |
| 2 | method params | ~2522 | `if _pdtype not in _EXTERN_DTYPE_TO_IL and _pdtype not in extern_class_defs:` |
| 3 | method returns | ~2540 | `if _m['returns'] not in _EXTERN_DTYPE_TO_IL and _m['returns'] not in extern_class_defs:` |
| 4 | property dtype | ~2562 | `if _p['dtype'] not in _EXTERN_DTYPE_TO_IL and _p['dtype'] not in extern_class_defs:` |

Cả 4 nằm trong `compile_tkv_cli`, các vòng lặp ~2482-2503 (ctor),
~2510-2544 (methods), ~2551-2575 (properties). Dòng số CÓ THỂ xê dịch nhẹ
— đọc lại thật trước khi sửa, KHÔNG tin tuyệt đối số dòng.

**`compiler/typed_dsl_parser.py`** — parser TÁI DÙNG ĐƯỢC NGUYÊN VẸN:
`parse_type_ann_str(text, record_names=frozenset(), extern_class_names=frozenset())`,
dòng 476-489:
```python
def parse_type_ann_str(text: str, record_names=frozenset(), extern_class_names=frozenset()) -> TypeAnn:
    tokens = tokenize(text)
    parser = Parser(tokens, text, record_names=record_names,
                     extern_class_names=extern_class_names)
    ta = parser.parse_type_ann()
    k, v, pos = parser.peek()
    if k != 'EOF':
        raise SyntaxError(f"Kieu {text!r} con thua token {v!r} (vi tri ~{pos})")
    return ta
```
`Parser.parse_type_ann`'s nhánh `'list'` (dòng 200-207) ĐÃ xử lý CẢ 2
case: `list[i32]` (scalar) VÀ `list[MyHandleType]` (handle type qua
`extern_class_names` — cơ chế này đã tồn tại từ TRƯỚC, có thể từ Phase 3,
xác nhận lúc implement). Trả về `TypeAnn(elem_dtype, 'list', elem_ta=...)`.
**Dùng hàm này để VALIDATE** ở cả 4 điểm trong `tkv_compile.py` (Task 1)
— gọi `parse_type_ann_str(dtype_str, extern_class_names=set(extern_class_defs))`,
bắt `SyntaxError`, re-raise `TranspileError`. **Container-của-container**
(`list[list[i32]]`) — XÁC NHẬN lúc implement liệu `Parser.parse_type_ann`
có tự chặn hay tự cho qua (đọc code thật) — nếu tự CHO QUA (không chặn),
Task 1 PHẢI thêm guard riêng chặn `elem_ta.shape == 'list'` sau khi parse.

**`compiler/il_features/list_type.py`**:
- `il_list_elem_ilstr(dtype: str, records: dict = None) -> str`: dòng
  22-37. CHỈ biết scalar (`IL_SCALAR`) hoặc `records` dict (record type,
  trả `f'class {dtype}'` — KHÔNG assembly-qualified, chỉ đúng cho class
  DO COMPILER TỰ SINH). KHÔNG biết `extern_class_defs` — PHẢI mở rộng
  thêm 1 tham số/nhánh mới cho handle type (trả
  `f"class [{d['assembly']}]{d['class']}"`, giống `_il_ctor_param_type`).
- `il_list_type(dtype, records=None)`: dòng 40-45, bọc
  `f'class [mscorlib]System.Collections.Generic.List\`1<{il_list_elem_ilstr(dtype, records)}>'`
  — TÁI DÙNG NGUYÊN, chỉ cần `il_list_elem_ilstr` hỗ trợ đúng elem là
  handle type.
- **KHÔNG import sẵn trong `tkv_compile.py`** — cần `from
  il_features.list_type import il_list_elem_ilstr` (hoặc `il_list_type`)
  mới, xác nhận đúng đường import theo cách các file `il_features/*` khác
  đã làm (module này thiết kế ĐỘC LẬP, không phụ thuộc `il_codegen.py`
  trực tiếp — đọc docstring dòng 6-12 trước khi sửa, tránh phá nguyên tắc
  chống circular-import).

**Test tích cực — CHƯA có API .NET xác nhận trước** — Task 1 PHẢI tự xác
minh qua PowerShell reflection thật (KHÔNG đoán) trước khi viết test. Ứng
viên cần tìm: 1 method/constructor/property trong `mscorlib`
(hoặc `System`) mà chữ ký CIL trả về/nhận ĐÚNG
`System.Collections.Generic.List\`1<T>` (KHÔNG phải `IEnumerable<T>`/
`IList<T>`/mảng). Nếu KHÔNG tìm được ứng viên `mscorlib` thuần túy phù
hợp, phương án dự phòng: dùng CHÍNH `List<T>`'s method
`AddRange(IEnumerable<T>)` KHÔNG DÙNG ĐƯỢC (interface) — thay vào đó cân
nhắc viết 1 class .NET tối giản test-only (biên dịch bằng `csc.exe` có
sẵn trên máy .NET Framework) làm assembly phụ trợ CHỈ để test — GHI RÕ
trong test đây là fixture test-only, không phải minh chứng cho use-case
thật với thư viện `mscorlib` (đã có tiền lệ tương tự ở Phase 3's spec
với `MyMathLib` giả định).

**Test template**: `test/verify/extern_class_property_test.py` (171
dòng) — cấu trúc tham khảo cho `test/verify/extern_class_list_test.py`.

---

### Task 1: Validate `list[T]` dtype tại 4 điểm + xác minh API test qua reflection thật

**Files:**
- Modify: `tkv_compile.py` (4 điểm validate)
- Test: `test/verify/extern_class_list_parse_test.py` (mới, chỉ validate
  — không codegen, vì codegen là Task 2)

**Interfaces:**
- Consumes: `parse_type_ann_str` (`compiler/typed_dsl_parser.py`, đã
  có), `extern_class_defs` (dict đã có từ Phase 3 Task 1).
- Produces: 4 điểm validate ở `tkv_compile.py` chấp nhận `list[T]` hợp lệ,
  từ chối `list[list[T]]`/`list[<dtype không hợp lệ>]` bằng
  `TranspileError`.

- [ ] **Step 1: XÁC MINH qua PowerShell reflection thật — tìm 1 API .NET
  trả/nhận `List<T>` cụ thể**

Chạy PowerShell (không đoán, xác nhận output thật trước khi dùng trong
test — vd thử các ứng viên sau, ghi lại kết quả THẬT):
```powershell
[System.Text.RegularExpressions.Regex].GetMethods() | Where-Object { $_.ReturnType.FullName -like "*List``1*" } | Select-Object Name, ReturnType
[System.Random].GetMethods() | Where-Object { $_.ReturnType.FullName -like "*List``1*" }
```
Nếu KHÔNG tìm được ứng viên `mscorlib`/`System` phù hợp sau vài lần thử,
tạo 1 class .NET test-only tối giản, biên dịch bằng `csc.exe` (có sẵn
trên .NET Framework), đặt cạnh `.exe` test lúc build — vd:
```csharp
// test/verify/_fixtures/ListContainerTestLib.cs
using System.Collections.Generic;
public class ListContainerHelper {
    public static List<int> MakeInts(int n) {
        var r = new List<int>();
        for (int i = 0; i < n; i++) r.Add(i);
        return r;
    }
    public int Sum(List<int> xs) {
        int s = 0;
        foreach (var x in xs) s += x;
        return s;
    }
}
```
Ghi RÕ trong `test/verify/extern_class_list_test.py` (Task 3) đây là
fixture test-only nếu dùng hướng này. Ghi kết quả xác minh (API tìm
được HOẶC quyết định dùng fixture riêng) vào báo cáo implementer.

- [ ] **Step 2: Viết test thất bại cho validate `list[T]`**

Tạo `test/verify/extern_class_list_parse_test.py`:
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

# Test 1: list[scalar] hop le trong ctor
src1 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [{"name": "ToString", "params": [], "returns": "list[i32]"}],
    },
]
def main() -> "i32":
    return 0
'''
tmp1 = HERE / '_extern_class_list_parse_ok.tkv'
tmp1.write_text(src1, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp1), out_exe=str(HERE / '_extern_class_list_parse_ok.exe'), entry_name='main')
    check('list_scalar_return_accepted', True)
except TranspileError as e:
    check('list_scalar_return_accepted', False, f'bi tu choi nham: {e}')

# Test 2: list[HandleType] hop le
src2 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [{"name": "Foo", "params": [], "returns": "list[Sb]"}],
    },
]
def main() -> "i32":
    return 0
'''
tmp2 = HERE / '_extern_class_list_parse_handle.tkv'
tmp2.write_text(src2, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp2), out_exe=str(HERE / '_extern_class_list_parse_handle.exe'), entry_name='main')
    check('list_handle_return_accepted', True)
except TranspileError as e:
    check('list_handle_return_accepted', False, f'bi tu choi nham: {e}')

# Test 3: list[list[i32]] -> TranspileError
src3 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [{"name": "Bad", "params": [], "returns": "list[list[i32]]"}],
    },
]
def main() -> "i32":
    return 0
'''
tmp3 = HERE / '_extern_class_list_parse_nested_err.tkv'
tmp3.write_text(src3, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp3), out_exe=str(HERE / '_extern_class_list_parse_nested_err.exe'), entry_name='main')
    check('nested_list_rejected', False, 'khong raise')
except TranspileError:
    check('nested_list_rejected', True)

# Test 4: list[bignum] (dtype ben trong khong hop le) -> TranspileError
src4 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": [], "methods": [{"name": "Bad2", "params": [], "returns": "list[bignum]"}],
    },
]
def main() -> "i32":
    return 0
'''
tmp4 = HERE / '_extern_class_list_parse_baddtype_err.tkv'
tmp4.write_text(src4, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp4), out_exe=str(HERE / '_extern_class_list_parse_baddtype_err.exe'), entry_name='main')
    check('bad_inner_dtype_rejected', False, 'khong raise')
except TranspileError:
    check('bad_inner_dtype_rejected', True)

# Test 5: list[T] trong ctor params + property dtype cung phai validate dung
src5 = '''
__tkv_extern_class__ = [
    {
        "name": "Sb", "assembly": "mscorlib", "class": "System.Text.StringBuilder",
        "ctor": ["list[i32]"], "methods": [],
        "properties": [{"name": "X", "dtype": "list[str]", "readonly": True}],
    },
]
def main() -> "i32":
    return 0
'''
tmp5 = HERE / '_extern_class_list_parse_ctor_prop.tkv'
tmp5.write_text(src5, encoding='utf-8')
try:
    compile_tkv_cli(str(tmp5), out_exe=str(HERE / '_extern_class_list_parse_ctor_prop.exe'), entry_name='main')
    check('list_ctor_and_property_accepted', True)
except TranspileError as e:
    check('list_ctor_and_property_accepted', False, f'bi tu choi nham: {e}')

for p in HERE.glob('_extern_class_list_parse_*'):
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
**LƯU Ý**: Test 1/2/5 sẽ FAIL ở BƯỚC CODEGEN (không phải validate) nếu
Task 1 hoàn thành nhưng Task 2 chưa — vì `compile_tkv_cli` chạy validate
XONG rồi mới tới codegen (`_il_ctor_param_type` sẽ `KeyError` trên
`'list[i32]'` nếu Task 2 chưa xong). Nếu gặp `KeyError` (không phải
`TranspileError`) ở bước này, đó là dấu hiệu ĐÚNG rằng validate (Task 1)
đã pass nhưng codegen (Task 2) chưa — CHẤP NHẬN ĐƯỢC tạm thời, ghi rõ
trong báo cáo, KHÔNG cố sửa codegen ở Task 1 (giữ đúng ranh giới task).
Nếu implementer thấy điều này gây khó viết test sạch, có thể tách Step 2
thành gọi trực tiếp hàm validate nội bộ (nếu tách được thành hàm riêng)
thay vì qua `compile_tkv_cli` toàn bộ — quyết định lúc implement.

- [ ] **Step 3: Chạy test, xác nhận trạng thái ban đầu** (rất có thể FAIL
  vì dtype string `'list[i32]'` hiện chưa qua `_EXTERN_DTYPE_TO_IL`/
  `extern_class_defs` check nào — sẽ bị từ chối SAI ở bước validate)

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_list_parse_test.py`

- [ ] **Step 4: Sửa 4 điểm validate trong `tkv_compile.py`**

Tại MỖI trong 4 điểm (đọc lại số dòng THẬT trước khi sửa — bảng trên chỉ
là ước lượng lúc điều tra), thay:
```python
if _pdtype not in _EXTERN_DTYPE_TO_IL and _pdtype not in extern_class_defs:
    raise TranspileError(...)
```
thành (import `parse_type_ann_str` ở đầu file nếu chưa có — xác nhận
đường import đúng: `from typed_dsl_parser import parse_type_ann_str`,
KHÔNG phải `from compiler.typed_dsl_parser import ...`, theo đúng quy ước
flat-import đã xác nhận ở phiên trước cho `il_dispatch`):
```python
if _pdtype not in _EXTERN_DTYPE_TO_IL and _pdtype not in extern_class_defs:
    if _pdtype.startswith('list['):
        try:
            _list_ta = parse_type_ann_str(_pdtype, extern_class_names=set(extern_class_defs))
        except SyntaxError as e:
            raise TranspileError(
                f"__tkv_extern_class__: dtype {_pdtype!r} khong hop le - {e}")
        if _list_ta.elem_ta is not None and _list_ta.elem_ta.shape == 'list':
            raise TranspileError(
                f"__tkv_extern_class__: dtype {_pdtype!r} - KHONG ho tro "
                f"container-cua-container (list long nhau)")
    else:
        raise TranspileError(...)  # giu nguyen message loi cu cho nhanh khong phai list
```
**LƯU Ý implementer**: cấu trúc `TypeAnn` trả về từ `parse_type_ann_str`
cho `list[T]` — thuộc tính chính xác chứa "phần tử" (`elem_ta`? hay khác
tên?) PHẢI xác nhận bằng cách đọc `TypeAnn` class definition VÀ nhánh
`'list'` của `Parser.parse_type_ann` (dòng 200-207) trước khi viết code
trên — sửa tên thuộc tính cho khớp THẬT, không theo đoán ở bản nháp này.
Áp dụng CÙNG pattern cho cả 4 điểm (ctor/method-params/method-returns/
property) — có thể cân nhắc factor thành 1 helper dùng chung
`_validate_extern_class_dtype(dtype_str, extern_class_defs, ctx_label)`
nếu thấy lặp lại quá nhiều (4 lần) — quyết định lúc implement, không bắt
buộc nếu 4 điểm có ngữ cảnh lỗi hơi khác nhau khó gộp sạch.

- [ ] **Step 5: Chạy lại, xác nhận validate PASS** (codegen có thể vẫn
  lỗi `KeyError` — CHẤP NHẬN theo Step 2's lưu ý, xác nhận đây ĐÚNG là
  `KeyError` không phải `TranspileError` sai)

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_list_parse_test.py`
Expected: Test 3/4 (case lỗi) PASS. Test 1/2/5 (case hợp lệ) CÓ THỂ vẫn
fail nếu đường codegen bên dưới đụng `KeyError` — nếu vậy, sửa test tạm
thời để CHỈ assert KHÔNG raise `TranspileError` (KHÔNG assert build hoàn
tất) ở bước này, note rõ "codegen hoàn tất ở Task 2" trong comment test.

- [ ] **Step 6: Regression Phase 1-4**

Run:
```bash
cd "D:\Claude AI Project\TokenVector"
python test/verify/extern_class_list_parse_test.py
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
```
Expected: tất cả PASS.

- [ ] **Step 7: Commit**

```bash
git add tkv_compile.py test/verify/extern_class_list_parse_test.py
git commit -m "feat(compiler): validate dtype list[T] cho __tkv_extern_class__ (Task 1, extern-class-list)"
```

---

### Task 2: Codegen `List<T>` — mở rộng `_il_ctor_param_type` + `il_list_elem_ilstr`

**Files:**
- Modify: `compiler/il_codegen.py` (`_il_ctor_param_type`)
- Modify: `compiler/il_features/list_type.py` (`il_list_elem_ilstr` — thêm
  tham số/nhánh handle type)
- Test: mở rộng `test/verify/extern_class_list_parse_test.py` thành build
  THẬT (không chỉ validate)

**Interfaces:**
- Consumes: `_EXTERN_CLASS_DEFS`/`extern_class_defs` (đã có), Task 1's
  validate.
- Produces: `_il_ctor_param_type('list[i32]', extern_class_defs)` trả
  đúng `'class [mscorlib]System.Collections.Generic.List\`1<int32>'`;
  tương tự cho `list[HandleType]`.

- [ ] **Step 1: Mở rộng test — build+chạy THẬT cho case `list[scalar]`**

Sửa `test/verify/extern_class_list_parse_test.py`'s Test 1/2/5 (từ Task
1) thành assert build THÀNH CÔNG HOÀN TOÀN (không chỉ "không raise
TranspileError") — sau khi Task 2 xong, `KeyError` không còn xảy ra nữa.
Đổi assertion từ try/except-chỉ-bắt-TranspileError sang assert
`compile_tkv_cli(...)` trả về đường dẫn `.exe` hợp lệ (không raise gì
cả).

- [ ] **Step 2: Chạy, xác nhận FAIL đúng chỗ** (nếu Task 1 đã xong,
  `KeyError` xuất hiện đúng như dự kiến)

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_list_parse_test.py`
Expected: FAIL với `KeyError: 'list[i32]'` (hoặc tương tự) từ
`_il_ctor_param_type`/`IL_SCALAR[dtype_name]`.

- [ ] **Step 3: Mở rộng `il_list_elem_ilstr` cho handle type**

Trong `compiler/il_features/list_type.py`, sửa hàm (dòng 22-37) thêm
tham số `extern_class_defs=None`:
```python
def il_list_elem_ilstr(dtype: str, records: dict = None, extern_class_defs: dict = None) -> str:
    elem = IL_SCALAR.get(dtype)
    if elem is not None:
        return elem
    if records and dtype in records:
        return f'class {dtype}'
    if extern_class_defs and dtype in extern_class_defs:
        d = extern_class_defs[dtype]
        return f"class [{d['assembly']}]{d['class']}"
    raise SyntaxError(
        f"il_codegen: List phan tu kieu {dtype!r} khong hop le - phai la dtype vo huong "
        f"(f32/f64/i32/i64/str) hoac ten 1 class dang record/extern-class da khai bao")
```
Cập nhật `il_list_type` (dòng 40-45) thread thêm `extern_class_defs`
tham số nếu chưa có, truyền xuống `il_list_elem_ilstr`. **LƯU Ý**: kiểm
tra lại MỌI call site HIỆN CÓ của `il_list_elem_ilstr`/`il_list_type`
(grep toàn repo) — thêm tham số MẶC ĐỊNH `None` để KHÔNG phá call site
cũ (record-only, chưa biết `extern_class_defs`).

- [ ] **Step 4: Mở rộng `_il_ctor_param_type` trong `compiler/il_codegen.py`**

Sửa dòng 1690-1699:
```python
def _il_ctor_param_type(dtype_name, extern_class_defs):
    if dtype_name in extern_class_defs:
        d = extern_class_defs[dtype_name]
        return f"class [{d['assembly']}]{d['class']}"
    if dtype_name.startswith('list['):
        elem_dtype = dtype_name[len('list['):-1]
        from il_features.list_type import il_list_elem_ilstr
        elem_il = il_list_elem_ilstr(elem_dtype, records=None, extern_class_defs=extern_class_defs)
        return f"class [mscorlib]System.Collections.Generic.List`1<{elem_il}>"
    return IL_SCALAR[dtype_name]
```
**LƯU Ý implementer**: cách trích `elem_dtype` từ chuỗi `'list[i32]'`
bằng slicing thô (`dtype_name[len('list['):-1]`) là CÁCH ĐƠN GIẢN NHẤT
nếu dtype string LUÔN đúng format `list[X]` (đã qua validate Task 1) —
NHƯNG nếu `X` bản thân chứa dấu `]` lồng (không nên xảy ra vì Task 1 đã
chặn container-của-container, nhưng xác nhận lại KHÔNG có edge case khác
như `list[dict[str,i32]]` bị hiểu nhầm) thì cần dùng
`parse_type_ann_str` (đã dùng ở Task 1) để lấy `elem_ta.dtype` CHÍNH XÁC
thay vì slicing chuỗi — CÂN NHẮC dùng `parse_type_ann_str` ở ĐÂY luôn
(nhất quán với Task 1, tránh 2 cách trích elem-dtype khác nhau ở 2 nơi)
thay vì slicing — quyết định lúc implement, ưu tiên nhất quán.

Import `from il_features.list_type import il_list_elem_ilstr` đặt Ở ĐÂU
(module-level đầu file hay import cục bộ trong hàm) — xác nhận có rủi ro
circular-import không (đọc lại docstring `list_type.py` dòng 6-12 đã nêu
ở phần điều tra) trước khi quyết định vị trí import.

- [ ] **Step 5: Chạy lại, xác nhận PASS**

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_list_parse_test.py`
Expected: `OK 5/5` (build hoàn tất thật, không còn `KeyError`).

- [ ] **Step 6: Regression Task 1 + Phase 1-4**

Run:
```bash
cd "D:\Claude AI Project\TokenVector"
python test/verify/extern_class_list_parse_test.py
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
python test/verify/list_test.py
python test/verify/list_methods_test.py
```
Expected: tất cả PASS. ĐẶC BIỆT `list_test.py`/`list_methods_test.py`
(hoặc tên file test list thật — xác nhận đúng tên file lúc implement, có
thể khác) xác nhận `list[...]` DSL THƯỜNG (không qua extern-class) không
bị ảnh hưởng bởi thay đổi chữ ký `il_list_elem_ilstr`.

- [ ] **Step 7: Commit**

```bash
git add compiler/il_codegen.py compiler/il_features/list_type.py test/verify/extern_class_list_parse_test.py
git commit -m "feat(compiler): sinh CIL List<T> cho dtype list[T] trong extern-class (Task 2, extern-class-list)"
```

---

### Task 3: Test tổng hợp thật (build+chạy với API .NET đã xác minh) + docs + commit cuối

**Files:**
- Create: `test/verify/extern_class_list_test.py` (mới, dùng API/fixture
  đã xác minh ở Task 1 Step 1)
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`
- Test: chạy toàn bộ regression cuối cùng

**Interfaces:**
- Consumes: Task 1-2.
- Produces: test end-to-end thật với `.exe` chạy, đối chiếu giá trị đúng;
  checklist cập nhật.

- [ ] **Step 1: Viết test thất bại — build+chạy thật với API/fixture đã xác minh**

Dùng KẾT QUẢ xác minh ở Task 1 Step 1 (API `mscorlib` thật HOẶC fixture
`.cs` test-only). Viết `test/verify/extern_class_list_test.py` theo
template `extern_class_property_test.py` (xem điều tra §7): ít nhất 3
case —
1. Method/property trả `list[i32]` (hoặc `list[str]`) — build, chạy,
   lặp qua kết quả bằng `list[...]` DSL có sẵn (`for x in lst:` hoặc
   index/`len()`), in tổng/giá trị cụ thể, đối chiếu.
2. Method nhận `list[i32]` làm tham số — tạo 1 `list[i32]` DSL bình
   thường (KHÔNG qua extern-class), truyền thẳng vào method, xác nhận
   marshaling đúng.
3. Method trả `list[HandleType]` (phần tử là handle type khác) — lặp
   qua, gọi method/đọc property TRÊN TỪNG phần tử, xác nhận đúng.

Nếu dùng fixture `.cs` test-only (Task 1 Step 1's phương án dự phòng):
biên dịch fixture đó THÀNH `.dll` TRƯỚC khi test chạy (dùng `csc.exe` —
xác nhận đường dẫn `csc.exe` chuẩn trên .NET Framework, có thể cần build
step riêng trong test file hoặc 1 script `.ps1` phụ trợ), đặt cạnh `.exe`
sinh ra để `__tkv_extern_assembly__` load được lúc runtime (giống cách
Phase 1's spec đã mô tả cho `MyMathLib.dll`).

- [ ] **Step 2: Chạy, xác nhận FAIL rồi PASS sau khi Task 1-2 đã đúng**
  (nếu Task 1-2 đã merge đúng, bước này chỉ xác nhận, không sửa thêm gì
  ở compiler — nếu FAIL thật do gap ở Task 1-2, quay lại sửa ĐÚNG task
  đó, không vá tạm ở Task 3)

Run: `cd "D:\Claude AI Project\TokenVector" && python test/verify/extern_class_list_test.py`

- [ ] **Step 3: Regression CUỐI toàn bộ**

Run:
```bash
cd "D:\Claude AI Project\TokenVector"
python test/verify/extern_class_list_parse_test.py
python test/verify/extern_class_list_test.py
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
python test/verify/list_test.py
```
Expected: tất cả PASS.

- [ ] **Step 4: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Trong mục "#1 Package ecosystem"'s đoạn `__tkv_extern_class__`, thêm Phase
5 ĐÃ XONG — liệt kê "Đã làm" (`list[T]` cho ctor/method/property, T
scalar hoặc handle type) và "CHƯA làm" copy nguyên mục "Giới hạn KHÔNG
làm" từ spec (CHỈ `List<T>` cụ thể — cảnh báo RÕ rủi ro
`InvalidCastException` nếu API thật trả interface, KHÔNG `Dictionary`,
KHÔNG container-của-container, KHÔNG generic tự khai khác). Ghi lại
API/fixture THẬT đã dùng cho test (từ Task 1 Step 1) để phiên sau biết
chính xác đã kiểm chứng với cái gì.

- [ ] **Step 5: Cập nhật ledger SDD**

```bash
cd "D:\Claude AI Project"
echo "PLAN THUC SU DONG: extern-class-list-container (#1 Phase 5) - 3 task xong." >> .superpowers/sdd/progress.md
```

- [ ] **Step 6: Commit cuối**

```bash
cd "D:\Claude AI Project\TokenVector"
git add test/verify/extern_class_list_test.py docs/PYTHON_GAP_CHECKLIST.md
git commit -m "feat(compiler): extern-class Phase 5 hoan tat - test list[T] thuc te + docs (Task 3, extern-class-list)"
```

---

## Self-Review

**Spec coverage**: validate `list[T]` tại 4 điểm (Task 1) → codegen CIL
`List<T>` thật (Task 2) → test end-to-end với API/fixture đã XÁC MINH
THẬT + docs (Task 3). Mọi mục "Kiểm chứng" của spec: test tích cực (Task
3), phần tử handle type (Task 3 case 3), lỗi container-của-container +
dtype không hợp lệ (Task 1), tương thích Phase 3/4 (regression mọi task),
mirror tree ghi chú (Task 3 docs).

**Điểm KHÔNG chắc chắn 100% cần implementer tự xác nhận lúc thực thi**:
API .NET thật cho test tích cực CHƯA xác định trước — Task 1 Step 1 BẮT
BUỘC xác minh qua PowerShell reflection thật hoặc chuyển sang fixture
test-only, KHÔNG được đoán. Tên thuộc tính chính xác của `TypeAnn` cho
phần tử `list` (Task 1 Step 4). Cách trích `elem_dtype` từ chuỗi
`list[T]` — slicing thô vs tái dùng `parse_type_ann_str` (Task 2 Step 4,
khuyến nghị nhất quán dùng lại parser). Vị trí import
`il_features.list_type` tránh circular-import (Task 2 Step 4).
