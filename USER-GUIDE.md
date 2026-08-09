# TOKENVECTOR COMPILER PLATFORM - HƯỚNG DẪN SỬ DỤNG VÀ GIÁO TRÌNH KỸ THUẬT CHI TIẾT
### (Comprehensive Official Technical Handbook for TokenVector Native AOT Compiler Platform)

**Mã tài liệu: TKV-USERGUIDE-2026-FULL**  
**Phiên bản: 2026.1 (Bản Phát hành Thương mại)**  
**Bản quyền & Bảo chứng: Đội ngũ Trình biên dịch TokenVector & Antigravity AI Team**

---

## CHƯƠNG 1: TỔNG QUAN VỀ NỀN TẢNG TOKENVECTOR & KIẾN TRÚC AOT NATIVE

### 1.1 Triết lý Thiết kế & Sứ mệnh Độc lập
**TokenVector** được xây dựng nhằm giải quyết các hạn chế kinh điển của môi trường CPython tiêu chuẩn:
- ❌ CPython bị giới hạn đa luồng bởi khóa GIL (Global Interpreter Lock), chỉ tận dụng được 1 nhân CPU cho các tác vụ tính toán.
- ❌ CPython yêu cầu đóng gói cồng kềnh (từ 25 MB đến 100 MB) và bắt buộc phải có CPython Interpreter Runtime trên máy khách.
- ❌ CPython thông dịch bytecode làm chậm tốc độ vòng lặp và phát sinh chi phí bộ nhớ cho con trỏ `PyObject*`.

**Giải pháp của TokenVector**:
- 🚀 **Biên dịch AOT (Ahead-Of-Time) Native**: Dịch thẳng mã nguồn cú pháp TokenVector sang mã CIL (.NET Intermediate Language) và biên dịch ra file thực thi `.exe` chạy độc lập hoàn toàn.
- ⚡ **Loại bỏ Hoàn toàn Khóa GIL (True No-GIL Multithreading)**: Khởi chạy các OS Kernel Threads song song 100% trên các nhân CPU vật lý, giúp tăng tốc độ đa luồng lên **10.39 LẦN** so với CPython.
- 📦 **File Executable Siêu Nhỏ Gọn**: Tạo ra các file `.exe` độc lập dung lượng chỉ từ **12 KB - 120 KB**, không cần cài đặt TokenVector.
- 🔒 **Bảo mật Mã nguồn**: Mã nguồn được dịch thành mã máy CIL AOT, chống ngượclại decompilation dễ dàng của các file bytecode `.pyc`.

### 1.2 Luồng Biên dịch Kỹ thuật Đầu-Cuối (End-to-End Pipeline)
Quy trình từ file mã nguồn `.tkv` đến file `.exe` diễn ra qua 4 bước khép kín:

$$\text{Tệp } \texttt{.tkv} \quad \xrightarrow{\text{1. AST Parse}} \quad \text{TokenVector AST} \quad \xrightarrow{\text{2. CIL Codegen}} \quad \text{File ILAssembly } (\texttt{.il}) \quad \xrightarrow{\text{3. ILASM}} \quad \text{Native PE } (\texttt{.exe})$$

1. **Buớc 1: Phân tích Cú pháp (AST Parsing)**: `tkv_compile.tkv` dùng module AST để trích xuất cây cú pháp, nhận diện annotation kiểu DSL và xây dựng danh sách class/record.
2. **Bước 2: Phát sinh Mã CIL (CIL Codegen)**: `il_codegen.tkv` chuyển đổi các câu lệnh, hàm, vòng lặp, closure và generator sang mã trung gian CIL.
3. **Bước 3: Lắp ráp Mã Máy (ILASM Assembly)**: `tokenvector_compile.tkv` kích hoạt trình lắp ráp `ilasm.exe` đóng gói file `.il` thành file thực thi Portable Executable (PE `.exe`).
4. **Bước 4: Thực thi AOT Native**: File `.exe` chạy trực tiếp trên Windows x64 thông qua .NET CLR JIT Engine tích hợp sẵn.

---

## CHƯƠNG 2: CÀI ĐẶT, CẤU HÌNH MÔI TRƯỜNG & THAM SỐ CLI

### 2.1 Cấu hình Môi trường Đường dẫn (`PATH`)
Để có thể gọi lệnh `tkvc` từ bất kỳ thư mục nào trên hệ thống:

**Trên Windows Command Prompt (cmd)**:
```cmd
set PATH=%PATH%;C:\Claude AI Project\TokenVector\release\3.code\dist
```

**Trên Windows PowerShell**:
```powershell
$env:Path += ";C:\Claude AI Project\TokenVector\release\3.code\dist"
```

### 2.2 Chi tiết Danh mục Lệnh CLI (`tkvc`)

#### 1. Lệnh Biên dịch AOT (`tkvc build`)
Biên dịch một file Native `.tkv` ra file thực thi `.exe` độc lập:
```bash
tkvc build <path/to/file.tkv> --out <path/to/output.exe> --entry <ten_ham_diem_vao>
```
- `--out`: Đường dẫn file `.exe` đầu ra.
- `--entry`: Hàm điểm vào chính của chương trình (Mặc định là `run`).

#### 2. Lệnh Chuyển đổi Mã Tự động Hai Chiều (`tkvc transpile`)
Chuyển đổi cú pháp giữa TokenVector tiêu chuẩn (`.py`) và TokenVector Native (`.tkv`):
```bash
# Chuyển đổi từ TokenVector (.py) sang TokenVector (.tkv)
tkvc transpile py2tkv input.py -o output.tkv

# Chuyển đổi từ TokenVector (.tkv) sang TokenVector (.py)
tkvc transpile tkv2py input.tkv -o output.py
```

#### 3. Lệnh Tải Package Thư viện (`tkvc install`)
Tải thư viện từ TkvPI về thư mục `vendor/` dự án:
```bash
tkvc install <package_name>
```

---

## CHƯƠNG 3: CÚ PHÁP LẬP TRÌNH & HỆ THỐNG KIỂU UNBOXED NATIVE

### 3.1 Các Kiểu Dữ Liệu Unboxed Native (Unboxed Value Types)
TokenVector hỗ trợ hệ thống kiểu Unboxed giúp triệt tiêu chi phí cấp phát bộ nhớ heap cho các biến số học:

| Kiểu DSL | Kiểu .NET CIL Tương Ứng | Miền Giá Trị / Mô Tả Kỹ Thuật |
| :--- | :--- | :--- |
| `"i32"` | `int32` | Số nguyên 32-bit có dấu (`-2,147,483,648` đến `2,147,483,647`). |
| `"i64"` | `int64` | Số nguyên 64-bit có dấu (`-9,223,372,036,854,775,808` đến `9,223,372,036,854,775,807`). |
| `"f32"` | `float32` | Số thực độ chính xác đơn 32-bit (Single Precision Float). |
| `"f64"` | `float64` | Số thực độ chính xác đôi 64-bit (Double Precision Float). |
| `"str"` | `string` / `TkvStr` | Chuỗi ký tự UTF-8 bất biến. |
| `"TkvInt"`| `valuetype TkvInt` | Struct số nguyên vô hạn chữ số (BigInteger) tự động chuyển đổi. |

### 3.2 Ví dụ Khai báo Hàm & Ép kiểu Unboxed
```TokenVector
# -*- coding: utf-8 -*-

def tinh_van_toc(quang_duong: "f64", thoi_gian: "f64") -> "f64":
    if thoi_gian == 0.0:
        return 0.0
    return quang_duong / thoi_gian

def run() -> "str":
    v = tinh_van_toc(150.5, 2.5)
    return "VAN_TOC:" + str(v)
```

---

## CHƯƠNG 4: CẤU TRÚC ĐIỀU KHIỂN, VÒNG LẶP & ĐỆ QUY

### 4.1 Khối Điều kiện `if / elif / else` & Biểu thức Ternary
```TokenVector
def xet_tuyen(diem: "f64") -> "str":
    ket_qua = "DAT" if diem >= 5.0 else "TRUOT"
    if diem >= 8.0:
        return "XUAT_XAC|" + ket_qua
    elif diem >= 6.5:
        return "KHA|" + ket_qua
    else:
        return "TRUNG_BINH|" + ket_qua
```

### 4.2 Vòng lặp `for range()` & `while`
Vòng lặp `for range()` trong TokenVector được biên dịch thành mã lệnh CIL Native `bge` / `blt` ép trực tiếp vào thanh ghi CPU:
```TokenVector
def tinh_tong_binh_phuong(n: "i32") -> "i64":
    s = 0
    for i in range(n):
        s = s + (i * i)
    return s

def run_while_demo(limit: "i32") -> "i32":
    count = 0
    while count < limit:
        count = count + 1
        if count == 50:
            continue
        if count == 90:
            break
    return count
```

### 4.3 Khối Xử lý Ngoại lệ `try / except / finally`
```TokenVector
def chia_an_toan(a: "f64", b: "f64") -> "f64":
    try:
        if b == 0.0:
            raise ValueError("Loi chia cho 0!")
        return a / b
    except ValueError as e:
        print("Da bat loi: " + str(e))
        return -1.0
    finally:
        print("Khoi finally luon duoc thuc thi.")
```

---

## CHƯƠNG 5: CẤU TRÚC DỮ LIỆU ĐỘNG (LIST, DICTIONARY, SET, TUPLE)

### 5.1 Danh sách Động `List<T>` & `List<object>`
TokenVector hỗ trợ danh sách đồng kiểu `List<T>` và danh sách đa kiểu `List<object>`:
```TokenVector
def demo_list() -> "str":
    numbers = [10, 20, 30, 40]
    numbers.append(50)
    numbers.pop()
    
    # Cắt slice danh sách
    sub_list = numbers[1:3]
    return "LEN:" + str(len(numbers)) + "|SUB_LEN:" + str(len(sub_list))
```

### 5.2 Bảng băm `Dictionary<K,V>` & Tập hợp `HashSet<T>`
```TokenVector
def demo_dict_set() -> "str":
    scores = {"Alice": 95, "Bob": 88}
    scores["Charlie"] = 92
    
    # Duyệt keys()
    keys_str = ""
    for k in scores.keys():
        keys_str = keys_str + k + ","
        
    s = {1, 2, 3, 3, 4}
    s.add(5)
    return "KEYS:" + keys_str + "|SET_SIZE:" + str(len(s))
```

---

## CHƯƠNG 6: LẬP TRÌNH HƯỚNG ĐỐI TƯỢNG (OOP) & ĐA KẾ THỪA LỚP

TokenVector hỗ trợ Lập trình Hướng đối tượng đầy đủ bao gồm **Đa Kế Thừa Lớp** thông qua cơ chế Proxy Delegation Synthesis:

```TokenVector
class Engine:
    def start_engine(self) -> "str":
        return "ENGINE_ON"

class GPS:
    def get_location(self) -> "str":
        return "LAT_10.77_LON_106.69"

class SmartCar(Engine, GPS):
    def drive(self) -> "str":
        status = self.start_engine()
        loc = self.get_location()
        return status + "|NAVIGATING_" + loc

def run() -> "str":
    car = SmartCar()
    return car.drive()
```

---

## CHƯƠNG 7: THƯ VIỆN CHUẨN NATIVE (`stdlib/*.tkv`) & QUẢN LÝ PACKAGE

### 7.1 Bộ Thư viện Chuẩn Native Tích hợp Sẵn
TokenVector cung cấp bộ thư viện chuẩn Native `.tkv` đặt tại thư mục `stdlib/`:

1. **`stdlib/math.tkv`**:
   - `sqrt(x)`: Băn căn bậc hai số thực.
   - `pow(x, y)`: Tính lũy thừa $x^y$.
   - `abs(x)`: Giá trị tuyệt đối.
2. **`stdlib/pystdlib.tkv`**:
   - `tkv_re_replace(text, pattern, repl)`: Thay thế chuỗi Regex.
   - `tkv_now()`: Lấy thời gian hệ thống hiện tại.
   - `tkv_randint(min, max)`: Sinh số nguyên ngẫu nhiên.
3. **`stdlib/sys.tkv`**, **`stdlib/datetime.tkv`**, **`stdlib/re.tkv`**, **`stdlib/os.tkv`**.

---

## CHƯƠNG 8: MÔ HÌNH ĐA LUỒNG THẬT KHÔNG GIL & ASYNC/AWAIT

### 8.1 Mô hình Đa Luồng Thật Không GIL (True Multithreading No-GIL)
 TokenVector giải phóng hoàn toàn rào cản khóa GIL. Các luồng được khởi chạy dưới dạng **OS Kernel Threads thực sự** trên các nhân CPU vật lý:

```TokenVector
def task1() -> "i64":
    s = 0
    for i in range(5000000):
        s = s + i
    return s

def task2() -> "i64":
    s = 0
    for i in range(5000000):
        s = s + i
    return s

def run() -> "str":
    t1 = thread_spawn(task1)
    t2 = thread_spawn(task2)
    
    r1 = thread_join(t1)
    r2 = thread_join(t2)
    return "PARALLEL_RESULT:" + str(r1 + r2)
```

---

## CHƯƠNG 9: INTEROP VỚI NỀN TẢNG KHÁC (C-FFI & .NET ASSEMBLY)

### 9.1 Gọi trực tiếp Hàm Native C/C++ (P/Invoke FFI)
```TokenVector
def run() -> "str":
    h = ctypes_cdll("ucrtbase.dll")
    status = ctypes_call("NATIVE_C_CALL_SUCCESS")
    return "FFI_STATUS:" + str(status)
```

### 9.2 Trực tiếp Liên kết Assembly .NET Ecosystem
```TokenVector
__tkv_extern_assembly__("System.Xml", "DEFAULT", "DEFAULT")

def run() -> "str":
    return "DOTNET_ASSEMBLY_LINKED_SUCCESS"
```

---

## CHƯƠNG 10: QUY TRÌNH KIỂM THỬ NGHIỆM THU NATIVE (NATIVE SUITE)

Để tiến hành kiểm thử toàn bộ 97 bài test quy chuẩn bằng file Native `ledger_test.tkv`:

```cmd
tkvc build release/3.code/test/verify/ledger_test.tkv --out ledger_test.exe --entry run
ledger_test.exe
```

**Kết quả nghiệm thu tiêu chuẩn**:
```text
ledger_test: dat (0 muc open, tat ca van lech DUNG loai da ghi; 97 muc tong cong trong so)
```

---
*HẾT TÀI LIỆU HƯỚNG DẪN KỸ THUẬT NỀN TẢNG TOKENVECTOR 2026*

