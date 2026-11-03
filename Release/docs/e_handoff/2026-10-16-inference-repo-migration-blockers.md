# HANDOFF 2026-10-16 — 7 điểm chặn repo `TokenVector.Inference` (compiler build 16-Oct 11:40)

Bổ sung cho `2026-10-15-inference-repo-build-blocker.md`. File đó ghi trạng thái trước
khi compiler được sửa; file này ghi trạng thái **sau** và tập trung vào phần còn lại.

**Kết quả kiểm tra toàn repo:** biên dịch 43 module canonical của
`D:\TokenVector.Inference\tv` (mỗi module một probe 3 dòng `import <module>` + `main`).
**PASS 15 / FAIL 28.** Không module nào build sạch chưa.

---

## 1. Đã sửa được phía repo (không cần compiler can thiệp)

| Nhóm | Cách sửa |
|---|---|
| `//` `%` thiếu nhớ tạm — `runtime/hal.tkv`, `quantization/int4.tkv`, `format/gguf.tkv` | Bọc vào helper `_idiv_<module>` / `_imod_<module>` (tên duy nhất theo module) |
| `else:` rỗng — `quantization/int4.tkv` | Xoá nhánh `else` rỗng (`elif` bên dưới nối vào `if` trên) |

Sau đó 3 module này đi tiếp vào nhóm lỗi #2 bên dưới — tức là fix trên **đúng quy
tắc** nhưng chưa đủ.

---

## 2. CHẶN LỚN NHẤT — suy luận kiểu phụ thuộc thứ tự trong file

**Triệu chứng:** 12 module dừng ở
`'<bieu thuc>[i]' - khong suy duoc hinh dang cua bieu thuc ben trai`

`quantization.engine`, `runtime.dynamic_shapes`, `runtime.kv_cache`,
`runtime.paged_kv`, `runtime.prefix_skip`, `runtime.session`, `text.beam`,
`text.sampling`, `text.speculative`, `text.tree_speculative`, `vision.preprocess`,
`vision.vit`.

**Bằng chứng đáng chú ý — đây là lỗi compiler, không phải lỗi mã:**

Hàm `_int4_scales_sym` trong `quantization/int4.tkv` **biên dịch được một mình**:

```powershell
# cat đúng hàm _int4_scales_sym (12 dong) + main -> da dich, OK
```

nhưng đặt lại vào đúng vị trí cũ trong file thì hỏng. Thêm/bớt một hàm **đứng
trước** trong file cũng làm đổi kết quả. Nghĩa là kiểu của một biểu thức được
suy luận theo thứ tự duyệt chứ không phải theo phạm vi biến.

Cùng dấu hiệu xuất hiện ở lỗi khác của compiler:

```
'_t[...]' - '_t' khong phai list/dict/string/mang, hoac kieu long nhau khong suy
dung duoc do thu tu khai bao (container duoc THAM CHIEU phai khai bao TRUOC
container CHUA no trong van ban nguon)
```
(ở `onnx/translator.tkv`)

**Cần compiler kiểm tra:** có vẻ first-pass đang dùng danh sách phẳng các biến/
container đã thấy thay vì bảng phạm vi. Nếu một tên được gán nhiều kiể trong file
(dù ở các hàm khác nhau), bảng phẳng sẽ bị ghi đè và các hàm sau không suy được
kiểu ⇒ đúng lỗi này.

**Cách kiểm nhanh phía compiler:** lấy `_int4_scales_sym` từ
`D:\TokenVector.Inference\tv\quantization\int4.tkv`, biên dịch riêng (OK), rồi thêm
dần các hàm đứng trước cho tới khi hỏng.

---

## 3. `spawn(...)` không còn tồn tại

`server/batcher.tkv` gọi `spawn(self._worker)`:

```
'spawn(...)' dung o dang lenh doc lap (khong gan bien) - khong tim thay ham nay
trong chuong trinh dang bien dich (goi sai ten?)
```

Compiler cũ có `spawn`; bản mới không thấy. Cần biết: đã bỏ hẳn, hay đổi tên?
Nếu bỏ hẳn thì batcher phải viết lại đường worker (hiện nó cũng chưa chạy được vì
worker không bao giờ được tạo — xem `HANDOFF.md` bên repo inference).

---

## 4. `parallel_for` là builtin và **che hàm của repo một cách âm thầm**

`runtime/backend.tkv` và `runtime/simt.tkv` tự định nghĩa:

```
ham ['parallel_for'] trung ten voi builtin co san - builtin se che ham cua ban
(khong bao gio duoc goi). Doi ten ham.
```

Compiler **chỉ cảnh báo, không ném lỗi** — hàm đó sẽ chết âm thầm, không ai biết
cho tới khi chạy. Cân nhắc ném lỗi như trường hợp trùng tên hàm giữa 2 module
(`trung ten ham [...]`), vì đây cùng một họ lỗi nhưng hậu quả im lặng.

---

## 5. `AST node khong ro` — 3 module `onnx.*`

```
onnx/models.tkv : AST node khong ro: 1000412
onnx/parser.tkv : AST node khong ro: 1001948
onnx/writer.tkv : AST node khong ro: 1009018
```

Cùng một họ lỗi, ba node id khác nhau. Cần map các id này về loại nút để biết
tính năng/cú pháp nào đang thiếu.

---

## 6. `KeyError` — ĐÃ THU HẸP, còn 3 module

`session.tkv` (3800 dòng) đã hết lỗi này, nhưng `text.generate` / `text.tools` /
`text.grammar` vẫn dính. Repro **6 dòng** — xem mục 3.0 của file handoff 15-10.

Điểm cần lưu ý khi debug: `import tv.runtime.session` đứng riêng báo lỗi **khác**
(`'<bieu thuc>[i]'`), còn đi qua `tv.text.generate` thì ra `KeyError`. Cùng nguyên
nhân gốc nhưng **thứ tự báo lỗi phụ thuộc đường đi** — đừng dừng ở lỗi đầu tiên.

---

## 7. Quy tắc mới (nghiêm hơn, làm hỏng mã cũ)

| Quy tắc | Ảnh hưởng |
|---|---|
| **`else:` rỗng bị từ chối** — `else: khong co than khoi (block rong)` | `quantization/int4.tkv` có `else:` rỗng **từ trước khi đổi compiler** (commit cũ), compiler cũ chấp nhận |
| **Record ctor đòi đủ mọi field không phải container** — `record 'LayerNorm' can 6 tham so (dim, eps, _adam_g, _adam_b, _opt_g, _opt_b), gap 1` | `training/autograd.tkv` |

Câu hỏi cho #1: cố ý siết hay nên cho phép? Nếu cố ý thì nên có thông điệp gợi ý
cách viết lại (xoá nhánh rỗng), vì đây là thay đổi phá mã đang chạy.

---

## 8. Thứ tự đề xuất

| # | Việc | Mức |
|---|---|---|
| 1 | Suy luận kiểu phụ thuộc thứ tự (mục 2) | Cao — chặn 12 module, và có thể là gốc của `KeyError` |
| 2 | `simd_*` + thiếu `System.Numerics.Vectors.dll` (mục 4.1 của file 15-10) | Cao |
| 3 | `spawn` biến mất (mục 3) | Trung bình |
| 4 | `AST node khong ro` (mục 5) | Trung bình |
| 5 | `parallel_for` che âm thầm (mục 4) | Thấp nhưng nguy hiểm |
| 6 | Gán số cho biến `str` (mục 3.4 file 15-10) | Thấp |

Nếu mục 2 được sửa thì phần lớn 28 lỗi còn lại có thể tự biến mất, vì nhiều lỗi
`<bieu thuc>[i]` nhiều khả năng chỉ là **biểu hiện thứ hai** của cùng một vấn đề suy
luận kiểu.