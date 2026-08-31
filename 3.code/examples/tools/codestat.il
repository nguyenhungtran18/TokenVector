.assembly extern mscorlib {}
.assembly extern System.Core { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly extern System { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly extern System.Numerics { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly TKVApp {}
.module TKVApp.exe

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
    .locals init (int64 x, valuetype [System.Numerics]System.Numerics.BigInteger b, float64 d)
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
    ldarga.s a
    ldfld object TkvInt::big
    isinst [mscorlib]System.Double
    brtrue.s DOUBLEPATH
    ldarg.0
    call valuetype [System.Numerics]System.Numerics.BigInteger TkvInt::ToBig(valuetype TkvInt)
    stloc.s b
    ldloca.s b
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string [System.Numerics]System.Numerics.BigInteger::ToString(class [mscorlib]System.IFormatProvider)
    ret
  DOUBLEPATH:
    ldarga.s a
    ldfld object TkvInt::big
    unbox.any float64
    call string TkvStr::F64(float64)
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
    ldarga.s a
    ldfld object TkvInt::big
    isinst [mscorlib]System.Double
    brfalse TOF64_NOT_DBL
    ldarga.s a
    ldfld object TkvInt::big
    unbox.any float64
    ret
  TOF64_NOT_DBL:
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
  .method public hidebysig virtual instance string ToString() cil managed
  {
    .maxstack 8
    ldarg.0
    ldobj valuetype TkvInt
    call string TkvInt::Str(valuetype TkvInt)
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
    .locals init (int64 e, float64 d, valuetype TkvInt r)
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
    ldarg.0
    call float64 TkvInt::ToF64(valuetype TkvInt)
    ldarg.1
    call float64 TkvInt::ToF64(valuetype TkvInt)
    call float64 [mscorlib]System.Math::Pow(float64, float64)
    stloc.s d
    ldloca.s r
    ldc.i8 0
    stfld int64 TkvInt::lo
    ldloca.s r
    ldloc.s d
    box float64
    stfld object TkvInt::big
    ldloc.s r
    ret
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

.class public auto ansi TKVApp extends [mscorlib]System.Object
{
  .method public static int32 'indent_of'(string 'ln') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt 'n', valuetype TkvInt 'i', string 'ch', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 0
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 1
  indent_of_W1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    clt
    brfalse indent_of_W1_end
    ldarg.s 0
    ldloc.s 1
    call int32 TkvInt::ToI32(valuetype TkvInt)
    dup
    ldc.i4.0
    bge.s indent_of_idx_pos_2
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    br.s indent_of_idx_end_2
  indent_of_idx_pos_2:
  indent_of_idx_end_2:
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    stloc.s 2
    ldloc.s 2
    ldstr " "
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse indent_of_If3_else
    ldloc.s 0
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue indent_of_int4_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue indent_of_int4_slow
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloca.s 4
    ldfld int64 TkvInt::lo
    add
    stloc.s 6
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloc.s 6
    xor
    ldloca.s 4
    ldfld int64 TkvInt::lo
    ldloc.s 6
    xor
    and
    ldc.i8 0
    blt indent_of_int4_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br indent_of_int4_done
  indent_of_int4_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  indent_of_int4_done:
    stloc.s 0
    br indent_of_If3_end
  indent_of_If3_else:
    ldloc.s 2
    ldstr "\t"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse indent_of_If5_else
    ldloc.s 0
    ldc.i4 4
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue indent_of_int6_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue indent_of_int6_slow
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloca.s 4
    ldfld int64 TkvInt::lo
    add
    stloc.s 6
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloc.s 6
    xor
    ldloca.s 4
    ldfld int64 TkvInt::lo
    ldloc.s 6
    xor
    and
    ldc.i8 0
    blt indent_of_int6_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br indent_of_int6_done
  indent_of_int6_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  indent_of_int6_done:
    stloc.s 0
    br indent_of_If5_end
  indent_of_If5_else:
    ldloc.s 0
    call int32 TkvInt::ToI32(valuetype TkvInt)
    ret
  indent_of_If5_end:
  indent_of_If3_end:
    ldloc.s 1
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue indent_of_int7_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue indent_of_int7_slow
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloca.s 4
    ldfld int64 TkvInt::lo
    add
    stloc.s 6
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloc.s 6
    xor
    ldloca.s 4
    ldfld int64 TkvInt::lo
    ldloc.s 6
    xor
    and
    ldc.i8 0
    blt indent_of_int7_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br indent_of_int7_done
  indent_of_int7_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  indent_of_int7_done:
    stloc.s 1
    br indent_of_W1_start
  indent_of_W1_end:
    ldloc.s 0
    call int32 TkvInt::ToI32(valuetype TkvInt)
    ret
  }
  .method public static string 'line_kind'(string 'ln') cil managed
  {
    .maxstack 10
    .locals init (string 'body', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance string [mscorlib]System.String::Trim()
    stloc.s 0
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse line_kind_If1_else
    ldstr "blank"
    ret
  line_kind_If1_else:
    ldloc.s 0
    ldstr "#"
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    brfalse line_kind_If2_else
    ldstr "comment"
    ret
  line_kind_If2_else:
    ldstr "code"
    ret
  }
  .method public static string 'word_after'(string 'ln', string 'kw') cil managed
  {
    .maxstack 11
    .locals init (string 'body', string 'head', string 'rest', int32 '__slice1720316952336_start', int32 '__slice1720316952336_stop', int32 '__slice1720316952336_count', string 'out', valuetype TkvInt 'i', string 'ch', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance string [mscorlib]System.String::Trim()
    stloc.s 0
    ldarg.s 1
    ldstr " "
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 1
    ldloc.s 0
    ldloc.s 1
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    ldc.i4.0
    ceq
    brfalse word_after_If1_else
    ldstr ""
    ret
  word_after_If1_else:
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    dup
    ldc.i4.0
    bge.s word_after_slc_neg_2
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s word_after_slc_neg_2
    pop
    ldc.i4.0
  word_after_slc_neg_2:
    dup
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s word_after_slc_clamp_2
    pop
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
  word_after_slc_clamp_2:
    stloc.s 3
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    stloc.s 4
    ldloc.s 4
    ldloc.s 3
    sub
    dup
    ldc.i4.0
    bge.s word_after_slc_cnt_3
    pop
    ldc.i4.0
  word_after_slc_cnt_3:
    stloc.s 5
    ldloc.s 0
    ldloc.s 3
    ldloc.s 5
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    callvirt instance string [mscorlib]System.String::Trim()
    stloc.s 2
    ldstr ""
    stloc.s 6
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 7
  word_after_W4_start:
    ldloc.s 7
    ldloc.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    clt
    brfalse word_after_W4_end
    ldloc.s 2
    ldloc.s 7
    call int32 TkvInt::ToI32(valuetype TkvInt)
    dup
    ldc.i4.0
    bge.s word_after_idx_pos_5
    ldloc.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    br.s word_after_idx_end_5
  word_after_idx_pos_5:
  word_after_idx_end_5:
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    stloc.s 8
    ldloc.s 8
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    dup
    brtrue word_after_sc8_end
    pop
    ldloc.s 8
    ldstr ":"
    call bool [mscorlib]System.String::Equals(string, string)
  word_after_sc8_end:
    dup
    brtrue word_after_sc7_end
    pop
    ldloc.s 8
    ldstr " "
    call bool [mscorlib]System.String::Equals(string, string)
  word_after_sc7_end:
    brfalse word_after_If6_else
    ldloc.s 6
    ret
  word_after_If6_else:
    ldloc.s 6
    ldloc.s 8
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 6
    ldloc.s 7
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 10
    stloc.s 9
    ldloca.s 9
    ldfld object TkvInt::big
    brtrue word_after_int9_slow
    ldloca.s 10
    ldfld object TkvInt::big
    brtrue word_after_int9_slow
    ldloca.s 9
    ldfld int64 TkvInt::lo
    ldloca.s 10
    ldfld int64 TkvInt::lo
    add
    stloc.s 12
    ldloca.s 9
    ldfld int64 TkvInt::lo
    ldloc.s 12
    xor
    ldloca.s 10
    ldfld int64 TkvInt::lo
    ldloc.s 12
    xor
    and
    ldc.i8 0
    blt word_after_int9_slow
    ldloca.s 11
    ldloc.s 12
    stfld int64 TkvInt::lo
    ldloca.s 11
    ldnull
    stfld object TkvInt::big
    ldloc.s 11
    br word_after_int9_done
  word_after_int9_slow:
    ldloc.s 9
    ldloc.s 10
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  word_after_int9_done:
    stloc.s 7
    br word_after_W4_start
  word_after_W4_end:
    ldloc.s 6
    ret
  }
  .method public static int32 'has_marker'(string 'ln') cil managed
  {
    .maxstack 10
    .locals init (string 'up', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance string [mscorlib]System.String::ToUpper()
    stloc.s 0
    ldloc.s 0
    ldstr "TODO"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse has_marker_If1_else
    ldc.i4 1
    ret
  has_marker_If1_else:
    ldloc.s 0
    ldstr "FIXME"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse has_marker_If2_else
    ldc.i4 1
    ret
  has_marker_If2_else:
    ldloc.s 0
    ldstr "XXX"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse has_marker_If3_else
    ldc.i4 1
    ret
  has_marker_If3_else:
    ldc.i4 0
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'split_lines'(string 'txt') cil managed
  {
    .maxstack 11
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'raw', class [mscorlib]System.Collections.Generic.List`1<string> 'out', int32 '__iterlist0_idx', string 'ln', int32 '__slice1720316925552_start', int32 '__slice1720316925552_stop', int32 '__slice1720316925552_count', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldc.i4.1
    newarr [mscorlib]System.Char
    dup
    ldc.i4.0
    ldstr "\n"
    ldc.i4.0
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    stelem.i2
    callvirt instance string[] [mscorlib]System.String::Split(char[])
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
    stloc.s 0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 1
    ldc.i4.0
    stloc.s 2
  split_lines_L1_start:
    ldloc.s 2
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge split_lines_L1_end
    ldloc.s 0
    ldloc.s 2
    dup
    ldc.i4.0
    bge.s split_lines_idx_pos_2
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s split_lines_idx_end_2
  split_lines_idx_pos_2:
  split_lines_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 3
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    dup
    brfalse split_lines_sc4_end
    pop
    ldloc.s 3
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 1
    sub.ovf
    dup
    ldc.i4.0
    bge.s split_lines_idx_pos_5
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    br.s split_lines_idx_end_5
  split_lines_idx_pos_5:
  split_lines_idx_end_5:
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ldstr "\r"
    call bool [mscorlib]System.String::Equals(string, string)
  split_lines_sc4_end:
    brfalse split_lines_If3_else
    ldloc.s 1
    ldc.i4 0
    dup
    ldc.i4.0
    bge.s split_lines_slc_neg_6
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s split_lines_slc_neg_6
    pop
    ldc.i4.0
  split_lines_slc_neg_6:
    dup
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s split_lines_slc_clamp_6
    pop
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
  split_lines_slc_clamp_6:
    stloc.s 4
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 1
    sub.ovf
    dup
    ldc.i4.0
    bge.s split_lines_slc_neg_7
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s split_lines_slc_neg_7
    pop
    ldc.i4.0
  split_lines_slc_neg_7:
    dup
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s split_lines_slc_clamp_7
    pop
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
  split_lines_slc_clamp_7:
    stloc.s 5
    ldloc.s 5
    ldloc.s 4
    sub
    dup
    ldc.i4.0
    bge.s split_lines_slc_cnt_8
    pop
    ldc.i4.0
  split_lines_slc_cnt_8:
    stloc.s 6
    ldloc.s 3
    ldloc.s 4
    ldloc.s 6
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br split_lines_If3_end
  split_lines_If3_else:
    ldloc.s 1
    ldloc.s 3
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  split_lines_If3_end:
  split_lines_L1_cont:
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    br split_lines_L1_start
  split_lines_L1_end:
    ldloc.s 1
    ret
  }
  .method public static int32 'block_end'(class [mscorlib]System.Collections.Generic.List`1<string> 'lines', int32 'start', int32 'base') cil managed
  {
    .maxstack 10
    .locals init (int32 'last', int32 'i', string 'ln', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 1
    stloc.s 0
    ldarg.s 1
    ldc.i4 1
    add.ovf
    stloc.s 1
  block_end_W1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse block_end_W1_end
    ldarg.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s block_end_idx_pos_2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s block_end_idx_end_2
  block_end_idx_pos_2:
  block_end_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 2
    ldloc.s 2
    call string TKVApp::'line_kind'(string)
    ldstr "code"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse block_end_If3_else
    ldloc.s 2
    call int32 TKVApp::'indent_of'(string)
    ldarg.s 2
    cgt
    ldc.i4.0
    ceq
    brfalse block_end_If4_else
    ldloc.s 0
    ret
  block_end_If4_else:
    ldloc.s 1
    stloc.s 0
  block_end_If3_else:
    ldloc.s 1
    ldc.i4 1
    add.ovf
    stloc.s 1
    br block_end_W1_start
  block_end_W1_end:
    ldloc.s 0
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32> 'count_kinds'(class [mscorlib]System.Collections.Generic.List`1<string> 'lines') cil managed
  {
    .maxstack 11
    .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32> 'tally', int32 '__iterlist1_idx', string 'ln', string 'k', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::.ctor()
    stloc.s 0
    ldloc.s 0
    ldstr "blank"
    ldc.i4 0
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
    ldloc.s 0
    ldstr "comment"
    ldc.i4 0
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
    ldloc.s 0
    ldstr "code"
    ldc.i4 0
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
    ldc.i4.0
    stloc.s 1
  count_kinds_L1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge count_kinds_L1_end
    ldarg.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s count_kinds_idx_pos_2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s count_kinds_idx_end_2
  count_kinds_idx_pos_2:
  count_kinds_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 2
    ldloc.s 2
    call string TKVApp::'line_kind'(string)
    stloc.s 3
    ldloc.s 0
    ldloc.s 3
    ldloc.s 0
    ldloc.s 3
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
    ldc.i4 1
    add.ovf
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::set_Item(!0, !1)
  count_kinds_L1_cont:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br count_kinds_L1_start
  count_kinds_L1_end:
    ldloc.s 0
    ret
  }
  .method public static int32 'deepest_indent'(class [mscorlib]System.Collections.Generic.List`1<string> 'lines') cil managed
  {
    .maxstack 10
    .locals init (object 'deep', int32 '__iterlist2_idx', string 'ln', int32 'd', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    box TkvInt
    stloc.s 0
    ldc.i4.0
    stloc.s 1
  deepest_indent_L1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge deepest_indent_L1_end
    ldarg.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s deepest_indent_idx_pos_2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s deepest_indent_idx_end_2
  deepest_indent_idx_pos_2:
  deepest_indent_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 2
    ldloc.s 2
    call string TKVApp::'line_kind'(string)
    ldstr "code"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse deepest_indent_If3_else
    ldloc.s 2
    call int32 TKVApp::'indent_of'(string)
    stloc.s 3
    ldloc.s 3
    ldloc.s 0
    unbox.any [mscorlib]System.Int32
    cgt
    brfalse deepest_indent_If4_else
    ldloc.s 3
    box [mscorlib]System.Int32
    stloc.s 0
  deepest_indent_If4_else:
  deepest_indent_If3_else:
  deepest_indent_L1_cont:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br deepest_indent_L1_start
  deepest_indent_L1_end:
    ldloc.s 0
    unbox.any [mscorlib]System.Int32
    ret
  }
  .method public static int32 'longest_line'(class [mscorlib]System.Collections.Generic.List`1<string> 'lines') cil managed
  {
    .maxstack 10
    .locals init (object 'best', object 'best_len', int32 'i', int32 'n', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    box TkvInt
    neg
    stloc.s 0
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    box TkvInt
    neg
    stloc.s 1
    ldc.i4.0
    stloc.s 2
  longest_line_L1_start:
    ldloc.s 2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge longest_line_L1_end
    ldarg.s 0
    ldloc.s 2
    dup
    ldc.i4.0
    bge.s longest_line_idx_pos_2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s longest_line_idx_end_2
  longest_line_idx_pos_2:
  longest_line_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance int32 [mscorlib]System.String::get_Length()
    stloc.s 3
    ldloc.s 3
    ldloc.s 1
    unbox.any [mscorlib]System.Int32
    cgt
    brfalse longest_line_If3_else
    ldloc.s 3
    box [mscorlib]System.Int32
    stloc.s 1
    ldloc.s 2
    box [mscorlib]System.Int32
    stloc.s 0
  longest_line_If3_else:
  longest_line_L1_cont:
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    br longest_line_L1_start
  longest_line_L1_end:
    ldloc.s 0
    unbox.any [mscorlib]System.Int32
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<int32> 'marker_lines'(class [mscorlib]System.Collections.Generic.List`1<string> 'lines') cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<int32> 'out', int32 'i', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<int32>::.ctor()
    stloc.s 0
    ldc.i4.0
    stloc.s 1
  marker_lines_L1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge marker_lines_L1_end
    ldarg.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s marker_lines_idx_pos_3
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s marker_lines_idx_end_3
  marker_lines_idx_pos_3:
  marker_lines_idx_end_3:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call int32 TKVApp::'has_marker'(string)
    ldc.i4 1
    ceq
    brfalse marker_lines_If2_else
    ldloc.s 0
    ldloc.s 1
    ldc.i4 1
    add.ovf
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::Add(!0)
  marker_lines_If2_else:
  marker_lines_L1_cont:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br marker_lines_L1_start
  marker_lines_L1_end:
    ldloc.s 0
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'func_names'(class [mscorlib]System.Collections.Generic.List`1<string> 'lines') cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', int32 '__iterlist3_idx', string 'ln', string 'nm', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldc.i4.0
    stloc.s 1
  func_names_L1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge func_names_L1_end
    ldarg.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s func_names_idx_pos_2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s func_names_idx_end_2
  func_names_idx_pos_2:
  func_names_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 2
    ldloc.s 2
    ldstr "def"
    call string TKVApp::'word_after'(string, string)
    stloc.s 3
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse func_names_If3_else
    ldloc.s 0
    ldloc.s 3
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  func_names_If3_else:
  func_names_L1_cont:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br func_names_L1_start
  func_names_L1_end:
    ldloc.s 0
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'func_spans'(class [mscorlib]System.Collections.Generic.List`1<string> 'lines') cil managed
  {
    .maxstack 11
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', int32 'i', string 'nm', int32 'base', int32 'fin', int32 'span', int32 '__strtmp1720316921792', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldc.i4.0
    stloc.s 1
  func_spans_L1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge func_spans_L1_end
    ldarg.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s func_spans_idx_pos_2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s func_spans_idx_end_2
  func_spans_idx_pos_2:
  func_spans_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldstr "def"
    call string TKVApp::'word_after'(string, string)
    stloc.s 2
    ldloc.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse func_spans_If3_else
    ldarg.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s func_spans_idx_pos_4
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s func_spans_idx_end_4
  func_spans_idx_pos_4:
  func_spans_idx_end_4:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call int32 TKVApp::'indent_of'(string)
    stloc.s 3
    ldarg.s 0
    ldloc.s 1
    ldloc.s 3
    call int32 TKVApp::'block_end'(class [mscorlib]System.Collections.Generic.List`1<string>, int32, int32)
    stloc.s 4
    ldloc.s 4
    ldloc.s 1
    sub.ovf
    ldc.i4 1
    add.ovf
    stloc.s 5
    ldloc.s 0
    ldloc.s 2
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 5
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  func_spans_If3_else:
  func_spans_L1_cont:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br func_spans_L1_start
  func_spans_L1_end:
    ldloc.s 0
    ret
  }
  .method public static string 'field_at'(string 'rec', int32 'idx') cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'parts', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldc.i4.1
    newarr [mscorlib]System.Char
    dup
    ldc.i4.0
    ldstr "|"
    ldc.i4.0
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    stelem.i2
    callvirt instance string[] [mscorlib]System.String::Split(char[])
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
    stloc.s 0
    ldloc.s 0
    ldarg.s 1
    dup
    ldc.i4.0
    bge.s field_at_idx_pos_1
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s field_at_idx_end_1
  field_at_idx_pos_1:
  field_at_idx_end_1:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'long_funcs'(class [mscorlib]System.Collections.Generic.List`1<string> 'spans') cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', int32 '__iterlist4_idx', string 'rec', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldc.i4.0
    stloc.s 1
  long_funcs_L1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge long_funcs_L1_end
    ldarg.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s long_funcs_idx_pos_2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s long_funcs_idx_end_2
  long_funcs_idx_pos_2:
  long_funcs_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 2
    ldloc.s 2
    ldc.i4 2
    call string TKVApp::'field_at'(string, int32)
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call int32 [mscorlib]System.Int32::Parse(string, class [mscorlib]System.IFormatProvider)
    ldc.i4 50
    cgt
    brfalse long_funcs_If3_else
    ldloc.s 0
    ldloc.s 2
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  long_funcs_If3_else:
  long_funcs_L1_cont:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br long_funcs_L1_start
  long_funcs_L1_end:
    ldloc.s 0
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'class_spans'(class [mscorlib]System.Collections.Generic.List`1<string> 'lines') cil managed
  {
    .maxstack 11
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', int32 'i', string 'nm', int32 'base', int32 'fin', valuetype TkvInt 'methods', int32 'j', int32 '__strtmp1720316952096', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldc.i4.0
    stloc.s 1
  class_spans_L1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge class_spans_L1_end
    ldarg.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s class_spans_idx_pos_2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s class_spans_idx_end_2
  class_spans_idx_pos_2:
  class_spans_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldstr "class"
    call string TKVApp::'word_after'(string, string)
    stloc.s 2
    ldloc.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse class_spans_If3_else
    ldarg.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s class_spans_idx_pos_4
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s class_spans_idx_end_4
  class_spans_idx_pos_4:
  class_spans_idx_end_4:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call int32 TKVApp::'indent_of'(string)
    stloc.s 3
    ldarg.s 0
    ldloc.s 1
    ldloc.s 3
    call int32 TKVApp::'block_end'(class [mscorlib]System.Collections.Generic.List`1<string>, int32, int32)
    stloc.s 4
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 5
    ldloc.s 1
    ldc.i4 1
    add.ovf
    stloc.s 6
  class_spans_W5_start:
    ldloc.s 6
    ldloc.s 4
    cgt
    ldc.i4.0
    ceq
    brfalse class_spans_W5_end
    ldarg.s 0
    ldloc.s 6
    dup
    ldc.i4.0
    bge.s class_spans_idx_pos_7
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s class_spans_idx_end_7
  class_spans_idx_pos_7:
  class_spans_idx_end_7:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldstr "def"
    call string TKVApp::'word_after'(string, string)
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse class_spans_If6_else
    ldloc.s 5
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 9
    stloc.s 8
    ldloca.s 8
    ldfld object TkvInt::big
    brtrue class_spans_int8_slow
    ldloca.s 9
    ldfld object TkvInt::big
    brtrue class_spans_int8_slow
    ldloca.s 8
    ldfld int64 TkvInt::lo
    ldloca.s 9
    ldfld int64 TkvInt::lo
    add
    stloc.s 11
    ldloca.s 8
    ldfld int64 TkvInt::lo
    ldloc.s 11
    xor
    ldloca.s 9
    ldfld int64 TkvInt::lo
    ldloc.s 11
    xor
    and
    ldc.i8 0
    blt class_spans_int8_slow
    ldloca.s 10
    ldloc.s 11
    stfld int64 TkvInt::lo
    ldloca.s 10
    ldnull
    stfld object TkvInt::big
    ldloc.s 10
    br class_spans_int8_done
  class_spans_int8_slow:
    ldloc.s 8
    ldloc.s 9
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  class_spans_int8_done:
    stloc.s 5
  class_spans_If6_else:
    ldloc.s 6
    ldc.i4 1
    add.ovf
    stloc.s 6
    br class_spans_W5_start
  class_spans_W5_end:
    ldloc.s 0
    ldloc.s 2
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 5
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  class_spans_If3_else:
  class_spans_L1_cont:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br class_spans_L1_start
  class_spans_L1_end:
    ldloc.s 0
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'duplicates'(class [mscorlib]System.Collections.Generic.List`1<string> 'names') cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'ordered', class [mscorlib]System.Collections.Generic.List`1<string> 'dup', valuetype TkvInt 'i', valuetype TkvInt 'j', valuetype TkvInt '__strtmp1720316946416', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
    dup
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Sort()
    stloc.s 0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 1
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 2
  duplicates_W1_start:
    ldloc.s 2
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    clt
    brfalse duplicates_W1_end
    ldloc.s 2
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue duplicates_int2_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue duplicates_int2_slow
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
    blt duplicates_int2_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br duplicates_int2_done
  duplicates_int2_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  duplicates_int2_done:
    stloc.s 3
  duplicates_W3_start:
    ldloc.s 3
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    clt
    brfalse duplicates_W3_end
    ldloc.s 0
    ldloc.s 3
    call int32 TkvInt::ToI32(valuetype TkvInt)
    dup
    ldc.i4.0
    bge.s duplicates_idx_pos_5
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s duplicates_idx_end_5
  duplicates_idx_pos_5:
  duplicates_idx_end_5:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldloc.s 0
    ldloc.s 2
    call int32 TkvInt::ToI32(valuetype TkvInt)
    dup
    ldc.i4.0
    bge.s duplicates_idx_pos_6
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s duplicates_idx_end_6
  duplicates_idx_pos_6:
  duplicates_idx_end_6:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse duplicates_If4_else
    br duplicates_W3_end
  duplicates_If4_else:
    ldloc.s 3
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue duplicates_int7_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue duplicates_int7_slow
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
    blt duplicates_int7_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br duplicates_int7_done
  duplicates_int7_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  duplicates_int7_done:
    stloc.s 3
    br duplicates_W3_start
  duplicates_W3_end:
    ldloc.s 3
    ldloc.s 2
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue duplicates_int9_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue duplicates_int9_slow
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    sub
    stloc.s 8
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    xor
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    and
    ldc.i8 0
    blt duplicates_int9_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br duplicates_int9_done
  duplicates_int9_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::SubSlow(valuetype TkvInt, valuetype TkvInt)
  duplicates_int9_done:
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    cgt
    brfalse duplicates_If8_else
    ldloc.s 1
    ldloc.s 0
    ldloc.s 2
    call int32 TkvInt::ToI32(valuetype TkvInt)
    dup
    ldc.i4.0
    bge.s duplicates_idx_pos_10
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s duplicates_idx_end_10
  duplicates_idx_pos_10:
  duplicates_idx_end_10:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldstr "x"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 3
    ldloc.s 2
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue duplicates_int11_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue duplicates_int11_slow
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    sub
    stloc.s 8
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloca.s 6
    ldfld int64 TkvInt::lo
    xor
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 8
    xor
    and
    ldc.i8 0
    blt duplicates_int11_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br duplicates_int11_done
  duplicates_int11_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::SubSlow(valuetype TkvInt, valuetype TkvInt)
  duplicates_int11_done:
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  duplicates_If8_else:
    ldloc.s 3
    stloc.s 2
    br duplicates_W1_start
  duplicates_W1_end:
    ldloc.s 1
    ret
  }
  .method public static string 'join_ints'(class [mscorlib]System.Collections.Generic.List`1<int32> 'nums') cil managed
  {
    .maxstack 10
    .locals init (string 'out', int32 'i', class [mscorlib]System.Text.StringBuilder '__sb_out', int32 '__strtmp1720316437760', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr ""
    stloc.s 0
    ldc.i4.0
    stloc.s 1
    ldloc.s 0
    newobj instance void [mscorlib]System.Text.StringBuilder::.ctor(string)
    stloc.s 2
  join_ints_L1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Count()
    bge join_ints_L1_end
    ldloc.s 1
    ldc.i4 0
    cgt
    brfalse join_ints_If2_else
    ldloc.s 2
    ldstr ","
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
    pop
  join_ints_If2_else:
    ldloc.s 2
    ldarg.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s join_ints_idx_pos_3
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Count()
    add
    br.s join_ints_idx_end_3
  join_ints_idx_pos_3:
  join_ints_idx_end_3:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    call string TkvStr::I32(int32)
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
    pop
  join_ints_L1_cont:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br join_ints_L1_start
  join_ints_L1_end:
    ldloc.s 2
    callvirt instance string [mscorlib]System.Object::ToString()
    stloc.s 0
    ldloc.s 0
    ret
  }
  .method public static int32 'pct'(int32 'part', int32 'whole') cil managed
  {
    .maxstack 8
    .locals init (int32 '__idiv1720316950976_a', int32 '__idiv1720316950976_b', int32 '__idiv1720316950976_q', int32 '__idiv1720316950976_r', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 1
    ldc.i4 0
    ceq
    brfalse pct_If1_else
    ldc.i4 0
    ret
  pct_If1_else:
    ldarg.s 0
    ldc.i4 100
    mul.ovf
    stloc.s 0
    ldarg.s 1
    stloc.s 1
    ldloc.s 0
    ldloc.s 1
    div
    stloc.s 2
    ldloc.s 0
    ldloc.s 1
    rem
    stloc.s 3
    ldloc.s 3
    ldc.i4.0
    beq pct_idiv2_done
    ldloc.s 0
    ldloc.s 1
    xor
    ldc.i4.0
    bge pct_idiv2_done
    ldloc.s 2
    ldc.i4.1
    sub
    stloc.s 2
  pct_idiv2_done:
    ldloc.s 2
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'head_section'(class [mscorlib]System.Collections.Generic.List`1<string> 'lines', class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32> 'tally') cil managed
  {
    .maxstack 10
    .locals init (int32 'total', int32 'code', class [mscorlib]System.Collections.Generic.List`1<string> 'out', int32 '__strtmp1720316436032', int32 '__strtmp1720316412416', int32 '__strtmp1720316416896', int32 '__idiv1720316922032_a', int32 '__idiv1720316922032_b', int32 '__idiv1720316922032_q', int32 '__idiv1720316922032_r', int32 '__strtmp1720316922032', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 0
    ldarg.s 1
    ldstr "code"
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
    stloc.s 1
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 2
    ldloc.s 2
    ldstr "== codestat =="
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 2
    ldstr "dong tong    : "
    ldloc.s 0
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 2
    ldstr "dong ma      : "
    ldloc.s 1
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " ("
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    ldloc.s 0
    call int32 TKVApp::'pct'(int32, int32)
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "%)"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 2
    ldstr "dong chu thich: "
    ldarg.s 1
    ldstr "comment"
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 2
    ldstr "dong trong   : "
    ldarg.s 1
    ldstr "blank"
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::get_Item(!0)
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 2
    ldstr "thut le sau nhat: "
    ldarg.s 0
    call int32 TKVApp::'deepest_indent'(class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 6
    ldc.i4 4
    stloc.s 7
    ldloc.s 6
    ldloc.s 7
    div
    stloc.s 8
    ldloc.s 6
    ldloc.s 7
    rem
    stloc.s 9
    ldloc.s 9
    ldc.i4.0
    beq head_section_idiv1_done
    ldloc.s 6
    ldloc.s 7
    xor
    ldc.i4.0
    bge head_section_idiv1_done
    ldloc.s 8
    ldc.i4.1
    sub
    stloc.s 8
  head_section_idiv1_done:
    ldloc.s 8
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " cap"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 2
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'func_section'(class [mscorlib]System.Collections.Generic.List`1<string> 'spans') cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', int32 '__strtmp1720316413568', valuetype TkvInt 'total_span', int32 '__iterlist5_idx', string 'rec', valuetype TkvInt '__strtmp1720316921792', class [mscorlib]System.Collections.Generic.List`1<string> 'over', int32 '__iterlist6_idx', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldloc.s 0
    ldstr "ham          : "
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 2
    ldc.i4.0
    stloc.s 3
  func_section_L1_start:
    ldloc.s 3
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge func_section_L1_end
    ldarg.s 0
    ldloc.s 3
    dup
    ldc.i4.0
    bge.s func_section_idx_pos_2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s func_section_idx_end_2
  func_section_idx_pos_2:
  func_section_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 4
    ldloc.s 2
    ldloc.s 4
    ldc.i4 2
    call string TKVApp::'field_at'(string, int32)
    call valuetype TkvInt TkvInt::FromStr(string)
    stloc.s 9
    stloc.s 8
    ldloca.s 8
    ldfld object TkvInt::big
    brtrue func_section_int3_slow
    ldloca.s 9
    ldfld object TkvInt::big
    brtrue func_section_int3_slow
    ldloca.s 8
    ldfld int64 TkvInt::lo
    ldloca.s 9
    ldfld int64 TkvInt::lo
    add
    stloc.s 11
    ldloca.s 8
    ldfld int64 TkvInt::lo
    ldloc.s 11
    xor
    ldloca.s 9
    ldfld int64 TkvInt::lo
    ldloc.s 11
    xor
    and
    ldc.i8 0
    blt func_section_int3_slow
    ldloca.s 10
    ldloc.s 11
    stfld int64 TkvInt::lo
    ldloca.s 10
    ldnull
    stfld object TkvInt::big
    ldloc.s 10
    br func_section_int3_done
  func_section_int3_slow:
    ldloc.s 8
    ldloc.s 9
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  func_section_int3_done:
    stloc.s 2
  func_section_L1_cont:
    ldloc.s 3
    ldc.i4 1
    add
    stloc.s 3
    br func_section_L1_start
  func_section_L1_end:
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 0
    cgt
    brfalse func_section_If4_else
    ldloc.s 0
    ldstr "do dai TB    : "
    ldloc.s 2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    call valuetype TkvInt TkvInt::FloorDiv(valuetype TkvInt, valuetype TkvInt)
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " dong"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  func_section_If4_else:
    ldarg.s 0
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'long_funcs'(class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 6
    ldloc.s 6
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 0
    ceq
    brfalse func_section_If5_else
    ldloc.s 0
    ldstr "ham qua dai  : khong"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br func_section_If5_end
  func_section_If5_else:
    ldc.i4.0
    stloc.s 7
  func_section_L6_start:
    ldloc.s 7
    ldloc.s 6
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge func_section_L6_end
    ldloc.s 6
    ldloc.s 7
    dup
    ldc.i4.0
    bge.s func_section_idx_pos_7
    ldloc.s 6
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s func_section_idx_end_7
  func_section_idx_pos_7:
  func_section_idx_end_7:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 4
    ldloc.s 0
    ldstr "  QUA DAI: "
    ldloc.s 4
    ldc.i4 0
    call string TKVApp::'field_at'(string, int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " (dong "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 4
    ldc.i4 1
    call string TKVApp::'field_at'(string, int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ", "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 4
    ldc.i4 2
    call string TKVApp::'field_at'(string, int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " dong > "
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "50"
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ")"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  func_section_L6_cont:
    ldloc.s 7
    ldc.i4 1
    add
    stloc.s 7
    br func_section_L6_start
  func_section_L6_end:
  func_section_If5_end:
    ldloc.s 0
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'class_section'(class [mscorlib]System.Collections.Generic.List`1<string> 'spans') cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', int32 '__strtmp1720316392192', int32 '__iterlist7_idx', string 'rec', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldloc.s 0
    ldstr "class        : "
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldc.i4.0
    stloc.s 2
  class_section_L1_start:
    ldloc.s 2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge class_section_L1_end
    ldarg.s 0
    ldloc.s 2
    dup
    ldc.i4.0
    bge.s class_section_idx_pos_2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s class_section_idx_end_2
  class_section_idx_pos_2:
  class_section_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 3
    ldloc.s 0
    ldstr "  "
    ldloc.s 3
    ldc.i4 0
    call string TKVApp::'field_at'(string, int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " (dong "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 3
    ldc.i4 1
    call string TKVApp::'field_at'(string, int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ", "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 3
    ldc.i4 2
    call string TKVApp::'field_at'(string, int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " method)"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  class_section_L1_cont:
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    br class_section_L1_start
  class_section_L1_end:
    ldloc.s 0
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'warn_section'(class [mscorlib]System.Collections.Generic.List`1<string> 'lines', class [mscorlib]System.Collections.Generic.List`1<string> 'names') cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', class [mscorlib]System.Collections.Generic.List`1<int32> 'marks', int32 '__strtmp1720316416448', class [mscorlib]System.Collections.Generic.List`1<string> 'dup', int32 'idx', int32 'n', string 'tail', int32 '__strtmp1720316590368', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldarg.s 0
    call class [mscorlib]System.Collections.Generic.List`1<int32> TKVApp::'marker_lines'(class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 1
    ldloc.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Count()
    ldc.i4 0
    ceq
    brfalse warn_section_If1_else
    ldloc.s 0
    ldstr "TODO/FIXME   : khong"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br warn_section_If1_end
  warn_section_If1_else:
    ldloc.s 0
    ldstr "TODO/FIXME   : "
    ldloc.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Count()
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " (dong "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    call string TKVApp::'join_ints'(class [mscorlib]System.Collections.Generic.List`1<int32>)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ")"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  warn_section_If1_end:
    ldarg.s 1
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'duplicates'(class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 3
    ldloc.s 3
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 0
    ceq
    brfalse warn_section_If2_else
    ldloc.s 0
    ldstr "ten ham trung: khong"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br warn_section_If2_end
  warn_section_If2_else:
    ldloc.s 0
    ldstr "ten ham trung: "
    ldstr ","
    ldloc.s 3
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  warn_section_If2_end:
    ldarg.s 0
    call int32 TKVApp::'longest_line'(class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse warn_section_If3_else
    ldarg.s 0
    ldloc.s 4
    dup
    ldc.i4.0
    bge.s warn_section_idx_pos_4
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s warn_section_idx_end_4
  warn_section_idx_pos_4:
  warn_section_idx_end_4:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance int32 [mscorlib]System.String::get_Length()
    stloc.s 5
    ldstr ""
    stloc.s 6
    ldloc.s 5
    ldc.i4 100
    cgt
    brfalse warn_section_If5_else
    ldstr " QUA DAI"
    stloc.s 6
  warn_section_If5_else:
    ldloc.s 0
    ldstr "dong dai nhat: "
    ldloc.s 5
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " ky tu (dong "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 4
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ")"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 6
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  warn_section_If3_else:
    ldloc.s 0
    ret
  }
  .method public static string 'report_text'(string 'txt') cil managed
  {
    .maxstack 11
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'lines', class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32> 'tally', class [mscorlib]System.Collections.Generic.List`1<string> 'spans', class [mscorlib]System.Collections.Generic.List`1<string> 'out', class [mscorlib]System.Collections.Generic.List`1<string> '__forsrc1720316909952', int32 '__foridx1720316909952', string 's', class [mscorlib]System.Collections.Generic.List`1<string> '__forsrc1720316911104', int32 '__foridx1720316911104', class [mscorlib]System.Collections.Generic.List`1<string> '__forsrc1720316863936', int32 '__foridx1720316863936', class [mscorlib]System.Collections.Generic.List`1<string> '__forsrc1720316854592', int32 '__foridx1720316854592', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'split_lines'(string)
    stloc.s 0
    ldloc.s 0
    call class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32> TKVApp::'count_kinds'(class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 1
    ldloc.s 0
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'func_spans'(class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 2
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 3
    ldloc.s 0
    ldloc.s 1
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'head_section'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>)
    stloc.s 4
    ldc.i4.0
    stloc.s 5
  report_text_FCL1_start:
    ldloc.s 5
    ldloc.s 4
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge report_text_FCL1_end
    ldloc.s 4
    ldloc.s 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 6
    ldloc.s 3
    ldloc.s 6
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  report_text_FCL1_cont:
    ldloc.s 5
    ldc.i4.1
    add
    stloc.s 5
    br report_text_FCL1_start
  report_text_FCL1_end:
    ldloc.s 2
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'func_section'(class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 7
    ldc.i4.0
    stloc.s 8
  report_text_FCL2_start:
    ldloc.s 8
    ldloc.s 7
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge report_text_FCL2_end
    ldloc.s 7
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 6
    ldloc.s 3
    ldloc.s 6
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  report_text_FCL2_cont:
    ldloc.s 8
    ldc.i4.1
    add
    stloc.s 8
    br report_text_FCL2_start
  report_text_FCL2_end:
    ldloc.s 0
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'class_spans'(class [mscorlib]System.Collections.Generic.List`1<string>)
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'class_section'(class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 9
    ldc.i4.0
    stloc.s 10
  report_text_FCL3_start:
    ldloc.s 10
    ldloc.s 9
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge report_text_FCL3_end
    ldloc.s 9
    ldloc.s 10
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 6
    ldloc.s 3
    ldloc.s 6
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  report_text_FCL3_cont:
    ldloc.s 10
    ldc.i4.1
    add
    stloc.s 10
    br report_text_FCL3_start
  report_text_FCL3_end:
    ldloc.s 0
    ldloc.s 0
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'func_names'(class [mscorlib]System.Collections.Generic.List`1<string>)
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'warn_section'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 11
    ldc.i4.0
    stloc.s 12
  report_text_FCL4_start:
    ldloc.s 12
    ldloc.s 11
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge report_text_FCL4_end
    ldloc.s 11
    ldloc.s 12
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 6
    ldloc.s 3
    ldloc.s 6
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  report_text_FCL4_cont:
    ldloc.s 12
    ldc.i4.1
    add
    stloc.s 12
    br report_text_FCL4_start
  report_text_FCL4_end:
    ldstr "\n"
    ldloc.s 3
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    ret
  }
  .method public static string 'main'(string 'path') cil managed
  {
    .maxstack 11
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    call string [mscorlib]System.IO.File::ReadAllText(string)
    ldstr "\r\n"
    ldstr "\n"
    callvirt instance string [mscorlib]System.String::Replace(string, string)
    ldstr "\r"
    ldstr "\n"
    callvirt instance string [mscorlib]System.String::Replace(string, string)
    call string TKVApp::'report_text'(string)
    ret
  }
  .method public static hidebysig pinvokeimpl("kernel32.dll" ansi winapi) native int LoadLibraryA(string lpLibFileName) cil managed preservesig {}
  .method public static hidebysig pinvokeimpl("kernel32.dll" ansi winapi) native int GetProcAddress(native int hModule, string lpProcName) cil managed preservesig {}
  .method public static hidebysig pinvokeimpl("ucrtbase.dll" ansi cdecl) int32 puts(string str) cil managed preservesig {}

  .method public static native int TkvLoadCDLL(string dllName) cil managed
  {
    .maxstack 8
    ldarg.0
    call native int TKVApp::LoadLibraryA(string)
    ret
  }
  .method public static int32 TkvCCall(string msg) cil managed
  {
    .maxstack 8
    ldarg.0
    call int32 TKVApp::puts(string)
    ret
  }

  .method public static int32 TkvEvalCode(string expr) cil managed
  {
    .maxstack 8
    .locals init (int32 'idx', string 'left', string 'right', int32 'a', int32 'b')
    ldarg.0
    ldstr "+"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.0
    ldloc.0
    ldc.i4.0
    blt IL_eval_raw

    ldarg.0
    ldc.i4.0
    ldloc.0
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    callvirt instance string [mscorlib]System.String::Trim()
    call int32 [mscorlib]System.Int32::Parse(string)
    stloc.3

    ldarg.0
    ldloc.0
    ldc.i4.1
    add
    callvirt instance string [mscorlib]System.String::Substring(int32)
    callvirt instance string [mscorlib]System.String::Trim()
    call int32 [mscorlib]System.Int32::Parse(string)
    stloc.s 4

    ldloc.3
    ldloc.s 4
    add
    ret

    IL_eval_raw:
    ldarg.0
    ldstr " "
    ldstr ""
    callvirt instance string [mscorlib]System.String::Replace(string, string)
    call int32 [mscorlib]System.Int32::Parse(string)
    ret
  }
  .method public static string TkvExecCode(string code) cil managed
  {
    .maxstack 8
    ldstr "EXEC_OK:"
    ldarg.0
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }

  .method public static string TkvReReplace(string text, string pattern, string replacement) cil managed
  {
    .maxstack 8
    ldarg.0
    ldarg.1
    ldarg.2
    call string [System]System.Text.RegularExpressions.Regex::Replace(string, string, string)
    ret
  }
  .method public static string TkvDateTimeNow() cil managed
  {
    .maxstack 8
    .locals init (valuetype [mscorlib]System.DateTime 'dt')
    call valuetype [mscorlib]System.DateTime [mscorlib]System.DateTime::get_Now()
    stloc.0
    ldloca.s 0
    callvirt instance string [mscorlib]System.DateTime::ToString()
    ret
  }
  .method public static int32 TkvRandomRandint(int32 min_val, int32 max_val) cil managed
  {
    .maxstack 8
    newobj instance void [mscorlib]System.Random::.ctor()
    ldarg.0
    ldarg.1
    callvirt instance int32 [mscorlib]System.Random::Next(int32, int32)
    ret
  }

  .method public static class [mscorlib]System.Collections.Generic.List`1<object> TkvPyTupleNew(int32 size) cil managed
  {
    .maxstack 8
    ldarg.0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<object>::.ctor(int32)
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.Dictionary`2<object,object> TkvPyDictNew() cil managed
  {
    .maxstack 8
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<object,object>::.ctor()
    ret
  }

  .method public static void Main(string[] args) cil managed
  {
    .entrypoint
    .maxstack 8
    ldarg.0
    ldc.i4 0
    ldelem.ref
    call string TKVApp::'main'(string)
    call void [mscorlib]System.Console::WriteLine(string)
    ret
  }
}
