# set.remove() ném lỗi khi thiếu phần tử Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `set.remove(x)` ném lỗi khi `x` không có trong set (khớp
Python thật); `set.discard(x)` giữ nguyên hành vi im lặng. Đóng mục
CUỐI CÙNG của batch 5.5b trong `docs/PYTHON_GAP_CHECKLIST.md`.

**Architecture:** Tách `_codegen_set_remove_like`
(`compiler/il_features/set_methods_batch2.py`) thành 2 nhánh theo
`stmt['kind']` — `set_discard` giữ nguyên (`pop`, không kiểm tra),
`set_remove` kiểm tra `bool` trả về của `HashSet<T>::Remove(T)`, ném
`System.Collections.Generic.KeyNotFoundException` nếu `false`. Đã xác
nhận `except KeyError:` (DSL có sẵn, `control_flow.py`'s
`_EXC_TYPE_MAP`) ánh xạ ĐÚNG `KeyNotFoundException` — dùng được ngay
trong test mà không cần thêm ánh xạ mới.

**Tech Stack:** Python 3 (compiler), CIL text + `ilasm.exe` (.NET
Framework mscorlib v4.0.30319).

## Global Constraints

- TUYỆT ĐỐI KHÔNG build/rebuild `release/3.code/dist/tkvc.exe`.
- Cả 2 cây `compiler/` (`.py`) và `release/3.code/compiler/` (`.tkv`)
  PHẢI sửa đồng bộ 100%.
- `set.discard(x)` PHẢI giữ NGUYÊN hành vi hiện có (không ném lỗi dù
  thiếu phần tử) — không regression.
- `set.remove(x)` với `x` CÓ trong set PHẢI vẫn hoạt động bình thường
  (xóa đúng phần tử, không ném lỗi giả) — chỉ ném lỗi khi THẬT SỰ thiếu.
- Không refactor `union`/`intersection`/`difference` hay bất kỳ phần
  nào khác của `set_methods_batch2.py` ngoài `_codegen_set_remove_like`.

---

### Task 1: Tách nhánh `remove`/`discard` + test + regression + docs

**Files:**
- Modify: `compiler/il_features/set_methods_batch2.py` (132 dòng hiện
  tại — sửa `_codegen_set_remove_like`, dòng 64-69)
- Modify: `release/3.code/compiler/il_features/set_methods_batch2.tkv`
  (mirror, hiện byte-identical với `.py`)
- Test: `release/3.code/Testkit/set_remove_error_test.tkv` (MỚI)
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`

**Interfaces:**
- Consumes: `except KeyError:` (đã có sẵn trong DSL, ánh xạ
  `System.Collections.Generic.KeyNotFoundException` qua
  `_EXC_TYPE_MAP` trong `compiler/il_features/control_flow.py` —
  KHÔNG cần sửa gì ở đó).
- Produces: không có interface mới cho task khác — task đóng gói cuối
  của TOÀN BỘ batch 5.5b.

- [ ] **Step 1: Sửa `_codegen_set_remove_like` — tách nhánh theo
  `stmt['kind']`**

Thay TOÀN BỘ hàm hiện tại (dòng 64-69) trong
`compiler/il_features/set_methods_batch2.py`:

```python
def _codegen_set_remove_like(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """set.discard(x): giu nguyen hanh vi cu (Remove(T) roi pop, khong
    kiem tra ket qua). set.remove(x) (batch 5.5b, muc cuoi, 2026-08-13):
    kiem tra bool tra ve tu Remove(T) - neu False (phan tu KHONG co
    trong set), nem KeyNotFoundException (gan nghia nhat voi KeyError
    cua Python - .NET khong co exception ten 'KeyError'). Khong tu viet
    message chua gia tri thieu - chap nhan sai khac nho ve loai/noi dung
    exception, giong tien le sample()/RFind da chap nhan truoc do."""
    _, _, ta = scope[stmt['name']]
    ctx['load_var_ref'](stmt['name'], scope, body)
    ctx['compile_expr'](stmt['value_node'], scope, body, ta.dtype, ctx)
    body.append(f'    callvirt instance bool {il_set_type(ta.dtype, ctx.get("records"))}::Remove(!0)')
    if stmt['kind'] == 'set_discard':
        body.append('    pop')
    else:
        ctx['label_counter'][0] += 1
        n = ctx['label_counter'][0]
        ok_lbl = f"{ctx['prefix']}_setrm{n}_ok"
        body.append(f'    brtrue {ok_lbl}')
        body.append('    newobj instance void [mscorlib]System.Collections.Generic.KeyNotFoundException::.ctor()')
        body.append('    throw')
        body.append(f'  {ok_lbl}:')
```

**LƯU Ý**: `stmt['kind']` đã có sẵn giá trị `'set_remove'`/`'set_discard'`
(xem `_make_set_remove_parser`'s `return {'kind': kind, ...}` — không
cần thay đổi gì ở tầng parser, chỉ dùng LẠI giá trị đã có).

- [ ] **Step 2: Mirror sang `.tkv`**

Áp dụng NGUYÊN VĂN vào
`release/3.code/compiler/il_features/set_methods_batch2.tkv`.

- [ ] **Step 3: Viết test mới `set_remove_error_test.tkv`**

Tạo `release/3.code/Testkit/set_remove_error_test.tkv`:

```python
__tkv_import__ = ["tkv_test_lib"]

def run() -> "i32":
    total = 0
    tested = 0

    s1: "set[i32]" = {1, 2, 3}
    s1.remove(2)
    tested = tested + 1
    total = total + check("remove_existing_ok", str(len(s1)), "2")

    s2: "set[i32]" = {1, 2, 3}
    caught = 0
    try:
        s2.remove(99)
    except KeyError:
        caught = 1
    tested = tested + 1
    total = total + check("remove_missing_raises", str(caught), "1")

    s3: "set[i32]" = {1, 2, 3}
    s3.discard(99)
    tested = tested + 1
    total = total + check("discard_missing_no_raise", str(len(s3)), "3")

    return test_summary("set_remove_error_test", total, tested)
```

**LƯU Ý**: nếu khai báo `s1: "set[i32]" = {1, 2, 3}` không đúng cú
pháp DSL hiện có, kiểm tra 1 file test set khác trong `Testkit/` (tìm
bằng `grep -l "set\[" release/3.code/Testkit/*.tkv`) để biết đúng cú
pháp khai báo set trước khi sửa lại test.

- [ ] **Step 4: Build + chạy thật, xác nhận PASS**

```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/set_remove_error_test.tkv --entry run --out "$env:TEMP/sre_t1.exe"
"$env:TEMP/sre_t1.exe"
```
Expected: build PASS, `SUMMARY 3/3`. Nếu `remove_missing_raises` fail
vì exception không bị `except KeyError:` bắt được, kiểm tra lại
`_EXC_TYPE_MAP['KeyError']` trong `control_flow.py` có đúng ánh xạ
`System.Collections.Generic.KeyNotFoundException` như đã xác nhận qua
`grep` ở bước brainstorm không — nếu khác, đối chiếu lại và sửa type
exception ném ra trong Step 1 cho khớp.

- [ ] **Step 5: Regression toàn bộ `Testkit/*.tkv` qua cây `.py`**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  python tkv.py build "$f" --entry run --out "$TEMP/sre_reg_${base}.exe" > "$TEMP/sre_buildlog_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; continue; fi
  res=$("$TEMP/sre_reg_${base}.exe" 2>&1)
  echo "$res" | grep -qi "^FAIL \|Exception" && { echo "=== $base ==="; echo "$res" | tail -5; } || echo "OK $base"
done
```

Expected: mọi dòng `OK` trừ `path_isfile_isdir_test` (pre-existing fail
đã biết, không liên quan). ĐẶC BIỆT chú ý file nào dùng
`.discard(`/`.remove(` hiện có (tìm bằng
`grep -l "\.discard(\|\.remove(" release/3.code/Testkit/*.tkv`) —
xác nhận không hồi quy.

- [ ] **Step 6: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md` — ĐÓNG TOÀN BỘ
  batch 5.5b**

Đọc lại nội dung THẬT của dòng `5.5b batch nhỏ còn lại` (hiện CHỈ còn
`set.remove()` — mục CUỐI CÙNG). Tách thành `[x]` riêng — SAU BƯỚC NÀY,
dòng `5.5b batch nhỏ còn lại` không còn mục nào, có thể XÓA HẲN dòng đó
(không để lại dòng rỗng `[ ] 5.5b batch nhỏ còn lại:` không nội dung):

```
- [x] `set.remove(x)` ném lỗi khi thiếu phần tử — **ĐÃ XONG
      (2026-08-13)**. Kiểm tra bool trả về của `HashSet<T>::Remove`,
      ném `KeyNotFoundException` nếu thiếu (khớp `except KeyError:` có
      sẵn trong DSL). `discard()` giữ nguyên hành vi im lặng. Xem
      `docs/superpowers/specs/2026-08-13-set-remove-error-design.md`.
      **Batch 5.5b HOÀN TẤT — toàn bộ 7 mục đã xong.**
```

(Đọc lại nội dung THẬT của file trước khi sửa — không giả định đúng
format trên nếu khác thực tế. Nếu có heading/section riêng cho "batch
5.5b" cần đóng tổng kết, thêm 1 dòng xác nhận batch hoàn tất ngay dưới
mục cuối này.)

- [ ] **Step 7: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_features/set_methods_batch2.py \
        release/3.code/compiler/il_features/set_methods_batch2.tkv \
        release/3.code/Testkit/set_remove_error_test.tkv \
        docs/PYTHON_GAP_CHECKLIST.md
git commit -m "$(cat <<'EOF'
feat(compiler): set.remove(x) nem KeyNotFoundException khi thieu phan tu

Tach _codegen_set_remove_like theo stmt['kind'] - set_discard giu
nguyen (pop, im lang), set_remove kiem tra bool tra ve tu HashSet::
Remove, nem KeyNotFoundException neu False (gan nghia nhat voi KeyError
- .NET khong co KeyError, da xac nhan except KeyError: co san anh xa
dung sang KeyNotFoundException qua _EXC_TYPE_MAP). Test moi xac nhan
remove() thanh cong khi co phan tu, nem loi khi thieu (bat duoc qua
except KeyError:), discard() khong doi hanh vi. Regression toan bo
Testkit/*.tkv - khong hoi quy moi. DONG TOAN BO batch 5.5b (7/7 muc).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```
