.assembly extern mscorlib {}
.assembly extern System.Core { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly extern System { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly extern System.Numerics { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly TKVApp {}
.module TKVApp.exe

.class public auto ansi CalcError extends [mscorlib]System.Exception
{
  .field public string 'msg'
  .method public hidebysig specialname rtspecialname instance void .ctor(string 'msg') cil managed
  {
    .maxstack 8
    ldarg.0
    ldarg.1
    call instance void [mscorlib]System.Exception::.ctor(string)
    ldarg.0
    ldarg.s 1
    stfld string CalcError::'msg'
    ret
  }
  .method public hidebysig newslot virtual instance string 'label'() cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "loi"
    ret
  }
  .method public hidebysig newslot virtual instance string 'render'() cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance string CalcError::'label'()
    ldstr ": "
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld string CalcError::'msg'
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
}
.class public auto ansi LexError extends CalcError
{
  .method public hidebysig specialname rtspecialname instance void .ctor(string 'msg') cil managed
  {
    .maxstack 8
    ldarg.0
    ldarg.s 1
    call instance void CalcError::.ctor(string 'msg')
    ret
  }
  .method public hidebysig virtual instance string 'label'() cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "loi tu vung"
    ret
  }
}
.class public auto ansi ParseError extends CalcError
{
  .method public hidebysig specialname rtspecialname instance void .ctor(string 'msg') cil managed
  {
    .maxstack 8
    ldarg.0
    ldarg.s 1
    call instance void CalcError::.ctor(string 'msg')
    ret
  }
  .method public hidebysig virtual instance string 'label'() cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "loi cu phap"
    ret
  }
}
.class public auto ansi EvalError extends CalcError
{
  .method public hidebysig specialname rtspecialname instance void .ctor(string 'msg') cil managed
  {
    .maxstack 8
    ldarg.0
    ldarg.s 1
    call instance void CalcError::.ctor(string 'msg')
    ret
  }
  .method public hidebysig virtual instance string 'label'() cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "loi tinh toan"
    ret
  }
}
.class public auto ansi Tok extends [mscorlib]System.Object
{
  .field public string 'kind'
  .field public string 'text'
  .field public int32 'pos'
  .method public hidebysig specialname rtspecialname instance void .ctor(string 'kind', string 'text', int32 'pos') cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.s 1
    stfld string Tok::'kind'
    ldarg.0
    ldarg.s 2
    stfld string Tok::'text'
    ldarg.0
    ldarg.s 3
    stfld int32 Tok::'pos'
    ret
  }
  .method public hidebysig newslot virtual instance string 'show'() cil managed
  {
    .maxstack 10
    .locals init (int32 '__strtmp1893928210048', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld string Tok::'kind'
    ldstr "("
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld string Tok::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ")@"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld int32 Tok::'pos'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public hidebysig newslot virtual instance int32 'is_kind'(string 'want') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld string Tok::'kind'
    ldarg.s 1
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_kind_If1_else
    ldc.i4 1
    ret
  is_kind_If1_else:
    ldc.i4 0
    ret
  }
  .method public hidebysig newslot virtual instance int32 'is_value_start'() cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld string Tok::'kind'
    ldstr "NUM"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_value_start_If1_else
    ldc.i4 1
    ret
  is_value_start_If1_else:
    ldarg.s 0
    ldfld string Tok::'kind'
    ldstr "NAME"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_value_start_If2_else
    ldc.i4 1
    ret
  is_value_start_If2_else:
    ldarg.s 0
    ldfld string Tok::'kind'
    ldstr "LPAREN"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_value_start_If3_else
    ldc.i4 1
    ret
  is_value_start_If3_else:
    ldc.i4 0
    ret
  }
  .method public hidebysig newslot virtual instance int32 'is_end'() cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld string Tok::'kind'
    ldstr "EOF"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_end_If1_else
    ldc.i4 1
    ret
  is_end_If1_else:
    ldarg.s 0
    ldfld string Tok::'kind'
    ldstr "SEMI"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_end_If2_else
    ldc.i4 1
    ret
  is_end_If2_else:
    ldc.i4 0
    ret
  }
  .method public hidebysig newslot virtual instance float64 'numeric_value'() cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld string Tok::'kind'
    ldstr "NUM"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse numeric_value_If1_else
    ldstr "the '"
    ldarg.s 0
    ldfld string Tok::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' khong phai so"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class EvalError::.ctor(string)
    throw
  numeric_value_If1_else:
    ldarg.s 0
    ldfld string Tok::'text'
    call float64 TkvStr::ParseF64(string)
    ret
  }
}
.class public auto ansi SrcCursor extends [mscorlib]System.Object
{
  .field public string 'src'
  .field public int32 'pos'
  .method public hidebysig specialname rtspecialname instance void .ctor(string 'src', int32 'pos') cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.s 1
    stfld string SrcCursor::'src'
    ldarg.0
    ldarg.s 2
    stfld int32 SrcCursor::'pos'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'at_end'() cil managed
  {
    .maxstack 9
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldarg.s 0
    ldfld string SrcCursor::'src'
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    ldc.i4.0
    ceq
    brfalse at_end_If1_else
    ldc.i4 1
    ret
  at_end_If1_else:
    ldc.i4 0
    ret
  }
  .method public hidebysig newslot virtual instance string 'peek_ch'() cil managed
  {
    .maxstack 10
    .locals init (string '__hoist0', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance int32 SrcCursor::'at_end'()
    ldc.i4 1
    ceq
    brfalse peek_ch_If1_else
    ldstr ""
    ret
  peek_ch_If1_else:
    ldarg.s 0
    ldfld string SrcCursor::'src'
    stloc.s 0
    ldloc.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    dup
    ldc.i4.0
    bge.s peek_ch_idx_pos_2
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    br.s peek_ch_idx_end_2
  peek_ch_idx_pos_2:
  peek_ch_idx_end_2:
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ret
  }
  .method public hidebysig newslot virtual instance string 'peek_ch_at'(int32 'offset') cil managed
  {
    .maxstack 10
    .locals init (int32 'k', string '__hoist1', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldarg.s 1
    add.ovf
    stloc.s 0
    ldloc.s 0
    ldarg.s 0
    ldfld string SrcCursor::'src'
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    ldc.i4.0
    ceq
    brfalse peek_ch_at_If1_else
    ldstr ""
    ret
  peek_ch_at_If1_else:
    ldloc.s 0
    ldc.i4 0
    clt
    brfalse peek_ch_at_If2_else
    ldstr ""
    ret
  peek_ch_at_If2_else:
    ldarg.s 0
    ldfld string SrcCursor::'src'
    stloc.s 1
    ldloc.s 1
    ldloc.s 0
    dup
    ldc.i4.0
    bge.s peek_ch_at_idx_pos_3
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    br.s peek_ch_at_idx_end_3
  peek_ch_at_idx_pos_3:
  peek_ch_at_idx_end_3:
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ret
  }
  .method public hidebysig newslot virtual instance string 'advance'() cil managed
  {
    .maxstack 9
    .locals init (string 'ch', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance string SrcCursor::'peek_ch'()
    stloc.s 0
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    ldloc.s 0
    ret
  }
  .method public hidebysig newslot virtual instance int32 'remaining'() cil managed
  {
    .maxstack 9
    .locals init (string '__hoist2', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld string SrcCursor::'src'
    stloc.s 0
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    sub.ovf
    ret
  }
  .method public hidebysig newslot virtual instance string 'describe'() cil managed
  {
    .maxstack 10
    .locals init (string '__hoist3', int32 '__strtmp1893922206208', int32 '__strtmp1893922209536', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld string SrcCursor::'src'
    stloc.s 0
    ldstr "cursor@"
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "/"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
}
.class public auto ansi Lexer extends SrcCursor
{
  .field public int32 'count'
  .method public hidebysig specialname rtspecialname instance void .ctor(string 'src', int32 'pos', int32 'count') cil managed
  {
    .maxstack 8
    ldarg.0
    ldarg.s 1
    ldarg.s 2
    call instance void SrcCursor::.ctor(string 'src', int32 'pos')
    ldarg.0
    ldarg.s 3
    stfld int32 Lexer::'count'
    ret
  }
  .method public hidebysig virtual instance string 'describe'() cil managed
  {
    .maxstack 10
    .locals init (int32 '__strtmp1893922260992', int32 '__strtmp1893922851200', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "lexer@"
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " da doc "
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld int32 Lexer::'count'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " the"
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public hidebysig newslot virtual instance int32 'skip_blanks'() cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt 'skipped', string 'ch', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 0
  skip_blanks_W1_start:
    ldarg.s 0
    callvirt instance int32 Lexer::'at_end'()
    ldc.i4 0
    ceq
    brfalse skip_blanks_W1_end
    ldarg.s 0
    callvirt instance string Lexer::'peek_ch'()
    stloc.s 1
    ldloc.s 1
    call int32 TKVApp::'is_space'(string)
    ldc.i4 1
    ceq
    brfalse skip_blanks_If2_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    ldloc.s 0
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 3
    stloc.s 2
    ldloca.s 2
    ldfld object TkvInt::big
    brtrue skip_blanks_int3_slow
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue skip_blanks_int3_slow
    ldloca.s 2
    ldfld int64 TkvInt::lo
    ldloca.s 3
    ldfld int64 TkvInt::lo
    add
    stloc.s 5
    ldloca.s 2
    ldfld int64 TkvInt::lo
    ldloc.s 5
    xor
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloc.s 5
    xor
    and
    ldc.i8 0
    blt skip_blanks_int3_slow
    ldloca.s 4
    ldloc.s 5
    stfld int64 TkvInt::lo
    ldloca.s 4
    ldnull
    stfld object TkvInt::big
    ldloc.s 4
    br skip_blanks_int3_done
  skip_blanks_int3_slow:
    ldloc.s 2
    ldloc.s 3
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  skip_blanks_int3_done:
    stloc.s 0
    br skip_blanks_If2_end
  skip_blanks_If2_else:
    ldloc.s 1
    ldstr "#"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse skip_blanks_If4_else
  skip_blanks_W5_start:
    ldarg.s 0
    callvirt instance int32 Lexer::'at_end'()
    ldc.i4 0
    ceq
    brfalse skip_blanks_W5_end
    ldarg.s 0
    callvirt instance string Lexer::'peek_ch'()
    ldstr "\n"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse skip_blanks_If6_else
    br skip_blanks_W5_end
  skip_blanks_If6_else:
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    ldloc.s 0
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 3
    stloc.s 2
    ldloca.s 2
    ldfld object TkvInt::big
    brtrue skip_blanks_int7_slow
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue skip_blanks_int7_slow
    ldloca.s 2
    ldfld int64 TkvInt::lo
    ldloca.s 3
    ldfld int64 TkvInt::lo
    add
    stloc.s 5
    ldloca.s 2
    ldfld int64 TkvInt::lo
    ldloc.s 5
    xor
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloc.s 5
    xor
    and
    ldc.i8 0
    blt skip_blanks_int7_slow
    ldloca.s 4
    ldloc.s 5
    stfld int64 TkvInt::lo
    ldloca.s 4
    ldnull
    stfld object TkvInt::big
    ldloc.s 4
    br skip_blanks_int7_done
  skip_blanks_int7_slow:
    ldloc.s 2
    ldloc.s 3
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  skip_blanks_int7_done:
    stloc.s 0
    br skip_blanks_W5_start
  skip_blanks_W5_end:
    br skip_blanks_If4_end
  skip_blanks_If4_else:
    ldloc.s 0
    call int32 TkvInt::ToI32(valuetype TkvInt)
    ret
  skip_blanks_If4_end:
  skip_blanks_If2_end:
    br skip_blanks_W1_start
  skip_blanks_W1_end:
    ldloc.s 0
    call int32 TkvInt::ToI32(valuetype TkvInt)
    ret
  }
  .method public hidebysig newslot virtual instance class Tok 'read_number'() cil managed
  {
    .maxstack 11
    .locals init (int32 'start', string 'digits', valuetype TkvInt 'dots', class [mscorlib]System.Text.StringBuilder '__sb_digits', string 'ch', int32 '__strtmp1893923007488', string 'nxt', int32 '__strtmp1893923008448', int32 '__strtmp1893923008208', int32 '__strtmp1893923007968', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    stloc.s 0
    ldstr ""
    stloc.s 1
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 2
    ldloc.s 1
    newobj instance void [mscorlib]System.Text.StringBuilder::.ctor(string)
    stloc.s 3
  read_number_W1_start:
    ldarg.s 0
    callvirt instance int32 Lexer::'at_end'()
    ldc.i4 0
    ceq
    brfalse read_number_W1_end
    ldarg.s 0
    callvirt instance string Lexer::'peek_ch'()
    stloc.s 4
    ldloc.s 4
    call int32 TKVApp::'is_digit'(string)
    ldc.i4 1
    ceq
    brfalse read_number_If2_else
    ldloc.s 3
    ldloc.s 4
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
    pop
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    br read_number_If2_end
  read_number_If2_else:
    ldloc.s 4
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_number_If3_else
    ldloc.s 2
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    ceq
    brfalse read_number_If4_else
    ldstr "so co 2 dau cham tai cot "
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class LexError::.ctor(string)
    throw
  read_number_If4_else:
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 2
    ldloc.s 3
    ldloc.s 4
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
    pop
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    br read_number_If3_end
  read_number_If3_else:
    br read_number_W1_end
  read_number_If3_end:
  read_number_If2_end:
    br read_number_W1_start
  read_number_W1_end:
    ldloc.s 3
    callvirt instance string [mscorlib]System.Object::ToString()
    stloc.s 1
    ldarg.s 0
    callvirt instance string Lexer::'peek_ch'()
    stloc.s 6
    ldloc.s 6
    ldstr "e"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_number_If5_else
    ldstr "chua ho tro ky hieu khoa hoc tai cot "
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class LexError::.ctor(string)
    throw
  read_number_If5_else:
    ldloc.s 6
    ldstr "E"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_number_If6_else
    ldstr "chua ho tro ky hieu khoa hoc tai cot "
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class LexError::.ctor(string)
    throw
  read_number_If6_else:
    ldloc.s 1
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_number_If7_else
    ldstr "so khong hop le tai cot "
    ldloc.s 0
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class LexError::.ctor(string)
    throw
  read_number_If7_else:
    ldstr "NUM"
    ldloc.s 1
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  }
  .method public hidebysig newslot virtual instance class Tok 'read_name'() cil managed
  {
    .maxstack 11
    .locals init (int32 'start', string 'name', class [mscorlib]System.Text.StringBuilder '__sb_name', string 'ch', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    stloc.s 0
    ldstr ""
    stloc.s 1
    ldloc.s 1
    newobj instance void [mscorlib]System.Text.StringBuilder::.ctor(string)
    stloc.s 2
  read_name_W1_start:
    ldarg.s 0
    callvirt instance int32 Lexer::'at_end'()
    ldc.i4 0
    ceq
    brfalse read_name_W1_end
    ldarg.s 0
    callvirt instance string Lexer::'peek_ch'()
    stloc.s 3
    ldloc.s 3
    call int32 TKVApp::'is_alnum'(string)
    ldc.i4 0
    ceq
    brfalse read_name_If2_else
    br read_name_W1_end
  read_name_If2_else:
    ldloc.s 2
    ldloc.s 3
    callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
    pop
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    br read_name_W1_start
  read_name_W1_end:
    ldloc.s 2
    callvirt instance string [mscorlib]System.Object::ToString()
    stloc.s 1
    ldstr "NAME"
    ldloc.s 1
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  }
  .method public hidebysig newslot virtual instance class Tok 'read_operator'() cil managed
  {
    .maxstack 11
    .locals init (int32 'start', string 'ch', string 'nxt', int32 '__strtmp1893922461296', int32 '__strtmp1893922753328', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    stloc.s 0
    ldarg.s 0
    callvirt instance string Lexer::'advance'()
    stloc.s 1
    ldarg.s 0
    callvirt instance string Lexer::'peek_ch'()
    stloc.s 2
    ldloc.s 1
    ldstr "/"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If1_else
    ldloc.s 2
    ldstr "/"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If2_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    ldstr "OP"
    ldstr "//"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If2_else:
    ldstr "OP"
    ldstr "/"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If1_else:
    ldloc.s 1
    ldstr "<"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If3_else
    ldloc.s 2
    ldstr "="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If4_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    ldstr "OP"
    ldstr "<="
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If4_else:
    ldstr "OP"
    ldstr "<"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If3_else:
    ldloc.s 1
    ldstr ">"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If5_else
    ldloc.s 2
    ldstr "="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If6_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    ldstr "OP"
    ldstr ">="
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If6_else:
    ldstr "OP"
    ldstr ">"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If5_else:
    ldloc.s 1
    ldstr "="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If7_else
    ldloc.s 2
    ldstr "="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If8_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    ldstr "OP"
    ldstr "=="
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If8_else:
    ldstr "ASSIGN"
    ldstr "="
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If7_else:
    ldloc.s 1
    ldstr "!"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If9_else
    ldloc.s 2
    ldstr "="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If10_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    ldstr "OP"
    ldstr "!="
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If10_else:
    ldstr "ky tu '!' don le tai cot "
    ldloc.s 0
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class LexError::.ctor(string)
    throw
  read_operator_If9_else:
    ldloc.s 1
    ldstr "+"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If11_else
    ldstr "OP"
    ldstr "+"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If11_else:
    ldloc.s 1
    ldstr "-"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If12_else
    ldstr "OP"
    ldstr "-"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If12_else:
    ldloc.s 1
    ldstr "*"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If13_else
    ldstr "OP"
    ldstr "*"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If13_else:
    ldloc.s 1
    ldstr "%"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If14_else
    ldstr "OP"
    ldstr "%"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If14_else:
    ldloc.s 1
    ldstr "^"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If15_else
    ldstr "OP"
    ldstr "^"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If15_else:
    ldstr "ky tu la '"
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' tai cot "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class LexError::.ctor(string)
    throw
  }
  .method public hidebysig newslot virtual instance class Tok 'next_tok'() cil managed
  {
    .maxstack 11
    .locals init (int32 'skipped', string 'ch', int32 '__strtmp1893922093264', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance int32 Lexer::'skip_blanks'()
    stloc.s 0
    ldarg.s 0
    callvirt instance int32 Lexer::'at_end'()
    ldc.i4 1
    ceq
    brfalse next_tok_If1_else
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    call class Tok TKVApp::'make_eof'(int32)
    ret
  next_tok_If1_else:
    ldarg.s 0
    ldarg.s 0
    ldfld int32 Lexer::'count'
    ldc.i4 1
    add.ovf
    stfld int32 Lexer::'count'
    ldarg.s 0
    callvirt instance string Lexer::'peek_ch'()
    stloc.s 1
    ldloc.s 1
    call int32 TKVApp::'is_digit'(string)
    ldc.i4 1
    ceq
    brfalse next_tok_If2_else
    ldarg.s 0
    callvirt instance class Tok Lexer::'read_number'()
    ret
  next_tok_If2_else:
    ldloc.s 1
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse next_tok_If3_else
    ldarg.s 0
    ldc.i4 1
    callvirt instance string Lexer::'peek_ch_at'(int32)
    call int32 TKVApp::'is_digit'(string)
    ldc.i4 1
    ceq
    brfalse next_tok_If4_else
    ldarg.s 0
    callvirt instance class Tok Lexer::'read_number'()
    ret
  next_tok_If4_else:
    ldstr "dau cham don le tai cot "
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class LexError::.ctor(string)
    throw
  next_tok_If3_else:
    ldloc.s 1
    call int32 TKVApp::'is_alpha'(string)
    ldc.i4 1
    ceq
    brfalse next_tok_If5_else
    ldarg.s 0
    callvirt instance class Tok Lexer::'read_name'()
    ret
  next_tok_If5_else:
    ldloc.s 1
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse next_tok_If6_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    ldstr "LPAREN"
    ldstr "("
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    sub.ovf
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  next_tok_If6_else:
    ldloc.s 1
    ldstr ")"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse next_tok_If7_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    ldstr "RPAREN"
    ldstr ")"
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    sub.ovf
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  next_tok_If7_else:
    ldloc.s 1
    ldstr ","
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse next_tok_If8_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    ldstr "COMMA"
    ldstr ","
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    sub.ovf
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  next_tok_If8_else:
    ldloc.s 1
    ldstr ";"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse next_tok_If9_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 SrcCursor::'pos'
    ldstr "SEMI"
    ldstr ";"
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    ldc.i4 1
    sub.ovf
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  next_tok_If9_else:
    ldarg.s 0
    callvirt instance class Tok Lexer::'read_operator'()
    ret
  }
}
.class public auto ansi TokCursor extends [mscorlib]System.Object
{
  .field public int32 'pos'
  .method public hidebysig specialname rtspecialname instance void .ctor(int32 'pos') cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.s 1
    stfld int32 TokCursor::'pos'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'at_end'(class [mscorlib]System.Collections.Generic.List`1<class Tok> 'toks') cil managed
  {
    .maxstack 9
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld int32 TokCursor::'pos'
    ldarg.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class Tok>::get_Count()
    clt
    ldc.i4.0
    ceq
    brfalse at_end_If1_else
    ldc.i4 1
    ret
  at_end_If1_else:
    ldc.i4 0
    ret
  }
  .method public hidebysig newslot virtual instance class Tok 'peek'(class [mscorlib]System.Collections.Generic.List`1<class Tok> 'toks') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldarg.s 1
    callvirt instance int32 TokCursor::'at_end'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    ldc.i4 1
    ceq
    brfalse peek_If1_else
    ldarg.s 0
    ldfld int32 TokCursor::'pos'
    call class Tok TKVApp::'make_eof'(int32)
    ret
  peek_If1_else:
    ldarg.s 1
    ldarg.s 0
    ldfld int32 TokCursor::'pos'
    dup
    ldc.i4.0
    bge.s peek_idx_pos_2
    ldarg.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class Tok>::get_Count()
    add
    br.s peek_idx_end_2
  peek_idx_pos_2:
  peek_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class Tok>::get_Item(int32)
    ret
  }
  .method public hidebysig newslot virtual instance class Tok 'take'(class [mscorlib]System.Collections.Generic.List`1<class Tok> 'toks') cil managed
  {
    .maxstack 10
    .locals init (class Tok 't', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldarg.s 1
    callvirt instance class Tok TokCursor::'peek'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    stloc.s 0
    ldarg.s 0
    ldarg.s 0
    ldfld int32 TokCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 TokCursor::'pos'
    ldloc.s 0
    ret
  }
  .method public hidebysig newslot virtual instance int32 'skip'() cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldarg.s 0
    ldfld int32 TokCursor::'pos'
    ldc.i4 1
    add.ovf
    stfld int32 TokCursor::'pos'
    ldarg.s 0
    ldfld int32 TokCursor::'pos'
    ret
  }
}
.class public auto ansi Expr extends [mscorlib]System.Object
{
  .field public string 'kind'
  .field public float64 'num'
  .field public string 'text'
  .field public class Expr 'a'
  .field public class Expr 'b'
  .method public hidebysig specialname rtspecialname instance void .ctor(string 'kind', float64 'num', string 'text', class Expr 'a', class Expr 'b') cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.s 1
    stfld string Expr::'kind'
    ldarg.0
    ldarg.s 2
    stfld float64 Expr::'num'
    ldarg.0
    ldarg.s 3
    stfld string Expr::'text'
    ldarg.0
    ldarg.s 4
    stfld class Expr Expr::'a'
    ldarg.0
    ldarg.s 5
    stfld class Expr Expr::'b'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'is_leaf'() cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld class Expr Expr::'a'
    ldnull
    ceq
    brfalse is_leaf_If1_else
    ldarg.s 0
    ldfld class Expr Expr::'b'
    ldnull
    ceq
    brfalse is_leaf_If2_else
    ldc.i4 1
    ret
  is_leaf_If2_else:
  is_leaf_If1_else:
    ldc.i4 0
    ret
  }
  .method public hidebysig newslot virtual instance int32 'node_count'() cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt 'n', class Expr '__hoist4', class Expr '__hoist5', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 0
    ldarg.s 0
    ldfld class Expr Expr::'a'
    ldnull
    ceq
    ldc.i4.0
    ceq
    brfalse node_count_If1_else
    ldarg.s 0
    ldfld class Expr Expr::'a'
    stloc.s 1
    ldloc.s 0
    ldloc.s 1
    callvirt instance int32 Expr::'node_count'()
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue node_count_int2_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue node_count_int2_slow
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
    blt node_count_int2_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br node_count_int2_done
  node_count_int2_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  node_count_int2_done:
    stloc.s 0
  node_count_If1_else:
    ldarg.s 0
    ldfld class Expr Expr::'b'
    ldnull
    ceq
    ldc.i4.0
    ceq
    brfalse node_count_If3_else
    ldarg.s 0
    ldfld class Expr Expr::'b'
    stloc.s 2
    ldloc.s 0
    ldloc.s 2
    callvirt instance int32 Expr::'node_count'()
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue node_count_int4_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue node_count_int4_slow
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
    blt node_count_int4_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br node_count_int4_done
  node_count_int4_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  node_count_int4_done:
    stloc.s 0
  node_count_If3_else:
    ldloc.s 0
    call int32 TkvInt::ToI32(valuetype TkvInt)
    ret
  }
  .method public hidebysig newslot virtual instance int32 'depth'() cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt 'da', valuetype TkvInt 'db', class Expr '__hoist6', class Expr '__hoist7', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 0
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 1
    ldarg.s 0
    ldfld class Expr Expr::'a'
    ldnull
    ceq
    ldc.i4.0
    ceq
    brfalse depth_If1_else
    ldarg.s 0
    ldfld class Expr Expr::'a'
    stloc.s 2
    ldloc.s 2
    callvirt instance int32 Expr::'depth'()
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 0
  depth_If1_else:
    ldarg.s 0
    ldfld class Expr Expr::'b'
    ldnull
    ceq
    ldc.i4.0
    ceq
    brfalse depth_If2_else
    ldarg.s 0
    ldfld class Expr Expr::'b'
    stloc.s 3
    ldloc.s 3
    callvirt instance int32 Expr::'depth'()
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 1
  depth_If2_else:
    ldloc.s 0
    ldloc.s 1
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    cgt
    brfalse depth_If3_else
    ldloc.s 0
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 5
    stloc.s 4
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue depth_int4_slow
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue depth_int4_slow
    ldloca.s 4
    ldfld int64 TkvInt::lo
    ldloca.s 5
    ldfld int64 TkvInt::lo
    add
    stloc.s 7
    ldloca.s 4
    ldfld int64 TkvInt::lo
    ldloc.s 7
    xor
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 7
    xor
    and
    ldc.i8 0
    blt depth_int4_slow
    ldloca.s 6
    ldloc.s 7
    stfld int64 TkvInt::lo
    ldloca.s 6
    ldnull
    stfld object TkvInt::big
    ldloc.s 6
    br depth_int4_done
  depth_int4_slow:
    ldloc.s 4
    ldloc.s 5
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  depth_int4_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    ret
  depth_If3_else:
    ldloc.s 1
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 5
    stloc.s 4
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue depth_int5_slow
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue depth_int5_slow
    ldloca.s 4
    ldfld int64 TkvInt::lo
    ldloca.s 5
    ldfld int64 TkvInt::lo
    add
    stloc.s 7
    ldloca.s 4
    ldfld int64 TkvInt::lo
    ldloc.s 7
    xor
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 7
    xor
    and
    ldc.i8 0
    blt depth_int5_slow
    ldloca.s 6
    ldloc.s 7
    stfld int64 TkvInt::lo
    ldloca.s 6
    ldnull
    stfld object TkvInt::big
    ldloc.s 6
    br depth_int5_done
  depth_int5_slow:
    ldloc.s 4
    ldloc.s 5
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  depth_int5_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    ret
  }
  .method public hidebysig newslot virtual instance string 'render'() cil managed
  {
    .maxstack 10
    .locals init (class Expr '__hoist8', class Expr '__hoist9', class Expr '__hoist10', class Expr '__hoist12', class Expr '__hoist11', class Expr '__hoist13', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld string Expr::'kind'
    ldstr "num"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse render_If1_else
    ldarg.s 0
    ldfld float64 Expr::'num'
    call string TKVApp::'fmt_value'(float64)
    ret
  render_If1_else:
    ldarg.s 0
    ldfld string Expr::'kind'
    ldstr "var"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse render_If2_else
    ldarg.s 0
    ldfld string Expr::'text'
    ret
  render_If2_else:
    ldarg.s 0
    ldfld string Expr::'kind'
    ldstr "un"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse render_If3_else
    ldarg.s 0
    ldfld class Expr Expr::'a'
    stloc.s 0
    ldstr "("
    ldarg.s 0
    ldfld string Expr::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    callvirt instance string Expr::'render'()
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ")"
    call string [mscorlib]System.String::Concat(string, string)
    ret
  render_If3_else:
    ldarg.s 0
    ldfld string Expr::'kind'
    ldstr "call1"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse render_If4_else
    ldarg.s 0
    ldfld class Expr Expr::'a'
    stloc.s 1
    ldstr "("
    ldarg.s 0
    ldfld string Expr::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    callvirt instance string Expr::'render'()
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ")"
    call string [mscorlib]System.String::Concat(string, string)
    ret
  render_If4_else:
    ldarg.s 0
    ldfld string Expr::'kind'
    ldstr "call2"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse render_If5_else
    ldarg.s 0
    ldfld class Expr Expr::'a'
    stloc.s 2
    ldarg.s 0
    ldfld class Expr Expr::'b'
    stloc.s 3
    ldstr "("
    ldarg.s 0
    ldfld string Expr::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 2
    callvirt instance string Expr::'render'()
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 3
    callvirt instance string Expr::'render'()
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ")"
    call string [mscorlib]System.String::Concat(string, string)
    ret
  render_If5_else:
    ldarg.s 0
    ldfld class Expr Expr::'a'
    stloc.s 4
    ldarg.s 0
    ldfld class Expr Expr::'b'
    stloc.s 5
    ldstr "("
    ldarg.s 0
    ldfld string Expr::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 4
    callvirt instance string Expr::'render'()
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 5
    callvirt instance string Expr::'render'()
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ")"
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public hidebysig newslot virtual instance float64 'eval_with'(class [mscorlib]System.Collections.Generic.List`1<string> 'names', class [mscorlib]System.Collections.Generic.List`1<float64> 'vals') cil managed
  {
    .maxstack 11
    .locals init (int32 'i', class Expr '__hoist14', float64 'av', class Expr '__hoist15', class Expr '__hoist16', class Expr '__hoist17', float64 'bv', class Expr '__hoist18', class Expr '__hoist19', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld string Expr::'kind'
    ldstr "num"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse eval_with_If1_else
    ldarg.s 0
    ldfld float64 Expr::'num'
    ret
  eval_with_If1_else:
    ldarg.s 0
    ldfld string Expr::'kind'
    ldstr "var"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse eval_with_If2_else
    ldc.i4.0
    stloc.s 0
  eval_with_L3_start:
    ldloc.s 0
    ldarg.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge eval_with_L3_end
    ldarg.s 1
    ldloc.s 0
    dup
    ldc.i4.0
    bge.s eval_with_idx_pos_5
    ldarg.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s eval_with_idx_end_5
  eval_with_idx_pos_5:
  eval_with_idx_end_5:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldarg.s 0
    ldfld string Expr::'text'
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse eval_with_If4_else
    ldarg.s 2
    ldloc.s 0
    dup
    ldc.i4.0
    bge.s eval_with_idx_pos_6
    ldarg.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Count()
    add
    br.s eval_with_idx_end_6
  eval_with_idx_pos_6:
  eval_with_idx_end_6:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Item(int32)
    ret
  eval_with_If4_else:
  eval_with_L3_cont:
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    br eval_with_L3_start
  eval_with_L3_end:
    ldstr "bien '"
    ldarg.s 0
    ldfld string Expr::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' chua duoc dat"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class EvalError::.ctor(string)
    throw
  eval_with_If2_else:
    ldarg.s 0
    ldfld string Expr::'kind'
    ldstr "un"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse eval_with_If7_else
    ldarg.s 0
    ldfld class Expr Expr::'a'
    stloc.s 1
    ldloc.s 1
    ldarg.s 1
    ldarg.s 2
    callvirt instance float64 Expr::'eval_with'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<float64>)
    stloc.s 2
    ldarg.s 0
    ldfld string Expr::'text'
    ldloc.s 2
    call float64 TKVApp::'apply_unary'(string, float64)
    ret
  eval_with_If7_else:
    ldarg.s 0
    ldfld string Expr::'kind'
    ldstr "call1"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse eval_with_If8_else
    ldarg.s 0
    ldfld class Expr Expr::'a'
    stloc.s 3
    ldloc.s 3
    ldarg.s 1
    ldarg.s 2
    callvirt instance float64 Expr::'eval_with'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<float64>)
    stloc.s 2
    ldarg.s 0
    ldfld string Expr::'text'
    ldloc.s 2
    call float64 TKVApp::'apply_func1'(string, float64)
    ret
  eval_with_If8_else:
    ldarg.s 0
    ldfld string Expr::'kind'
    ldstr "call2"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse eval_with_If9_else
    ldarg.s 0
    ldfld class Expr Expr::'a'
    stloc.s 4
    ldloc.s 4
    ldarg.s 1
    ldarg.s 2
    callvirt instance float64 Expr::'eval_with'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<float64>)
    stloc.s 2
    ldarg.s 0
    ldfld class Expr Expr::'b'
    stloc.s 5
    ldloc.s 5
    ldarg.s 1
    ldarg.s 2
    callvirt instance float64 Expr::'eval_with'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<float64>)
    stloc.s 6
    ldarg.s 0
    ldfld string Expr::'text'
    ldloc.s 2
    ldloc.s 6
    call float64 TKVApp::'apply_func2'(string, float64, float64)
    ret
  eval_with_If9_else:
    ldarg.s 0
    ldfld class Expr Expr::'a'
    stloc.s 7
    ldloc.s 7
    ldarg.s 1
    ldarg.s 2
    callvirt instance float64 Expr::'eval_with'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<float64>)
    stloc.s 2
    ldarg.s 0
    ldfld class Expr Expr::'b'
    stloc.s 8
    ldloc.s 8
    ldarg.s 1
    ldarg.s 2
    callvirt instance float64 Expr::'eval_with'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<float64>)
    stloc.s 6
    ldarg.s 0
    ldfld string Expr::'text'
    ldloc.s 2
    ldloc.s 6
    call float64 TKVApp::'apply_binary'(string, float64, float64)
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
  .method public static class Tok 'make_eof'(int32 'pos') cil managed
  {
    .maxstack 11
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "EOF"
    ldstr ""
    ldarg.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  }
  .method public static int32 'is_space'(string 'ch') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldstr " "
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_space_If1_else
    ldc.i4 1
    ret
  is_space_If1_else:
    ldarg.s 0
    ldstr "\t"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_space_If2_else
    ldc.i4 1
    ret
  is_space_If2_else:
    ldarg.s 0
    ldstr "\n"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_space_If3_else
    ldc.i4 1
    ret
  is_space_If3_else:
    ldarg.s 0
    ldstr "\r"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_space_If4_else
    ldc.i4 1
    ret
  is_space_If4_else:
    ldc.i4 0
    ret
  }
  .method public static int32 'is_digit'(string 'ch') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 1
    ceq
    ldc.i4.0
    ceq
    brfalse is_digit_If1_else
    ldc.i4 0
    ret
  is_digit_If1_else:
    ldarg.s 0
    ldstr "0"
    call int32 [mscorlib]System.String::CompareOrdinal(string, string)
    ldc.i4.0
    clt
    ldc.i4.0
    ceq
    brfalse is_digit_If2_else
    ldarg.s 0
    ldstr "9"
    call int32 [mscorlib]System.String::CompareOrdinal(string, string)
    ldc.i4.0
    cgt
    ldc.i4.0
    ceq
    brfalse is_digit_If3_else
    ldc.i4 1
    ret
  is_digit_If3_else:
  is_digit_If2_else:
    ldc.i4 0
    ret
  }
  .method public static int32 'is_alpha'(string 'ch') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 1
    ceq
    ldc.i4.0
    ceq
    brfalse is_alpha_If1_else
    ldc.i4 0
    ret
  is_alpha_If1_else:
    ldarg.s 0
    ldstr "_"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_alpha_If2_else
    ldc.i4 1
    ret
  is_alpha_If2_else:
    ldarg.s 0
    ldstr "a"
    call int32 [mscorlib]System.String::CompareOrdinal(string, string)
    ldc.i4.0
    clt
    ldc.i4.0
    ceq
    brfalse is_alpha_If3_else
    ldarg.s 0
    ldstr "z"
    call int32 [mscorlib]System.String::CompareOrdinal(string, string)
    ldc.i4.0
    cgt
    ldc.i4.0
    ceq
    brfalse is_alpha_If4_else
    ldc.i4 1
    ret
  is_alpha_If4_else:
  is_alpha_If3_else:
    ldarg.s 0
    ldstr "A"
    call int32 [mscorlib]System.String::CompareOrdinal(string, string)
    ldc.i4.0
    clt
    ldc.i4.0
    ceq
    brfalse is_alpha_If5_else
    ldarg.s 0
    ldstr "Z"
    call int32 [mscorlib]System.String::CompareOrdinal(string, string)
    ldc.i4.0
    cgt
    ldc.i4.0
    ceq
    brfalse is_alpha_If6_else
    ldc.i4 1
    ret
  is_alpha_If6_else:
  is_alpha_If5_else:
    ldc.i4 0
    ret
  }
  .method public static int32 'is_alnum'(string 'ch') cil managed
  {
    .maxstack 9
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    call int32 TKVApp::'is_alpha'(string)
    ldc.i4 1
    ceq
    brfalse is_alnum_If1_else
    ldc.i4 1
    ret
  is_alnum_If1_else:
    ldarg.s 0
    call int32 TKVApp::'is_digit'(string)
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<class Tok> 'tokenize'(string 'src') cil managed
  {
    .maxstack 11
    .locals init (class Lexer 'lx', class [mscorlib]System.Collections.Generic.List`1<class Tok> 'toks', valuetype TkvInt 'guard', class Tok 't', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldc.i4 0
    ldc.i4 0
    newobj instance void Lexer::.ctor(string, int32, int32)
    stloc.s 0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<class Tok>::.ctor()
    stloc.s 1
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 2
  tokenize_W1_start:
    ldloc.s 0
    callvirt instance int32 Lexer::'at_end'()
    ldc.i4 0
    ceq
    brfalse tokenize_W1_end
    ldloc.s 0
    callvirt instance class Tok Lexer::'next_tok'()
    stloc.s 3
    ldloc.s 3
    ldfld string Tok::'kind'
    ldstr "EOF"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse tokenize_If2_else
    br tokenize_W1_end
  tokenize_If2_else:
    ldloc.s 1
    ldloc.s 3
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class Tok>::Add(!0)
    ldloc.s 2
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 5
    stloc.s 4
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue tokenize_int3_slow
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue tokenize_int3_slow
    ldloca.s 4
    ldfld int64 TkvInt::lo
    ldloca.s 5
    ldfld int64 TkvInt::lo
    add
    stloc.s 7
    ldloca.s 4
    ldfld int64 TkvInt::lo
    ldloc.s 7
    xor
    ldloca.s 5
    ldfld int64 TkvInt::lo
    ldloc.s 7
    xor
    and
    ldc.i8 0
    blt tokenize_int3_slow
    ldloca.s 6
    ldloc.s 7
    stfld int64 TkvInt::lo
    ldloca.s 6
    ldnull
    stfld object TkvInt::big
    ldloc.s 6
    br tokenize_int3_done
  tokenize_int3_slow:
    ldloc.s 4
    ldloc.s 5
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  tokenize_int3_done:
    stloc.s 2
    ldloc.s 2
    ldc.i8 4096
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    cgt
    brfalse tokenize_If4_else
    ldstr "bieu thuc qua dai"
    newobj instance void class LexError::.ctor(string)
    throw
  tokenize_If4_else:
    br tokenize_W1_start
  tokenize_W1_end:
    ldloc.s 1
    ret
  }
  .method public static int32 'func_arity'(string 'name') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldstr "abs"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse func_arity_If1_else
    ldc.i4 1
    ret
  func_arity_If1_else:
    ldarg.s 0
    ldstr "sqrt"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse func_arity_If2_else
    ldc.i4 1
    ret
  func_arity_If2_else:
    ldarg.s 0
    ldstr "floor"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse func_arity_If3_else
    ldc.i4 1
    ret
  func_arity_If3_else:
    ldarg.s 0
    ldstr "ceil"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse func_arity_If4_else
    ldc.i4 1
    ret
  func_arity_If4_else:
    ldarg.s 0
    ldstr "round"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse func_arity_If5_else
    ldc.i4 1
    ret
  func_arity_If5_else:
    ldarg.s 0
    ldstr "sign"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse func_arity_If6_else
    ldc.i4 1
    ret
  func_arity_If6_else:
    ldarg.s 0
    ldstr "min"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse func_arity_If7_else
    ldc.i4 2
    ret
  func_arity_If7_else:
    ldarg.s 0
    ldstr "max"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse func_arity_If8_else
    ldc.i4 2
    ret
  func_arity_If8_else:
    ldarg.s 0
    ldstr "pow"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse func_arity_If9_else
    ldc.i4 2
    ret
  func_arity_If9_else:
    ldarg.s 0
    ldstr "hypot"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse func_arity_If10_else
    ldc.i4 2
    ret
  func_arity_If10_else:
    ldc.i4 0
    ret
  }
  .method public static int32 'is_int_value'(float64 'v') cil managed
  {
    .maxstack 9
    .locals init (int32 'r', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    call float64 [mscorlib]System.Math::Round(float64)
    conv.i4
    stloc.s 0
    ldarg.s 0
    ldloc.s 0
    conv.r8
    ceq
    brfalse is_int_value_If1_else
    ldc.i4 1
    ret
  is_int_value_If1_else:
    ldc.i4 0
    ret
  }
  .method public static float64 'floor_div'(float64 'a', float64 'b') cil managed
  {
    .maxstack 9
    .locals init (float64 'q', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 1
    ldc.r8 0.0
    ceq
    brfalse floor_div_If1_else
    ldstr "chia cho 0"
    newobj instance void class EvalError::.ctor(string)
    throw
  floor_div_If1_else:
    ldarg.s 0
    ldarg.s 1
    div
    stloc.s 0
    ldloc.s 0
    conv.r8
    call float64 [mscorlib]System.Math::Floor(float64)
    ret
  }
  .method public static float64 'float_mod'(float64 'a', float64 'b') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 1
    ldc.r8 0.0
    ceq
    brfalse float_mod_If1_else
    ldstr "chia cho 0"
    newobj instance void class EvalError::.ctor(string)
    throw
  float_mod_If1_else:
    ldarg.s 0
    ldarg.s 0
    ldarg.s 1
    call float64 TKVApp::'floor_div'(float64, float64)
    ldarg.s 1
    mul
    sub
    ret
  }
  .method public static float64 'apply_binary'(string 'sym', float64 'a', float64 'b') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldstr "+"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_binary_If1_else
    ldarg.s 1
    ldarg.s 2
    add
    ret
  apply_binary_If1_else:
    ldarg.s 0
    ldstr "-"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_binary_If2_else
    ldarg.s 1
    ldarg.s 2
    sub
    ret
  apply_binary_If2_else:
    ldarg.s 0
    ldstr "*"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_binary_If3_else
    ldarg.s 1
    ldarg.s 2
    mul
    ret
  apply_binary_If3_else:
    ldarg.s 0
    ldstr "/"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_binary_If4_else
    ldarg.s 2
    ldc.r8 0.0
    ceq
    brfalse apply_binary_If5_else
    ldstr "chia cho 0"
    newobj instance void class EvalError::.ctor(string)
    throw
  apply_binary_If5_else:
    ldarg.s 1
    ldarg.s 2
    div
    ret
  apply_binary_If4_else:
    ldarg.s 0
    ldstr "//"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_binary_If6_else
    ldarg.s 1
    ldarg.s 2
    call float64 TKVApp::'floor_div'(float64, float64)
    ret
  apply_binary_If6_else:
    ldarg.s 0
    ldstr "%"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_binary_If7_else
    ldarg.s 1
    ldarg.s 2
    call float64 TKVApp::'float_mod'(float64, float64)
    ret
  apply_binary_If7_else:
    ldarg.s 0
    ldstr "^"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_binary_If8_else
    ldarg.s 1
    conv.r8
    ldarg.s 2
    conv.r8
    call float64 [mscorlib]System.Math::Pow(float64, float64)
    ret
  apply_binary_If8_else:
    ldarg.s 0
    ldstr "<"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_binary_If9_else
    ldarg.s 1
    ldarg.s 2
    clt
    brfalse apply_binary_If10_else
    ldc.r8 1.0
    ret
  apply_binary_If10_else:
    ldc.r8 0.0
    ret
  apply_binary_If9_else:
    ldarg.s 0
    ldstr "<="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_binary_If11_else
    ldarg.s 1
    ldarg.s 2
    cgt
    ldc.i4.0
    ceq
    brfalse apply_binary_If12_else
    ldc.r8 1.0
    ret
  apply_binary_If12_else:
    ldc.r8 0.0
    ret
  apply_binary_If11_else:
    ldarg.s 0
    ldstr ">"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_binary_If13_else
    ldarg.s 1
    ldarg.s 2
    cgt
    brfalse apply_binary_If14_else
    ldc.r8 1.0
    ret
  apply_binary_If14_else:
    ldc.r8 0.0
    ret
  apply_binary_If13_else:
    ldarg.s 0
    ldstr ">="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_binary_If15_else
    ldarg.s 1
    ldarg.s 2
    clt
    ldc.i4.0
    ceq
    brfalse apply_binary_If16_else
    ldc.r8 1.0
    ret
  apply_binary_If16_else:
    ldc.r8 0.0
    ret
  apply_binary_If15_else:
    ldarg.s 0
    ldstr "=="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_binary_If17_else
    ldarg.s 1
    ldarg.s 2
    ceq
    brfalse apply_binary_If18_else
    ldc.r8 1.0
    ret
  apply_binary_If18_else:
    ldc.r8 0.0
    ret
  apply_binary_If17_else:
    ldarg.s 0
    ldstr "!="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_binary_If19_else
    ldarg.s 1
    ldarg.s 2
    ceq
    ldc.i4.0
    ceq
    brfalse apply_binary_If20_else
    ldc.r8 1.0
    ret
  apply_binary_If20_else:
    ldc.r8 0.0
    ret
  apply_binary_If19_else:
    ldstr "toan tu 2 ngoi la '"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "'"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class EvalError::.ctor(string)
    throw
  }
  .method public static float64 'apply_unary'(string 'sym', float64 'a') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldstr "u-"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_unary_If1_else
    ldc.r8 0.0
    ldarg.s 1
    sub
    ret
  apply_unary_If1_else:
    ldarg.s 0
    ldstr "u+"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_unary_If2_else
    ldarg.s 1
    ret
  apply_unary_If2_else:
    ldstr "toan tu 1 ngoi la '"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "'"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class EvalError::.ctor(string)
    throw
  }
  .method public static float64 'apply_func1'(string 'name', float64 'a') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldstr "abs"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_func1_If1_else
    ldarg.s 1
    ldc.r8 0.0
    clt
    brfalse apply_func1_If2_else
    ldc.r8 0.0
    ldarg.s 1
    sub
    ret
  apply_func1_If2_else:
    ldarg.s 1
    ret
  apply_func1_If1_else:
    ldarg.s 0
    ldstr "sqrt"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_func1_If3_else
    ldarg.s 1
    ldc.r8 0.0
    clt
    brfalse apply_func1_If4_else
    ldstr "sqrt cua so am"
    newobj instance void class EvalError::.ctor(string)
    throw
  apply_func1_If4_else:
    ldarg.s 1
    conv.r8
    call float64 [mscorlib]System.Math::Sqrt(float64)
    ret
  apply_func1_If3_else:
    ldarg.s 0
    ldstr "floor"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_func1_If5_else
    ldarg.s 1
    conv.r8
    call float64 [mscorlib]System.Math::Floor(float64)
    ret
  apply_func1_If5_else:
    ldarg.s 0
    ldstr "ceil"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_func1_If6_else
    ldarg.s 1
    conv.r8
    call float64 [mscorlib]System.Math::Ceiling(float64)
    ret
  apply_func1_If6_else:
    ldarg.s 0
    ldstr "round"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_func1_If7_else
    ldarg.s 1
    call float64 [mscorlib]System.Math::Round(float64)
    ret
  apply_func1_If7_else:
    ldarg.s 0
    ldstr "sign"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_func1_If8_else
    ldarg.s 1
    ldc.r8 0.0
    cgt
    brfalse apply_func1_If9_else
    ldc.r8 1.0
    ret
  apply_func1_If9_else:
    ldarg.s 1
    ldc.r8 0.0
    clt
    brfalse apply_func1_If10_else
    ldc.r8 0.0
    ldc.r8 1.0
    sub
    ret
  apply_func1_If10_else:
    ldc.r8 0.0
    ret
  apply_func1_If8_else:
    ldstr "ham 1 tham so la '"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "'"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class EvalError::.ctor(string)
    throw
  }
  .method public static float64 'apply_func2'(string 'name', float64 'a', float64 'b') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldstr "min"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_func2_If1_else
    ldarg.s 1
    ldarg.s 2
    clt
    brfalse apply_func2_If2_else
    ldarg.s 1
    ret
  apply_func2_If2_else:
    ldarg.s 2
    ret
  apply_func2_If1_else:
    ldarg.s 0
    ldstr "max"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_func2_If3_else
    ldarg.s 1
    ldarg.s 2
    cgt
    brfalse apply_func2_If4_else
    ldarg.s 1
    ret
  apply_func2_If4_else:
    ldarg.s 2
    ret
  apply_func2_If3_else:
    ldarg.s 0
    ldstr "pow"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_func2_If5_else
    ldarg.s 1
    conv.r8
    ldarg.s 2
    conv.r8
    call float64 [mscorlib]System.Math::Pow(float64, float64)
    ret
  apply_func2_If5_else:
    ldarg.s 0
    ldstr "hypot"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse apply_func2_If6_else
    ldarg.s 1
    ldarg.s 1
    mul
    ldarg.s 2
    ldarg.s 2
    mul
    add
    conv.r8
    call float64 [mscorlib]System.Math::Sqrt(float64)
    ret
  apply_func2_If6_else:
    ldstr "ham 2 tham so la '"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "'"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class EvalError::.ctor(string)
    throw
  }
  .method public static string 'fmt_value'(float64 'v') cil managed
  {
    .maxstack 9
    .locals init (int32 'r', int32 '__strtmp1893922209472', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    call int32 TKVApp::'is_int_value'(float64)
    ldc.i4 1
    ceq
    brfalse fmt_value_If1_else
    ldarg.s 0
    call float64 [mscorlib]System.Math::Round(float64)
    conv.i4
    stloc.s 0
    ldloc.s 0
    call string TkvStr::I32(int32)
    ret
  fmt_value_If1_else:
    ldarg.s 0
    call string TkvStr::F64(float64)
    ret
  }
  .method public static string 'fmt_pair'(string 'name', float64 'v') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldstr "="
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string TKVApp::'fmt_value'(float64)
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static class Expr 'num_node'(float64 'v') cil managed
  {
    .maxstack 13
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "num"
    ldarg.s 0
    ldstr ""
    ldnull
    ldnull
    newobj instance void Expr::.ctor(string, float64, string, class Expr, class Expr)
    ret
  }
  .method public static class Expr 'var_node'(string 'name') cil managed
  {
    .maxstack 13
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "var"
    ldc.r8 0.0
    ldarg.s 0
    ldnull
    ldnull
    newobj instance void Expr::.ctor(string, float64, string, class Expr, class Expr)
    ret
  }
  .method public static class Expr 'bin_node'(string 'sym', class Expr 'a', class Expr 'b') cil managed
  {
    .maxstack 13
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "bin"
    ldc.r8 0.0
    ldarg.s 0
    ldarg.s 1
    ldarg.s 2
    newobj instance void Expr::.ctor(string, float64, string, class Expr, class Expr)
    ret
  }
  .method public static class Expr 'un_node'(string 'sym', class Expr 'a') cil managed
  {
    .maxstack 13
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "un"
    ldc.r8 0.0
    ldarg.s 0
    ldarg.s 1
    ldnull
    newobj instance void Expr::.ctor(string, float64, string, class Expr, class Expr)
    ret
  }
  .method public static int32 'bin_prec'(string 'sym') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldstr "=="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bin_prec_If1_else
    ldc.i4 1
    ret
  bin_prec_If1_else:
    ldarg.s 0
    ldstr "!="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bin_prec_If2_else
    ldc.i4 1
    ret
  bin_prec_If2_else:
    ldarg.s 0
    ldstr "<"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bin_prec_If3_else
    ldc.i4 2
    ret
  bin_prec_If3_else:
    ldarg.s 0
    ldstr "<="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bin_prec_If4_else
    ldc.i4 2
    ret
  bin_prec_If4_else:
    ldarg.s 0
    ldstr ">"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bin_prec_If5_else
    ldc.i4 2
    ret
  bin_prec_If5_else:
    ldarg.s 0
    ldstr ">="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bin_prec_If6_else
    ldc.i4 2
    ret
  bin_prec_If6_else:
    ldarg.s 0
    ldstr "+"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bin_prec_If7_else
    ldc.i4 3
    ret
  bin_prec_If7_else:
    ldarg.s 0
    ldstr "-"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bin_prec_If8_else
    ldc.i4 3
    ret
  bin_prec_If8_else:
    ldarg.s 0
    ldstr "*"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bin_prec_If9_else
    ldc.i4 4
    ret
  bin_prec_If9_else:
    ldarg.s 0
    ldstr "/"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bin_prec_If10_else
    ldc.i4 4
    ret
  bin_prec_If10_else:
    ldarg.s 0
    ldstr "//"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bin_prec_If11_else
    ldc.i4 4
    ret
  bin_prec_If11_else:
    ldarg.s 0
    ldstr "%"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bin_prec_If12_else
    ldc.i4 4
    ret
  bin_prec_If12_else:
    ldarg.s 0
    ldstr "^"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bin_prec_If13_else
    ldc.i4 7
    ret
  bin_prec_If13_else:
    ldc.i4 0
    ret
  }
  .method public static int32 'is_right_assoc'(string 'sym') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldstr "^"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_right_assoc_If1_else
    ldc.i4 1
    ret
  is_right_assoc_If1_else:
    ldc.i4 0
    ret
  }
  .method public static class Expr 'parse_primary'(class [mscorlib]System.Collections.Generic.List`1<class Tok> 'toks', class TokCursor 'cur') cil managed
  {
    .maxstack 13
    .locals init (class Tok 't', int32 '__strtmp1893922460736', class Expr 'inner', class Tok 'closing', int32 'arity', class Tok 'opening', int32 '__strtmp1893922459616', class Expr 'first', class Tok 'comma', class Expr 'second', int32 '__strtmp1893922093344', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 1
    ldarg.s 0
    callvirt instance class Tok TokCursor::'take'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    stloc.s 0
    ldloc.s 0
    ldfld string Tok::'kind'
    ldstr "NUM"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse parse_primary_If1_else
    ldloc.s 0
    ldfld string Tok::'text'
    call float64 TkvStr::ParseF64(string)
    call class Expr TKVApp::'num_node'(float64)
    ret
  parse_primary_If1_else:
    ldloc.s 0
    ldfld string Tok::'kind'
    ldstr "OP"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse parse_primary_If2_else
    ldloc.s 0
    ldfld string Tok::'text'
    ldstr "-"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse parse_primary_If3_else
    ldstr "u-"
    ldarg.s 0
    ldarg.s 1
    ldc.i4 7
    call class Expr TKVApp::'parse_binary'(class [mscorlib]System.Collections.Generic.List`1<class Tok>, class TokCursor, int32)
    call class Expr TKVApp::'un_node'(string, class Expr)
    ret
  parse_primary_If3_else:
    ldloc.s 0
    ldfld string Tok::'text'
    ldstr "+"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse parse_primary_If4_else
    ldarg.s 0
    ldarg.s 1
    ldc.i4 7
    call class Expr TKVApp::'parse_binary'(class [mscorlib]System.Collections.Generic.List`1<class Tok>, class TokCursor, int32)
    ret
  parse_primary_If4_else:
    ldstr "thieu toan hang truoc '"
    ldloc.s 0
    ldfld string Tok::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' tai cot "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    ldfld int32 Tok::'pos'
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class ParseError::.ctor(string)
    throw
  parse_primary_If2_else:
    ldloc.s 0
    ldfld string Tok::'kind'
    ldstr "LPAREN"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse parse_primary_If5_else
    ldarg.s 0
    ldarg.s 1
    ldc.i4 1
    call class Expr TKVApp::'parse_binary'(class [mscorlib]System.Collections.Generic.List`1<class Tok>, class TokCursor, int32)
    stloc.s 2
    ldarg.s 1
    ldarg.s 0
    callvirt instance class Tok TokCursor::'take'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    stloc.s 3
    ldloc.s 3
    ldfld string Tok::'kind'
    ldstr "RPAREN"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse parse_primary_If6_else
    ldstr "thieu dau ')'"
    newobj instance void class ParseError::.ctor(string)
    throw
  parse_primary_If6_else:
    ldloc.s 2
    ret
  parse_primary_If5_else:
    ldloc.s 0
    ldfld string Tok::'kind'
    ldstr "NAME"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse parse_primary_If7_else
    ldloc.s 0
    ldfld string Tok::'text'
    call int32 TKVApp::'func_arity'(string)
    stloc.s 4
    ldloc.s 4
    ldc.i4 0
    ceq
    brfalse parse_primary_If8_else
    ldloc.s 0
    ldfld string Tok::'text'
    call class Expr TKVApp::'var_node'(string)
    ret
  parse_primary_If8_else:
    ldarg.s 1
    ldarg.s 0
    callvirt instance class Tok TokCursor::'take'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    stloc.s 5
    ldloc.s 5
    ldfld string Tok::'kind'
    ldstr "LPAREN"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse parse_primary_If9_else
    ldstr "ham '"
    ldloc.s 0
    ldfld string Tok::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' can dau '(' tai cot "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    ldfld int32 Tok::'pos'
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class ParseError::.ctor(string)
    throw
  parse_primary_If9_else:
    ldarg.s 0
    ldarg.s 1
    ldc.i4 1
    call class Expr TKVApp::'parse_binary'(class [mscorlib]System.Collections.Generic.List`1<class Tok>, class TokCursor, int32)
    stloc.s 7
    ldloc.s 4
    ldc.i4 1
    ceq
    brfalse parse_primary_If10_else
    ldarg.s 1
    ldarg.s 0
    callvirt instance class Tok TokCursor::'take'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    stloc.s 3
    ldloc.s 3
    ldfld string Tok::'kind'
    ldstr "RPAREN"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse parse_primary_If11_else
    ldstr "ham '"
    ldloc.s 0
    ldfld string Tok::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' can dung 1 tham so"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class ParseError::.ctor(string)
    throw
  parse_primary_If11_else:
    ldstr "call1"
    ldc.r8 0.0
    ldloc.s 0
    ldfld string Tok::'text'
    ldloc.s 7
    ldnull
    newobj instance void Expr::.ctor(string, float64, string, class Expr, class Expr)
    ret
  parse_primary_If10_else:
    ldarg.s 1
    ldarg.s 0
    callvirt instance class Tok TokCursor::'take'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    stloc.s 8
    ldloc.s 8
    ldfld string Tok::'kind'
    ldstr "COMMA"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse parse_primary_If12_else
    ldstr "ham '"
    ldloc.s 0
    ldfld string Tok::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' can dung 2 tham so"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class ParseError::.ctor(string)
    throw
  parse_primary_If12_else:
    ldarg.s 0
    ldarg.s 1
    ldc.i4 1
    call class Expr TKVApp::'parse_binary'(class [mscorlib]System.Collections.Generic.List`1<class Tok>, class TokCursor, int32)
    stloc.s 9
    ldarg.s 1
    ldarg.s 0
    callvirt instance class Tok TokCursor::'take'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    stloc.s 3
    ldloc.s 3
    ldfld string Tok::'kind'
    ldstr "RPAREN"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse parse_primary_If13_else
    ldstr "ham '"
    ldloc.s 0
    ldfld string Tok::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' can dung 2 tham so"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class ParseError::.ctor(string)
    throw
  parse_primary_If13_else:
    ldstr "call2"
    ldc.r8 0.0
    ldloc.s 0
    ldfld string Tok::'text'
    ldloc.s 7
    ldloc.s 9
    newobj instance void Expr::.ctor(string, float64, string, class Expr, class Expr)
    ret
  parse_primary_If7_else:
    ldloc.s 0
    ldfld string Tok::'kind'
    ldstr "EOF"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse parse_primary_If14_else
    ldstr "bieu thuc rong"
    newobj instance void class ParseError::.ctor(string)
    throw
  parse_primary_If14_else:
    ldstr "the la '"
    ldloc.s 0
    ldfld string Tok::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' tai cot "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    ldfld int32 Tok::'pos'
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class ParseError::.ctor(string)
    throw
  }
  .method public static class Expr 'parse_binary'(class [mscorlib]System.Collections.Generic.List`1<class Tok> 'toks', class TokCursor 'cur', int32 'min_prec') cil managed
  {
    .maxstack 11
    .locals init (class Expr 'left', valuetype TkvInt 'guard', class Tok 't', int32 'prec', int32 'next_min', class Expr 'right', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldarg.s 1
    call class Expr TKVApp::'parse_primary'(class [mscorlib]System.Collections.Generic.List`1<class Tok>, class TokCursor)
    stloc.s 0
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 1
  parse_binary_W1_start:
    ldarg.s 1
    ldarg.s 0
    callvirt instance int32 TokCursor::'at_end'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    ldc.i4 0
    ceq
    brfalse parse_binary_W1_end
    ldloc.s 1
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 7
    stloc.s 6
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue parse_binary_int2_slow
    ldloca.s 7
    ldfld object TkvInt::big
    brtrue parse_binary_int2_slow
    ldloca.s 6
    ldfld int64 TkvInt::lo
    ldloca.s 7
    ldfld int64 TkvInt::lo
    add
    stloc.s 9
    ldloca.s 6
    ldfld int64 TkvInt::lo
    ldloc.s 9
    xor
    ldloca.s 7
    ldfld int64 TkvInt::lo
    ldloc.s 9
    xor
    and
    ldc.i8 0
    blt parse_binary_int2_slow
    ldloca.s 8
    ldloc.s 9
    stfld int64 TkvInt::lo
    ldloca.s 8
    ldnull
    stfld object TkvInt::big
    ldloc.s 8
    br parse_binary_int2_done
  parse_binary_int2_slow:
    ldloc.s 6
    ldloc.s 7
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  parse_binary_int2_done:
    stloc.s 1
    ldloc.s 1
    ldc.i8 4096
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    cgt
    brfalse parse_binary_If3_else
    ldstr "bieu thuc qua phuc tap"
    newobj instance void class ParseError::.ctor(string)
    throw
  parse_binary_If3_else:
    ldarg.s 1
    ldarg.s 0
    callvirt instance class Tok TokCursor::'peek'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    stloc.s 2
    ldloc.s 2
    ldfld string Tok::'kind'
    ldstr "OP"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse parse_binary_If4_else
    br parse_binary_W1_end
  parse_binary_If4_else:
    ldloc.s 2
    ldfld string Tok::'text'
    call int32 TKVApp::'bin_prec'(string)
    stloc.s 3
    ldloc.s 3
    ldarg.s 2
    clt
    brfalse parse_binary_If5_else
    br parse_binary_W1_end
  parse_binary_If5_else:
    ldarg.s 1
    callvirt instance int32 TokCursor::'skip'()
    pop
    ldloc.s 3
    ldc.i4 1
    add.ovf
    stloc.s 4
    ldloc.s 2
    ldfld string Tok::'text'
    call int32 TKVApp::'is_right_assoc'(string)
    ldc.i4 1
    ceq
    brfalse parse_binary_If6_else
    ldloc.s 3
    stloc.s 4
  parse_binary_If6_else:
    ldarg.s 0
    ldarg.s 1
    ldloc.s 4
    call class Expr TKVApp::'parse_binary'(class [mscorlib]System.Collections.Generic.List`1<class Tok>, class TokCursor, int32)
    stloc.s 5
    ldloc.s 2
    ldfld string Tok::'text'
    ldloc.s 0
    ldloc.s 5
    call class Expr TKVApp::'bin_node'(string, class Expr, class Expr)
    stloc.s 0
    br parse_binary_W1_start
  parse_binary_W1_end:
    ldloc.s 0
    ret
  }
  .method public static class Expr 'parse_statement'(class [mscorlib]System.Collections.Generic.List`1<class Tok> 'toks', class TokCursor 'cur') cil managed
  {
    .maxstack 11
    .locals init (class Tok 'head', class Expr 'tree', class Tok 'nxt', int32 '__strtmp1893923000368', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 1
    ldarg.s 0
    callvirt instance int32 TokCursor::'at_end'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    ldc.i4 1
    ceq
    brfalse parse_statement_If1_else
    ldstr "bieu thuc rong"
    newobj instance void class ParseError::.ctor(string)
    throw
  parse_statement_If1_else:
    ldarg.s 1
    ldarg.s 0
    callvirt instance class Tok TokCursor::'peek'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    stloc.s 0
    ldloc.s 0
    ldfld string Tok::'kind'
    ldstr "SEMI"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse parse_statement_If2_else
    ldstr "bieu thuc rong"
    newobj instance void class ParseError::.ctor(string)
    throw
  parse_statement_If2_else:
    ldarg.s 0
    ldarg.s 1
    ldc.i4 1
    call class Expr TKVApp::'parse_binary'(class [mscorlib]System.Collections.Generic.List`1<class Tok>, class TokCursor, int32)
    stloc.s 1
    ldarg.s 1
    ldarg.s 0
    callvirt instance int32 TokCursor::'at_end'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    ldc.i4 0
    ceq
    brfalse parse_statement_If3_else
    ldarg.s 1
    ldarg.s 0
    callvirt instance class Tok TokCursor::'peek'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    stloc.s 2
    ldloc.s 2
    ldfld string Tok::'kind'
    ldstr "SEMI"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse parse_statement_If4_else
    ldstr "the thua '"
    ldloc.s 2
    ldfld string Tok::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' tai cot "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 2
    ldfld int32 Tok::'pos'
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class ParseError::.ctor(string)
    throw
  parse_statement_If4_else:
  parse_statement_If3_else:
    ldloc.s 1
    ret
  }
  .method public static string 'read_assign_name'(class [mscorlib]System.Collections.Generic.List`1<class Tok> 'toks', class TokCursor 'cur') cil managed
  {
    .maxstack 10
    .locals init (class Tok 'first', int32 'nxt_pos', class Tok 'second', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 1
    ldarg.s 0
    callvirt instance int32 TokCursor::'at_end'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    ldc.i4 1
    ceq
    brfalse read_assign_name_If1_else
    ldstr ""
    ret
  read_assign_name_If1_else:
    ldarg.s 1
    ldarg.s 0
    callvirt instance class Tok TokCursor::'peek'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    stloc.s 0
    ldloc.s 0
    ldfld string Tok::'kind'
    ldstr "NAME"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse read_assign_name_If2_else
    ldstr ""
    ret
  read_assign_name_If2_else:
    ldloc.s 0
    ldfld string Tok::'text'
    call int32 TKVApp::'func_arity'(string)
    ldc.i4 0
    cgt
    brfalse read_assign_name_If3_else
    ldstr ""
    ret
  read_assign_name_If3_else:
    ldarg.s 1
    ldfld int32 TokCursor::'pos'
    ldc.i4 1
    add.ovf
    stloc.s 1
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class Tok>::get_Count()
    clt
    ldc.i4.0
    ceq
    brfalse read_assign_name_If4_else
    ldstr ""
    ret
  read_assign_name_If4_else:
    ldarg.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s read_assign_name_idx_pos_5
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class Tok>::get_Count()
    add
    br.s read_assign_name_idx_end_5
  read_assign_name_idx_pos_5:
  read_assign_name_idx_end_5:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class Tok>::get_Item(int32)
    stloc.s 2
    ldloc.s 2
    ldfld string Tok::'kind'
    ldstr "ASSIGN"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse read_assign_name_If6_else
    ldstr ""
    ret
  read_assign_name_If6_else:
    ldarg.s 1
    callvirt instance int32 TokCursor::'skip'()
    pop
    ldarg.s 1
    callvirt instance int32 TokCursor::'skip'()
    pop
    ldloc.s 0
    ldfld string Tok::'text'
    ret
  }
  .method public static int32 'store_value'(class [mscorlib]System.Collections.Generic.List`1<string> 'names', class [mscorlib]System.Collections.Generic.List`1<float64> 'vals', string 'name', float64 'v') cil managed
  {
    .maxstack 11
    .locals init (int32 'i', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldc.i4.0
    stloc.s 0
  store_value_L1_start:
    ldloc.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge store_value_L1_end
    ldarg.s 0
    ldloc.s 0
    dup
    ldc.i4.0
    bge.s store_value_idx_pos_3
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s store_value_idx_end_3
  store_value_idx_pos_3:
  store_value_idx_end_3:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldarg.s 2
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse store_value_If2_else
    ldarg.s 1
    ldloc.s 0
    ldarg.s 3
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<float64>::set_Item(int32, !0)
    ldloc.s 0
    ret
  store_value_If2_else:
  store_value_L1_cont:
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    br store_value_L1_start
  store_value_L1_end:
    ldarg.s 0
    ldarg.s 2
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldarg.s 1
    ldarg.s 3
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<float64>::Add(!0)
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 1
    sub.ovf
    ret
  }
  .method public static string 'run_source'(string 'src', string 'mode') cil managed
  {
    .maxstack 13
    .locals init (class [mscorlib]System.Collections.Generic.List`1<class Tok> 'toks', class TokCursor 'cur', class [mscorlib]System.Collections.Generic.List`1<string> 'names', class [mscorlib]System.Collections.Generic.List`1<float64> 'vals', float64 'result', valuetype TkvInt 'produced', valuetype TkvInt 'nodes', valuetype TkvInt 'deepest', valuetype TkvInt 'stmts', class Expr 'last_tree', valuetype TkvInt 'guard', class Tok 'head', string 'target', class Expr 'tree', float64 'value', int32 'd', string 'line', int32 '__strtmp1893928033792', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    call class [mscorlib]System.Collections.Generic.List`1<class Tok> TKVApp::'tokenize'(string)
    stloc.s 0
    ldc.i4 0
    newobj instance void TokCursor::.ctor(int32)
    stloc.s 1
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 2
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<float64>::.ctor()
    stloc.s 3
    ldc.r8 0.0
    stloc.s 4
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 5
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 7
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 8
    ldstr "num"
    ldc.r8 0.0
    ldstr ""
    ldnull
    ldnull
    newobj instance void Expr::.ctor(string, float64, string, class Expr, class Expr)
    stloc.s 9
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 10
  run_source_W1_start:
    ldloc.s 1
    ldloc.s 0
    callvirt instance int32 TokCursor::'at_end'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    ldc.i4 0
    ceq
    brfalse run_source_W1_end
    ldloc.s 10
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 19
    stloc.s 18
    ldloca.s 18
    ldfld object TkvInt::big
    brtrue run_source_int2_slow
    ldloca.s 19
    ldfld object TkvInt::big
    brtrue run_source_int2_slow
    ldloca.s 18
    ldfld int64 TkvInt::lo
    ldloca.s 19
    ldfld int64 TkvInt::lo
    add
    stloc.s 21
    ldloca.s 18
    ldfld int64 TkvInt::lo
    ldloc.s 21
    xor
    ldloca.s 19
    ldfld int64 TkvInt::lo
    ldloc.s 21
    xor
    and
    ldc.i8 0
    blt run_source_int2_slow
    ldloca.s 20
    ldloc.s 21
    stfld int64 TkvInt::lo
    ldloca.s 20
    ldnull
    stfld object TkvInt::big
    ldloc.s 20
    br run_source_int2_done
  run_source_int2_slow:
    ldloc.s 18
    ldloc.s 19
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_source_int2_done:
    stloc.s 10
    ldloc.s 10
    ldc.i8 1024
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    cgt
    brfalse run_source_If3_else
    ldstr "qua nhieu cau lenh"
    newobj instance void class ParseError::.ctor(string)
    throw
  run_source_If3_else:
    ldloc.s 1
    ldloc.s 0
    callvirt instance class Tok TokCursor::'peek'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    stloc.s 11
    ldloc.s 11
    ldfld string Tok::'kind'
    ldstr "SEMI"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse run_source_If4_else
    ldloc.s 1
    callvirt instance int32 TokCursor::'skip'()
    pop
    br run_source_W1_start
  run_source_If4_else:
    ldloc.s 0
    ldloc.s 1
    call string TKVApp::'read_assign_name'(class [mscorlib]System.Collections.Generic.List`1<class Tok>, class TokCursor)
    stloc.s 12
    ldloc.s 0
    ldloc.s 1
    call class Expr TKVApp::'parse_statement'(class [mscorlib]System.Collections.Generic.List`1<class Tok>, class TokCursor)
    stloc.s 13
    ldloc.s 13
    stloc.s 9
    ldloc.s 13
    ldloc.s 2
    ldloc.s 3
    callvirt instance float64 Expr::'eval_with'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<float64>)
    stloc.s 14
    ldloc.s 12
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse run_source_If5_else
    ldloc.s 2
    ldloc.s 3
    ldloc.s 12
    ldloc.s 14
    call int32 TKVApp::'store_value'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<float64>, string, float64)
    pop
  run_source_If5_else:
    ldloc.s 14
    stloc.s 4
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 5
    ldloc.s 8
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 19
    stloc.s 18
    ldloca.s 18
    ldfld object TkvInt::big
    brtrue run_source_int6_slow
    ldloca.s 19
    ldfld object TkvInt::big
    brtrue run_source_int6_slow
    ldloca.s 18
    ldfld int64 TkvInt::lo
    ldloca.s 19
    ldfld int64 TkvInt::lo
    add
    stloc.s 21
    ldloca.s 18
    ldfld int64 TkvInt::lo
    ldloc.s 21
    xor
    ldloca.s 19
    ldfld int64 TkvInt::lo
    ldloc.s 21
    xor
    and
    ldc.i8 0
    blt run_source_int6_slow
    ldloca.s 20
    ldloc.s 21
    stfld int64 TkvInt::lo
    ldloca.s 20
    ldnull
    stfld object TkvInt::big
    ldloc.s 20
    br run_source_int6_done
  run_source_int6_slow:
    ldloc.s 18
    ldloc.s 19
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_source_int6_done:
    stloc.s 8
    ldloc.s 6
    ldloc.s 13
    callvirt instance int32 Expr::'node_count'()
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 19
    stloc.s 18
    ldloca.s 18
    ldfld object TkvInt::big
    brtrue run_source_int7_slow
    ldloca.s 19
    ldfld object TkvInt::big
    brtrue run_source_int7_slow
    ldloca.s 18
    ldfld int64 TkvInt::lo
    ldloca.s 19
    ldfld int64 TkvInt::lo
    add
    stloc.s 21
    ldloca.s 18
    ldfld int64 TkvInt::lo
    ldloc.s 21
    xor
    ldloca.s 19
    ldfld int64 TkvInt::lo
    ldloc.s 21
    xor
    and
    ldc.i8 0
    blt run_source_int7_slow
    ldloca.s 20
    ldloc.s 21
    stfld int64 TkvInt::lo
    ldloca.s 20
    ldnull
    stfld object TkvInt::big
    ldloc.s 20
    br run_source_int7_done
  run_source_int7_slow:
    ldloc.s 18
    ldloc.s 19
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_source_int7_done:
    stloc.s 6
    ldloc.s 13
    callvirt instance int32 Expr::'depth'()
    stloc.s 15
    ldloc.s 15
    ldloc.s 7
    call int32 TkvInt::ToI32(valuetype TkvInt)
    cgt
    brfalse run_source_If8_else
    ldloc.s 15
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 7
  run_source_If8_else:
    br run_source_W1_start
  run_source_W1_end:
    ldloc.s 5
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    ceq
    brfalse run_source_If9_else
    ldstr "khong co cau lenh nao"
    newobj instance void class ParseError::.ctor(string)
    throw
  run_source_If9_else:
    ldarg.s 1
    ldstr "tree"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse run_source_If10_else
    ldloc.s 9
    callvirt instance string Expr::'render'()
    ret
  run_source_If10_else:
    ldloc.s 4
    call string TKVApp::'fmt_value'(float64)
    stloc.s 16
    ldarg.s 1
    ldstr "stats"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse run_source_If11_else
    ldloc.s 16
    ldstr " | cau lenh="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 8
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " nut="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 6
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " sau nhat="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 7
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " | bien="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 16
  run_source_If11_else:
    ldloc.s 16
    ret
  }
  .method public static string 'describe_tokens'(string 'src') cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<class Tok> 'toks', class [mscorlib]System.Collections.Generic.List`1<string> 'parts', int32 '__iterlist0_idx', class Tok 't', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    call class [mscorlib]System.Collections.Generic.List`1<class Tok> TKVApp::'tokenize'(string)
    stloc.s 0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 1
    ldc.i4.0
    stloc.s 2
  describe_tokens_L1_start:
    ldloc.s 2
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class Tok>::get_Count()
    bge describe_tokens_L1_end
    ldloc.s 0
    ldloc.s 2
    dup
    ldc.i4.0
    bge.s describe_tokens_idx_pos_2
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class Tok>::get_Count()
    add
    br.s describe_tokens_idx_end_2
  describe_tokens_idx_pos_2:
  describe_tokens_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class Tok>::get_Item(int32)
    stloc.s 3
    ldloc.s 1
    ldloc.s 3
    callvirt instance string Tok::'show'()
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  describe_tokens_L1_cont:
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    br describe_tokens_L1_start
  describe_tokens_L1_end:
    ldstr " "
    ldloc.s 1
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    ret
  }
  .method public static string 'evaluate'(string 'src', string 'mode') cil managed
  {
    .maxstack 10
    .locals init (class LexError 'e', string '__ret_tmp', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    .try
    {
    ldarg.s 1
    ldstr "tokens"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse evaluate_If2_else
    ldarg.s 0
    call string TKVApp::'describe_tokens'(string)
    stloc.s 1
    leave evaluate_epilogue
  evaluate_If2_else:
    ldarg.s 0
    ldarg.s 1
    call string TKVApp::'run_source'(string, string)
    stloc.s 1
    leave evaluate_epilogue
    }
    catch class LexError
    {
      stloc.s 0
    ldloc.s 0
    callvirt instance string LexError::'render'()
    stloc.s 1
    leave evaluate_epilogue
    }
    catch class ParseError
    {
      stloc.s 0
    ldloc.s 0
    callvirt instance string LexError::'render'()
    stloc.s 1
    leave evaluate_epilogue
    }
    catch class EvalError
    {
      stloc.s 0
    ldloc.s 0
    callvirt instance string LexError::'render'()
    stloc.s 1
    leave evaluate_epilogue
    }
  evaluate_Try1_end:
  evaluate_epilogue:
    ldloc.s 1
    ret
  }
  .method public static string 'main'(string 'src', string 'mode') cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldarg.s 1
    call string TKVApp::'evaluate'(string, string)
    ret
  }
  .method public static void Main(string[] args) cil managed
  {
    .entrypoint
    .maxstack 8
    ldarg.0
    ldc.i4 0
    ldelem.ref
    ldarg.0
    ldc.i4 1
    ldelem.ref
    call string TKVApp::'main'(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ret
  }
}
