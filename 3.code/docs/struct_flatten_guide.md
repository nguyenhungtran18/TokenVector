# Struct lồng nhau / fixed-array: flatten tay (quy ước P2, 2026-09-23)

`__tkv_struct__` v1 CHỈ nhận field vô hướng blittable
(`i16/i32/i64/f32/f64`) — struct lồng nhau, fixed-array (`T[N]`),
`bool/str` đều bị từ chối ồn ào lúc validate. Lý do: CLR `sequential`
tự pad/căn theo packing của JIT — compiler không đoán offset tay
(không `pack=`/`FieldOffset`), nhúng valuetype + offset thủ công dễ
lệch với native (X11/Vulkan) mà pinvoke 2-chiều không chịu được.

Quy ước: **flatten tay** — khai 1 struct phẳng tương đương layout.

## Ví dụ: XRectangle (X11) lồng XPoint

C gốc:

```c
typedef struct { int x, y; } XPoint;
typedef struct { XPoint pos; int w, h; } XRect;
typedef struct { char name[16]; int id; } Named;   // fixed-array
```

Khai TokenVector (phẳng, đúng thứ tự C):

```tkv
__tkv_struct__ = [
    {"name": "XRect", "fields": [["pos_x", "i32"], ["pos_y", "i32"],
                                 ["w", "i32"], ["h", "i32"]]},
    {"name": "Named", "fields": [["n0", "i32"], ["n1", "i32"],
                                 ["n2", "i32"], ["n3", "i32"],
                                 ["id", "i32"]]},
]
```

- `pos` lồng → `pos_x/pos_y` (giữ thứ tự field C).
- `char name[16]` → 4 × `i32` (`n0..n3`, đủ 16 bytes, đúng alignment
  `i32` — thay `char` bằng khối 4-byte, đọc/ghi từng khối).
- Truyền pinvoke như struct thường (`XRect*`, `valuetype XRect&`).

## Khi nào KHÔNG flatten được

- Union/overlay (2 field chung offset) — struct v1 không biểu diễn được,
  tách 2 struct riêng hoặc chờ embedded valuetype (chưa lên lịch).
- `T[N]` với N lẻ theo `i16` (vd `short[3]` = 6 bytes + pad) — pad tay
  bằng field `i16` đệm cho đủ bội số alignment lớn nhất.

## Đọc/ghi

Như struct thường (`r.pos_x`, `r.pos_x = 10` — `ldfld`/`stfld`,
`i16` suy về `i32` trên stack). Không có `.ctor` lồng — `new_XRect(a,
b, c, d)` nhận đủ field phẳng theo thứ tự khai báo.
