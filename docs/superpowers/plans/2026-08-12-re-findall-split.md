# re.findall/re.split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm `re_findall(pattern, s) -> list[str]` và `re_split(pattern, s)
-> list[str]` vào TokenVector compiler, đóng mục đầu tiên của batch 5.5b
trong `docs/PYTHON_GAP_CHECKLIST.md`.

**Architecture:** Cả 2 hàm thêm vào `compiler/il_features/stdlib_re.py`
(cạnh `re_match`/`re_search`/`re_fullmatch`/`re_sub` có sẵn), đăng ký qua
`register_expr_builtin(..., 'str', return_shape='list')`. `re_split` map
thẳng `Regex.Split()` → `string[]` → `List<string>` (không cần local ẩn,
y hệt `os_list_files`). `re_findall` cần vòng lặp trích `.Value` từng
`Match` từ `MatchCollection` — dùng lại cơ chế `temps_fn`/`declare_named`
đã có từ RandomSeed Task 3, và cần thêm 1 dòng ánh xạ kiểu mới
(`shape='regex_matches'`) vào `il_type_str` trong `il_codegen.py` (mirror
sang `.tkv`) — y hệt cách `shape='regex_match'` (số ít, đã có sẵn cho
`Match`) từng được thêm cho `stdlib_json_get.py`.

**Tech Stack:** Python 3 (compiler), CIL text + `ilasm.exe` (.NET
Framework mscorlib v4.0.30319, KHÔNG phải .NET Core).

## Global Constraints

- TUYỆT ĐỐI KHÔNG build/rebuild `release/3.code/dist/tkvc.exe` ở BẤT KỲ
  task nào trong plan này.
- Cả 2 cây `compiler/` (`.py`) và `release/3.code/compiler/` (`.tkv`)
  PHẢI sửa đồng bộ 100% ở mọi task chạm code.
- `re.compile()` KHÔNG làm — quyết định đã chốt ở spec, ngoài phạm vi.
- `re_findall` trên pattern có group con (`(...)`) trả `.Value` của TOÀN
  BỘ match, không phải tuple group — giới hạn đã biết, không phải bug,
  không cần xử lý thêm trong plan này.
- Trước khi dùng bất kỳ chữ ký API .NET nào chưa từng dùng trong codebase
  (`MatchCollection::get_Item`/`get_Count`, `Match::get_Value`), XÁC NHẬN
  THẬT qua PowerShell reflection — không đoán.
- Không refactor code không liên quan ngoài phạm vi 2 hàm này.

---

### Task 1: `re_split(pattern, s) -> list[str]`

**Files:**
- Modify: `compiler/il_features/stdlib_re.py` (73 dòng hiện tại, thêm
  cuối file trước 2 dòng `register_expr_builtin` cuối)
- Modify: `release/3.code/compiler/il_features/stdlib_re.tkv` (mirror,
  hiện tại y hệt `.py` từng dòng)
- Test: `release/3.code/Testkit/re_extend_test.tkv` (mở rộng file có
  sẵn)

**Interfaces:**
- Consumes: không phụ thuộc gì mới, chỉ dùng `ctx['compile_expr']` có
  sẵn (giống 4 hàm `re_*` khác trong cùng file).
- Produces: `register_expr_builtin('re_split', compile_re_split, 'str',
  return_shape='list')` — hàm `re_split` dùng được ở bất kỳ statement
  gán nào (`x = re_split(p, s)`), giống `os_list_files`.

- [ ] **Step 1: Xác nhận chữ ký `Regex.Split(string, string)` đã có
  tiền lệ dùng trong codebase**

```bash
cd "D:\Claude AI Project\TokenVector"
grep -n "Regex::Split\|Regex::Replace" compiler/il_features/*.py
```

Nếu chưa từng dùng `Regex::Split`, xác nhận nhanh qua PowerShell:
```bash
powershell -Command "[System.Text.RegularExpressions.Regex].GetMethod('Split', [Type[]]@([string],[string]))"
```
Expected: trả về `System.String[] Split(System.String, System.String)`
— xác nhận chữ ký `string[]  Split(string, string)` đúng như dự đoán.

- [ ] **Step 2: Viết `compile_re_split` trong `stdlib_re.py`**

Thêm vào cuối file, TRƯỚC 2 dòng `register_expr_builtin` hiện có:

```python
def compile_re_split(args, scope, out, dtype, ctx):
    """re_split(pattern, s) -> list[str] - .NET Regex.Split(input,
    pattern) tra thang string[], la 1 IEnumerable<string> hop le de dua
    thang vao List<string> constructor - giong het cach _push_os_list_files
    (stdlib_os.py) da lam voi Directory.GetFiles(). CHU Y thu tu tham so
    KHAC Python (input truoc, giong re_sub)."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: re_split(pattern, s) can dung 2 tham so")
    compile_expr = ctx['compile_expr']
    compile_expr(args[1], scope, out, 'str', ctx)
    compile_expr(args[0], scope, out, 'str', ctx)
    out.append('    call string[] [System]System.Text.RegularExpressions.Regex::Split(string, string)')
    out.append('    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')
```

- [ ] **Step 3: Đăng ký `re_split`**

Sửa dòng cuối file từ:
```python
register_expr_builtin('re_sub', compile_re_sub, 'str')
```
thành:
```python
register_expr_builtin('re_sub', compile_re_sub, 'str')
register_expr_builtin('re_split', compile_re_split, 'str', return_shape='list')
```

- [ ] **Step 4: Mirror sang `.tkv`**

Áp dụng NGUYÊN VĂN Step 2/3 vào
`release/3.code/compiler/il_features/stdlib_re.tkv` (file hiện đồng bộ
từng dòng với `.py`, giữ nguyên tắc đó).

- [ ] **Step 5: Thêm test vào `re_extend_test.tkv`**

Sửa `release/3.code/Testkit/re_extend_test.tkv`, chèn TRƯỚC dòng
`return test_summary(...)`:

```python
    words: "list[str]" = re_split("\\s+", "hello   world  foo")
    tested = tested + 1
    total = total + check("split_len", str(len(words)), "3")
    tested = tested + 1
    total = total + check("split_first", words[0], "hello")
    tested = tested + 1
    total = total + check("split_last", words[2], "foo")
```

**LƯU Ý**: nếu build báo lỗi cú pháp khai báo `words: "list[str]" =
...`, xem lại giới hạn parser đã ghi nhận ở RandomSeed Task 3 (test
`.tkv` KHÔNG hỗ trợ annotation kiểu tường minh trên local list) — bỏ
annotation, để trình biên dịch tự suy dtype từ RHS (`words = re_split(...)`),
đúng cách RandomSeed Task 3 đã phải sửa.

- [ ] **Step 6: Build + chạy thật, xác nhận PASS**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/re_extend_test.tkv --entry run --out "$env:TEMP/re_ext_t1.exe"
"$env:TEMP/re_ext_t1.exe"
```
Expected: build PASS, tất cả dòng `PASS`, `SUMMARY 7/7` (4 test cũ + 3
test mới).

- [ ] **Step 7: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_features/stdlib_re.py \
        release/3.code/compiler/il_features/stdlib_re.tkv \
        release/3.code/Testkit/re_extend_test.tkv
git commit -m "$(cat <<'EOF'
feat(compiler): re_split(pattern, s) - Regex.Split -> List<string>

Regex.Split() tra thang string[], IEnumerable<string> hop le de dua
thang vao List<string> constructor - khong can vong lap, giong het
os_list_files (Directory.GetFiles()). Test moi xac nhan dung so luong +
noi dung tung phan tu.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: `re_findall(pattern, s) -> list[str]`

**Files:**
- Modify: `compiler/il_codegen.py` — thêm 1 nhánh `shape ==
  'regex_matches'` vào `il_type_str` (dòng ~152, cạnh nhánh
  `'regex_match'` đã có).
- Modify: `release/3.code/compiler/il_codegen.tkv` — mirror.
- Modify: `compiler/il_features/stdlib_re.py` — thêm `compile_re_findall`
  + `_findall_temps`.
- Modify: `release/3.code/compiler/il_features/stdlib_re.tkv` — mirror.
- Test: `release/3.code/Testkit/re_extend_test.tkv` (tiếp tục mở rộng).

**Interfaces:**
- Consumes: `shape='regex_matches'` mới trong `il_type_str` (Step 1),
  `ctx['declare_named']`/`ctx['TypeAnn']` (có sẵn, đã dùng ở
  `stdlib_json_get.py`/`stdlib_random.py`), `register_expr_builtin`'s
  `temps_fn=` param (có sẵn từ RandomSeed Task 3).
- Produces: `register_expr_builtin('re_findall', compile_re_findall,
  'str', return_shape='list', temps_fn=_findall_temps)`.

- [ ] **Step 1: Xác nhận chữ ký `MatchCollection`/`Match` qua PowerShell
  reflection (BẮT BUỘC, không đoán)**

```bash
powershell -Command "[System.Text.RegularExpressions.Regex].GetMethod('Matches', [Type[]]@([string],[string]))"
powershell -Command "[System.Text.RegularExpressions.MatchCollection].GetProperty('Item')"
powershell -Command "[System.Text.RegularExpressions.MatchCollection].GetProperty('Count')"
powershell -Command "[System.Text.RegularExpressions.Match].GetProperty('Value')"
```

Expected (xác nhận đúng trước khi viết Step 3):
- `Regex.Matches(string, string) -> MatchCollection`
- `MatchCollection.Item[int32] -> Match` (indexer, tên IL method
  `get_Item`)
- `MatchCollection.Count -> int32` (tên IL method `get_Count`)
- `Match.Value -> string` (tên IL method `get_Value`, ĐÃ dùng sẵn trong
  `stdlib_json_get.py` cho `regex_match` — grep xác nhận lại:
  `grep -n "Match::get_Value" compiler/il_features/stdlib_json_get.py`).

Nếu bất kỳ chữ ký nào khác dự đoán (vd `MatchCollection` không có
indexer `Item` mà chỉ có `GetEnumerator`), DỪNG lại, báo cáo phát hiện,
không tiếp tục Step 3 theo giả định sai.

- [ ] **Step 2: Thêm shape `'regex_matches'` vào `il_type_str`**

Sửa `compiler/il_codegen.py`, tìm đoạn (dòng ~152):
```python
    if type_ann.shape == 'regex_match':
        # json_get_str (2026-07-30, xem il_features/stdlib_json_get.py) -
        # local AN giu 1 doi tuong System.Text.RegularExpressions.Match
        # (reference type, khong can dia chi).
        return 'class [System]System.Text.RegularExpressions.Match'
```
Thêm NGAY SAU đó:
```python
    if type_ann.shape == 'regex_matches':
        # re_findall (batch 5.5b, 2026-08-12) - local AN giu 1 doi tuong
        # System.Text.RegularExpressions.MatchCollection (reference type),
        # can Count + indexer de duyet trich .Value tung Match.
        return 'class [System]System.Text.RegularExpressions.MatchCollection'
```

- [ ] **Step 3: Mirror Step 2 sang `.tkv`**

Áp dụng đúng đoạn trên vào tương ứng trong
`release/3.code/compiler/il_codegen.tkv` (tìm nhánh `'regex_match'`
tương ứng bằng `grep -n "regex_match" release/3.code/compiler/il_codegen.tkv`).

- [ ] **Step 4: Viết `_findall_temps` + `compile_re_findall` trong
  `stdlib_re.py`**

Thêm vào cuối file (sau `compile_re_split` từ Task 1, trước dòng đăng
ký `register_expr_builtin` cuối cùng):

```python
def _findall_temps(node, ctx):
    """FIRST PASS: khai 3 local an cho re_findall(pattern, s) - 'mc'
    (MatchCollection tra ve tu Regex.Matches, giu de doc Count + indexer
    nhieu lan khong tinh lai), 'result' (List<string> tich luy ket qua),
    'i' (chi so vong lap i32). Dung lai NGUYEN co che declare_named/
    id(args)-khoa da dung cho sample()/shuffle() o RandomSeed Task 3."""
    args = node[2]
    if len(args) != 2:
        return
    TypeAnn = ctx['TypeAnn']
    ctx['declare_named'](f'__refa{id(args)}_mc', TypeAnn('', 'regex_matches'))
    ctx['declare_named'](f'__refa{id(args)}_result', TypeAnn('str', 'list'))
    ctx['declare_named'](f'__refa{id(args)}_i', TypeAnn('i32', None))


def compile_re_findall(args, scope, out, dtype, ctx):
    """re_findall(pattern, s) -> list[str] - Regex.Matches(input,
    pattern) tra ve MatchCollection (KHONG the dua thang vao List<string>
    constructor nhu re_split - moi phan tu la 1 Match, can trich .Value
    tung phan tu qua vong lap chi so, xem spec 2026-08-12-re-findall-
    split-design.md). GIOI HAN DA BIET: pattern co group con ((...)) tra
    .Value CUA CA MATCH, khong phai tuple cac group - giong gioi han
    repl-la-string-thuong cua re_sub, chap nhan duoc."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: re_findall(pattern, s) can dung 2 tham so")
    compile_expr = ctx['compile_expr']

    mc_idx = scope[f'__refa{id(args)}_mc'][1]
    result_idx = scope[f'__refa{id(args)}_result'][1]
    i_idx = scope[f'__refa{id(args)}_i'][1]

    # mc = Regex.Matches(s, pattern)
    compile_expr(args[1], scope, out, 'str', ctx)
    compile_expr(args[0], scope, out, 'str', ctx)
    out.append('    call class [System]System.Text.RegularExpressions.MatchCollection '
                '[System]System.Text.RegularExpressions.Regex::Matches(string, string)')
    out.append(f'    stloc.s {mc_idx}')

    # result = new List<string>()
    out.append('    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()')
    out.append(f'    stloc.s {result_idx}')

    # i = 0
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {i_idx}')

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    prefix = ctx.get('prefix', 'refa')
    start_lbl = f'{prefix}_refa{n}_start'
    end_lbl = f'{prefix}_refa{n}_end'

    out.append(f'  {start_lbl}:')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    ldloc.s {mc_idx}')
    out.append('    callvirt instance int32 [System]System.Text.RegularExpressions.MatchCollection::get_Count()')
    out.append(f'    bge {end_lbl}')

    # result.Add(mc[i].Value)
    out.append(f'    ldloc.s {result_idx}')
    out.append(f'    ldloc.s {mc_idx}')
    out.append(f'    ldloc.s {i_idx}')
    out.append('    callvirt instance class [System]System.Text.RegularExpressions.Match '
                '[System]System.Text.RegularExpressions.MatchCollection::get_Item(int32)')
    out.append('    callvirt instance string [System]System.Text.RegularExpressions.Match::get_Value()')
    out.append('    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)')

    # i = i + 1; goto start
    out.append(f'    ldloc.s {i_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'    br {start_lbl}')
    out.append(f'  {end_lbl}:')
    out.append(f'    ldloc.s {result_idx}')
```

**LƯU Ý quan trọng**: `bge {end_lbl}` so sánh `i >= mc.Count` để thoát —
thứ tự đẩy stack ở khối `start_lbl` PHẢI là `i` rồi `mc.Count` (`bge`
so `[val1] >= [val2]` rồi nhảy nếu đúng, val1=i đẩy trước, val2=Count
đẩy sau — xác nhận lại đúng thứ tự operand của `bge` trong CIL spec
hoặc đối chiếu 1 vòng lặp `bge`/`blt` khác đã có trong `il_codegen.py`
trước khi tin code mẫu trên là đúng 100% — SỬA lại nếu thứ tự operand
sai khi test Step 6 thất bại với kết quả sai (không phải lỗi assemble).

- [ ] **Step 5: Đăng ký `re_findall`**

Sửa dòng đăng ký cuối `stdlib_re.py` (đã có `re_split` từ Task 1):
```python
register_expr_builtin('re_split', compile_re_split, 'str', return_shape='list')
register_expr_builtin('re_findall', compile_re_findall, 'str', return_shape='list', temps_fn=_findall_temps)
```

- [ ] **Step 6: Mirror Step 4/5 sang `.tkv`**

Áp dụng NGUYÊN VĂN vào
`release/3.code/compiler/il_features/stdlib_re.tkv`.

- [ ] **Step 7: Thêm test vào `re_extend_test.tkv`**

Chèn TRƯỚC dòng `return test_summary(...)` (sau phần test `re_split`
của Task 1):

```python
    nums = re_findall("[0-9]+", "a12 b345 c6")
    tested = tested + 1
    total = total + check("findall_len", str(len(nums)), "3")
    tested = tested + 1
    total = total + check("findall_first", nums[0], "12")
    tested = tested + 1
    total = total + check("findall_second", nums[1], "345")
    tested = tested + 1
    total = total + check("findall_third", nums[2], "6")
```

- [ ] **Step 8: Build + chạy thật, xác nhận PASS**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/re_extend_test.tkv --entry run --out "$env:TEMP/re_ext_t2.exe"
"$env:TEMP/re_ext_t2.exe"
```
Expected: build PASS, `SUMMARY 11/11` (4 gốc + 3 `re_split` + 4
`re_findall`). Nếu `findall_first`/`findall_second`/`findall_third` sai
thứ tự hoặc thiếu phần tử, xem lại cảnh báo thứ tự operand `bge` ở
Step 4.

- [ ] **Step 9: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_codegen.py \
        release/3.code/compiler/il_codegen.tkv \
        compiler/il_features/stdlib_re.py \
        release/3.code/compiler/il_features/stdlib_re.tkv \
        release/3.code/Testkit/re_extend_test.tkv
git commit -m "$(cat <<'EOF'
feat(compiler): re_findall(pattern, s) - MatchCollection -> List<string>

Regex.Matches() tra MatchCollection, khong the dua thang vao List<string>
constructor nhu re_split (moi phan tu la 1 Match) - vong lap chi so trich
.Value tung Match. Them shape moi 'regex_matches' vao il_type_str (cach
'regex_match' so it da co cho stdlib_json_get.py) de khai local an giu
MatchCollection. Dung lai co che temps_fn/declare_named tu RandomSeed
Task 3. Gioi han da biet: pattern co group con tra .Value ca match,
khong phai tuple group - chap nhan duoc, giong gioi han cua re_sub.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Regression toàn diện + cập nhật checklist doc

**Files:**
- Test: chạy toàn bộ `release/3.code/Testkit/*.tkv` qua cây `.py`.
- Modify: `docs/PYTHON_GAP_CHECKLIST.md` — đánh dấu `re.findall/split`
  đã xong trong mục 5.5b.

**Interfaces:**
- Consumes: toàn bộ thay đổi Task 1+2.
- Produces: không có interface mới — task đóng gói cuối.

- [ ] **Step 1: Regression toàn bộ `Testkit/*.tkv` qua cây `.py`**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  python tkv.py build "$f" --entry run --out "$TEMP/re_t3_reg_${base}.exe" > "$TEMP/re_t3_buildlog_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; continue; fi
  res=$("$TEMP/re_t3_reg_${base}.exe" 2>&1)
  echo "$res" | grep -qi "^FAIL \|Exception" && { echo "=== $base ==="; echo "$res" | tail -5; } || echo "OK $base"
done
```

Expected: mọi dòng `OK` trừ `path_isfile_isdir_test` (pre-existing fail,
không liên quan, đã xác nhận nhiều lần ở các task trước — KHÔNG phải hồi
quy mới do batch này gây ra).

- [ ] **Step 2: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Đọc dòng 129-132 hiện tại:
```
- [ ] 5.5b batch nhỏ còn lại: `re.findall/split/compile`,
      `.replace(...,count)`, `.format()` kwargs, `os.path.splitext()`,
      `divmod()`, `set.remove()` phải ném lỗi khi thiếu phần tử
```

Thay bằng (tách `re.findall/split` ra thành dòng riêng đã xong, giữ
`re.compile` ghi rõ "không làm", các mục còn lại giữ nguyên):
```
- [x] `re.findall`/`re.split` — **ĐÃ XONG (2026-08-12)**. `re_findall`
      (MatchCollection → vòng lặp trích `.Value`), `re_split`
      (`Regex.Split` → `List<string>` trực tiếp). `re.compile()` KHÔNG
      làm có chủ đích — DSL không có kiểu "compiled regex object", xem
      `docs/superpowers/specs/2026-08-12-re-findall-split-design.md`.
- [ ] 5.5b batch nhỏ còn lại: `.replace(...,count)`, `.format()` kwargs,
      `os.path.splitext()`, `divmod()`, `set.remove()` phải ném lỗi khi
      thiếu phần tử
```

- [ ] **Step 3: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add docs/PYTHON_GAP_CHECKLIST.md
git commit -m "$(cat <<'EOF'
docs: xac nhan hoan thanh re.findall/re.split (5.5b)

Regression toan bo Testkit/*.tkv qua cay .py - khong hoi quy moi (tru
path_isfile_isdir_test pre-existing). Danh dau 5.5b's re.findall/split
da xong, tach rieng khoi 5 muc con lai cua batch. Khong rebuild
release/3.code/dist/tkvc.exe.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```
