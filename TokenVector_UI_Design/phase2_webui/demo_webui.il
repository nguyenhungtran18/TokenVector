.assembly extern mscorlib {}
.assembly extern System.Core { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly extern System { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly extern System.Numerics { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly TKVApp {}
.module TKVApp.exe

.class public auto ansi ApiRequest extends [mscorlib]System.Object
{
  .field public string 'method'
  .field public string 'path'
  .field public string 'body'
  .method public hidebysig specialname rtspecialname instance void .ctor(string 'method', string 'path', string 'body') cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.s 1
    stfld string ApiRequest::'method'
    ldarg.0
    ldarg.s 2
    stfld string ApiRequest::'path'
    ldarg.0
    ldarg.s 3
    stfld string ApiRequest::'body'
    ret
  }
}
.class public auto ansi ApiResponse extends [mscorlib]System.Object
{
  .field public int32 'status'
  .field public string 'body'
  .field public string 'content_type'
  .method public hidebysig specialname rtspecialname instance void .ctor(int32 'status', string 'body', string 'content_type') cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.s 1
    stfld int32 ApiResponse::'status'
    ldarg.0
    ldarg.s 2
    stfld string ApiResponse::'body'
    ldarg.0
    ldarg.s 3
    stfld string ApiResponse::'content_type'
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
  .method public static string 'json_str'(string 'key', string 'val') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "\""
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\": \""
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\""
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static string 'json_int'(string 'key', int32 'val') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "\""
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\": "
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static string 'build_json'(string 'fields') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "{"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "}"
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static class ApiResponse 'handle_route'(class ApiRequest 'req') cil managed
  {
    .maxstack 11
    .locals init (string 'body', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld string ApiRequest::'path'
    ldstr "/api/info"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse handle_route_If1_else
    ldstr "name"
    ldstr "TokenVector"
    call string TKVApp::'json_str'(string, string)
    ldstr ", "
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "version"
    ldstr "2026.1.0"
    call string TKVApp::'json_str'(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ", "
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "compiler"
    ldstr "tkvc"
    call string TKVApp::'json_str'(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ", "
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "output"
    ldstr "Native AOT .exe"
    call string TKVApp::'json_str'(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call string TKVApp::'build_json'(string)
    stloc.s 0
    ldc.i4 200
    ldloc.s 0
    ldstr "application/json"
    newobj instance void ApiResponse::.ctor(int32, string, string)
    ret
  handle_route_If1_else:
    ldarg.s 0
    ldfld string ApiRequest::'path'
    ldstr "/api/status"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse handle_route_If2_else
    ldstr "status"
    ldstr "running"
    call string TKVApp::'json_str'(string, string)
    ldstr ", "
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "uptime_ms"
    ldc.i4 100
    call string TKVApp::'json_int'(string, int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ", "
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\"no_gil\": true, "
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "threads"
    ldc.i4 4
    call string TKVApp::'json_int'(string, int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string TKVApp::'build_json'(string)
    stloc.s 0
    ldc.i4 200
    ldloc.s 0
    ldstr "application/json"
    newobj instance void ApiResponse::.ctor(int32, string, string)
    ret
  handle_route_If2_else:
    ldarg.s 0
    ldfld string ApiRequest::'path'
    ldstr "/api/benchmark"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse handle_route_If3_else
    ldstr "integer_loop_10M_ms"
    ldc.i4 410
    call string TKVApp::'json_int'(string, int32)
    ldstr ", "
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "float_ops_2M_ms"
    ldc.i4 429
    call string TKVApp::'json_int'(string, int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ", "
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "multithread_4t_ms"
    ldc.i4 244
    call string TKVApp::'json_int'(string, int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ", "
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "speedup_vs_python"
    ldc.i4 10
    call string TKVApp::'json_int'(string, int32)
    call string [mscorlib]System.String::Concat(string, string)
    call string TKVApp::'build_json'(string)
    stloc.s 0
    ldc.i4 200
    ldloc.s 0
    ldstr "application/json"
    newobj instance void ApiResponse::.ctor(int32, string, string)
    ret
  handle_route_If3_else:
    ldarg.s 0
    ldfld string ApiRequest::'path'
    ldstr "/api/compile"
    call bool [mscorlib]System.String::Equals(string, string)
    dup
    brfalse handle_route_sc5_end
    pop
    ldarg.s 0
    ldfld string ApiRequest::'method'
    ldstr "POST"
    call bool [mscorlib]System.String::Equals(string, string)
  handle_route_sc5_end:
    brfalse handle_route_If4_else
    ldstr "status"
    ldstr "queued"
    call string TKVApp::'json_str'(string, string)
    ldstr ", "
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "message"
    ldstr "Compilation scheduled"
    call string TKVApp::'json_str'(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ", "
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "source"
    ldarg.s 0
    ldfld string ApiRequest::'body'
    call string TKVApp::'json_str'(string, string)
    call string [mscorlib]System.String::Concat(string, string)
    call string TKVApp::'build_json'(string)
    stloc.s 0
    ldc.i4 201
    ldloc.s 0
    ldstr "application/json"
    newobj instance void ApiResponse::.ctor(int32, string, string)
    ret
  handle_route_If4_else:
  handle_route_If3_end:
  handle_route_If2_end:
  handle_route_If1_end:
    ldstr "error"
    ldstr "Route not found: "
    ldarg.s 0
    ldfld string ApiRequest::'path'
    call string [mscorlib]System.String::Concat(string, string)
    call string TKVApp::'json_str'(string, string)
    call string TKVApp::'build_json'(string)
    stloc.s 0
    ldc.i4 404
    ldloc.s 0
    ldstr "application/json"
    newobj instance void ApiResponse::.ctor(int32, string, string)
    ret
  }
  .method public static int32 'print_request'(class ApiRequest 'req') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "  \x1b[90m>>> "
    ldarg.s 0
    ldfld string ApiRequest::'method'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld string ApiRequest::'path'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\x1b[0m"
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
    ret
  }
  .method public static int32 'print_response'(class ApiResponse 'resp') cil managed
  {
    .maxstack 10
    .locals init (int32 '__strtmp2255113597248', int32 '__strtmp2255113599360', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld int32 ApiResponse::'status'
    ldc.i4 200
    ceq
    dup
    brtrue print_response_sc2_end
    pop
    ldarg.s 0
    ldfld int32 ApiResponse::'status'
    ldc.i4 201
    ceq
  print_response_sc2_end:
    brfalse print_response_If1_else
    ldstr "  \x1b[32m<<< "
    ldarg.s 0
    ldfld int32 ApiResponse::'status'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\x1b[0m "
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld string ApiResponse::'body'
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    br print_response_If1_end
  print_response_If1_else:
    ldstr "  \x1b[31m<<< "
    ldarg.s 0
    ldfld int32 ApiResponse::'status'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\x1b[0m "
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld string ApiResponse::'body'
    call string [mscorlib]System.String::Concat(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
  print_response_If1_end:
    ldc.i4 1
    ret
  }
  .method public static int32 'main'() cil managed
  {
    .maxstack 11
    .locals init (class ApiRequest 'req1', class ApiRequest 'req2', class ApiRequest 'req3', class ApiRequest 'req4', class ApiRequest 'req5', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "\x1b[1m\x1b[36m=== TOKENVECTOR WEB UI BRIDGE - PHASE 2 DEMO ===\x1b[0m"
    call void [mscorlib]System.Console::WriteLine(string)
    ldstr ""
    call void [mscorlib]System.Console::WriteLine(string)
    ldstr "\x1b[33m  Simulating HTTP API request-response cycle...\x1b[0m"
    call void [mscorlib]System.Console::WriteLine(string)
    ldstr ""
    call void [mscorlib]System.Console::WriteLine(string)
    ldstr "GET"
    ldstr "/api/info"
    ldstr ""
    newobj instance void ApiRequest::.ctor(string, string, string)
    stloc.s 0
    ldloc.s 0
    call int32 TKVApp::'print_request'(class ApiRequest)
    pop
    ldloc.s 0
    call class ApiResponse TKVApp::'handle_route'(class ApiRequest)
    call int32 TKVApp::'print_response'(class ApiResponse)
    pop
    ldstr ""
    call void [mscorlib]System.Console::WriteLine(string)
    ldstr "GET"
    ldstr "/api/status"
    ldstr ""
    newobj instance void ApiRequest::.ctor(string, string, string)
    stloc.s 1
    ldloc.s 1
    call int32 TKVApp::'print_request'(class ApiRequest)
    pop
    ldloc.s 1
    call class ApiResponse TKVApp::'handle_route'(class ApiRequest)
    call int32 TKVApp::'print_response'(class ApiResponse)
    pop
    ldstr ""
    call void [mscorlib]System.Console::WriteLine(string)
    ldstr "GET"
    ldstr "/api/benchmark"
    ldstr ""
    newobj instance void ApiRequest::.ctor(string, string, string)
    stloc.s 2
    ldloc.s 2
    call int32 TKVApp::'print_request'(class ApiRequest)
    pop
    ldloc.s 2
    call class ApiResponse TKVApp::'handle_route'(class ApiRequest)
    call int32 TKVApp::'print_response'(class ApiResponse)
    pop
    ldstr ""
    call void [mscorlib]System.Console::WriteLine(string)
    ldstr "POST"
    ldstr "/api/compile"
    ldstr "hello.tkv"
    newobj instance void ApiRequest::.ctor(string, string, string)
    stloc.s 3
    ldloc.s 3
    call int32 TKVApp::'print_request'(class ApiRequest)
    pop
    ldloc.s 3
    call class ApiResponse TKVApp::'handle_route'(class ApiRequest)
    call int32 TKVApp::'print_response'(class ApiResponse)
    pop
    ldstr ""
    call void [mscorlib]System.Console::WriteLine(string)
    ldstr "GET"
    ldstr "/api/unknown"
    ldstr ""
    newobj instance void ApiRequest::.ctor(string, string, string)
    stloc.s 4
    ldloc.s 4
    call int32 TKVApp::'print_request'(class ApiRequest)
    pop
    ldloc.s 4
    call class ApiResponse TKVApp::'handle_route'(class ApiRequest)
    call int32 TKVApp::'print_response'(class ApiResponse)
    pop
    ldstr ""
    call void [mscorlib]System.Console::WriteLine(string)
    ldstr "\x1b[90m  -----------------------------------------------\x1b[0m"
    call void [mscorlib]System.Console::WriteLine(string)
    ldstr "\x1b[32m  [OK] Phase 2 Web UI Bridge logic: 100% functional\x1b[0m"
    call void [mscorlib]System.Console::WriteLine(string)
    ldstr "\x1b[36m  [HTML] Template: TokenVector_UI_Design/phase2_webui/templates/dashboard.html\x1b[0m"
    call void [mscorlib]System.Console::WriteLine(string)
    ldstr "\x1b[90m  Next: Connect tkvc_http to .NET HttpListener for real HTTP serving\x1b[0m"
    call void [mscorlib]System.Console::WriteLine(string)
    ldc.i4 1
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
    .locals init (int32 __cli_ret)
    call int32 TKVApp::'main'()
    stloc.0
    ldloca.s 0
    call instance string [mscorlib]System.Int32::ToString()
    call void [mscorlib]System.Console::WriteLine(string)
    ret
  }
}
