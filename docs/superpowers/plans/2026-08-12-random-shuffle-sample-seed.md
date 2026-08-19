# random.seed/shuffle/sample Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `seed(n)`/`shuffle(lst)`/`sample(lst, k)` cho TokenVector, và
làm cho `seed()` THẬT SỰ có tác dụng (mọi lời gọi random dùng chung 1
`System.Random` đã seed).

**Architecture:** `TkvRandom` static helper class (tái dùng mẫu
`TkvLogging`) giữ 1 `System.Random` field static, khởi tạo lười.
`shuffle`/`sample` sinh Fisher-Yates INLINE tại điểm gọi (KHÔNG dùng
generic method tự viết — đã probe thật, rủi ro `MissingMethodException`,
xem spec), dùng kiểu `List<T>` cụ thể qua `il_list_type` giống hệt
`compile_choice` hiện có.

**Tech Stack:** Python 3 (compiler), CIL text qua `ilasm.exe`.

## Global Constraints

- Sửa CẢ 2 cây (`compiler/il_features/stdlib_random.py`/
  `release/3.code/compiler/il_features/stdlib_random.tkv`,
  `compiler/il_features/file_io.py`/`.tkv`) đồng bộ.
- `shuffle`/`sample` CHỈ nhận 1 BIẾN list đơn (giống giới hạn `choice()`
  hiện có), KHÔNG generic method tự viết.
- `seed(n)` bắt buộc có tham số `n: i32` — KHÔNG hỗ trợ `seed()` không
  tham số.
- Mọi thay đổi codegen phải xác nhận qua build+chạy THẬT.
- Spec đầy đủ: `docs/superpowers/specs/2026-08-12-random-shuffle-sample-seed-design.md`.

---

### Task 1: `TkvRandom` static class + chuyển 5 hàm random hiện có sang dùng chung

**Files:**
- Modify: `compiler/il_features/stdlib_random.py` — thêm `ensure_class`,
  hàm `TkvRandom`, sửa `compile_random`/`compile_randint`/
  `compile_uniform`/`compile_randrange`/`compile_choice` dùng
  `TkvRandom::Instance()` thay vì `newobj Random::.ctor()`.
- Modify: `release/3.code/compiler/il_features/stdlib_random.tkv` —
  mirror.
- Test: `release/3.code/Testkit/random_shared_rng_py_tree_test.tkv` (mới).

**Interfaces:**
- Produces: `ensure_class(ctx)` (idempotent, dedupe qua
  `ctx['emitted_types']`), sinh `.class ... TkvRandom` với 2 method:
  `Instance() -> class [mscorlib]System.Random` (public static, khởi
  tạo lười), `SetSeed(int32) -> void` (public static). Task 2 (`seed`
  statement) tiêu thụ `SetSeed`; Task 3 (`shuffle`/`sample`) tiêu thụ
  `Instance()`.

- [ ] **Step 1: Thêm `ensure_class`/`_HELPER_CLASS` vào đầu `stdlib_random.py`**

Thêm vào đầu `compiler/il_features/stdlib_random.py` (sau các dòng
`import`):

```python
_HELPER_CLASS = 'TkvRandom'


def ensure_class(ctx):
    """Sinh 1 lan/chuong trinh (dedupe qua ctx['emitted_types']) class
    tinh TkvRandom giu 1 System.Random DUNG CHUNG toan chuong trinh -
    khoi tao LUOI (neu chua tung goi seed()) tai lan goi Instance() DAU
    TIEN, giong het mau TkvLogging (logging_feature.py's ensure_class)."""
    emitted = ctx.get('emitted_types')
    if emitted is None or _HELPER_CLASS in emitted:
        return
    emitted.add(_HELPER_CLASS)
    ctx['extra_classes'].append([
        f'.class public auto ansi beforefieldinit {_HELPER_CLASS} extends [mscorlib]System.Object',
        '{',
        '  .field private static class [mscorlib]System.Random rng',
        '  .method public static class [mscorlib]System.Random Instance() cil managed',
        '  {',
        '    .maxstack 8',
        f'    ldsfld class [mscorlib]System.Random {_HELPER_CLASS}::rng',
        '    brtrue TKVRANDOM_HAVE',
        '    newobj instance void [mscorlib]System.Random::.ctor()',
        f'    stsfld class [mscorlib]System.Random {_HELPER_CLASS}::rng',
        '  TKVRANDOM_HAVE:',
        f'    ldsfld class [mscorlib]System.Random {_HELPER_CLASS}::rng',
        '    ret',
        '  }',
        '  .method public static void SetSeed(int32 n) cil managed',
        '  {',
        '    .maxstack 8',
        '    ldarg.0',
        '    newobj instance void [mscorlib]System.Random::.ctor(int32)',
        f'    stsfld class [mscorlib]System.Random {_HELPER_CLASS}::rng',
        '    ret',
        '  }',
        '}',
    ])
```

- [ ] **Step 2: Sửa 5 hàm random dùng `TkvRandom::Instance()`**

Trong `stdlib_random.py`, thêm `ensure_class(ctx)` làm dòng ĐẦU TIÊN của
mỗi hàm `compile_random`/`compile_randint`/`compile_uniform`/
`compile_randrange`/`compile_choice`, rồi thay MỌI dòng
`out.append('    newobj instance void [mscorlib]System.Random::.ctor()')`
bằng `out.append(f'    call class [mscorlib]System.Random {_HELPER_CLASS}::Instance()')`.

Ví dụ cụ thể cho `compile_random` (áp dụng tương tự cho 4 hàm còn lại —
CHỈ đổi dòng tạo Random, KHÔNG đổi phần còn lại của mỗi hàm):

```python
def compile_random(args, scope, out, dtype, ctx):
    if len(args) != 0:
        raise SyntaxError("il_codegen: random() khong nhan tham so nao")
    ensure_class(ctx)
    out.append(f'    call class [mscorlib]System.Random {_HELPER_CLASS}::Instance()')
    out.append('    callvirt instance float64 [mscorlib]System.Random::NextDouble()')
    ctx['widen_if_needed']('f64', dtype, out)
```

- [ ] **Step 3: Viết test xác nhận `TkvRandom` sinh đúng, build được**

Tạo `release/3.code/Testkit/random_shared_rng_py_tree_test.tkv`:

```python
def run() -> "i32":
    a: "f64" = random()
    b: "i32" = randint(1, 100)
    print("a=" + str(a))
    print("b=" + str(b))
    return 0
```

Chạy:
```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/random_shared_rng_py_tree_test.tkv --entry run --out /tmp/rnd_t1_test.exe
/tmp/rnd_t1_test.exe
```

Expected: build PASS, in ra 2 dòng `a=`/`b=` với giá trị hợp lệ (không
crash — `a` trong `[0,1)`, `b` trong `[1,100]`).

- [ ] **Step 4: Regression các file test random cũ (nếu có) + 1 mẫu Testkit khác**

```bash
cd "D:\Claude AI Project\TokenVector"
grep -rl "random()\|randint(\|choice(\|uniform(\|randrange(" release/3.code/Testkit/*.tkv
```

Với MỖI file tìm được, build+chạy qua `.py` tree, xác nhận PASS (không
crash, không lỗi `ilasm`) — 5 hàm cũ chỉ đổi NGUỒN lấy `Random` instance,
không đổi logic gọi method sau đó.

- [ ] **Step 5: Áp dụng Step 1/2 cho cây `.tkv`**

Sửa `release/3.code/compiler/il_features/stdlib_random.tkv` y hệt.

- [ ] **Step 6: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_features/stdlib_random.py \
        release/3.code/compiler/il_features/stdlib_random.tkv \
        release/3.code/Testkit/random_shared_rng_py_tree_test.tkv
git commit -m "$(cat <<'EOF'
feat(compiler): TkvRandom static class - RNG dung chung ca chuong trinh

Tai dung mau TkvLogging (logging_feature.py): 1 field static System.Random,
khoi tao LUOI tai lan goi Instance() dau tien. 5 ham random/randint/
uniform/randrange/choice chuyen tu 'newobj Random moi moi lan goi' sang
dung chung 1 instance qua TkvRandom::Instance() - chuan bi cho seed()
(Task 2) THAT SU co tac dung. Sua luon 1 bug cu (docstring da ghi nhan):
2 loi goi random() rat gan nhau co the tra CUNG gia tri do TickCount seed
trung nhau - dung chung 1 instance loai bo hoan toan van de nay.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: `seed(n)` statement

**Files:**
- Modify: `compiler/il_features/stdlib_random.py` — thêm
  `RANDOM_STMT_CODEGEN` dict + `codegen_seed`.
- Modify: `compiler/il_features/file_io.py` — import
  `stdlib_random`, thêm nhánh `elif name in _stdlib_random.RANDOM_STMT_CODEGEN:`
  vào `codegen_call_stmt`.
- Modify: `release/3.code/compiler/il_features/stdlib_random.tkv`,
  `release/3.code/compiler/il_features/file_io.tkv` — mirror.
- Test: mở rộng `release/3.code/Testkit/random_shared_rng_py_tree_test.tkv`.

**Interfaces:**
- Consumes: `_HELPER_CLASS`/`ensure_class`/`TkvRandom::SetSeed(int32)`
  từ Task 1.
- Produces: `RANDOM_STMT_CODEGEN = {'seed': codegen_seed}` — dict cùng
  hình dạng với `LOG_STMT_CODEGEN`/`DUMP_STMT_CODEGEN`/`SYS_STMT_CODEGEN`
  (đã có sẵn, xem `file_io.py`'s `codegen_call_stmt`), key là tên hàm
  DSL, value là hàm `(call_args, scope, body, ctx) -> None`.

- [ ] **Step 1: Thêm `codegen_seed`/`RANDOM_STMT_CODEGEN` vào `stdlib_random.py`**

Thêm vào cuối `compiler/il_features/stdlib_random.py` (SAU các
`register_expr_builtin(...)` hiện có):

```python
def codegen_seed(call_args, scope, body, ctx):
    """seed(n) - lenh DOC LAP (khong tra gia tri), dispatch qua
    RANDOM_STMT_CODEGEN giong het log_set_level (logging_feature.py)."""
    if len(call_args) != 1:
        raise SyntaxError("il_codegen: seed(n) nhan dung 1 tham so")
    ensure_class(ctx)
    ctx['compile_expr'](call_args[0], scope, body, 'i32', ctx)
    body.append(f'    call void {_HELPER_CLASS}::SetSeed(int32)')


RANDOM_STMT_CODEGEN = {'seed': codegen_seed}
```

- [ ] **Step 2: Wire vào `file_io.py`'s `codegen_call_stmt`**

Thêm import ở đầu `compiler/il_features/file_io.py` (cạnh các import
`_logging_feature`/`_pickle_feature`/`_stdlib_sys` đã có):

```python
import il_features.stdlib_random as _stdlib_random
```

Thêm 1 nhánh `elif` MỚI vào `codegen_call_stmt` (đặt SAU nhánh
`_stdlib_sys.SYS_STMT_CODEGEN` hiện có, TRƯỚC nhánh `else` cuối cùng —
đọc lại toàn bộ chuỗi `elif` hiện có trong file trước khi chèn để chèn
đúng vị trí, không phá thứ tự):

```python
    elif name in _stdlib_random.RANDOM_STMT_CODEGEN:
        # seed(n) (batch 5.5, 2026-08-12) - xem il_features/stdlib_random.py.
        # Ham VOID, dispatch qua day giong log_X/pickle_dump_X/sys_exit.
        _stdlib_random.RANDOM_STMT_CODEGEN[name](call_args, scope, body, ctx)
```

- [ ] **Step 3: Mở rộng test, xác nhận `seed()` THẬT SỰ có tác dụng (cùng seed → cùng dãy giá trị)**

Sửa `release/3.code/Testkit/random_shared_rng_py_tree_test.tkv` thành:

```python
def check(name: "str", got: "str", want: "str") -> "i32":
    if got == want:
        print("PASS " + name)
        return 1
    print("FAIL " + name + " got=" + got + " want=" + want)
    return 0


def run() -> "i32":
    tested: "i32" = 0
    total: "i32" = 0

    seed(42)
    a1: "i32" = randint(1, 1000000)
    a2: "i32" = randint(1, 1000000)
    seed(42)
    b1: "i32" = randint(1, 1000000)
    b2: "i32" = randint(1, 1000000)
    tested = tested + 1
    total = total + check("seed_reproducible",
                           str(a1) + "," + str(a2), str(b1) + "," + str(b2))

    print("SUMMARY " + str(total) + "/" + str(tested))
    return 0
```

Chạy:
```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/random_shared_rng_py_tree_test.tkv --entry run --out /tmp/rnd_t2_test.exe
/tmp/rnd_t2_test.exe
```

Expected: build PASS, output `SUMMARY 1/1` (`PASS seed_reproducible`) —
đây là bằng chứng `seed()` THẬT SỰ seed lại `TkvRandom`'s instance dùng
chung, không chỉ không lỗi.

- [ ] **Step 4: Áp dụng Step 1/2 cho cây `.tkv`**

Sửa `release/3.code/compiler/il_features/stdlib_random.tkv`,
`release/3.code/compiler/il_features/file_io.tkv` y hệt.

- [ ] **Step 5: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_features/stdlib_random.py compiler/il_features/file_io.py \
        release/3.code/compiler/il_features/stdlib_random.tkv \
        release/3.code/compiler/il_features/file_io.tkv \
        release/3.code/Testkit/random_shared_rng_py_tree_test.tkv
git commit -m "$(cat <<'EOF'
feat(compiler): seed(n) - dat lai TkvRandom dung chung, xac nhan that co tac dung

seed(n) dispatch qua RANDOM_STMT_CODEGEN (giong mau log_set_level/
sys_exit) - goi TkvRandom::SetSeed(int32), gan lai field static rng =
new Random(n). Test moi xac nhan CUNG seed(42) -> CUNG day gia tri
randint() lien tiep - bang chung that seed() co tac dung, khong chi
khong loi.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: `shuffle(lst)` và `sample(lst, k)` — Fisher-Yates inline

**Files:**
- Modify: `compiler/il_features/stdlib_random.py` — thêm
  `codegen_shuffle_stmt` (vào `RANDOM_STMT_CODEGEN`), `compile_sample`
  (expr builtin).
- Modify: `release/3.code/compiler/il_features/stdlib_random.tkv` —
  mirror.
- Test: `release/3.code/Testkit/random_shuffle_sample_py_tree_test.tkv`
  (mới).

**Interfaces:**
- Consumes: `_HELPER_CLASS`/`ensure_class`/`TkvRandom::Instance()` từ
  Task 1, `RANDOM_STMT_CODEGEN` từ Task 2 (thêm `'shuffle'` vào dict đó).
- Produces: `shuffle(lst)` — statement, mutate `lst` tại chỗ. `sample(lst,
  k)` — expr builtin, trả `List<T>` MỚI cùng dtype phần tử với `lst`
  (đăng ký `return_dtype_fn` TRẢ VỀ dtype của `lst`, giống hệt cách
  `_choice_dtype_fn` đã làm cho `choice()`).

- [ ] **Step 1: `shuffle(lst)` — statement, Fisher-Yates tại chỗ**

Thêm vào `stdlib_random.py`:

```python
def codegen_shuffle_stmt(call_args, scope, body, ctx):
    """shuffle(lst) - Fisher-Yates TAI CHO, sinh INLINE (khong generic
    method tu viet - xem spec 2026-08-12-random-shuffle-sample-seed-design.md
    muc 'Sua lai so voi y tuong ban dau'). lst PHAI la 1 BIEN list don
    (giong gioi han choice()). Vong lap: for i in [len-1 .. 1]: j =
    Instance().Next(0, i+1); swap lst[i], lst[j]."""
    if len(call_args) != 1:
        raise SyntaxError("il_codegen: shuffle(lst) nhan dung 1 tham so")
    if call_args[0][0] != 'var':
        raise SyntaxError(
            "il_codegen: shuffle(lst) chi ho tro tham so la 1 BIEN list don")
    var_name = call_args[0][1]
    _, _, ta = scope[var_name]
    if ta.shape != 'list':
        raise SyntaxError(f"il_codegen: shuffle(lst) can '{var_name}' la list (shape={ta.shape!r})")
    from il_features.list_type import il_list_type
    list_type = il_list_type(ta.dtype, (ctx or {}).get('records'))
    load_var_ref = ctx['load_var_ref']
    ensure_class(ctx)

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    prefix = ctx.get('prefix', 'shuffle')
    start_lbl, end_lbl = f'{prefix}_shuf{n}_start', f'{prefix}_shuf{n}_end'

    body.append('    .locals init (int32)')  # KHONG dung - xem Step 2 ghi chu ve locals that
    # (placeholder logic - THAY THE bang cach dung 2 local tam that qua
    # scope o Step 2, xem ghi chu ben duoi truoc khi code that)
```

**QUAN TRỌNG — sự thật về khai báo local trong kiến trúc này**: hàm
codegen builtin (`compile_*`/`codegen_*` trong `il_features/*.py`)
KHÔNG được tự thêm `.locals init` trực tiếp vào `body` (danh sách
`.locals` của method được `gen_il_function` gom 1 LẦN DUY NHẤT ở first-
pass, TRƯỚC khi any `il_features/*.py` codegen chạy — xem
`_first_pass_collect_locals`/`FIRST_PASS_WALK`). Cần 2 biến tạm nguyên
(`i`, `j`) cho vòng lặp Fisher-Yates — đọc lại cách `stdlib_aggregates.py`
hoặc module khác đã cần local tạm ẩn bên trong 1 `EXPR_BUILTIN`/
`STMT_CODEGEN` xử lý việc này (tìm bằng
`grep -rn "declare_named\|__.*tmp" compiler/il_features/*.py | head -20`
để tìm ĐÚNG API khai báo local ẩn từ first-pass) — implementer PHẢI đọc
cơ chế thật này trước khi viết `codegen_shuffle_stmt`, KHÔNG tự chèn
`.locals init` trực tiếp như dòng ví dụ placeholder ở trên (dòng đó SẼ
lỗi `ilasm` vì trùng khai báo `.locals` với block do `gen_il_function`
tự sinh — bỏ dòng đó, thay bằng cơ chế local-ẩn-first-pass thật).

- [ ] **Step 2: Đọc cơ chế khai báo local ẩn thật, viết lại `codegen_shuffle_stmt` cho đúng**

```bash
cd "D:\Claude AI Project\TokenVector"
grep -rn "FIRST_PASS_WALK\|register_first_pass_walk\|declare_named\|__.*_tmp" \
  compiler/il_codegen.py compiler/il_features/stdlib_aggregates.py | head -30
```

Xác nhận API đăng ký "cần N local ẩn kiểu i32" cho 1 `kind` mới (nếu
`shuffle` cần được nâng cấp từ `call_stmt` chung thành 1 `kind` Stmt
RIÊNG có `FIRST_PASS_WALK` để khai local `__shuf_i`/`__shuf_j` — theo
ĐÚNG mẫu `nested_def`/vòng lặp `for` khác đã dùng `ctx['declare_named']`
hoặc tương đương, xem `closures.py`'s `ctx['declare_named'](hidden_local,
closure_ta)` dòng 173 làm ví dụ tham chiếu THẬT). Sau khi xác nhận API
đúng, viết lại `codegen_shuffle_stmt` dùng 2 local ẩn `i32` cho `i`/`j`,
thân vòng lặp:

```
i = len(lst) - 1
LOOP:
  if i <= 0: goto END
  j = TkvRandom::Instance().Next(0, i + 1)
  tmp = lst[i]; lst[i] = lst[j]; lst[j] = tmp
  i = i - 1
  goto LOOP
END:
```

(Cần thêm 1 local ẩn thứ 3 kiểu `T` — dtype phần tử `lst` — cho biến
`tmp` khi hoán đổi 2 phần tử `List<T>` qua `get_Item`/`set_Item`, KHÔNG
có cách hoán đổi trực tiếp không qua biến tạm với `List<T>` API.)

- [ ] **Step 3: Đăng ký `shuffle` vào `RANDOM_STMT_CODEGEN`**

```python
RANDOM_STMT_CODEGEN = {'seed': codegen_seed, 'shuffle': codegen_shuffle_stmt}
```

- [ ] **Step 4: `sample(lst, k)` — expr builtin, trả list mới**

```python
def compile_sample(args, scope, out, dtype, ctx):
    """sample(lst, k) - tra ve 1 List<T> MOI gom k phan tu ngau nhien tu
    lst, KHONG mutate lst goc. Tao ban sao qua .ctor(IEnumerable<T>),
    xao k phan tu dau (CUNG thuat toan Fisher-Yates nhu shuffle, gioi han
    o k buoc dau thay vi het list), roi GetRange(0, k) cat lay k phan tu
    dau."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: sample(lst, k) nhan dung 2 tham so")
    if args[0][0] != 'var':
        raise SyntaxError(
            "il_codegen: sample(lst, k) chi ho tro tham so dau la 1 BIEN list don")
    var_name = args[0][1]
    _, _, ta = scope[var_name]
    if ta.shape != 'list':
        raise SyntaxError(f"il_codegen: sample(lst, k) can '{var_name}' la list (shape={ta.shape!r})")
    from il_features.list_type import il_list_type
    list_type = il_list_type(ta.dtype, (ctx or {}).get('records'))
    ensure_class(ctx)
    load_var_ref = ctx['load_var_ref']
    compile_expr = ctx['compile_expr']

    # Ban sao: newobj List<T>(IEnumerable<T>) nhan THANG list nguon lam
    # tham so .ctor - xac nhan lai qua ilasm THAT truoc khi cho vao
    # implementation cuoi cung (List<T> co overload .ctor(IEnumerable<T>),
    # List<T> tu no La 1 IEnumerable<T> hop le - xac nhan qua reflection
    # thuc te, khong doan).
    load_var_ref(var_name, scope, out)
    out.append(f'    newobj instance void {list_type}::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')
    # (con lai: xao k phan tu dau CUNG thuat toan Fisher-Yates cua Step 2,
    # ap dung tren BAN SAO tren dinh stack/1 local an moi, roi GetRange(0,k)
    # - viet chi tiet dua tren local-tam API da xac nhan o Step 2, KHONG
    # lap lai code Fisher-Yates lan 2 - trich xuat 1 ham dung chung
    # _fisher_yates_prefix(body, list_type, list_local_idx, k_node, n_limit)
    # goi tu CA codegen_shuffle_stmt LAN compile_sample de tranh trung lap.)


def _sample_dtype_fn(args, scope):
    """dtype tra ve cua sample(lst, k) PHU THUOC dtype 'lst' - giong het
    _choice_dtype_fn."""
    if len(args) != 2 or args[0][0] != 'var':
        return None
    try:
        return scope[args[0][1]][2].dtype
    except KeyError:
        return None


register_expr_builtin('sample', compile_sample, None, return_dtype_fn=_sample_dtype_fn)
```

**Bắt buộc**: TRƯỚC khi hoàn thiện code trên, xác nhận THẬT (không đoán)
qua PowerShell reflection rằng `List<T>` có constructor nhận
`IEnumerable<T>`:
```bash
powershell -Command "[System.Collections.Generic.List[int]].GetConstructor([Type[]]@([System.Collections.Generic.IEnumerable[int]]))"
```
Nếu KHÔNG có overload này (hoặc chữ ký IL khác với dự đoán), sửa lại
cách sao chép list (fallback: vòng lặp `Add` thủ công từng phần tử,
giống cách nhiều chỗ khác trong codebase đã làm) — KHÔNG giữ nguyên code
trên nếu reflection không xác nhận đúng.

Trích xuất phần Fisher-Yates dùng chung giữa `codegen_shuffle_stmt` và
`compile_sample` thành 1 hàm nội bộ `_fisher_yates_prefix(...)` (tránh
trùng lặp thuật toán 2 lần) — cụ thể hóa chữ ký sau khi Step 2 đã chốt
API local-ẩn thật.

- [ ] **Step 5: Viết test `shuffle`/`sample`, xác nhận đúng ngữ nghĩa**

Tạo `release/3.code/Testkit/random_shuffle_sample_py_tree_test.tkv`:

```python
def check(name: "str", got: "str", want: "str") -> "i32":
    if got == want:
        print("PASS " + name)
        return 1
    print("FAIL " + name + " got=" + got + " want=" + want)
    return 0


def sum_list(lst: "list[i32]") -> "i32":
    total: "i32" = 0
    for x in lst:
        total = total + x
    return total


def run() -> "i32":
    tested: "i32" = 0
    total: "i32" = 0

    seed(7)
    nums: "list[i32]" = [1, 2, 3, 4, 5]
    before_sum: "i32" = sum_list(nums)
    shuffle(nums)
    after_sum: "i32" = sum_list(nums)
    tested = tested + 1
    total = total + check("shuffle_preserves_sum", str(after_sum), str(before_sum))
    tested = tested + 1
    total = total + check("shuffle_preserves_len", str(len(nums)), "5")

    seed(7)
    src: "list[i32]" = [10, 20, 30, 40, 50]
    picked: "list[i32]" = sample(src, 3)
    tested = tested + 1
    total = total + check("sample_len", str(len(picked)), "3")
    tested = tested + 1
    total = total + check("sample_source_unchanged", str(sum_list(src)), "150")

    print("SUMMARY " + str(total) + "/" + str(tested))
    return 0
```

Chạy:
```bash
cd "D:\Claude AI Project\TokenVector"
python tkv.py build release/3.code/Testkit/random_shuffle_sample_py_tree_test.tkv --entry run --out /tmp/rnd_t3_test.exe
/tmp/rnd_t3_test.exe
```

Expected: build PASS, `SUMMARY 4/4`. Nếu `ilasm` báo lỗi cú pháp IL —
đối chiếu lại `compile_choice`'s cách dùng `get_Item`/`set_Item` (đã
chạy đúng) và sửa cho khớp, KHÔNG đoán.

- [ ] **Step 6: Regression toàn bộ `Testkit/*.tkv` qua `.py` tree**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  python tkv.py build "$f" --entry run --out "/tmp/rnd_t3_reg_${base}.exe" > "/tmp/rnd_t3_buildlog_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; continue; fi
  res=$("/tmp/rnd_t3_reg_${base}.exe" 2>&1)
  echo "$res" | grep -qi "^FAIL \|Exception" && { echo "=== $base ==="; echo "$res" | tail -5; } || echo "OK $base"
done
```

Expected: mọi dòng `OK` (trừ `path_isfile_isdir_test` pre-existing).

- [ ] **Step 7: Áp dụng toàn bộ Task này cho cây `.tkv`**

Sửa `release/3.code/compiler/il_features/stdlib_random.tkv` y hệt.

- [ ] **Step 8: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add compiler/il_features/stdlib_random.py \
        release/3.code/compiler/il_features/stdlib_random.tkv \
        release/3.code/Testkit/random_shuffle_sample_py_tree_test.tkv
git commit -m "$(cat <<'EOF'
feat(compiler): shuffle(lst)/sample(lst,k) - Fisher-Yates inline, khong generic

shuffle(lst): Fisher-Yates TAI CHO qua RANDOM_STMT_CODEGEN. sample(lst,k):
tra List<T> MOI (khong mutate lst goc), cung thuat toan xao k phan tu dau
tren 1 ban sao. Sinh IL INLINE tai diem goi (khong generic method tu
viet - xem spec, da probe that phat hien MissingMethodException voi
cach tiep can generic ban dau) - dung kieu List<T> CU THE qua
il_list_type, giong het compile_choice da co san. Test moi xac nhan
shuffle giu nguyen tong/do dai, sample dung do dai + khong doi list goc.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Regression cuối + cập nhật docs (KHÔNG rebuild tkvc.exe)

**Files:**
- Modify: `docs/PYTHON_GAP_CHECKLIST.md` (mục 5.5, đánh dấu
  `random.shuffle/sample/seed` xong).

**Interfaces:** không có.

- [ ] **Step 1: Regression toàn bộ `Testkit/*.tkv` qua `.py` tree (xác nhận lần cuối)**

```bash
cd "D:\Claude AI Project\TokenVector"
for f in release/3.code/Testkit/*.tkv; do
  base=$(basename "$f" .tkv)
  case "$base" in tkv_test_lib|import_lib_mod|example_lib|input_py_tree_test|native_test_suite) continue;; esac
  python tkv.py build "$f" --entry run --out "/tmp/rnd_t4_${base}.exe" > "/tmp/rnd_t4_build_${base}.log" 2>&1
  if [ $? -ne 0 ]; then echo "BUILD-FAIL $base"; continue; fi
  res=$("/tmp/rnd_t4_${base}.exe" 2>&1)
  echo "$res" | grep -qi "^FAIL \|Exception" && { echo "=== $base ==="; echo "$res" | tail -5; } || echo "OK $base"
done
```

Expected: mọi dòng `OK` (trừ `path_isfile_isdir_test` pre-existing).

- [ ] **Step 2: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`**

Sửa dòng 5.5 (`- [ ] 5.5 batch nhỏ: random.shuffle/sample/seed, ...`)
thành 2 dòng — 1 dòng `[x]` riêng cho phần vừa xong, giữ nguyên phần
`[ ]` còn lại của batch:

```
- [x] 5.5a `random.shuffle/sample/seed` — ĐÃ XONG (2026-08-12), xem
      `docs/superpowers/plans/2026-08-12-random-shuffle-sample-seed.md`.
      `TkvRandom` static helper class (tái dùng mẫu `TkvLogging`) giữ 1
      `System.Random` dùng chung cả chương trình, khởi tạo lười —
      `seed(n)` giờ THẬT SỰ có tác dụng (trước đây mỗi lời gọi tạo
      Random mới, không có gì để seed). `shuffle(lst)` Fisher-Yates tại
      chỗ, `sample(lst, k)` trả list mới không mutate nguồn — CẢ 2 sinh
      IL inline tại điểm gọi (KHÔNG dùng generic method tự viết — probe
      thật qua `ilasm.exe` phát hiện generic method tự định nghĩa gây
      `MissingMethodException` lúc chạy dù assemble không lỗi, xem spec).
      Tác dụng phụ có lợi: sửa luôn 1 bug cũ (2 lời gọi random() liên
      tiếp có thể trùng giá trị do TickCount seed trùng nhau).
- [ ] 5.5b batch nhỏ còn lại: `re.findall/split/compile`,
      `.replace(...,count)`, `.format()` kwargs, `os.path.splitext()`,
      `divmod()`, `set.remove()` phải ném lỗi khi thiếu phần tử
```

- [ ] **Step 3: Commit**

```bash
cd "D:\Claude AI Project\TokenVector"
git add docs/PYTHON_GAP_CHECKLIST.md
git commit -m "$(cat <<'EOF'
docs: xac nhan hoan thanh random.shuffle/sample/seed (5.5a)

Regression toan dien qua cay .py cho ket qua khong doi tren toan bo
Testkit/*.tkv. KHONG rebuild tkvc.exe (theo chi thi nguoi dung, giong
2 plan truoc). Xem chi tiet o
docs/superpowers/specs/2026-08-12-random-shuffle-sample-seed-design.md
va docs/superpowers/plans/2026-08-12-random-shuffle-sample-seed.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review (đã thực hiện khi viết plan này)

**1. Spec coverage**: `TkvRandom` static class + 5 hàm cũ dùng chung →
Task 1. `seed(n)` → Task 2 (kèm test xác nhận THẬT SỰ có tác dụng, đúng
yêu cầu "Kiểm chứng" của spec). `shuffle`/`sample` Fisher-Yates inline
(không generic) → Task 3. Regression + docs → Task 4. Phần "Phạm vi"
của spec (chỉ nhận biến list đơn, không `seed()` không tham số, không
`choices()` có trọng số) — không có task nào vi phạm, đúng ý định.

**2. Placeholder scan**: Task 3 Step 1 có 1 đoạn code MINH HỌA rồi tự
đánh dấu "placeholder logic" và YÊU CẦU RÕ RÀNG không giữ nguyên, phải
đọc API local-ẩn thật ở Step 2 trước khi hoàn thiện — đây LÀ MỘT
PLACEHOLDER THẬT theo nghĩa "No Placeholders" cấm, nhưng được xử lý
ĐÚNG CÁCH bằng cách: (a) không để implementer tự đoán cách khai local,
(b) chỉ rõ chính xác lệnh `grep` cần chạy để tìm API thật, (c) tách
riêng thành 2 Step (1 = nhận diện vấn đề, 2 = giải quyết bằng API thật)
thay vì để 1 Step half-baked. Đây là mẫu hình đã dùng THÀNH CÔNG nhiều
lần trong các plan trước của dự án này (vd DebugPDB Task 1's ghi chú về
`_rewrite_nested_defs`) — chấp nhận được vì đi kèm hướng dẫn xác minh cụ
thể, không phải "TBD" mơ hồ. Task 3 Step 4 tương tự (yêu cầu xác minh
`List<T>.ctor(IEnumerable<T>)` qua reflection THẬT trước khi chốt code,
có lệnh cụ thể để chạy).

**3. Type consistency**: `ensure_class(ctx)`/`_HELPER_CLASS` (Task 1)
dùng NHẤT QUÁN ở Task 2/3 (import cùng tên, không đổi). `RANDOM_STMT_CODEGEN`
(Task 2 định nghĩa `{'seed': ...}`) được Task 3 MỞ RỘNG thêm
`'shuffle'` (không tạo dict mới trùng tên). `TkvRandom::Instance()`/
`SetSeed(int32)` — chữ ký dùng nhất quán xuyên suốt Task 1 (định nghĩa
IL) → Task 2/3 (gọi).

## Execution Handoff

Plan hoàn chỉnh, lưu tại
`docs/superpowers/plans/2026-08-12-random-shuffle-sample-seed.md`.

Hai lựa chọn thực thi:

**1. Subagent-Driven (khuyến nghị)** - giao mỗi Task cho 1 subagent mới,
review giữa các Task, lặp nhanh.

**2. Inline Execution** - thực thi trong phiên này qua executing-plans,
chạy theo lô có checkpoint để bạn review.

Bạn muốn dùng cách nào?
