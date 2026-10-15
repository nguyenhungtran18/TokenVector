# TokenVector — lộ trình tới ngang bằng Python hoàn toàn

> **QUY ƯỚC TỪ 2026-08-08:** file này là bảng điều phối chính cho mọi AI/agent
> cùng làm TokenVector. Hễ bắt đầu/sửa/xác minh xong một việc thuộc lộ trình,
> phải cập nhật lại mục trạng thái gần đầu file này trước khi bàn giao: đã làm
> gì, còn lại gì, test/arbiter nào đã chạy, mục `ledger.toml` nào đổi trạng thái,
> và có file dirty nào không thuộc việc của mình cần tránh đụng vào. Không chỉ
> ghi trong chat.

## TRẠNG THÁI LÀM TIẾP (xác minh 2026-08-08)

- Nhánh hiện tại: `feature/universal-ai-context-compressor`.
- `test/parity/ledger.toml` còn **11 mục `open`**.
- CodeGraph cho **TokenVector** đã được sinh lại trước khi sửa code:
  - Dữ liệu graph: `C:\Claude AI Project\TokenVector\graph\`
  - HTML xem tổng quan: `C:\Claude AI Project\TokenVector\GraphView\graph_visualization.html`
  - Số liệu pipeline: 252 file Python, 1.076 import edges, 1.517 call edges;
    reviewer đọc 1.881 cạnh hợp lệ, 0 issue, 1 warning (`11 file` mồ côi).
  - Lưu ý: launcher release mặc định trỏ `--path .` vào chính thư mục
    `CodeGraph2.0_Release`, không phải TokenVector. Hai file
    `CodeGraph_TKV\codegraph_v2.exe`/`CodeGraph_MCP.exe` ngoài release không
    phải PE executable thật mà là token dump, nên không dùng chúng để chạy.
- Worktree có thay đổi sẵn trong `tkv_compile.py` liên quan cJSON/Gemini
  (`stdlib_cjson`, `CJSON_PINVOKE_DECL_LINES`). Đây là thay đổi có trước phiên
  này; AI khác **không được revert/đụng vào** nếu việc đang làm không liên quan.
- Thứ tự khuyến nghị hiện tại:
  1. Sửa `.isdigit()` (`P036`, `P041`) — nhỏ, độc lập, giảm 2 mục open.
  2. Sửa `not in set` (`P021`) — nhỏ, độc lập.
  3. Sửa/siết `test/parity/reducer.py` để repro không bị rút gọn sai nguyên
     nhân; sau đó rà lại `P014`, `P018`, `P038`, `P044`.
  4. Hoãn `P012`, `P023`, `P054` tới mốc 10 (`/` → float và số học int liên
     quan), không vá lẻ.
  5. Hoãn `P057` tới mốc 11 (slice/index).
- Trước khi sửa mỗi mục: chạy hoặc đọc `test/parity/arbiter.py`/ledger để xác
  nhận lỗi thật hiện tại. Sau khi sửa: chạy arbiter đúng repro, cập nhật
  `ledger.toml` nếu lỗi đã fixed, rồi ghi lại kết quả vào mục này.

> **✅ MERGE XONG 2026-08-06** (`2445470`): worktree `thuc-hien-theo-plan-
> 2144a1` (32 commit, mốc 6/7/8) đã gộp vào `feature/universal-ai-context-
> compressor`. 3 conflict giải quyết tay + 2 bug MỚI phát sinh từ merge tự
> tìm và sửa (macro dict-iteration của worktree cướp vòng lặp list; thứ tự
> nhánh sai trong bản resolve-conflict). `python test/run_tests.py` →
> **132/132 PASS**. Ledger P015 đã đổi `status='fixed'` (trùng bug B2 sửa
> cùng ngày). CodeGraph đã `regen.sh` lại: 767 file, 9.410 cạnh, 0 issue.
> Worktree cũ (`.claude/worktrees/thuc-hien-theo-plan-2144a1`) giờ đã lỗi
> thời (nội dung đã nằm hết trong nhánh chính) — có thể xoá an toàn bằng
> `git worktree remove`, nhưng CHƯA xoá, chờ xác nhận. Mốc 9-15 dưới đây
> vẫn CHƯA bắt đầu — đây là việc kế tiếp thật sự của lộ trình.

## TIẾN ĐỘ (cập nhật 2026-08-04)

**`python test/run_tests.py --exclude native,repo` → 120 PASS / 0 FAIL / 4 SKIP,
mã thoát 0.** (kết phiên 2026-08-05, 11 commit)

| Mốc | Trạng thái |
|---|---|
| 1. Trình chạy test + CI | ✅ `1d8c8ac` — nghiệm thu bằng tiêm lỗi (0→1→0) |
| 2. Segfault `dict[str,i32]` | ✅ `1739232` — đối chứng đột biến 2/3 |
| 3. Shim → thư viện chuẩn | ✅ **gần như không cần** — 4 shim ĐÃ là uỷ nhiệm thật |
| 4. `_tkv_arbiter.py` | ✅ `3913df6` — đối chứng đột biến cả 2 phép so |
| 5. Chuyển 15 test | ✅ `d81c7ee`+`a019e42` — **15/15** |
| 6. Độ rộng số nguyên | ✅ **XONG** — `bddcc57` `73a7fa5` `856ed94` `3225ad1` `050d244`; `int` là **mặc định toàn cục** |
| — Hiệu năng O(n²) chuỗi | ✅ `9f6ee8c` — 18.025ms → 123ms, nay **nhanh hơn CPython 24×** |
| — `**` số nguyên sai âm thầm | ✅ `1023eb4` — lỗi THẬT tìm được, không có trong danh sách nào |
| 7. `print` + một đường `str()`/float | ✅ `ef30667` — `TkvStr`; 4 lệch thật với Python, 2 lệch đã biết ghim hai chiều |
| 8. Bộ dò lệch (sinh+rút gọn+sổ) | ✅ **nghiệm thu vượt mức** — 97 mục `open` trong `test/parity/ledger.toml` (đích chỉ cần ≥10) |
| 9-15 | ⬜ chưa bắt đầu |

### ĐÃ LÀM PHIÊN 2026-08-05 (nối tiếp lát 1)

`73a7fa5` — **`//` `%` `**` `-x` trên `int`**. Ngữ nghĩa floor của Python
trên **cả hai** đường (int64 và BigInteger): CIL `div`/`rem` *và*
`BigInteger.Divide/Remainder` đều cắt về 0, chỉ trùng Python khi hai toán
hạng cùng dấu → lệch âm thầm. `MIN_VALUE / -1`, `MIN_VALUE rem -1`,
`-MIN_VALUE` đều bị lái xuống BigInteger. `/` trên `int` **báo lỗi rõ ràng**
(Python trả float — mốc 10). Ba phép này đi **helper**, không nội tuyến: chúng
hiếm hơn hẳn `+ - *` và thân dài gấp mấy lần. `bigint_divmod_test.py` 23 ca,
đột biến 5/5.

`1023eb4` — **lỗi THẬT, chưa từng có trong danh sách nào**: `a ** b` với
`a,b` nguyên đi `System.Math::Pow`, tức float64, tức **xấp xỉ**:
`3**35` → …704 thay vì …707; `3**38` lệch 89; `7**20` lệch 1. **Luỹ thừa
của 2 luôn khớp** — đó là lý do nó sống sót: phản xạ đầu tiên của ai cũng là
thử `2**n`. Nay đi `TkvIPow::Pow` (bình phương liên tiếp, `mul.ovf`,
`conv.ovf.i4`). Số mũ âm nay ném thay vì trả 0 lặng lẽ. `ipow_test.py` 15 ca
+ 3 ca phải ném, đột biến 4/4.

`856ed94` — **`int` làm phần tử `list`/`dict`**. Bất ngờ: bảng kiểu **không**
phải chỗ thiếu (`IL_SCALAR` đã kéo theo `List`/`Dictionary` từ lát 1). Chỗ
thiếu là **chỉ số**: trong hàm trả `int`, *mọi* biến không chú thích là `int`,
kể cả biến đếm → `xs[j]` báo lỗi. Nay chỉ số đi `TkvInt::ToI32`, thu hẹp **có
kiểm tra**. Ba dòng đăng ký `IL_LDELEM`/`IL_STELEM`/`IL_NEWARR_ELEM` viết lúc
đầu **đã bị gỡ**: đột biến chứng minh chúng không hề được chạm tới (mảng thô
chỉ tạo được bằng `np.zeros(dtype=np.…)`, `int` không có dtype numpy).
`bigint_container_test.py` 9 ca (tới 10³²) + 3 ca phải ném, đột biến 4/4.

> Bài học của phiên, đáng nhớ hơn cả ba commit: **vòng đột biến đầu tiên của
> mục 2 lọt 4/4**, và cả bốn đều lọt vì cùng một lý do — bộ ca chưa chạm tới
> đường mã đang sửa. Test xanh ngay lần đầu là **tín hiệu nghi ngờ**, không
> phải tín hiệu xong việc.

### ĐÃ LÀM PHIÊN 2026-08-05 (lát 3)

`3225ad1` — **`int()`/`abs()`/`min`/`max`/`sum` trên `int`**, và một **lớp
bug thật chưa có trong bất kỳ danh sách nào**: điều kiện của `if`/`while`
được biên dịch với `body_dtype`. Trong hàm trả `int`, mọi điều kiện có giá
trị THẬT là `i32` (`any(xs)`, `k in d`, một hàm trả `i32`) bị
`_widen_if_needed` nâng lên `TkvInt`, rồi `brfalse` nhìn một **struct** như
một địa chỉ → `AccessViolationException` lúc chạy, **không phải** lỗi biên
dịch. Điều kiện so sánh (`i <= n`) sống sót chỉ vì chúng tự sinh `i32` và
không đi qua đường widen — đó là lý do lớp bug này ẩn sau vẻ ngoài "if/while
chạy tốt với int". Nay đi `_compile_cond`.

Ba kiểu hỏng của năm builtin, đáng ghi vì **khác nhau về mức nguy hiểm**:
`sum`/`min`/`max` báo lỗi rõ ràng (bế tắc nhưng ồn ào); `abs()` sinh lời gọi
`System.Math::Abs(TkvInt)` — overload **không tồn tại**, ilasm vẫn ra `.exe`;
`int()` **âm thầm** — đi `Int32.Parse` rồi để widen nâng lên, tức
`int("99999999999999999999")` ném trong khi Python trả đúng số.

`bigint_builtins_test.py` 23 ca, đối chiếu ba phía. **Đột biến 8/8 — nhưng
vòng đầu chỉ 7/8**: ca lọt lưới là phép kiểm tràn của đường nhanh
`TkvInt::Add`, vì mọi ca `sum()` lúc đó đều có phần tử **đã là BigInteger
sẵn** nên đường nhanh không hề được chạy. Đúng bài học của lát 2, lặp lại
lần thứ hai trong cùng một mốc.

### ĐÃ LÀM PHIÊN 2026-08-05 (lát 4 — MỐC 6 XONG)

`050d244` — **chủ dự án chốt: đổi toàn cục sang `int`.** Một dòng đổi
(`_infer_literal_dtype` trả `'int'` thay `'i32'`), rồi bảy lớp bug thật.
Bộ test: 125 PASS → **63 PASS / 62 FAIL** → về lại **125 PASS / 0 FAIL**
sau sáu lần chạy toàn bộ, mỗi lần là một lớp nguyên nhân riêng.

Kết quả đáng giá: `fact(30)`, `2**100`, `2147483647+1` nay **trả về đúng
như Python** ngay trong hàm khai báo `-> "i32"`/`-> "str"`.

Bảy lớp bug (không lớp nào có trong bất kỳ danh sách nào):

1. Thu hẹp `int` → `i32/i64/f64` **báo lỗi biên dịch** — đúng khi `int`
   còn là ngoại lệ, sai khi nó là mặc định: nó chặn cả những chỗ độ rộng
   cố định là **bắt buộc về cấu trúc** (chỉ số, biến đếm, API .NET).
   43/129 test trượt vì đúng một lỗi này. Nay thu hẹp **có kiểm tra**.
2. Nhánh `int` của `compile_binop` **trả về ngay**, bỏ qua kiểu ngữ cảnh
   → `ret` một struct ở chỗ khai báo `int32`, in ra `0`. **Âm thầm.**
3. Ngược lại: ngữ cảnh đòi `int`, hai toán hạng `i32` → cả hai bị nâng
   thành `TkvInt` rồi sinh `mul.ovf` **trên hai struct** → BadImageFormat.
4. `_infer_dtype` không có nhánh cho `compare`/`boolop`/`not`/`in` → rơi
   về quét hằng số, bắt được số `0` trong `ok = idx < 0 or …` → khai báo
   `ok` là `TkvInt` trong khi giá trị thật là `int32` 0/1 → **AccessViolation**.
5. **Chú thích tường minh phải thắng phỏng đoán từ hằng số** — container
   không có đường ép kiểu ngầm. `_container_arg_hints` mới.
6. `ensure_class` theo yêu cầu không còn đủ → `.class TkvInt` và 4 local
   nháp nay cấp phát **vô điều kiện**.
7. `int` chưa đi được vào: cell của closure, `json_dumps`, `list.count`,
   và `sorted()` (`TkvInt` phải cài `IComparable`).

**Giá đã đo:** bộ test toàn bộ 576s → 665s (**+15%**, chủ yếu là biên
dịch); giá lúc **chạy** của số học `int` là **2,4×** so với `int64` thuần
(spike 2), vẫn nhanh hơn CPython 37,7×.

### ĐÃ LÀM PHIÊN 2026-08-05 (mốc 7)

`ef30667` — **`print()` + `.class TkvStr`**. `print` trước bản vá này
**không tồn tại**: một file `.tkv` chạy được bằng CPython nhưng không biên
dịch được nếu nó in bất cứ thứ gì — tức bất biến cốt lõi không kiểm chứng
được trên chính cách quan sát phổ biến nhất.

Đường cũ gọi `ToString()` — **instance method** trên value type nên CIL đòi
địa chỉ → `str(a + b)` phải đổ qua một local ẩn. `TkvStr::*` là **static,
nhận giá trị**, nên hạn chế đó biến mất cùng cả cơ chế đi kèm.

Bốn lệch thật với Python, đều âm thầm: (1) `ToString("R")` của .NET
Framework **không** cho chuỗi ngắn nhất (`123456789012345.6` → `...59`) →
nay đi thang `G15→G16→G17`; (2) ngưỡng ký hiệu khoa học `10^15` (.NET) vs
`10^16` (Python) — riêng số mũ 15 phải dựng lại dạng thường, và **không**
dùng `ToString("F1")` dù trông có vẻ đúng (F1 chỉ giữ 15 chữ số có nghĩa);
(3) `E` hoa vs `e` thường, `Infinity`/`NaN`; (4) `-0.0` — phải xét **bit
dấu**, `==` không phân biệt được. Cùng dịp: `float()` nay nhận
`"inf"/"-inf"/"nan"` như Python.

**Hai lệch đã biết, ghim hai chiều:** `Double.Parse("-0.0")` của .NET
Framework trả về không âm (lệch của đường **vào**); và khi chuỗi ngắn nhất
có 17 chữ số mà có hai bản cùng đọc lại đúng, `G17` làm tròn ra xa 0 còn
Python chọn bản gần nhất (`2000000000000000.25`). Cùng họ với subnormal
`repr(5e-324)`. Sửa thật cần port Grisu/Ryu — **mốc 15**.

`print_float_test.py`: 24 giá trị × 2 đường + 4 ca `print`, corpus sinh
bằng cách CHẠY CPython. Đột biến **7/7**.

### ĐÃ LÀM PHIÊN 2026-08-05 (mốc 8 — BỘ DÒ LỆCH)

`test/parity/{generator,arbiter,reducer,ledger,fuzz}.py` +
`test/verify/{grammar_coverage,ledger}_test.py` (chưa commit — làm ở
worktree `thuc-hien-theo-plan-2144a1`, đọc lại đúng worktree này trước
khi tiếp). Kiến trúc đúng như 1.1/1.2/1.3 của kế hoạch:

- **Sinh (1.1):** `generator.py` đọc thẳng `il_dispatch` cho builtin/
  method thư viện (`grammar_coverage_test.py` khoá: đăng ký thêm là bắt
  buộc phải xuất hiện trong generator hoặc `UNGENERATABLE` kèm lý do).
  Văn phạm cơ bản (if/for/while/container/subscript/slice) viết tay,
  CỐ Ý đa dạng hoá đúng những chỗ B1-B6 sống (biến vs biểu thức làm
  iterable, một vs nhiều đối số trong subscript, tập vs dict cho
  `not in`...) — không hardcode ca cụ thể, để fuzz.py tìm ra bằng cách
  CHẠY.
- **Rút gọn (1.2):** `reducer.py` delta-debug 1-minimal theo "chunk"
  (câu lệnh top-level, giữ nguyên `except`/`elif` dính với khối trước).
- **Sổ (1.3):** `ledger.py` + `test/parity/ledger.toml` (đọc bằng
  `tomllib` có sẵn, ghi bằng serializer tay — không thêm dependency).
  Ghim hai chiều qua `ledger_test.py`: mỗi mục `open` chạy lại phải VẪN
  lệch ĐÚNG loại đã ghi.

**Nghiệm thu vượt xa mức tối thiểu:** 300 chương trình sinh ra (seed
1-300) → **137 lần lệch → 97 mục MỚI, riêng biệt** sau khi khử trùng.
Đích của mốc 8 chỉ cần "tự tìm lại ≥10 lệch đã biết mà không được
mách" — đạt gấp gần 10 lần. Rà theo lớp:

| Lớp | Số mục | Khớp BUGS_TODO |
|---|---|---|
| Dấu phẩy TRONG CHUỖI làm gãy tokenizer khi chuỗi đó làm khoá subscript | 28 | họ hàng B3 (bộ tách chỉ số không biết ranh giới chuỗi) |
| Lệch giá trị khác (method trên kết quả gọi hàm, `.replace("", x)`...) | 17 | mới, gần họ B4 |
| `for x in <biểu thức>.split(...)::` không dịch được | 11 | **B5 - khớp thẳng** |
| `for k in dict:` biên dịch được, `KeyNotFoundException` lúc chạy | 9 | **B1 - khớp thẳng** |
| `round(x, n)` — chỉ nhận đúng 1 tham số | 7 | mới (liên quan mốc 14's `round()`) |
| Runtime crash khác (list/dict biên) | 7 | — |
| `str(bool_expr)` → `"1"/"0"` thay vì `"True"/"False"` | 6 | **mới, đáng chú ý** — Python không có kiểu bool riêng trong TokenVector |
| `.rfind()`/method thư viện chỉ được làm RHS TRỰC TIẾP 1 phép gán, không lồng trong biểu thức khác | 3 | **B6 - khớp thẳng**, cộng thêm hé lộ ràng buộc cấu trúc rộng hơn ("chỉ nhận BIẾN thuần" — đúng như Giai đoạn 2.1 đã dự đoán) |
| `/` giữa hai `int` (không phải i32) chưa hỗ trợ | 2 | mới — thu hẹp phạm vi mốc 10 |
| `KeyError: 'infer_literal_dtype'` — COMPILER TỰ SẬP, không phải lỗi biên dịch có kiểm soát | 1 | mới, cần ưu tiên (crash nội bộ nặng hơn SyntaxError có kiểm soát) |

Bài học của mốc này: viết generator 2 lần bị chính mình gài bẫy —
(1) `x: "i32" = giá_trị` KHÔNG phải cú pháp cục bộ thật của TokenVector
(grep cả repo không ai dùng, chỉ tham số hàm mới có annotation); phải
đổi sang gán trần và dựa luật suy kiểu mặc định (`int` toàn cục từ mốc
6) — bài học ["Chú thích tường minh thắng phỏng đoán từ hằng số"](feedback-explicit-annotation-beats-literal-guess.md) áp dụng NGƯỢC ở đây: sinh mã cho compiler thì phải
DÙNG ĐÚNG quy ước suy luận của nó, không phải áp annotation tưởng tượng.
(2) Biến khai báo TRONG một nhánh `if`/`while` bị generator để "rò rỉ"
ra ngoài phạm vi khi nhánh đó cuối cùng không được emit (mẫu `try body
rồi return None` mà vẫn đã `env.declare()` trước đó) — `UnboundLocalError`
phía CPython. Sửa bằng chụp/khôi phục `env.vars` quanh mọi khối lồng.
Không có mục nào trong 97 mục bị nhiễm bởi 2 lỗi này (đã kiểm — cả hai
đều bị bắt bởi vòng CPython-sanity-check TRƯỚC khi vào ledger).

**Việc kế tiếp của phiên sau:** commit `test/parity/*` + 2 test mới
(chưa commit ở cuối phiên này — kiểm tra `git status` trước). Rà 97 mục
theo độ nguy hiểm (âm thầm trước, ồn ào sau — mục `value_mismatch`/
`bool-str-formatting` đứng trước `compile_gap`), bắt đầu sửa từ đó thay
vì theo Giai đoạn 3 cũ (danh sách đó nay đã có BẰNG CHỨNG THẬT thay vì
suy đoán). Mốc 9 (`ast.IfExp` — ternary) vẫn đứng nguyên như kế hoạch.
Lưu ý cho mốc 10 (`/` → float): nay `/` giữa hai `int`
**báo lỗi rõ ràng**, không còn chia nguyên âm thầm — bán kính của mốc 10
đã hẹp lại đáng kể.

### ĐÃ LÀM PHIÊN 2026-08-05 (tiếp — sửa lệch, giao việc AgnesCode)

Bắt đầu sửa 97 mục sổ lệch, **thử nghiệm giao việc cho AgnesCode**
(agent AI khác, `C:\Program Files\AgnesCode`) với Claude làm vai trò
kiểm soát/xác minh độc lập trước khi commit (không bao giờ tin báo cáo
tự khai của agent khác — chạy lại `test/parity/arbiter.py`/`git diff`
mỗi lần). Kết quả: **97 → 33 mục open** (`0cefce3`→`ca98a32`, 4 commit
sửa lệch).

**Đã sửa (đều xác minh độc lập, không regression):**
| Commit | Nội dung | Ai làm | Kết quả |
|---|---|---|---|
| `0cefce3` | B1: `for k in d:` sinh macro riêng (register TRƯỚC `for_in_list`) | AgnesCode (auto) | 16 mục |
| `1675e14` | Họ B3: `_split_expr_list()` tôn trọng ranh giới chuỗi, thay `.split(',')` | AgnesCode (auto) | 26 mục |
| `f03c40d` | B4: `_infer_dtype`'s `method_call_expr` hardcode `'str'`, quên cập nhật khi mở rộng ho tro method khác `.join()` | **Claude tự làm** (2 lần AgnesCode thất bại) | 9 mục |
| `ca98a32` | `round(x,n)`: tách khỏi `_MATH_FUNCS` chung, cùng lớp lỗi suy dtype với B4 | **Claude tự làm** (2 lần AgnesCode thất bại) | 13 mục |

**Bài học về AgnesCode (đáng nhớ hơn cả 4 lần sửa):**
1. **Giới hạn tool-call là THEO TURN, không theo session** — reset mỗi
   tin nhắn mới, không cần mở chat mới khi bị chặn.
2. **Model "auto" có thể tụt xuống "agnes-2.5-flash" và hỏng nặng** —
   dấu hiệu: lặp đọc CÙNG 1 file liên tục không tiến triển, hoặc trả
   lời **lạc đề hoàn toàn** (từng thấy nó bàn về "matmul/C# codegen"
   không tồn tại trong project). Đổi tay sang **agnes-2.5-pro** đỡ hơn
   NHIỀU (suy luận IL chi tiết, tự phát hiện + sửa lỗi cú pháp của
   chính nó) nhưng **vẫn tái phát cùng 1 kiểu lạc đề** sau ~1 giờ làm 1
   task khó (round()) — không phải chỉ do RAM/model tier, có vẻ là
   **giới hạn thật của agent này với các thay đổi sâu vào compiler
   internals** (suy luận qua nhiều lớp file, ngược với các sửa
   "khoanh vùng rõ, 1 điểm chèn" như B1/B3 mà nó làm rất tốt).
3. **Agent khác có thể "tự tin" viết sai nghiêm trọng** — 1 lần đoán mò
   chỉ số local variable (`len(scope._d)-1`) thay vì dùng cơ chế cấp
   phát thật của compiler; 1 lần import các class C# hoàn toàn không
   tồn tại (`ILBuilder`, `ILType`,...); 1 lần để lại lời gọi hàm
   (`_compile_round_builtin`) mà KHÔNG hề định nghĩa — cả ba đều sẽ làm
   **mọi lần biên dịch sau đó hỏng** nếu không bị chặn lại. Luôn
   `git diff` xem XÉT NỘI DUNG THẬT trước khi tin, không chỉ xem
   "compiled ok"/"test pass" tự báo.
4. **Việc PHÙ HỢP để giao**: lỗi có vị trí rõ ràng, 1 điểm chèn, không
   cần lần theo nhiều lớp gọi hàm (B1: 1 macro mới; B3: 1 hàm tokenizer
   mới thay 1 điểm gọi). **Việc KHÔNG phù hợp** (ít nhất với model hiện
   tại): lỗi cần lần theo suy luận kiểu (`_infer_dtype`) qua NHIỀU
   nhánh tag khác nhau để tìm đúng chỗ hai đường code "lẽ ra phải khớp
   nhau" bị lệch — cả B4 lẫn round() đều thuộc lớp này, và Claude tự
   chẩn đoán bằng cách **đọc IL sinh ra thật + monkeypatch trace trực
   tiếp** (không đoán mô hình) nhanh hơn hẳn so với đợi agent kia dò
   dẫm.
5. **Trước khi sửa, ĐO THẬT chứ đừng giả định** — brief ban đầu cho
   round() giả định cần `MidpointRounding.ToEven` tường minh (dựa theo
   trực giác, KHÔNG kiểm chứng), tốn công vô ích cho AgnesCode đi tìm
   `ldsfld` đúng cú pháp cho 1 thứ **hoá ra không cần** — .NET
   `Math.Round` mặc định ĐÃ là banker's rounding, đo bằng
   `test/parity/arbiter.py` trên 7 ca midpoint xác nhận khớp Python
   100% trước khi viết dòng code nào.

**Phát hiện thêm (chưa sửa, ghi lại cho phiên sau):**
- Bug trong CHÍNH `test/parity/reducer.py`: rút gọn quá tay có thể xoá
  nhầm dòng khai báo biến, khiến repro lưu lại lỗi vì LÝ DO KHÁC (biến
  chưa khai báo) thay vì lỗi thật đang ghi. Ảnh hưởng 7 mục round() -
  đã sửa tay repro, nhưng **reducer cần thêm điều kiện khớp not-just-
  kind mà còn khớp NỘI DUNG lỗi** trước khi chấp nhận một lần rút gọn.
- `test/verify/tkvcalc_test.py`/`tkvcalc_ast_test.py` **ĐỎ SẴN TỪ
  TRƯỚC** (xác nhận bằng `git stash` đối chiếu, không liên quan các sửa
  phiên này): `'.keys(...)' chỉ dùng được trên biến kiểu record,
  string... - 'toks' có shape='list' dtype='Tok'` — không phải lỗi bộ
  dò tìm ra (record+list nằm ngoài phạm vi generator hiện tại), thuộc
  diện phải rà riêng phiên sau.

**Việc kế tiếp (ĐÃ LÀM — cùng phiên, tiếp tục 2026-08-05, thêm Gemini
web vào quy trình):** 33 → **12 mục open** (6 commit mới: `0e42ba2`
`ecc96de` `313272f` `dcb1b38` `4271e4a`, xem bảng dưới). Quy trình mới
hình thành phiên này: **Claude tự chẩn đoán gốc rễ trước** (đọc code,
đo thật) → **hỏi Gemini web** (qua Claude in Chrome, KHÔNG dùng
computer-use vì trình duyệt chỉ được cấp quyền "read" — không click/
gõ được) xin 2-3 hướng thiết kế có đánh đổi → Claude tự chọn hướng khớp
ràng buộc thật + tự viết + **luôn tự kiểm chứng bằng `test/parity/
arbiter.py` trước khi tin** (2 lần bản thân Claude tự sửa theo đúng
lời khuyên của Gemini mà VẪN có lỗi: fix P094 "an toàn" ban đầu biến
compile-time error thành runtime crash tệ hơn; `TkvStr::RFind` viết sai
kiểu trả về `string` thay `int32` lúc gõ theo mẫu — cả hai đều bắt được
nhờ tự test lại, không nhờ Gemini phát hiện).

| Commit | Nội dung | Gemini góp gì | Mục ledger |
|---|---|---|---|
| `0e42ba2` | `str(bool)`/`print(bool)` in "True"/"False" thay "1"/"0" | 3 hướng thiết kế, chọn hướng 3 (special-case tại điểm gọi) | 6 |
| `ecc96de` | `str(list_slice)` hết crash nội bộ (`KeyError`), lộ thêm 1 lớp sâu hơn (`_infer_literal_dtype` quét nhầm vào node `slice`) | đồng ý hướng an toàn, nhưng KHÔNG lường được lớp lỗi runtime-crash mới — Claude tự đào tiếp | 1 |
| `313272f` | `.replace(old, new)` khớp Python khi `old=""` (khác `.NET` ném `ArgumentException`) | thuật toán CIL cụ thể (`StringBuilder`, rẽ nhánh `TkvStr::Replace`) — đúng, dùng thẳng | 1 |
| `dcb1b38` | **B5**: `for x in <biểu thức>:` dịch được (trước chỉ nhận tên biến trần) | regex `negative lookahead` loại trừ đúng `range(...)`/`generator(...)` — đúng, dùng thẳng; Claude tự thêm phần giữ nguyên đường cũ cho biến trần | 11 |
| `4271e4a` | **B6**: thêm `.rfind()` + sửa lệch `.NET LastIndexOf("")` vs Python `rfind("")` | không hỏi (đối xứng rõ với `.find()` đã có) — tự làm, tự đo ra lệch thật lúc kiểm chứng | 2 |

**Bài học Gemini web (bổ sung bài học AgnesCode ở trên):** hữu ích nhất
khi hỏi **thiết kế/thuật toán có ràng buộc rõ** (đưa đủ context: quy
ước IL hiện có, class `TkvStr` mẫu, lý do lịch sử của quyết định cũ) —
trả lời chất lượng cao, đôi khi đề xuất kiến trúc dư thừa so với ràng
buộc thật của dự án (vd lần đầu đề xuất boxing/`List<object>`/`isinst`
runtime cho "list lồng list" trong khi TokenVector là ngôn ngữ **tĩnh
kiểu**, list luôn `List<T>` đồng nhất — Claude phải tự đối chiếu kiến
trúc thật rồi sửa lại đề xuất). Không thay thế bước tự viết + tự kiểm
chứng — 2/5 lần bản thân Claude viết sai dù đã hỏi đúng, chỉ bắt được
nhờ chạy `arbiter.probe` chứ không nhờ Gemini.

**Việc kế tiếp phiên sau:** rà tiếp 12 mục open còn lại trong
`test/parity/ledger.toml` — `'not in' set` (B2, 2 mục, tiếp theo dự
định), tokenize lạ P036/P057 (2 mục), `.isdigit()` sai kiểu (1 mục).
KHÔNG sửa lẻ 3 mục `/`/`**` trên `int` (bị chặn bởi mốc 10, sửa lẻ chỉ
vá triệu chứng). 4 mục "biến chưa khai báo" (P014/P018/P038/P044) là
tàn tích bug trong CHÍNH `test/parity/reducer.py` (xem mục "Phát hiện
thêm" phía trên) — cần sửa gốc `reducer.py` trước khi tin lại repro của
chúng, không sửa tay từng cái nữa.

<details><summary>Hồ sơ: quyết định độ rộng số nguyên (đã chốt)</summary>

2. **Quyết định**: có đổi mặc định của hằng số nguyên từ `i32` sang `int`
   không? Hiện chỉ đổi *bên trong hàm khai báo* `-> "int"`. Đổi toàn cục là
   ngang bằng Python thật nhưng làm chậm mọi code `.tkv` đang có → cần đo
   trước, đừng quyết bằng cảm tính. **Dữ kiện mới ủng hộ việc đổi:** quy tắc
   "trong hàm trả `int` thì mọi biến là `int`" đã đẻ ra hai chỗ vướng thật
   (chỉ số, và truyền vào tham số `i32`) — tức mô hình *nửa vời* hiện tại tự
   nó cũng có giá. **Dữ kiện lát 3 bồi thêm:** lớp bug điều kiện `if`/`while`
   ở trên là hệ quả TRỰC TIẾP của mô hình nửa vời — trong một thế giới toàn
   `int` hoặc toàn `i32` nó không tồn tại. Mỗi lát lại lộ thêm một chỗ nối
   giữa hai thế giới bị hở, và các chỗ hở đó **âm thầm**, không ồn ào.
   Cái giá đã đo của `int`: **2,4× chậm hơn `int64` thuần** (spike 2: 59ms
   vs 25ms), vẫn nhanh hơn CPython 37,7×.

</details>

Quyết định thiết kế đã chốt bằng đo (spike 2, `ebdf4bc`): **struct `TkvInt`
một giá trị trên stack**, không phải hai local song song — chỉ đắt hơn 18%
và giữ nguyên giao ước "một giá trị trên stack" của cả codegen, tránh viết
lại ~100 điểm gọi. Đường nhanh `+ - *` vẫn **nội tuyến** đúng như spike 1 đòi
hỏi; `// % ** -x` thì không (xem trên).

**GIAI ĐOẠN 0 XONG.** Cả 15 công cụ đều biên dịch được, kể cả `typegraph.tkv`
939 dòng — file `.tkv` thật lớn nhất dự án, trước nay chưa từng gặp compiler.
Câu hỏi "64% mã thật chưa từng biên dịch thì có chạy không" đã có lời giải:
**có**. `ArbiterSession` xử lý công cụ nhiều bước (`graphstale`); `run_both`
rút gọn thành một bước của nó để chỉ có MỘT đường so sánh.

### Lỗi THẬT tìm được nhờ mốc 4-5 (đúng như đã liệu trước)

1. **`read_file` không chuẩn hoá xuống dòng** — Python `open(p,'r')` đổi `\r\n`
   và `\r` đơn lẻ thành `\n`; TokenVector ánh xạ thẳng `ReadAllText`, không đổi
   gì. Đo trên `a\r\nb\r\nc\r\n`: **CPython 6, TokenVector 9**. Windows sinh
   CRLF theo mặc định → mọi công cụ đếm dòng/đếm token/băm chuỗi đọc từ đĩa đều
   sai âm thầm. **KHÔNG có trong bất kỳ danh sách nào trước đây.** Đã sửa +
   `read_file_crlf_test.py`, đột biến bắt 3/5.
2. **`test_office_db.tkv` mã cứng đường dẫn tuyệt đối** vào checkout gốc → bộ
   test lâu nay ghi đè vào repo chính khi chạy từ worktree.
3. **Hạn chế cấu trúc:** entry CLI chỉ nhận tham số vô hướng
   (`tkv_compile.py:1055`) → hàm nhận `list`/`dict` **không thể** kiểm ở dạng đã
   biên dịch nếu không có hàm bọc. Ảnh hưởng các hàm trợ giúp của `impgraph`.

### Mốc 6 (độ rộng số nguyên) — ĐÃ XONG (phiên 2026-08-05)

Chốt: `int` (vô hạn chữ số, kiểu `TkvInt`) là **mặc định toàn cục** cho mọi
literal/biến số nguyên, không cần khai báo tường minh (commit `050d244`, sau
`73a7fa5`/`1023eb4`/`856ed94`/`3225ad1`). `fact(30)`, `2**100`,
`2147483647+1` nay khớp Python. Giá đo được: bộ test +15% thời gian biên
dịch, số học `int` chậm hơn `i64` thuần 2,4× nhưng vẫn nhanh hơn CPython
37,7×. Chi tiết đầy đủ + 3 lỗi ngầm nguy hiểm phát hiện khi lật cờ này:
xem memory `[[project-tokenvector-session-2026-08-05]]`.

### Mốc 7 (print + str()/float) — ĐÃ XONG (commit `ef30667`)

Một đường chuyển chuỗi duy nhất (`.class TkvStr`), 4 lệch thật đã sửa
(định dạng số thực ngắn nhất, ngưỡng khoa học, `inf`/`nan`, `-0.0`). Hai lệch
đã biết ghim hai chiều, cần Grisu/Ryu — hoãn sang mốc 15.

### Mốc 8 (bộ dò lệch tự động) — ĐÃ XONG (commit `0cefce3`)

`test/parity/{generator,arbiter,reducer,ledger,fuzz}.py`. 300 seed → 97 mục
lệch riêng biệt trong `test/parity/ledger.toml`. Rediscover B1/B3-họ/B5/B6 +
phát hiện mới (`str(bool)`, `round(x,n)`, 1 crash nội bộ compiler).

### Đang làm — sửa lệch tìm được (97 → 33 mục open, cùng phiên 2026-08-05)

4 commit sửa (`0cefce3` `1675e14` `f03c40d` `ca98a32`): B1 (16 mục) + họ
B3/dấu-phẩy-trong-chuỗi (26 mục) do AgnesCode sửa; B4-method-call-trên-kết-
quả-hàm (9 mục) + `round(x,n)` (13 mục) do Claude tự chẩn đoán (AgnesCode
thất bại 2 lần/việc). Bài học giao việc AgnesCode: `[[feedback-agnescode-delegation-lessons]]`.
**Việc tiếp: rà 33 mục open còn lại** trong `test/parity/ledger.toml`, ưu
tiên `value_mismatch` (âm thầm) trước `compile_gap` (ồn ào). Nợ kỹ thuật
chưa xử lý: bug trong chính `test/parity/reducer.py` (rút gọn có thể xoá
nhầm khai báo biến — đã vá tay 7 repro, chưa sửa gốc); `tkvcalc_test.py`/
`tkvcalc_ast_test.py` đỏ sẵn từ trước (record+list, ngoài phạm vi fuzzer
hiện tại), cần rà riêng.

---

## Context

Mục tiêu đứng sau dự án: **Claude tự tin dùng TokenVector viết code thật thay
Python** — không lỗi, không khoảng cách với Python. Chủ dự án đã chốt trong
phiên này:

1. **Đích: ngang bằng HOÀN TOÀN** (không phải "tập con được bảo chứng"). Khó
   thì dùng Groq/Qwen3 + đội AI Provider nghiên cứu.
2. **Tính năng thiếu thì PORT từ mã Python/CPython có sẵn, không sáng tác lại.**
3. `/` giữa hai số nguyên phải **trả float** như Python.
4. **Siết độ tin cậy bộ test TRƯỚC mọi tính năng.**

Bất biến cốt lõi của dự án: *một file `.tkv` chạy bằng CPython và chính nó biên
dịch ra `.exe` phải cho kết quả GIỐNG HỆT.* Mọi việc dưới đây phục vụ bất biến
đó.

### Đã làm xong trong phiên này (đã commit `bba8373`)

- **A1** `il_features/fstring.py` — regex `f"([^"]*)"` khớp nhầm chữ `f` cuối
  một chuỗi thường, viết lại `if w == "def" or w == "class":` thành điều kiện
  LUÔN sai. Là nguyên nhân thật của cả ba mục 9/11/12 trong PARITY_GAPS.
- **A2** `il_codegen.py` — `.maxstack` tính từ thân hàm thay hằng số 8.
- Phát hiện thêm: A2 chỉ vá `gen_il_function`, **generator đi đường khác** nên
  `MoveNext()` và wrapper vẫn hỏng. Đã sửa + test đối chứng đột biến (2/2).
- Bộ test: **115/120**. Năm mục trượt đã kiểm bằng `git stash` là **trượt y hệt
  trên bản chưa vá** — do môi trường (thiếu `sqlite3.dll`; worktree ít file hơn
  repo gốc), không phải regress.

### Phát hiện lớn nhất khi khảo sát (chưa sửa)

- **`/` giữa hai i32 sinh CIL `div` = chia NGUYÊN** (`il_features/operators.py:167`).
  `7/2` → TokenVector `3`, Python `3.5`. Sai âm thầm ở toán tử số học phổ biến
  nhất. Test lẽ ra bắt được (`manual_chat_math12_test.py:26-59`) thì lại **viết
  tay 5 hàm `_ref_*` dùng `//`** — test bị uốn theo lỗi thay vì tố cáo lỗi.
- **Bộ test chứng minh ít hơn nhiều so với số "xanh"**: 15 test không hề biên
  dịch gì (xoá sạch compiler chúng vẫn xanh); **4436/6911 dòng (64%) trong
  `tools/*.tkv` chưa bao giờ qua compiler**; không có trình chạy nào cho ra một
  kết quả đậu/rớt duy nhất.
- **Số nguyên Python là vô hạn chữ số, TokenVector chỉ có i32/i64.** Không nằm
  trong mọi danh sách lỗi hiện có. Với đích "ngang bằng hoàn toàn" đây là khoảng
  cách lớn nhất chưa ai ghi nhận.

---

## QUYẾT ĐỊNH ĐÃ CHỐT (2026-08-05) — ĐỘ RỘNG SỐ NGUYÊN

**Đã chọn hướng `BigInteger` có đường nhanh small-int**, dưới tên `TkvInt`,
làm **mặc định toàn cục** cho mọi số nguyên — không phải tuỳ chọn khai báo.
Thực hiện xong ở mốc 6 (commit `050d244`, sau `73a7fa5`/`1023eb4`/`856ed94`/
`3225ad1`); `fact(30)`, `2**100` nay khớp Python. Giá đo được: bộ test +15%
thời gian biên dịch, số học `int` chậm hơn `i64` thuần 2,4× (vẫn nhanh hơn
CPython 37,7×). Hai lựa chọn còn lại (nâng lên `i64`, hoặc `wontfix`) đã bị
loại vì mâu thuẫn trực tiếp với đích "ngang bằng hoàn toàn". Chi tiết đầy đủ
+ 3 lỗi ngầm nguy hiểm lộ ra khi lật cờ này: `[[project-tokenvector-session-2026-08-05]]`.

---

## Giai đoạn 0 — Bộ test phải nói thật (làm trước, không thương lượng)

Chừng nào chưa xong, **mọi tuyên bố "đã sửa" — kể cả của tôi — đều không kiểm
chứng được.**

**0.1 Trình chạy `test/run_tests.py` + CI.** Không viết lại 123 script sang
pytest — chúng đã đúng giao ước (exit 0/1). Bọc lại: chạy từng file bằng
subprocess riêng (chúng sửa `sys.path`, `exec` file `.tkv`, ghi `.exe`), timeout
mỗi test, xuất `_results.json` + một dòng tổng kết + exit code. Bảng
`test/verify/_manifest.py` gắn nhãn `net`/`native`/`slow` → 5 mục trượt vì môi
trường hôm nay thành **skip có lý do**, không còn là nhiễu. Thêm CI Windows
(toolchain là `ilasm`/.NET).

**0.2 Một harness dùng chung `test/verify/_tkv_arbiter.py`.** Phát hiện then
chốt: **cả 15 công cụ đều có entry `run(...) -> "str"` với tham số toàn `str`**
— đúng tập `compile_tkv_cli` hỗ trợ. Chúng không hề khó biên dịch; chúng được
viết với `read_file`/`write_file` giả chỉ vì tiện. Harness `run_both()`: phía
CPython nạp `.tkv` qua **chính đường phân giải `__tkv_import__` của compiler**
(`tkv_compile.py:769`) thay cho trò thay chuỗi hiện tại, `read_file`/`write_file`
trỏ vào thư mục tạm THẬT; phía biên dịch `compile_tkv_cli` + chạy `.exe`; so
sánh kết quả trả về, **nội dung mọi file xuất ra**, và loại exception. Thân
assertion cũ của mỗi test giữ nguyên, chạy hai lần.

Thứ tự chuyển: `ctxpack` (nhiều assertion nhất) → 11 công cụ chỉ phụ thuộc
`impgraph` → `typegraph` (939 dòng, chuỗi import 2 tầng) **sau cùng**.

> **Liệu trước:** 4436 dòng code thật chưa từng gặp compiler. Giai đoạn 0 nhiều
> khả năng lộ ra **nhiều lỗi hơn toàn bộ danh sách đã biết**. Hãy tính công sức
> cho nó ngang tổng giai đoạn 2+3, đừng coi là khởi động nhẹ. Lỗi mới không sửa
> tại chỗ — ghi vào sổ (§1.4) rồi đốt dần.

**0.3 Diệt nạn "shim đấu shim".** `_re_helpers.py`, `_json_helpers.py`,
`_file_io_helpers.py`, `_repeat_helpers.py` được **chính file `.tkv` import**, mà
`extract_program` bỏ qua `from X import` — nên trọng tài đang so "builtin của
DSL" với "bản Python do cùng tác giả viết". Lỗi chung thì vô hình. Sửa: **trỏ
thẳng vào thư viện chuẩn Python** (`re.search`, `json.dumps`, `Path.read_text`).
Chỗ nào không có tương đương thì shim chỉ được là **một dòng uỷ nhiệm** —
`tkvcalc_test.py:18` (`{'floor': math.floor, ...}`) là khuôn mẫu đúng. Thêm
`shim_purity_test.py` chặn mọc lại. Việc này sẽ **làm đỏ vài test** — đó là kết
quả đúng và mong muốn.

**0.4 Sửa ngay segfault `dict[str,i32]` làm tham số.** Xếp ở đây, không đợi:
segfault là mất an toàn bộ nhớ, tệ hơn hẳn một con số sai, và nó sẽ phá hỏng cả
phiên dò tự động ở giai đoạn 1 (không có exception sạch để phân loại). Nguyên
nhân: `{}` phía gọi luôn dựng `Dictionary<string,string>` bất kể chú thích của
hàm nhận.

---

## Giai đoạn 1 — Bộ dò lệch (cỗ máy trung tâm)

Đây là thay đổi kinh tế của cả dự án: thôi sửa lỗi lẻ mãi mãi, chuyển sang để
**máy tự tìm lệch ở quy mô lớn**, thay vì tình cờ gặp khi viết công cụ.

**1.1 Sinh chương trình từ CHÍNH các registry, không phải danh sách viết tay.**
`il_dispatch.py` là registry thuần có metadata kiểu (`EXPR_BUILTIN_DTYPE`,
`EXPR_METHOD_SHAPE`, …). Import `compiler.il_features` rồi đọc các bảng đó để
dựng văn phạm có kiểu. Hệ quả đáng giá: **ngày ai đó đăng ký `str.rfind`, bộ dò
bắt đầu sinh `rfind` ngay hôm đó**, không cần viết test riêng. Thêm
`grammar_coverage_test.py` bắt buộc mọi tên đã đăng ký phải xuất hiện trong ít
nhất một luật sinh hoặc nằm trong danh sách `UNGENERATABLE` có ghi lý do — tính
năng mới không thể lọt vào mà không bị dò.

Ràng buộc để chương trình sinh ra biên dịch được: (a) sinh theo kiểu nên không
bao giờ sai kiểu; (b) bảng `restrictions.py` mã hoá luật "chỉ nhận BIẾN thuần"
— **bảng này teo dần chính là thước đo tiến độ**; (c) biên dịch trượt thì xếp
`LOUD_GAP` và **đếm tần suất**, không tính là lỗi — biểu đồ tần suất này là tín
hiệu ưu tiên đúng cho giai đoạn 3.

Chương trình sinh ra phải thuần và dừng: không thời gian, không mạng, vòng lặp
có chặn trên.

**1.2 Rút gọn ca lỗi.** Giai đoạn 1a: bộ rút gọn viết tay (~200 dòng, tất định,
dễ gỡ) với vài phép tôn trọng kiểu — xoá câu lệnh, thay biểu thức con bằng hằng
cùng kiểu, co số về 0. Giai đoạn 1b: chuyển sang `hypothesis` khi văn phạm đã ổn
định. Bộ rút gọn tay là giàn giáo dùng xong bỏ — và như thế là đúng.

**1.3 Sổ lệch `test/parity/ledger.toml`** — mỗi mục ghi `id`, `site`
(file:dòng), `repro`, giá trị Python, giá trị TokenVector, `status`, `severity`.
Ghim **hai chiều**: ca `open` phải vẫn lệch, và **lệch ĐÚNG KIỂU đã ghi**. Tự
nhiên hết lệch → test đỏ, báo "có vẻ đã sửa, hãy đổi status". Lệch kiểu khác →
cũng đỏ. Nhờ vậy sổ giữ bộ test xanh mà không cho lỗi đã biết âm thầm biến hình.
Lệch mới chưa có mục → đỏ ngay.

> **Số mục `open` chính là thước đo tiến độ trung thực của dự án**, thay cho câu
> "tất cả đều xanh". CI chỉ chạy corpus tất định; bộ dò ngẫu nhiên chạy tay/hằng
> đêm — bộ test xanh không bao giờ được phụ thuộc vào hạt ngẫu nhiên.

**Nghiệm thu giai đoạn 1:** bộ dò **tự tìm lại được ≥10 lệch đã biết mà không
được mách**. Không tìm ra chia nguyên và slice không kẹp thì nó chưa dò đúng chỗ.

---

## Giai đoạn 2 — Nền móng làm rộng mọi thứ

**2.1 Hoist biểu thức tổng quát** — đòn bẩy lớn nhất. Luật "chỉ nhận BIẾN
thuần" lặp ở ~20 tính năng. `expr_hoist.py` (184 dòng) hiện là **regex trên văn
bản** với danh sách cứng `_WRAPPER_CALLS`. **Bắt buộc chuyển sang chạy trên dòng
token của `il_core.py` TRƯỚC, rồi mới tổng quát hoá** — nới regex sẽ sớm viết
đè vào bên trong một chuỗi ký tự (đúng lớp lỗi của A1 vừa sửa). Thêm
`register_hoist_position()` vào `il_dispatch.py` để mỗi feature tự khai báo ràng
buộc lúc đăng ký.

**2.2 `print`** — hiện **không tồn tại**. Tiền đề cho trọng tài của bộ dò.

**2.3 Một đường chuyển chuỗi duy nhất cho `str()`/`print`/`repr`.** Làm TRƯỚC
khi dò ở quy mô lớn, nếu không sẽ chìm trong nhiễu định dạng số thực.

**2.4 Ternary `a if c else b`** — `tkv_compile.py` không hề viết lại `ast.IfExp`,
mà DSL đòi `cond ? a : b` (**không phải Python hợp lệ**). Đây là **vi phạm bất
biến từ cả hai phía**, không phải "thiếu tiện nghi". Cùng loại: cú pháp
`module.function()` không tồn tại (`import os; os.path.join` không viết được) và
`x not in <set>` là SyntaxError. Cả ba nâng lên đây.

---

## Giai đoạn 3 — Sửa lệch, theo thứ tự

Nguyên tắc: **âm thầm trước, ồn ào sau** (lỗi ồn ào không thể phá bất biến), và
trong nhóm âm thầm thì theo bán kính ảnh hưởng lên code `.tkv` đang chạy.

### Nhóm A — âm thầm, có rủi ro phá code cũ, phải rà trước

1. **`/` → float** (`operators.py:167`). Rủi ro cao nhất kế hoạch: đổi kiểu của
   mọi `a / b`, lan qua suy kiểu → kiểu trả về → `str()` → dict. Trình tự: (a)
   ghi sổ hành vi hiện tại, (b) sửa, (c) **rà toàn bộ `.tkv` đổi chỗ nào thật sự
   muốn chia nguyên sang `//`**, (d) `tkvcalc_test.py` phải **mới khớp** CPython
   ở `7/2`, `10/4` — đó là bằng chứng. Làm **đầu tiên** trong nhóm A, vì làm sau
   20 bản vá khác nghĩa là phải kiểm chứng lại cả 20.
2. **Slice kẹp biên** — Python `"ab"[0:3]` → `"ab"`, TokenVector ném exception.
   Rủi ro thấp (đường lệch hiện đang *sập*, không code đúng nào dựa vào nó).
3. **Chỉ số âm động** `lst[-i]` — âm thầm dùng chỉ số dương.
4. **`round()` trả int** — phải làm **cùng lúc** với 2.3, nếu tách thì cái này
   che lỗi cái kia. Dùng `EXPR_BUILTIN_DTYPE_FN` sẵn có (`il_dispatch.py:83`)
   cho kiểu trả về phụ thuộc số đối số, đừng thêm cơ chế mới.

### Nhóm B — âm thầm, rủi ro thấp

5. `for k in dict:` ném `ArgumentNullException` — mở rộng `for_in_kvlist.py`.
6. `list.index`/`remove`, `set.remove` phải **ném đúng exception kèm đúng câu
   thông báo của CPython** (thông báo quan sát được qua `str(e)`).
7. **Thứ tự chèn của dict** — .NET `Dictionary<K,V>` không bảo đảm gì, Python bảo
   đảm từ 3.7 và điều đó *chịu lực* cho `json.dumps`, `str(dict)`, `for k in d`.
   Thay đổi biểu diễn lúc chạy, đụng 8 module. **Đi qua một hàm dựng duy nhất
   trong `dict_type.py`** + test canh gác cấm module feature nào nhắc thẳng
   `Dictionary<`.
8. `json_dumps`: thoát ký tự (port thẳng) — **sau** mục 7 vì thứ tự khoá phụ
   thuộc nó.
9. **`@property` setter** — hồ sơ cũ xếp vào nhóm "ồn ào", nhưng theo chính mô tả
   thì nó **âm thầm làm sai**. Chuyển vào đây.
10. `random` — xem §4, đây là ca "port, đừng sáng tác" rõ nhất.

**Không thuộc sổ lệch:** dồn chuỗi trong vòng lặp chậm ~68× là **hiệu năng,
không phá bất biến** → tách sang tồn đọng hiệu năng riêng (dù vẫn nên sửa vì nó
làm bộ dò chạy chậm).

### Nhóm C — khoảng trống ồn ào, xếp theo BIỂU ĐỒ TẦN SUẤT của giai đoạn 1

Không xếp theo cảm tính. Dự đoán top: `enumerate`/`zip`/`map`/`filter` ở vị trí
biểu thức → `isinstance`/`type`/`bool` → cú pháp `module.function()` → các method
chuỗi thiếu (`rfind`, `rsplit`, `splitlines`, `ljust/rjust/center`, `isdigit`,
`partition`, `removeprefix/suffix`) → `str.format`/`%` → `list.sort(key=,reverse=)`
→ `d[f(a,b)] = v` (sửa **tokenizer** trong `il_core.py`, không vá regex) → biến
toàn cục ghi được → khoá dict lồng nhau.

---

## Giai đoạn 4 — "Port, đừng sáng tác" cụ thể

Mỗi port kèm: (a) tiêu đề `PORTED-FROM:` ghi rõ file + phiên bản CPython, (b)
corpus **lấy từ chính bộ test của CPython**, chạy qua bộ dò.

| Tính năng | Nguồn port | Cách nghiệm thu |
|---|---|---|
| `str.format` + format spec | `Python/formatter_unicode.c`; văn phạm field ở `Objects/stringlib/unicode_format.h` | `Lib/test/test_format.py` vốn là một bảng `(format, args, expected)` — chép thẳng thành corpus. **`fstring.py` phải dựng LẠI trên bộ phân tích spec đã port**, hai bản format song song chắc chắn lệch nhau. |
| float → chuỗi | `Python/pystrtod.c` (`format_float_short`) | .NET Core cũng shortest-roundtrip nên chữ số thường khớp, nhưng **ngưỡng và số chữ số mũ khác** (`1e+16` vs `E+16`). Port phần hậu xử lý. Nghiệm thu bằng `Lib/test/floating_points.txt` (~5000 giá trị). |
| `list.sort(key=,reverse=)` | `Objects/listobject.c::listsort_impl` (Timsort) | **Tuyệt đối không dùng `List<T>.Sort`** — introsort của .NET **không ổn định**, là lệch âm thầm chỉ lộ khi có khoá trùng. `reverse=True` phải là đảo-trang trí-sắp-đảo để giữ tính ổn định. Nghiệm thu `Lib/test/test_sort.py`. |
| Thứ tự chèn dict | Thiết kế compact dict của `Objects/dictobject.c` | Chuyển thành `List<KeyValuePair<K,V>>` + `Dictionary<K,int>`, xoá ghi bia mộ (`DKIX_DUMMY`) để thứ tự sau `del` khớp. Nghiệm thu `Lib/test/test_dict.py`, `test_ordered_dict.py` (xoá rồi chèn lại phải nhảy về cuối). |
| `round()` | `Objects/floatobject.c::float_round` | Python **làm tròn về số chẵn**: `round(2.5)==2`, `round(3.5)==4`. `tkvcalc_test.py:48` đã test đúng hai ca này — **kiểm xem nó đang đậu thật hay shim che**, đây là chim báo bão tốt. `round(x,n)` của Python KHÁC `Math.Round(x,n)` của .NET. |
| `random` | `Modules/_randommodule.c` (MT19937) + `Lib/random.py` | **Chỉ bit-exact MT19937 mới cho ngang bằng.** Nghiệm thu bằng chính vector tham chiếu của CPython (`test_random.py::test_referenceImplementation`). Port lớn, tự chứa, cơ học — **ứng viên tốt nhất để giao cho AI Provider phụ**. |

**Cách dùng AI Provider cho đúng:** giao việc *tìm và giải thích nguồn tham
chiếu* và *dịch máy móc thuật toán tự chứa* (MT19937, Timsort, bộ phân tích
format). **Không giao việc quyết định ngữ nghĩa** — ngữ nghĩa lấy từ mã C và bộ
test CPython, cả hai đều là sự thật nền có sẵn. Sản phẩm giao nộp của mỗi
sub-agent là **corpus sinh ra bằng cách CHẠY CPython**, không bao giờ là lời mô
hình khẳng định CPython làm gì. Mọi đầu ra đều qua bộ dò trước khi được tin.

---

## Rủi ro chéo (một chỗ sửa làm hỏng chỗ khác)

- **`/` → float lan qua suy kiểu** toàn hệ thống → làm đầu nhóm A + rà toàn bộ.
- **Thứ tự dict đụng 8 module cùng lúc** → một module còn dùng `Dictionary<K,V>`
  thô là sinh bất định theo thứ tự. Chốt qua một hàm dựng + test canh gác.
- **Hoist tổng quát trên regex sẽ viết đè vào chuỗi ký tự** → chuyển sang token
  trước. Thêm ca canh gác: `.tkv` chứa `"x.y.z("` **bên trong** một chuỗi.
- **`round()` và `str()` khớp nối nhau** — sửa lệch nhau sẽ khiến cái này trông
  như đã xong trong khi lỗi bù trừ của cái kia đang ẩn. Một commit, corpus phủ cả
  hai.
- **Bản thân cuốn sổ là rủi ro** — mỗi mục là một lần bịt miệng lỗi thật. Chốt
  chặn: ghim hai chiều, bắt buộc có `site` file:dòng, và số `open` là chỉ số
  công khai.

---

## Verification

Sau **mỗi** mốc, không dồn tới cuối:

```bash
python test/run_tests.py
```

Từ mốc 1 trở đi đây là **một exit code duy nhất**, không còn là lời người nói.
Kèm theo:

1. Test mới của chính mốc đó, đối chiếu CPython, đặt trong `test/verify/`.
2. **Đối chứng bằng đột biến**: cố tình khôi phục hành vi cũ, test phải bắt được.
   Test viết sau khi code đã chạy ổn mà đậu ngay lần đầu là điều đáng nghi.
3. Chương trình thật chạy lại không đổi kết quả: `codestat_test.py`,
   `tkvcalc_test.py`.
4. Từ mốc 8: `python test/parity/fuzz.py --minutes 30` không sinh lệch mới ngoài sổ.
5. Commit riêng từng mốc, thông điệp ghi rõ **lỗi thật đã tìm được**.

### Trình tự mốc (mỗi mốc nghiệm thu độc lập)

| # | Mốc | Nghiệm thu bằng |
|---|---|---|
| 1 | `run_tests.py` + manifest + CI | exit code thật; cố tình làm hỏng 1 test → CI đỏ |
| 2 | Segfault `dict[str,i32]` làm tham số | ca tái hiện cho kết quả đúng |
| 3 | Shim trỏ về thư viện chuẩn + `shim_purity_test` | lệch bị che nay hiện ra, ghi sổ |
| 4 | `_tkv_arbiter.py` + chuyển `ctxpack_test` | ctxpack kiểm qua `.exe` thật |
| 5 | Chuyển 14 test còn lại, `typegraph` sau cùng | 4436 dòng được biên dịch; công bố danh sách xfail |
| 6 | **Chốt chính sách độ rộng số nguyên** | quyết định thành văn + mục sổ |
| 7 | `print` + một đường `str()`/float | corpus `floating_points.txt` xanh |
| 8 | Bộ dò (sinh + rút gọn + sổ) | **tự tìm lại ≥10 lệch đã biết mà không được mách** |
| 9 | Ternary `ast.IfExp` | `.tkv` dùng `a if c else b` biên dịch và khớp CPython |
| 10 | `/` → float + rà toàn bộ `.tkv` | `tkvcalc_test` **mới khớp** ở `7/2`, `10/4` |
| 11 | Kẹp slice, chỉ số âm động | không gian slice/index mở ra cho bộ dò |
| 12 | Thứ tự chèn dict → thoát chuỗi `json_dumps` | corpus `test_dict.py` xanh |
| 13 | Hoist trên token; `restrictions.py` teo lại | số mục bị xoá; tầm với bộ dò rộng ra |
| 14 | Nhóm C theo biểu đồ tần suất | mục đầu bảng đổi sau mỗi vòng |
| 15 | Port `random`/`sort`/`format` | khớp bit vector tham chiếu CPython |

Trạng thái ổn định sau mốc 8: bộ dò chạy hằng đêm, lệch mới về dưới dạng ca đã
rút gọn kèm mục sổ, và tiến độ dự án là **một con số trung thực — số lệch
`open`, giảm dần về 0.**
