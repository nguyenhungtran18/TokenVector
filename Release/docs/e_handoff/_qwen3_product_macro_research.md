# creative_options

Dưới đây là phân tích chi tiết và đề xuất 8 hướng tiếp cận khác nhau để giải quyết vấn đề hỗ trợ `itertools.product` (hoặc cú pháp tương đương) trong bộ biên dịch TokenVector, dựa trên các ràng buộc hiện có (giữ pipeline đơn giản, tương thích CPython, không viết lại parser).

### Bối cảnh kỹ thuật hiện tại
Cơ chế `_expand_macros_once` hiện tại hoạt động theo kiểu **"Thay thế dòng đơn" (Line-level replacement)**.
- **Input:** Một dòng code nguồn.
- **Output:** Một hoặc nhiều dòng code mới.
- **Vấn đề với `product`:** Để dịch `for x, y in product(a, b):` thành 2 vòng lặp lồng nhau, chúng ta cần thay đổi **độ sâu thụt lề (indentation)** của tất cả các dòng code phía sau (thân vòng lặp gốc). Cơ chế hiện tại không có khả năng "nhìn xuống" (look-ahead) để xác định khối code nào thuộc về vòng lặp này, và cũng không có cơ chế "đổ lại" (re-indent) khối code đó.

---

### Hướng 1: Giữ nguyên quyết định "Không làm" (No-Op / User Responsibility)

Đây là lựa chọn an toàn nhất và phù hợp với triết lý "giữ bộ biên dịch đơn giản".

*   **(a) Cần sửa gì trong pipeline:** Không cần sửa gì. Có thể thêm một thông báo cảnh báo (warning) hoặc lỗi biên dịch rõ ràng nếu phát hiện pattern `product` để hướng dẫn người dùng.
*   **(b) Rủi ro/Độ phức tạp:** Rủi ro bằng 0. Độ phức tạp bằng 0.
*   **(c) Ảnh hưởng đến macro khác:** Không ảnh hưởng. `enumerate`, `zip` vẫn hoạt động vì chúng chỉ thay thế dòng `for` bằng một dòng `for` khác (cùng độ sâu thụt lề), không thay đổi cấu trúc khối.

**Lý do chọn:** `itertools.product` tạo ra cấu trúc điều khiển luồng (control flow) phức tạp hơn nhiều so với `enumerate` hay `zip`. Việc ép buộc một cơ chế macro đơn giản xử lý cấu trúc lồng nhau là nguyên nhân gốc rễ của lỗi. Để người dùng viết tay 2 vòng `for` là cách rõ ràng, dễ debug và đúng với bản chất của Python subset.

---

### Hướng 2: Macro "Khối" (Block-level Macro) với Đánh dấu Đóng (Sentinel-based)

Thay vì thay thế từng dòng, macro sẽ tìm kiếm một khối code hoàn chỉnh dựa trên độ thụt lề.

*   **(a) Cần sửa gì:**
    *   `_expand_macros_once` cần được viết lại thành `_expand_block_macros`.
    *   Khi gặp `for x, y in product(a, b):`, nó sẽ:
        1.  Xác định độ thụt lề cơ sở (base indent) của dòng `for`.
        2.  Quét các dòng tiếp theo cho đến khi gặp dòng có độ thụt lề <= base indent (hoặc hết hàm).
        3.  Lấy toàn bộ khối thân (body) này.
        4.  Tạo ra cấu trúc mới:
            ```python
            for __i in range(len(a)):
                x = a[__i]
                for __j in range(len(b)):
                    y = b[__j]
                    <BODY_WITH_INCREASED_INDENT>
            ```
        5.  Thay thế toàn bộ đoạn từ dòng `for` cũ đến dòng cuối của body bằng đoạn code mới đã được tăng thụt lề cho body.
*   **(b) Rủi ro/Độ phức tạp:** **Cao.**
    *   Phức tạp logic: Phải xử lý trường hợp body rỗng, comment, hoặc các cấu trúc điều khiển lồng nhau khác (`if`, `try-except`) bên trong body.
    *   Xử lý lỗi: Nếu người dùng viết sai thụt lề, macro có thể "ăn" nhầm code của khối khác.
*   **(c) Ảnh hưởng đến macro khác:** Có thể tái sử dụng logic này cho `enumerate` hoặc `zip` nếu muốn, nhưng không cần thiết. Tuy nhiên, việc thay đổi từ "line-based" sang "block-based" có thể phá vỡ giả định của các macro đơn giản khác nếu chúng không được viết cẩn thận để không can thiệp vào việc quét khối.

---

### Hướng 3: Tiền xử lý AST (AST Pre-processing) thay vì Text-level

Thay vì thao tác trên văn bản thô (raw text), hãy parse một phần nhỏ thành AST, biến đổi AST, rồi chuyển ngược lại thành code (unparse).

*   **(a) Cần sửa gì:**
    *   Thêm một bước giữa đọc file và `_expand_macros_once`: Parse toàn bộ file thành AST (dùng `ast` module của Python).
    *   Tìm node `For` có target là tuple và iter là `Call` với func `product`.
    *   Biến đổi node `For` đó thành hai node `For` lồng nhau trong cây AST.
    *   Dùng `ast.unparse` (Python 3.9+) hoặc thư viện `astor` để chuyển AST thành code nguồn mới.
    *   Sau đó, pipeline macro cũ (nếu còn) sẽ chạy trên code mới này.
*   **(b) Rủi ro/Độ phức tạp:** **Trung bình - Cao.**
    *   Cần xử lý việc bảo toàn vị trí (line numbers) cho debug nếu cần.
    *   `ast.unparse` có thể tạo ra code khác biệt về mặt format so với code gốc (do đó có thể gây ra vấn đề nếu các macro khác phụ thuộc vào format cụ thể).
    *   Phức tạp hơn việc thao tác text thuần túy.
*   **(c) Ảnh hưởng đến macro khác:** Các macro text-level cũ có thể trở nên thừa thãi hoặc xung đột nếu chúng cố gắng sửa đổi code đã được unparse. Tốt nhất là thay thế hoàn toàn hệ thống macro text bằng hệ thống AST transformation.

---

### Hướng 4: Macro "Giả lập" bằng Danh sách Tiền tạo (Pre-computed List)

Thay vì tạo vòng lặp lồng nhau, hãy tạo một danh sách các bộ (tuple) trước khi vòng lặp bắt đầu.

*   **(a) Cần sửa gì:**
    *   Macro `for x, y in product(a, b):` sẽ được thay thế bằng:
        ```python
        __product_result = [(a[i], b[j]) for i in range(len(a)) for j in range(len(b))]
        for x, y in __product_result:
        ```
    *   Lưu ý: Dòng `for x, y in __product_result:` này sẽ thay thế dòng `for` gốc.
    *   **Vấn đề:** Thân vòng lặp gốc vẫn giữ nguyên độ thụt lề. Nhưng vì dòng `for` mới chỉ là 1 dòng, nên thân vòng lặp (đã thụt lề +4 so với dòng `for` gốc) sẽ vẫn đúng vị trí so với dòng `for` mới.
*   **(b) Rủi ro/Độ phức tạp:** **Thấp - Trung bình.**
    *   **Hiệu suất:** Tạo ra một danh sách mới trong bộ nhớ. Nếu `a` và `b` lớn, đây là rủi ro về bộ nhớ (Memory overhead) và hiệu năng (Time complexity tăng do phải tạo hết danh sách trước).
    *   **Độ phức tạp logic:** Đơn giản, chỉ cần thay thế 1 dòng bằng 2 dòng. Không cần xử lý lại thụt lề của body.
*   **(c) Ảnh hưởng đến macro khác:** Không ảnh hưởng. Cơ chế thay thế dòng đơn vẫn hoạt động. Đây là hướng đi khả thi nhất nếu chấp nhận đánh đổi hiệu suất.

---

### Hướng 5: Macro "Giả lập" bằng Iterator/Tương tự `zip` của `itertools`

Tương tự Hướng 4, nhưng dùng một generator expression hoặc một hàm helper để tránh tạo danh sách lớn.

*   **(a) Cần sửa gì:**
    *   Macro thay thế `for x, y in product(a, b):` bằng:
        ```python
        def __product_iter(a, b):
            for i in range(len(a)):
                for j in range(len(b)):
                    yield (a[i], b[j])
        
        for x, y in __product_iter(a, b):
        ```
    *   **Vấn đề:** Định nghĩa hàm `__product_iter` phải được đặt ở đâu?
        *   Nếu đặt ngay trước vòng lặp: Nó sẽ nằm trong thân hàm hiện tại. Điều này có thể gây xung đột tên biến hoặc làm rối code.
        *   Nếu đặt ở đầu file: Cần logic phức tạp để chèn code vào đúng vị trí.
        *   Giải pháp đơn giản hơn: Dùng một list comprehension ngắn gọn như Hướng 4, nhưng bọc trong `iter()`: `for x, y in iter([(a[i], b[j]) for i in range(len(a)) for j in range(len(b))]):`.
*   **(b) Rủi ro/Độ phức tạp:** **Cao.**
    *   Việc nhúng định nghĩa hàm hoặc biểu thức phức tạp vào giữa code nguồn có thể gây ra các vấn đề về scope và độ đọc.
    *   Phức tạp hơn Hướng 4.
*   **(c) Ảnh hưởng đến macro khác:** Không ảnh hưởng trực tiếp, nhưng làm tăng độ phức tạp của code trung gian.

---

### Hướng 6: Cú pháp thay thế "Flat" (Flat Syntax)

Thay vì cố gắng mô phỏng `product`, hãy giới thiệu một cú pháp mới, đơn giản hơn cho bộ biên dịch, nhưng vẫn tương đương về mặt ngữ nghĩa trong Python subset.

*   **(a) Cần sửa gì:**
    *   Không hỗ trợ `product(a, b)`.
    *   Thay vào đó, hỗ trợ một cú pháp đặc biệt (ví dụ: `for x, y in cartesian(a, b):`).
    *   Macro cho `cartesian(a, b)` sẽ hoạt động giống như Hướng 4 (tạo danh sách hoặc dùng list comprehension).
    *   Hoặc, đơn giản hơn, yêu cầu người dùng dùng `for x in a: for y in b:` và cung cấp một công cụ mã hóa (linter/formatter) tự động chuyển đổi code Python chuẩn sang dạng này nếu cần.
*   **(b) Rủi ro/Độ phức tạp:** **Thấp.**
    *   Nếu chọn cách tạo danh sách (như Hướng 4), rủi ro là hiệu suất.
    *   Nếu chọn cách yêu cầu người dùng viết tay, rủi ro là trải nghiệm người dùng kém.
*   **(c) Ảnh hưởng đến macro khác:** Không ảnh hưởng.

---

### Hướng 7: Macro "Đệ quy" (Recursive Macro Expansion) với Stack

Cho phép macro gọi lại chính nó hoặc các macro khác trong quá trình mở rộng, và xử lý thụt lề thông qua một stack độ sâu.

*   **(a) Cần sửa gì:**
    *   `_expand_macros_once` cần được thay thế bằng một hệ thống mở rộng đệ quy.
    *   Khi gặp `product`, nó không thay thế trực tiếp, mà chèn một "marker" hoặc một cấu trúc trung gian.
    *   Một bước sau đó sẽ duyệt lại code, tìm các marker này và xử lý thụt lề cho các khối code liên quan.
    *   Đây thực chất là một phiên bản đơn giản của AST transformation nhưng làm trên text.
*   **(b) Rủi ro/Độ phức tạp:** **Rất Cao.**
    *   Dễ dẫn đến lỗi vô hạn lặp (infinite loop) nếu không kiểm soát tốt.
    *   Khó debug.
    *   Phức tạp hơn nhiều so với lợi ích mang lại.
*   **(c) Ảnh hưởng đến macro khác:** Có thể phá vỡ các macro đơn giản nếu không được thiết kế cẩn thận để tương thích với hệ thống stack.

---

### Hướng 8: Hỗ trợ `product` thông qua Thư viện Tiêu chuẩn (Standard Library Support)

Thay vì cố gắng biến đổi cú pháp, hãy đảm bảo rằng `itertools.product` được hỗ trợ đầy đủ ở cấp độ runtime (IL code).

*   **(a) Cần sửa gì:**
    *   Không cần sửa macro.
    *   Cần đảm bảo rằng trình biên dịch có thể dịch `import itertools` và `itertools.product(a, b)` thành code IL gọi đúng hàm tương ứng trong runtime .NET.
    *   Người dùng sẽ viết:
        ```python
        import itertools
        for x, y in itertools.product(a, b):
            ...
        ```
    *   Trình biên dịch sẽ dịch `for x, y in itertools.product(a, b):` thành code IL tạo một iterator từ `product`, sau đó lặp qua iterator đó.
*   **(b) Rủi ro/Độ phức tạp:** **Trung bình.**
    *   Cần implement `itertools.product` trong runtime .NET (dễ dàng).
    *   Cần đảm bảo trình biên dịch hiểu cú pháp `for ... in ...` với bất kỳ iterable nào, không chỉ là `range` hay `list`.
    *   Nếu trình biên dịch hiện tại chỉ hỗ trợ `for` với `range` hoặc `list` cụ thể, thì cần mở rộng parser/compiler để hỗ trợ bất kỳ iterable nào.
*   **(c) Ảnh hưởng đến macro khác:** Không ảnh hưởng. Đây là cách tiếp cận đúng đắn nhất về mặt kiến trúc: để runtime xử lý logic phức tạp, compiler chỉ cần dịch cú pháp chuẩn.

---

### Tổng kết và Khuyến nghị

| Hướng | Độ phức tạp | Rủi ro | Hiệu suất | Khả thi | Ghi chú |
| :--- | :--- | :--- | :--- | :---

# critical_evaluation

Dựa trên bối cảnh kỹ thuật bạn cung cấp về `TokenVector` (compiler Python-subset -> .NET IL) và cơ chế macro text-level hiện tại, dưới đây là phân tích chi tiết, đánh giá rủi ro và khuyến nghị cuối cùng.

### 1. Phân biệt và Đánh giá các hướng tiếp cận

Vấn đề cốt lõi là **mâu thuẫn giữa cấu trúc phẳng (flat) của danh sách dòng raw và cấu trúc lồng nhau (nested) của logic `product`**. Cơ chế hiện tại `_expand_macros_once` hoạt động trên nguyên tắc "Thay thế 1 dòng bằng N dòng, giữ nguyên vị trí tuyệt đối của các dòng tiếp theo". Điều này hoạt động tốt cho `enumerate`/`zip` (vì chúng là vòng lặp đơn cấp) nhưng thất bại thảm hại với `product` (vòng lặp lồng nhau).

Dưới đây là 3 hướng giải quyết thường được đề xuất trong các hệ thống compiler/text-processing, được đánh giá dựa trên tiêu chí: **Tính khả thi với codebase 15k+ dòng**, **Rủi ro phá vỡ macro cũ**, và **Độ phức tạp**.

#### Hướng 1: Sửa đổi `_expand_macros_once` để hỗ trợ "Indent Shifting" (Dịch chuyển thụt lề)
*   **Ý tưởng:** Khi thay thế dòng `for x, y in product...` bằng khối code lồng nhau, hàm macro sẽ đồng thời quét các dòng tiếp theo (cho đến khi gặp dòng chưa thụt lề hoặc `if/else/try` mới) và cộng thêm 4 space (hoặc 1 level indent) vào đầu mỗi dòng đó.
*   **Đánh giá rủi ro với macro cũ (enumerate/zip/chain):**
    *   **RẤT CAO.** Các macro hiện tại (`enumerate`, `zip`) giả định rằng thân vòng lặp sau đó ở đúng level indent cũ. Nếu logic "Indent Shifting" được tích hợp chung vào `_expand_macros_once`, nó cần một cơ chế để biết *bao nhiêu* level cần dịch chuyển.
    *   Nếu logic đó là "luôn dịch chuyển +1 level cho mọi macro", thì `enumerate` sẽ bị hỏng (thân vòng lặp bị thụt quá sâu, hoặc nếu logic chỉ dịch chuyển khi phát hiện pattern đặc biệt, nó sẽ làm code phức tạp hóa đáng kể).
    *   Nếu logic là "dịch chuyển dựa trên độ sâu lồng nhau của macro", thì cần phân tích cú pháp (parse) trước khi expand, điều này vi phạm nguyên tắc "text-level trước khi parse" của hệ thống hiện tại.
*   **Tính khả thi:** Thấp. Dễ gây ra các lỗi side-effect khó debug (ví dụ: comment bị thụt lề sai, hoặc các dòng code không thuộc thân vòng lặp nhưng nằm liền kề bị dịch chuyển sai).

#### Hướng 2: Tách biệt cơ chế Macro thành 2 loại: "Flat Replacement" và "Block Expansion"
*   **Ý tưởng:**
    *   Giữ nguyên `_expand_macros_once` cho các trường hợp đơn giản (`enumerate`, `zip`, `chain`).
    *   Viết một hàm mới, ví dụ `_expand_complex_macros`, xử lý riêng các trường hợp cần thay đổi cấu trúc khối (như `product`). Hàm này sẽ:
        1.  Tìm dòng `for ... in product(...)`.
        2.  Xác định ranh giới của khối thân vòng lặp (dựa vào indent).
        3.  Thay thế dòng đầu bằng khối lồng nhau.
        4.  Dịch chuyển toàn bộ khối thân vòng lặp gốc sang level sâu hơn.
        5.  Gộp lại vào danh sách dòng.
*   **Đánh giá rủi ro với macro cũ:**
    *   **THẤP.** Vì `_expand_macros_once` không bị thay đổi logic nội tại. Các macro cũ vẫn hoạt động độc lập.
    *   Rủi ro duy nhất là thứ tự gọi hàm: Nếu `_expand_complex_macros` chạy trước hoặc sau `_expand_macros_once` không đúng, có thể xảy ra xung đột. Tuy nhiên, vì `product` có pattern rất đặc thù (`itertools.product`), khả năng trùng lặp pattern với `enumerate`/`zip` là gần như bằng 0.
*   **Tính khả thi:** Trung bình. Cần viết thêm logic để xác định "block boundary" (ranh giới khối) dựa vào indent trong giai đoạn pre-parse. Đây là công việc tốn kém nhưng an toàn.

#### Hướng 3: Không làm macro cho `product`, để người dùng tự viết (Hướng đã chọn)
*   **Ý tưởng:** Từ bỏ việc expand `product` thành code. Người dùng phải viết tay 2 vòng `for` lồng nhau.
*   **Đánh giá rủi ro:**
    *   **BẰNG 0.** Không ảnh hưởng đến codebase, không ảnh hưởng đến macro cũ.
*   **Tính khả thi:** Cao nhất (vì không cần code mới), nhưng **trải nghiệm người dùng (DX) kém**. Người dùng phải viết nhiều code hơn, dễ sai sót về logic index.

---

### 2. Đánh giá rõ ràng: Hướng nào có thể phá vỡ macro cũ?

*   **Hướng 1 (Sửa chung `_expand_macros_once`):** **CÓ THỂ PHÁ VÕ MACRO CŨ.**
    *   Lý do: Cơ chế hiện tại dựa vào sự đơn giản "1 dòng -> N dòng". Nếu thêm tính năng "dịch chuyển indent các dòng sau", bạn buộc phải đưa ra quy tắc chung cho *tất cả* macro. Nếu quy tắc đó không phân biệt được macro nào cần dịch chuyển indent (product) và macro nào không (enumerate), thì ít nhất một trong hai sẽ bị hỏng. Việc thêm điều kiện `if macro_type == 'product'` vào hàm chung làm tăng độ phức tạp và rủi ro regression (lỗi quay lại) cho các macro khác.

*   **Hướng 2 (Tách hàm riêng `_expand_complex_macros`):** **KHÔNG PHÁ VÕ MACRO CŨ (An toàn hơn).**
    *   Lý do: Macro cũ (`enumerate`, `zip`) tiếp tục dùng `_expand_macros_once` với logic cũ. Macro mới (`product`) dùng hàm mới. Hai hệ thống song song, ít tương tác. Rủi ro chỉ nằm ở việc xác định đúng ranh giới khối (block parsing) cho `product`, nhưng lỗi đó chỉ ảnh hưởng đến `product`, không lan sang `enumerate`.

*   **Hướng 3 (Không làm):** **KHÔNG PHÁ VÕ GÌ CẢ.**

---

### 3. Khuyến nghị cuối cùng: Nên làm `product()` ngay bây giờ hay tiếp tục để dành?

**Khuyến nghị: TIẾP TỤC ĐỂ DÀNH (KHÔNG LÀM MACRO CHO PRODUCT NGAY BÂY GIỜ).**

#### Tại sao?

1.  **Tỷ lệ Lợi ích / Rủi ro (ROI) thấp:**
    *   `itertools.product` là một hàm tiện ích, nhưng không phải là cấu trúc điều khiển cơ bản như `for` hay `if`.
    *   Chi phí để implement an toàn (Hướng 2) là khá cao: Bạn phải viết một mini-parser để xác định "thân vòng lặp" dựa vào indent *trước khi* cây cú pháp được xây dựng. Điều này mâu thuẫn với triết lý "text-level macro đơn giản" của hệ thống hiện tại.
    *   Rủi ro: Nếu implement sai, nó sẽ tạo ra các lỗi logic cực kỳ khó debug (vòng lặp chạy sai số lần, biến bị leak scope sai) mà không báo lỗi compile-time rõ ràng.

2.  **Giải pháp thay thế đã có sẵn và hiệu quả:**
    *   Người dùng có thể viết tay 2 vòng `for` lồng nhau. Code này không dài hơn nhiều so với việc gọi `product`.
    *   Ví dụ:
        ```python
        # Thay vì:
        for x, y in product(a, b):
            print(x, y)

        # Viết:
        for i in range(len(a)):
            x = a[i]
            for j in range(len(b)):
                y = b[j]
                print(x, y)
        ```
    *   Với compiler AOT, việc viết tay còn cho phép tối ưu hóa thủ công nếu cần (ví dụ: cache `len(b)` ra ngoài vòng ngoài).

3.  **Độ phức tạp của codebase:**
    *   Với 15,000+ dòng code, mỗi lần sửa đổi cơ chế tiền xử lý (pre-processing) đều là một "minh họa cho định luật Murphy": *Bạn sẽ luôn phá vỡ một thứ gì đó mà bạn không ngờ tới.*
    *   Các macro hiện tại (`enumerate`, `zip`) đang hoạt động ổn định. Việc chạm vào lõi của `_expand_macros_once` (Hướng 1) là rủi ro không đáng có. Việc viết một hàm mới (Hướng 2) là công sức lớn cho một tính năng không phải là "pain point" lớn (vì có thể viết tay).

4.  **Chiến lược dài hạn:**
    *   Nếu trong tương lai, nhu cầu về các macro phức tạp (lồng nhau, thay đổi cấu trúc khối) tăng lên, hãy xem xét nâng cấp toàn bộ hệ thống macro từ "text-level" lên "AST-level" (thao tác trên cây cú pháp sau khi parse). Khi đó, việc xử lý `product` sẽ dễ dàng và an toàn hơn rất nhiều vì bạn đã có thông tin về cấu trúc khối (block scope).
    *   Làm macro text-level cho `product` là giải pháp "vá víu" (hacky) và dễ gây nợ kỹ thuật.

### Nếu BẮT BUỘC phải làm (Ví dụ: yêu cầu khách hàng cứng rắn)

Nếu bạn *phải* implement, hãy chọn **Hướng 2 (Tách hàm riêng)** để đảm bảo an toàn cho macro cũ. Dưới đây là các bước cụ thể ít rủi ro nhất:

1.  **Tạo hàm `_expand_product_macros(lines)`:**
    *   Input: Danh sách các dòng raw.
    *   Output: Danh sách các dòng đã xử lý.

2.  **Logic trong `_expand_product_macros`:**
    *   Duyệt qua danh sách dòng.
    *   Khi gặp dòng khớp pattern `for ... in product(...)`:
        *   Xác định `base_indent` của dòng `for`.
        *   Xác định `body_indent` của dòng tiếp theo (phải lớn hơn `base_indent`).
        *   Tìm tất cả các dòng tiếp theo có indent >= `body_indent` (đây là thân vòng lặp gốc).
        *   **Thay thế:**
            *   Dòng `for` gốc -> Thay bằng:
                ```python
                for __i in range(len(a)):
                    x = a[__i]
                    for __j in range(len(b)):
                        y = b[__j]
                ```
                (Lưu ý: Các dòng này phải có indent phù hợp với `base_indent`).
            *   Các dòng thân vòng lặp gốc -> Dịch chuyển indent thêm 1 level (thêm 4 space) và chèn vào sau dòng `y = b[__j]`.
    *   Tiếp tục duyệt các dòng còn lại.

3.  **Tích hợp vào pipeline:**
    *   Gọi `_expand_product_macros(lines)` **TRƯỚC** hoặc **SAU** `_expand_macros_once`?
    *   **Khuyến nghị:** Gọi **TRƯỚC** `_expand_macros_once`.
        *   Lý do: Sau khi expand `product`, code trở thành các vòng `for` lồng nhau thông thường. Các macro khác (như `enumerate`) nếu có trong thân vòng lặp mới sẽ được `_expand_macros_once` xử lý bình thường sau đó.
    *   **Quan trọng:** Đảm bảo pattern của `product` không trùng với `enumerate`/`zip`. (VD: `product(a, b)` khác `enumerate(a)`).

4.  **Kiểm thử (Testing):**
    *   Viết test case cụ thể cho `product` với nhiều cấp độ lồng nhau.
    *   Viết test case regression cho `enumerate` và `zip` để đảm bảo chúng không bị ảnh hưởng.

**Tóm lại:** Với triết lý "đơn giản và ổn định" của một compiler AOT, việc **không làm macro cho `product`** là lựa chọn thông minh nhất. Hãy để người dùng viết tay, hoặc đợi khi hệ thống nâng cấp lên AST-level macro thì mới implement tính năng này một cách chính xác và an toàn.

