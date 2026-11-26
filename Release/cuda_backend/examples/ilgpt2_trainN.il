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
    .maxstack 1120
    .locals init (int32 'rc', int64 'hcell', int64 'ch', int32 'NL', int32 'T', int32 'H', int32 'F', int32 'V', int32 'hb', int32 'h4', int32 'qb', int32 'fb', int32 'sb', int32 'tvb', int32 'stb', int32 'whb', int32 'w1b', int32 'w2b', int32 'wh2', int32 'msz', int64 'cell', int64 'AWq', int64 'AWk', int64 'AWv', int64 'AWo', int64 'AW1', int64 'AW2', int64 'AGq', int64 'AGk', int64 'AGv', int64 'AGo', int64 'AG1', int64 'AG2', int64 'AX1', int64 'AY1', int64 'AS1', int64 'AY2', int64 'AX2', int64 'AS2', int64 'AP', int64 'AZ', int64 'AO', int64 'HWq', int64 'HWk', int64 'HWv', int64 'HWo', int64 'HW1', int64 'HW2', int64 'HGq', int64 'HGk', int64 'HGv', int64 'HGo', int64 'HG1', int64 'HG2', int64 'one', int64 'wh', int64 'zero', int64 'hal', int64 'hX', int64 'hIds', int32 'ii', int32 'jj', int32 '__idiv1003712_a', int32 '__idiv1003712_b', int32 '__idiv1003712_q', int32 '__idiv1003712_r', int32 '__idiv1003730_a', int32 '__idiv1003730_b', int32 '__idiv1003730_q', int32 '__idiv1003730_r', int64 'dY1', int64 '__tern1', int64 'dS', int64 'dP', int64 'dQ', int64 'dK', int64 'dV', int64 'dA', int64 'dO', int64 'dX2', int64 'dY2', int64 'dZ', int64 'dHH', int64 'dO2', int64 'dOUT', int64 'dLG', int64 'dDL', int64 'gHH', int64 'gZ', int64 'gY2', int64 'gDX2', int64 'gA', int64 'gWo', int64 'gP', int64 'gV', int64 'gS', int64 'gQ', int64 'gK', int64 'gY1', int64 'gOUT', int64 'hY1', int64 'hY2', int64 'hST', int64 'hXH', int64 'hyq', int64 'hyk', int64 'hyv', int64 'g1h', int64 'b1h', int64 'g2h', int64 'b2h', int64 'hS', int64 'hP', int64 'hO', int64 'hX2', int64 'hO2', int64 'hOUT', int64 'hZ', int64 'hLG', int64 'hDL', int64 'hGP', int64 'hDS', int64 'hGY2', int64 'hGDX2', int64 'hy1', int64 'gWh', int64 'gW1h', int64 'gW2h', int64 'gWqh', int64 'gWkh', int64 'gWvh', int64 'gWoh', int32 'll', int64 'wqd', int64 'wkd', int64 'wvd', int64 'wod', int64 'w1d', int64 'w2d', int64 'hwq', int64 'hwk', int64 'hwv', int64 'hwo', int64 'hw1', int64 'hw2', int32 '__idiv1004290_a', int32 '__idiv1004290_b', int32 '__idiv1004290_q', int32 '__idiv1004290_r', int32 '__idiv1004308_a', int32 '__idiv1004308_b', int32 '__idiv1004308_q', int32 '__idiv1004308_r', int32 '__idiv1004326_a', int32 '__idiv1004326_b', int32 '__idiv1004326_q', int32 '__idiv1004326_r', int32 '__idiv1004344_a', int32 '__idiv1004344_b', int32 '__idiv1004344_q', int32 '__idiv1004344_r', int32 '__idiv1004369_a', int32 '__idiv1004369_b', int32 '__idiv1004369_q', int32 '__idiv1004369_r', int32 '__idiv1004401_a', int32 '__idiv1004401_b', int32 '__idiv1004401_q', int32 '__idiv1004401_r', int64 'hWh', int32 '__idiv1004471_a', int32 '__idiv1004471_b', int32 '__idiv1004471_q', int32 '__idiv1004471_r', int64 'dWh', int32 '__idiv1004508_a', int32 '__idiv1004508_b', int32 '__idiv1004508_q', int32 '__idiv1004508_r', int32 '__idiv1004519_a', int32 '__idiv1004519_b', int32 '__idiv1004519_q', int32 '__idiv1004519_r', int32 '__idiv1004530_a', int32 '__idiv1004530_b', int32 '__idiv1004530_q', int32 '__idiv1004530_r', int32 '__idiv1004541_a', int32 '__idiv1004541_b', int32 '__idiv1004541_q', int32 '__idiv1004541_r', float32 'lr', int32 'step', int64 'xh1d', int64 's1d', int64 'y2d', int64 'xh2d', int64 's2d', int64 'pd', int64 'zd', int64 'od', float32 'sm', float32 'su', float32 'sq', float32 'xv', float32 'mn', float32 'vr', float32 'rs', float32 'xhv', float32 'mx', float32 'sv', float32 'zs', float32 'ev', float32 'pv', float32 'zz', float32 'thv', float32 'e2', float32 'lossv', float32 'lv', int32 'idv', float32 'pc', float32 'dv', int64 'gqd', int64 'gkd', int64 'gvd', int64 'god', int64 'g1d', int64 'g2d', float32 'dg', float32 'rv', float32 'acc1', float32 'acc2', float32 'dvv', float32 'gvv', float32 'dxv', float32 'rst', int64 'wqh', int64 'wkh', int64 'wvh', int64 'woh', int64 'w1h', int64 'w2h', float32 'nv', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x', valuetype [System.Numerics]System.Numerics.Complex '__tkvcplx_str', object '__arr2d_src', object '__arr2d_dst', int32 '__arr2d_i', int32 '__arr2d_n', valuetype [System.Numerics]System.Numerics.Vector4 '__v4hsum', int32 '__licm253', int32 '__licm254', int32 '__licm255', int32 '__licm256')
    ldc.i4 0
    call int32 TKVApp::__pinvoke_cu_init(int32)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If1_else
    ldc.i4 1
    ret
  run_If1_else:
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
    ldc.i4 24
    stloc.s 3
    ldc.i4 512
    stloc.s 4
    ldc.i4 1024
    stloc.s 5
    ldc.i4 4
    ldloc.s 5
    mul
    stloc.s 6
    ldc.i4 50257
    stloc.s 7
    ldloc.s 5
    ldc.i4 4
    mul
    stloc.s 8
    ldloc.s 6
    ldc.i4 4
    mul
    stloc.s 9
    ldloc.s 4
    ldloc.s 5
    mul
    ldc.i4 4
    mul
    stloc.s 10
    ldloc.s 4
    ldloc.s 6
    mul
    ldc.i4 4
    mul
    stloc.s 11
    ldloc.s 4
    ldloc.s 4
    mul
    ldc.i4 4
    mul
    stloc.s 12
    ldloc.s 4
    ldloc.s 7
    mul
    ldc.i4 4
    mul
    stloc.s 13
    ldloc.s 4
    ldc.i4 8
    mul
    stloc.s 14
    ldloc.s 8
    ldloc.s 5
    mul
    stloc.s 15
    ldloc.s 9
    ldloc.s 5
    mul
    stloc.s 16
    ldloc.s 8
    ldloc.s 6
    mul
    stloc.s 17
    ldloc.s 7
    ldloc.s 8
    mul
    stloc.s 18
    ldloc.s 3
    ldc.i4 8
    mul
    stloc.s 19
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 20
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 21
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 22
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 23
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 24
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 25
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 26
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 27
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 28
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 29
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 30
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 31
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 32
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 33
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 34
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 35
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 36
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 37
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 38
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 39
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 40
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 41
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 42
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 43
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 44
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 45
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 46
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 47
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 48
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 49
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 50
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 51
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 52
    ldloc.s 19
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 53
    ldc.i4 4
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 54
    ldloc.s 54
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldc.r4 1.0
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldc.i4 4
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 56
    ldloc.s 56
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldc.r4 0.0
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldc.i4 4
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 57
    ldloc.s 57
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldc.r4 1.0
    ldloc.s 5
    conv.r4
    conv.r8
    call float64 [mscorlib]System.Math::Sqrt(float64)
    conv.r4
    div
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 10
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 58
    ldloc.s 4
    ldc.i4 4
    mul
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 59
    ldc.i4 0
    stloc.s 60
    ldc.i4 0
    stloc.s 61
  run_W2_start:
    ldloc.s 60
    ldloc.s 4
    clt
    brfalse run_W2_end
    ldc.i4 0
    stloc.s 61
  run_W3_start:
    ldloc.s 61
    ldloc.s 5
    clt
    brfalse run_W3_end
    ldloc.s 58
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.1
    ldc.r4 0.02
    ldloc.s 60
    ldloc.s 61
    add
    stloc.s 62
    ldc.i4 16
    stloc.s 63
    ldloc.s 62
    ldloc.s 63
    div
    stloc.s 64
    ldloc.s 62
    ldloc.s 63
    rem
    stloc.s 65
    ldloc.s 65
    ldc.i4.0
    beq run_idiv4_done
    ldloc.s 65
    ldloc.s 63
    xor
    ldc.i4.0
    bge run_idiv4_done
    ldloc.s 65
    ldloc.s 63
    add
    stloc.s 65
  run_idiv4_done:
    ldloc.s 65
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W3_start
  run_W3_end:
    ldloc.s 59
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 66
    ldloc.s 7
    stloc.s 67
    ldloc.s 66
    ldloc.s 67
    div
    stloc.s 68
    ldloc.s 66
    ldloc.s 67
    rem
    stloc.s 69
    ldloc.s 69
    ldc.i4.0
    beq run_idiv5_done
    ldloc.s 69
    ldloc.s 67
    xor
    ldc.i4.0
    bge run_idiv5_done
    ldloc.s 69
    ldloc.s 67
    add
    stloc.s 69
  run_idiv5_done:
    ldloc.s 69
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt32(native int, int32)
    ldc.i8 0
    stloc.s 55
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W2_start
  run_W2_end:
    ldc.i4 1
    ldc.i4.0
    ceq
    brfalse run_tern6_false
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 71
    br run_tern6_end
  run_tern6_false:
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 71
  run_tern6_end:
    ldloc.s 71
    stloc.s 70
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 70
    ldloc.s 20
    ldloc.s 12
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 72
    ldloc.s 20
    ldloc.s 12
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 73
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 74
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 75
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 76
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 77
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 78
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 79
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 80
    ldloc.s 20
    ldloc.s 11
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 81
    ldloc.s 20
    ldloc.s 11
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 82
    ldloc.s 20
    ldloc.s 11
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 83
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 84
    ldloc.s 20
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 85
    ldloc.s 20
    ldloc.s 13
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 86
    ldloc.s 20
    ldloc.s 11
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 87
    ldloc.s 20
    ldloc.s 11
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 88
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 89
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 90
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 91
    ldloc.s 20
    ldloc.s 15
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 92
    ldloc.s 20
    ldloc.s 12
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 93
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 94
    ldloc.s 20
    ldloc.s 12
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 95
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 96
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 97
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 98
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 99
    ldloc.s 10
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 100
    ldloc.s 10
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 101
    ldloc.s 14
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 102
    ldloc.s 10
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 103
    ldloc.s 10
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 104
    ldloc.s 10
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 105
    ldloc.s 10
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 106
    ldloc.s 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 107
    ldloc.s 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 108
    ldloc.s 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 109
    ldloc.s 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 110
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 111
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 112
    ldloc.s 10
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 113
    ldloc.s 10
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 114
    ldloc.s 10
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 115
    ldloc.s 10
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 116
    ldloc.s 11
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 117
    ldloc.s 13
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 118
    ldloc.s 13
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 119
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 120
    ldloc.s 12
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 121
    ldloc.s 10
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 122
    ldloc.s 10
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 123
    ldloc.s 10
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 124
    ldloc.s 18
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 125
    ldloc.s 16
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 126
    ldloc.s 17
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 127
    ldloc.s 15
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 128
    ldloc.s 15
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 129
    ldloc.s 15
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 130
    ldloc.s 15
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 131
    ldc.i4 0
    stloc.s 132
  run_W7_start:
    ldloc.s 132
    ldloc.s 3
    clt
    brfalse run_W7_end
    ldloc.s 20
    ldloc.s 15
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 133
    ldloc.s 21
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 133
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 15
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 134
    ldloc.s 22
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 134
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 15
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 135
    ldloc.s 23
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 135
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 15
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 136
    ldloc.s 24
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 136
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 16
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 137
    ldloc.s 25
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 137
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 138
    ldloc.s 26
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 138
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 15
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 27
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 15
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 28
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 15
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 29
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 15
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 30
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 16
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 31
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 17
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 32
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 33
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 34
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 14
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 35
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 36
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 37
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 14
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 38
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 12
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 39
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 11
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 40
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 20
    ldloc.s 10
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 41
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 15
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 139
    ldloc.s 15
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 140
    ldloc.s 15
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 141
    ldloc.s 15
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 142
    ldloc.s 16
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 143
    ldloc.s 17
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 144
    ldloc.s 42
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 139
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 43
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 140
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 44
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 141
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 45
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 142
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 46
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 143
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 47
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 144
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 48
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 128
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 49
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 129
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 50
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 130
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 51
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 131
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 52
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 126
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldloc.s 53
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 127
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 55
    ldc.i4 0
    stloc.s 60
  run_W8_start:
    ldloc.s 60
    ldloc.s 5
    clt
    brfalse run_W8_end
    ldc.i4 0
    stloc.s 61
  run_W9_start:
    ldloc.s 61
    ldloc.s 5
    clt
    brfalse run_W9_end
    ldloc.s 139
    ldloc.s 60
    ldloc.s 61
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.20
    ldc.r4 0.01
    ldloc.s 60
    conv.r4
    ldloc.s 61
    stloc.s 145
    ldc.i4 8
    stloc.s 146
    ldloc.s 145
    ldloc.s 146
    div
    stloc.s 147
    ldloc.s 145
    ldloc.s 146
    rem
    stloc.s 148
    ldloc.s 148
    ldc.i4.0
    beq run_idiv10_done
    ldloc.s 148
    ldloc.s 146
    xor
    ldc.i4.0
    bge run_idiv10_done
    ldloc.s 148
    ldloc.s 146
    add
    stloc.s 148
  run_idiv10_done:
    ldloc.s 148
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 140
    ldloc.s 60
    ldloc.s 61
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.15
    ldc.r4 0.01
    ldloc.s 60
    conv.r4
    ldloc.s 61
    stloc.s 149
    ldc.i4 8
    stloc.s 150
    ldloc.s 149
    ldloc.s 150
    div
    stloc.s 151
    ldloc.s 149
    ldloc.s 150
    rem
    stloc.s 152
    ldloc.s 152
    ldc.i4.0
    beq run_idiv11_done
    ldloc.s 152
    ldloc.s 150
    xor
    ldc.i4.0
    bge run_idiv11_done
    ldloc.s 152
    ldloc.s 150
    add
    stloc.s 152
  run_idiv11_done:
    ldloc.s 152
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 141
    ldloc.s 60
    ldloc.s 61
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.10
    ldc.r4 0.01
    ldloc.s 60
    conv.r4
    ldloc.s 61
    stloc.s 153
    ldc.i4 8
    stloc.s 154
    ldloc.s 153
    ldloc.s 154
    div
    stloc.s 155
    ldloc.s 153
    ldloc.s 154
    rem
    stloc.s 156
    ldloc.s 156
    ldc.i4.0
    beq run_idiv12_done
    ldloc.s 156
    ldloc.s 154
    xor
    ldc.i4.0
    bge run_idiv12_done
    ldloc.s 156
    ldloc.s 154
    add
    stloc.s 156
  run_idiv12_done:
    ldloc.s 156
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 142
    ldloc.s 60
    ldloc.s 61
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.30
    ldc.r4 0.01
    ldloc.s 60
    conv.r4
    ldloc.s 61
    stloc.s 157
    ldc.i4 8
    stloc.s 158
    ldloc.s 157
    ldloc.s 158
    div
    stloc.s 159
    ldloc.s 157
    ldloc.s 158
    rem
    stloc.s 160
    ldloc.s 160
    ldc.i4.0
    beq run_idiv13_done
    ldloc.s 160
    ldloc.s 158
    xor
    ldc.i4.0
    bge run_idiv13_done
    ldloc.s 160
    ldloc.s 158
    add
    stloc.s 160
  run_idiv13_done:
    ldloc.s 160
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W9_start
  run_W9_end:
    ldc.i4 0
    stloc.s 61
  run_W14_start:
    ldloc.s 61
    ldloc.s 6
    clt
    brfalse run_W14_end
    ldloc.s 143
    ldloc.s 60
    ldloc.s 61
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.2
    ldc.r4 0.005
    ldloc.s 60
    conv.r4
    ldloc.s 61
    stloc.s 161
    ldc.i4 8
    stloc.s 162
    ldloc.s 161
    ldloc.s 162
    div
    stloc.s 163
    ldloc.s 161
    ldloc.s 162
    rem
    stloc.s 164
    ldloc.s 164
    ldc.i4.0
    beq run_idiv15_done
    ldloc.s 164
    ldloc.s 162
    xor
    ldc.i4.0
    bge run_idiv15_done
    ldloc.s 164
    ldloc.s 162
    add
    stloc.s 164
  run_idiv15_done:
    ldloc.s 164
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W14_start
  run_W14_end:
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W8_start
  run_W8_end:
    ldc.i4 0
    stloc.s 60
  run_W16_start:
    ldloc.s 60
    ldloc.s 6
    clt
    brfalse run_W16_end
    ldc.i4 0
    stloc.s 61
  run_W17_start:
    ldloc.s 61
    ldloc.s 5
    clt
    brfalse run_W17_end
    ldloc.s 144
    ldloc.s 60
    ldloc.s 61
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
    ldloc.s 60
    conv.r4
    ldloc.s 61
    stloc.s 165
    ldc.i4 8
    stloc.s 166
    ldloc.s 165
    ldloc.s 166
    div
    stloc.s 167
    ldloc.s 165
    ldloc.s 166
    rem
    stloc.s 168
    ldloc.s 168
    ldc.i4.0
    beq run_idiv18_done
    ldloc.s 168
    ldloc.s 166
    xor
    ldc.i4.0
    bge run_idiv18_done
    ldloc.s 168
    ldloc.s 166
    add
    stloc.s 168
  run_idiv18_done:
    ldloc.s 168
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W17_start
  run_W17_end:
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W16_start
  run_W16_end:
    ldloc.s 133
    ldloc.s 139
    ldloc.s 15
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 134
    ldloc.s 140
    ldloc.s 15
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 135
    ldloc.s 141
    ldloc.s 15
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 136
    ldloc.s 142
    ldloc.s 15
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 137
    ldloc.s 143
    ldloc.s 16
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 138
    ldloc.s 144
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 132
    ldc.i4 1
    add
    stloc.s 132
    br run_W7_start
  run_W7_end:
    ldloc.s 18
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 169
    ldc.i4 0
    stloc.s 60
  run_W19_start:
    ldloc.s 60
    ldloc.s 5
    clt
    brfalse run_W19_end
    ldc.i4 0
    stloc.s 61
  run_W20_start:
    ldloc.s 61
    ldloc.s 7
    clt
    brfalse run_W20_end
    ldloc.s 169
    ldloc.s 60
    ldloc.s 61
    ldloc.s 5
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.2
    ldc.r4 0.01
    ldloc.s 60
    conv.r4
    ldloc.s 61
    stloc.s 170
    ldc.i4 8
    stloc.s 171
    ldloc.s 170
    ldloc.s 171
    div
    stloc.s 172
    ldloc.s 170
    ldloc.s 171
    rem
    stloc.s 173
    ldloc.s 173
    ldc.i4.0
    beq run_idiv21_done
    ldloc.s 173
    ldloc.s 171
    xor
    ldc.i4.0
    bge run_idiv21_done
    ldloc.s 173
    ldloc.s 171
    add
    stloc.s 173
  run_idiv21_done:
    ldloc.s 173
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W20_start
  run_W20_end:
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W19_start
  run_W19_end:
    ldloc.s 20
    ldloc.s 18
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 174
    ldloc.s 174
    ldloc.s 169
    ldloc.s 18
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.i4 0
    stloc.s 60
  run_W22_start:
    ldloc.s 60
    ldloc.s 5
    clt
    brfalse run_W22_end
    ldloc.s 107
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 1.0
    ldc.r4 0.05
    ldloc.s 60
    stloc.s 175
    ldc.i4 8
    stloc.s 176
    ldloc.s 175
    ldloc.s 176
    div
    stloc.s 177
    ldloc.s 175
    ldloc.s 176
    rem
    stloc.s 178
    ldloc.s 178
    ldc.i4.0
    beq run_idiv23_done
    ldloc.s 178
    ldloc.s 176
    xor
    ldc.i4.0
    bge run_idiv23_done
    ldloc.s 178
    ldloc.s 176
    add
    stloc.s 178
  run_idiv23_done:
    ldloc.s 178
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 108
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.01
    ldloc.s 60
    stloc.s 179
    ldc.i4 8
    stloc.s 180
    ldloc.s 179
    ldloc.s 180
    div
    stloc.s 181
    ldloc.s 179
    ldloc.s 180
    rem
    stloc.s 182
    ldloc.s 182
    ldc.i4.0
    beq run_idiv24_done
    ldloc.s 182
    ldloc.s 180
    xor
    ldc.i4.0
    bge run_idiv24_done
    ldloc.s 182
    ldloc.s 180
    add
    stloc.s 182
  run_idiv24_done:
    ldloc.s 182
    conv.r4
    mul
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 109
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 1.1
    ldc.r4 0.04
    ldloc.s 60
    stloc.s 183
    ldc.i4 8
    stloc.s 184
    ldloc.s 183
    ldloc.s 184
    div
    stloc.s 185
    ldloc.s 183
    ldloc.s 184
    rem
    stloc.s 186
    ldloc.s 186
    ldc.i4.0
    beq run_idiv25_done
    ldloc.s 186
    ldloc.s 184
    xor
    ldc.i4.0
    bge run_idiv25_done
    ldloc.s 186
    ldloc.s 184
    add
    stloc.s 186
  run_idiv25_done:
    ldloc.s 186
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 110
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.02
    ldloc.s 60
    stloc.s 187
    ldc.i4 8
    stloc.s 188
    ldloc.s 187
    ldloc.s 188
    div
    stloc.s 189
    ldloc.s 187
    ldloc.s 188
    rem
    stloc.s 190
    ldloc.s 190
    ldc.i4.0
    beq run_idiv26_done
    ldloc.s 190
    ldloc.s 188
    xor
    ldc.i4.0
    bge run_idiv26_done
    ldloc.s 190
    ldloc.s 188
    add
    stloc.s 190
  run_idiv26_done:
    ldloc.s 190
    conv.r4
    mul
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W22_start
  run_W22_end:
    ldc.r4 0.0000001
    stloc.s 191
    ldc.i4 1
    stloc.s 192
    ldloc.s 4
    ldloc.s 6
    mul
    stloc.s 253
    ldloc.s 5
    ldloc.s 5
    mul
    stloc.s 254
    ldloc.s 5
    ldloc.s 6
    mul
    stloc.s 255
    ldloc.s 6
    ldloc.s 5
    mul
    stloc.s 256
  run_W27_start:
    ldloc.s 192
    ldc.i4 2
    cgt
    ldc.i4.0
    ceq
    brfalse run_W27_end
    ldc.i4 0
    stloc.s 132
  run_W28_start:
    ldloc.s 132
    ldloc.s 3
    clt
    brfalse run_W28_end
    ldloc.s 21
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 133
    ldloc.s 22
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 134
    ldloc.s 23
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 135
    ldloc.s 24
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 136
    ldloc.s 25
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 137
    ldloc.s 26
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 138
    ldloc.s 33
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 193
    ldloc.s 35
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 194
    ldloc.s 36
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 195
    ldloc.s 37
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 196
    ldloc.s 38
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 197
    ldloc.s 39
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 198
    ldloc.s 40
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 199
    ldloc.s 41
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 200
    ldc.r4 0.0
    stloc.s 201
    ldc.i4 0
    stloc.s 60
  run_W29_start:
    ldloc.s 60
    ldloc.s 4
    clt
    brfalse run_W29_end
    ldc.r4 0.0
    stloc.s 202
    ldc.r4 0.0
    stloc.s 203
    ldc.i4 0
    stloc.s 61
  run_W30_start:
    ldloc.s 61
    ldloc.s 5
    clt
    brfalse run_W30_end
    ldloc.s 58
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 204
    ldloc.s 202
    ldloc.s 204
    add
    stloc.s 202
    ldloc.s 203
    ldloc.s 204
    ldloc.s 204
    mul
    add
    stloc.s 203
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W30_start
  run_W30_end:
    ldloc.s 202
    ldloc.s 5
    conv.r4
    div
    stloc.s 205
    ldloc.s 203
    ldloc.s 5
    conv.r4
    div
    ldloc.s 205
    ldloc.s 205
    mul
    sub
    ldc.r4 0.000001
    add
    stloc.s 206
    ldc.r4 1.0
    ldloc.s 206
    conv.r8
    call float64 [mscorlib]System.Math::Sqrt(float64)
    conv.r4
    div
    stloc.s 207
    ldloc.s 102
    ldloc.s 60
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 205
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 102
    ldloc.s 60
    ldc.i4 8
    mul
    ldc.i4 4
    add
    conv.i8
    add
    conv.i
    ldloc.s 207
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldc.i4 0
    stloc.s 61
  run_W31_start:
    ldloc.s 61
    ldloc.s 5
    clt
    brfalse run_W31_end
    ldloc.s 58
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 204
    ldloc.s 204
    ldloc.s 205
    sub
    ldloc.s 207
    mul
    stloc.s 208
    ldloc.s 100
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 208
    ldloc.s 107
    ldloc.s 61
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    ldloc.s 108
    ldloc.s 61
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 103
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 208
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W31_start
  run_W31_end:
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W29_start
  run_W29_end:
    ldloc.s 132
    ldc.i4 0
    ceq
    brfalse run_If32_else
    ldc.r4 0.0
    stloc.s 201
    ldc.i4 0
    stloc.s 60
  run_W33_start:
    ldloc.s 60
    conv.r8
    ldloc.s 10
    conv.r8
    ldc.i4 4
    dup
    brtrue run_tdiv34_nz
    pop
    ldstr "division by zero"
    newobj instance void [mscorlib]System.DivideByZeroException::.ctor(string)
    throw
  run_tdiv34_nz:
    conv.r8
    div
    clt
    brfalse run_W33_end
    ldloc.s 201
    ldloc.s 100
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 201
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W33_start
  run_W33_end:
    ldstr "F1 ln1"
    ldstr " "
    ldloc.s 201
    call string TkvStr::F32(float32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
  run_If32_else:
    ldloc.s 70
    ldloc.s 100
    ldloc.s 10
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 34
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    ldloc.s 100
    ldloc.s 10
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 193
    ldloc.s 103
    ldloc.s 10
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 194
    ldloc.s 102
    ldloc.s 14
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 4
    ldloc.s 5
    ldloc.s 5
    ldloc.s 54
    ldloc.s 70
    ldloc.s 4
    ldloc.s 133
    ldloc.s 5
    ldloc.s 56
    ldloc.s 74
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If35_else
    ldstr "Q GEMM FAIL"
    ldstr " "
    ldloc.s 132
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If35_else:
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 4
    ldloc.s 5
    ldloc.s 5
    ldloc.s 54
    ldloc.s 70
    ldloc.s 4
    ldloc.s 134
    ldloc.s 5
    ldloc.s 56
    ldloc.s 75
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If36_else
    ldstr "K GEMM FAIL"
    ldstr " "
    ldloc.s 132
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If36_else:
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 4
    ldloc.s 5
    ldloc.s 5
    ldloc.s 54
    ldloc.s 70
    ldloc.s 4
    ldloc.s 135
    ldloc.s 5
    ldloc.s 56
    ldloc.s 76
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If37_else
    ldstr "V GEMM FAIL"
    ldstr " "
    ldloc.s 132
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If37_else:
    ldloc.s 132
    ldc.i4 0
    ceq
    brfalse run_If38_else
    ldloc.s 113
    ldloc.s 76
    ldloc.s 10
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.r4 0.0
    stloc.s 201
    ldc.i4 0
    stloc.s 60
  run_W39_start:
    ldloc.s 60
    conv.r8
    ldloc.s 10
    conv.r8
    ldc.i4 4
    dup
    brtrue run_tdiv40_nz
    pop
    ldstr "division by zero"
    newobj instance void [mscorlib]System.DivideByZeroException::.ctor(string)
    throw
  run_tdiv40_nz:
    conv.r8
    div
    clt
    brfalse run_W39_end
    ldloc.s 201
    ldloc.s 113
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 201
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W39_start
  run_W39_end:
    ldstr "F2a dV"
    ldstr " "
    ldloc.s 201
    call string TkvStr::F32(float32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    ldstr "wvd"
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    ldloc.s 135
    call string TkvStr::I64(int64)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
  run_If38_else:
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 4
    ldloc.s 4
    ldloc.s 5
    ldloc.s 57
    ldloc.s 74
    ldloc.s 4
    ldloc.s 75
    ldloc.s 4
    ldloc.s 56
    ldloc.s 72
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If41_else
    ldstr "S GEMM FAIL"
    ldstr " "
    ldloc.s 132
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If41_else:
    ldloc.s 111
    ldloc.s 72
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.i4 0
    stloc.s 60
  run_W42_start:
    ldloc.s 60
    ldloc.s 4
    clt
    brfalse run_W42_end
    ldc.r4 1000000000.0
    neg
    stloc.s 209
    ldc.i4 0
    stloc.s 61
  run_W43_start:
    ldloc.s 61
    ldloc.s 60
    cgt
    ldc.i4.0
    ceq
    brfalse run_W43_end
    ldloc.s 111
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 210
    ldloc.s 210
    ldloc.s 209
    cgt
    brfalse run_If44_else
    ldloc.s 210
    stloc.s 209
  run_If44_else:
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W43_start
  run_W43_end:
    ldc.r4 0.0
    stloc.s 211
    ldc.i4 0
    stloc.s 61
  run_W45_start:
    ldloc.s 61
    ldloc.s 60
    cgt
    ldc.i4.0
    ceq
    brfalse run_W45_end
    ldloc.s 111
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 210
    ldloc.s 210
    ldloc.s 209
    sub
    conv.r8
    call float64 [mscorlib]System.Math::Exp(float64)
    conv.r4
    stloc.s 212
    ldloc.s 211
    ldloc.s 212
    add
    stloc.s 211
    ldloc.s 112
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 212
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W45_start
  run_W45_end:
    ldc.i4 0
    stloc.s 61
  run_W46_start:
    ldloc.s 61
    ldloc.s 60
    cgt
    ldc.i4.0
    ceq
    brfalse run_W46_end
    ldloc.s 112
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 213
    ldloc.s 112
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 213
    ldloc.s 211
    div
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W46_start
  run_W46_end:
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W42_start
  run_W42_end:
    ldloc.s 132
    ldc.i4 0
    ceq
    brfalse run_If47_else
    ldc.r4 0.0
    stloc.s 201
    ldc.i4 0
    stloc.s 60
  run_W48_start:
    ldloc.s 60
    conv.r8
    ldloc.s 12
    conv.r8
    ldc.i4 4
    dup
    brtrue run_tdiv49_nz
    pop
    ldstr "division by zero"
    newobj instance void [mscorlib]System.DivideByZeroException::.ctor(string)
    throw
  run_tdiv49_nz:
    conv.r8
    div
    clt
    brfalse run_W48_end
    ldloc.s 201
    ldloc.s 112
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 201
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W48_start
  run_W48_end:
    ldstr "F2 softmax"
    ldstr " "
    ldloc.s 201
    call string TkvStr::F32(float32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
  run_If47_else:
    ldloc.s 198
    ldloc.s 112
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 73
    ldloc.s 112
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 132
    ldc.i4 0
    ceq
    brfalse run_If50_else
    ldloc.s 111
    ldloc.s 73
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.r4 0.0
    stloc.s 201
    ldc.i4 0
    stloc.s 60
  run_W51_start:
    ldloc.s 60
    conv.r8
    ldloc.s 12
    conv.r8
    ldc.i4 4
    dup
    brtrue run_tdiv52_nz
    pop
    ldstr "division by zero"
    newobj instance void [mscorlib]System.DivideByZeroException::.ctor(string)
    throw
  run_tdiv52_nz:
    conv.r8
    div
    clt
    brfalse run_W51_end
    ldloc.s 201
    ldloc.s 111
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 201
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W51_start
  run_W51_end:
    ldstr "F2d dPdev"
    ldstr " "
    ldloc.s 201
    call string TkvStr::F32(float32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
  run_If50_else:
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 4
    ldloc.s 5
    ldloc.s 4
    ldloc.s 54
    ldloc.s 73
    ldloc.s 4
    ldloc.s 76
    ldloc.s 4
    ldloc.s 56
    ldloc.s 77
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If53_else
    ldstr "A GEMM FAIL"
    ldstr " "
    ldloc.s 132
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If53_else:
    ldloc.s 132
    ldc.i4 0
    ceq
    brfalse run_If54_else
    ldloc.s 113
    ldloc.s 77
    ldloc.s 10
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.r4 0.0
    stloc.s 201
    ldc.i4 0
    stloc.s 60
  run_W55_start:
    ldloc.s 60
    conv.r8
    ldloc.s 10
    conv.r8
    ldc.i4 4
    dup
    brtrue run_tdiv56_nz
    pop
    ldstr "division by zero"
    newobj instance void [mscorlib]System.DivideByZeroException::.ctor(string)
    throw
  run_tdiv56_nz:
    conv.r8
    div
    clt
    brfalse run_W55_end
    ldloc.s 201
    ldloc.s 113
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 201
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W55_start
  run_W55_end:
    ldstr "F2b dA"
    ldstr " "
    ldloc.s 201
    call string TkvStr::F32(float32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
  run_If54_else:
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 4
    ldloc.s 5
    ldloc.s 5
    ldloc.s 54
    ldloc.s 77
    ldloc.s 4
    ldloc.s 136
    ldloc.s 5
    ldloc.s 56
    ldloc.s 78
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If57_else
    ldstr "O GEMM FAIL"
    ldstr " "
    ldloc.s 132
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If57_else:
    ldloc.s 132
    ldc.i4 0
    ceq
    brfalse run_If58_else
    ldstr "F2c wod"
    ldstr " "
    ldloc.s 136
    call string TkvStr::I64(int64)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
  run_If58_else:
    ldloc.s 132
    ldc.i4 0
    ceq
    brfalse run_If59_else
    ldc.r4 0.0
    stloc.s 201
    ldc.i4 0
    stloc.s 60
  run_W60_start:
    ldloc.s 60
    conv.r8
    ldloc.s 10
    conv.r8
    ldc.i4 4
    dup
    brtrue run_tdiv61_nz
    pop
    ldstr "division by zero"
    newobj instance void [mscorlib]System.DivideByZeroException::.ctor(string)
    throw
  run_tdiv61_nz:
    conv.r8
    div
    clt
    brfalse run_W60_end
    ldloc.s 201
    ldloc.s 113
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 201
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W60_start
  run_W60_end:
    ldstr "F3 attn"
    ldstr " "
    ldloc.s 201
    call string TkvStr::F32(float32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
  run_If59_else:
    ldloc.s 113
    ldloc.s 78
    ldloc.s 10
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.i4 0
    stloc.s 60
  run_W62_start:
    ldloc.s 60
    ldloc.s 4
    clt
    brfalse run_W62_end
    ldc.i4 0
    stloc.s 61
  run_W63_start:
    ldloc.s 61
    ldloc.s 5
    clt
    brfalse run_W63_end
    ldloc.s 114
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 58
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 113
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W63_start
  run_W63_end:
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W62_start
  run_W62_end:
    ldloc.s 79
    ldloc.s 114
    ldloc.s 10
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.i4 0
    stloc.s 60
  run_W64_start:
    ldloc.s 60
    ldloc.s 4
    clt
    brfalse run_W64_end
    ldc.r4 0.0
    stloc.s 202
    ldc.r4 0.0
    stloc.s 203
    ldc.i4 0
    stloc.s 61
  run_W65_start:
    ldloc.s 61
    ldloc.s 5
    clt
    brfalse run_W65_end
    ldloc.s 114
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 204
    ldloc.s 202
    ldloc.s 204
    add
    stloc.s 202
    ldloc.s 203
    ldloc.s 204
    ldloc.s 204
    mul
    add
    stloc.s 203
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W65_start
  run_W65_end:
    ldloc.s 202
    ldloc.s 5
    conv.r4
    div
    stloc.s 205
    ldloc.s 203
    ldloc.s 5
    conv.r4
    div
    ldloc.s 205
    ldloc.s 205
    mul
    sub
    ldc.r4 0.000001
    add
    stloc.s 206
    ldc.r4 1.0
    ldloc.s 206
    conv.r8
    call float64 [mscorlib]System.Math::Sqrt(float64)
    conv.r4
    div
    stloc.s 207
    ldloc.s 102
    ldloc.s 60
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldloc.s 205
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 102
    ldloc.s 60
    ldc.i4 8
    mul
    ldc.i4 4
    add
    conv.i8
    add
    conv.i
    ldloc.s 207
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldc.i4 0
    stloc.s 61
  run_W66_start:
    ldloc.s 61
    ldloc.s 5
    clt
    brfalse run_W66_end
    ldloc.s 114
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 204
    ldloc.s 204
    ldloc.s 205
    sub
    ldloc.s 207
    mul
    stloc.s 208
    ldloc.s 101
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 208
    ldloc.s 109
    ldloc.s 61
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    ldloc.s 110
    ldloc.s 61
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 103
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 208
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W66_start
  run_W66_end:
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W64_start
  run_W64_end:
    ldloc.s 132
    ldc.i4 0
    ceq
    brfalse run_If67_else
    ldc.r4 0.0
    stloc.s 201
    ldc.i4 0
    stloc.s 60
  run_W68_start:
    ldloc.s 60
    conv.r8
    ldloc.s 10
    conv.r8
    ldc.i4 4
    dup
    brtrue run_tdiv69_nz
    pop
    ldstr "division by zero"
    newobj instance void [mscorlib]System.DivideByZeroException::.ctor(string)
    throw
  run_tdiv69_nz:
    conv.r8
    div
    clt
    brfalse run_W68_end
    ldloc.s 201
    ldloc.s 101
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 201
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W68_start
  run_W68_end:
    ldstr "F4 ln2"
    ldstr " "
    ldloc.s 201
    call string TkvStr::F32(float32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
  run_If67_else:
    ldloc.s 80
    ldloc.s 101
    ldloc.s 10
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 195
    ldloc.s 101
    ldloc.s 10
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 196
    ldloc.s 103
    ldloc.s 10
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 197
    ldloc.s 102
    ldloc.s 14
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 4
    ldloc.s 6
    ldloc.s 5
    ldloc.s 54
    ldloc.s 80
    ldloc.s 4
    ldloc.s 137
    ldloc.s 5
    ldloc.s 56
    ldloc.s 81
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 117
    ldloc.s 81
    ldloc.s 11
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 132
    ldc.i4 0
    ceq
    brfalse run_If70_else
    ldc.r4 0.0
    stloc.s 201
    ldc.i4 0
    stloc.s 60
  run_W71_start:
    ldloc.s 60
    conv.r8
    ldloc.s 11
    conv.r8
    ldc.i4 4
    dup
    brtrue run_tdiv72_nz
    pop
    ldstr "division by zero"
    newobj instance void [mscorlib]System.DivideByZeroException::.ctor(string)
    throw
  run_tdiv72_nz:
    conv.r8
    div
    clt
    brfalse run_W71_end
    ldloc.s 201
    ldloc.s 117
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 201
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W71_start
  run_W71_end:
    ldstr "F4b Z"
    ldstr " "
    ldloc.s 201
    call string TkvStr::F32(float32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    ldstr "w1d"
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    ldloc.s 137
    call string TkvStr::I64(int64)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
  run_If70_else:
    ldloc.s 199
    ldloc.s 81
    ldloc.s 11
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.i4 0
    stloc.s 60
  run_W73_start:
    ldloc.s 60
    ldloc.s 253
    clt
    brfalse run_W73_end
    ldloc.s 117
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 204
    ldc.r4 0.79788456
    ldloc.s 204
    ldc.r4 0.044715
    ldloc.s 204
    mul
    ldloc.s 204
    mul
    ldloc.s 204
    mul
    add
    mul
    stloc.s 214
    ldc.r4 1.0
    stloc.s 215
    ldloc.s 214
    ldc.r4 8.0
    neg
    clt
    brfalse run_If74_else
    ldc.r4 1.0
    neg
    stloc.s 215
    br run_If74_end
  run_If74_else:
    ldloc.s 214
    ldc.r4 8.0
    clt
    brfalse run_If75_else
    ldc.r4 2.0
    ldloc.s 214
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
    stloc.s 215
  run_If75_else:
  run_If74_end:
    ldloc.s 117
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.5
    ldloc.s 204
    mul
    ldc.r4 1.0
    ldloc.s 215
    add
    mul
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W73_start
  run_W73_end:
    ldloc.s 132
    ldc.i4 0
    ceq
    brfalse run_If76_else
    ldc.r4 0.0
    stloc.s 201
    ldc.i4 0
    stloc.s 60
  run_W77_start:
    ldloc.s 60
    conv.r8
    ldloc.s 11
    conv.r8
    ldc.i4 4
    dup
    brtrue run_tdiv78_nz
    pop
    ldstr "division by zero"
    newobj instance void [mscorlib]System.DivideByZeroException::.ctor(string)
    throw
  run_tdiv78_nz:
    conv.r8
    div
    clt
    brfalse run_W77_end
    ldloc.s 201
    ldloc.s 117
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 201
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W77_start
  run_W77_end:
    ldstr "F5 gelu"
    ldstr " "
    ldloc.s 201
    call string TkvStr::F32(float32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
  run_If76_else:
    ldloc.s 82
    ldloc.s 117
    ldloc.s 11
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 4
    ldloc.s 5
    ldloc.s 6
    ldloc.s 54
    ldloc.s 82
    ldloc.s 4
    ldloc.s 138
    ldloc.s 6
    ldloc.s 56
    ldloc.s 83
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 115
    ldloc.s 83
    ldloc.s 10
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.i4 0
    stloc.s 60
  run_W79_start:
    ldloc.s 60
    ldloc.s 4
    clt
    brfalse run_W79_end
    ldc.i4 0
    stloc.s 61
  run_W80_start:
    ldloc.s 61
    ldloc.s 5
    clt
    brfalse run_W80_end
    ldloc.s 116
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 114
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 115
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W80_start
  run_W80_end:
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W79_start
  run_W79_end:
    ldloc.s 200
    ldloc.s 116
    ldloc.s 10
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.r4 0.0
    stloc.s 201
    ldc.i4 0
    stloc.s 60
  run_W81_start:
    ldloc.s 60
    conv.r8
    ldloc.s 10
    conv.r8
    ldc.i4 4
    dup
    brtrue run_tdiv82_nz
    pop
    ldstr "division by zero"
    newobj instance void [mscorlib]System.DivideByZeroException::.ctor(string)
    throw
  run_tdiv82_nz:
    conv.r8
    div
    clt
    brfalse run_W81_end
    ldloc.s 201
    ldloc.s 116
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 201
    ldloc.s 58
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 116
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W81_start
  run_W81_end:
    ldstr "DBGL"
    ldstr " "
    ldloc.s 132
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    ldloc.s 201
    call string TkvStr::F32(float32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 132
    ldc.i4 1
    add
    stloc.s 132
    br run_W28_start
  run_W28_end:
    ldloc.s 84
    ldloc.s 116
    ldloc.s 10
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 4
    ldloc.s 7
    ldloc.s 5
    ldloc.s 54
    ldloc.s 84
    ldloc.s 4
    ldloc.s 174
    ldloc.s 5
    ldloc.s 56
    ldloc.s 85
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 118
    ldloc.s 85
    ldloc.s 13
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.r4 0.0
    stloc.s 217
    ldc.i4 0
    stloc.s 60
  run_W83_start:
    ldloc.s 60
    ldloc.s 4
    clt
    brfalse run_W83_end
    ldc.r4 1000000000.0
    neg
    stloc.s 209
    ldc.i4 0
    stloc.s 61
  run_W84_start:
    ldloc.s 61
    ldloc.s 7
    clt
    brfalse run_W84_end
    ldloc.s 118
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 218
    ldloc.s 218
    ldloc.s 209
    cgt
    brfalse run_If85_else
    ldloc.s 218
    stloc.s 209
  run_If85_else:
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W84_start
  run_W84_end:
    ldc.r4 0.0
    stloc.s 211
    ldc.i4 0
    stloc.s 61
  run_W86_start:
    ldloc.s 61
    ldloc.s 7
    clt
    brfalse run_W86_end
    ldloc.s 118
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 218
    ldloc.s 218
    ldloc.s 209
    sub
    conv.r8
    call float64 [mscorlib]System.Math::Exp(float64)
    conv.r4
    stloc.s 212
    ldloc.s 211
    ldloc.s 212
    add
    stloc.s 211
    ldloc.s 119
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 212
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W86_start
  run_W86_end:
    ldloc.s 59
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int)
    stloc.s 219
    ldloc.s 119
    ldloc.s 60
    ldloc.s 219
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 211
    div
    stloc.s 220
    ldloc.s 217
    ldloc.s 220
    conv.r8
    call float64 [mscorlib]System.Math::Log(float64)
    conv.r4
    sub
    stloc.s 217
    ldc.i4 0
    stloc.s 61
  run_W87_start:
    ldloc.s 61
    ldloc.s 7
    clt
    brfalse run_W87_end
    ldloc.s 119
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 211
    div
    stloc.s 213
    ldloc.s 213
    stloc.s 221
    ldloc.s 61
    ldloc.s 219
    ceq
    brfalse run_If88_else
    ldloc.s 221
    ldc.r4 1.0
    sub
    stloc.s 221
  run_If88_else:
    ldloc.s 119
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 221
    ldloc.s 4
    conv.r4
    div
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W87_start
  run_W87_end:
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W83_start
  run_W83_end:
    ldloc.s 217
    ldloc.s 4
    conv.r4
    div
    stloc.s 217
    ldstr "LOSS"
    ldstr " "
    ldloc.s 217
    call string TkvStr::F32(float32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 86
    ldloc.s 119
    ldloc.s 13
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldstr "MARK FWD"
    ldstr " "
    ldloc.s 192
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 4
    ldloc.s 5
    ldloc.s 7
    ldloc.s 54
    ldloc.s 86
    ldloc.s 4
    ldloc.s 174
    ldloc.s 5
    ldloc.s 56
    ldloc.s 99
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 3
    ldc.i4 1
    sub
    stloc.s 132
  run_W89_start:
    ldloc.s 132
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse run_W89_end
    ldloc.s 21
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 133
    ldloc.s 22
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 134
    ldloc.s 23
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 135
    ldloc.s 24
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 136
    ldloc.s 25
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 137
    ldloc.s 26
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 138
    ldloc.s 27
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 222
    ldloc.s 28
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 223
    ldloc.s 29
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 224
    ldloc.s 30
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 225
    ldloc.s 31
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 226
    ldloc.s 32
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 227
    ldloc.s 33
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 193
    ldloc.s 35
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 194
    ldloc.s 36
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 195
    ldloc.s 37
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 196
    ldloc.s 38
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 197
    ldloc.s 39
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 198
    ldloc.s 40
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 199
    ldloc.s 41
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 200
    ldc.r4 0.0
    stloc.s 201
    ldloc.s 200
    ldloc.s 116
    ldloc.s 10
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 6
    ldloc.s 5
    ldloc.s 4
    ldloc.s 54
    ldloc.s 82
    ldloc.s 4
    ldloc.s 99
    ldloc.s 4
    ldloc.s 56
    ldloc.s 227
    ldloc.s 6
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 4
    ldloc.s 6
    ldloc.s 5
    ldloc.s 54
    ldloc.s 99
    ldloc.s 4
    ldloc.s 138
    ldloc.s 6
    ldloc.s 56
    ldloc.s 87
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 117
    ldloc.s 199
    ldloc.s 11
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.i4 0
    stloc.s 60
  run_W90_start:
    ldloc.s 60
    ldloc.s 253
    clt
    brfalse run_W90_end
    ldloc.s 117
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 204
    ldc.r4 0.79788456
    ldloc.s 204
    ldc.r4 0.044715
    ldloc.s 204
    mul
    ldloc.s 204
    mul
    ldloc.s 204
    mul
    add
    mul
    stloc.s 214
    ldc.r4 2.0
    ldloc.s 214
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
    stloc.s 215
    ldloc.s 117
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.5
    ldloc.s 204
    mul
    ldc.r4 1.0
    ldloc.s 215
    add
    mul
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W90_start
  run_W90_end:
    ldloc.s 132
    ldc.i4 0
    ceq
    brfalse run_If91_else
    ldc.r4 0.0
    stloc.s 201
    ldc.i4 0
    stloc.s 60
  run_W92_start:
    ldloc.s 60
    conv.r8
    ldloc.s 11
    conv.r8
    ldc.i4 4
    dup
    brtrue run_tdiv93_nz
    pop
    ldstr "division by zero"
    newobj instance void [mscorlib]System.DivideByZeroException::.ctor(string)
    throw
  run_tdiv93_nz:
    conv.r8
    div
    clt
    brfalse run_W92_end
    ldloc.s 201
    ldloc.s 117
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stloc.s 201
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W92_start
  run_W92_end:
    ldstr "F5 gelu"
    ldstr " "
    ldloc.s 201
    call string TkvStr::F32(float32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
  run_If91_else:
    ldloc.s 82
    ldloc.s 117
    ldloc.s 11
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 117
    ldloc.s 199
    ldloc.s 11
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 122
    ldloc.s 87
    ldloc.s 11
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.i4 0
    stloc.s 60
  run_W94_start:
    ldloc.s 60
    ldloc.s 253
    clt
    brfalse run_W94_end
    ldloc.s 117
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 204
    ldc.r4 0.79788456
    ldloc.s 204
    ldc.r4 0.044715
    ldloc.s 204
    mul
    ldloc.s 204
    mul
    ldloc.s 204
    mul
    add
    mul
    stloc.s 214
    ldc.r4 1.0
    stloc.s 215
    ldloc.s 214
    ldc.r4 8.0
    neg
    clt
    brfalse run_If95_else
    ldc.r4 1.0
    neg
    stloc.s 215
    br run_If95_end
  run_If95_else:
    ldloc.s 214
    ldc.r4 8.0
    clt
    brfalse run_If96_else
    ldc.r4 2.0
    ldloc.s 214
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
    stloc.s 215
  run_If96_else:
  run_If95_end:
    ldc.r4 0.5
    ldc.r4 1.0
    ldloc.s 215
    add
    mul
    ldc.r4 0.5
    ldloc.s 204
    mul
    ldc.r4 1.0
    ldloc.s 215
    ldloc.s 215
    mul
    sub
    mul
    ldc.r4 0.79788456
    mul
    ldc.r4 1.0
    ldc.r4 0.134145
    ldloc.s 204
    mul
    ldloc.s 204
    mul
    add
    mul
    add
    stloc.s 228
    ldloc.s 117
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 122
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 228
    mul
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W94_start
  run_W94_end:
    ldloc.s 88
    ldloc.s 117
    ldloc.s 11
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 80
    ldloc.s 195
    ldloc.s 10
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 5
    ldloc.s 6
    ldloc.s 4
    ldloc.s 54
    ldloc.s 80
    ldloc.s 4
    ldloc.s 88
    ldloc.s 4
    ldloc.s 56
    ldloc.s 226
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 4
    ldloc.s 5
    ldloc.s 6
    ldloc.s 54
    ldloc.s 88
    ldloc.s 4
    ldloc.s 137
    ldloc.s 5
    ldloc.s 56
    ldloc.s 89
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 101
    ldloc.s 195
    ldloc.s 10
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 103
    ldloc.s 196
    ldloc.s 10
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 102
    ldloc.s 197
    ldloc.s 14
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 122
    ldloc.s 89
    ldloc.s 10
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.i4 0
    stloc.s 60
  run_W97_start:
    ldloc.s 60
    ldloc.s 4
    clt
    brfalse run_W97_end
    ldloc.s 102
    ldloc.s 60
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 205
    ldloc.s 102
    ldloc.s 60
    ldc.i4 8
    mul
    ldc.i4 4
    add
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 229
    ldc.r4 0.0
    stloc.s 230
    ldc.r4 0.0
    stloc.s 231
    ldc.i4 0
    stloc.s 61
  run_W98_start:
    ldloc.s 61
    ldloc.s 5
    clt
    brfalse run_W98_end
    ldloc.s 122
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 232
    ldloc.s 109
    ldloc.s 61
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 233
    ldloc.s 103
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 208
    ldloc.s 230
    ldloc.s 232
    ldloc.s 233
    mul
    add
    stloc.s 230
    ldloc.s 231
    ldloc.s 232
    ldloc.s 233
    mul
    ldloc.s 208
    mul
    add
    stloc.s 231
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W98_start
  run_W98_end:
    ldc.i4 0
    stloc.s 61
  run_W99_start:
    ldloc.s 61
    ldloc.s 5
    clt
    brfalse run_W99_end
    ldloc.s 122
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 232
    ldloc.s 109
    ldloc.s 61
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 233
    ldloc.s 103
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 208
    ldloc.s 232
    ldloc.s 233
    mul
    ldloc.s 230
    ldloc.s 5
    conv.r4
    div
    sub
    ldloc.s 208
    ldloc.s 231
    mul
    ldloc.s 5
    conv.r4
    div
    sub
    ldloc.s 229
    mul
    stloc.s 234
    ldloc.s 123
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 234
    ldloc.s 116
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W99_start
  run_W99_end:
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W97_start
  run_W97_end:
    ldloc.s 90
    ldloc.s 123
    ldloc.s 10
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 4
    ldloc.s 5
    ldloc.s 5
    ldloc.s 54
    ldloc.s 90
    ldloc.s 4
    ldloc.s 136
    ldloc.s 5
    ldloc.s 56
    ldloc.s 91
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 5
    ldloc.s 5
    ldloc.s 4
    ldloc.s 54
    ldloc.s 77
    ldloc.s 4
    ldloc.s 90
    ldloc.s 4
    ldloc.s 56
    ldloc.s 92
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 4
    ldloc.s 4
    ldloc.s 5
    ldloc.s 54
    ldloc.s 91
    ldloc.s 4
    ldloc.s 76
    ldloc.s 4
    ldloc.s 56
    ldloc.s 93
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 4
    ldloc.s 5
    ldloc.s 4
    ldloc.s 54
    ldloc.s 73
    ldloc.s 4
    ldloc.s 91
    ldloc.s 4
    ldloc.s 56
    ldloc.s 94
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 112
    ldloc.s 198
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 120
    ldloc.s 93
    ldloc.s 12
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.i4 0
    stloc.s 60
  run_W100_start:
    ldloc.s 60
    ldloc.s 4
    clt
    brfalse run_W100_end
    ldc.r4 0.0
    stloc.s 235
    ldc.i4 0
    stloc.s 61
  run_W101_start:
    ldloc.s 61
    ldloc.s 4
    clt
    brfalse run_W101_end
    ldloc.s 235
    ldloc.s 112
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 120
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    add
    stloc.s 235
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W101_start
  run_W101_end:
    ldc.i4 0
    stloc.s 61
  run_W102_start:
    ldloc.s 61
    ldloc.s 4
    clt
    brfalse run_W102_end
    ldloc.s 121
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 112
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 120
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 235
    sub
    mul
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W102_start
  run_W102_end:
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W100_start
  run_W100_end:
    ldloc.s 95
    ldloc.s 121
    ldloc.s 12
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 4
    ldloc.s 5
    ldloc.s 4
    ldloc.s 57
    ldloc.s 95
    ldloc.s 4
    ldloc.s 75
    ldloc.s 4
    ldloc.s 56
    ldloc.s 96
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 4
    ldloc.s 5
    ldloc.s 4
    ldloc.s 57
    ldloc.s 95
    ldloc.s 4
    ldloc.s 74
    ldloc.s 4
    ldloc.s 56
    ldloc.s 97
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 5
    ldloc.s 5
    ldloc.s 4
    ldloc.s 54
    ldloc.s 70
    ldloc.s 4
    ldloc.s 96
    ldloc.s 4
    ldloc.s 56
    ldloc.s 222
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 5
    ldloc.s 5
    ldloc.s 4
    ldloc.s 54
    ldloc.s 70
    ldloc.s 4
    ldloc.s 97
    ldloc.s 4
    ldloc.s 56
    ldloc.s 223
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 2
    ldc.i4 1
    ldc.i4 0
    ldloc.s 5
    ldloc.s 5
    ldloc.s 4
    ldloc.s 54
    ldloc.s 70
    ldloc.s 4
    ldloc.s 94
    ldloc.s 4
    ldloc.s 56
    ldloc.s 224
    ldloc.s 5
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 4
    ldloc.s 5
    ldloc.s 5
    ldloc.s 54
    ldloc.s 96
    ldloc.s 4
    ldloc.s 133
    ldloc.s 5
    ldloc.s 56
    ldloc.s 74
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 4
    ldloc.s 5
    ldloc.s 5
    ldloc.s 54
    ldloc.s 97
    ldloc.s 4
    ldloc.s 134
    ldloc.s 5
    ldloc.s 56
    ldloc.s 75
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 2
    ldc.i4 0
    ldc.i4 1
    ldloc.s 4
    ldloc.s 5
    ldloc.s 5
    ldloc.s 54
    ldloc.s 94
    ldloc.s 4
    ldloc.s 135
    ldloc.s 5
    ldloc.s 56
    ldloc.s 76
    ldloc.s 4
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 104
    ldloc.s 74
    ldloc.s 10
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 105
    ldloc.s 75
    ldloc.s 10
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 106
    ldloc.s 76
    ldloc.s 10
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.i4 0
    stloc.s 60
  run_W103_start:
    ldloc.s 60
    ldloc.s 4
    clt
    brfalse run_W103_end
    ldc.i4 0
    stloc.s 61
  run_W104_start:
    ldloc.s 61
    ldloc.s 5
    clt
    brfalse run_W104_end
    ldloc.s 124
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 104
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 105
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    ldloc.s 106
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    add
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W104_start
  run_W104_end:
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W103_start
  run_W103_end:
    ldloc.s 70
    ldloc.s 34
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    ldloc.s 10
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 98
    ldloc.s 124
    ldloc.s 10
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 103
    ldloc.s 193
    ldloc.s 10
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 102
    ldloc.s 194
    ldloc.s 14
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 122
    ldloc.s 98
    ldloc.s 10
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.i4 0
    stloc.s 60
  run_W105_start:
    ldloc.s 60
    ldloc.s 4
    clt
    brfalse run_W105_end
    ldloc.s 102
    ldloc.s 60
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 205
    ldloc.s 102
    ldloc.s 60
    ldc.i4 8
    mul
    ldc.i4 4
    add
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 229
    ldc.r4 0.0
    stloc.s 230
    ldc.r4 0.0
    stloc.s 231
    ldc.i4 0
    stloc.s 61
  run_W106_start:
    ldloc.s 61
    ldloc.s 5
    clt
    brfalse run_W106_end
    ldloc.s 122
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 232
    ldloc.s 107
    ldloc.s 61
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 233
    ldloc.s 103
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 208
    ldloc.s 230
    ldloc.s 232
    ldloc.s 233
    mul
    add
    stloc.s 230
    ldloc.s 231
    ldloc.s 232
    ldloc.s 233
    mul
    ldloc.s 208
    mul
    add
    stloc.s 231
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W106_start
  run_W106_end:
    ldc.i4 0
    stloc.s 61
  run_W107_start:
    ldloc.s 61
    ldloc.s 5
    clt
    brfalse run_W107_end
    ldloc.s 122
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 232
    ldloc.s 107
    ldloc.s 61
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 233
    ldloc.s 103
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 208
    ldloc.s 123
    ldloc.s 60
    ldloc.s 61
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 232
    ldloc.s 233
    mul
    ldloc.s 230
    ldloc.s 5
    conv.r4
    div
    sub
    ldloc.s 208
    ldloc.s 231
    mul
    ldloc.s 5
    conv.r4
    div
    sub
    ldloc.s 229
    mul
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 61
    ldc.i4 1
    add
    stloc.s 61
    br run_W107_start
  run_W107_end:
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W105_start
  run_W105_end:
    ldloc.s 99
    ldloc.s 123
    ldloc.s 10
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldstr "MARK B"
    ldstr " "
    ldloc.s 132
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 132
    ldc.i4 1
    sub
    stloc.s 132
    br run_W89_start
  run_W89_end:
    ldstr "MARK BWD"
    ldstr " "
    ldloc.s 192
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 0
    stloc.s 132
  run_W108_start:
    ldloc.s 132
    ldloc.s 3
    clt
    brfalse run_W108_end
    ldloc.s 27
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 222
    ldloc.s 28
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 223
    ldloc.s 29
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 224
    ldloc.s 30
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 225
    ldloc.s 31
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 226
    ldloc.s 32
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 227
    ldloc.s 42
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 236
    ldloc.s 43
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 237
    ldloc.s 44
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 238
    ldloc.s 45
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 239
    ldloc.s 46
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 240
    ldloc.s 47
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 241
    ldloc.s 128
    ldloc.s 222
    ldloc.s 15
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 129
    ldloc.s 223
    ldloc.s 15
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 130
    ldloc.s 224
    ldloc.s 15
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 131
    ldloc.s 225
    ldloc.s 15
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 126
    ldloc.s 226
    ldloc.s 16
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 127
    ldloc.s 227
    ldloc.s 17
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldc.i4 0
    stloc.s 60
  run_W109_start:
    ldloc.s 60
    ldloc.s 254
    clt
    brfalse run_W109_end
    ldloc.s 236
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 191
    ldloc.s 128
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 242
    ldloc.s 236
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 242
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 237
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 191
    ldloc.s 129
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 242
    ldloc.s 237
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 242
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 238
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 191
    ldloc.s 130
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 242
    ldloc.s 238
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 242
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 239
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 191
    ldloc.s 131
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 242
    ldloc.s 239
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 242
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W109_start
  run_W109_end:
    ldc.i4 0
    stloc.s 60
  run_W110_start:
    ldloc.s 60
    ldloc.s 255
    clt
    brfalse run_W110_end
    ldloc.s 240
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 191
    ldloc.s 126
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 242
    ldloc.s 240
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 242
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W110_start
  run_W110_end:
    ldc.i4 0
    stloc.s 60
  run_W111_start:
    ldloc.s 60
    ldloc.s 256
    clt
    brfalse run_W111_end
    ldloc.s 241
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    ldloc.s 191
    ldloc.s 127
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    mul
    sub
    stloc.s 242
    ldloc.s 241
    ldloc.s 60
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 242
    stind.r4
    ldc.i8 0
    stloc.s 55
    ldloc.s 60
    ldc.i4 1
    add
    stloc.s 60
    br run_W111_start
  run_W111_end:
    ldloc.s 21
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    ldloc.s 236
    ldloc.s 15
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 22
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    ldloc.s 237
    ldloc.s 15
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 23
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    ldloc.s 238
    ldloc.s 15
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 24
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    ldloc.s 239
    ldloc.s 15
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 25
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    ldloc.s 240
    ldloc.s 16
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 26
    ldloc.s 132
    ldc.i4 8
    mul
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    ldloc.s 241
    ldloc.s 17
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 132
    ldc.i4 1
    add
    stloc.s 132
    br run_W108_start
  run_W108_end:
    ldstr "MARK UPD"
    ldstr " "
    ldloc.s 192
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldloc.s 192
    ldc.i4 1
    add
    stloc.s 192
    br run_W27_start
  run_W27_end:
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
.method public hidebysig static pinvokeimpl("cudart.dll" as "cudaMalloc" cdecl)
    int32 __pinvoke_cuda_malloc(int64, int64) cil managed preservesig {}
.method public hidebysig static pinvokeimpl("cudart.dll" as "cudaMemcpy" cdecl)
    int32 __pinvoke_cuda_h2d(int64, int64, int64, int32) cil managed preservesig {}
.method public hidebysig static pinvokeimpl("cublas.dll" as "cublasCreate_v2" cdecl)
    int32 __pinvoke_cublas_create(int64) cil managed preservesig {}
.method public hidebysig static pinvokeimpl("cublas.dll" as "cublasSgemm_v2" cdecl)
    int32 __pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32) cil managed preservesig {}
}
