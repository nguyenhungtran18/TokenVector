# -*- coding: utf-8 -*-
"""eval_arith(s: "str") -> "f64" - danh gia 1 BIEU THUC SO HOC trong chuoi
luc CHAY, bang cach PORT thang System.Data.DataTable.Compute cua BCL
(2026-08-03, Giai doan 2.3).

Vi sao khong tu viet parser: ban cu (eval.tkv, Pratt parser viet tay ~150
dong) CHI lam duoc so nguyen khong dau, chia lay nguyen, va phai tu bao
tri tokenizer + bang uu tien toan tu. DataTable.Compute co san trong .NET
Framework, da xu ly dung uu tien toan tu, ngoac, so thuc, so am, so sanh.
Dung tinh than "port cai da co" cua du an (giong http_get/db_* truoc do),
KHONG phat minh lai.

DA XAC MINH THAT truoc khi viet IL (PowerShell, khong doan):
    1+2*3    -> 7    (Int32)      (4+6)/4  -> 2.5  (Double)
    10 % 3   -> 1    (Int32)      -3 + 1.5 -> -1.5 (Decimal)
    2 > 1    -> True (Boolean)    7/2      -> 3.5  (Double)
Kieu tra ve KHAC NHAU tuy bieu thuc (Int32/Double/Decimal/Boolean) nen
KHONG the unbox cung 1 kieu - phai qua Convert::ToDouble(object,
IFormatProvider) voi InvariantCulture (may locale vi-VN dung dau PHAY lam
dau thap phan, tung gay bug THAT voi Single.Parse - xem STATUS.md).

KHAC Python, ghi ro khong giau:
- Chi BIEU THUC SO HOC/SO SANH. Khong bien, khong goi ham, khong chuoi,
  khong ** (luy thua) - DataTable khong co toan tu do.
- Bool tra ve 1.0/0.0 (Python tra True/False).
- Bieu thuc sai cu phap NEM exception (Python nem SyntaxError bat duoc).
- KHONG phai eval() tong quat cua Python va se KHONG BAO GIO la vay:
  chay ma nguon dong trong ngon ngu kieu tinh la buc tuong kien truc da
  ket luan loai vinh vien (xem ROADMAP.md).

Assembly 'System.Data' KHONG nam trong 3 assembly mac dinh -> file .tkv
dung ham nay phai khai bao __tkv_extern_assembly__ = "System.Data"
(eval.tkv da khai bao san)."""
from il_dispatch import register_expr_builtin


def push_eval_arith(args, scope, out, dtype, ctx):
    if len(args) != 1:
        raise SyntaxError("il_codegen: eval_arith(expr) chi nhan dung 1 tham so")
    out.append('    newobj instance void [System.Data]System.Data.DataTable::.ctor()')
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    ldstr ""')
    out.append('    callvirt instance object [System.Data]System.Data.DataTable::Compute(string, string)')
    out.append('    call class [mscorlib]System.Globalization.CultureInfo '
               '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()')
    out.append('    call float64 [mscorlib]System.Convert::ToDouble(object, '
               'class [mscorlib]System.IFormatProvider)')


register_expr_builtin('eval_arith', push_eval_arith, 'f64')
