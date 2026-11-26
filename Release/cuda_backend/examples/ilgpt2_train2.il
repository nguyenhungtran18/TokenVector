.assembly extern mscorlib {}
.assembly extern System.Core { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly extern System { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly extern System.Numerics { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly TKVApp {}
.module TKVApp.exe

.class public sequential ansi sealed beforefieldinit TkvInt
       extends [mscorlib]System.ValueType
       implements class [mscorlib]System.IComparable`1<valuetype TkvInt>, [mscorlib]System.IComparable
{
  .field public int64 lo
  .field public object big
  .method public static valuetype TkvInt FromI64(int64 v) cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt r)
    ldloca.s r
    ldarg.0
    stfld int64 TkvInt::lo
    ldloca.s r
    ldnull
    stfld object TkvInt::big
    ldloc.s r
    ret
  }
  .method public static valuetype TkvInt FromStr(string s) cil managed
  {
    .maxstack 8
    ldarg.0
    ldc.i4.7
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::Parse(string, valuetype [mscorlib]System.Globalization.NumberStyles, class [mscorlib]System.IFormatProvider)
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static valuetype TkvInt FromBig(valuetype [System.Numerics]System.Numerics.BigInteger b) cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt r)
    ldarg.0
    ldc.i8 0x8000000000000000
    call bool [System.Numerics]System.Numerics.BigInteger::op_GreaterThanOrEqual(valuetype [System.Numerics]System.Numerics.BigInteger, int64)
    brfalse.s BIGPATH
    ldarg.0
    ldc.i8 0x7FFFFFFFFFFFFFFF
    call bool [System.Numerics]System.Numerics.BigInteger::op_LessThanOrEqual(valuetype [System.Numerics]System.Numerics.BigInteger, int64)
    brfalse.s BIGPATH
    ldloca.s r
    ldarg.0
    call int64 [System.Numerics]System.Numerics.BigInteger::op_Explicit(valuetype [System.Numerics]System.Numerics.BigInteger)
    stfld int64 TkvInt::lo
    ldloca.s r
    ldnull
    stfld object TkvInt::big
    ldloc.s r
    ret
  BIGPATH:
    ldloca.s r
    ldc.i8 0
    stfld int64 TkvInt::lo
    ldloca.s r
    ldarg.0
    box [System.Numerics]System.Numerics.BigInteger
    stfld object TkvInt::big
    ldloc.s r
    ret
  }
  .method public static valuetype [System.Numerics]System.Numerics.BigInteger ToBig(valuetype TkvInt a) cil managed
  {
    .maxstack 8
    ldarga.s a
    ldfld object TkvInt::big
    brfalse.s FASTPATH
    ldarga.s a
    ldfld object TkvInt::big
    unbox.any [System.Numerics]System.Numerics.BigInteger
    ret
  FASTPATH:
    ldarga.s a
    ldfld int64 TkvInt::lo
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_Implicit(int64)
    ret
  }
  .method public static valuetype TkvInt AddSlow(valuetype TkvInt a, valuetype TkvInt b) cil managed
  {
    .maxstack 8
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    ldarg.1
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_Addition(valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger)
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static valuetype TkvInt SubSlow(valuetype TkvInt a, valuetype TkvInt b) cil managed
  {
    .maxstack 8
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    ldarg.1
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_Subtraction(valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger)
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static valuetype TkvInt MulSlow(valuetype TkvInt a, valuetype TkvInt b) cil managed
  {
    .maxstack 8
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    ldarg.1
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_Multiply(valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger)
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static int32 Cmp(valuetype TkvInt a, valuetype TkvInt b) cil managed
  {
    .maxstack 8
    .locals init (int64 x)
    ldarga.s a
    ldfld object TkvInt::big
    brtrue.s SLOWPATH
    ldarga.s b
    ldfld object TkvInt::big
    brtrue.s SLOWPATH
    ldarga.s a
    ldfld int64 TkvInt::lo
    stloc.s x
    ldloca.s x
    ldarga.s b
    ldfld int64 TkvInt::lo
    call instance int32 [mscorlib]System.Int64::CompareTo(int64)
    ret
  SLOWPATH:
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    ldarg.1
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    call int32 [System.Numerics]System.Numerics.BigInteger::Compare(valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static string Str(valuetype TkvInt a) cil managed
  {
    .maxstack 8
    .locals init (int64 x, valuetype [System.Numerics]System.Numerics.BigInteger b)
    ldarga.s a
    ldfld object TkvInt::big
    brtrue.s SLOWPATH
    ldarga.s a
    ldfld int64 TkvInt::lo
    stloc.s x
    ldloca.s x
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string [mscorlib]System.Int64::ToString(class [mscorlib]System.IFormatProvider)
    ret
  SLOWPATH:
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    stloc.s b
    ldloca.s b
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string [System.Numerics]System.Numerics.BigInteger::ToString(class [mscorlib]System.IFormatProvider)
    ret
  }
  .method public static int32 ToI32(valuetype TkvInt a) cil managed
  {
    .maxstack 8
    ldarga.s a
    ldfld object TkvInt::big
    brtrue TOI32_BIG
    ldarga.s a
    ldfld int64 TkvInt::lo
    conv.ovf.i4
    ret
  TOI32_BIG:
    ldstr "chi so int qua lon: khong vua int32."
    newobj instance void [mscorlib]System.OverflowException::.ctor(string)
    throw
  }
  .method public static int64 ToI64(valuetype TkvInt a) cil managed
  {
    .maxstack 8
    ldarga.s a
    ldfld object TkvInt::big
    brtrue TOI64_BIG
    ldarga.s a
    ldfld int64 TkvInt::lo
    ret
  TOI64_BIG:
    ldstr "gia tri int qua lon: khong vua int64."
    newobj instance void [mscorlib]System.OverflowException::.ctor(string)
    throw
  }
  .method public static float64 ToF64(valuetype TkvInt a) cil managed
  {
    .maxstack 8
    .locals init (valuetype [System.Numerics]System.Numerics.BigInteger b, float64 d)
    ldarga.s a
    ldfld object TkvInt::big
    brtrue TOF64_BIG
    ldarga.s a
    ldfld int64 TkvInt::lo
    conv.r8
    ret
  TOF64_BIG:
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    stloc.s b
    ldloc.s b
    call float64 [System.Numerics]System.Numerics.BigInteger::op_Explicit(valuetype [System.Numerics]System.Numerics.BigInteger)
    stloc.s d
    ldloc.s d
    call bool [mscorlib]System.Double::IsInfinity(float64)
    brtrue TOF64_OVF
    ldloc.s d
    ret
  TOF64_OVF:
    ldstr "gia tri int qua lon de chuyen thanh float."
    newobj instance void [mscorlib]System.OverflowException::.ctor(string)
    throw
  }
  .method public hidebysig newslot virtual final instance int32 CompareTo(valuetype TkvInt other) cil managed
  {
    .maxstack 8
    .override method instance int32 class [mscorlib]System.IComparable`1<valuetype TkvInt>::CompareTo(!0)
    ldarg.0
    ldobj valuetype TkvInt
    ldarg.1
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ret
  }
  .method public hidebysig newslot virtual final instance int32 CompareTo(object other) cil managed
  {
    .maxstack 8
    .override [mscorlib]System.IComparable::CompareTo
    ldarg.0
    ldobj valuetype TkvInt
    ldarg.1
    unbox.any valuetype TkvInt
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ret
  }
  .method public static valuetype TkvInt FloorDiv(valuetype TkvInt a, valuetype TkvInt b) cil managed
  {
    .maxstack 8
    .locals init (int64 x, int64 y, int64 q, int64 r, valuetype [System.Numerics]System.Numerics.BigInteger ba, valuetype [System.Numerics]System.Numerics.BigInteger bb, valuetype [System.Numerics]System.Numerics.BigInteger bq, valuetype [System.Numerics]System.Numerics.BigInteger bdu)
    ldarga.s a
    ldfld object TkvInt::big
    brtrue FD_SLOW
    ldarga.s b
    ldfld object TkvInt::big
    brtrue FD_SLOW
    ldarga.s a
    ldfld int64 TkvInt::lo
    stloc.s x
    ldarga.s b
    ldfld int64 TkvInt::lo
    stloc.s y
    ldloc.s y
    ldc.i8 0
    beq FD_SLOW
    ldloc.s y
    ldc.i8 -1
    beq FD_SLOW
    ldloc.s x
    ldloc.s y
    div
    stloc.s q
    ldloc.s x
    ldloc.s y
    rem
    stloc.s r
    ldloc.s r
    ldc.i8 0
    beq FD_FAST_DONE
    ldloc.s x
    ldloc.s y
    xor
    ldc.i8 0
    bge FD_FAST_DONE
    ldloc.s q
    ldc.i8 1
    sub
    stloc.s q
  FD_FAST_DONE:
    ldloc.s q
    call valuetype TkvInt TkvInt::FromI64(int64)
    ret
  FD_SLOW:
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    stloc.s ba
    ldarg.1
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    stloc.s bb
    ldloc.s ba
    ldloc.s bb
    ldloca.s bdu
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::DivRem(valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger&)
    stloc.s bq
    ldloca.s bdu
    call instance int32 [System.Numerics]System.Numerics.BigInteger::get_Sign()
    ldc.i4.0
    beq FD_SLOW_DONE
    ldloca.s bdu
    call instance int32 [System.Numerics]System.Numerics.BigInteger::get_Sign()
    ldloca.s bb
    call instance int32 [System.Numerics]System.Numerics.BigInteger::get_Sign()
    beq FD_SLOW_DONE
    ldloc.s bq
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::get_One()
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_Subtraction(valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger)
    stloc.s bq
  FD_SLOW_DONE:
    ldloc.s bq
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static valuetype TkvInt Mod(valuetype TkvInt a, valuetype TkvInt b) cil managed
  {
    .maxstack 8
    .locals init (int64 x, int64 y, int64 q, int64 r, valuetype [System.Numerics]System.Numerics.BigInteger ba, valuetype [System.Numerics]System.Numerics.BigInteger bb, valuetype [System.Numerics]System.Numerics.BigInteger bq, valuetype [System.Numerics]System.Numerics.BigInteger bdu)
    ldarga.s a
    ldfld object TkvInt::big
    brtrue MD_SLOW
    ldarga.s b
    ldfld object TkvInt::big
    brtrue MD_SLOW
    ldarga.s a
    ldfld int64 TkvInt::lo
    stloc.s x
    ldarga.s b
    ldfld int64 TkvInt::lo
    stloc.s y
    ldloc.s y
    ldc.i8 0
    beq MD_SLOW
    ldloc.s y
    ldc.i8 -1
    beq MD_SLOW
    ldloc.s x
    ldloc.s y
    rem
    stloc.s r
    ldloc.s r
    ldc.i8 0
    beq MD_FAST_DONE
    ldloc.s r
    ldloc.s y
    xor
    ldc.i8 0
    bge MD_FAST_DONE
    ldloc.s r
    ldloc.s y
    add
    stloc.s r
  MD_FAST_DONE:
    ldloc.s r
    call valuetype TkvInt TkvInt::FromI64(int64)
    ret
  MD_SLOW:
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    stloc.s ba
    ldarg.1
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    stloc.s bb
    ldloc.s ba
    ldloc.s bb
    ldloca.s bdu
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::DivRem(valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger&)
    stloc.s bq
    ldloca.s bdu
    call instance int32 [System.Numerics]System.Numerics.BigInteger::get_Sign()
    ldc.i4.0
    beq MD_SLOW_DONE
    ldloca.s bdu
    call instance int32 [System.Numerics]System.Numerics.BigInteger::get_Sign()
    ldloca.s bb
    call instance int32 [System.Numerics]System.Numerics.BigInteger::get_Sign()
    beq MD_SLOW_DONE
    ldloc.s bdu
    ldloc.s bb
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_Addition(valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger)
    stloc.s bdu
  MD_SLOW_DONE:
    ldloc.s bdu
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static valuetype TkvInt Pow(valuetype TkvInt a, valuetype TkvInt b) cil managed
  {
    .maxstack 8
    .locals init (int64 e)
    ldarga.s b
    ldfld object TkvInt::big
    brtrue PW_HUGE
    ldarga.s b
    ldfld int64 TkvInt::lo
    stloc.s e
    ldloc.s e
    ldc.i8 0
    blt PW_NEG
    ldloc.s e
    ldc.i8 2147483647
    bgt PW_HUGE
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    ldloc.s e
    conv.i4
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::Pow(valuetype [System.Numerics]System.Numerics.BigInteger, int32)
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  PW_NEG:
    ldstr "int ** so mu am tra ve float trong Python - TokenVector chua co duong int->float (moc 10). Doi ve f64 truoc khi luy thua."
    newobj instance void [mscorlib]System.NotSupportedException::.ctor(string)
    throw
  PW_HUGE:
    ldstr "int ** so mu qua lon (> 2^31-1): ket qua khong the vua bo nho."
    newobj instance void [mscorlib]System.OverflowException::.ctor(string)
    throw
  }
  .method public static valuetype TkvInt Neg(valuetype TkvInt a) cil managed
  {
    .maxstack 8
    .locals init (int64 x)
    ldarga.s a
    ldfld object TkvInt::big
    brtrue NG_SLOW
    ldarga.s a
    ldfld int64 TkvInt::lo
    stloc.s x
    ldloc.s x
    ldc.i8 0x8000000000000000
    beq NG_SLOW
    ldc.i8 0
    ldloc.s x
    sub
    call valuetype TkvInt TkvInt::FromI64(int64)
    ret
  NG_SLOW:
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::Negate(valuetype [System.Numerics]System.Numerics.BigInteger)
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static valuetype TkvInt Add(valuetype TkvInt a, valuetype TkvInt b) cil managed
  {
    .maxstack 8
    .locals init (int64 x, int64 y, int64 r)
    ldarga.s a
    ldfld object TkvInt::big
    brtrue AD_SLOW
    ldarga.s b
    ldfld object TkvInt::big
    brtrue AD_SLOW
    ldarga.s a
    ldfld int64 TkvInt::lo
    stloc.s x
    ldarga.s b
    ldfld int64 TkvInt::lo
    stloc.s y
    ldloc.s x
    ldloc.s y
    add
    stloc.s r
    ldloc.s x
    ldloc.s r
    xor
    ldloc.s y
    ldloc.s r
    xor
    and
    ldc.i8 0
    blt AD_SLOW
    ldloc.s r
    call valuetype TkvInt TkvInt::FromI64(int64)
    ret
  AD_SLOW:
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    ldarg.1
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_Addition(valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger)
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static valuetype TkvInt Abs(valuetype TkvInt a) cil managed
  {
    .maxstack 8
    .locals init (int64 x)
    ldarga.s a
    ldfld object TkvInt::big
    brtrue AB_SLOW
    ldarga.s a
    ldfld int64 TkvInt::lo
    stloc.s x
    ldloc.s x
    ldc.i8 0
    bge AB_POS
    ldloc.s x
    ldc.i8 0x8000000000000000
    beq AB_SLOW
    ldc.i8 0
    ldloc.s x
    sub
    call valuetype TkvInt TkvInt::FromI64(int64)
    ret
  AB_POS:
    ldarg.0
    ret
  AB_SLOW:
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::Abs(valuetype [System.Numerics]System.Numerics.BigInteger)
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static valuetype TkvInt FromF64(float64 d) cil managed
  {
    .maxstack 8
    ldarg.0
    newobj instance void [System.Numerics]System.Numerics.BigInteger::.ctor(float64)
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static int32 IsZero(valuetype TkvInt a) cil managed
  {
    .maxstack 8
    ldarga.s a
    ldfld object TkvInt::big
    brtrue IZ_BIG
    ldarga.s a
    ldfld int64 TkvInt::lo
    ldc.i8 0
    ceq
    ret
  IZ_BIG:
    ldc.i4.0
    ret
  }
  .method public static valuetype TkvInt BitAnd(valuetype TkvInt a, valuetype TkvInt b) cil managed
  {
    .maxstack 8
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    ldarg.1
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_BitwiseAnd(valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger)
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static valuetype TkvInt BitOr(valuetype TkvInt a, valuetype TkvInt b) cil managed
  {
    .maxstack 8
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    ldarg.1
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_BitwiseOr(valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger)
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static valuetype TkvInt BitXor(valuetype TkvInt a, valuetype TkvInt b) cil managed
  {
    .maxstack 8
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    ldarg.1
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_ExclusiveOr(valuetype [System.Numerics]System.Numerics.BigInteger, valuetype [System.Numerics]System.Numerics.BigInteger)
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static valuetype TkvInt Shl(valuetype TkvInt a, valuetype TkvInt b) cil managed
  {
    .maxstack 8
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    ldarg.1
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    call int32 [System.Numerics]System.Numerics.BigInteger::op_Explicit(valuetype [System.Numerics]System.Numerics.BigInteger)
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_LeftShift(valuetype [System.Numerics]System.Numerics.BigInteger, int32)
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
  .method public static valuetype TkvInt Shr(valuetype TkvInt a, valuetype TkvInt b) cil managed
  {
    .maxstack 8
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    ldarg.1
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    call int32 [System.Numerics]System.Numerics.BigInteger::op_Explicit(valuetype [System.Numerics]System.Numerics.BigInteger)
    call valuetype [System.Numerics]System.Numerics.BigInteger [System.Numerics]System.Numerics.BigInteger::op_RightShift(valuetype [System.Numerics]System.Numerics.BigInteger, int32)
    call valuetype TkvInt TkvInt::FromBig(valuetype [System.Numerics]System.Numerics.BigInteger)
    ret
  }
}
.class public abstract sealed auto ansi TkvStr
       extends [mscorlib]System.Object
{
  .method public static string I32(int32 v) cil managed
  {
    .maxstack 8
    ldarga.s 0
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string [mscorlib]System.Int32::ToString(class [mscorlib]System.IFormatProvider)
    ret
  }
  .method public static string I64(int64 v) cil managed
  {
    .maxstack 8
    ldarga.s 0
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string [mscorlib]System.Int64::ToString(class [mscorlib]System.IFormatProvider)
    ret
  }
  .method public static string Bool(int32 v) cil managed
  {
    .maxstack 8
    ldarg.0
    brfalse BOOL_FALSE
    ldstr "True"
    ret
  BOOL_FALSE:
    ldstr "False"
    ret
  }
  .method public static string F64(float64 v) cil managed
  {
    .maxstack 8
    .locals init (string s)
    ldarg.0
    call bool [mscorlib]System.Double::IsNaN(float64)
    brfalse F64_NOTNAN
    ldstr "nan"
    ret
  F64_NOTNAN:
    ldarg.0
    call bool [mscorlib]System.Double::IsInfinity(float64)
    brfalse F64_NOTINF
    ldarg.0
    ldc.r8 0.0
    blt F64_NEGINF
    ldstr "inf"
    ret
  F64_NEGINF:
    ldstr "-inf"
    ret
  F64_NOTINF:
    ldarg.0
    ldc.r8 0.0
    bne.un F64_NOTZERO
    ldarg.0
    call int64 [mscorlib]System.BitConverter::DoubleToInt64Bits(float64)
    ldc.i8 0
    blt F64_NEGZERO
    ldstr "0.0"
    ret
  F64_NEGZERO:
    ldstr "-0.0"
    ret
  F64_NOTZERO:
    ldarga.s 0
    ldstr "G15"
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string [mscorlib]System.Double::ToString(string, class [mscorlib]System.IFormatProvider)
    stloc.s s
    ldloc.s s
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call float64 [mscorlib]System.Double::Parse(string, class [mscorlib]System.IFormatProvider)
    ldarg.0
    beq LAD_DONE
    ldarga.s 0
    ldstr "G16"
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string [mscorlib]System.Double::ToString(string, class [mscorlib]System.IFormatProvider)
    stloc.s s
    ldloc.s s
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call float64 [mscorlib]System.Double::Parse(string, class [mscorlib]System.IFormatProvider)
    ldarg.0
    beq LAD_DONE
    ldarga.s 0
    ldstr "G17"
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string [mscorlib]System.Double::ToString(string, class [mscorlib]System.IFormatProvider)
    stloc.s s
  LAD_DONE:
    ldloc.s s
    call string TkvStr::Post(string)
    ret
  }
  .method public static string F32(float32 v) cil managed
  {
    .maxstack 8
    .locals init (string s)
    ldarg.0
    call bool [mscorlib]System.Single::IsNaN(float32)
    brfalse F32_NOTNAN
    ldstr "nan"
    ret
  F32_NOTNAN:
    ldarg.0
    call bool [mscorlib]System.Single::IsInfinity(float32)
    brfalse F32_NOTINF
    ldarg.0
    ldc.r4 0.0
    blt F32_NEGINF
    ldstr "inf"
    ret
  F32_NEGINF:
    ldstr "-inf"
    ret
  F32_NOTINF:
    ldarga.s 0
    ldstr "G7"
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string [mscorlib]System.Single::ToString(string, class [mscorlib]System.IFormatProvider)
    stloc.s s
    ldloc.s s
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call float32 [mscorlib]System.Single::Parse(string, class [mscorlib]System.IFormatProvider)
    ldarg.0
    beq LAD_DONE
    ldarga.s 0
    ldstr "G8"
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string [mscorlib]System.Single::ToString(string, class [mscorlib]System.IFormatProvider)
    stloc.s s
    ldloc.s s
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call float32 [mscorlib]System.Single::Parse(string, class [mscorlib]System.IFormatProvider)
    ldarg.0
    beq LAD_DONE
    ldarga.s 0
    ldstr "G9"
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string [mscorlib]System.Single::ToString(string, class [mscorlib]System.IFormatProvider)
    stloc.s s
  LAD_DONE:
    ldloc.s s
    call string TkvStr::Post(string)
    ret
  }
  .method public static string Post(string s) cil managed
  {
    .maxstack 8
    .locals init (int32 i, int32 e)
    ldarg.0
    ldc.i4 69
    callvirt instance int32 [mscorlib]System.String::IndexOf(char)
    stloc.s i
    ldloc.s i
    ldc.i4.0
    blt PS_NOEXP
    ldarg.0
    ldloc.s i
    ldc.i4.1
    add
    callvirt instance string [mscorlib]System.String::Substring(int32)
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call int32 [mscorlib]System.Int32::Parse(string, class [mscorlib]System.IFormatProvider)
    stloc.s e
    ldloc.s e
    ldc.i4 15
    bne.un PS_LOWER
    ldarg.0
    ldloc.s i
    call string TkvStr::Expand16(string, int32)
    ret
  PS_LOWER:
    ldarg.0
    ldstr "E"
    ldstr "e"
    callvirt instance string [mscorlib]System.String::Replace(string, string)
    ret
  PS_NOEXP:
    ldarg.0
    ldstr "."
    callvirt instance bool [mscorlib]System.String::Contains(string)
    brtrue PS_ASIS
    ldarg.0
    ldstr ".0"
    call string [mscorlib]System.String::Concat(string, string)
    ret
  PS_ASIS:
    ldarg.0
    ret
  }
  .method public static string Expand16(string s, int32 epos) cil managed
  {
    .maxstack 8
    .locals init (string sign, string mant, string digs, string frac)
    ldstr ""
    stloc.s sign
    ldarg.0
    ldc.i4.0
    ldarg.1
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s mant
    ldloc.s mant
    ldstr "-"
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    brfalse EX_NOSIGN
    ldstr "-"
    stloc.s sign
    ldloc.s mant
    ldc.i4.1
    callvirt instance string [mscorlib]System.String::Substring(int32)
    stloc.s mant
  EX_NOSIGN:
    ldloc.s mant
    ldstr "."
    ldstr ""
    callvirt instance string [mscorlib]System.String::Replace(string, string)
    stloc.s digs
    ldloc.s digs
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 16
    bgt EX_LONG
    ldloc.s digs
    ldc.i4 16
    ldc.i4 48
    callvirt instance string [mscorlib]System.String::PadRight(int32, char)
    stloc.s digs
    ldstr "0"
    stloc.s frac
    br EX_JOIN
  EX_LONG:
    ldloc.s digs
    ldc.i4 16
    callvirt instance string [mscorlib]System.String::Substring(int32)
    stloc.s frac
    ldloc.s digs
    ldc.i4.0
    ldc.i4 16
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s digs
  EX_JOIN:
    ldloc.s sign
    ldloc.s digs
    ldstr "."
    ldloc.s frac
    call string [mscorlib]System.String::Concat(string, string, string, string)
    ret
  }
  .method public static float64 ParseF64(string s) cil managed
  {
    .maxstack 8
    .locals init (string t)
    ldarg.0
    callvirt instance string [mscorlib]System.String::Trim()
    callvirt instance string [mscorlib]System.String::ToLowerInvariant()
    stloc.s t
    ldloc.s t
    ldstr "inf"
    call bool [mscorlib]System.String::op_Equality(string, string)
    brtrue PF_INF
    ldloc.s t
    ldstr "infinity"
    call bool [mscorlib]System.String::op_Equality(string, string)
    brtrue PF_INF
    ldloc.s t
    ldstr "+inf"
    call bool [mscorlib]System.String::op_Equality(string, string)
    brtrue PF_INF
    ldloc.s t
    ldstr "-inf"
    call bool [mscorlib]System.String::op_Equality(string, string)
    brtrue PF_NEGINF
    ldloc.s t
    ldstr "-infinity"
    call bool [mscorlib]System.String::op_Equality(string, string)
    brtrue PF_NEGINF
    ldloc.s t
    ldstr "nan"
    call bool [mscorlib]System.String::op_Equality(string, string)
    brtrue PF_NAN
    ldarg.0
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call float64 [mscorlib]System.Double::Parse(string, class [mscorlib]System.IFormatProvider)
    ret
  PF_INF:
    ldc.r8 (00 00 00 00 00 00 F0 7F)
    ret
  PF_NEGINF:
    ldc.r8 (00 00 00 00 00 00 F0 FF)
    ret
  PF_NAN:
    ldc.r8 (00 00 00 00 00 00 F8 FF)
    ret
  }
  .method public static string Replace(string src, string oldStr, string newStr) cil managed
  {
    .maxstack 8
    .locals init (int32 i, int32 n, class [mscorlib]System.Text.StringBuilder sb)
    ldarg.1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    brtrue RP_NORMAL
    ldarg.0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    stloc.s n
    ldloc.s n
    ldc.i4.1
    add
    ldarg.2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    mul
    ldloc.s n
    add
    newobj instance void [mscorlib]System.Text.StringBuilder::.ctor(int32)
    stloc.s sb
    ldc.i4.0
    stloc.s i
  RP_LOOP:
    ldloc.s i
    ldloc.s n
    bge RP_TAIL
    ldloc.s sb
    ldarg.2
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
    pop
    ldloc.s sb
    ldarg.0
    ldloc.s i
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(char)
    pop
    ldloc.s i
    ldc.i4.1
    add
    stloc.s i
    br RP_LOOP
  RP_TAIL:
    ldloc.s sb
    ldarg.2
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
    pop
    ldloc.s sb
    callvirt instance string [mscorlib]System.Text.StringBuilder::ToString()
    ret
  RP_NORMAL:
    ldarg.0
    ldarg.1
    ldarg.2
    callvirt instance string [mscorlib]System.String::Replace(string, string)
    ret
  }
  .method public static string ReplaceCount(string src, string oldStr, string newStr, int32 count) cil managed
  {
    .maxstack 8
    .locals init (int32 i, int32 n, int32 pos, int32 replaced, int32 idx, class [mscorlib]System.Text.StringBuilder sb)
    ldarg.3
    ldc.i4.0
    bge RC_NONNEG
    ldarg.0
    ldarg.1
    ldarg.2
    call string TkvStr::Replace(string, string, string)
    ret
  RC_NONNEG:
    ldarg.1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    brtrue RC_OLDNONEMPTY
    ldarg.0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    stloc.s n
    newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()
    stloc.s sb
    ldc.i4.0
    stloc.s i
  RC_EMPTY_LOOP:
    ldloc.s i
    ldarg.3
    bge RC_EMPTY_TAIL
    ldloc.s i
    ldloc.s n
    bge RC_EMPTY_TAIL
    ldloc.s sb
    ldarg.2
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
    pop
    ldloc.s sb
    ldarg.0
    ldloc.s i
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(char)
    pop
    ldloc.s i
    ldc.i4.1
    add
    stloc.s i
    br RC_EMPTY_LOOP
  RC_EMPTY_TAIL:
    ldarg.3
    ldloc.s n
    ble RC_EMPTY_NOEXTRA
    ldloc.s sb
    ldarg.2
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
    pop
  RC_EMPTY_NOEXTRA:
    ldloc.s sb
    ldarg.0
    ldloc.s i
    callvirt instance string [mscorlib]System.String::Substring(int32)
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
    pop
    ldloc.s sb
    callvirt instance string [mscorlib]System.Text.StringBuilder::ToString()
    ret
  RC_OLDNONEMPTY:
    ldc.i4.0
    stloc.s pos
    ldc.i4.0
    stloc.s replaced
    newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()
    stloc.s sb
  RC_LOOP:
    ldloc.s replaced
    ldarg.3
    bge RC_TAIL
    ldarg.0
    ldarg.1
    ldloc.s pos
    callvirt instance int32 [mscorlib]System.String::IndexOf(string, int32)
    stloc.s idx
    ldloc.s idx
    ldc.i4.0
    blt RC_TAIL
    ldloc.s sb
    ldarg.0
    ldloc.s pos
    ldloc.s idx
    ldloc.s pos
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
    pop
    ldloc.s sb
    ldarg.2
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
    pop
    ldloc.s idx
    ldarg.1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    stloc.s pos
    ldloc.s replaced
    ldc.i4.1
    add
    stloc.s replaced
    br RC_LOOP
  RC_TAIL:
    ldloc.s sb
    ldarg.0
    ldloc.s pos
    callvirt instance string [mscorlib]System.String::Substring(int32)
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
    pop
    ldloc.s sb
    callvirt instance string [mscorlib]System.Text.StringBuilder::ToString()
    ret
  }
  .method public static int32 RFind(string src, string subStr) cil managed
  {
    .maxstack 8
    ldarg.1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    brtrue RF_NORMAL
    ldarg.0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ret
  RF_NORMAL:
    ldarg.0
    ldarg.1
    callvirt instance int32 [mscorlib]System.String::LastIndexOf(string)
    ret
  }
  .method public static int32 IsDigit(string s) cil managed
  {
    .maxstack 8
    .locals init (int32 i, int32 n)
    ldarg.0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    stloc.s n
    ldloc.s n
    brtrue ID_INIT
    ldc.i4.0
    ret
  ID_INIT:
    ldc.i4.0
    stloc.s i
  ID_LOOP:
    ldloc.s i
    ldloc.s n
    bge ID_TRUE
    ldarg.0
    ldloc.s i
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    call bool [mscorlib]System.Char::IsDigit(char)
    brfalse ID_FALSE
    ldloc.s i
    ldc.i4.1
    add
    stloc.s i
    br ID_LOOP
  ID_FALSE:
    ldc.i4.0
    ret
  ID_TRUE:
    ldc.i4.1
    ret
  }
  .method public static int32 IsAlpha(string s) cil managed
  {
    .maxstack 8
    .locals init (int32 i, int32 n)
    ldarg.0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    stloc.s n
    ldloc.s n
    brtrue IA_INIT
    ldc.i4.0
    ret
  IA_INIT:
    ldc.i4.0
    stloc.s i
  IA_LOOP:
    ldloc.s i
    ldloc.s n
    bge IA_TRUE
    ldarg.0
    ldloc.s i
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    call bool [mscorlib]System.Char::IsLetter(char)
    brfalse IA_FALSE
    ldloc.s i
    ldc.i4.1
    add
    stloc.s i
    br IA_LOOP
  IA_FALSE:
    ldc.i4.0
    ret
  IA_TRUE:
    ldc.i4.1
    ret
  }
  .method public static int32 IsAlnum(string s) cil managed
  {
    .maxstack 8
    .locals init (int32 i, int32 n)
    ldarg.0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    stloc.s n
    ldloc.s n
    brtrue IN_INIT
    ldc.i4.0
    ret
  IN_INIT:
    ldc.i4.0
    stloc.s i
  IN_LOOP:
    ldloc.s i
    ldloc.s n
    bge IN_TRUE
    ldarg.0
    ldloc.s i
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    call bool [mscorlib]System.Char::IsLetterOrDigit(char)
    brfalse IN_FALSE
    ldloc.s i
    ldc.i4.1
    add
    stloc.s i
    br IN_LOOP
  IN_FALSE:
    ldc.i4.0
    ret
  IN_TRUE:
    ldc.i4.1
    ret
  }
  .method public static int32 IsSpace(string s) cil managed
  {
    .maxstack 8
    .locals init (int32 i, int32 n)
    ldarg.0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    stloc.s n
    ldloc.s n
    brtrue IW_INIT
    ldc.i4.0
    ret
  IW_INIT:
    ldc.i4.0
    stloc.s i
  IW_LOOP:
    ldloc.s i
    ldloc.s n
    bge IW_TRUE
    ldarg.0
    ldloc.s i
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    call bool [mscorlib]System.Char::IsWhiteSpace(char)
    brfalse IW_FALSE
    ldloc.s i
    ldc.i4.1
    add
    stloc.s i
    br IW_LOOP
  IW_FALSE:
    ldc.i4.0
    ret
  IW_TRUE:
    ldc.i4.1
    ret
  }
}

.class public auto ansi TKVApp extends [mscorlib]System.Object
{
  .method public static int32 'run'() cil managed
  {
    .maxstack 1387
    .locals init (int32 'rc', int64 'hc', int64 'ch', int64 'wh', int32 'rcv', int32 'T', int32 'H', int32 'F', int32 'V', int32 'hb', int32 'h4', int32 'vb', int32 'qb', int32 'fb', int32 'sb', int32 'tvb', int32 'stb', int32 'whb', int32 'w1b', int32 'w2b', int32 'wh2', int64 'cell', int64 'hX', int64 'hIds', int64 'hWq', int64 'hWk', int64 'hWv', int64 'hWo', int64 'hW1', int64 'hW2', int64 'hWh', int64 'hG1', int64 'hB1', int64 'hG2', int64 'hB2', int32 'i', int32 'j', int32 '__idiv1004975_a', int32 '__idiv1004975_b', int32 '__idiv1004975_q', int32 '__idiv1004975_r', int32 '__idiv1005165_a', int32 '__idiv1005165_b', int32 '__idiv1005165_q', int32 '__idiv1005165_r', int64 'dY1', int64 'dS', int64 'dP', int64 'dQ', int64 'dK', int64 'dV', int64 'dA', int64 'dO', int64 'dX2', int64 'dY2', int64 'dZ', int64 'dHH', int64 'dO2', int64 'dOUT', int64 'dLG', int64 'dDL', int64 'dWq', int64 'dWk', int64 'dWv', int64 'dWo', int64 'dW1', int64 'dW2', int64 'dWh', int64 'gWq', int64 'gWk', int64 'gWv', int64 'gWo', int64 'gW1', int64 'gW2', int64 'gWh', int64 'gHH', int64 'gZ', int64 'gY2', int64 'gDX2', int64 'gA', int64 'gWo2', int64 'gP', int64 'gV', int64 'gS', int64 'gQ', int64 'gK', int64 'gY1', int64 'gOUT', int64 'hTmpQ', int64 'hTmpK', int64 'hTmpV', int64 'shX', int64 'shWq', int64 'shWk', int64 'shWv', int64 'shWo', int64 'shW1', int64 'shW2', int64 'shWh', int64 'shG1', int64 'shB1', int64 'shG2', int64 'shB2', int32 '__idiv1005552_a', int32 '__idiv1005552_b', int32 '__idiv1005552_q', int32 '__idiv1005552_r', int32 '__idiv1005742_a', int32 '__idiv1005742_b', int32 '__idiv1005742_q', int32 '__idiv1005742_r', int64 'sdY1', int64 'sdS', int64 'sdP', int64 'sdQ', int64 'sdK', int64 'sdV', int64 'sdA', int64 'sdO', int64 'sdX2', int64 'sdY2', int64 'sdZ', int64 'sdHH', int64 'sdO2', int64 'sdOUT', int64 'sdDL', int64 'sdWq', int64 'sdWk', int64 'sdWv', int64 'sdWo', int64 'sdW1', int64 'sdW2', int64 'sdWh', int64 'sgWq', int64 'sgWk', int64 'sgWv', int64 'sgWo', int64 'sgW1', int64 'sgW2', int64 'sgWh', int64 'sgHH', int64 'sgZ', int64 'sgY2', int64 'sgDX2', int64 'sgA', int64 'sgWo2', int64 'sgP', int64 'sgV', int64 'sgS', int64 'sgQ', int64 'sgK', int64 'sgY1', int64 'sgOUT', int64 'one', int64 'zero', int64 'hal', int64 'hY1', int64 'hXH1', int64 'hST1', int64 'hY2', int64 'hXH2', int64 'hST2', int64 'hS', int64 'hP', int64 'hZ', int64 'hHH', int64 'hO', int64 'hX2', int64 'hO2', int64 'hOUT', int64 'hORIGZ', int64 'hHHTMP', int64 'hLG', int64 'hDL', int64 'gW1h', int64 'gW2h', int64 'gWqh', int64 'gWkh', int64 'gWvh', int64 'gWoh', int64 'gWhh', int64 'shY1', int64 'shXH1', int64 'shST1', int64 'shY2', int64 'shXH2', int64 'shST2', int64 'shP', int64 'shZ', int64 'shHH', int64 'shO', int64 'shX2', int64 'shO2', int64 'shOUT', int64 'shLG', int64 'shDL', float32 'lr', int32 'step', int32 'ii', float32 'su', float32 'sq', int32 'jj', float32 'xv', float32 'mn', float32 'vr', float32 'rs', int64 'wz', float32 'xhv', float32 'gv', float32 'bv', float32 'mx', float32 'sv', float32 'zs', float32 'ev', float32 'pv', float32 'zz', float32 'e2', float32 'thv', float32 'lossv', float32 'lv', int32 'idv', float32 'pcorrect', float32 'pv2', float32 'dv', float32 'dvv', int64 'hGY2', int64 'hGDX2', float32 'acc1', float32 'acc2', float32 'gvv', float32 'dxv', float32 'doutv', int64 'hGP', int64 'hDS', float32 'rst', float32 'ppv', float32 'ddv', int64 'hyq', int64 'hyk', int64 'hyv', int64 'hy1', float32 'vsum', int64 'shGDX1', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x', valuetype [System.Numerics]System.Numerics.Complex '__tkvcplx_str', object '__arr2d_src', object '__arr2d_dst', int32 '__arr2d_i', int32 '__arr2d_n', valuetype [System.Numerics]System.Numerics.Vector4 '__v4hsum', int32 '__licm253', int32 '__licm254', int32 '__licm255', int32 '__licm256', int32 '__licm257')
    ldc.i4 0
    call int32 TKVApp::__pinvoke_cu_init(int32)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If1_else
    ldstr "CUINIT FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If1_else:
    ldstr "T0 start"
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 1
    ldloc.s 1
    call int32 TKVApp::__pinvoke_cublas_create(int64)
    stloc.s 0
    ldloc.s 1
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 2
    ldc.i8 0
    stloc.s 3
    ldc.i4 0
    stloc.s 4
    ldc.i4 512
    stloc.s 5
    ldc.i4 8
    stloc.s 6
    ldc.i4 4
    ldloc.s 6
    mul
    stloc.s 7
    ldc.i4 50257
    stloc.s 8
    ldloc.s 6
    ldc.i4 4
    mul
    stloc.s 9
    ldloc.s 7
    ldc.i4 4
    mul
    stloc.s 10
    ldloc.s 8
    ldc.i4 4
    mul
    stloc.s 11
    ldloc.s 5
    ldloc.s 6
    mul
    ldc.i4 4
    mul
    stloc.s 12
    ldloc.s 5
    ldloc.s 7
    mul
    ldc.i4 4
    mul
    stloc.s 13
    ldloc.s 5
    ldloc.s 5
    mul
    ldc.i4 4
    mul
    stloc.s 14
    ldloc.s 5
    ldloc.s 8
    mul
    ldc.i4 4
    mul
    stloc.s 15
    ldloc.s 5
    ldc.i4 8
    mul
    stloc.s 16
    ldloc.s 9
    ldloc.s 6
    mul
    stloc.s 17
    ldloc.s 10
    ldloc.s 6
    mul
    stloc.s 18
    ldloc.s 9
    ldloc.s 7
    mul
    stloc.s 19
    ldloc.s 11
    ldloc.s 6
    mul
    stloc.s 20
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 21
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 22
    ldloc.s 5
    ldc.i4 4
    mul
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 23
    ldloc.s 17
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 24
    ldloc.s 17
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 25
    ldloc.s 17
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 26
    ldloc.s 17
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 27
    ldloc.s 18
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 28
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 29
    ldloc.s 20
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 30
    ldloc.s 9
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 31
    ldloc.s 9
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 32
    ldloc.s 9
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 33
    ldloc.s 9
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 34
    ldc.i4 0
    stloc.s 35
    ldc.i4 0
    stloc.s 36
  run_W2_start:
    ldloc.s 35
    ldloc.s 5
    clt
    brfalse run_W2_end
    ldc.i4 0
    stloc.s 36
  run_W3_start:
    ldloc.s 36
    ldloc.s 6
    clt
    brfalse run_W3_end
    ldloc.s 22
    ldloc.s 35
    ldloc.s 36
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.1
    ldc.r4 0.02
    ldloc.s 35
    conv.r4
    ldloc.s 36
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 36
    ldc.i4 1
    add
    stloc.s 36
    br run_W3_start
  run_W3_end:
    ldloc.s 23
    ldloc.s 35
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 35
    ldc.i4 1
    add
    stloc.s 37
    ldloc.s 8
    stloc.s 38
    ldloc.s 37
    ldloc.s 38
    div
    stloc.s 39
    ldloc.s 37
    ldloc.s 38
    rem
    stloc.s 40
    ldloc.s 40
    ldc.i4.0
    beq run_idiv4_done
    ldloc.s 40
    ldloc.s 38
    xor
    ldc.i4.0
    bge run_idiv4_done
    ldloc.s 40
    ldloc.s 38
    add
    stloc.s 40
  run_idiv4_done:
    ldloc.s 40
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt32(native int, int32)
    ldc.i8 0
    stloc.s 3
    ldloc.s 35
    ldc.i4 1
    add
    stloc.s 35
    br run_W2_start
  run_W2_end:
    ldc.i4 0
    stloc.s 35
  run_W5_start:
    ldloc.s 35
    ldloc.s 6
    clt
    brfalse run_W5_end
    ldc.i4 0
    stloc.s 36
  run_W6_start:
    ldloc.s 36
    ldloc.s 6
    clt
    brfalse run_W6_end
    ldloc.s 24
    ldloc.s 35
    ldloc.s 36
    ldloc.s 6
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.20
    ldc.r4 0.01
    ldloc.s 35
    conv.r4
    ldloc.s 36
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 25
    ldloc.s 35
    ldloc.s 36
    ldloc.s 6
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.15
    ldc.r4 0.01
    ldloc.s 35
    conv.r4
    ldloc.s 36
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 26
    ldloc.s 35
    ldloc.s 36
    ldloc.s 6
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.10
    ldc.r4 0.01
    ldloc.s 35
    conv.r4
    ldloc.s 36
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 27
    ldloc.s 35
    ldloc.s 36
    ldloc.s 6
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.30
    ldc.r4 0.01
    ldloc.s 35
    conv.r4
    ldloc.s 36
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 36
    ldc.i4 1
    add
    stloc.s 36
    br run_W6_start
  run_W6_end:
    ldc.i4 0
    stloc.s 36
  run_W7_start:
    ldloc.s 36
    ldloc.s 7
    clt
    brfalse run_W7_end
    ldloc.s 28
    ldloc.s 35
    ldloc.s 36
    ldloc.s 6
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.2
    ldc.r4 0.005
    ldloc.s 35
    conv.r4
    ldloc.s 36
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 36
    ldc.i4 1
    add
    stloc.s 36
    br run_W7_start
  run_W7_end:
    ldloc.s 31
    ldloc.s 35
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 1.0
    ldc.r4 0.05
    ldloc.s 35
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 32
    ldloc.s 35
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.01
    ldloc.s 35
    conv.r4
    mul
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 33
    ldloc.s 35
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 1.1
    ldc.r4 0.04
    ldloc.s 35
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 34
    ldloc.s 35
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.02
    ldloc.s 35
    conv.r4
    mul
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 35
    ldc.i4 1
    add
    stloc.s 35
    br run_W5_start
  run_W5_end:
    ldc.i4 0
    stloc.s 35
  run_W8_start:
    ldloc.s 35
    ldloc.s 7
    clt
    brfalse run_W8_end
    ldc.i4 0
    stloc.s 36
  run_W9_start:
    ldloc.s 36
    ldloc.s 6
    clt
    brfalse run_W9_end
    ldloc.s 29
    ldloc.s 35
    ldloc.s 36
    ldloc.s 7
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.2
    ldc.r4 0.005
    ldloc.s 35
    conv.r4
    ldloc.s 36
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 36
    ldc.i4 1
    add
    stloc.s 36
    br run_W9_start
  run_W9_end:
    ldloc.s 35
    ldc.i4 1
    add
    stloc.s 35
    br run_W8_start
  run_W8_end:
    ldc.i4 0
    stloc.s 35
  run_W10_start:
    ldloc.s 35
    ldloc.s 6
    clt
    brfalse run_W10_end
    ldc.i4 0
    stloc.s 36
  run_W11_start:
    ldloc.s 36
    ldloc.s 8
    clt
    brfalse run_W11_end
    ldloc.s 30
    ldloc.s 35
    ldloc.s 36
    ldloc.s 6
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.2
    ldc.r4 0.01
    ldloc.s 35
    conv.r4
    ldloc.s 36
    stloc.s 41
    ldc.i4 8
    stloc.s 42
    ldloc.s 41
    ldloc.s 42
    div
    stloc.s 43
    ldloc.s 41
    ldloc.s 42
    rem
    stloc.s 44
    ldloc.s 44
    ldc.i4.0
    beq run_idiv12_done
    ldloc.s 44
    ldloc.s 42
    xor
    ldc.i4.0
    bge run_idiv12_done
    ldloc.s 44
    ldloc.s 42
    add
    stloc.s 44
  run_idiv12_done:
    ldloc.s 44
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 36
    ldc.i4 1
    add
    stloc.s 36
    br run_W11_start
  run_W11_end:
    ldloc.s 35
    ldc.i4 1
    add
    stloc.s 35
    br run_W10_start
  run_W10_end:
    ldloc.s 21
    ldloc.s 12
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 45
    ldloc.s 21
    ldloc.s 14
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 46
    ldloc.s 21
    ldloc.s 14
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 47
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 48
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 49
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 50
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 51
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 52
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 53
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 54
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 55
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 56
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 57
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 58
    ldloc.s 21
    ldloc.s 15
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 59
    ldloc.s 21
    ldloc.s 15
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 60
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 61
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 62
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 63
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 64
    ldloc.s 21
    ldloc.s 18
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 65
    ldloc.s 21
    ldloc.s 19
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 66
    ldloc.s 21
    ldloc.s 20
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 67
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 68
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 69
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 70
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 71
    ldloc.s 21
    ldloc.s 18
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 72
    ldloc.s 21
    ldloc.s 19
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 73
    ldloc.s 21
    ldloc.s 20
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 74
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 75
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 76
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 77
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 78
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 79
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 80
    ldloc.s 21
    ldloc.s 14
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 81
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 82
    ldloc.s 21
    ldloc.s 14
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 83
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 84
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 85
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 86
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 87
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 88
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 89
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 90
    ldloc.s 61
    ldloc.s 24
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 62
    ldloc.s 25
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 63
    ldloc.s 26
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 64
    ldloc.s 27
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 65
    ldloc.s 28
    ldloc.s 18
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 66
    ldloc.s 29
    ldloc.s 19
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 67
    ldloc.s 30
    ldloc.s 20
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "T1 weights"
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 21
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 91
    ldloc.s 17
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 92
    ldloc.s 17
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 93
    ldloc.s 17
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 94
    ldloc.s 17
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 95
    ldloc.s 18
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 96
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 97
    ldloc.s 20
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 98
    ldloc.s 9
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 99
    ldloc.s 9
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 100
    ldloc.s 9
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 101
    ldloc.s 9
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 102
    ldc.i4 0
    stloc.s 35
    ldc.i4 0
    stloc.s 36
  run_W13_start:
    ldloc.s 35
    ldloc.s 5
    clt
    brfalse run_W13_end
    ldc.i4 0
    stloc.s 36
  run_W14_start:
    ldloc.s 36
    ldloc.s 6
    clt
    brfalse run_W14_end
    ldloc.s 91
    ldloc.s 35
    ldloc.s 36
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.1
    ldc.r4 0.02
    ldloc.s 35
    conv.r4
    ldloc.s 36
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 36
    ldc.i4 1
    add
    stloc.s 36
    br run_W14_start
  run_W14_end:
    ldloc.s 23
    ldloc.s 35
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 35
    ldc.i4 1
    add
    stloc.s 103
    ldloc.s 8
    stloc.s 104
    ldloc.s 103
    ldloc.s 104
    div
    stloc.s 105
    ldloc.s 103
    ldloc.s 104
    rem
    stloc.s 106
    ldloc.s 106
    ldc.i4.0
    beq run_idiv15_done
    ldloc.s 106
    ldloc.s 104
    xor
    ldc.i4.0
    bge run_idiv15_done
    ldloc.s 106
    ldloc.s 104
    add
    stloc.s 106
  run_idiv15_done:
    ldloc.s 106
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt32(native int, int32)
    ldc.i8 0
    stloc.s 3
    ldloc.s 35
    ldc.i4 1
    add
    stloc.s 35
    br run_W13_start
  run_W13_end:
    ldc.i4 0
    stloc.s 35
  run_W16_start:
    ldloc.s 35
    ldloc.s 6
    clt
    brfalse run_W16_end
    ldc.i4 0
    stloc.s 36
  run_W17_start:
    ldloc.s 36
    ldloc.s 6
    clt
    brfalse run_W17_end
    ldloc.s 92
    ldloc.s 35
    ldloc.s 36
    ldloc.s 6
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.20
    ldc.r4 0.01
    ldloc.s 35
    conv.r4
    ldloc.s 36
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 93
    ldloc.s 35
    ldloc.s 36
    ldloc.s 6
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.15
    ldc.r4 0.01
    ldloc.s 35
    conv.r4
    ldloc.s 36
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 94
    ldloc.s 35
    ldloc.s 36
    ldloc.s 6
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.10
    ldc.r4 0.01
    ldloc.s 35
    conv.r4
    ldloc.s 36
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 95
    ldloc.s 35
    ldloc.s 36
    ldloc.s 6
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.30
    ldc.r4 0.01
    ldloc.s 35
    conv.r4
    ldloc.s 36
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 36
    ldc.i4 1
    add
    stloc.s 36
    br run_W17_start
  run_W17_end:
    ldc.i4 0
    stloc.s 36
  run_W18_start:
    ldloc.s 36
    ldloc.s 7
    clt
    brfalse run_W18_end
    ldloc.s 96
    ldloc.s 35
    ldloc.s 36
    ldloc.s 6
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.2
    ldc.r4 0.005
    ldloc.s 35
    conv.r4
    ldloc.s 36
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 36
    ldc.i4 1
    add
    stloc.s 36
    br run_W18_start
  run_W18_end:
    ldloc.s 99
    ldloc.s 35
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 1.0
    ldc.r4 0.05
    ldloc.s 35
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 100
    ldloc.s 35
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.01
    ldloc.s 35
    conv.r4
    mul
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 101
    ldloc.s 35
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 1.1
    ldc.r4 0.04
    ldloc.s 35
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 102
    ldloc.s 35
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.02
    ldloc.s 35
    conv.r4
    mul
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 35
    ldc.i4 1
    add
    stloc.s 35
    br run_W16_start
  run_W16_end:
    ldc.i4 0
    stloc.s 35
  run_W19_start:
    ldloc.s 35
    ldloc.s 7
    clt
    brfalse run_W19_end
    ldc.i4 0
    stloc.s 36
  run_W20_start:
    ldloc.s 36
    ldloc.s 6
    clt
    brfalse run_W20_end
    ldloc.s 97
    ldloc.s 35
    ldloc.s 36
    ldloc.s 7
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.2
    ldc.r4 0.005
    ldloc.s 35
    conv.r4
    ldloc.s 36
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 36
    ldc.i4 1
    add
    stloc.s 36
    br run_W20_start
  run_W20_end:
    ldloc.s 35
    ldc.i4 1
    add
    stloc.s 35
    br run_W19_start
  run_W19_end:
    ldc.i4 0
    stloc.s 35
  run_W21_start:
    ldloc.s 35
    ldloc.s 6
    clt
    brfalse run_W21_end
    ldc.i4 0
    stloc.s 36
  run_W22_start:
    ldloc.s 36
    ldloc.s 8
    clt
    brfalse run_W22_end
    ldloc.s 98
    ldloc.s 35
    ldloc.s 36
    ldloc.s 6
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.2
    ldc.r4 0.01
    ldloc.s 35
    conv.r4
    ldloc.s 36
    stloc.s 107
    ldc.i4 8
    stloc.s 108
    ldloc.s 107
    ldloc.s 108
    div
    stloc.s 109
    ldloc.s 107
    ldloc.s 108
    rem
    stloc.s 110
    ldloc.s 110
    ldc.i4.0
    beq run_idiv23_done
    ldloc.s 110
    ldloc.s 108
    xor
    ldc.i4.0
    bge run_idiv23_done
    ldloc.s 110
    ldloc.s 108
    add
    stloc.s 110
  run_idiv23_done:
    ldloc.s 110
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 36
    ldc.i4 1
    add
    stloc.s 36
    br run_W22_start
  run_W22_end:
    ldloc.s 35
    ldc.i4 1
    add
    stloc.s 35
    br run_W21_start
  run_W21_end:
    ldloc.s 21
    ldloc.s 12
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 111
    ldloc.s 21
    ldloc.s 14
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 112
    ldloc.s 21
    ldloc.s 14
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 113
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 114
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 115
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 116
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 117
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 118
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 119
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 120
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 121
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 122
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 123
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 124
    ldloc.s 21
    ldloc.s 15
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldloc.s 15
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 125
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 126
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 127
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 128
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 129
    ldloc.s 21
    ldloc.s 18
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 130
    ldloc.s 21
    ldloc.s 19
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 131
    ldloc.s 21
    ldloc.s 20
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 132
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 133
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 134
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 135
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 136
    ldloc.s 21
    ldloc.s 18
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 137
    ldloc.s 21
    ldloc.s 19
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 138
    ldloc.s 21
    ldloc.s 20
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 139
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 140
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 141
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 142
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 143
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 144
    ldloc.s 21
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 145
    ldloc.s 21
    ldloc.s 14
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 146
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 147
    ldloc.s 21
    ldloc.s 14
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 148
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 149
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 150
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 151
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 152
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 21
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 126
    ldloc.s 92
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 127
    ldloc.s 93
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 128
    ldloc.s 94
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 129
    ldloc.s 95
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 130
    ldloc.s 96
    ldloc.s 18
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 131
    ldloc.s 97
    ldloc.s 19
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 132
    ldloc.s 98
    ldloc.s 20
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "T1 weights"
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 4
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 153
    ldloc.s 153
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldc.r4 1.0
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldc.i4 4
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 154
    ldloc.s 154
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldc.r4 0.0
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldc.i4 4
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 155
    ldloc.s 155
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldc.r4 1.0
    ldloc.s 6
    conv.r4
    conv.r8
    call float64 [mscorlib]System.Math::Sqrt(float64)
    conv.r4
    div
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 156
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 157
    ldloc.s 16
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 158
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 159
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 160
    ldloc.s 16
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 161
    ldloc.s 14
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 162
    ldloc.s 14
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 163
    ldloc.s 13
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 164
    ldloc.s 13
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 165
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 166
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 167
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 168
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 169
    ldloc.s 13
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 170
    ldloc.s 13
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 171
    ldloc.s 15
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 172
    ldloc.s 15
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 173
    ldloc.s 18
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 174
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 175
    ldloc.s 17
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 176
    ldloc.s 17
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 177
    ldloc.s 17
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 178
    ldloc.s 17
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 179
    ldloc.s 20
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 180
    ldstr "T2 scratch"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 181
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 182
    ldloc.s 16
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 183
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 184
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 185
    ldloc.s 16
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 186
    ldloc.s 14
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 187
    ldloc.s 13
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 188
    ldloc.s 13
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 189
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 190
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 191
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 192
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 193
    ldloc.s 15
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 194
    ldloc.s 15
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 195
    ldstr "T2 scratch"
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.r4 0.000001
    stloc.s 196
    ldc.i4 1
    stloc.s 197
    ldloc.s 5
    ldloc.s 7
    mul
    stloc.s 253
    ldloc.s 6
    ldloc.s 7
    mul
    stloc.s 254
    ldloc.s 7
    ldloc.s 6
    mul
    stloc.s 255
    ldloc.s 6
    ldloc.s 6
    mul
    stloc.s 256
    ldloc.s 6
    ldloc.s 8
    mul
    stloc.s 257
  run_W24_start:
    ldloc.s 197
    ldc.i4 3
    cgt
    ldc.i4.0
    ceq
    brfalse run_W24_end
    ldc.i4 0
    stloc.s 198
  run_W25_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W25_end
    ldc.r4 0.0
    stloc.s 199
    ldc.r4 0.0
    stloc.s 200
    ldc.i4 0
    stloc.s 201
  run_W26_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W26_end
    ldloc.s 22
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 202
    ldloc.s 199
    ldloc.s 202
    add
    stloc.s 199
    ldloc.s 200
    ldloc.s 202
    ldloc.s 202
    mul
    add
    stloc.s 200
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W26_start
  run_W26_end:
    ldstr "T3a sums"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 199
    ldloc.s 6
    conv.r4
    div
    stloc.s 203
    ldloc.s 200
    ldloc.s 6
    conv.r4
    div
    ldloc.s 203
    ldloc.s 203
    mul
    sub
    stloc.s 204
    ldloc.s 204
    ldc.r4 0.000001
    add
    stloc.s 204
    ldc.r4 1.0
    ldloc.s 204
    conv.r8
    call float64 [mscorlib]System.Math::Sqrt(float64)
    conv.r4
    div
    stloc.s 205
    ldstr "T3b stats"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 158
    ldloc.s 198
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 203
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 158
    ldloc.s 198
    ldc.i4 8
    mul
    ldc.i4 4
    add
    conv.i8
    add
    conv.i
    ldloc.s 205
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldc.i4 0
    stloc.s 201
  run_W27_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W27_end
    ldloc.s 22
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 202
    ldloc.s 202
    ldloc.s 203
    sub
    ldloc.s 205
    mul
    stloc.s 207
    ldloc.s 31
    ldloc.s 201
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 208
    ldloc.s 32
    ldloc.s 201
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 209
    ldloc.s 157
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 207
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 156
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 207
    ldloc.s 208
    mul
    ldloc.s 209
    add
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W27_start
  run_W27_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W25_start
  run_W25_end:
    ldstr "T3c ln1 done"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 45
    ldloc.s 156
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "T4 ln1"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 45
    ldloc.s 5
    ldloc.s 61
    ldloc.s 6
    ldloc.s 154
    ldloc.s 48
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 45
    ldloc.s 5
    ldloc.s 62
    ldloc.s 6
    ldloc.s 154
    ldloc.s 49
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 45
    ldloc.s 5
    ldloc.s 63
    ldloc.s 6
    ldloc.s 154
    ldloc.s 50
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If28_else
    ldstr "QKV FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If28_else:
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 5
    ldloc.s 6
    ldloc.s 155
    ldloc.s 48
    ldloc.s 5
    ldloc.s 49
    ldloc.s 5
    ldloc.s 154
    ldloc.s 46
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If29_else
    ldstr "S FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If29_else:
    ldstr "T5 qkv+s"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 162
    ldloc.s 46
    ldloc.s 14
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W30_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W30_end
    ldc.r4 1000000000.0
    neg
    stloc.s 210
    ldc.i4 0
    stloc.s 201
  run_W31_start:
    ldloc.s 201
    ldloc.s 198
    cgt
    ldc.i4.0
    ceq
    brfalse run_W31_end
    ldloc.s 162
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 211
    ldloc.s 211
    ldloc.s 210
    cgt
    brfalse run_If32_else
    ldloc.s 211
    stloc.s 210
  run_If32_else:
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W31_start
  run_W31_end:
    ldc.r4 0.0
    stloc.s 212
    ldc.i4 0
    stloc.s 201
  run_W33_start:
    ldloc.s 201
    ldloc.s 198
    cgt
    ldc.i4.0
    ceq
    brfalse run_W33_end
    ldloc.s 162
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 211
    ldloc.s 211
    ldloc.s 210
    sub
    conv.r8
    call float64 [mscorlib]System.Math::Exp(float64)
    conv.r4
    stloc.s 213
    ldloc.s 212
    ldloc.s 213
    add
    stloc.s 212
    ldloc.s 163
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 213
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W33_start
  run_W33_end:
    ldc.i4 0
    stloc.s 201
  run_W34_start:
    ldloc.s 201
    ldloc.s 198
    cgt
    ldc.i4.0
    ceq
    brfalse run_W34_end
    ldloc.s 163
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 214
    ldloc.s 163
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 214
    ldloc.s 212
    div
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W34_start
  run_W34_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W30_start
  run_W30_end:
    ldloc.s 47
    ldloc.s 163
    ldloc.s 14
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "T6 softmax"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 5
    ldloc.s 153
    ldloc.s 47
    ldloc.s 5
    ldloc.s 50
    ldloc.s 5
    ldloc.s 154
    ldloc.s 51
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 51
    ldloc.s 5
    ldloc.s 64
    ldloc.s 6
    ldloc.s 154
    ldloc.s 52
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If35_else
    ldstr "ATTN FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If35_else:
    ldloc.s 166
    ldloc.s 52
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W36_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W36_end
    ldc.i4 0
    stloc.s 201
  run_W37_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W37_end
    ldloc.s 22
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 166
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 202
    ldloc.s 167
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 202
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W37_start
  run_W37_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W36_start
  run_W36_end:
    ldloc.s 53
    ldloc.s 167
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W38_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W38_end
    ldc.r4 0.0
    stloc.s 199
    ldc.r4 0.0
    stloc.s 200
    ldc.i4 0
    stloc.s 201
  run_W39_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W39_end
    ldloc.s 167
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 202
    ldloc.s 199
    ldloc.s 202
    add
    stloc.s 199
    ldloc.s 200
    ldloc.s 202
    ldloc.s 202
    mul
    add
    stloc.s 200
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W39_start
  run_W39_end:
    ldloc.s 199
    ldloc.s 6
    conv.r4
    div
    stloc.s 203
    ldloc.s 200
    ldloc.s 6
    conv.r4
    div
    ldloc.s 203
    ldloc.s 203
    mul
    sub
    ldc.r4 0.000001
    add
    stloc.s 204
    ldc.r4 1.0
    ldloc.s 204
    conv.r8
    call float64 [mscorlib]System.Math::Sqrt(float64)
    conv.r4
    div
    stloc.s 205
    ldloc.s 161
    ldloc.s 198
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 203
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 161
    ldloc.s 198
    ldc.i4 8
    mul
    ldc.i4 4
    add
    conv.i8
    add
    conv.i
    ldloc.s 205
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldc.i4 0
    stloc.s 201
  run_W40_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W40_end
    ldloc.s 167
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 202
    ldloc.s 202
    ldloc.s 203
    sub
    ldloc.s 205
    mul
    stloc.s 207
    ldloc.s 33
    ldloc.s 201
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 208
    ldloc.s 34
    ldloc.s 201
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 209
    ldloc.s 160
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 207
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 159
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 207
    ldloc.s 208
    mul
    ldloc.s 209
    add
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W40_start
  run_W40_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W38_start
  run_W38_end:
    ldloc.s 54
    ldloc.s 159
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "T7 ln2"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 7
    ldloc.s 6
    ldloc.s 153
    ldloc.s 54
    ldloc.s 5
    ldloc.s 65
    ldloc.s 6
    ldloc.s 154
    ldloc.s 55
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If41_else
    ldstr "Z FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If41_else:
    ldloc.s 164
    ldloc.s 55
    ldloc.s 13
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 170
    ldloc.s 55
    ldloc.s 13
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W42_start:
    ldloc.s 198
    ldloc.s 253
    clt
    brfalse run_W42_end
    ldloc.s 164
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 202
    ldc.r4 0.79788456
    ldloc.s 202
    ldc.r4 0.044715
    ldloc.s 202
    mul
    ldloc.s 202
    mul
    ldloc.s 202
    mul
    add
    mul
    stloc.s 215
    ldc.r4 2.0
    ldloc.s 215
    mul
    conv.r8
    call float64 [mscorlib]System.Math::Exp(float64)
    conv.r4
    stloc.s 216
    ldloc.s 216
    ldc.r4 1.0
    sub
    ldloc.s 216
    ldc.r4 1.0
    add
    div
    stloc.s 217
    ldc.r4 0.5
    ldloc.s 202
    mul
    ldc.r4 1.0
    ldloc.s 217
    add
    mul
    stloc.s 208
    ldloc.s 164
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 208
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W42_start
  run_W42_end:
    ldloc.s 56
    ldloc.s 164
    ldloc.s 13
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "T8 gelu"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 7
    ldloc.s 153
    ldloc.s 56
    ldloc.s 5
    ldloc.s 66
    ldloc.s 7
    ldloc.s 154
    ldloc.s 57
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If43_else
    ldstr "O2 FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If43_else:
    ldloc.s 168
    ldloc.s 57
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W44_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W44_end
    ldc.i4 0
    stloc.s 201
  run_W45_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W45_end
    ldloc.s 167
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 168
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 202
    ldloc.s 169
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 202
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W45_start
  run_W45_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W44_start
  run_W44_end:
    ldloc.s 58
    ldloc.s 169
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W46_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W46_end
    ldc.r4 0.0
    stloc.s 199
    ldc.r4 0.0
    stloc.s 200
    ldc.i4 0
    stloc.s 201
  run_W47_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W47_end
    ldloc.s 169
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 202
    ldloc.s 199
    ldloc.s 202
    add
    stloc.s 199
    ldloc.s 200
    ldloc.s 202
    ldloc.s 202
    mul
    add
    stloc.s 200
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W47_start
  run_W47_end:
    ldstr "T3a sums"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 199
    ldloc.s 6
    conv.r4
    div
    stloc.s 203
    ldloc.s 200
    ldloc.s 6
    conv.r4
    div
    ldloc.s 203
    ldloc.s 203
    mul
    sub
    stloc.s 204
    ldloc.s 204
    ldc.r4 0.000001
    add
    stloc.s 204
    ldc.r4 1.0
    ldloc.s 204
    conv.r8
    call float64 [mscorlib]System.Math::Sqrt(float64)
    conv.r4
    div
    stloc.s 205
    ldstr "T3b stats"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 183
    ldloc.s 198
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 203
    stind.r4
    ldc.i8 0
    stloc.s 3
    ldloc.s 183
    ldloc.s 198
    ldc.i4 8
    mul
    ldc.i4 4
    add
    conv.i8
    add
    conv.i
    ldloc.s 205
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldc.i4 0
    stloc.s 201
  run_W48_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W48_end
    ldloc.s 169
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 202
    ldloc.s 202
    ldloc.s 203
    sub
    ldloc.s 205
    mul
    stloc.s 207
    ldloc.s 99
    ldloc.s 201
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 208
    ldloc.s 100
    ldloc.s 201
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 209
    ldloc.s 182
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 207
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 181
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 207
    ldloc.s 208
    mul
    ldloc.s 209
    add
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W48_start
  run_W48_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W46_start
  run_W46_end:
    ldstr "T3c ln1 done"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 111
    ldloc.s 181
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "T4 ln1"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 111
    ldloc.s 5
    ldloc.s 126
    ldloc.s 6
    ldloc.s 154
    ldloc.s 114
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 111
    ldloc.s 5
    ldloc.s 127
    ldloc.s 6
    ldloc.s 154
    ldloc.s 115
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 111
    ldloc.s 5
    ldloc.s 128
    ldloc.s 6
    ldloc.s 154
    ldloc.s 116
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If49_else
    ldstr "QKV FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If49_else:
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 5
    ldloc.s 6
    ldloc.s 155
    ldloc.s 114
    ldloc.s 5
    ldloc.s 115
    ldloc.s 5
    ldloc.s 154
    ldloc.s 112
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If50_else
    ldstr "S FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If50_else:
    ldstr "T5 qkv+s"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 162
    ldloc.s 112
    ldloc.s 14
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W51_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W51_end
    ldc.r4 1000000000.0
    neg
    stloc.s 210
    ldc.i4 0
    stloc.s 201
  run_W52_start:
    ldloc.s 201
    ldloc.s 198
    cgt
    ldc.i4.0
    ceq
    brfalse run_W52_end
    ldloc.s 162
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 211
    ldloc.s 211
    ldloc.s 210
    cgt
    brfalse run_If53_else
    ldloc.s 211
    stloc.s 210
  run_If53_else:
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W52_start
  run_W52_end:
    ldc.r4 0.0
    stloc.s 212
    ldc.i4 0
    stloc.s 201
  run_W54_start:
    ldloc.s 201
    ldloc.s 198
    cgt
    ldc.i4.0
    ceq
    brfalse run_W54_end
    ldloc.s 162
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 211
    ldloc.s 211
    ldloc.s 210
    sub
    conv.r8
    call float64 [mscorlib]System.Math::Exp(float64)
    conv.r4
    stloc.s 213
    ldloc.s 212
    ldloc.s 213
    add
    stloc.s 212
    ldloc.s 187
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 213
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W54_start
  run_W54_end:
    ldc.i4 0
    stloc.s 201
  run_W55_start:
    ldloc.s 201
    ldloc.s 198
    cgt
    ldc.i4.0
    ceq
    brfalse run_W55_end
    ldloc.s 187
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 214
    ldloc.s 187
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 214
    ldloc.s 212
    div
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W55_start
  run_W55_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W51_start
  run_W51_end:
    ldloc.s 113
    ldloc.s 187
    ldloc.s 14
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "T6 softmax"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 5
    ldloc.s 153
    ldloc.s 113
    ldloc.s 5
    ldloc.s 116
    ldloc.s 5
    ldloc.s 154
    ldloc.s 117
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 117
    ldloc.s 5
    ldloc.s 129
    ldloc.s 6
    ldloc.s 154
    ldloc.s 118
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If56_else
    ldstr "ATTN FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If56_else:
    ldloc.s 190
    ldloc.s 118
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W57_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W57_end
    ldc.i4 0
    stloc.s 201
  run_W58_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W58_end
    ldloc.s 169
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 190
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 202
    ldloc.s 191
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 202
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W58_start
  run_W58_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W57_start
  run_W57_end:
    ldloc.s 119
    ldloc.s 191
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W59_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W59_end
    ldc.r4 0.0
    stloc.s 199
    ldc.r4 0.0
    stloc.s 200
    ldc.i4 0
    stloc.s 201
  run_W60_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W60_end
    ldloc.s 191
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 202
    ldloc.s 199
    ldloc.s 202
    add
    stloc.s 199
    ldloc.s 200
    ldloc.s 202
    ldloc.s 202
    mul
    add
    stloc.s 200
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W60_start
  run_W60_end:
    ldloc.s 199
    ldloc.s 6
    conv.r4
    div
    stloc.s 203
    ldloc.s 200
    ldloc.s 6
    conv.r4
    div
    ldloc.s 203
    ldloc.s 203
    mul
    sub
    ldc.r4 0.000001
    add
    stloc.s 204
    ldc.r4 1.0
    ldloc.s 204
    conv.r8
    call float64 [mscorlib]System.Math::Sqrt(float64)
    conv.r4
    div
    stloc.s 205
    ldloc.s 186
    ldloc.s 198
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 203
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 186
    ldloc.s 198
    ldc.i4 8
    mul
    ldc.i4 4
    add
    conv.i8
    add
    conv.i
    ldloc.s 205
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldc.i4 0
    stloc.s 201
  run_W61_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W61_end
    ldloc.s 191
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 202
    ldloc.s 202
    ldloc.s 203
    sub
    ldloc.s 205
    mul
    stloc.s 207
    ldloc.s 101
    ldloc.s 201
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 208
    ldloc.s 102
    ldloc.s 201
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 209
    ldloc.s 185
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 207
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 184
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 207
    ldloc.s 208
    mul
    ldloc.s 209
    add
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W61_start
  run_W61_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W59_start
  run_W59_end:
    ldloc.s 120
    ldloc.s 184
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "T7 ln2"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 7
    ldloc.s 6
    ldloc.s 153
    ldloc.s 120
    ldloc.s 5
    ldloc.s 130
    ldloc.s 6
    ldloc.s 154
    ldloc.s 121
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If62_else
    ldstr "Z FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If62_else:
    ldloc.s 188
    ldloc.s 121
    ldloc.s 13
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 170
    ldloc.s 121
    ldloc.s 13
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W63_start:
    ldloc.s 198
    ldloc.s 253
    clt
    brfalse run_W63_end
    ldloc.s 188
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 202
    ldc.r4 0.79788456
    ldloc.s 202
    ldc.r4 0.044715
    ldloc.s 202
    mul
    ldloc.s 202
    mul
    ldloc.s 202
    mul
    add
    mul
    stloc.s 215
    ldc.r4 2.0
    ldloc.s 215
    mul
    conv.r8
    call float64 [mscorlib]System.Math::Exp(float64)
    conv.r4
    stloc.s 216
    ldloc.s 216
    ldc.r4 1.0
    sub
    ldloc.s 216
    ldc.r4 1.0
    add
    div
    stloc.s 217
    ldc.r4 0.5
    ldloc.s 202
    mul
    ldc.r4 1.0
    ldloc.s 217
    add
    mul
    stloc.s 208
    ldloc.s 188
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 208
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W63_start
  run_W63_end:
    ldloc.s 122
    ldloc.s 188
    ldloc.s 13
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "T8 gelu"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 7
    ldloc.s 153
    ldloc.s 122
    ldloc.s 5
    ldloc.s 131
    ldloc.s 7
    ldloc.s 154
    ldloc.s 123
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If64_else
    ldstr "O2 FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If64_else:
    ldloc.s 192
    ldloc.s 123
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W65_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W65_end
    ldc.i4 0
    stloc.s 201
  run_W66_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W66_end
    ldloc.s 191
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 192
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 202
    ldloc.s 193
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 202
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W66_start
  run_W66_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W65_start
  run_W65_end:
    ldloc.s 124
    ldloc.s 193
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "T9 mlp"
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 8
    ldloc.s 6
    ldloc.s 153
    ldloc.s 124
    ldloc.s 5
    ldloc.s 132
    ldloc.s 6
    ldloc.s 154
    ldloc.s 59
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If67_else
    ldstr "LG FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If67_else:
    ldloc.s 194
    ldloc.s 59
    ldloc.s 15
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "T10 logits"
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.r4 0.0
    stloc.s 218
    ldc.i4 0
    stloc.s 198
  run_W68_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W68_end
    ldc.r4 1000000000.0
    neg
    stloc.s 210
    ldc.i4 0
    stloc.s 201
  run_W69_start:
    ldloc.s 201
    ldloc.s 8
    clt
    brfalse run_W69_end
    ldloc.s 194
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 219
    ldloc.s 219
    ldloc.s 210
    cgt
    brfalse run_If70_else
    ldloc.s 219
    stloc.s 210
  run_If70_else:
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W69_start
  run_W69_end:
    ldc.r4 0.0
    stloc.s 212
    ldc.i4 0
    stloc.s 201
  run_W71_start:
    ldloc.s 201
    ldloc.s 8
    clt
    brfalse run_W71_end
    ldloc.s 194
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 219
    ldloc.s 219
    ldloc.s 210
    sub
    conv.r8
    call float64 [mscorlib]System.Math::Exp(float64)
    conv.r4
    stloc.s 213
    ldloc.s 212
    ldloc.s 213
    add
    stloc.s 212
    ldloc.s 195
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 213
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W71_start
  run_W71_end:
    ldloc.s 23
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int)
    stloc.s 220
    ldloc.s 195
    ldloc.s 198
    ldloc.s 220
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 212
    div
    stloc.s 221
    ldloc.s 218
    ldloc.s 221
    conv.r8
    call float64 [mscorlib]System.Math::Log(float64)
    conv.r4
    sub
    stloc.s 218
    ldc.i4 0
    stloc.s 201
  run_W72_start:
    ldloc.s 201
    ldloc.s 8
    clt
    brfalse run_W72_end
    ldloc.s 195
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 212
    div
    stloc.s 222
    ldloc.s 222
    stloc.s 223
    ldloc.s 201
    ldloc.s 220
    ceq
    brfalse run_If73_else
    ldloc.s 223
    ldc.r4 1.0
    sub
    stloc.s 223
  run_If73_else:
    ldloc.s 223
    ldloc.s 5
    conv.r4
    div
    stloc.s 223
    ldloc.s 195
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 223
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W72_start
  run_W72_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W68_start
  run_W68_end:
    ldloc.s 218
    ldloc.s 5
    conv.r4
    div
    stloc.s 218
    ldstr "LOSS"
    ldstr " "
    ldloc.s 218
    call string TkvStr::F32(float32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 60
    ldloc.s 195
    ldloc.s 15
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "MARK FWD"
    ldstr " "
    ldloc.s 197
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldstr "MARK FWD"
    ldstr " "
    ldloc.s 197
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 6
    ldloc.s 8
    ldloc.s 5
    ldloc.s 153
    ldloc.s 124
    ldloc.s 5
    ldloc.s 60
    ldloc.s 5
    ldloc.s 154
    ldloc.s 139
    ldloc.s 6
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 6
    ldloc.s 8
    ldloc.s 153
    ldloc.s 60
    ldloc.s 5
    ldloc.s 132
    ldloc.s 6
    ldloc.s 154
    ldloc.s 152
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If74_else
    ldstr "HEAD BW FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If74_else:
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 7
    ldloc.s 6
    ldloc.s 5
    ldloc.s 153
    ldloc.s 122
    ldloc.s 5
    ldloc.s 152
    ldloc.s 5
    ldloc.s 154
    ldloc.s 138
    ldloc.s 7
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 7
    ldloc.s 6
    ldloc.s 153
    ldloc.s 152
    ldloc.s 5
    ldloc.s 131
    ldloc.s 7
    ldloc.s 154
    ldloc.s 140
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If75_else
    ldstr "W2 BW FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If75_else:
    ldloc.s 171
    ldloc.s 140
    ldloc.s 13
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W76_start:
    ldloc.s 198
    ldloc.s 253
    clt
    brfalse run_W76_end
    ldloc.s 170
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 202
    ldc.r4 0.79788456
    ldloc.s 202
    ldc.r4 0.044715
    ldloc.s 202
    mul
    ldloc.s 202
    mul
    ldloc.s 202
    mul
    add
    mul
    stloc.s 215
    ldc.r4 2.0
    ldloc.s 215
    mul
    conv.r8
    call float64 [mscorlib]System.Math::Exp(float64)
    conv.r4
    stloc.s 216
    ldloc.s 216
    ldc.r4 1.0
    sub
    ldloc.s 216
    ldc.r4 1.0
    add
    div
    stloc.s 217
    ldc.r4 0.5
    ldc.r4 1.0
    ldloc.s 217
    add
    mul
    ldc.r4 0.5
    ldloc.s 202
    mul
    ldc.r4 1.0
    ldloc.s 217
    ldloc.s 217
    mul
    sub
    mul
    ldc.r4 0.79788456
    mul
    ldc.r4 1.0
    ldc.r4 0.134145
    ldloc.s 202
    mul
    ldloc.s 202
    mul
    add
    mul
    add
    stloc.s 208
    ldloc.s 171
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 208
    mul
    stloc.s 224
    ldloc.s 170
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 224
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W76_start
  run_W76_end:
    ldloc.s 141
    ldloc.s 170
    ldloc.s 13
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 6
    ldloc.s 7
    ldloc.s 5
    ldloc.s 153
    ldloc.s 120
    ldloc.s 5
    ldloc.s 141
    ldloc.s 5
    ldloc.s 154
    ldloc.s 137
    ldloc.s 6
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 6
    ldloc.s 7
    ldloc.s 153
    ldloc.s 141
    ldloc.s 5
    ldloc.s 130
    ldloc.s 6
    ldloc.s 154
    ldloc.s 142
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If77_else
    ldstr "W1 BW FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If77_else:
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 225
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 226
    ldloc.s 225
    ldloc.s 142
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W78_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W78_end
    ldloc.s 186
    ldloc.s 198
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 203
    ldloc.s 186
    ldloc.s 198
    ldc.i4 8
    mul
    ldc.i4 4
    add
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 205
    ldc.r4 0.0
    stloc.s 227
    ldc.r4 0.0
    stloc.s 228
    ldc.i4 0
    stloc.s 201
  run_W79_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W79_end
    ldloc.s 225
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 224
    ldloc.s 101
    ldloc.s 201
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 229
    ldloc.s 185
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 207
    ldloc.s 227
    ldloc.s 224
    ldloc.s 229
    mul
    add
    stloc.s 227
    ldloc.s 228
    ldloc.s 224
    ldloc.s 229
    mul
    ldloc.s 207
    mul
    add
    stloc.s 228
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W79_start
  run_W79_end:
    ldc.i4 0
    stloc.s 201
  run_W80_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W80_end
    ldloc.s 225
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 224
    ldloc.s 101
    ldloc.s 201
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 229
    ldloc.s 185
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 207
    ldloc.s 224
    ldloc.s 229
    mul
    ldloc.s 227
    ldloc.s 6
    conv.r4
    div
    sub
    ldloc.s 207
    ldloc.s 228
    mul
    ldloc.s 6
    conv.r4
    div
    sub
    ldloc.s 205
    mul
    stloc.s 230
    ldloc.s 193
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 231
    ldloc.s 226
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    ldloc.s 231
    add
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W80_start
  run_W80_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W78_start
  run_W78_end:
    ldloc.s 143
    ldloc.s 226
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "MARK B2"
    ldstr " "
    ldloc.s 197
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 143
    ldloc.s 5
    ldloc.s 129
    ldloc.s 6
    ldloc.s 154
    ldloc.s 144
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 6
    ldloc.s 6
    ldloc.s 5
    ldloc.s 153
    ldloc.s 117
    ldloc.s 5
    ldloc.s 143
    ldloc.s 5
    ldloc.s 154
    ldloc.s 145
    ldloc.s 6
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 5
    ldloc.s 6
    ldloc.s 153
    ldloc.s 144
    ldloc.s 5
    ldloc.s 116
    ldloc.s 5
    ldloc.s 154
    ldloc.s 146
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 5
    ldloc.s 153
    ldloc.s 113
    ldloc.s 5
    ldloc.s 144
    ldloc.s 5
    ldloc.s 154
    ldloc.s 147
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If81_else
    ldstr "ATTN BW FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If81_else:
    ldloc.s 14
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 232
    ldloc.s 14
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 233
    ldloc.s 232
    ldloc.s 146
    ldloc.s 14
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W82_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W82_end
    ldc.r4 0.0
    stloc.s 234
    ldc.i4 0
    stloc.s 201
  run_W83_start:
    ldloc.s 201
    ldloc.s 5
    clt
    brfalse run_W83_end
    ldloc.s 187
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 235
    ldloc.s 232
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 236
    ldloc.s 234
    ldloc.s 235
    ldloc.s 236
    mul
    add
    stloc.s 234
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W83_start
  run_W83_end:
    ldc.i4 0
    stloc.s 201
  run_W84_start:
    ldloc.s 201
    ldloc.s 5
    clt
    brfalse run_W84_end
    ldloc.s 187
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 235
    ldloc.s 232
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 236
    ldloc.s 233
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 235
    ldloc.s 236
    ldloc.s 234
    sub
    mul
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W84_start
  run_W84_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W82_start
  run_W82_end:
    ldloc.s 148
    ldloc.s 233
    ldloc.s 14
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 5
    ldloc.s 155
    ldloc.s 148
    ldloc.s 5
    ldloc.s 115
    ldloc.s 5
    ldloc.s 154
    ldloc.s 149
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 5
    ldloc.s 155
    ldloc.s 148
    ldloc.s 5
    ldloc.s 114
    ldloc.s 5
    ldloc.s 154
    ldloc.s 150
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If85_else
    ldstr "QK BW FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If85_else:
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 6
    ldloc.s 6
    ldloc.s 5
    ldloc.s 153
    ldloc.s 111
    ldloc.s 5
    ldloc.s 149
    ldloc.s 5
    ldloc.s 154
    ldloc.s 133
    ldloc.s 6
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 6
    ldloc.s 6
    ldloc.s 5
    ldloc.s 153
    ldloc.s 111
    ldloc.s 5
    ldloc.s 150
    ldloc.s 5
    ldloc.s 154
    ldloc.s 134
    ldloc.s 6
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 6
    ldloc.s 6
    ldloc.s 5
    ldloc.s 153
    ldloc.s 111
    ldloc.s 5
    ldloc.s 147
    ldloc.s 5
    ldloc.s 154
    ldloc.s 135
    ldloc.s 6
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If86_else
    ldstr "WQKV BW FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If86_else:
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 149
    ldloc.s 5
    ldloc.s 126
    ldloc.s 6
    ldloc.s 154
    ldloc.s 88
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 150
    ldloc.s 5
    ldloc.s 127
    ldloc.s 6
    ldloc.s 154
    ldloc.s 89
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 147
    ldloc.s 5
    ldloc.s 128
    ldloc.s 6
    ldloc.s 154
    ldloc.s 90
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If87_else
    ldstr "YQKV BW FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If87_else:
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 237
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 238
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 239
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 240
    ldloc.s 237
    ldloc.s 88
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 238
    ldloc.s 89
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 239
    ldloc.s 90
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W88_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W88_end
    ldc.i4 0
    stloc.s 201
  run_W89_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W89_end
    ldloc.s 237
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 238
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    ldloc.s 239
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 241
    ldloc.s 240
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 241
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W89_start
  run_W89_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W88_start
  run_W88_end:
    ldloc.s 151
    ldloc.s 240
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 242
    ldc.i4 0
    stloc.s 198
  run_W90_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W90_end
    ldloc.s 183
    ldloc.s 198
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 203
    ldloc.s 183
    ldloc.s 198
    ldc.i4 8
    mul
    ldc.i4 4
    add
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 205
    ldc.r4 0.0
    stloc.s 227
    ldc.r4 0.0
    stloc.s 228
    ldc.i4 0
    stloc.s 201
  run_W91_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W91_end
    ldloc.s 240
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 224
    ldloc.s 99
    ldloc.s 201
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 229
    ldloc.s 182
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 207
    ldloc.s 227
    ldloc.s 224
    ldloc.s 229
    mul
    add
    stloc.s 227
    ldloc.s 228
    ldloc.s 224
    ldloc.s 229
    mul
    ldloc.s 207
    mul
    add
    stloc.s 228
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W91_start
  run_W91_end:
    ldc.i4 0
    stloc.s 201
  run_W92_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W92_end
    ldloc.s 240
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 224
    ldloc.s 99
    ldloc.s 201
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 229
    ldloc.s 182
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 207
    ldloc.s 224
    ldloc.s 229
    mul
    ldloc.s 227
    ldloc.s 6
    conv.r4
    div
    sub
    ldloc.s 207
    ldloc.s 228
    mul
    ldloc.s 6
    conv.r4
    div
    sub
    ldloc.s 205
    mul
    stloc.s 230
    ldloc.s 242
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W92_start
  run_W92_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W90_start
  run_W90_end:
    ldstr "MARK B3"
    ldstr " "
    ldloc.s 197
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 87
    ldloc.s 242
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 7
    ldloc.s 6
    ldloc.s 5
    ldloc.s 153
    ldloc.s 56
    ldloc.s 5
    ldloc.s 87
    ldloc.s 5
    ldloc.s 154
    ldloc.s 73
    ldloc.s 7
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 7
    ldloc.s 6
    ldloc.s 153
    ldloc.s 87
    ldloc.s 5
    ldloc.s 66
    ldloc.s 7
    ldloc.s 154
    ldloc.s 75
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If93_else
    ldstr "W2 BW FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If93_else:
    ldloc.s 171
    ldloc.s 75
    ldloc.s 13
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W94_start:
    ldloc.s 198
    ldloc.s 253
    clt
    brfalse run_W94_end
    ldloc.s 170
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 202
    ldc.r4 0.79788456
    ldloc.s 202
    ldc.r4 0.044715
    ldloc.s 202
    mul
    ldloc.s 202
    mul
    ldloc.s 202
    mul
    add
    mul
    stloc.s 215
    ldc.r4 2.0
    ldloc.s 215
    mul
    conv.r8
    call float64 [mscorlib]System.Math::Exp(float64)
    conv.r4
    stloc.s 216
    ldloc.s 216
    ldc.r4 1.0
    sub
    ldloc.s 216
    ldc.r4 1.0
    add
    div
    stloc.s 217
    ldc.r4 0.5
    ldc.r4 1.0
    ldloc.s 217
    add
    mul
    ldc.r4 0.5
    ldloc.s 202
    mul
    ldc.r4 1.0
    ldloc.s 217
    ldloc.s 217
    mul
    sub
    mul
    ldc.r4 0.79788456
    mul
    ldc.r4 1.0
    ldc.r4 0.134145
    ldloc.s 202
    mul
    ldloc.s 202
    mul
    add
    mul
    add
    stloc.s 208
    ldloc.s 171
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 208
    mul
    stloc.s 224
    ldloc.s 170
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 224
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W94_start
  run_W94_end:
    ldloc.s 76
    ldloc.s 170
    ldloc.s 13
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 6
    ldloc.s 7
    ldloc.s 5
    ldloc.s 153
    ldloc.s 54
    ldloc.s 5
    ldloc.s 76
    ldloc.s 5
    ldloc.s 154
    ldloc.s 72
    ldloc.s 6
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 6
    ldloc.s 7
    ldloc.s 153
    ldloc.s 76
    ldloc.s 5
    ldloc.s 65
    ldloc.s 6
    ldloc.s 154
    ldloc.s 77
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If95_else
    ldstr "W1 BW FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If95_else:
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 225
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 226
    ldloc.s 225
    ldloc.s 77
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W96_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W96_end
    ldloc.s 161
    ldloc.s 198
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 203
    ldloc.s 161
    ldloc.s 198
    ldc.i4 8
    mul
    ldc.i4 4
    add
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 205
    ldc.r4 0.0
    stloc.s 227
    ldc.r4 0.0
    stloc.s 228
    ldc.i4 0
    stloc.s 201
  run_W97_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W97_end
    ldloc.s 225
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 224
    ldloc.s 33
    ldloc.s 201
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 229
    ldloc.s 160
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 207
    ldloc.s 227
    ldloc.s 224
    ldloc.s 229
    mul
    add
    stloc.s 227
    ldloc.s 228
    ldloc.s 224
    ldloc.s 229
    mul
    ldloc.s 207
    mul
    add
    stloc.s 228
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W97_start
  run_W97_end:
    ldc.i4 0
    stloc.s 201
  run_W98_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W98_end
    ldloc.s 225
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 224
    ldloc.s 33
    ldloc.s 201
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 229
    ldloc.s 160
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 207
    ldloc.s 224
    ldloc.s 229
    mul
    ldloc.s 227
    ldloc.s 6
    conv.r4
    div
    sub
    ldloc.s 207
    ldloc.s 228
    mul
    ldloc.s 6
    conv.r4
    div
    sub
    ldloc.s 205
    mul
    stloc.s 230
    ldloc.s 169
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 231
    ldloc.s 226
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    ldloc.s 231
    add
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W98_start
  run_W98_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W96_start
  run_W96_end:
    ldloc.s 78
    ldloc.s 226
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "MARK B2"
    ldstr " "
    ldloc.s 197
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 78
    ldloc.s 5
    ldloc.s 64
    ldloc.s 6
    ldloc.s 154
    ldloc.s 79
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 6
    ldloc.s 6
    ldloc.s 5
    ldloc.s 153
    ldloc.s 51
    ldloc.s 5
    ldloc.s 78
    ldloc.s 5
    ldloc.s 154
    ldloc.s 80
    ldloc.s 6
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 5
    ldloc.s 6
    ldloc.s 153
    ldloc.s 79
    ldloc.s 5
    ldloc.s 50
    ldloc.s 5
    ldloc.s 154
    ldloc.s 81
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 5
    ldloc.s 153
    ldloc.s 47
    ldloc.s 5
    ldloc.s 79
    ldloc.s 5
    ldloc.s 154
    ldloc.s 82
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If99_else
    ldstr "ATTN BW FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If99_else:
    ldloc.s 14
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 232
    ldloc.s 14
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 233
    ldloc.s 232
    ldloc.s 81
    ldloc.s 14
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W100_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W100_end
    ldc.r4 0.0
    stloc.s 234
    ldc.i4 0
    stloc.s 201
  run_W101_start:
    ldloc.s 201
    ldloc.s 5
    clt
    brfalse run_W101_end
    ldloc.s 163
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 235
    ldloc.s 232
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 236
    ldloc.s 234
    ldloc.s 235
    ldloc.s 236
    mul
    add
    stloc.s 234
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W101_start
  run_W101_end:
    ldc.i4 0
    stloc.s 201
  run_W102_start:
    ldloc.s 201
    ldloc.s 5
    clt
    brfalse run_W102_end
    ldloc.s 163
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 235
    ldloc.s 232
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 236
    ldloc.s 233
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 235
    ldloc.s 236
    ldloc.s 234
    sub
    mul
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W102_start
  run_W102_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W100_start
  run_W100_end:
    ldloc.s 83
    ldloc.s 233
    ldloc.s 14
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 5
    ldloc.s 155
    ldloc.s 83
    ldloc.s 5
    ldloc.s 49
    ldloc.s 5
    ldloc.s 154
    ldloc.s 84
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 5
    ldloc.s 155
    ldloc.s 83
    ldloc.s 5
    ldloc.s 48
    ldloc.s 5
    ldloc.s 154
    ldloc.s 85
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If103_else
    ldstr "QK BW FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If103_else:
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 6
    ldloc.s 6
    ldloc.s 5
    ldloc.s 153
    ldloc.s 45
    ldloc.s 5
    ldloc.s 84
    ldloc.s 5
    ldloc.s 154
    ldloc.s 68
    ldloc.s 6
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 6
    ldloc.s 6
    ldloc.s 5
    ldloc.s 153
    ldloc.s 45
    ldloc.s 5
    ldloc.s 85
    ldloc.s 5
    ldloc.s 154
    ldloc.s 69
    ldloc.s 6
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 6
    ldloc.s 6
    ldloc.s 5
    ldloc.s 153
    ldloc.s 45
    ldloc.s 5
    ldloc.s 82
    ldloc.s 5
    ldloc.s 154
    ldloc.s 70
    ldloc.s 6
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If104_else
    ldstr "WQKV BW FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If104_else:
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 84
    ldloc.s 5
    ldloc.s 61
    ldloc.s 6
    ldloc.s 154
    ldloc.s 88
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 85
    ldloc.s 5
    ldloc.s 62
    ldloc.s 6
    ldloc.s 154
    ldloc.s 89
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 5
    ldloc.s 6
    ldloc.s 6
    ldloc.s 153
    ldloc.s 82
    ldloc.s 5
    ldloc.s 63
    ldloc.s 6
    ldloc.s 154
    ldloc.s 90
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If105_else
    ldstr "YQKV BW FAIL"
    ldstr " "
    ldloc.s 4
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If105_else:
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 237
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 238
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 239
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 240
    ldloc.s 237
    ldloc.s 88
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 238
    ldloc.s 89
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 239
    ldloc.s 90
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W106_start:
    ldloc.s 198
    ldloc.s 5
    clt
    brfalse run_W106_end
    ldc.i4 0
    stloc.s 201
  run_W107_start:
    ldloc.s 201
    ldloc.s 6
    clt
    brfalse run_W107_end
    ldloc.s 237
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 238
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    ldloc.s 239
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 241
    ldloc.s 240
    ldloc.s 198
    ldloc.s 201
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 241
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 201
    ldc.i4 1
    add
    stloc.s 201
    br run_W107_start
  run_W107_end:
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W106_start
  run_W106_end:
    ldloc.s 86
    ldloc.s 240
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 174
    ldloc.s 72
    ldloc.s 18
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 175
    ldloc.s 73
    ldloc.s 19
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 176
    ldloc.s 68
    ldloc.s 17
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 177
    ldloc.s 69
    ldloc.s 17
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 178
    ldloc.s 70
    ldloc.s 17
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 179
    ldloc.s 80
    ldloc.s 17
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 180
    ldloc.s 74
    ldloc.s 20
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W108_start:
    ldloc.s 198
    ldloc.s 254
    clt
    brfalse run_W108_end
    ldloc.s 28
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 196
    ldloc.s 174
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 230
    ldloc.s 28
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W108_start
  run_W108_end:
    ldc.i4 0
    stloc.s 198
  run_W109_start:
    ldloc.s 198
    ldloc.s 255
    clt
    brfalse run_W109_end
    ldloc.s 29
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 196
    ldloc.s 175
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 230
    ldloc.s 29
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W109_start
  run_W109_end:
    ldc.i4 0
    stloc.s 198
  run_W110_start:
    ldloc.s 198
    ldloc.s 256
    clt
    brfalse run_W110_end
    ldloc.s 24
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 196
    ldloc.s 176
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 230
    ldloc.s 24
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 25
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 196
    ldloc.s 177
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 230
    ldloc.s 25
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 26
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 196
    ldloc.s 178
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 230
    ldloc.s 26
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 27
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 196
    ldloc.s 179
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 230
    ldloc.s 27
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W110_start
  run_W110_end:
    ldc.i4 0
    stloc.s 198
  run_W111_start:
    ldloc.s 198
    ldloc.s 257
    clt
    brfalse run_W111_end
    ldloc.s 30
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 196
    ldloc.s 180
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 230
    ldloc.s 30
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W111_start
  run_W111_end:
    ldloc.s 65
    ldloc.s 28
    ldloc.s 18
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 66
    ldloc.s 29
    ldloc.s 19
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 61
    ldloc.s 24
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 62
    ldloc.s 25
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 63
    ldloc.s 26
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 64
    ldloc.s 27
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 67
    ldloc.s 30
    ldloc.s 20
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "MARK UPD"
    ldstr " "
    ldloc.s 197
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 174
    ldloc.s 137
    ldloc.s 18
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 175
    ldloc.s 138
    ldloc.s 19
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 176
    ldloc.s 133
    ldloc.s 17
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 177
    ldloc.s 134
    ldloc.s 17
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 178
    ldloc.s 135
    ldloc.s 17
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 179
    ldloc.s 145
    ldloc.s 17
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 180
    ldloc.s 139
    ldloc.s 20
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldc.i4 0
    stloc.s 198
  run_W112_start:
    ldloc.s 198
    ldloc.s 254
    clt
    brfalse run_W112_end
    ldloc.s 96
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 196
    ldloc.s 174
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 230
    ldloc.s 96
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W112_start
  run_W112_end:
    ldc.i4 0
    stloc.s 198
  run_W113_start:
    ldloc.s 198
    ldloc.s 255
    clt
    brfalse run_W113_end
    ldloc.s 97
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 196
    ldloc.s 175
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 230
    ldloc.s 97
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W113_start
  run_W113_end:
    ldc.i4 0
    stloc.s 198
  run_W114_start:
    ldloc.s 198
    ldloc.s 256
    clt
    brfalse run_W114_end
    ldloc.s 92
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 196
    ldloc.s 176
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 230
    ldloc.s 92
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 93
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 196
    ldloc.s 177
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 230
    ldloc.s 93
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 94
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 196
    ldloc.s 178
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 230
    ldloc.s 94
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 95
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 196
    ldloc.s 179
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 230
    ldloc.s 95
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W114_start
  run_W114_end:
    ldc.i4 0
    stloc.s 198
  run_W115_start:
    ldloc.s 198
    ldloc.s 257
    clt
    brfalse run_W115_end
    ldloc.s 98
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 196
    ldloc.s 180
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 230
    ldloc.s 98
    ldloc.s 198
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 230
    stind.r4
    ldc.i8 0
    stloc.s 206
    ldloc.s 198
    ldc.i4 1
    add
    stloc.s 198
    br run_W115_start
  run_W115_end:
    ldloc.s 130
    ldloc.s 96
    ldloc.s 18
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 131
    ldloc.s 97
    ldloc.s 19
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 126
    ldloc.s 92
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 127
    ldloc.s 93
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 128
    ldloc.s 94
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 129
    ldloc.s 95
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldloc.s 132
    ldloc.s 98
    ldloc.s 20
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 3
    ldstr "MARK UPD"
    ldstr " "
    ldloc.s 197
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 197
    ldc.i4 1
    add
    stloc.s 197
    br run_W24_start
  run_W24_end:
    ldstr "BATCH DONE"
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 0
    ret
  }
  .method public static void Main(string[] args) cil managed
  {
    .entrypoint
    .maxstack 8
    call int32 TKVApp::'run'()
    call void [mscorlib]System.Environment::Exit(int32)
    ret
  }
.method public hidebysig static pinvokeimpl("cuda.dll" as "cuInit" cdecl)
    int32 __pinvoke_cu_init(int32) cil managed preservesig {}
.method public hidebysig static pinvokeimpl("cudart.dll" as "cudaDeviceSynchronize" cdecl)
    int32 __pinvoke_cuda_sync() cil managed preservesig {}
.method public hidebysig static pinvokeimpl("cudart.dll" as "cudaMalloc" cdecl)
    int32 __pinvoke_cuda_malloc(int64, int64) cil managed preservesig {}
.method public hidebysig static pinvokeimpl("cudart.dll" as "cudaMemcpy" cdecl)
    int32 __pinvoke_cuda_h2d(int64, int64, int64, int32) cil managed preservesig {}
.method public hidebysig static pinvokeimpl("cublas.dll" as "cublasCreate_v2" cdecl)
    int32 __pinvoke_cublas_create(int64) cil managed preservesig {}
.method public hidebysig static pinvokeimpl("cublas.dll" as "cublasSgemm_v2" cdecl)
    int32 __pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32) cil managed preservesig {}
}
