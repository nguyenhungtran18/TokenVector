.assembly extern mscorlib {}
.assembly probe_lambda_closure {}
.module probe_lambda_closure.exe

// __LambdaClosure_1: bat 2 bien - 1 scalar (int32 'a') BANG GIA TRI TRUC
// TIEP (khong qua cell/boxed nhu nested_def that), 1 kieu tham chieu
// (class List<int32> 'lst') cung BANG GIA TRI TRUC TIEP (tham chieu).
// Gia thuyet dang kiem chung: capture-by-value (khong cell) DU DUNG cho
// truong hop lambda dung NGAY LAP TUC lam tham so goi ham (khong luu lai
// qua bien/tra ve ngoai ham) - vi khong co "sau nay" de gia tri cu the
// thay doi truoc khi goi.
.class public auto ansi __LambdaClosure_1 extends [mscorlib]System.Object
{
  .field public int32 a
  .field public class [mscorlib]System.Collections.Generic.List`1<int32> lst

  .method public hidebysig specialname rtspecialname instance void
      .ctor(int32 a0, class [mscorlib]System.Collections.Generic.List`1<int32> lst0) cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.1
    stfld int32 __LambdaClosure_1::a
    ldarg.0
    ldarg.2
    stfld class [mscorlib]System.Collections.Generic.List`1<int32> __LambdaClosure_1::lst
    ret
  }

  // than lambda that su: return x + a + sum(lst)
  .method public hidebysig instance int32 invoke(int32 x) cil managed
  {
    .maxstack 8
    .locals init (int32 total, int32 i, class [mscorlib]System.Collections.Generic.List`1<int32> l)
    ldarg.0
    ldfld class [mscorlib]System.Collections.Generic.List`1<int32> __LambdaClosure_1::lst
    stloc.s l
    ldc.i4.0
    stloc.s total
    ldc.i4.0
    stloc.s i
  SUM_LOOP:
    ldloc.s i
    ldloc.s l
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Count()
    bge SUM_DONE
    ldloc.s total
    ldloc.s l
    ldloc.s i
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    add
    stloc.s total
    ldloc.s i
    ldc.i4.1
    add
    stloc.s i
    br SUM_LOOP
  SUM_DONE:
    ldarg.1
    ldarg.0
    ldfld int32 __LambdaClosure_1::a
    add
    ldloc.s total
    add
    ret
  }
}

.method public static int32 apply_int(class [mscorlib]System.Func`2<int32,int32> f, int32 x) cil managed
{
  .maxstack 8
  ldarg.0
  ldarg.1
  callvirt instance !1 class [mscorlib]System.Func`2<int32,int32>::Invoke(!0)
  ret
}

.method public static void Main() cil managed
{
  .entrypoint
  .maxstack 8
  .locals init (int32 a, class [mscorlib]System.Collections.Generic.List`1<int32> lst,
                class __LambdaClosure_1 closure_inst, class [mscorlib]System.Func`2<int32,int32> f,
                int32 result)

  // a = 10
  ldc.i4.s 10
  stloc.s a

  // lst = [1,2,3]
  newobj instance void class [mscorlib]System.Collections.Generic.List`1<int32>::.ctor()
  stloc.s lst
  ldloc.s lst
  ldc.i4.1
  callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::Add(!0)
  ldloc.s lst
  ldc.i4.2
  callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::Add(!0)
  ldloc.s lst
  ldc.i4.3
  callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::Add(!0)

  // Truoc khi tao closure, DOI GIA TRI cua 'a' NGAY SAU do de kiem tra
  // xem closure co "chup anh" gia tri hien tai luc tao (dung, du kien) hay
  // bam theo bien sau nay (khong dung voi thiet ke direct-capture).
  // O DAY ta MO PHONG dung use case thuc te: tao closure roi GOI NGAY,
  // KHONG doi 'a' o giua - phan kiem tra "khong doi giua chung" nam o
  // probe thu 2 ben duoi (Main2-style) neu can, o day chi xac nhan luong
  // co ban dung.

  // closure_inst = new __LambdaClosure_1(a, lst)
  ldloc.s a
  ldloc.s lst
  newobj instance void __LambdaClosure_1::.ctor(int32, class [mscorlib]System.Collections.Generic.List`1<int32>)
  stloc.s closure_inst

  // f = new Func<int32,int32>(closure_inst, ldftn invoke)
  ldloc.s closure_inst
  ldftn instance int32 __LambdaClosure_1::invoke(int32)
  newobj instance void class [mscorlib]System.Func`2<int32,int32>::.ctor(object, native int)
  stloc.s f

  // result = apply_int(f, 100)  ->  100 + 10 + (1+2+3) = 116
  ldloc.s f
  ldc.i4.s 100
  call int32 apply_int(class [mscorlib]System.Func`2<int32,int32>, int32)
  stloc.s result

  ldloc.s result
  call void [mscorlib]System.Console::WriteLine(int32)
  ret
}
