# TokenVector Handbook / Sổ tay TokenVector

<p align="left"><strong>English</strong> | <a href="HANDBOOK.vi.md">Tiếng Việt (bản đầy đủ)</a></p>

Two languages, one source of truth. The **detailed** handbook is
`HANDBOOK.vi.md` (10 chapters, Vietnamese). This page is the bilingual index plus
the rules that bite most often — the parts worth reading even if you read
nothing else.

> **Still the single authority:** `REFERENCE.md` lists every builtin with its
> syntax, behaviour and Python differences. This handbook is orientation.

---

## 1. What the compiler is / Compiler là gì

**EN** — TokenVector compiles `.tkv` to .NET CIL and links a standalone PE
executable.

The compiler **is** written in TokenVector: `compiler_bootstrap/` is 132 `.tkv`
files of real TokenVector source. `dist\tkvc-tv.exe` is built by `tools\vong.exe`,
which concatenates them and compiles the result **twice**; the two IL dumps must
match byte-for-byte (`IL_IDENTICAL`). No CPython is involved at any point.

**VI** — TokenVector biên dịch `.tkv` ra .NET CIL rồi liên kết thành tệp `.exe`
độc lập.

Bản thân compiler **viết bằng TokenVector**: `compiler_bootstrap/` là 132 file
`.tkv` TokenVector thật. `dist\tkvc-tv.exe` do `tools\vong.exe` sinh ra — nó gộp
132 file đó rồi biên dịch **hai lần**, và hai bản IL phải giống hệt nhau
byte-for-byte (`IL_IDENTICAL`). Không có CPython ở bất kỳ bước nào.

## 2. Layout / Bố cục repo

| Path | EN | VI |
|---|---|---|
| `compiler_bootstrap/` | **The compiler.** 132 `.tkv` files of real TokenVector | **Compiler:** lexer, parser, emitter, 132 file TokenVector thật |
| `tests/` | 123 acceptance tests + 31 negative cases | 123 test nghiệm thu + 31 case phải bị từ chối |
| `tools/` | Gates, plus `tkv_guide.tkv` | Các cổng kiểm + tool hỏi đáp |
| `projects/` | 19 real tools written in `.tkv` | 19 công cụ thật viết bằng `.tkv` |
| `examples/` | Sample programs + `stdlib/` | Chương trình mẫu + thư viện stdlib mẫu |
| `docs/` | All documentation | Toàn bộ tài liệu |
| `packaging/` | NuGet nuspec, props/targets, `pack.ps1` | Thông tin đóng gói NuGet |
| `assets/` | Diagrams, HTML demos, preview image | Sơ đồ, demo HTML, ảnh xem trước |

## 3. The rules that bite / Ràng buộc hay cắn người viết

**EN** — every one of these is enforced by the compiler or covered by a test:

| # | Rule |
|---|---|
| 1 | Locals inside a function must **not** be annotated: `x = 1`, never `x: "i32" = 1`. The type is inferred from the right-hand side. |
| 2 | **Module level has no variables.** Only `def`, `class`, constants and typed one-way globals (`counter: "i32" = 0`). |
| 3 | A module-level constant of type `"str"` **cannot be read inside a function** — only `i32` globals work. Write the expression inside the function instead. |
| 4 | **Methods only on named variables**, not literals or arbitrary expressions (`t = ","; t.join(xs)`). |
| 5 | **Container methods are standalone statements**: `xs.append(v)` is a statement, `y = xs.pop()` is a compile error. Use `y = xs[len(xs) - 1]`. |
| 6 | `str(x)` accepts **any expression** — `str(a + b)`, `str(len(xs) + 1)`. Only `fmt_float(v, n)` requires `v` to be a plain variable. |
| 7 | Regex builtins take the **input first**: `re_search(pattern, s)`. |
| 8 | `except RuntimeError:` **also catches `StopIteration`** — both are `InvalidOperationException`. Use `next(it, default)`. |
| 9 | A **UTF-8 BOM** in the source is rejected (`U+FEFF`). PowerShell 5.1's `Set-Content -Encoding UTF8` writes one. |
| 10 | **A green build is not a correct program.** Always build *and run*. |

**VI** — cả 10 điều trên đều có compiler chặn hoặc test che:

1. Biến cục bộ trong thân hàm **không được** annotate kiểu: `x = 1`, không phải `x: "i32" = 1`.
2. **Cấp module không có biến.** Chỉ `def`, `class`, hằng số và biến global một chiều có kiểu (`counter: "i32" = 0`).
3. Hằng số cấp module kiểu `"str"` **không đọc được trong hàm** — chỉ `i32` global hoạt động.
4. **Method chỉ gọi trên biến có tên**, không trên literal hay biểu thức bất kỳ (`t = ","; t.join(xs)`).
5. **Method container là lệnh độc lập**: `xs.append(v)` là lệnh, `y = xs.pop()` là lỗi biên dịch. Dùng `y = xs[len(xs) - 1]`.
6. `str(x)` nhận **mọi biểu thức** — `str(a + b)`, `str(len(xs) + 1)`. Chỉ `fmt_float(v, n)` mới bắt buộc `v` là biến đơn.
7. Regex nhận **đầu vào trước**: `re_search(pattern, s)`.
8. `except RuntimeError:` **cũng bắt `StopIteration`** — cùng là `InvalidOperationException`. Dùng `next(it, default)`.
9. **BOM UTF-8** trong file nguồn bị từ chối (`U+FEFF`).
10. **Build xanh không có nghĩa chương trình đúng.** Luôn build *và chạy*.

## 4. Worked example / Ví dụ

```python
# -*- coding: utf-8 -*-
class Series:
    name: "str"
    values: "list[int]"

    def __init__(self, name, values):
        self.name = name
        self.values = values

    def mean(self) -> "f64":
        if len(self.values) == 0:
            return 0.0
        total = 0.0
        for v in self.values:
            total = total + v
        return total / len(self.values)

def run() -> "i32":
    s = Series("cpu", [1, 2, 3, 4])
    print(s.name + " mean=" + str(s.mean()))
    return 0
```

Note: the container field is declared `list[int]` (not `list[i32]`) because the
list literal's dtype is `int`; mixing the two causes real type confusion in the
emitted IL. The constructor takes only the scalar fields, so `values` is assigned
by the constructor call as written above.

*Chú ý: field container khai `list[int]` chứ không phải `list[i32]` vì list literal
có dtype `int`; trộn hai loại gây type-confusion thật trong IL. Constructor chỉ
nhận field vô hướng nên `values` được gán qua lệnh khởi tạo như trên.*

## 5. Known gaps / Giới hạn đã biết

Verified by probe; ranked list in `PLAN.md`.

- **No `subprocess`** — a program cannot start another process.
- **Negative slice step rejected** — `a[::-1]`, `a[1:-1]`; positive steps work.
- No `slice()` callable; no keyword-only or positional-only parameters.
- A conditional expression with mismatched branch types (`i32 if c else f64`)
  compiles and returns a **garbage pointer** — keep both branches the same dtype.
- `hash()` is FNV-1a, not Python's: fine as a key, not value-compatible.
- `sort(key=)` / `sorted(key=)` is **not stable** on tied keys.

*Đã probe; xếp theo độ khó trong `PLAN.md`: không `subprocess`; bước slice âm bị
từ chối; không `slice()` dạng hàm; không tham số keyword-only/positional-only;
biểu thức điều kiện lệch kiểu trả con trỏ rác; `hash()` là FNV-1a; `sorted(key=)`
không ổn định.*

## 6. Where to go next / Đọc gì tiếp

| Want / Muốn | Read / Đọc |
|---|---|
| Exact syntax of a builtin / Cú pháp chính xác của một hàm | `REFERENCE.md`, hoặc `dist\tkv_guide.exe find <tên>` |
| Chapter-by-chapter tutorial / Hướng dẫn từng chương | `HANDBOOK.vi.md`, `TUTORIAL.md` |
| How the compiler works / Compiler hoạt động thế nào | `ARCHITECTURE.md` |
| How it differs from Python / Khác Python ở chỗ nào | `COMPARISON-PYTHON.md` |
| What is still missing / Còn thiếu gì | `PLAN.md` |
| Why it is built this way / Vì sao thiết kế thế | `REPOSITORY-NOTES.md` |