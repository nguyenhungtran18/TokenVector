# `frozenset` — Design

## Bối cảnh

`set` hiện CHỈ tạo được RỖNG (`s = set()`, `assign_set_new`), dtype
phần tử suy sau từ lệnh `.add()` ĐẦU TIÊN (`find_first_append_dtype`,
`compiler/il_features/set_type.py`). `frozenset` (bất biến — không có
`.add()`/`.remove()` sau khi tạo) không khớp mô hình "tạo rỗng rồi
add" này — cần constructor NHẬN SẴN dữ liệu. Đây là mục đầu tiên
trong 4 kiểu của 6.8 (sau: `complex`, `bytearray`, `bytes`).

## Mục tiêu

`fs = frozenset(a_list)` — tạo 1 `HashSet<T>` điền sẵn TOÀN BỘ phần
tử của `a_list` (dtype phần tử suy từ `a_list`), gắn `shape='frozenset'`.
Đọc (`x in fs`, `len(fs)`, `for x in fs:` qua macro `for_in_list` hiện
có cho set) hoạt động Y HỆT `set`. Gọi `.add()`/`.remove()`/`.discard()`
trên biến `frozenset` → `SyntaxError` rõ ("frozenset la bat bien").

## Kiến trúc

- **Type annotation**: thêm `shape='frozenset'` (song song `'set'` đã
  có trong `typed_dsl_parser.py`'s `parse_type_ann`) — CHỈ dùng nội bộ
  (suy tự động từ RHS `frozenset(...)`, KHÔNG cần cú pháp chú thích
  tường minh `frozenset[dtype]` như `set[dtype]` — giữ tối giản, đúng
  tinh thần "chỉ thêm cái cần dùng ngay").
- **`ASSIGN_RHS_PARSERS` entry mới** (`try_rhs_frozenset_new`, song
  song `try_rhs_set_new`): khớp `s = frozenset(<ten_bien_list>)` — CHỈ
  chấp nhận 1 biến list ĐƠN làm nguồn (không constructor lồng/biểu
  thức phức tạp, giống giới hạn quen thuộc). Tra `scope`/`known_shapes`
  xác nhận nguồn là `list`, gắn `known_shapes[name] = 'frozenset'`.
- **Codegen**: `newobj instance void {hashset_type}::.ctor()` rồi LẶP
  qua từng phần tử của list nguồn, `Add()` — HOẶC dùng CTOR
  `HashSet<T>(IEnumerable<T>)` có sẵn trong BCL (rẻ hơn, 1 lệnh) —
  xác nhận sự tồn tại overload này qua PowerShell reflection TRƯỚC khi
  dùng (giống kỷ luật đã áp dụng cho `List<T>(IEnumerable<T>)` ở
  `random.sample()` trước đây), rồi `newobj instance void
  {hashset_type}::.ctor(class ...IEnumerable\`1<T>)` truyền thẳng list.
- **Chặn mutate**: `il_set_type`'s call site cho `.add()`/`.remove()`/
  `.discard()` (trong `set_type.py`/`set_methods_batch2.py`) thêm 1
  check đầu hàm: `if ta.shape == 'frozenset': raise SyntaxError(...)`.
  KHÔNG đụng logic sinh IL hiện có cho `set` thường — chỉ thêm guard
  sớm.
- **Đọc (không mutate)**: `x in fs`/`len(fs)`/`for x in fs:` — dùng
  LẠI NGUYÊN các hàm hiện có xử lý theo `shape == 'set'`; sửa các nơi
  đó thành `shape in ('set', 'frozenset')` (rà soát TOÀN BỘ các điểm
  kiểm tra `shape == 'set'` liên quan tới ĐỌC, không phải MUTATE —
  liệt kê rõ trong plan).

## Phạm vi

- Chỉ `frozenset(<bien_list_don>)` — không constructor rỗng
  `frozenset()`, không từ biểu thức phức tạp/set khác.
- Không hỗ trợ union/intersection/difference giữa `frozenset` (nếu
  `set` hiện tại đã có các phép này, để nguyên phạm vi hiện tại — nếu
  `set` CHƯA có, không thêm mới ở đây, ngoài phạm vi).
- `.add()`/`.remove()`/`.discard()` trên `frozenset` → LUÔN lỗi biên
  dịch rõ ràng.

## Kiểm chứng

- Test mới: `frozenset(list)` — `x in fs` đúng cả 2 chiều (có/không),
  `len(fs)` đúng, `for x in fs:` duyệt đúng số phần tử (không trùng
  lặp nếu list nguồn có phần tử trùng — đúng ngữ nghĩa set). Gọi
  `.add()`/`.remove()` trên `frozenset` — spike riêng xác nhận
  `SyntaxError` rõ.
- Regression: `set` thường (`set()` + `.add()`) không đổi hành vi.
- Cả 2 cây sửa đồng bộ. KHÔNG rebuild `tkvc.exe`.
