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
    .maxstack 222
    .locals init (int32 'rc', int64 'hc', int64 'ch', int32 'T', int32 'D', int32 'V', int32 'td', int32 'dv', int32 'tb', int32 'vb', int64 'hX', int64 'hW1', int64 'hW2', int64 'hb1', int64 'hb2', int64 'hIds', int64 'hLG', int64 'hcell', int64 'ha', int64 'wa1', int64 'hb', int64 'wb0', int32 'i', int32 'j', int64 'wx', int32 'idv', int32 '__idiv1000097_a', int32 '__idiv1000097_b', int32 '__idiv1000097_q', int32 '__idiv1000097_r', int64 'wids', int64 'ww1', int64 'wb1', int64 'ww2', int64 'wb2', int64 'cell', int64 'dX', int64 'dW1', int64 'dZ', int64 'dH', int64 'dW2', int64 'dLG', int64 'db1', int64 'db2', int64 'hbe1', int64 'hbe2', int32 'ii', int32 'jj', float32 'bv1', int64 'wbe1', float32 'bv2', int64 'wbe2', int64 'dbe1', int64 'dbe2', int64 'wbe1d', int64 'wbe2d', int64 'wa', int64 'wb', int64 'wc', int64 'wd', int64 'we', class [mscorlib]System.Collections.Generic.List`1<unsigned int8> 'PTX2', class [mscorlib]System.Collections.Generic.List`1<unsigned int8> 'FN2', int64 'p2', valuetype TkvInt 'k2', int64 'wu2', int64 'wz2', int64 'm2', int64 'o2', int64 'f2', valuetype TkvInt 'r2', int64 'ww2b', int64 'c2', int64 'fn2', int64 'b0', int64 'b1p', int64 'wb1p', int64 'b2p', int64 'wb2p', int64 'b3p', int64 'wb3p', int64 'pa2', int64 'wp20', int64 'wp21', int64 'wp22', int64 'wp23', class [mscorlib]System.Collections.Generic.List`1<unsigned int8> 'PTX3', class [mscorlib]System.Collections.Generic.List`1<unsigned int8> 'FN3', int64 'p3', int32 'k3', int64 'wu3', int64 'wz3', int64 'm3', int64 'o3', int64 'f3', int32 'r3', int64 'ww3', int64 'c3', int64 'fn3', int64 'g0', int64 'wg0', int64 'g1', int64 'wg1', int64 'g2', int64 'wg2', int64 'pag', int64 'wg3', int64 'wg4', int64 'wg5', int64 'q0', int64 'wq0', int64 'q1', int64 'wq1', int64 'q2', int64 'wq2', int64 'q3', int64 'wq3n', int64 'paq', int64 'wq4', int64 'wq5', int64 'wq6', int64 'wq7', int64 'wr', float32 'loss', float32 'mx', float32 'lv', float32 'zsum', float32 'ev', int32 'idv2', float32 'lv2', float32 'ev2', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x', valuetype [System.Numerics]System.Numerics.Complex '__tkvcplx_str', object '__arr2d_src', object '__arr2d_dst', int32 '__arr2d_i', int32 '__arr2d_n', valuetype [System.Numerics]System.Numerics.Vector4 '__v4hsum')
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
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
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
    ldc.i4 4
    stloc.s 3
    ldc.i4 8
    stloc.s 4
    ldc.i4 8
    stloc.s 5
    ldloc.s 3
    ldloc.s 4
    mul
    stloc.s 6
    ldloc.s 4
    ldloc.s 5
    mul
    stloc.s 7
    ldloc.s 6
    ldc.i4 4
    mul
    stloc.s 8
    ldloc.s 7
    ldc.i4 4
    mul
    stloc.s 9
    ldloc.s 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 10
    ldloc.s 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 11
    ldloc.s 9
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 12
    ldloc.s 4
    ldc.i4 4
    mul
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 13
    ldloc.s 5
    ldc.i4 4
    mul
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 14
    ldloc.s 3
    ldc.i4 4
    mul
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 15
    ldloc.s 9
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 16
    ldc.i4 4
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 17
    ldc.i4 4
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 18
    ldloc.s 18
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldc.r4 1.0
    stind.r4
    ldc.i8 0
    stloc.s 19
    ldc.i4 4
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 20
    ldloc.s 20
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldc.r4 0.0
    stind.r4
    ldc.i8 0
    stloc.s 21
    ldc.i4 0
    stloc.s 22
    ldc.i4 0
    stloc.s 23
  run_W2_start:
    ldloc.s 22
    ldloc.s 3
    clt
    brfalse run_W2_end
    ldc.i4 0
    stloc.s 23
  run_W3_start:
    ldloc.s 23
    ldloc.s 4
    clt
    brfalse run_W3_end
    ldloc.s 10
    ldloc.s 22
    ldloc.s 23
    ldloc.s 3
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.1
    ldc.r4 0.02
    ldloc.s 22
    conv.r4
    ldloc.s 23
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 24
    ldloc.s 23
    ldc.i4 1
    add
    stloc.s 23
    br run_W3_start
  run_W3_end:
    ldloc.s 22
    ldc.i4 1
    add
    stloc.s 26
    ldloc.s 5
    stloc.s 27
    ldloc.s 26
    ldloc.s 27
    div
    stloc.s 28
    ldloc.s 26
    ldloc.s 27
    rem
    stloc.s 29
    ldloc.s 29
    ldc.i4.0
    beq run_idiv4_done
    ldloc.s 29
    ldloc.s 27
    xor
    ldc.i4.0
    bge run_idiv4_done
    ldloc.s 29
    ldloc.s 27
    add
    stloc.s 29
  run_idiv4_done:
    ldloc.s 29
    stloc.s 25
    ldloc.s 15
    ldloc.s 22
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 25
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt32(native int, int32)
    ldc.i8 0
    stloc.s 30
    ldloc.s 22
    ldc.i4 1
    add
    stloc.s 22
    br run_W2_start
  run_W2_end:
    ldc.i4 0
    stloc.s 22
  run_W5_start:
    ldloc.s 22
    ldloc.s 4
    clt
    brfalse run_W5_end
    ldc.i4 0
    stloc.s 23
  run_W6_start:
    ldloc.s 23
    ldloc.s 4
    clt
    brfalse run_W6_end
    ldloc.s 11
    ldloc.s 22
    ldloc.s 23
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.2
    ldc.r4 0.01
    ldloc.s 22
    conv.r4
    ldloc.s 23
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 31
    ldloc.s 23
    ldc.i4 1
    add
    stloc.s 23
    br run_W6_start
  run_W6_end:
    ldloc.s 13
    ldloc.s 22
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.1
    stind.r4
    ldc.i8 0
    stloc.s 32
    ldloc.s 22
    ldc.i4 1
    add
    stloc.s 22
    br run_W5_start
  run_W5_end:
    ldc.i4 0
    stloc.s 22
  run_W7_start:
    ldloc.s 22
    ldloc.s 4
    clt
    brfalse run_W7_end
    ldc.i4 0
    stloc.s 23
  run_W8_start:
    ldloc.s 23
    ldloc.s 5
    clt
    brfalse run_W8_end
    ldloc.s 12
    ldloc.s 22
    ldloc.s 23
    ldloc.s 4
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.3
    ldc.r4 0.01
    ldloc.s 22
    conv.r4
    ldloc.s 23
    conv.r4
    add
    conv.r4
    mul
    add
    stind.r4
    ldc.i8 0
    stloc.s 33
    ldloc.s 23
    ldc.i4 1
    add
    stloc.s 23
    br run_W8_start
  run_W8_end:
    ldloc.s 22
    ldc.i4 1
    add
    stloc.s 22
    br run_W7_start
  run_W7_end:
    ldc.i4 0
    stloc.s 22
  run_W9_start:
    ldloc.s 22
    ldloc.s 5
    clt
    brfalse run_W9_end
    ldloc.s 14
    ldloc.s 22
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldc.r4 0.05
    stind.r4
    ldc.i8 0
    stloc.s 34
    ldloc.s 22
    ldc.i4 1
    add
    stloc.s 22
    br run_W9_start
  run_W9_end:
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 35
    ldloc.s 35
    ldloc.s 8
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 35
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 36
    ldloc.s 35
    ldloc.s 8
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 35
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 37
    ldloc.s 35
    ldloc.s 8
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 35
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 38
    ldloc.s 35
    ldloc.s 8
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 35
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 39
    ldloc.s 35
    ldloc.s 9
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 35
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 40
    ldloc.s 35
    ldloc.s 9
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 35
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 41
    ldloc.s 35
    ldloc.s 4
    ldc.i4 4
    mul
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 35
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 42
    ldloc.s 35
    ldloc.s 5
    ldc.i4 4
    mul
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 35
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 43
    ldloc.s 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 44
    ldloc.s 9
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 45
    ldc.i4 0
    stloc.s 46
    ldc.i4 0
    stloc.s 47
  run_W10_start:
    ldloc.s 46
    ldloc.s 3
    clt
    brfalse run_W10_end
    ldc.i4 0
    stloc.s 47
  run_W11_start:
    ldloc.s 47
    ldloc.s 4
    clt
    brfalse run_W11_end
    ldloc.s 13
    ldloc.s 47
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 48
    ldloc.s 44
    ldloc.s 46
    ldloc.s 47
    ldloc.s 3
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 48
    stind.r4
    ldc.i8 0
    stloc.s 49
    ldloc.s 47
    ldc.i4 1
    add
    stloc.s 47
    br run_W11_start
  run_W11_end:
    ldloc.s 46
    ldc.i4 1
    add
    stloc.s 46
    br run_W10_start
  run_W10_end:
    ldc.i4 0
    stloc.s 46
  run_W12_start:
    ldloc.s 46
    ldloc.s 3
    clt
    brfalse run_W12_end
    ldc.i4 0
    stloc.s 47
  run_W13_start:
    ldloc.s 47
    ldloc.s 5
    clt
    brfalse run_W13_end
    ldloc.s 14
    ldloc.s 47
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 50
    ldloc.s 45
    ldloc.s 46
    ldloc.s 47
    ldloc.s 3
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldloc.s 50
    stind.r4
    ldc.i8 0
    stloc.s 51
    ldloc.s 47
    ldc.i4 1
    add
    stloc.s 47
    br run_W13_start
  run_W13_end:
    ldloc.s 46
    ldc.i4 1
    add
    stloc.s 46
    br run_W12_start
  run_W12_end:
    ldloc.s 35
    ldloc.s 8
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 35
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 52
    ldloc.s 35
    ldloc.s 9
    conv.i8
    call int32 TKVApp::__pinvoke_cuda_malloc(int64, int64)
    stloc.s 0
    ldloc.s 35
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 53
    ldloc.s 52
    ldloc.s 44
    ldloc.s 8
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 54
    ldloc.s 53
    ldloc.s 45
    ldloc.s 9
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 55
    ldloc.s 36
    ldloc.s 10
    ldloc.s 8
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 56
    ldloc.s 37
    ldloc.s 11
    ldloc.s 8
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 57
    ldloc.s 40
    ldloc.s 12
    ldloc.s 9
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 58
    ldloc.s 42
    ldloc.s 13
    ldloc.s 4
    ldc.i4 4
    mul
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 59
    ldloc.s 43
    ldloc.s 14
    ldloc.s 5
    ldc.i4 4
    mul
    conv.i8
    ldc.i4 1
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 60
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 3
    ldloc.s 4
    ldloc.s 4
    ldloc.s 18
    ldloc.s 36
    ldloc.s 3
    ldloc.s 37
    ldloc.s 4
    ldloc.s 20
    ldloc.s 38
    ldloc.s 3
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If14_else
    ldstr "GEMM1 FAIL"
    ldstr " "
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If14_else:
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::.ctor()
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 118
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 56
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 48
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 95
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 55
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 53
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 95
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 122
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 95
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 107
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 40
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 41
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 123
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 113
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 91
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 93
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 91
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 93
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 91
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 93
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 91
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 93
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 118
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 37
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 113
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 64
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 113
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 76
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 69
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 78
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 68
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 119
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 99
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 118
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 99
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 118
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 99
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 118
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 91
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 93
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 91
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 93
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 91
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 93
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 76
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 69
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 78
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 68
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 58
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 125
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    stloc.s 61
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::.ctor()
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 95
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 107
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 0
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    stloc.s 62
    ldloc.s 61
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::get_Count()
    ldc.i4 1
    add
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 63
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 64
  run_W15_start:
    ldloc.s 64
    ldloc.s 61
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::get_Count()
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    clt
    brfalse run_W15_end
    ldloc.s 63
    conv.i
    ldloc.s 64
    call int32 TkvInt::ToI32(valuetype TkvInt)
    ldloc.s 61
    ldloc.s 64
    call int32 TkvInt::ToI32(valuetype TkvInt)
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::get_Item(int32)
    conv.ovf.u1
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteByte(native int, int32, uint8)
    ldc.i8 0
    stloc.s 65
    ldloc.s 64
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 132
    stloc.s 131
    ldloca.s 131
    ldfld object TkvInt::big
    brtrue run_int16_slow
    ldloca.s 132
    ldfld object TkvInt::big
    brtrue run_int16_slow
    ldloca.s 131
    ldfld int64 TkvInt::lo
    ldloca.s 132
    ldfld int64 TkvInt::lo
    add
    stloc.s 134
    ldloca.s 131
    ldfld int64 TkvInt::lo
    ldloc.s 134
    xor
    ldloca.s 132
    ldfld int64 TkvInt::lo
    ldloc.s 134
    xor
    and
    ldc.i8 0
    blt run_int16_slow
    ldloca.s 133
    ldloc.s 134
    stfld int64 TkvInt::lo
    ldloca.s 133
    ldnull
    stfld object TkvInt::big
    ldloc.s 133
    br run_int16_done
  run_int16_slow:
    ldloc.s 131
    ldloc.s 132
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int16_done:
    stloc.s 64
    br run_W15_start
  run_W15_end:
    ldloc.s 63
    conv.i
    ldloc.s 64
    call int32 TkvInt::ToI32(valuetype TkvInt)
    ldc.i4 0
    conv.ovf.u1
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteByte(native int, int32, uint8)
    ldc.i8 0
    stloc.s 66
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 67
    ldloc.s 67
    ldloc.s 63
    call int32 TKVApp::__pinvoke_cu_module_load(int64, int64)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If17_else
    ldstr "BIASLOAD FAIL"
    ldstr " "
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If17_else:
    ldloc.s 67
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 68
    ldloc.s 62
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::get_Count()
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 69
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 70
  run_W18_start:
    ldloc.s 70
    ldloc.s 62
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::get_Count()
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    clt
    brfalse run_W18_end
    ldloc.s 69
    conv.i
    ldloc.s 70
    call int32 TkvInt::ToI32(valuetype TkvInt)
    ldloc.s 62
    ldloc.s 70
    call int32 TkvInt::ToI32(valuetype TkvInt)
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::get_Item(int32)
    conv.ovf.u1
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteByte(native int, int32, uint8)
    ldc.i8 0
    stloc.s 71
    ldloc.s 70
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 132
    stloc.s 131
    ldloca.s 131
    ldfld object TkvInt::big
    brtrue run_int19_slow
    ldloca.s 132
    ldfld object TkvInt::big
    brtrue run_int19_slow
    ldloca.s 131
    ldfld int64 TkvInt::lo
    ldloca.s 132
    ldfld int64 TkvInt::lo
    add
    stloc.s 134
    ldloca.s 131
    ldfld int64 TkvInt::lo
    ldloc.s 134
    xor
    ldloca.s 132
    ldfld int64 TkvInt::lo
    ldloc.s 134
    xor
    and
    ldc.i8 0
    blt run_int19_slow
    ldloca.s 133
    ldloc.s 134
    stfld int64 TkvInt::lo
    ldloca.s 133
    ldnull
    stfld object TkvInt::big
    ldloc.s 133
    br run_int19_done
  run_int19_slow:
    ldloc.s 131
    ldloc.s 132
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int19_done:
    stloc.s 70
    br run_W18_start
  run_W18_end:
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 72
    ldloc.s 72
    ldloc.s 68
    ldloc.s 69
    call int32 TKVApp::__pinvoke_cu_module_fn(int64, int64, int64)
    stloc.s 0
    ldloc.s 72
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 73
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 74
    ldloc.s 74
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldloc.s 38
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 21
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 75
    ldloc.s 75
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldloc.s 52
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 76
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 77
    ldloc.s 77
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldloc.s 6
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt32(native int, int32)
    ldc.i8 0
    stloc.s 78
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 79
    ldloc.s 79
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldloc.s 38
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 80
    ldc.i4 32
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 81
    ldloc.s 81
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldloc.s 74
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 82
    ldloc.s 81
    ldc.i4 8
    conv.i8
    add
    conv.i
    ldloc.s 75
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 83
    ldloc.s 81
    ldc.i4 16
    conv.i8
    add
    conv.i
    ldloc.s 79
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 84
    ldloc.s 81
    ldc.i4 24
    conv.i8
    add
    conv.i
    ldloc.s 77
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 85
    ldloc.s 73
    ldc.i4 1
    ldc.i4 1
    ldc.i4 1
    ldc.i4 64
    ldc.i4 1
    ldc.i4 1
    ldc.i4 0
    ldc.i8 0
    ldloc.s 81
    ldc.i8 0
    call int32 TKVApp::__pinvoke_cu_launch(int64, int32, int32, int32, int32, int32, int32, int32, int64, int64, int64)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If20_else
    ldstr "BIAS1 LAUNCH FAIL"
    ldstr " "
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If20_else:
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::.ctor()
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 118
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 56
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 48
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 95
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 55
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 53
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 95
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 122
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 95
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 107
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 40
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 41
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 123
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 49
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 53
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 113
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 91
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 93
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 91
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 93
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 91
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 93
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 118
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 37
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 113
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 64
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 113
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 76
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 69
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 78
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 68
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 119
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 105
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 99
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 118
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 99
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 118
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 49
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 91
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 93
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 49
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 49
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 49
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 118
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 48
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 48
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 55
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 49
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 53
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 49
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 118
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 48
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 55
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 57
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 55
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 56
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 56
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 53
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 54
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 52
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 104
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 112
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 120
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 118
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 49
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 48
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 100
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 118
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 48
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 53
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 109
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 53
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 49
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 115
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 111
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 98
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 97
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 46
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 51
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 50
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 91
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 121
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 93
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 44
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 102
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 53
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 76
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 69
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 78
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 68
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 58
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 32
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 116
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 59
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 125
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 10
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    stloc.s 86
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::.ctor()
    dup
    ldc.i4 103
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 117
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 95
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 107
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 114
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 110
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 101
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 108
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    dup
    ldc.i4 0
    conv.u1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::Add(!0)
    stloc.s 87
    ldloc.s 86
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::get_Count()
    ldc.i4 1
    add
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 88
    ldc.i4 0
    stloc.s 89
  run_W21_start:
    ldloc.s 89
    ldloc.s 86
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::get_Count()
    clt
    brfalse run_W21_end
    ldloc.s 88
    conv.i
    ldloc.s 89
    ldloc.s 86
    ldloc.s 89
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::get_Item(int32)
    conv.ovf.u1
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteByte(native int, int32, uint8)
    ldc.i8 0
    stloc.s 90
    ldloc.s 89
    ldc.i4 1
    add
    stloc.s 89
    br run_W21_start
  run_W21_end:
    ldloc.s 88
    conv.i
    ldloc.s 89
    ldc.i4 0
    conv.ovf.u1
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteByte(native int, int32, uint8)
    ldc.i8 0
    stloc.s 91
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 92
    ldloc.s 92
    ldloc.s 88
    call int32 TKVApp::__pinvoke_cu_module_load(int64, int64)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If22_else
    ldstr "GELULOAD FAIL"
    ldstr " "
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If22_else:
    ldloc.s 92
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 93
    ldloc.s 87
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::get_Count()
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 94
    ldc.i4 0
    stloc.s 95
  run_W23_start:
    ldloc.s 95
    ldloc.s 87
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::get_Count()
    clt
    brfalse run_W23_end
    ldloc.s 94
    conv.i
    ldloc.s 95
    ldloc.s 87
    ldloc.s 95
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<unsigned int8>::get_Item(int32)
    conv.ovf.u1
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteByte(native int, int32, uint8)
    ldc.i8 0
    stloc.s 96
    ldloc.s 95
    ldc.i4 1
    add
    stloc.s 95
    br run_W23_start
  run_W23_end:
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 97
    ldloc.s 97
    ldloc.s 93
    ldloc.s 94
    call int32 TKVApp::__pinvoke_cu_module_fn(int64, int64, int64)
    stloc.s 0
    ldloc.s 97
    ldc.i4 0
    conv.i8
    add
    conv.i
    call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
    stloc.s 98
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 99
    ldloc.s 99
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldloc.s 38
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 100
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 101
    ldloc.s 101
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldloc.s 39
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 102
    ldc.i4 4
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 103
    ldloc.s 103
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldloc.s 6
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt32(native int, int32)
    ldc.i8 0
    stloc.s 104
    ldc.i4 24
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 105
    ldloc.s 105
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldloc.s 99
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 106
    ldloc.s 105
    ldc.i4 8
    conv.i8
    add
    conv.i
    ldloc.s 101
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 107
    ldloc.s 105
    ldc.i4 16
    conv.i8
    add
    conv.i
    ldloc.s 103
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 108
    ldloc.s 98
    ldc.i4 1
    ldc.i4 1
    ldc.i4 1
    ldc.i4 64
    ldc.i4 1
    ldc.i4 1
    ldc.i4 0
    ldc.i8 0
    ldloc.s 105
    ldc.i8 0
    call int32 TKVApp::__pinvoke_cu_launch(int64, int32, int32, int32, int32, int32, int32, int32, int64, int64, int64)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If24_else
    ldstr "GELU LAUNCH FAIL"
    ldstr " "
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If24_else:
    ldloc.s 2
    ldc.i4 0
    ldc.i4 0
    ldloc.s 3
    ldloc.s 5
    ldloc.s 4
    ldloc.s 18
    ldloc.s 39
    ldloc.s 3
    ldloc.s 40
    ldloc.s 4
    ldloc.s 20
    ldloc.s 41
    ldloc.s 3
    call int32 TKVApp::__pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If25_else
    ldstr "GEMM2 FAIL"
    ldstr " "
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If25_else:
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 109
    ldloc.s 109
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldloc.s 41
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 110
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 111
    ldloc.s 111
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldloc.s 53
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 112
    ldc.i4 8
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 113
    ldloc.s 113
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldloc.s 41
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 114
    ldc.i4 4
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 115
    ldloc.s 115
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldloc.s 7
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt32(native int, int32)
    ldc.i8 0
    stloc.s 116
    ldc.i4 32
    call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
    conv.i8
    stloc.s 117
    ldloc.s 117
    ldc.i4 0
    conv.i8
    add
    conv.i
    ldloc.s 109
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 118
    ldloc.s 117
    ldc.i4 8
    conv.i8
    add
    conv.i
    ldloc.s 111
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 119
    ldloc.s 117
    ldc.i4 16
    conv.i8
    add
    conv.i
    ldloc.s 113
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 120
    ldloc.s 117
    ldc.i4 24
    conv.i8
    add
    conv.i
    ldloc.s 115
    call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt64(native int, int64)
    ldc.i8 0
    stloc.s 121
    ldloc.s 73
    ldc.i4 1
    ldc.i4 1
    ldc.i4 1
    ldc.i4 64
    ldc.i4 1
    ldc.i4 1
    ldc.i4 0
    ldc.i8 0
    ldloc.s 117
    ldc.i8 0
    call int32 TKVApp::__pinvoke_cu_launch(int64, int32, int32, int32, int32, int32, int32, int32, int64, int64, int64)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    ldc.i4.0
    ceq
    brfalse run_If26_else
    ldstr "BIAS2 LAUNCH FAIL"
    ldstr " "
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  run_If26_else:
    ldloc.s 16
    ldloc.s 41
    ldloc.s 9
    conv.i8
    ldc.i4 2
    call int32 TKVApp::__pinvoke_cuda_h2d(int64, int64, int64, int32)
    conv.i8
    stloc.s 122
    ldc.r4 0.0
    stloc.s 123
    ldc.i4 0
    stloc.s 22
  run_W27_start:
    ldloc.s 22
    ldloc.s 3
    clt
    brfalse run_W27_end
    ldc.r4 1000000000.0
    neg
    stloc.s 124
    ldc.i4 0
    stloc.s 23
  run_W28_start:
    ldloc.s 23
    ldloc.s 5
    clt
    brfalse run_W28_end
    ldloc.s 16
    ldloc.s 22
    ldloc.s 23
    ldloc.s 3
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 125
    ldloc.s 125
    ldloc.s 124
    cgt
    brfalse run_If29_else
    ldloc.s 125
    stloc.s 124
  run_If29_else:
    ldloc.s 23
    ldc.i4 1
    add
    stloc.s 23
    br run_W28_start
  run_W28_end:
    ldc.r4 0.0
    stloc.s 126
    ldc.i4 0
    stloc.s 23
  run_W30_start:
    ldloc.s 23
    ldloc.s 5
    clt
    brfalse run_W30_end
    ldloc.s 16
    ldloc.s 22
    ldloc.s 23
    ldloc.s 3
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 125
    ldloc.s 125
    ldloc.s 124
    sub
    conv.r8
    call float64 [mscorlib]System.Math::Exp(float64)
    conv.r4
    stloc.s 127
    ldloc.s 126
    ldloc.s 127
    add
    stloc.s 126
    ldloc.s 23
    ldc.i4 1
    add
    stloc.s 23
    br run_W30_start
  run_W30_end:
    ldloc.s 15
    ldloc.s 22
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int)
    stloc.s 128
    ldloc.s 16
    ldloc.s 22
    ldloc.s 128
    ldloc.s 3
    mul
    add
    ldc.i4 4
    mul
    conv.i8
    add
    conv.i
    ldind.r4
    stloc.s 129
    ldloc.s 129
    ldloc.s 124
    sub
    conv.r8
    call float64 [mscorlib]System.Math::Exp(float64)
    conv.r4
    stloc.s 130
    ldloc.s 123
    ldloc.s 130
    ldloc.s 126
    div
    conv.r8
    call float64 [mscorlib]System.Math::Log(float64)
    conv.r4
    sub
    stloc.s 123
    ldloc.s 22
    ldc.i4 1
    add
    stloc.s 22
    br run_W27_start
  run_W27_end:
    ldloc.s 123
    ldc.r4 4.0
    div
    stloc.s 123
    ldstr "LOSS"
    ldstr " "
    ldloc.s 123
    call string TkvStr::F32(float32)
    call string [mscorlib]System.String::Concat(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
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
.method public hidebysig static pinvokeimpl("cuda.dll" as "cuModuleLoadData" cdecl)
    int32 __pinvoke_cu_module_load(int64, int64) cil managed preservesig {}
.method public hidebysig static pinvokeimpl("cuda.dll" as "cuModuleGetFunction" cdecl)
    int32 __pinvoke_cu_module_fn(int64, int64, int64) cil managed preservesig {}
.method public hidebysig static pinvokeimpl("cuda.dll" as "cuLaunchKernel" cdecl)
    int32 __pinvoke_cu_launch(int64, int32, int32, int32, int32, int32, int32, int32, int64, int64, int64) cil managed preservesig {}
.method public hidebysig static pinvokeimpl("cudart.dll" as "cudaMalloc" cdecl)
    int32 __pinvoke_cuda_malloc(int64, int64) cil managed preservesig {}
.method public hidebysig static pinvokeimpl("cudart.dll" as "cudaMemcpy" cdecl)
    int32 __pinvoke_cuda_h2d(int64, int64, int64, int32) cil managed preservesig {}
.method public hidebysig static pinvokeimpl("cublas.dll" as "cublasCreate_v2" cdecl)
    int32 __pinvoke_cublas_create(int64) cil managed preservesig {}
.method public hidebysig static pinvokeimpl("cublas.dll" as "cublasSgemm_v2" cdecl)
    int32 __pinvoke_cublas_sgemm(int64, int32, int32, int32, int32, int32, int64, int64, int32, int64, int32, int64, int64, int32) cil managed preservesig {}
}
