# SÁCH HƯỚNG DẪN LẬP TRÌNH NGÔN NGỮ TOKENVECTOR NATIVE AOT
### (TokenVector Native AOT Programming Language Master Guidebook)

**Mã giáo trình: TKV-BOOK-2026-EXHAUSTIVE**  
**Phiên bản: 2026.1 (Bản Phát hành Thương mại Độc lập)**  
**Bản quyền & Bảo chứng: Đội ngũ Trình biên dịch TokenVector**

---

## TỔNG QUAN CHƯƠNG TRÌNH HỌC (TABLE OF CONTENTS)

- **UNIT I: CƠ BẢN VỀ NGÔN NGỮ TOKENVECTOR & HỆ THỐNG KIỂU UNBOXED**
  - Bài 1: Ngôn ngữ TokenVector Native & Trình biên dịch AOT `tkvc`
  - Bài 2: Khai báo Biến, Phạm vi Scope & Quy tắc Gán giá trị
  - Bài 3: Chi tiết Hệ thống Kiểu Unboxed Native (`i32`, `i64`, `f32`, `f64`, `str`, `TkvInt`)
  - Bài 4: Khai báo Hàm (`def`), Chú thích Kiểu DSL & Giá trị Trả về
- **UNIT II: CẤU TRÚC ĐIỀU KHIỂN, VÒNG LẶP & NGOẠI LỆ NATIVE**
  - Bài 5: Khối Điều kiện `if / elif / else` & Biểu thức Ternary
  - Bài 6: Vòng lặp `for range()` Ép Thanh ghi CPU & Vòng lặp `while`
  - Bài 7: Lệnh Nhảy `break`, `continue` & Kỹ thuật Đệ quy (Recursion)
  - Bài 8: Khối Quản lý Ngoại lệ `try / except / finally` & Ném Ngoại lệ `raise`
- **UNIT III: CẤU TRÚC DỮ LIỆU ĐỘNG & THAO TÁC XỬ LÝ CHUỖI**
  - Bài 9: Chuỗi ký tự `str`, Thao tác Cắt chuỗi Slicing & Regex `re_replace`
  - Bài 10: Danh sách Động `List<T>` & Danh sách Đa kiểu `List<object>`
  - Bài 11: Bảng băm `Dictionary<K,V>`, Tập hợp `HashSet<T>` & Bộ Bất biến `Tuple`
- **UNIT IV: LẬP TRÌNH HƯỚNG ĐỐI TƯỢNG (OOP) & HỆ THỐNG MODULE NATIVE**
  - Bài 12: Khai báo Lớp / Record (`record`), Attributes & Constructor `.ctor`
  - Bài 13: Đơn Kế thừa & Đa Kế thừa Lớp (`class Child(ParentA, ParentB)`), `super()`
  - Bài 14: Hệ thống Module Native (`import`), Thư viện Chuẩn `stdlib/*.tkv` & Package `vendor/`
- **UNIT V: LẬP TRÌNH NÂNG CAO, ĐA LUỒNG KHÔNG GIL & INTEROP NỀN TẢNG**
  - Bài 15: Generator State Machine CIL (`yield`, `yield from`, `iter()`, `next()`)
  - Bài 16: Lập trình Bất đồng bộ Native Async/Await (`async def` / `await` $\rightarrow$ `.NET Task<T>`)
  - Bài 17: Mô hình Đa luồng Thật Không GIL (`thread_spawn` / `thread_join` $\rightarrow$ OS Kernel Threads)
  - Bài 18: FFI Bridge & P/Invoke Calling Native C/C++ (`ctypes_cdll`, `ctypes_call`)
  - Bài 19: Trực tiếp Liên kết Assembly .NET Ecosystem (`__tkv_extern_assembly__`)
  - Bài 20: Thực thi Mã Động Native (Dynamic Execution & REPL `eval_code`, `exec_code`)

---

# UNIT I: CƠ BẢN VỀ NGÔN NGỮ TOKENVECTOR & HỆ THỐNG KIỂU UNBOXED

## BÀI 1: NGÔN NGỮ TOKENVECTOR NATIVE & TRÌNH BIÊN DỊCH AOT `tkvc`

### 1.1 Ngôn ngữ TokenVector là gì?
**TokenVector** là một ngôn ngữ lập trình biên dịch **AOT (Ahead-Of-Time) Native** độc lập, cao cấp và hiệu năng cao. TokenVector được thiết kế để tạo ra các ứng dụng `.exe` chạy trực tiếp trên hệ điều hành mà không cần bất kỳ bộ thông dịch hay môi trường phụ thuộc bên ngoài nào.

### 1.2 Ví dụ 1: Viết và Biên dịch Chương trình Đầu tiên

#### 📝 Mã nguồn tệp `hello.tkv`:
```tkv
# -*- coding: utf-8 -*-

def run() -> "str":
    print("Chao mung ban den voi Ngon ngu Lap trinh TokenVector Native!")
    return "TOKENVECTOR_AOT_SUCCESS"
```

#### 🎯 Mục đích của ví dụ:
Minh họa điểm vào mặc định `run()` của một ứng dụng TokenVector Native, cách in chuỗi ra màn hình console và cách trả về giá trị chuỗi kết quả cho trình thực thi hệ thống.

#### 🔍 Giải thích chi tiết từng dòng lệnh:
- **Dòng 1 (`# -*- coding: utf-8 -*-`)**: Khai báo bảng mã UTF-8 để hỗ trợ xử lý chuỗi ký tự Tiếng Việt và các ký tự đặc biệt.
- **Dòng 3 (`def run() -> "str":`)**: Định nghĩa hàm điểm vào có tên `run`, tham số rỗng, có annotation chú thích kiểu trả về là chuỗi ký tự `"str"`.
- **Dòng 4 (`print(...)`)**: Gọi hàm built-in `print` để in thông điệp `"Chao mung ban den voi Ngon ngu Lap trinh TokenVector Native!"` ra màn hình console.
- **Dòng 5 (`return "TOKENVECTOR_AOT_SUCCESS"`)**: Trả về giá trị chuỗi kết quả `"TOKENVECTOR_AOT_SUCCESS"` kết thúc hàm điểm vào.

#### 📊 Kết quả thực thi cuối cùng (Output):
- **Console Output**: `Chao mung ban den voi Ngon ngu Lap trinh TokenVector Native!`
- **Return Value**: `"TOKENVECTOR_AOT_SUCCESS"`

---

## BÀI 2: KHAI BÁO BIẾN, PHẠM VI SCOPE & QUY TẮC GÁN GIÁ TRỊ

### 2.1 Ví dụ 2: Khai báo Biến & Định kiểu Unboxed

#### 📝 Mã nguồn tệp `variables_demo.tkv`:
```tkv
# -*- coding: utf-8 -*-

def demo_variables() -> "str":
    age = 25
    count: "i64" = 1000000000
    price = 99.95
    name = "TokenVector Engine"
    return name + "|AGE_" + str(age) + "|COUNT_" + str(count)

def run() -> "str":
    return demo_variables()
```

#### 🎯 Mục đích của ví dụ:
Hướng dẫn khai báo biến số nguyên 32-bit (`i32`), số nguyên 64-bit (`i64`), số thực 64-bit (`f64`), biến chuỗi (`str`), và cách ghép chuỗi bằng phép cộng `+` cùng hàm chuyển đổi `str()`.

#### 🔍 Giải thích chi tiết từng dòng lệnh:
- **Dòng 4 (`age = 25`)**: Khai báo biến `age`, gán giá trị `25`. Trình biên dịch tự suy luận kiểu số nguyên 32-bit `i32`.
- **Dòng 5 (`count: "i64" = 1000000000`)**: Khai báo biến `count` với chú thích kiểu rõ ràng `"i64"` (số nguyên 64-bit).
- **Dòng 6 (`price = 99.95`)**: Khai báo biến `price`, gán số thực `99.95` (kiểu `f64`).
- **Dòng 7 (`name = "TokenVector Engine"`)**: Khai báo biến `name` chứa chuỗi `"TokenVector Engine"`.
- **Dòng 8 (`return name + ...`)**: Nối các chuỗi và các giá trị chuyển đổi `str(age)`, `str(count)` để trả về kết quả cuối cùng.

#### 📊 Kết quả thực thi cuối cùng (Output):
- **Return Value**: `"TokenVector Engine|AGE_25|COUNT_1000000000"`

---

## BÀI 3: CHI TIẾT HỆ THỐNG KIỂU UNBOXED NATIVE

### 3.1 Ví dụ 3: Phép toán Số học Tính Động năng (Physics Calculation)

#### 📝 Mã nguồn tệp `physics_calc.tkv`:
```tkv
# -*- coding: utf-8 -*-

def calc_energy(mass: "f64", velocity: "f64") -> "f64":
    energy = 0.5 * mass * (velocity * velocity)
    return energy

def run() -> "str":
    e = calc_energy(10.0, 5.0)
    return "DONG_NANG:" + str(e)
```

#### 🎯 Mục đích của ví dụ:
Thực hiện tính toán số thực độ chính xác đôi `f64` trên thanh ghi CPU x64 theo công thức động năng $E = \frac{1}{2} m v^2$.

#### 🔍 Giải thích chi tiết từng dòng lệnh:
- **Dòng 3 (`def calc_energy(mass: "f64", velocity: "f64") -> "f64":`)**: Hàm nhận 2 tham số số thực `mass` (khối lượng) và `velocity` (vận tốc), trả về kiểu `f64`.
- **Dòng 4 (`energy = 0.5 * mass * (velocity * velocity)`)**: Tính giá trị $0.5 \times 10.0 \times (5.0 \times 5.0) = 125.0$.
- **Dòng 8 (`e = calc_energy(10.0, 5.0)`)**: Gọi hàm `calc_energy` với khối lượng `10.0` kg và vận tốc `5.0` m/s.
- **Dòng 9 (`return "DONG_NANG:" + str(e)`)**: Trả về kết quả nối chuỗi `"DONG_NANG:125.0"`.

#### 📊 Kết quả thực thi cuối cùng (Output):
- **Return Value**: `"DONG_NANG:125.0"`

---

# UNIT II: CẤU TRÚC ĐIỀU KHIỂN, VÒNG LẶP & NGOẠI LỆ NATIVE

## BÀI 5: KHỐI ĐIỀU KIỆN IF / ELIF / ELSE & BIỂU THỨC TERNARY

### 5.1 Ví dụ 4: Phân Loại Điểm Số Học Sinh

#### 📝 Mã nguồn tệp `conditionals_demo.tkv`:
```tkv
# -*- coding: utf-8 -*-

def classify_grade(score: "f64") -> "str":
    status = "PASSED" if score >= 5.0 else "FAILED"
    if score >= 8.5:
        return "EXCELLENT|" + status
    elif score >= 6.5:
        return "GOOD|" + status
    elif score >= 5.0:
        return "AVERAGE|" + status
    else:
        return "POOR|" + status

def run() -> "str":
    r1 = classify_grade(9.0)
    r2 = classify_grade(4.5)
    return r1 + "||" + r2
```

#### 🎯 Mục đích của ví dụ:
Minh họa khối điều kiện rẽ nhánh nhiều tầng `if / elif / else` và biểu thức gán điều kiện Ternary (`PASSED if score >= 5.0 else FAILED`).

#### 🔍 Giải thích chi tiết từng dòng lệnh:
- **Dòng 4 (`status = "PASSED" if ...`)**: Sử dụng biểu thức Ternary để gán `"PASSED"` nếu `score >= 5.0`, ngược lại gán `"FAILED"`.
- **Dòng 5-12 (`if score >= 8.5: ...`)**: Rẽ nhánh kiểm tra phân loại điểm số từ Xuất sắc, Khá, Trung bình đến Kém.
- **Dòng 15-16**: Gọi hàm với 2 mức điểm `9.0` (Xuất sắc) và `4.5` (Kém), rồi ghép lại bằng `"||"`.

#### 📊 Kết quả thực thi cuối cùng (Output):
- **Return Value**: `"EXCELLENT|PASSED||POOR|FAILED"`

---

## BÀI 6: VÒNG LẶP FOR RANGE ÉP THANH GHI CPU & VÒNG LẶP WHILE

### 6.1 Ví dụ 5: Tính Tổng Giai Thừa & Vòng lặp Controlled Loop

#### 📝 Mã nguồn tệp `loop_demo.tkv`:
```tkv
# -*- coding: utf-8 -*-

def compute_factorial(n: "i32") -> "i64":
    fact = 1
    for i in range(1, n + 1):
        fact = fact * i
    return fact

def run() -> "str":
    ans = compute_factorial(5)
    return "5_FACTORIAL:" + str(ans)
```

#### 🎯 Mục đích của ví dụ:
Sử dụng vòng lặp `for range()` để tính giai thừa $5! = 1 \times 2 \times 3 \times 4 \times 5 = 120$.

#### 🔍 Giải thích chi tiết từng dòng lệnh:
- **Dòng 4 (`fact = 1`)**: Khởi tạo tích giai thừa ban đầu bằng `1`.
- **Dòng 5 (`for i in range(1, n + 1):`)**: Tạo vòng lặp chạy từ `1` đến `n` (với $n = 5$).
- **Dòng 6 (`fact = fact * i`)**: Nhân dồn biến `i` vào `fact` qua mỗi vòng lặp.
- **Dòng 10 (`ans = compute_factorial(5)`)**: Gọi tính giai thừa của `5`.

#### 📊 Kết quả thực thi cuối cùng (Output):
- **Return Value**: `"5_FACTORIAL:120"`

---

## BÀI 8: KHỐI QUẢN LÝ NGOẠI LỆ TRY / EXCEPT / FINALLY & RAISE

### 8.1 Ví dụ 6: Bắt và Quản lý Ngoại lệ Chia cho Khống

#### 📝 Mã nguồn tệp `exception_demo.tkv`:
```tkv
# -*- coding: utf-8 -*-

def safe_divide(a: "f64", b: "f64") -> "f64":
    try:
        if b == 0.0:
            raise ValueError("Loi mau so bang 0!")
        return a / b
    except ValueError as err:
        print("Da xu ly: " + str(err))
        return -1.0
    finally:
        print("Hoan tat khoi try-finally.")

def run() -> "str":
    res = safe_divide(10.0, 0.0)
    return "RESULT:" + str(res)
```

#### 🎯 Mục đích của ví dụ:
Minh họa cơ chế chủ động ném ngoại lệ bằng `raise`, bắt ngoại lệ bằng `except ValueError as err` và đảm bảo khối `finally` luôn chạy.

#### 🔍 Giải thích chi tiết từng dòng lệnh:
- **Dòng 5-6 (`if b == 0.0: raise ...`)**: Chủ động ném ngoại lệ `ValueError` nếu mẫu số `b` bằng `0.0`.
- **Dòng 8-9 (`except ValueError as err:`)**: Bắt ngoại lệ, in ra thông báo lỗi và trả về giá trị an toàn `-1.0`.
- **Dòng 11-12 (`finally:`)**: Khối lệnh dọn dẹp tài nguyên luôn luôn thực thi dù có lỗi hay không.

#### 📊 Kết quả thực thi cuối cùng (Output):
- **Console Output**: 
  `Da xu ly: Loi mau so bang 0!`  
  `Hoan tat khoi try-finally.`
- **Return Value**: `"RESULT:-1.0"`

---

# UNIT III: CẤU TRÚC DỮ LIỆU ĐỘNG & THAO TÁC XỬ LÝ CHUỖI

## BÀI 9: CHUỖI KÝ TỰ STR, THAO TÁC SLICING & REGEX RE_REPLACE

### 9.1 Ví dụ 7: Xử lý Chuỗi & Thay thế Regex

#### 📝 Mã nguồn tệp `string_demo.tkv`:
```tkv
# -*- coding: utf-8 -*-
import re

def process_text(raw: "str") -> "str":
    sub_str = raw[0:4]
    cleaned = re_replace(raw, "[0-9]+", "NUM")
    return sub_str + "|" + cleaned

def run() -> "str":
    res = process_text("CODE1234TEST")
    return res
```

#### 🎯 Mục đích của ví dụ:
Trích xuất chuỗi con bằng cú pháp Slicing `[0:4]` và thay thế tất cả các chữ số bằng từ `"NUM"` qua hàm Regex `re_replace`.

#### 🔍 Giải thích chi tiết từng dòng lệnh:
- **Dòng 5 (`sub_str = raw[0:4]`)**: Lấy 4 ký tự đầu tiên của chuỗi `"CODE1234TEST"` $\rightarrow$ thu được `"CODE"`.
- **Dòng 6 (`cleaned = re_replace(...)`)**: Tìm mẫu biểu thức chính quy `[0-9]+` (các chữ số) và thay thế thành `"NUM"` $\rightarrow$ thu được `"CODENUMTEST"`.
- **Dòng 7 (`return sub_str + "|" + cleaned`)**: Ghép hai kết quả lại thành `"CODE|CODENUMTEST"`.

#### 📊 Kết quả thực thi cuối cùng (Output):
- **Return Value**: `"CODE|CODENUMTEST"`

---

## BÀI 10: DANH SÁCH ĐỘNG LIST<T> VA LIST<OBJECT>

### 10.1 Ví dụ 8: Quản lý Danh sách Điểm số

#### 📝 Mã nguồn tệp `list_demo.tkv`:
```tkv
# -*- coding: utf-8 -*-

def calculate_average() -> "f64":
    scores = [80.0, 90.0, 100.0]
    scores.append(70.0)
    
    total = 0.0
    for s in scores:
        total = total + s
        
    avg = total / float(len(scores))
    return avg

def run() -> "str":
    avg = calculate_average()
    return "AVERAGE_SCORE:" + str(avg)
```

#### 🎯 Mục đích của ví dụ:
Khai báo danh sách động `List<f64>`, thêm phần tử mới bằng `.append()`, duyệt vòng lặp tính tổng và chia trung bình bằng `len()`.

#### 🔍 Giải thích chi tiết từng dòng lệnh:
- **Dòng 4 (`scores = [80.0, 90.0, 100.0]`)**: Khởi tạo danh sách gồm 3 phần tử ban đầu.
- **Dòng 5 (`scores.append(70.0)`)**: Thêm phần tử `70.0` vào cuối danh sách (tổng số phần tử thành 4).
- **Dòng 7-9 (`for s in scores:`)**: Duyệt qua từng điểm số và cộng dồn vào `total` ($80 + 90 + 100 + 70 = 340.0$).
- **Dòng 11 (`avg = total / float(len(scores))`)**: Tính trung bình bằng $340.0 / 4.0 = 85.0$.

#### 📊 Kết quả thực thi cuối cùng (Output):
- **Return Value**: `"AVERAGE_SCORE:85.0"`

---

# UNIT IV: LẬP TRÌNH HƯỚNG ĐỐI TƯỢNG (OOP) & HỆ THỐNG MODULE NATIVE

## BÀI 12: KHAI BÁO CLASS / RECORD, ATTRIBUTES & CONSTRUCTOR `.ctor`

### 12.1 Ví dụ 9: Lớp Quản lý Tài khoản Ngân hàng

#### 📝 Mã nguồn tệp `bank_account.tkv`:
```tkv
# -*- coding: utf-8 -*-

class BankAccount:
    def __init__(self, owner: "str", balance: "f64"):
        self.owner = owner
        self.balance = balance
        
    def deposit(self, amount: "f64") -> "f64":
        self.balance = self.balance + amount
        return self.balance

def run() -> "str":
    acc = BankAccount("John Doe", 1000.0)
    new_bal = acc.deposit(500.0)
    return "OWNER:" + acc.owner + "|NEW_BALANCE:" + str(new_bal)
```

#### 🎯 Mục đích của ví dụ:
Khai báo một Class OOP Native có Constructor `__init__`, lưu trữ attributes `self.owner`, `self.balance` và phương thức nộp tiền `deposit()`.

#### 🔍 Giải thích chi tiết từng dòng lệnh:
- **Dòng 3 (`class BankAccount:`)**: Khai báo lớp `BankAccount`.
- **Dòng 4-6 (`def __init__(self, owner, balance):`)**: Hàm khởi tạo Constructor nhận tên chủ tài khoản và số dư ban đầu.
- **Dòng 8-10 (`def deposit(self, amount):`)**: Phương thức cộng thêm tiền gửi vào `self.balance`.
- **Dòng 13-15**: Khởi tạo tài khoản `"John Doe"` có `1000.0`$, gửi thêm `500.0`$ $\rightarrow$ số dư mới thành `1500.0`$.

#### 📊 Kết quả thực thi cuối cùng (Output):
- **Return Value**: `"OWNER:John Doe|NEW_BALANCE:1500.0"`

---

## BÀI 13: ĐƠN KẾ THỪA & ĐA KẾ THỪA LỚP (`class Child(ParentA, ParentB)`)

### 13.1 Ví dụ 10: Hệ thống Cảnh báo Đa Kế Thừa

#### 📝 Mã nguồn tệp `multi_inherit_demo.tkv`:
```tkv
# -*- coding: utf-8 -*-

class Logger:
    def log_msg(self, text: "str") -> "str":
        return "[LOG] " + text

class Notifier:
    def send_alert(self, target: "str") -> "str":
        return "[ALERT] Sent to " + target

class SecuritySystem(Logger, Notifier):
    def process_breach(self, user: "str") -> "str":
        m1 = self.log_msg("CHAM_NHAP_TRAI_PHEP")
        m2 = self.send_alert(user)
        return m1 + " || " + m2

def run() -> "str":
    sys_obj = SecuritySystem()
    res = sys_obj.process_breach("Admin")
    return res
```

#### 🎯 Mục đích của ví dụ:
Minh họa tính năng **Đa Kế Thừa Lớp Native** trong TokenVector: Lớp `SecuritySystem` kế thừa đồng thời cả hai lớp cha `Logger` và `Notifier`.

#### 🔍 Giải thích chi tiết từng dòng lệnh:
- **Dòng 3-4 (`class Logger:`)**: Định nghĩa lớp cha `Logger` chứa phương thức `log_msg`.
- **Dòng 7-8 (`class Notifier:`)**: Định nghĩa lớp cha `Notifier` chứa phương thức `send_alert`.
- **Dòng 11 (`class SecuritySystem(Logger, Notifier):`)**: Khai báo lớp con kế thừa đồng thời 2 lớp cha.
- **Dòng 13-14**: Phương thức `process_breach` gọi cả 2 phương thức từ 2 lớp cha khác nhau `self.log_msg()` và `self.send_alert()`.

#### 📊 Kết quả thực thi cuối cùng (Output):
- **Return Value**: `"[LOG] CHAM_NHAP_TRAI_PHEP || [ALERT] Sent to Admin"`

---

# UNIT V: LẬP TRÌNH NÂNG CAO, ĐA LUỒNG KHÔNG GIL & INTEROP NỀN TẢNG

## BÀI 15: GENERATOR STATE MACHINE CIL (`yield`, `yield from`)

### 15.1 Ví dụ 11: Chuỗi Generator Sinh Số Động

#### 📝 Mã nguồn tệp `generator_demo.tkv`:
```tkv
# -*- coding: utf-8 -*-

def sub_numbers() -> "list[i32]":
    yield 10
    yield 20

def main_numbers() -> "list[i32]":
    yield 1
    yield from sub_numbers()
    yield 2

def run() -> "str":
    out = ""
    for v in main_numbers():
        out = out + str(v) + ","
    return "GENERATOR_OUT:" + out
```

#### 🎯 Mục đích của ví dụ:
Minh họa Generator State Machine CIL với lệnh `yield` và nhúng Generator con qua lệnh `yield from`.

#### 🔍 Giải thích chi tiết từng dòng lệnh:
- **Dòng 3-5 (`sub_numbers`)**: Generator con sinh ra `10` rồi tới `20`.
- **Dòng 7-10 (`main_numbers`)**: Generator chính sinh ra `1`, ủy quyền sinh tiếp `10`, `20` từ `sub_numbers()`, rồi sinh cuối `2`.
- **Dòng 14-15 (`for v in main_numbers():`)**: Duyệt lặp qua Generator và nối chuỗi thu được `"1,10,20,2,"`.

#### 📊 Kết quả thực thi cuối cùng (Output):
- **Return Value**: `"GENERATOR_OUT:1,10,20,2,"`

---

## BÀI 17: MÔ HÌNH ĐA LUỒNG THẬT KHÔNG GIL (`thread_spawn` / `thread_join`)

### 17.1 Ví dụ 12: Chạy 2 Luồng Tính Toán Song Song Trực tiếp Trên OS Kernel

#### 📝 Mã nguồn tệp `multithread_demo.tkv`:
```tkv
# -*- coding: utf-8 -*-

def worker_task() -> "i64":
    s = 0
    for i in range(5000000):
        s = s + i
    return s

def run() -> "str":
    t1 = thread_spawn(worker_task)
    t2 = thread_spawn(worker_task)
    
    r1 = thread_join(t1)
    r2 = thread_join(t2)
    return "MULTITHREAD_NO_GIL_RESULT:" + str(r1 + r2)
```

#### 🎯 Mục đích của ví dụ:
Khởi chạy 2 OS Kernel Threads chạy tính toán song song 100% trên 2 nhân CPU vật lý mà không bị nghẽn bởi khóa GIL.

#### 🔍 Giải thích chi tiết từng dòng lệnh:
- **Dòng 3-7 (`worker_task`)**: Hàm thực hiện 5,000,000 phép tính cộng dồn.
- **Dòng 10-11 (`t1 = thread_spawn(...)`)**: Khởi tạo và khởi chạy 2 OS Kernel Threads độc lập song song.
- **Dòng 13-14 (`r1 = thread_join(t1)`)**: Chờ cả 2 luồng hoàn tất và thu về kết quả của từng luồng.
- **Dòng 15 (`return ...`)**: Trả về tổng kết quả của 2 luồng ($12,499,997,500,000 \times 2 = 24,999,995,000,000$).

#### 📊 Kết quả thực thi cuối cùng (Output):
- **Return Value**: `"MULTITHREAD_NO_GIL_RESULT:24999995000000"`

---

# HƯỚNG DẪN BIÊN DỊCH VÀ KIỂM THỬ TỔNG THỂ

Để biên dịch bất kỳ ví dụ nào ở trên ra file `.exe` độc lập bằng Trình biên dịch `tkvc`:

```cmd
tkvc build <ten_file.tkv> --out <ten_file.exe> --entry run
```

Chạy file thực thi trực tiếp:
```cmd
<ten_file.exe>
```

---
*HẾT SÁCH HƯỚNG DẪN LẬP TRÌNH NGÔN NGỮ TOKENVECTOR NATIVE AOT 2026*
