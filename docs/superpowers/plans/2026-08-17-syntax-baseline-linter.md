# Syntax Baseline Linter (#4 Tương thích cú pháp) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm 1 lượt kiểm tra tiền xử lý (pre-flight) trước `tkv.py build`
quét toàn bộ AST file `.tkv` nguồn, báo HẾT mọi construct cú pháp Python
không được compiler hỗ trợ (kèm dòng + tên construct + gợi ý thay thế nếu
có) trước khi vào pipeline biên dịch chính.

**Architecture:** Module độc lập mới `compiler/syntax_baseline.py` dùng
`ast.parse`/`ast.walk` chuẩn Python, đối chiếu whitelist node type suy ra từ
việc đọc thật code compiler. `tkv.py build` gọi module này TRƯỚC
`compile_tkv_cli`, có cờ `--no-lint` để tắt.

**Tech Stack:** Python 3 `ast` module (built-in, không thêm dependency).

## Global Constraints

- Linter KHÔNG được đụng/sửa `tkv_compile.py`/`il_codegen.py`/bất kỳ file
  compiler pipeline nào — hoàn toàn tách biệt, chỉ đọc AST bằng
  `ast.parse` chuẩn Python.
- Linter chỉ kiểm tra CÚ PHÁP (AST shape) — KHÔNG kiểm tra dtype/logic
  nghiệp vụ. Các `TranspileError`/`SyntaxError` hiện có trong pipeline vẫn
  giữ nguyên, không bị thay thế.
- Whitelist PHẢI suy ra từ việc đọc THẬT code compiler (Task 1) — không tự
  đoán/liệt kê thủ công trước khi điều tra.
- Mặc định `tkv.py build` LUÔN chạy linter; cờ `--no-lint` để tắt.
- Không dừng ở lỗi đầu tiên — báo HẾT mọi finding tìm thấy trong 1 lượt.
- KHÔNG rebuild `release/3.code/dist/tkvc.exe`.

---

### Task 1: Điều tra — liệt kê whitelist construct được compiler hỗ trợ

**Files:**
- Create: báo cáo điều tra (đường dẫn scratchpad session, KHÔNG phải file
  code) — implementer tự chọn tên rõ ràng, vd
  `.superpowers/sdd/task-1-report.md` theo quy ước SDD hiện có.
- Read: `tkv_compile.py` (toàn bộ, đặc biệt `_parse_program_ast` và mọi
  hàm `elif isinstance(node, ast.XXX)` xử lý top-level statement),
  `compiler/il_codegen.py` (toàn bộ, đặc biệt `_codegen_stmts`/`_expr_*`/
  `_first_pass_collect_locals`/`ASSIGN_RHS_PARSERS`/`LINE_PARSERS`),
  MỌI file `compiler/il_features/*.py` (mỗi file đăng ký 1 nhóm construct
  qua `register_expr_builtin`/`register_expr_method`/`LINE_PARSERS`/
  `FIRST_PASS_WALK`/`STMT_CODEGEN` — cần liệt kê từng file xử lý loại
  node/pattern nào).

**Interfaces:**
- Produces: 1 báo cáo dạng bảng — mỗi hàng là 1 loại AST node Python chuẩn
  (dùng đúng tên class trong module `ast`, vd `ast.ListComp`, `ast.Lambda`,
  `ast.NamedExpr`, `ast.Match`, `ast.JoinedStr`, `ast.FormattedValue`,
  `ast.Starred`, `ast.AsyncFor`, `ast.AsyncFunctionDef` (phân biệt với
  `async def` ĐÃ hỗ trợ — xem `docs/superpowers/plans/2026-08-12-async-
  real-concurrency.md`, cần map đúng), gán đa mục tiêu (`ast.Assign` với
  `len(node.targets) > 1`), v.v.) → cột "Hỗ trợ" (Có/Không/Có điều kiện) +
  cột "Điều kiện/giới hạn" (nếu có, trích nguyên văn comment/code thật, vd
  dòng `tkv_compile.py:191-192` về decorator) + cột "File/dòng xác nhận".
  Task 2 SẼ ĐỌC báo cáo này để viết whitelist thật — không tự đoán lại.

- [ ] **Step 1: Đọc `_parse_program_ast` (`tkv_compile.py`) — liệt kê MỌI
      nhánh `elif isinstance(node, ast.XXX)` xử lý top-level statement**

Ghi vào báo cáo: với mỗi nhánh, node type nào, điều kiện phụ nào (vd chỉ
chấp nhận `ast.Assign` với `target.id` là 1 trong các pragma đặc biệt như
`__tkv_extern_method__`/`__tkv_import__`), và nhánh `else`/fallback cuối
cùng xử lý gì (thường là `def`/`class` — cần đọc kỹ để không bỏ sót).

- [ ] **Step 2: Đọc phần thân hàm/method — liệt kê statement kind nào được
      `_codegen_stmts`/first-pass nhận diện** (`il_codegen.py`)

Liệt kê: `if`/`elif`/`else`, `for` (range/list/dict/set/iterator protocol —
đã có 4 dạng khác nhau, xem `docs/superpowers/plans/2026-08-13-iterator-
protocol.md`), `while`, `try`/`except`/`raise`, `with` (2 dạng: `with_open`
VÀ `with_ctx` — xem `docs/superpowers/plans/2026-08-13-context-manager.md`),
`return`, `break`/`continue`, `global`, gán đơn (`ast.Assign` 1 target),
gán có annotation (`ast.AnnAssign`), gọi hàm dạng lệnh độc lập
(`ast.Expr` bọc `ast.Call`), augmented assign (`ast.AugAssign`, vd `x += 1`
— XÁC NHẬN có hỗ trợ hay không, chưa được nhắc tới trong checklist hiện
có). Với mỗi kind, ghi rõ ast node type + điều kiện (vd `for` chỉ hỗ trợ 1
biến lặp trần, không hỗ trợ `for a, b, c in ...`).

- [ ] **Step 3: Đọc biểu thức (`_expr_*`/`compile_binop`/`compile_compare`
      trong `il_codegen.py` + `compiler/il_features/operators.py`) — liệt
      kê expression kind nào được hỗ trợ**

Liệt kê: literal (`int`/`float`/`str`/`bytes` b"..."/`bool`/`None`), toán
tử số học/so sánh/logic (`and`/`or`/`not`), ternary (`a if cond else b`),
gọi hàm/method (`ast.Call`), index (`ast.Subscript` — CHỈ index đơn, không
slice `a[1:3]`? xác nhận thật), attribute (`ast.Attribute` — chỉ 1 tầng
`obj.field`, không nested `a.b.c`? xác nhận thật theo ghi chú đã có ở mục
6.7 checklist "giới hạn CHUNG của toàn bộ compiler — `obj.field` chỉ 1
tầng"), f-string (`ast.JoinedStr`/`ast.FormattedValue` — XÁC NHẬN không hỗ
trợ, vì dự án dùng `.format()` riêng), list/dict/set LITERAL (`[1,2,3]`
KHÁC list COMPREHENSION `[x for x in y]` — literal có hỗ trợ, comprehension
không), lambda (`ast.Lambda` — XÁC NHẬN mức hỗ trợ thật, đối chiếu cơ chế
"first-class function value" đã dùng cho `map`/`filter`/`reduce`/
`sort(key=...)` chỉ nhận TÊN hàm, không nhận lambda tại chỗ — xác nhận qua
đọc `stdlib_functional.py`), walrus (`ast.NamedExpr` — XÁC NHẬN không hỗ
trợ), starred (`ast.Starred` trong lời gọi hàm hoặc unpacking), generator
expression (`ast.GeneratorExp`), comprehension (`ast.ListComp`/
`ast.DictComp`/`ast.SetComp`), `match`/`case` (`ast.Match`), multiple
assignment target (`a = b = c`), tuple unpacking đa biến (`a, b = f()` —
XÁC NHẬN mức hỗ trợ, đối chiếu `tuple_assign`/`divmod`/`path_splitext` đã
dùng cơ chế này).

- [ ] **Step 4: Viết báo cáo hoàn chỉnh theo format bảng ở mục "Interfaces"**

Mỗi hàng PHẢI có trích dẫn file+dòng thật (không suy đoán) làm bằng chứng.
Cuối báo cáo, liệt kê RIÊNG 1 danh sách "construct XÁC NHẬN KHÔNG hỗ trợ,
có gợi ý thay thế biết trước" (dùng cho Task 2's bảng gợi ý) — tối thiểu
phủ: list/dict/set comprehension, generator expression, lambda phức tạp
(đa dòng/không dùng trong `map`/`filter`/`reduce`/`sort(key=)`), f-string,
walrus, match/case, gán đa mục tiêu `a=b=c`, augmented assign nếu xác nhận
không hỗ trợ, decorator xếp chồng/trên method-trong-class (theo giới hạn đã
biết dòng 191-192).

---

### Task 2: Viết `compiler/syntax_baseline.py` (whitelist + AST walker)

**Files:**
- Create: `compiler/syntax_baseline.py`
- Create: `test/verify/syntax_baseline_test.py`
- Read: báo cáo Task 1 (bắt buộc đọc trước khi viết whitelist — đây LÀ
  nguồn whitelist thật, không viết lại từ đầu).

**Interfaces:**
- Consumes: báo cáo Task 1 (whitelist nội dung thật).
- Produces: hàm `check_syntax_baseline(source_text: str) -> list[SyntaxFinding]`
  — Task 3 gọi hàm NÀY, đúng chữ ký này, từ `tkv.py`.

- [ ] **Step 1: Viết test trước (TDD) — case construct KHÔNG hỗ trợ đơn
      giản nhất, dùng làm khung sườn trước khi có whitelist đầy đủ**

```python
# test/verify/syntax_baseline_test.py
# -*- coding: utf-8 -*-
"""Test cho compiler/syntax_baseline.py - doi chieu voi bao cao dieu tra
Task 1 (docs/superpowers/plans/2026-08-17-syntax-baseline-linter.md)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from compiler.syntax_baseline import check_syntax_baseline

passed = 0
failed = 0


def check(desc, cond):
    global passed, failed
    if cond:
        passed += 1
    else:
        failed += 1
        print(f"  FAIL: {desc}")


# Case 1: list comprehension - KHONG ho tro
src_listcomp = '''
def run() -> None:
    xs = [x for x in range(10)]
'''
findings = check_syntax_baseline(src_listcomp)
check("list comprehension bi bao loi", len(findings) >= 1)
if findings:
    check("bao dung dong (dong 3)", findings[0].line == 3)
    check("ten construct dung", 'comprehension' in findings[0].construct_name.lower())
    check("co goi y thay the", findings[0].suggestion is not None)

print(f"syntax_baseline_test: {'dat' if failed == 0 else 'THAT BAI'} ({passed}/{passed+failed})")
sys.exit(0 if failed == 0 else 1)
```

- [ ] **Step 2: Chạy test, xác nhận FAIL vì `compiler/syntax_baseline.py`
      chưa tồn tại**

Run: `cd "D:/Claude AI Project/TokenVector" && python test/verify/syntax_baseline_test.py`
Expected: `ModuleNotFoundError: No module named 'compiler.syntax_baseline'`

- [ ] **Step 3: Viết `compiler/syntax_baseline.py` — khung + whitelist đầy
      đủ theo báo cáo Task 1**

```python
# -*- coding: utf-8 -*-
"""Pre-flight syntax baseline linter (#4 Tuong thich cu phap,
docs/superpowers/specs/2026-08-17-syntax-baseline-linter-design.md).
Quet TOAN BO AST cua 1 file .tkv nguon, doi chieu voi whitelist cac
construct compiler THAT SU ho tro (suy ra tu tkv_compile.py/il_codegen.py/
compiler/il_features/*.py - xem bao cao dieu tra Task 1). KHONG dung/sua
bat ky file compiler pipeline nao - chi doc AST bang module `ast` chuan."""
import ast
from dataclasses import dataclass


@dataclass
class SyntaxFinding:
    line: int
    construct_name: str
    suggestion: str | None = None


# Ban anh xa construct khong ho tro -> goi y thay the (KHONG can day du
# 100% - construct hiem khong co trong bang thi suggestion=None).
_SUGGESTIONS = {
    'list comprehension': "dung vong 'for' tuong minh thay vi '[x for x in y]'",
    'dict comprehension': "dung vong 'for' tuong minh thay vi '{k:v for ...}'",
    'set comprehension': "dung vong 'for' tuong minh thay vi '{x for x in y}'",
    'generator expression': "dung vong 'for' tuong minh thay vi '(x for x in y)'",
    'f-string': "dung '.format()' hoac noi chuoi '+'",
    'walrus operator (:=)': "tach thanh 2 cau lenh rieng (gan roi dung)",
    'match/case statement': "dung chuoi if/elif/else",
    'multiple-target assignment (a = b = c)': "tach thanh nhieu dong gan rieng",
    # ... (bo sung day du theo bao cao Task 1, danh sach "XAC NHAN KHONG ho tro")
}


class _BaselineVisitor(ast.NodeVisitor):
    def __init__(self):
        self.findings = []

    def _flag(self, node, construct_name):
        self.findings.append(SyntaxFinding(
            line=node.lineno,
            construct_name=construct_name,
            suggestion=_SUGGESTIONS.get(construct_name),
        ))

    def visit_ListComp(self, node):
        self._flag(node, 'list comprehension')
        # KHONG generic_visit - tranh bao trung lap cho node con ben trong

    def visit_DictComp(self, node):
        self._flag(node, 'dict comprehension')

    def visit_SetComp(self, node):
        self._flag(node, 'set comprehension')

    def visit_GeneratorExp(self, node):
        self._flag(node, 'generator expression')

    def visit_JoinedStr(self, node):
        self._flag(node, 'f-string')

    def visit_NamedExpr(self, node):
        self._flag(node, 'walrus operator (:=)')

    def visit_Match(self, node):
        self._flag(node, 'match/case statement')

    def visit_Assign(self, node):
        if len(node.targets) > 1:
            self._flag(node, 'multiple-target assignment (a = b = c)')
        self.generic_visit(node)

    # ... (TIEP TUC bo sung MOI nhanh whitelist theo bao cao Task 1 -
    # MOI node type "KHONG ho tro" xac nhan trong bao cao can 1 method
    # visit_XXX rieng goi self._flag; node type "CO ho tro" hoac "CO dieu
    # kien" KHONG can method rieng - generic_visit tu di qua binh thuong,
    # TRU KHI dieu kien phu tu choi 1 truong hop cu the, vi du Lambda da
    # dong (multi-statement body khong the bieu dien trong AST Python that
    # - MOI ast.Lambda body la 1 bieu thuc DON, nen thuc ra KHONG can chan
    # gi them o day, xac nhan lai trong bao cao Task 1 xem co gioi han nao
    # khac ve lambda hay khong, vd chi cho dung trong map/filter/reduce/
    # sort(key=) - neu co, can 1 pass rieng kiem tra NGU CANH dung lambda,
    # khong chi ban than node Lambda).


def check_syntax_baseline(source_text):
    """Tra ve list[SyntaxFinding] - RONG neu khong co gi vi pham whitelist."""
    tree = ast.parse(source_text)
    visitor = _BaselineVisitor()
    visitor.visit(tree)
    return sorted(visitor.findings, key=lambda f: f.line)
```

**LƯU Ý CHO IMPLEMENTER**: khung code trên CHỈ là điểm khởi đầu — implementer
BẮT BUỘC đọc báo cáo Task 1 đầy đủ và bổ sung MỌI `visit_XXX` cần thiết cho
TỪNG construct "KHÔNG hỗ trợ" xác nhận trong báo cáo (không chỉ 7 case
trong khung mẫu ở trên). Với construct "CÓ ĐIỀU KIỆN" (vd decorator xếp
chồng, `for` đa biến lặp `for a,b,c in`, attribute nested `a.b.c`), viết
method `visit_XXX` kiểm tra ĐÚNG điều kiện phụ đó rồi mới `_flag` (không
chặn nhầm trường hợp hợp lệ).

- [ ] **Step 4: Chạy lại test Step 1, xác nhận PASS**

Run: `cd "D:/Claude AI Project/TokenVector" && python test/verify/syntax_baseline_test.py`
Expected: `syntax_baseline_test: dat (4/4)`

- [ ] **Step 5: Bổ sung test case cho MỖI construct "không hỗ trợ" khác
      liệt kê trong báo cáo Task 1** (dict comprehension, set comprehension,
      generator expression, f-string, walrus, match-case, gán đa mục tiêu,
      VÀ mọi construct khác báo cáo Task 1 xác nhận không hỗ trợ) — mỗi case
      theo đúng mẫu Step 1 (source có lỗi → `check_syntax_baseline` trả về
      finding đúng dòng/tên/gợi ý).

- [ ] **Step 6: Test tích cực — 1 file `.tkv` hợp lệ dùng nhiều construct
      ĐƯỢC hỗ trợ (đối chiếu 1 file thật có sẵn, vd đọc nội dung
      `test/sample_extern_method.tkv` hoặc `Testkit/mro_diamond_test.tkv`),
      xác nhận `check_syntax_baseline` trả về list RỖNG**

```python
sample_path = Path(__file__).resolve().parents[2] / 'test' / 'sample_extern_method.tkv'
src_valid = sample_path.read_text(encoding='utf-8')
findings_valid = check_syntax_baseline(src_valid)
check(f"file hop le khong bi bao loi (file: {sample_path.name})", len(findings_valid) == 0)
if findings_valid:
    for f in findings_valid:
        print(f"  false-positive: dong {f.line}: {f.construct_name}")
```

- [ ] **Step 7: Chạy lại toàn bộ `test/verify/syntax_baseline_test.py`,
      xác nhận PASS 100%. Commit.**

```bash
git add compiler/syntax_baseline.py test/verify/syntax_baseline_test.py
git commit -m "feat(compiler): syntax_baseline.py - whitelist + AST walker (Task 2/4, syntax-baseline-linter)"
```

---

### Task 3: Tích hợp vào `tkv.py build`

**Files:**
- Modify: `tkv.py`

**Interfaces:**
- Consumes: `check_syntax_baseline(source_text) -> list[SyntaxFinding]`
  (Task 2), `SyntaxFinding` (`.line`/`.construct_name`/`.suggestion`).

- [ ] **Step 1: Thêm cờ `--no-lint` vào subcommand `build`**

Sửa `tkv.py` (sau dòng khai `--debug`, trước `args = ap.parse_args()`):

```python
    build.add_argument('--no-lint', action='store_true', default=False,
                        help='Tat pre-flight syntax baseline linter (chi dung khi debug linter bao sai)')
```

- [ ] **Step 2: Gọi linter TRƯỚC `compile_tkv_cli`, in HẾT finding rồi
      thoát nếu có lỗi**

Sửa `tkv.py`'s `main()`, trong nhánh `if args.cmd == 'build':`, NGAY SAU
đoạn kiểm tra `src.exists()` (trước dòng `out_exe = ...`):

```python
        if not args.no_lint:
            from compiler.syntax_baseline import check_syntax_baseline
            source_text = src.read_text(encoding='utf-8')
            findings = check_syntax_baseline(source_text)
            if findings:
                print(f"[tkv] Syntax baseline linter: tim thay {len(findings)} loi cu phap khong ho tro:", file=sys.stderr)
                for f in findings:
                    msg = f"  dong {f.line}: {f.construct_name}"
                    if f.suggestion:
                        msg += f" - goi y: {f.suggestion}"
                    print(msg, file=sys.stderr)
                print("[tkv] Sua cac loi tren truoc khi build, hoac dung --no-lint de bo qua (khong khuyen nghi).", file=sys.stderr)
                sys.exit(1)
```

- [ ] **Step 3: Kiểm thử thủ công (không có test tự động cho `tkv.py`
      trước đây trong dự án — làm 2 spike thủ công, không lưu vào test
      suite chính thức, chỉ xác nhận CLI hoạt động đúng)**

Tạo 1 file tạm `scratch_bad_syntax.tkv` với 1 list comprehension:
```
cd "D:/Claude AI Project/TokenVector"
python -c "
from pathlib import Path
Path('scratch_bad_syntax.tkv').write_text('''
def run() -> None:
    xs = [x for x in range(10)]
''', encoding='utf-8')
"
python tkv.py build scratch_bad_syntax.tkv --entry run
```
Expected: in ra finding "dong 3: list comprehension", exit code 1, KHÔNG
sinh file `.exe`.

```
python tkv.py build scratch_bad_syntax.tkv --entry run --no-lint
```
Expected: linter bị bỏ qua, build đi thẳng vào `compile_tkv_cli` (sẽ fail
ở ĐÓ với lỗi KHÁC vì list comprehension thật sự không compile được — xác
nhận lỗi phát ra từ pipeline compile, không phải linter).

Xoá `scratch_bad_syntax.tkv`/`scratch_bad_syntax.exe` (nếu có) sau khi xác
nhận xong — không commit file rác này.

- [ ] **Step 4: Build lại 1 file hợp lệ có sẵn để xác nhận linter KHÔNG
      chặn nhầm luồng build bình thường**

```
python tkv.py build test/sample_extern_method.tkv --entry main --out scratch_valid_test.exe
```
Expected: build PASS bình thường như trước khi có linter (không in gì về
syntax baseline, không exit 1). Xoá `scratch_valid_test.exe` sau khi xác
nhận.

- [ ] **Step 5: Commit**

```bash
git add tkv.py
git commit -m "feat(compiler): tich hop syntax baseline linter vao tkv.py build (Task 3/4, syntax-baseline-linter)"
```

---

### Task 4: Regression toàn bộ test suite + docs + commit cuối

**Files:**
- Modify: `docs/PYTHON_GAP_CHECKLIST.md`

**Interfaces:**
- Consumes: toàn bộ Task 1-3.

- [ ] **Step 1: Chạy `tkv.py build` (KHÔNG `--no-lint`) cho TOÀN BỘ file
      `.tkv` hiện có build+chạy PASS trước đây** — quét
      `Testkit/*.tkv` (qua `release/3.code/Testkit/` nếu đó là nơi chứa
      thật, xác nhận đường dẫn đúng lúc thực hiện) VÀ mọi file `test/*.tkv`/
      `test/sample_*.tkv` ở root `TokenVector/`. Viết 1 script nhỏ lặp qua
      từng file gọi `check_syntax_baseline` trực tiếp (nhanh hơn build đầy
      đủ từng file qua `ilasm.exe`) — MỤC TIÊU: xác nhận linter trả về 0
      finding cho MỌI file trong bộ test hiện có. Đây là bài test QUAN
      TRỌNG NHẤT — chứng minh whitelist đủ đầy đủ, không có false-positive
      nào trên test suite thật.

Nếu phát hiện false-positive (file hợp lệ nhưng linter báo lỗi): QUAY LẠI
`compiler/syntax_baseline.py`, bổ sung/sửa `visit_XXX` thiếu, KHÔNG bỏ qua
hay tắt test.

- [ ] **Step 2: Nếu Task 1's báo cáo xác nhận cần mirror `.tkv` tự-host
      (`release/3.code/`) — thực hiện đồng bộ.** Nếu Task 1 xác nhận
      KHÔNG cần (vd `tkv.py`/linter chỉ tồn tại ở cây `.py`, cây `.tkv`
      không có entrypoint CLI tương đương) — ghi rõ lý do trong commit
      message, không mirror.

- [ ] **Step 3: Cập nhật `docs/PYTHON_GAP_CHECKLIST.md`'s mục "#4 Tương
      thích cú pháp"** — đánh dấu ĐÃ XONG, mô tả ngắn: pre-flight linter
      `compiler/syntax_baseline.py` + tích hợp `tkv.py build` (mặc định
      bật, `--no-lint` để tắt), whitelist suy ra từ compiler thật (dẫn tới
      báo cáo Task 1 nếu còn giữ lại, hoặc tóm tắt trực tiếp trong
      checklist), liệt kê rõ PHẠM VI: chỉ kiểm tra cú pháp AST-shape,
      không kiểm tra dtype/logic nghiệp vụ.

- [ ] **Step 4: Commit**

```bash
git add docs/PYTHON_GAP_CHECKLIST.md
git commit -m "docs: #4 tuong thich cu phap DA XONG - syntax baseline linter (Task 4/4)"
```

**KHÔNG rebuild `release/3.code/dist/tkvc.exe`.**
