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
  .method public static int32 'run'() cil managed
  {
    .maxstack 11
    .locals init (valuetype TkvInt 'total', valuetype TkvInt 'tested', class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt> 'a', class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt> 'b', class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt> 'c', valuetype TkvInt 's', int32 '__iterzip0_idx', int32 '__tern1', int32 '__tern2', int32 '__tern3', valuetype TkvInt 'x', valuetype TkvInt 'y', valuetype TkvInt 'z', class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt> 'd', valuetype TkvInt 's2', int32 '__iterzip1_idx', int32 '__tern4', valuetype TkvInt 'x2', valuetype TkvInt 'y2', class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt> 'e', class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt> 'f', class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt> 'g', class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt> 'h', valuetype TkvInt 's3', int32 '__iterzip2_idx', int32 '__tern5', int32 '__tern6', int32 '__tern7', int32 '__tern8', int32 '__tern9', int32 '__tern10', int32 '__tern11', valuetype TkvInt 'w1', valuetype TkvInt 'w2', valuetype TkvInt 'w3', valuetype TkvInt 'w4', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x', valuetype [System.Numerics]System.Numerics.Complex '__tkvcplx_str')
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 0
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 1
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::.ctor()
    stloc.s 2
    ldloc.s 2
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 2
    ldc.i8 2
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 2
    ldc.i8 3
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::.ctor()
    stloc.s 3
    ldloc.s 3
    ldc.i8 10
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 3
    ldc.i8 20
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 3
    ldc.i8 30
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::.ctor()
    stloc.s 4
    ldloc.s 4
    ldc.i8 100
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 4
    ldc.i8 200
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 4
    ldc.i8 300
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 5
    ldc.i4.0
    stloc.s 6
  run_L1_start:
    ldloc.s 6
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    ldloc.s 3
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    ldloc.s 4
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    clt
    brfalse run_tern3_false
    ldloc.s 3
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 8
    br run_tern3_end
  run_tern3_false:
    ldloc.s 4
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 8
  run_tern3_end:
    ldloc.s 8
    clt
    brfalse run_tern2_false
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 7
    br run_tern2_end
  run_tern2_false:
    ldloc.s 3
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    ldloc.s 4
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    clt
    brfalse run_tern4_false
    ldloc.s 3
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 9
    br run_tern4_end
  run_tern4_false:
    ldloc.s 4
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 9
  run_tern4_end:
    ldloc.s 9
    stloc.s 7
  run_tern2_end:
    ldloc.s 7
    bge run_L1_end
    ldloc.s 2
    ldloc.s 6
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Item(int32)
    stloc.s 10
    ldloc.s 3
    ldloc.s 6
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Item(int32)
    stloc.s 11
    ldloc.s 4
    ldloc.s 6
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Item(int32)
    stloc.s 12
    ldloc.s 5
    ldloc.s 10
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int5_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int5_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int5_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int5_done
  run_int5_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int5_done:
    ldloc.s 11
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int6_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int6_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int6_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int6_done
  run_int6_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int6_done:
    ldloc.s 12
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int7_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int7_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int7_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int7_done
  run_int7_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int7_done:
    stloc.s 5
  run_L1_cont:
    ldloc.s 6
    ldc.i4 1
    add
    stloc.s 6
    br run_L1_start
  run_L1_end:
    ldloc.s 1
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int8_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int8_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int8_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int8_done
  run_int8_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int8_done:
    stloc.s 1
    ldloc.s 0
    ldstr "zip3_sum"
    ldloc.s 5
    call string TkvInt::Str(valuetype TkvInt)
    ldstr "666"
    call int32 TKVApp::'check'(string, string, string)
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int9_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int9_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int9_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int9_done
  run_int9_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int9_done:
    stloc.s 0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::.ctor()
    stloc.s 13
    ldloc.s 13
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 13
    ldc.i8 2
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 14
    ldc.i4.0
    stloc.s 15
  run_L10_start:
    ldloc.s 15
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    ldloc.s 13
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    clt
    brfalse run_tern11_false
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 16
    br run_tern11_end
  run_tern11_false:
    ldloc.s 13
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 16
  run_tern11_end:
    ldloc.s 16
    bge run_L10_end
    ldloc.s 2
    ldloc.s 15
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Item(int32)
    stloc.s 17
    ldloc.s 13
    ldloc.s 15
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Item(int32)
    stloc.s 18
    ldloc.s 14
    ldloc.s 17
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int12_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int12_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int12_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int12_done
  run_int12_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int12_done:
    ldloc.s 18
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int13_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int13_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int13_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int13_done
  run_int13_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int13_done:
    stloc.s 14
  run_L10_cont:
    ldloc.s 15
    ldc.i4 1
    add
    stloc.s 15
    br run_L10_start
  run_L10_end:
    ldloc.s 1
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int14_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int14_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int14_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int14_done
  run_int14_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int14_done:
    stloc.s 1
    ldloc.s 0
    ldstr "zip2_backward_compat_short_circuits"
    ldloc.s 14
    call string TkvInt::Str(valuetype TkvInt)
    ldstr "6"
    call int32 TKVApp::'check'(string, string, string)
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int15_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int15_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int15_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int15_done
  run_int15_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int15_done:
    stloc.s 0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::.ctor()
    stloc.s 19
    ldloc.s 19
    ldc.i8 7
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 19
    ldc.i8 8
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 19
    ldc.i8 9
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 19
    ldc.i8 11
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::.ctor()
    stloc.s 20
    ldloc.s 20
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 20
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 20
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 20
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::.ctor()
    stloc.s 21
    ldloc.s 21
    ldc.i8 2
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 21
    ldc.i8 2
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 21
    ldc.i8 2
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 21
    ldc.i8 2
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::.ctor()
    stloc.s 22
    ldloc.s 22
    ldc.i8 3
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 22
    ldc.i8 3
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 22
    ldc.i8 3
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldloc.s 22
    ldc.i8 3
    call valuetype TkvInt TkvInt::FromI64(int64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::Add(!0)
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 23
    ldc.i4.0
    stloc.s 24
  run_L16_start:
    ldloc.s 24
    ldloc.s 19
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    ldloc.s 20
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    ldloc.s 21
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    ldloc.s 22
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    clt
    brfalse run_tern19_false
    ldloc.s 21
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 27
    br run_tern19_end
  run_tern19_false:
    ldloc.s 22
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 27
  run_tern19_end:
    ldloc.s 27
    clt
    brfalse run_tern18_false
    ldloc.s 20
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 26
    br run_tern18_end
  run_tern18_false:
    ldloc.s 21
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    ldloc.s 22
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    clt
    brfalse run_tern20_false
    ldloc.s 21
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 28
    br run_tern20_end
  run_tern20_false:
    ldloc.s 22
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 28
  run_tern20_end:
    ldloc.s 28
    stloc.s 26
  run_tern18_end:
    ldloc.s 26
    clt
    brfalse run_tern17_false
    ldloc.s 19
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 25
    br run_tern17_end
  run_tern17_false:
    ldloc.s 20
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    ldloc.s 21
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    ldloc.s 22
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    clt
    brfalse run_tern22_false
    ldloc.s 21
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 30
    br run_tern22_end
  run_tern22_false:
    ldloc.s 22
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 30
  run_tern22_end:
    ldloc.s 30
    clt
    brfalse run_tern21_false
    ldloc.s 20
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 29
    br run_tern21_end
  run_tern21_false:
    ldloc.s 21
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    ldloc.s 22
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    clt
    brfalse run_tern23_false
    ldloc.s 21
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 31
    br run_tern23_end
  run_tern23_false:
    ldloc.s 22
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Count()
    stloc.s 31
  run_tern23_end:
    ldloc.s 31
    stloc.s 29
  run_tern21_end:
    ldloc.s 29
    stloc.s 25
  run_tern17_end:
    ldloc.s 25
    bge run_L16_end
    ldloc.s 19
    ldloc.s 24
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Item(int32)
    stloc.s 32
    ldloc.s 20
    ldloc.s 24
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Item(int32)
    stloc.s 33
    ldloc.s 21
    ldloc.s 24
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Item(int32)
    stloc.s 34
    ldloc.s 22
    ldloc.s 24
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype TkvInt>::get_Item(int32)
    stloc.s 35
    ldloc.s 23
    ldloc.s 32
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int24_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int24_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int24_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int24_done
  run_int24_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int24_done:
    ldloc.s 33
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int25_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int25_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int25_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int25_done
  run_int25_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int25_done:
    ldloc.s 34
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int26_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int26_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int26_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int26_done
  run_int26_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int26_done:
    ldloc.s 35
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int27_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int27_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int27_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int27_done
  run_int27_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int27_done:
    stloc.s 23
  run_L16_cont:
    ldloc.s 24
    ldc.i4 1
    add
    stloc.s 24
    br run_L16_start
  run_L16_end:
    ldloc.s 1
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int28_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int28_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int28_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int28_done
  run_int28_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int28_done:
    stloc.s 1
    ldloc.s 0
    ldstr "zip4_sum"
    ldloc.s 23
    call string TkvInt::Str(valuetype TkvInt)
    ldstr "59"
    call int32 TKVApp::'check'(string, string, string)
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 37
    stloc.s 36
    ldloca.s 36
    ldfld object TkvInt::big
    brtrue run_int29_slow
    ldloca.s 37
    ldfld object TkvInt::big
    brtrue run_int29_slow
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloca.s 37
    ldfld int64 TkvInt::lo
    add
    stloc.s 39
    ldloca.s 36
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    ldloca.s 37
    ldfld int64 TkvInt::lo
    ldloc.s 39
    xor
    and
    ldc.i8 0
    blt run_int29_slow
    ldloca.s 38
    ldloc.s 39
    stfld int64 TkvInt::lo
    ldloca.s 38
    ldnull
    stfld object TkvInt::big
    ldloc.s 38
    br run_int29_done
  run_int29_slow:
    ldloc.s 36
    ldloc.s 37
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_int29_done:
    stloc.s 0
    ldstr "zip_nary_test"
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
