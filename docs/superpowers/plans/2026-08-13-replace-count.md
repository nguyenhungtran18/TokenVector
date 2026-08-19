# .replace(old, new, count) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm tham số thứ 3 optional `count` cho `.replace(old, new,
count)`, đóng mục thứ 2 của batch 5.5b trong `docs/PYTHON_GAP_CHECKLIST.md`.

**Architecture:** Helper mới `TkvStr::ReplaceCount(string, string, string,
int32)` trong `compiler/il_features/tkvstr.py`, 3 nhánh (`count<0` gọi lại
`Replace` hiện có, `old=""` chèn `new` trước mỗi ký tự dừng đủ `count`
lần, `old!=""` vòng lặp `IndexOf(string,int32)`). Tầng DSL
`compile_str_method_replace` (`string_methods_batch2.py`) nhận 2 hoặc 3
tham số, dispatch tương ứng.

**Tech Stack:** Python 3 (compiler), CIL text + `ilasm.exe` (.NET
Framework mscorlib v4.0.30319, KHÔNG phải .NET Core).

## Global Constraints

- TUYỆT ĐỐI KHÔNG build/rebuild `release/3.code/dist/tkvc.exe` ở BẤT KỲ
  task nào trong plan này.
- Cả 2 cây `compiler/` (`.py`) và `release/3.code/compiler/` (`.tkv`)
  PHẢI sửa đồng bộ 100% ở mọi task chạm code.
- `.replace(old, new)` 2 tham số PHẢI giữ NGUYÊN hành vi cũ — không đổi
  IL sinh ra cho đường 2-tham-số.
- `count < 0` → thay HẾT (giống không truyền `count`). `count == 0` →
  không đổi gì. `old == ""` với `count` → khớp ví dụ Python
  `'aaa'.replace('', '-', 2)` → `'-a-aa'`.
- Trước khi dùng `String::IndexOf(string, int32)` (overload có tham số
  vị trí bắt đầu, chưa từng dùng trong codebase), xác nhận chữ ký THẬT
  qua PowerShell reflection — không đoán.
- Không refactor code không liên quan ngoài phạm vi `.replace()`.

---

### Task 1: `TkvStr::ReplaceCount` — helper IL mới

**Files:**
- Modify: `compiler/il_features/tkvstr.py` (345 dòng hiện tại — thêm
  method mới NGAY SAU khối `Replace` hiện có, dòng 254-296, TRƯỚC khối
  `RFind` bắt đầu dòng 298)
- Modify: `release/3.code/compiler/il_features/tkvstr.tkv` (mirror,
  hiện đồng bộ với `.py` — 347 dòng, lệch 2 dòng do khác line-ending
  convention, nội dung logic giống hệt)

**Interfaces:**
- Consumes: `_m(sig, *body)` helper có sẵn (dòng 82-84, sinh khung
  `.method public static <sig> cil managed { ... }`), `_STR =
  '[mscorlib]System.String'` hằng số có sẵn (dòng 41).
- Produces: `TkvStr::ReplaceCount(string src, string oldStr, string
  newStr, int32 count) -> string` — dùng ở Task 2.

- [ ] **Step 1: Xác nhận chữ ký `String::IndexOf(string, int32)` qua
  PowerShell reflection**

```bash
powershell -Command "[string].GetMethod('IndexOf', [Type[]]@([string],[int]))"
```
Expected: `Int32 IndexOf(System.String, Int32)` — xác nhận overload có
tham số vị trí bắt đầu tồn tại đúng như dự đoán trước khi dùng ở Step 2.

- [ ] **Step 2: Viết `ReplaceCount` trong `tkvstr.py`**

Chèn vào `compiler/il_features/tkvstr.py` NGAY SAU khối `Replace` (sau
dòng có `'    ret')` kết thúc method `Replace`, TRƯỚC comment `# RFind:`
ở dòng 298):

```python
    # ReplaceCount: '.replace(old, new, count)' (batch 5.5b, 2026-08-13)
    # - gioi han so lan thay the TOI DA 'count' lan tinh tu trai. count<0
    # coi nhu KHONG gioi han (goi lai Replace() da co, tai dung nhanh
    # old="" cua no). old="" voi count cu the: chen newStr TRUOC moi ky
    # tu, dung SAU khi da chen du count lan (ke ca gap SAU ky tu cuoi neu
    # count > do dai src) - khop 'aaa'.replace('', '-', 2) Python ->
    # '-a-aa'. old!="": vong lap IndexOf(oldStr, pos) tim tung khop, dung
    # khi du count lan hoac het khop.
    lines += _m(
        'string ReplaceCount(string src, string oldStr, string newStr, int32 count)',
        '    .locals init (int32 i, int32 n, int32 pos, int32 replaced, int32 idx, '
        'class [mscorlib]System.Text.StringBuilder sb)',
        '    ldarg.3', '    ldc.i4.0', '    bge RC_NONNEG',
        '    ldarg.0', '    ldarg.1', '    ldarg.2',
        f'    call string {TKVSTR_CLASS}::Replace(string, string, string)',
        '    ret',
        '  RC_NONNEG:',
        '    ldarg.1', f'    callvirt instance int32 {_STR}::get_Length()',
        '    brtrue RC_OLDNONEMPTY',
        # old == "": chen newStr truoc toi da 'count' ky tu dau, dung du
        # thi thoi (khong lap het chuoi nhu Replace() lam khi khong gioi
        # han).
        '    ldarg.0', f'    callvirt instance int32 {_STR}::get_Length()', '    stloc.s n',
        '    newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()',
        '    stloc.s sb',
        '    ldc.i4.0', '    stloc.s i',
        '  RC_EMPTY_LOOP:',
        '    ldloc.s i', '    ldarg.3', '    bge RC_EMPTY_TAIL',
        '    ldloc.s i', '    ldloc.s n', '    bge RC_EMPTY_TAIL',
        '    ldloc.s sb', '    ldarg.2',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(string)', '    pop',
        '    ldloc.s sb', '    ldarg.0', '    ldloc.s i',
        f'    callvirt instance char {_STR}::get_Chars(int32)',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(char)', '    pop',
        '    ldloc.s i', '    ldc.i4.1', '    add', '    stloc.s i',
        '    br RC_EMPTY_LOOP',
        '  RC_EMPTY_TAIL:',
        # neu count > do dai src: con 1 gap SAU ky tu cuoi chua chen.
        '    ldarg.3', '    ldloc.s n', '    ble RC_EMPTY_NOEXTRA',
        '    ldloc.s sb', '    ldarg.2',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(string)', '    pop',
        '  RC_EMPTY_NOEXTRA:',
        '    ldloc.s sb', '    ldarg.0', '    ldloc.s i',
        f'    callvirt instance string {_STR}::Substring(int32)',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(string)', '    pop',
        '    ldloc.s sb',
        '    callvirt instance string [mscorlib]System.Text.StringBuilder::ToString()',
        '    ret',
        '  RC_OLDNONEMPTY:',
        # old != "": vong lap IndexOf(oldStr, pos), thay toi da 'count' lan.
        '    ldc.i4.0', '    stloc.s pos',
        '    ldc.i4.0', '    stloc.s replaced',
        '    newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()',
        '    stloc.s sb',
        '  RC_LOOP:',
        '    ldloc.s replaced', '    ldarg.3', '    bge RC_TAIL',
        '    ldarg.0', '    ldarg.1', '    ldloc.s pos',
        f'    callvirt instance int32 {_STR}::IndexOf(string, int32)',
        '    stloc.s idx',
        '    ldloc.s idx', '    ldc.i4.0', '    blt RC_TAIL',
        '    ldloc.s sb', '    ldarg.0', '    ldloc.s pos', '    ldloc.s idx', '    ldloc.s pos', '    sub',
        f'    callvirt instance string {_STR}::Substring(int32, int32)',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(string)', '    pop',
        '    ldloc.s sb', '    ldarg.2',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(string)', '    pop',
        '    ldloc.s idx', '    ldarg.1', f'    callvirt instance int32 {_STR}::get_Length()', '    add',
        '    stloc.s pos',
        '    ldloc.s replaced', '    ldc.i4.1', '    add', '    stloc.s replaced',
        '    br RC_LOOP',
        '  RC_TAIL:',
        '    ldloc.s sb', '    ldarg.0', '    ldloc.s pos',
        f'    callvirt instance string {_STR}::Substring(int32)',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(string)', '    pop',
        '    ldloc.s sb',
        '    callvirt instance string [mscorlib]System.Text.StringBuilder::ToString()',
        '    ret')
```

**LƯU Ý về thứ tự operand `sub`**: dòng
`'    ldloc.s pos', '    ldloc.s idx', '    ldloc.s pos', '    sub','`
tính `idx - pos` (CIL `sub` lấy `[val2] - [val1]` theo thứ tự đẩy
stack `val1, val2` rồi `sub` cho `val1 - val2` hay `val2 - val1`? XÁC
NHẬN LẠI thứ tự đúng của opcode `sub` trong CIL spec — hoặc đối chiếu 1
phép trừ khác đã có THẬT trong codebase (`grep -n "    sub$"
compiler/il_features/*.py compiler/il_codegen.py`) trước khi tin đoạn
code trên, SỬA nếu thứ tự operand sai (biểu hiện: `Substring(pos,
length)` nhận `length` âm hoặc sai, ilasm có thể không báo lỗi assemble
nhưng runtime `ArgumentOutOfRangeException` hoặc kết quả sai).

- [ ] **Step 3: Mirror sang `.tkv`**

Áp dụng NGUYÊN VĂN đoạn code Step 2 vào
`release/3.code/compiler/il_features/tkvstr.tkv` (chèn đúng vị trí
tương ứng — dùng `grep -n "# RFind:" release/3.code/compiler/il_features/tkvstr.tkv`
để định vị điểm chèn TRƯỚC).

- [ ] **Step 4: Xác nhận `ReplaceCount` assemble được (chưa cần gọi từ
  DSL) — viết 1 spike `.tkv` tối giản gọi trực tiếp qua `.replace()`
  3-tham-số SAU Task 2 (không tách riêng bước build ở đây vì
  `ReplaceCount` chưa có đường vào từ DSL cho tới khi Task 2 xong — bỏ
  qua build riêng cho Task 1, gộp verify vào Task 2 Step cuối).**

Không có lệnh chạy ở bước này — đây là ghi chú, không phải checkbox
thật, giữ nguyên cấu trúc file nhưng KHÔNG cần build/test tách biệt cho
Task 1 vì `.replace(old,new,count)` DSL syntax chưa tồn tại tới khi Task
2 hoàn thành đăng ký. Task 1 coi là DONE khi `ReplaceCount` đã viết +
mirror `.tkv` xong, KHÔNG build được độc lập (không có cách gọi trực
tiếp `TkvStr::ReplaceCount` từ 1 file `.tkv` DSL mà không qua Task 2's
`.replace()` 3-tham-số).

- [ ] **Step 5: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_features/tkvstr.py \
        release/3.code/compiler/il_features/tkvstr.tkv
git commit -m "$(cat <<'EOF'
feat(compiler): TkvStr::ReplaceCount - helper IL cho .replace(...,count)

3 nhanh: count<0 goi lai Replace() hien co (thay het), old="" chen
newStr truoc toi da count ky tu dau (dung sau du count lan, khac
Replace() lap het chuoi), old!="" vong lap IndexOf(string,int32) tim
tung khop toi da count lan. Chua co duong goi tu DSL (Task ke tiep dang
ky '.replace(old,new,count)' 3-tham-so).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: DSL 3-tham-số + test + regression + docs

**Files:**
- Modify: `compiler/il_features/string_methods_batch2.py` (100 dòng
  hiện tại — sửa `compile_str_method_replace`, dòng 54-67)
- Modify: `release/3.code/compiler/il_features/string_methods_batch2.tkv`
  (mirror, 100 dòng, đồng bộ `.py`)
- Test: `release/3.code/Testkit/str_methods_batch2_test.tkv` (MỚI —
  chưa có file test riêng cho `upper`/`lower`/`strip`/`replace`/`join`)
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`

**Interfaces:**
- Consumes: `TkvStr::ReplaceCount` từ Task 1.
- Produces: không có interface mới cho task khác — đây là task đóng gói
  cuối của batch item này.

- [ ] **Step 1: Sửa `compile_str_method_replace` nhận 2 hoặc 3 tham số**

Sửa `compiler/il_features/string_methods_batch2.py`, thay TOÀN BỘ hàm
hiện tại (dòng 54-67):

```python
def compile_str_method_replace(node, scope, out, dtype, ctx):
    """'.replace(old, new)' - di qua TkvStr::Replace (khong goi thang
    System.String::Replace) vi .NET NEM ArgumentException khi old="" con
    Python thi hop le (chen new xen giua moi ky tu) - xem tkvstr.py.
    '.replace(old, new, count)' (batch 5.5b, 2026-08-13) - them tham so
    thu 3 optional, gioi han so lan thay the TOI DA - di qua
    TkvStr::ReplaceCount rieng (giu nguyen duong 2-tham-so cu KHONG doi
    IL sinh ra, tranh regression)."""
    obj_name, args = node[1], node[3]
    if len(args) not in (2, 3):
        raise SyntaxError("il_codegen: s.replace(old, new) hoac s.replace(old, new, count) can dung 2 hoac 3 tham so")
    _validate_str_method_caller(obj_name, scope)
    import il_features.tkvstr as _tkvstr
    _tkvstr.ensure_class(ctx)
    ctx['load_var_ref'](obj_name, scope, out)
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    ctx['compile_expr'](args[1], scope, out, 'str', ctx)
    if len(args) == 3:
        ctx['compile_expr'](args[2], scope, out, 'i32', ctx)
        out.append(f'    call string {_tkvstr.TKVSTR_CLASS}::ReplaceCount(string, string, string, int32)')
    else:
        out.append(f'    call string {_tkvstr.TKVSTR_CLASS}::Replace(string, string, string)')
```

- [ ] **Step 2: Mirror sang `.tkv`**

Áp dụng NGUYÊN VĂN vào
`release/3.code/compiler/il_features/string_methods_batch2.tkv`.

- [ ] **Step 3: Viết test mới `str_methods_batch2_test.tkv`**

Tạo `release/3.code/Testkit/str_methods_batch2_test.tkv`:

```python
__tkv_import__ = ["tkv_test_lib"]

def run() -> "i32":
    total = 0
    tested = 0

    tested = tested + 1
    total = total + check("replace_no_count_unchanged",
                           "aXaXa".replace("X", "-"), "a-a-a")

    tested = tested + 1
    total = total + check("replace_count_positive",
                           "aXaXaXa".replace("X", "-", 2), "a-a-aXa")

    tested = tested + 1
    total = total + check("replace_count_zero",
                           "aXaXa".replace("X", "-", 0), "aXaXa")

    tested = tested + 1
    total = total + check("replace_count_negative_means_all",
                           "aXaXa".replace("X", "-", -1), "a-a-a")

    tested = tested + 1
    total = total + check("replace_empty_old_with_count",
                           "aaa".replace("", "-", 2), "-a-aa")

    return test_summary("str_methods_batch2_test", total, tested)
```

**LƯU Ý**: nếu DSL không hỗ trợ gọi method trực tiếp trên string
literal (`"aXaXa".replace(...)`), đổi sang gán biến trước:
```python
    s1 = "aXaXaXa"
    tested = tested + 1
    total = total + check("replace_count_positive", s1.replace("X", "-", 2), "a-a-aXa")
```
(áp dụng tương tự cho các dòng còn lại nếu cần) — kiểm tra 1 test string
method khác đã có trong `Testkit/` để biết cú pháp đúng trước khi viết.

- [ ] **Step 4: Build + chạy thật, xác nhận PASS**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/str_methods_batch2_test.tkv --entry run --out "$env:TEMP/rc_t2.exe"
"$env:TEMP/rc_t2.exe"
```
Expected: build PASS, `SUMMARY 5/5`. Nếu `replace_empty_old_with_count`
sai, xem lại thuật toán nhánh `old=""` ở Task 1 Step 2 (`RC_EMPTY_LOOP`)
— đối chiếu lại ví dụ `'aaa'.replace('', '-', 2)` → `'-a-aa'` bằng
Python thật (`python3 -c "print('aaa'.replace('', '-', 2))"`) nếu nghi
ngờ.

- [ ] **Step 5: Regression toàn bộ `Testkit/*.tkv` qua cây `.py`**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  python tkv.py build "$f" --entry run --out "$TEMP/rc_t2_reg_${base}.exe" > "$TEMP/rc_t2_buildlog_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; continue; fi
  res=$("$TEMP/rc_t2_reg_${base}.exe" 2>&1)
  echo "$res" | grep -qi "^FAIL \|Exception" && { echo "=== $base ==="; echo "$res" | tail -5; } || echo "OK $base"
done
```

Expected: mọi dòng `OK` trừ `path_isfile_isdir_test` (pre-existing fail
đã biết, không liên quan).

- [ ] **Step 6: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Tìm dòng `5.5b batch nhỏ còn lại: ...` (đã được Task 3 của plan
`2026-08-12-re-findall-split.md` sửa trước đó, hiện liệt kê 5 mục còn
lại bắt đầu bằng `.replace(...,count)`). Tách `.replace(...,count)` ra
thành dòng `[x]` riêng, giữ 4 mục còn lại:

```
- [x] `.replace(old,new,count)` — **ĐÃ XONG (2026-08-13)**. Tham số thứ
      3 optional qua `TkvStr::ReplaceCount` — count<0 thay hết, old=""
      chèn trước tối đa count ký tự đầu, old!="" vòng lặp IndexOf tìm
      tối đa count khớp. Xem
      `docs/superpowers/specs/2026-08-13-replace-count-design.md`.
- [ ] 5.5b batch nhỏ còn lại: `.format()` kwargs, `os.path.splitext()`,
      `divmod()`, `set.remove()` phải ném lỗi khi thiếu phần tử
```

(Điều chỉnh đúng nội dung dòng cũ nếu khác dự đoán — đọc lại file thật
trước khi sửa, không giả định nội dung chính xác.)

- [ ] **Step 7: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_features/string_methods_batch2.py \
        release/3.code/compiler/il_features/string_methods_batch2.tkv \
        release/3.code/Testkit/str_methods_batch2_test.tkv \
        docs/PYTHON_GAP_CHECKLIST.md
git commit -m "$(cat <<'EOF'
feat(compiler): .replace(old,new,count) - tham so thu 3 optional

compile_str_method_replace nhan 2 hoac 3 tham so - 2 tham so giu nguyen
IL cu (khong regression), 3 tham so dispatch TkvStr::ReplaceCount (Task
1). Test moi xac nhan count duong/0/am, va truong hop old="" voi count.
Regression toan bo Testkit/*.tkv - khong hoi quy moi. Danh dau
.replace(...,count) xong trong checklist 5.5b.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```
