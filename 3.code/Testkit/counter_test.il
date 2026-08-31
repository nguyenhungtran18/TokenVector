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
}

.class public auto ansi TKVApp extends [mscorlib]System.Object
{
  .method public static int32 'counting_from_list'() cil managed
  {
    .maxstack 11
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'words', class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32> 'c', int32 '__counter_idx_c', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x', valuetype [System.Numerics]System.Numerics.Complex '__tkvcplx_str')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldloc.s 0
    ldstr "a"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "b"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "a"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "c"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "a"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "b"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::.ctor()
    stloc.s 1
    ldc.i4.0
    stloc.s 2
  counting_from_list_counter1_start:
    ldloc.s 2
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge counting_from_list_counter1_end
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::ContainsKey(!0)
    brtrue counting_from_list_counter1_have
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldc.i4.1
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
    br counting_from_list_counter1_after
  counting_from_list_counter1_have:
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
    ldc.i4.1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
  counting_from_list_counter1_after:
    ldloc.s 2
    ldc.i4.1
    add
    stloc.s 2
    br counting_from_list_counter1_start
  counting_from_list_counter1_end:
    ldloc.s 1
    ldstr "a"
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::ContainsKey(!0)
    brtrue counting_from_list_counterget2_have
    ldc.i4.0
    br counting_from_list_counterget2_end
  counting_from_list_counterget2_have:
    ldloc.s 1
    ldstr "a"
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
  counting_from_list_counterget2_end:
    ldloc.s 1
    ldstr "b"
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::ContainsKey(!0)
    brtrue counting_from_list_counterget3_have
    ldc.i4.0
    br counting_from_list_counterget3_end
  counting_from_list_counterget3_have:
    ldloc.s 1
    ldstr "b"
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
  counting_from_list_counterget3_end:
    add.ovf
    ldloc.s 1
    ldstr "c"
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::ContainsKey(!0)
    brtrue counting_from_list_counterget4_have
    ldc.i4.0
    br counting_from_list_counterget4_end
  counting_from_list_counterget4_have:
    ldloc.s 1
    ldstr "c"
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
  counting_from_list_counterget4_end:
    add.ovf
    ret
  }
  .method public static int32 'missing_key_zero'() cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32> 'c', int32 '__counter_idx_c', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x', valuetype [System.Numerics]System.Numerics.Complex '__tkvcplx_str')
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::.ctor()
    stloc.s 0
    ldloc.s 0
    ldstr "nope"
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::ContainsKey(!0)
    brtrue missing_key_zero_counterget1_have
    ldc.i4.0
    br missing_key_zero_counterget1_end
  missing_key_zero_counterget1_have:
    ldloc.s 0
    ldstr "nope"
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
  missing_key_zero_counterget1_end:
    ret
  }
  .method public static int32 'increment_manually'() cil managed
  {
    .maxstack 11
    .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32> 'c', int32 '__counter_idx_c', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x', valuetype [System.Numerics]System.Numerics.Complex '__tkvcplx_str')
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::.ctor()
    stloc.s 0
    ldloc.s 0
    ldstr "x"
    ldloc.s 0
    ldstr "x"
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::ContainsKey(!0)
    brtrue increment_manually_counterget1_have
    ldc.i4.0
    br increment_manually_counterget1_end
  increment_manually_counterget1_have:
    ldloc.s 0
    ldstr "x"
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
  increment_manually_counterget1_end:
    ldc.i4 1
    add.ovf
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
    ldloc.s 0
    ldstr "x"
    ldloc.s 0
    ldstr "x"
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::ContainsKey(!0)
    brtrue increment_manually_counterget2_have
    ldc.i4.0
    br increment_manually_counterget2_end
  increment_manually_counterget2_have:
    ldloc.s 0
    ldstr "x"
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
  increment_manually_counterget2_end:
    ldc.i4 1
    add.ovf
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
    ldloc.s 0
    ldstr "y"
    ldloc.s 0
    ldstr "y"
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::ContainsKey(!0)
    brtrue increment_manually_counterget3_have
    ldc.i4.0
    br increment_manually_counterget3_end
  increment_manually_counterget3_have:
    ldloc.s 0
    ldstr "y"
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
  increment_manually_counterget3_end:
    ldc.i4 1
    add.ovf
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
    ldloc.s 0
    ldstr "x"
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::ContainsKey(!0)
    brtrue increment_manually_counterget4_have
    ldc.i4.0
    br increment_manually_counterget4_end
  increment_manually_counterget4_have:
    ldloc.s 0
    ldstr "x"
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
  increment_manually_counterget4_end:
    ldloc.s 0
    ldstr "y"
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::ContainsKey(!0)
    brtrue increment_manually_counterget5_have
    ldc.i4.0
    br increment_manually_counterget5_end
  increment_manually_counterget5_have:
    ldloc.s 0
    ldstr "y"
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
  increment_manually_counterget5_end:
    add.ovf
    ret
  }
  .method public static string 'most_common_top1'() cil managed
  {
    .maxstack 11
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'words', class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32> 'c', int32 '__counter_idx_c', class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>> 'top', class [mscorlib]System.Collections.Generic.List`1<string> '__mc2270214658368_keys', class [mscorlib]System.Collections.Generic.List`1<int32> '__mc2270214658368_vals', valuetype [mscorlib]System.Collections.Generic.Dictionary`2/Enumerator<string, int32> '__mc2270214658368_en', valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, int32> '__mc2270214658368_cur', int32 '__mc2270214658368_i', int32 '__mc2270214658368_j', int32 '__mc2270214658368_maxi', int32 '__mc2270214658368_maxv', int32 '__mc2270214658368_cnt', int32 '__mc2270214658368_limit', int32 '__mc2270214658368_tmpv', int32 '__mc2270214658368_nval', string '__mc2270214658368_tmpk', class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>> '__mc2270214658368_res', string 'k', int32 'v', valuetype [mscorlib]System.ValueTuple`2<string, int32> '__tupleassign2270214789056_tmp', int32 '__strtmp2270214629632', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x', valuetype [System.Numerics]System.Numerics.Complex '__tkvcplx_str')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldloc.s 0
    ldstr "a"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "b"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "a"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "c"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "a"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "b"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::.ctor()
    stloc.s 1
    ldc.i4.0
    stloc.s 2
  most_common_top1_counter1_start:
    ldloc.s 2
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge most_common_top1_counter1_end
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::ContainsKey(!0)
    brtrue most_common_top1_counter1_have
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldc.i4.1
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
    br most_common_top1_counter1_after
  most_common_top1_counter1_have:
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
    ldc.i4.1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
  most_common_top1_counter1_after:
    ldloc.s 2
    ldc.i4.1
    add
    stloc.s 2
    br most_common_top1_counter1_start
  most_common_top1_counter1_end:
    ldc.i4 1
    stloc.s 15
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 4
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<int32>::.ctor()
    stloc.s 5
    ldloc.s 1
    callvirt instance valuetype [mscorlib]System.Collections.Generic.Dictionary`2/Enumerator<!0, !1> class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::GetEnumerator()
    stloc.s 6
  most_common_top1_mc2_copy_start:
    ldloca.s 6
    call instance bool valuetype [mscorlib]System.Collections.Generic.Dictionary`2/Enumerator<string, int32>::MoveNext()
    brfalse most_common_top1_mc2_copy_end
    ldloca.s 6
    call instance valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<!0, !1> valuetype [mscorlib]System.Collections.Generic.Dictionary`2/Enumerator<string, int32>::get_Current()
    stloc.s 7
    ldloc.s 4
    ldloca.s 7
    call instance !0 valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, int32>::get_Key()
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 5
    ldloca.s 7
    call instance !1 valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, int32>::get_Value()
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::Add(!0)
    br most_common_top1_mc2_copy_start
  most_common_top1_mc2_copy_end:
    ldloc.s 4
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 12
    ldc.i4.0
    stloc.s 8
  most_common_top1_mc2_sorti_start:
    ldloc.s 8
    ldloc.s 12
    bge most_common_top1_mc2_sorti_end
    ldloc.s 8
    stloc.s 10
    ldloc.s 5
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 11
    ldloc.s 8
    ldc.i4.1
    add
    stloc.s 9
  most_common_top1_mc2_sortj_start:
    ldloc.s 9
    ldloc.s 12
    bge most_common_top1_mc2_sortj_end
    ldloc.s 5
    ldloc.s 9
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldloc.s 11
    ble most_common_top1_mc2_sortj_skip
    ldloc.s 9
    stloc.s 10
    ldloc.s 5
    ldloc.s 9
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 11
  most_common_top1_mc2_sortj_skip:
    ldloc.s 9
    ldc.i4.1
    add
    stloc.s 9
    br most_common_top1_mc2_sortj_start
  most_common_top1_mc2_sortj_end:
    ldloc.s 10
    ldloc.s 8
    beq most_common_top1_mc2_swap_skip
    ldloc.s 4
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 16
    ldloc.s 4
    ldloc.s 8
    ldloc.s 4
    ldloc.s 10
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::set_Item(int32, !0)
    ldloc.s 4
    ldloc.s 10
    ldloc.s 16
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::set_Item(int32, !0)
    ldloc.s 5
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 14
    ldloc.s 5
    ldloc.s 8
    ldloc.s 5
    ldloc.s 10
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldloc.s 5
    ldloc.s 10
    ldloc.s 14
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
  most_common_top1_mc2_swap_skip:
    ldloc.s 8
    ldc.i4.1
    add
    stloc.s 8
    br most_common_top1_mc2_sorti_start
  most_common_top1_mc2_sorti_end:
    ldloc.s 15
    ldloc.s 12
    bge most_common_top1_mc2_limit_ge
    ldloc.s 15
    stloc.s 13
    br most_common_top1_mc2_build_start_setup
  most_common_top1_mc2_limit_ge:
    ldloc.s 12
    stloc.s 13
  most_common_top1_mc2_build_start_setup:
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>>::.ctor()
    stloc.s 17
    ldc.i4.0
    stloc.s 8
  most_common_top1_mc2_build_start:
    ldloc.s 8
    ldloc.s 13
    bge most_common_top1_mc2_build_end
    ldloc.s 17
    ldloc.s 4
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldloc.s 5
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    newobj instance void valuetype [mscorlib]System.ValueTuple`2<string, int32>::.ctor(!0, !1)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>>::Add(!0)
    ldloc.s 8
    ldc.i4.1
    add
    stloc.s 8
    br most_common_top1_mc2_build_start
  most_common_top1_mc2_build_end:
    ldloc.s 17
    stloc.s 3
    ldloc.s 3
    ldc.i4 0
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>>::get_Item(int32)
    stloc.s 20
    ldloc.s 20
    ldfld !0 valuetype [mscorlib]System.ValueTuple`2<string, int32>::Item1
    stloc.s 18
    ldloc.s 20
    ldfld !1 valuetype [mscorlib]System.ValueTuple`2<string, int32>::Item2
    stloc.s 19
    ldloc.s 3
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    call string TkvStr::I32(int32)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 18
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 19
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static string 'most_common_top2_order'() cil managed
  {
    .maxstack 11
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'words', class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32> 'c', int32 '__counter_idx_c', class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>> 'top', class [mscorlib]System.Collections.Generic.List`1<string> '__mc2270214774464_keys', class [mscorlib]System.Collections.Generic.List`1<int32> '__mc2270214774464_vals', valuetype [mscorlib]System.Collections.Generic.Dictionary`2/Enumerator<string, int32> '__mc2270214774464_en', valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, int32> '__mc2270214774464_cur', int32 '__mc2270214774464_i', int32 '__mc2270214774464_j', int32 '__mc2270214774464_maxi', int32 '__mc2270214774464_maxv', int32 '__mc2270214774464_cnt', int32 '__mc2270214774464_limit', int32 '__mc2270214774464_tmpv', int32 '__mc2270214774464_nval', string '__mc2270214774464_tmpk', class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>> '__mc2270214774464_res', string 'k0', int32 'v0', valuetype [mscorlib]System.ValueTuple`2<string, int32> '__tupleassign2270214785024_tmp', string 'k1', int32 'v1', valuetype [mscorlib]System.ValueTuple`2<string, int32> '__tupleassign2270214660352_tmp', int32 '__strtmp2270214678784', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x', valuetype [System.Numerics]System.Numerics.Complex '__tkvcplx_str')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldloc.s 0
    ldstr "x"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "y"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "x"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "z"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "x"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "y"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::.ctor()
    stloc.s 1
    ldc.i4.0
    stloc.s 2
  most_common_top2_order_counter1_start:
    ldloc.s 2
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge most_common_top2_order_counter1_end
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::ContainsKey(!0)
    brtrue most_common_top2_order_counter1_have
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldc.i4.1
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
    br most_common_top2_order_counter1_after
  most_common_top2_order_counter1_have:
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
    ldc.i4.1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
  most_common_top2_order_counter1_after:
    ldloc.s 2
    ldc.i4.1
    add
    stloc.s 2
    br most_common_top2_order_counter1_start
  most_common_top2_order_counter1_end:
    ldc.i4 2
    stloc.s 15
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 4
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<int32>::.ctor()
    stloc.s 5
    ldloc.s 1
    callvirt instance valuetype [mscorlib]System.Collections.Generic.Dictionary`2/Enumerator<!0, !1> class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::GetEnumerator()
    stloc.s 6
  most_common_top2_order_mc2_copy_start:
    ldloca.s 6
    call instance bool valuetype [mscorlib]System.Collections.Generic.Dictionary`2/Enumerator<string, int32>::MoveNext()
    brfalse most_common_top2_order_mc2_copy_end
    ldloca.s 6
    call instance valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<!0, !1> valuetype [mscorlib]System.Collections.Generic.Dictionary`2/Enumerator<string, int32>::get_Current()
    stloc.s 7
    ldloc.s 4
    ldloca.s 7
    call instance !0 valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, int32>::get_Key()
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 5
    ldloca.s 7
    call instance !1 valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, int32>::get_Value()
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::Add(!0)
    br most_common_top2_order_mc2_copy_start
  most_common_top2_order_mc2_copy_end:
    ldloc.s 4
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 12
    ldc.i4.0
    stloc.s 8
  most_common_top2_order_mc2_sorti_start:
    ldloc.s 8
    ldloc.s 12
    bge most_common_top2_order_mc2_sorti_end
    ldloc.s 8
    stloc.s 10
    ldloc.s 5
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 11
    ldloc.s 8
    ldc.i4.1
    add
    stloc.s 9
  most_common_top2_order_mc2_sortj_start:
    ldloc.s 9
    ldloc.s 12
    bge most_common_top2_order_mc2_sortj_end
    ldloc.s 5
    ldloc.s 9
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldloc.s 11
    ble most_common_top2_order_mc2_sortj_skip
    ldloc.s 9
    stloc.s 10
    ldloc.s 5
    ldloc.s 9
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 11
  most_common_top2_order_mc2_sortj_skip:
    ldloc.s 9
    ldc.i4.1
    add
    stloc.s 9
    br most_common_top2_order_mc2_sortj_start
  most_common_top2_order_mc2_sortj_end:
    ldloc.s 10
    ldloc.s 8
    beq most_common_top2_order_mc2_swap_skip
    ldloc.s 4
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 16
    ldloc.s 4
    ldloc.s 8
    ldloc.s 4
    ldloc.s 10
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::set_Item(int32, !0)
    ldloc.s 4
    ldloc.s 10
    ldloc.s 16
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::set_Item(int32, !0)
    ldloc.s 5
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 14
    ldloc.s 5
    ldloc.s 8
    ldloc.s 5
    ldloc.s 10
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldloc.s 5
    ldloc.s 10
    ldloc.s 14
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
  most_common_top2_order_mc2_swap_skip:
    ldloc.s 8
    ldc.i4.1
    add
    stloc.s 8
    br most_common_top2_order_mc2_sorti_start
  most_common_top2_order_mc2_sorti_end:
    ldloc.s 15
    ldloc.s 12
    bge most_common_top2_order_mc2_limit_ge
    ldloc.s 15
    stloc.s 13
    br most_common_top2_order_mc2_build_start_setup
  most_common_top2_order_mc2_limit_ge:
    ldloc.s 12
    stloc.s 13
  most_common_top2_order_mc2_build_start_setup:
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>>::.ctor()
    stloc.s 17
    ldc.i4.0
    stloc.s 8
  most_common_top2_order_mc2_build_start:
    ldloc.s 8
    ldloc.s 13
    bge most_common_top2_order_mc2_build_end
    ldloc.s 17
    ldloc.s 4
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldloc.s 5
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    newobj instance void valuetype [mscorlib]System.ValueTuple`2<string, int32>::.ctor(!0, !1)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>>::Add(!0)
    ldloc.s 8
    ldc.i4.1
    add
    stloc.s 8
    br most_common_top2_order_mc2_build_start
  most_common_top2_order_mc2_build_end:
    ldloc.s 17
    stloc.s 3
    ldloc.s 3
    ldc.i4 0
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>>::get_Item(int32)
    stloc.s 20
    ldloc.s 20
    ldfld !0 valuetype [mscorlib]System.ValueTuple`2<string, int32>::Item1
    stloc.s 18
    ldloc.s 20
    ldfld !1 valuetype [mscorlib]System.ValueTuple`2<string, int32>::Item2
    stloc.s 19
    ldloc.s 3
    ldc.i4 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>>::get_Item(int32)
    stloc.s 23
    ldloc.s 23
    ldfld !0 valuetype [mscorlib]System.ValueTuple`2<string, int32>::Item1
    stloc.s 21
    ldloc.s 23
    ldfld !1 valuetype [mscorlib]System.ValueTuple`2<string, int32>::Item2
    stloc.s 22
    ldloc.s 3
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    call string TkvStr::I32(int32)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 18
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 19
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 21
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 22
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static string 'most_common_n_bigger_than_keys'() cil managed
  {
    .maxstack 11
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'words', class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32> 'c', int32 '__counter_idx_c', class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>> 'top', class [mscorlib]System.Collections.Generic.List`1<string> '__mc2270214624384_keys', class [mscorlib]System.Collections.Generic.List`1<int32> '__mc2270214624384_vals', valuetype [mscorlib]System.Collections.Generic.Dictionary`2/Enumerator<string, int32> '__mc2270214624384_en', valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, int32> '__mc2270214624384_cur', int32 '__mc2270214624384_i', int32 '__mc2270214624384_j', int32 '__mc2270214624384_maxi', int32 '__mc2270214624384_maxv', int32 '__mc2270214624384_cnt', int32 '__mc2270214624384_limit', int32 '__mc2270214624384_tmpv', int32 '__mc2270214624384_nval', string '__mc2270214624384_tmpk', class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>> '__mc2270214624384_res', int32 '__strtmp2270214785920', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x', valuetype [System.Numerics]System.Numerics.Complex '__tkvcplx_str')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldloc.s 0
    ldstr "p"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "q"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "p"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::.ctor()
    stloc.s 1
    ldc.i4.0
    stloc.s 2
  most_common_n_bigger_than_keys_counter1_start:
    ldloc.s 2
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge most_common_n_bigger_than_keys_counter1_end
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::ContainsKey(!0)
    brtrue most_common_n_bigger_than_keys_counter1_have
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldc.i4.1
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
    br most_common_n_bigger_than_keys_counter1_after
  most_common_n_bigger_than_keys_counter1_have:
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
    ldc.i4.1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
  most_common_n_bigger_than_keys_counter1_after:
    ldloc.s 2
    ldc.i4.1
    add
    stloc.s 2
    br most_common_n_bigger_than_keys_counter1_start
  most_common_n_bigger_than_keys_counter1_end:
    ldc.i4 10
    stloc.s 15
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 4
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<int32>::.ctor()
    stloc.s 5
    ldloc.s 1
    callvirt instance valuetype [mscorlib]System.Collections.Generic.Dictionary`2/Enumerator<!0, !1> class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::GetEnumerator()
    stloc.s 6
  most_common_n_bigger_than_keys_mc2_copy_start:
    ldloca.s 6
    call instance bool valuetype [mscorlib]System.Collections.Generic.Dictionary`2/Enumerator<string, int32>::MoveNext()
    brfalse most_common_n_bigger_than_keys_mc2_copy_end
    ldloca.s 6
    call instance valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<!0, !1> valuetype [mscorlib]System.Collections.Generic.Dictionary`2/Enumerator<string, int32>::get_Current()
    stloc.s 7
    ldloc.s 4
    ldloca.s 7
    call instance !0 valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, int32>::get_Key()
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 5
    ldloca.s 7
    call instance !1 valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, int32>::get_Value()
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::Add(!0)
    br most_common_n_bigger_than_keys_mc2_copy_start
  most_common_n_bigger_than_keys_mc2_copy_end:
    ldloc.s 4
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 12
    ldc.i4.0
    stloc.s 8
  most_common_n_bigger_than_keys_mc2_sorti_start:
    ldloc.s 8
    ldloc.s 12
    bge most_common_n_bigger_than_keys_mc2_sorti_end
    ldloc.s 8
    stloc.s 10
    ldloc.s 5
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 11
    ldloc.s 8
    ldc.i4.1
    add
    stloc.s 9
  most_common_n_bigger_than_keys_mc2_sortj_start:
    ldloc.s 9
    ldloc.s 12
    bge most_common_n_bigger_than_keys_mc2_sortj_end
    ldloc.s 5
    ldloc.s 9
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldloc.s 11
    ble most_common_n_bigger_than_keys_mc2_sortj_skip
    ldloc.s 9
    stloc.s 10
    ldloc.s 5
    ldloc.s 9
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 11
  most_common_n_bigger_than_keys_mc2_sortj_skip:
    ldloc.s 9
    ldc.i4.1
    add
    stloc.s 9
    br most_common_n_bigger_than_keys_mc2_sortj_start
  most_common_n_bigger_than_keys_mc2_sortj_end:
    ldloc.s 10
    ldloc.s 8
    beq most_common_n_bigger_than_keys_mc2_swap_skip
    ldloc.s 4
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 16
    ldloc.s 4
    ldloc.s 8
    ldloc.s 4
    ldloc.s 10
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::set_Item(int32, !0)
    ldloc.s 4
    ldloc.s 10
    ldloc.s 16
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::set_Item(int32, !0)
    ldloc.s 5
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 14
    ldloc.s 5
    ldloc.s 8
    ldloc.s 5
    ldloc.s 10
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldloc.s 5
    ldloc.s 10
    ldloc.s 14
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
  most_common_n_bigger_than_keys_mc2_swap_skip:
    ldloc.s 8
    ldc.i4.1
    add
    stloc.s 8
    br most_common_n_bigger_than_keys_mc2_sorti_start
  most_common_n_bigger_than_keys_mc2_sorti_end:
    ldloc.s 15
    ldloc.s 12
    bge most_common_n_bigger_than_keys_mc2_limit_ge
    ldloc.s 15
    stloc.s 13
    br most_common_n_bigger_than_keys_mc2_build_start_setup
  most_common_n_bigger_than_keys_mc2_limit_ge:
    ldloc.s 12
    stloc.s 13
  most_common_n_bigger_than_keys_mc2_build_start_setup:
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>>::.ctor()
    stloc.s 17
    ldc.i4.0
    stloc.s 8
  most_common_n_bigger_than_keys_mc2_build_start:
    ldloc.s 8
    ldloc.s 13
    bge most_common_n_bigger_than_keys_mc2_build_end
    ldloc.s 17
    ldloc.s 4
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldloc.s 5
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    newobj instance void valuetype [mscorlib]System.ValueTuple`2<string, int32>::.ctor(!0, !1)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.ValueTuple`2<string, int32>>::Add(!0)
    ldloc.s 8
    ldc.i4.1
    add
    stloc.s 8
    br most_common_n_bigger_than_keys_mc2_build_start
  most_common_n_bigger_than_keys_mc2_build_end:
    ldloc.s 17
    stloc.s 3
    ldloc.s 3
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    call string TkvStr::I32(int32)
    ret
  }
  .method public static int32 'run'() cil managed
  {
    .maxstack 11
    .locals init (valuetype TkvInt 'total', valuetype TkvInt 'tested', int32 '__strtmp2270214794944', int32 '__strtmp2270214767936', int32 '__strtmp2270214785856', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x', valuetype [System.Numerics]System.Numerics.Complex '__tkvcplx_str')
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 0
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 1
    ldloc.s 1
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue run_int1_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue run_int1_slow
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    add
    stloc.s 8
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    ldloca.s 6
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    and
    ldc.i8 0
    blt run_int1_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br run_int1_done
  run_int1_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int1_done:
    stloc.s 1
    ldloc.s 0
    ldstr "counting_from_list"
    call int32 TKVApp::'counting_from_list'()
    call string TkvStr::I32(int32)
    ldstr "6"
    call int32 TKVApp::'check'(string, string, string)
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue run_int2_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue run_int2_slow
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    add
    stloc.s 8
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    ldloca.s 6
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    and
    ldc.i8 0
    blt run_int2_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br run_int2_done
  run_int2_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int2_done:
    stloc.s 0
    ldloc.s 1
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue run_int3_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue run_int3_slow
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    add
    stloc.s 8
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    ldloca.s 6
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    and
    ldc.i8 0
    blt run_int3_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br run_int3_done
  run_int3_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int3_done:
    stloc.s 1
    ldloc.s 0
    ldstr "missing_key_zero"
    call int32 TKVApp::'missing_key_zero'()
    call string TkvStr::I32(int32)
    ldstr "0"
    call int32 TKVApp::'check'(string, string, string)
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue run_int4_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue run_int4_slow
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    add
    stloc.s 8
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    ldloca.s 6
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    and
    ldc.i8 0
    blt run_int4_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br run_int4_done
  run_int4_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int4_done:
    stloc.s 0
    ldloc.s 1
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue run_int5_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue run_int5_slow
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    add
    stloc.s 8
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    ldloca.s 6
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    and
    ldc.i8 0
    blt run_int5_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br run_int5_done
  run_int5_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int5_done:
    stloc.s 1
    ldloc.s 0
    ldstr "increment_manually"
    call int32 TKVApp::'increment_manually'()
    call string TkvStr::I32(int32)
    ldstr "3"
    call int32 TKVApp::'check'(string, string, string)
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue run_int6_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue run_int6_slow
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    add
    stloc.s 8
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    ldloca.s 6
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    and
    ldc.i8 0
    blt run_int6_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br run_int6_done
  run_int6_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int6_done:
    stloc.s 0
    ldloc.s 1
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue run_int7_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue run_int7_slow
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    add
    stloc.s 8
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    ldloca.s 6
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    and
    ldc.i8 0
    blt run_int7_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br run_int7_done
  run_int7_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int7_done:
    stloc.s 1
    ldloc.s 0
    ldstr "most_common_top1"
    call string TKVApp::'most_common_top1'()
    ldstr "1:a:3"
    call int32 TKVApp::'check'(string, string, string)
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue run_int8_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue run_int8_slow
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    add
    stloc.s 8
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    ldloca.s 6
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    and
    ldc.i8 0
    blt run_int8_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br run_int8_done
  run_int8_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int8_done:
    stloc.s 0
    ldloc.s 1
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue run_int9_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue run_int9_slow
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    add
    stloc.s 8
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    ldloca.s 6
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    and
    ldc.i8 0
    blt run_int9_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br run_int9_done
  run_int9_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int9_done:
    stloc.s 1
    ldloc.s 0
    ldstr "most_common_top2_order"
    call string TKVApp::'most_common_top2_order'()
    ldstr "2:x3:y2"
    call int32 TKVApp::'check'(string, string, string)
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue run_int10_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue run_int10_slow
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    add
    stloc.s 8
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    ldloca.s 6
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    and
    ldc.i8 0
    blt run_int10_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br run_int10_done
  run_int10_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int10_done:
    stloc.s 0
    ldloc.s 1
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue run_int11_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue run_int11_slow
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    add
    stloc.s 8
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    ldloca.s 6
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    and
    ldc.i8 0
    blt run_int11_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br run_int11_done
  run_int11_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int11_done:
    stloc.s 1
    ldloc.s 0
    ldstr "most_common_n_bigger_than_keys"
    call string TKVApp::'most_common_n_bigger_than_keys'()
    ldstr "2"
    call int32 TKVApp::'check'(string, string, string)
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue run_int12_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue run_int12_slow
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    add
    stloc.s 8
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    ldloca.s 6
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    and
    ldc.i8 0
    blt run_int12_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br run_int12_done
  run_int12_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int12_done:
    stloc.s 0
    ldstr "counter_test"
    ldloc.s 0
    call int32 TkvInt::ToI32(valuetype TkvInt)
    ldloc.s 1
    call int32 TkvInt::ToI32(valuetype TkvInt)
    call int32 TKVApp::'test_summary'(string, int32, int32)
    ret
  }
  .method public static int32 'check'(string 'name', string 'got', string 'expected') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x', valuetype [System.Numerics]System.Numerics.Complex '__tkvcplx_str')
    ldarg.s 1
    ldarg.s 2
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse check_If1_else
    ldstr "PASS "
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  check_If1_else:
    ldstr "FAIL "
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " got="
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " expected="
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 2
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 0
    ret
  check_If1_end:
  }
  .method public static int32 'test_summary'(string 'suite_name', int32 'total', int32 'tested') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x', valuetype [System.Numerics]System.Numerics.Complex '__tkvcplx_str')
    ldstr ""
    call void [mscorlib]System.Console::WriteLine(string)
    ldstr "=== "
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ": "
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "/"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 2
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " PASS ==="
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldarg.s 1
    ldarg.s 2
    ceq
    brfalse test_summary_If1_else
    ldc.i4 0
    ret
  test_summary_If1_else:
    ldc.i4 1
    ret
  }
  .method public static void Main(string[] args) cil managed
  {
    .entrypoint
    .maxstack 8
    .locals init (int32 __cli_ret)
    call int32 TKVApp::'run'()
    stloc.0
    ldloca.s 0
    call instance string [mscorlib]System.Int32::ToString()
    call void [mscorlib]System.Console::WriteLine(string)
    ret
  }
}
