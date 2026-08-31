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
.class public auto ansi Diagnostic extends [mscorlib]System.Object
{
  .field public string 'text'
  .field public int32 'pos'
  .field public int32 'severity'
  .method public hidebysig specialname rtspecialname instance void .ctor(string 'text', int32 'pos', int32 'severity') cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.s 1
    stfld string Diagnostic::'text'
    ldarg.0
    ldarg.s 2
    stfld int32 Diagnostic::'pos'
    ldarg.0
    ldarg.s 3
    stfld int32 Diagnostic::'severity'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'is_fatal'() cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld int32 Diagnostic::'severity'
    ldc.i4 2
    clt
    ldc.i4.0
    ceq
    brfalse is_fatal_If1_else
    ldc.i4 1
    ret
  is_fatal_If1_else:
    ldc.i4 0
    ret
  }
  .method public hidebysig newslot virtual instance string 'marker'() cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld int32 Diagnostic::'severity'
    ldc.i4 2
    clt
    ldc.i4.0
    ceq
    brfalse marker_If1_else
    ldstr "!!"
    ret
  marker_If1_else:
    ldarg.s 0
    ldfld int32 Diagnostic::'severity'
    ldc.i4 1
    ceq
    brfalse marker_If2_else
    ldstr "!"
    ret
  marker_If2_else:
    ldstr "-"
    ret
  }
  .method public hidebysig newslot virtual instance string 'render'() cil managed
  {
    .maxstack 10
    .locals init (int32 '__strtmp2028387823472', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance string Diagnostic::'marker'()
    ldstr " cot "
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld int32 Diagnostic::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 2
    stloc.s 1
    ldloca.s 1
    ldfld object TkvInt::big
    brtrue render_int1_slow
    ldloca.s 2
    ldfld object TkvInt::big
    brtrue render_int1_slow
    ldloca.s 1
    ldfld int64 TkvInt::lo
    ldloca.s 2
    ldfld int64 TkvInt::lo
    add
    stloc.s 4
    ldloca.s 1
    ldfld int64 TkvInt::lo
    ldloc.s 4
    xor
    ldloca.s 2
    ldfld int64 TkvInt::lo
    ldloc.s 4
    xor
    and
    ldc.i8 0
    blt render_int1_slow
    ldloca.s 3
    ldloc.s 4
    stfld int64 TkvInt::lo
    ldloca.s 3
    ldnull
    stfld object TkvInt::big
    ldloc.s 3
    br render_int1_done
  render_int1_slow:
    ldloc.s 1
    ldloc.s 2
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  render_int1_done:
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ": "
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld string Diagnostic::'text'
    call string [mscorlib]System.String::Concat(string, string)
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
    .locals init (int32 '__strtmp2028381591360', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
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
    .maxstack 10
    .locals init (string 'ch', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance string SrcCursor::'peek_ch'()
    stloc.s 0
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 2
    stloc.s 1
    ldloca.s 1
    ldfld object TkvInt::big
    brtrue advance_int1_slow
    ldloca.s 2
    ldfld object TkvInt::big
    brtrue advance_int1_slow
    ldloca.s 1
    ldfld int64 TkvInt::lo
    ldloca.s 2
    ldfld int64 TkvInt::lo
    add
    stloc.s 4
    ldloca.s 1
    ldfld int64 TkvInt::lo
    ldloc.s 4
    xor
    ldloca.s 2
    ldfld int64 TkvInt::lo
    ldloc.s 4
    xor
    and
    ldc.i8 0
    blt advance_int1_slow
    ldloca.s 3
    ldloc.s 4
    stfld int64 TkvInt::lo
    ldloca.s 3
    ldnull
    stfld object TkvInt::big
    ldloc.s 3
    br advance_int1_done
  advance_int1_slow:
    ldloc.s 1
    ldloc.s 2
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  advance_int1_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
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
    .locals init (string '__hoist3', int32 '__strtmp2028381592064', int32 '__strtmp2028387830592', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
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
    .locals init (int32 '__strtmp2028387871232', int32 '__strtmp2028387831488', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
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
    callvirt instance int32 SrcCursor::'at_end'()
    ldc.i4 0
    ceq
    brfalse skip_blanks_W1_end
    ldarg.s 0
    callvirt instance string SrcCursor::'peek_ch'()
    stloc.s 1
    ldloc.s 1
    call int32 TKVApp::'is_space'(string)
    ldc.i4 1
    ceq
    brfalse skip_blanks_If2_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
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
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 SrcCursor::'pos'
    ldloc.s 0
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 3
    stloc.s 2
    ldloca.s 2
    ldfld object TkvInt::big
    brtrue skip_blanks_int4_slow
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue skip_blanks_int4_slow
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
    blt skip_blanks_int4_slow
    ldloca.s 4
    ldloc.s 5
    stfld int64 TkvInt::lo
    ldloca.s 4
    ldnull
    stfld object TkvInt::big
    ldloc.s 4
    br skip_blanks_int4_done
  skip_blanks_int4_slow:
    ldloc.s 2
    ldloc.s 3
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  skip_blanks_int4_done:
    stloc.s 0
    br skip_blanks_If2_end
  skip_blanks_If2_else:
    ldloc.s 1
    ldstr "#"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse skip_blanks_If5_else
  skip_blanks_W6_start:
    ldarg.s 0
    callvirt instance int32 SrcCursor::'at_end'()
    ldc.i4 0
    ceq
    brfalse skip_blanks_W6_end
    ldarg.s 0
    callvirt instance string SrcCursor::'peek_ch'()
    ldstr "\n"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse skip_blanks_If7_else
    br skip_blanks_W6_end
  skip_blanks_If7_else:
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 3
    stloc.s 2
    ldloca.s 2
    ldfld object TkvInt::big
    brtrue skip_blanks_int8_slow
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue skip_blanks_int8_slow
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
    blt skip_blanks_int8_slow
    ldloca.s 4
    ldloc.s 5
    stfld int64 TkvInt::lo
    ldloca.s 4
    ldnull
    stfld object TkvInt::big
    ldloc.s 4
    br skip_blanks_int8_done
  skip_blanks_int8_slow:
    ldloc.s 2
    ldloc.s 3
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  skip_blanks_int8_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 SrcCursor::'pos'
    ldloc.s 0
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 3
    stloc.s 2
    ldloca.s 2
    ldfld object TkvInt::big
    brtrue skip_blanks_int9_slow
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue skip_blanks_int9_slow
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
    blt skip_blanks_int9_slow
    ldloca.s 4
    ldloc.s 5
    stfld int64 TkvInt::lo
    ldloca.s 4
    ldnull
    stfld object TkvInt::big
    ldloc.s 4
    br skip_blanks_int9_done
  skip_blanks_int9_slow:
    ldloc.s 2
    ldloc.s 3
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  skip_blanks_int9_done:
    stloc.s 0
    br skip_blanks_W6_start
  skip_blanks_W6_end:
    br skip_blanks_If5_end
  skip_blanks_If5_else:
    ldloc.s 0
    call int32 TkvInt::ToI32(valuetype TkvInt)
    ret
  skip_blanks_If5_end:
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
    .locals init (int32 'start', string 'digits', valuetype TkvInt 'dots', class [mscorlib]System.Text.StringBuilder '__sb_digits', string 'ch', int32 '__strtmp2028387826832', string 'nxt', int32 '__strtmp2028387890528', int32 '__strtmp2028387822592', int32 '__strtmp2028381449696', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
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
    callvirt instance int32 SrcCursor::'at_end'()
    ldc.i4 0
    ceq
    brfalse read_number_W1_end
    ldarg.s 0
    callvirt instance string SrcCursor::'peek_ch'()
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
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 11
    stloc.s 10
    ldloca.s 10
    ldfld object TkvInt::big
    brtrue read_number_int3_slow
    ldloca.s 11
    ldfld object TkvInt::big
    brtrue read_number_int3_slow
    ldloca.s 10
    ldfld int64 TkvInt::lo
    ldloca.s 11
    ldfld int64 TkvInt::lo
    add
    stloc.s 13
    ldloca.s 10
    ldfld int64 TkvInt::lo
    ldloc.s 13
    xor
    ldloca.s 11
    ldfld int64 TkvInt::lo
    ldloc.s 13
    xor
    and
    ldc.i8 0
    blt read_number_int3_slow
    ldloca.s 12
    ldloc.s 13
    stfld int64 TkvInt::lo
    ldloca.s 12
    ldnull
    stfld object TkvInt::big
    ldloc.s 12
    br read_number_int3_done
  read_number_int3_slow:
    ldloc.s 10
    ldloc.s 11
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  read_number_int3_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 SrcCursor::'pos'
    br read_number_If2_end
  read_number_If2_else:
    ldloc.s 4
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_number_If4_else
    ldloc.s 2
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    ceq
    brfalse read_number_If5_else
    ldstr "so co 2 dau cham tai cot "
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 11
    stloc.s 10
    ldloca.s 10
    ldfld object TkvInt::big
    brtrue read_number_int6_slow
    ldloca.s 11
    ldfld object TkvInt::big
    brtrue read_number_int6_slow
    ldloca.s 10
    ldfld int64 TkvInt::lo
    ldloca.s 11
    ldfld int64 TkvInt::lo
    add
    stloc.s 13
    ldloca.s 10
    ldfld int64 TkvInt::lo
    ldloc.s 13
    xor
    ldloca.s 11
    ldfld int64 TkvInt::lo
    ldloc.s 13
    xor
    and
    ldc.i8 0
    blt read_number_int6_slow
    ldloca.s 12
    ldloc.s 13
    stfld int64 TkvInt::lo
    ldloca.s 12
    ldnull
    stfld object TkvInt::big
    ldloc.s 12
    br read_number_int6_done
  read_number_int6_slow:
    ldloc.s 10
    ldloc.s 11
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  read_number_int6_done:
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class LexError::.ctor(string)
    throw
  read_number_If5_else:
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
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 11
    stloc.s 10
    ldloca.s 10
    ldfld object TkvInt::big
    brtrue read_number_int7_slow
    ldloca.s 11
    ldfld object TkvInt::big
    brtrue read_number_int7_slow
    ldloca.s 10
    ldfld int64 TkvInt::lo
    ldloca.s 11
    ldfld int64 TkvInt::lo
    add
    stloc.s 13
    ldloca.s 10
    ldfld int64 TkvInt::lo
    ldloc.s 13
    xor
    ldloca.s 11
    ldfld int64 TkvInt::lo
    ldloc.s 13
    xor
    and
    ldc.i8 0
    blt read_number_int7_slow
    ldloca.s 12
    ldloc.s 13
    stfld int64 TkvInt::lo
    ldloca.s 12
    ldnull
    stfld object TkvInt::big
    ldloc.s 12
    br read_number_int7_done
  read_number_int7_slow:
    ldloc.s 10
    ldloc.s 11
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  read_number_int7_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 SrcCursor::'pos'
    br read_number_If4_end
  read_number_If4_else:
    br read_number_W1_end
  read_number_If4_end:
  read_number_If2_end:
    br read_number_W1_start
  read_number_W1_end:
    ldloc.s 3
    callvirt instance string [mscorlib]System.Object::ToString()
    stloc.s 1
    ldarg.s 0
    callvirt instance string SrcCursor::'peek_ch'()
    stloc.s 6
    ldloc.s 6
    ldstr "e"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_number_If8_else
    ldstr "chua ho tro ky hieu khoa hoc tai cot "
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 11
    stloc.s 10
    ldloca.s 10
    ldfld object TkvInt::big
    brtrue read_number_int9_slow
    ldloca.s 11
    ldfld object TkvInt::big
    brtrue read_number_int9_slow
    ldloca.s 10
    ldfld int64 TkvInt::lo
    ldloca.s 11
    ldfld int64 TkvInt::lo
    add
    stloc.s 13
    ldloca.s 10
    ldfld int64 TkvInt::lo
    ldloc.s 13
    xor
    ldloca.s 11
    ldfld int64 TkvInt::lo
    ldloc.s 13
    xor
    and
    ldc.i8 0
    blt read_number_int9_slow
    ldloca.s 12
    ldloc.s 13
    stfld int64 TkvInt::lo
    ldloca.s 12
    ldnull
    stfld object TkvInt::big
    ldloc.s 12
    br read_number_int9_done
  read_number_int9_slow:
    ldloc.s 10
    ldloc.s 11
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  read_number_int9_done:
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class LexError::.ctor(string)
    throw
  read_number_If8_else:
    ldloc.s 6
    ldstr "E"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_number_If10_else
    ldstr "chua ho tro ky hieu khoa hoc tai cot "
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 11
    stloc.s 10
    ldloca.s 10
    ldfld object TkvInt::big
    brtrue read_number_int11_slow
    ldloca.s 11
    ldfld object TkvInt::big
    brtrue read_number_int11_slow
    ldloca.s 10
    ldfld int64 TkvInt::lo
    ldloca.s 11
    ldfld int64 TkvInt::lo
    add
    stloc.s 13
    ldloca.s 10
    ldfld int64 TkvInt::lo
    ldloc.s 13
    xor
    ldloca.s 11
    ldfld int64 TkvInt::lo
    ldloc.s 13
    xor
    and
    ldc.i8 0
    blt read_number_int11_slow
    ldloca.s 12
    ldloc.s 13
    stfld int64 TkvInt::lo
    ldloca.s 12
    ldnull
    stfld object TkvInt::big
    ldloc.s 12
    br read_number_int11_done
  read_number_int11_slow:
    ldloc.s 10
    ldloc.s 11
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  read_number_int11_done:
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class LexError::.ctor(string)
    throw
  read_number_If10_else:
    ldloc.s 1
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_number_If12_else
    ldstr "so khong hop le tai cot "
    ldloc.s 0
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class LexError::.ctor(string)
    throw
  read_number_If12_else:
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
    callvirt instance int32 SrcCursor::'at_end'()
    ldc.i4 0
    ceq
    brfalse read_name_W1_end
    ldarg.s 0
    callvirt instance string SrcCursor::'peek_ch'()
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
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 5
    stloc.s 4
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue read_name_int3_slow
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue read_name_int3_slow
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
    blt read_name_int3_slow
    ldloca.s 6
    ldloc.s 7
    stfld int64 TkvInt::lo
    ldloca.s 6
    ldnull
    stfld object TkvInt::big
    ldloc.s 6
    br read_name_int3_done
  read_name_int3_slow:
    ldloc.s 4
    ldloc.s 5
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  read_name_int3_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
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
    .locals init (int32 'start', string 'ch', string 'nxt', int32 '__strtmp2028382114400', int32 '__strtmp2028382115120', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    stloc.s 0
    ldarg.s 0
    callvirt instance string SrcCursor::'advance'()
    stloc.s 1
    ldarg.s 0
    callvirt instance string SrcCursor::'peek_ch'()
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
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue read_operator_int3_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue read_operator_int3_slow
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
    blt read_operator_int3_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br read_operator_int3_done
  read_operator_int3_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  read_operator_int3_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
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
    brfalse read_operator_If4_else
    ldloc.s 2
    ldstr "="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If5_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue read_operator_int6_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue read_operator_int6_slow
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
    blt read_operator_int6_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br read_operator_int6_done
  read_operator_int6_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  read_operator_int6_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 SrcCursor::'pos'
    ldstr "OP"
    ldstr "<="
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If5_else:
    ldstr "OP"
    ldstr "<"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If4_else:
    ldloc.s 1
    ldstr ">"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If7_else
    ldloc.s 2
    ldstr "="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If8_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue read_operator_int9_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue read_operator_int9_slow
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
    blt read_operator_int9_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br read_operator_int9_done
  read_operator_int9_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  read_operator_int9_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 SrcCursor::'pos'
    ldstr "OP"
    ldstr ">="
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If8_else:
    ldstr "OP"
    ldstr ">"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If7_else:
    ldloc.s 1
    ldstr "="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If10_else
    ldloc.s 2
    ldstr "="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If11_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue read_operator_int12_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue read_operator_int12_slow
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
    blt read_operator_int12_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br read_operator_int12_done
  read_operator_int12_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  read_operator_int12_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 SrcCursor::'pos'
    ldstr "OP"
    ldstr "=="
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If11_else:
    ldstr "ASSIGN"
    ldstr "="
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If10_else:
    ldloc.s 1
    ldstr "!"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If13_else
    ldloc.s 2
    ldstr "="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If14_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    stloc.s 5
    ldloca.s 5
    ldfld object TkvInt::big
    brtrue read_operator_int15_slow
    ldloca.s 6
    ldfld object TkvInt::big
    brtrue read_operator_int15_slow
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
    blt read_operator_int15_slow
    ldloca.s 7
    ldloc.s 8
    stfld int64 TkvInt::lo
    ldloca.s 7
    ldnull
    stfld object TkvInt::big
    ldloc.s 7
    br read_operator_int15_done
  read_operator_int15_slow:
    ldloc.s 5
    ldloc.s 6
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  read_operator_int15_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 SrcCursor::'pos'
    ldstr "OP"
    ldstr "!="
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If14_else:
    ldstr "ky tu '!' don le tai cot "
    ldloc.s 0
    ldc.i4 1
    add.ovf
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class LexError::.ctor(string)
    throw
  read_operator_If13_else:
    ldloc.s 1
    ldstr "+"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If16_else
    ldstr "OP"
    ldstr "+"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If16_else:
    ldloc.s 1
    ldstr "-"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If17_else
    ldstr "OP"
    ldstr "-"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If17_else:
    ldloc.s 1
    ldstr "*"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If18_else
    ldstr "OP"
    ldstr "*"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If18_else:
    ldloc.s 1
    ldstr "%"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If19_else
    ldstr "OP"
    ldstr "%"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If19_else:
    ldloc.s 1
    ldstr "^"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse read_operator_If20_else
    ldstr "OP"
    ldstr "^"
    ldloc.s 0
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  read_operator_If20_else:
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
    .locals init (int32 'skipped', string 'ch', int32 '__strtmp2028382135184', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance int32 Lexer::'skip_blanks'()
    stloc.s 0
    ldarg.s 0
    callvirt instance int32 SrcCursor::'at_end'()
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
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue next_tok_int2_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue next_tok_int2_slow
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
    blt next_tok_int2_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br next_tok_int2_done
  next_tok_int2_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  next_tok_int2_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 Lexer::'count'
    ldarg.s 0
    callvirt instance string SrcCursor::'peek_ch'()
    stloc.s 1
    ldloc.s 1
    call int32 TKVApp::'is_digit'(string)
    ldc.i4 1
    ceq
    brfalse next_tok_If3_else
    ldarg.s 0
    callvirt instance class Tok Lexer::'read_number'()
    ret
  next_tok_If3_else:
    ldloc.s 1
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse next_tok_If4_else
    ldarg.s 0
    ldc.i4 1
    callvirt instance string SrcCursor::'peek_ch_at'(int32)
    call int32 TKVApp::'is_digit'(string)
    ldc.i4 1
    ceq
    brfalse next_tok_If5_else
    ldarg.s 0
    callvirt instance class Tok Lexer::'read_number'()
    ret
  next_tok_If5_else:
    ldstr "dau cham don le tai cot "
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue next_tok_int6_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue next_tok_int6_slow
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
    blt next_tok_int6_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br next_tok_int6_done
  next_tok_int6_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  next_tok_int6_done:
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class LexError::.ctor(string)
    throw
  next_tok_If4_else:
    ldloc.s 1
    call int32 TKVApp::'is_alpha'(string)
    ldc.i4 1
    ceq
    brfalse next_tok_If7_else
    ldarg.s 0
    callvirt instance class Tok Lexer::'read_name'()
    ret
  next_tok_If7_else:
    ldloc.s 1
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse next_tok_If8_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue next_tok_int9_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue next_tok_int9_slow
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
    blt next_tok_int9_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br next_tok_int9_done
  next_tok_int9_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  next_tok_int9_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 SrcCursor::'pos'
    ldstr "LPAREN"
    ldstr "("
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue next_tok_int10_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue next_tok_int10_slow
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloca.s 4
    ldfld int64 TkvInt::lo
    sub
    stloc.s 6
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloca.s 4
    ldfld int64 TkvInt::lo
    xor
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloc.s 6
    xor
    and
    ldc.i8 0
    blt next_tok_int10_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br next_tok_int10_done
  next_tok_int10_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::SubSlow(valuetype TkvInt, valuetype TkvInt)
  next_tok_int10_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  next_tok_If8_else:
    ldloc.s 1
    ldstr ")"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse next_tok_If11_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue next_tok_int12_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue next_tok_int12_slow
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
    blt next_tok_int12_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br next_tok_int12_done
  next_tok_int12_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  next_tok_int12_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 SrcCursor::'pos'
    ldstr "RPAREN"
    ldstr ")"
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue next_tok_int13_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue next_tok_int13_slow
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloca.s 4
    ldfld int64 TkvInt::lo
    sub
    stloc.s 6
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloca.s 4
    ldfld int64 TkvInt::lo
    xor
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloc.s 6
    xor
    and
    ldc.i8 0
    blt next_tok_int13_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br next_tok_int13_done
  next_tok_int13_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::SubSlow(valuetype TkvInt, valuetype TkvInt)
  next_tok_int13_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  next_tok_If11_else:
    ldloc.s 1
    ldstr ","
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse next_tok_If14_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue next_tok_int15_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue next_tok_int15_slow
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
    blt next_tok_int15_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br next_tok_int15_done
  next_tok_int15_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  next_tok_int15_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 SrcCursor::'pos'
    ldstr "COMMA"
    ldstr ","
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue next_tok_int16_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue next_tok_int16_slow
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloca.s 4
    ldfld int64 TkvInt::lo
    sub
    stloc.s 6
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloca.s 4
    ldfld int64 TkvInt::lo
    xor
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloc.s 6
    xor
    and
    ldc.i8 0
    blt next_tok_int16_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br next_tok_int16_done
  next_tok_int16_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::SubSlow(valuetype TkvInt, valuetype TkvInt)
  next_tok_int16_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  next_tok_If14_else:
    ldloc.s 1
    ldstr ";"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse next_tok_If17_else
    ldarg.s 0
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue next_tok_int18_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue next_tok_int18_slow
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
    blt next_tok_int18_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br next_tok_int18_done
  next_tok_int18_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  next_tok_int18_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 SrcCursor::'pos'
    ldstr "SEMI"
    ldstr ";"
    ldarg.s 0
    ldfld int32 SrcCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue next_tok_int19_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue next_tok_int19_slow
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloca.s 4
    ldfld int64 TkvInt::lo
    sub
    stloc.s 6
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloca.s 4
    ldfld int64 TkvInt::lo
    xor
    ldloca.s 3
    ldfld int64 TkvInt::lo
    ldloc.s 6
    xor
    and
    ldc.i8 0
    blt next_tok_int19_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br next_tok_int19_done
  next_tok_int19_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::SubSlow(valuetype TkvInt, valuetype TkvInt)
  next_tok_int19_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    newobj instance void Tok::.ctor(string, string, int32)
    ret
  next_tok_If17_else:
    ldarg.s 0
    callvirt instance class Tok Lexer::'read_operator'()
    ret
  }
}
.class public auto ansi OpInfo extends [mscorlib]System.Object
{
  .field public string 'sym'
  .field public int32 'prec'
  .field public int32 'assoc'
  .field public int32 'arity'
  .method public hidebysig specialname rtspecialname instance void .ctor(string 'sym', int32 'prec', int32 'assoc', int32 'arity') cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.s 1
    stfld string OpInfo::'sym'
    ldarg.0
    ldarg.s 2
    stfld int32 OpInfo::'prec'
    ldarg.0
    ldarg.s 3
    stfld int32 OpInfo::'assoc'
    ldarg.0
    ldarg.s 4
    stfld int32 OpInfo::'arity'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'is_right'() cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld int32 OpInfo::'assoc'
    ldc.i4 1
    ceq
    brfalse is_right_If1_else
    ldc.i4 1
    ret
  is_right_If1_else:
    ldc.i4 0
    ret
  }
  .method public hidebysig newslot virtual instance string 'show'() cil managed
  {
    .maxstack 10
    .locals init (int32 '__strtmp2028381591808', int32 '__strtmp2028381587904', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld string OpInfo::'sym'
    ldstr "/p"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld int32 OpInfo::'prec'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "/a"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld int32 OpInfo::'arity'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
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
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 2
    stloc.s 1
    ldloca.s 1
    ldfld object TkvInt::big
    brtrue take_int1_slow
    ldloca.s 2
    ldfld object TkvInt::big
    brtrue take_int1_slow
    ldloca.s 1
    ldfld int64 TkvInt::lo
    ldloca.s 2
    ldfld int64 TkvInt::lo
    add
    stloc.s 4
    ldloca.s 1
    ldfld int64 TkvInt::lo
    ldloc.s 4
    xor
    ldloca.s 2
    ldfld int64 TkvInt::lo
    ldloc.s 4
    xor
    and
    ldc.i8 0
    blt take_int1_slow
    ldloca.s 3
    ldloc.s 4
    stfld int64 TkvInt::lo
    ldloca.s 3
    ldnull
    stfld object TkvInt::big
    ldloc.s 3
    br take_int1_done
  take_int1_slow:
    ldloc.s 1
    ldloc.s 2
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  take_int1_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 TokCursor::'pos'
    ldloc.s 0
    ret
  }
  .method public hidebysig newslot virtual instance int32 'skip'() cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldarg.s 0
    ldfld int32 TokCursor::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 1
    stloc.s 0
    ldloca.s 0
    ldfld object TkvInt::big
    brtrue skip_int1_slow
    ldloca.s 1
    ldfld object TkvInt::big
    brtrue skip_int1_slow
    ldloca.s 0
    ldfld int64 TkvInt::lo
    ldloca.s 1
    ldfld int64 TkvInt::lo
    add
    stloc.s 3
    ldloca.s 0
    ldfld int64 TkvInt::lo
    ldloc.s 3
    xor
    ldloca.s 1
    ldfld int64 TkvInt::lo
    ldloc.s 3
    xor
    and
    ldc.i8 0
    blt skip_int1_slow
    ldloca.s 2
    ldloc.s 3
    stfld int64 TkvInt::lo
    ldloca.s 2
    ldnull
    stfld object TkvInt::big
    ldloc.s 2
    br skip_int1_done
  skip_int1_slow:
    ldloc.s 0
    ldloc.s 1
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  skip_int1_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 TokCursor::'pos'
    ldarg.s 0
    ldfld int32 TokCursor::'pos'
    ret
  }
}
.class public auto ansi Shunter extends [mscorlib]System.Object
{
  .field public int32 'consumed'
  .field public int32 'max_depth'
  .method public hidebysig specialname rtspecialname instance void .ctor(int32 'consumed', int32 'max_depth') cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.s 1
    stfld int32 Shunter::'consumed'
    ldarg.0
    ldarg.s 2
    stfld int32 Shunter::'max_depth'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'note_depth'(int32 'depth') cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 1
    ldarg.s 0
    ldfld int32 Shunter::'max_depth'
    cgt
    brfalse note_depth_If1_else
    ldarg.s 0
    ldarg.s 1
    stfld int32 Shunter::'max_depth'
  note_depth_If1_else:
    ldarg.s 0
    ldfld int32 Shunter::'max_depth'
    ret
  }
  .method public hidebysig newslot virtual instance string 'show'() cil managed
  {
    .maxstack 10
    .locals init (int32 '__strtmp2028387747904', int32 '__strtmp2028381720320', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "shunter: "
    ldarg.s 0
    ldfld int32 Shunter::'consumed'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " the, sau nhat "
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld int32 Shunter::'max_depth'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
}
.class public auto ansi NumStack extends [mscorlib]System.Object
{
  .field public class [mscorlib]System.Collections.Generic.List`1<float64> 'data'
  .field public int32 'peak'
  .method public hidebysig specialname rtspecialname instance void .ctor(int32 'peak') cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.s 1
    stfld int32 NumStack::'peak'
    ldarg.0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<float64>::.ctor()
    stfld class [mscorlib]System.Collections.Generic.List`1<float64> NumStack::'data'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'push'(float64 'v') cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<float64> '__self_data', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld class [mscorlib]System.Collections.Generic.List`1<float64> NumStack::'data'
    stloc.s 0
    ldloc.s 0
    ldarg.s 1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<float64>::Add(!0)
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Count()
    ldarg.s 0
    ldfld int32 NumStack::'peak'
    cgt
    brfalse push_If1_else
    ldarg.s 0
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Count()
    stfld int32 NumStack::'peak'
  push_If1_else:
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Count()
    ldc.i4 256
    cgt
    brfalse push_If2_else
    ldstr "tran ngan xep"
    newobj instance void class EvalError::.ctor(string)
    throw
  push_If2_else:
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Count()
    ret
  }
  .method public hidebysig newslot virtual instance float64 'pop'() cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<float64> '__self_data', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld class [mscorlib]System.Collections.Generic.List`1<float64> NumStack::'data'
    stloc.s 0
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Count()
    ldc.i4 0
    ceq
    brfalse pop_If1_else
    ldstr "thieu toan hang"
    newobj instance void class EvalError::.ctor(string)
    throw
  pop_If1_else:
    ldloc.s 0
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Count()
    ldc.i4.1
    sub
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Item(int32)
    ldloc.s 0
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Count()
    ldc.i4.1
    sub
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<float64>::RemoveAt(int32)
    ret
  }
  .method public hidebysig newslot virtual instance int32 'depth'() cil managed
  {
    .maxstack 9
    .locals init (class [mscorlib]System.Collections.Generic.List`1<float64> '__self_data', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld class [mscorlib]System.Collections.Generic.List`1<float64> NumStack::'data'
    stloc.s 0
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Count()
    ret
  }
  .method public hidebysig newslot virtual instance float64 'top'() cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<float64> '__self_data', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld class [mscorlib]System.Collections.Generic.List`1<float64> NumStack::'data'
    stloc.s 0
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Count()
    ldc.i4 0
    ceq
    brfalse top_If1_else
    ldstr "ngan xep rong"
    newobj instance void class EvalError::.ctor(string)
    throw
  top_If1_else:
    ldloc.s 0
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Count()
    ldc.i4 1
    sub.ovf
    dup
    ldc.i4.0
    bge.s top_idx_pos_2
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Count()
    add
    br.s top_idx_end_2
  top_idx_pos_2:
  top_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Item(int32)
    ret
  }
}
.class public auto ansi VarStore extends [mscorlib]System.Object
{
  .field public class [mscorlib]System.Collections.Generic.List`1<string> 'names'
  .field public class [mscorlib]System.Collections.Generic.List`1<float64> 'vals'
  .field public int32 'reads'
  .field public int32 'writes'
  .method public hidebysig specialname rtspecialname instance void .ctor(int32 'reads', int32 'writes') cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.s 1
    stfld int32 VarStore::'reads'
    ldarg.0
    ldarg.s 2
    stfld int32 VarStore::'writes'
    ldarg.0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stfld class [mscorlib]System.Collections.Generic.List`1<string> VarStore::'names'
    ldarg.0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<float64>::.ctor()
    stfld class [mscorlib]System.Collections.Generic.List`1<float64> VarStore::'vals'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'index_of'(string 'name') cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> '__self_names', int32 'i', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld class [mscorlib]System.Collections.Generic.List`1<string> VarStore::'names'
    stloc.s 0
    ldc.i4.0
    stloc.s 1
  index_of_L1_start:
    ldloc.s 1
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge index_of_L1_end
    ldloc.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s index_of_idx_pos_3
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s index_of_idx_end_3
  index_of_idx_pos_3:
  index_of_idx_end_3:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldarg.s 1
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse index_of_If2_else
    ldloc.s 1
    ret
  index_of_If2_else:
  index_of_L1_cont:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br index_of_L1_start
  index_of_L1_end:
    ldc.i4 1
    neg
    ret
  }
  .method public hidebysig newslot virtual instance float64 'lookup'(string 'name') cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<float64> '__self_vals', int32 'i', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld class [mscorlib]System.Collections.Generic.List`1<float64> VarStore::'vals'
    stloc.s 0
    ldarg.s 0
    ldarg.s 1
    callvirt instance int32 VarStore::'index_of'(string)
    stloc.s 1
    ldloc.s 1
    ldc.i4 0
    clt
    brfalse lookup_If1_else
    ldstr "bien '"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' chua duoc dat"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class EvalError::.ctor(string)
    throw
  lookup_If1_else:
    ldarg.s 0
    ldarg.s 0
    ldfld int32 VarStore::'reads'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 3
    stloc.s 2
    ldloca.s 2
    ldfld object TkvInt::big
    brtrue lookup_int2_slow
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue lookup_int2_slow
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
    blt lookup_int2_slow
    ldloca.s 4
    ldloc.s 5
    stfld int64 TkvInt::lo
    ldloca.s 4
    ldnull
    stfld object TkvInt::big
    ldloc.s 4
    br lookup_int2_done
  lookup_int2_slow:
    ldloc.s 2
    ldloc.s 3
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  lookup_int2_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 VarStore::'reads'
    ldloc.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s lookup_idx_pos_3
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Count()
    add
    br.s lookup_idx_end_3
  lookup_idx_pos_3:
  lookup_idx_end_3:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Item(int32)
    ret
  }
  .method public hidebysig newslot virtual instance int32 'assign'(string 'name', float64 'v') cil managed
  {
    .maxstack 11
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> '__self_names', class [mscorlib]System.Collections.Generic.List`1<float64> '__self_vals', int32 'i', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld class [mscorlib]System.Collections.Generic.List`1<string> VarStore::'names'
    stloc.s 0
    ldarg.s 0
    ldfld class [mscorlib]System.Collections.Generic.List`1<float64> VarStore::'vals'
    stloc.s 1
    ldarg.s 0
    ldarg.s 1
    callvirt instance int32 VarStore::'index_of'(string)
    stloc.s 2
    ldarg.s 0
    ldarg.s 0
    ldfld int32 VarStore::'writes'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue assign_int1_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue assign_int1_slow
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
    blt assign_int1_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br assign_int1_done
  assign_int1_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  assign_int1_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 VarStore::'writes'
    ldloc.s 2
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse assign_If2_else
    ldloc.s 1
    ldloc.s 2
    ldarg.s 2
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<float64>::set_Item(int32, !0)
    ldloc.s 2
    ret
  assign_If2_else:
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 64
    clt
    ldc.i4.0
    ceq
    brfalse assign_If3_else
    ldstr "qua nhieu bien"
    newobj instance void class EvalError::.ctor(string)
    throw
  assign_If3_else:
    ldloc.s 0
    ldarg.s 1
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 1
    ldarg.s 2
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<float64>::Add(!0)
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 1
    sub.ovf
    ret
  }
  .method public hidebysig newslot virtual instance int32 'count'() cil managed
  {
    .maxstack 9
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> '__self_names', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld class [mscorlib]System.Collections.Generic.List`1<string> VarStore::'names'
    stloc.s 0
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ret
  }
  .method public hidebysig newslot virtual instance string 'render'() cil managed
  {
    .maxstack 10
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> '__self_names', class [mscorlib]System.Collections.Generic.List`1<float64> '__self_vals', class [mscorlib]System.Collections.Generic.List`1<string> 'parts', int32 'i', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld class [mscorlib]System.Collections.Generic.List`1<string> VarStore::'names'
    stloc.s 0
    ldarg.s 0
    ldfld class [mscorlib]System.Collections.Generic.List`1<float64> VarStore::'vals'
    stloc.s 1
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 2
    ldc.i4.0
    stloc.s 3
  render_L1_start:
    ldloc.s 3
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge render_L1_end
    ldloc.s 2
    ldloc.s 0
    ldloc.s 3
    dup
    ldc.i4.0
    bge.s render_idx_pos_2
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s render_idx_end_2
  render_idx_pos_2:
  render_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldloc.s 1
    ldloc.s 3
    dup
    ldc.i4.0
    bge.s render_idx_pos_3
    ldloc.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Count()
    add
    br.s render_idx_end_3
  render_idx_pos_3:
  render_idx_end_3:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<float64>::get_Item(int32)
    call string TKVApp::'fmt_pair'(string, float64)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  render_L1_cont:
    ldloc.s 3
    ldc.i4 1
    add
    stloc.s 3
    br render_L1_start
  render_L1_end:
    ldstr ","
    ldloc.s 2
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    ret
  }
}
.class public auto ansi Machine extends [mscorlib]System.Object
{
  .field public int32 'ops_done'
  .field public int32 'calls_done'
  .method public hidebysig specialname rtspecialname instance void .ctor(int32 'ops_done', int32 'calls_done') cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.s 1
    stfld int32 Machine::'ops_done'
    ldarg.0
    ldarg.s 2
    stfld int32 Machine::'calls_done'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'note_op'() cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldarg.s 0
    ldfld int32 Machine::'ops_done'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 1
    stloc.s 0
    ldloca.s 0
    ldfld object TkvInt::big
    brtrue note_op_int1_slow
    ldloca.s 1
    ldfld object TkvInt::big
    brtrue note_op_int1_slow
    ldloca.s 0
    ldfld int64 TkvInt::lo
    ldloca.s 1
    ldfld int64 TkvInt::lo
    add
    stloc.s 3
    ldloca.s 0
    ldfld int64 TkvInt::lo
    ldloc.s 3
    xor
    ldloca.s 1
    ldfld int64 TkvInt::lo
    ldloc.s 3
    xor
    and
    ldc.i8 0
    blt note_op_int1_slow
    ldloca.s 2
    ldloc.s 3
    stfld int64 TkvInt::lo
    ldloca.s 2
    ldnull
    stfld object TkvInt::big
    ldloc.s 2
    br note_op_int1_done
  note_op_int1_slow:
    ldloc.s 0
    ldloc.s 1
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  note_op_int1_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 Machine::'ops_done'
    ldarg.s 0
    ldfld int32 Machine::'ops_done'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'note_call'() cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldarg.s 0
    ldfld int32 Machine::'calls_done'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 1
    stloc.s 0
    ldloca.s 0
    ldfld object TkvInt::big
    brtrue note_call_int1_slow
    ldloca.s 1
    ldfld object TkvInt::big
    brtrue note_call_int1_slow
    ldloca.s 0
    ldfld int64 TkvInt::lo
    ldloca.s 1
    ldfld int64 TkvInt::lo
    add
    stloc.s 3
    ldloca.s 0
    ldfld int64 TkvInt::lo
    ldloc.s 3
    xor
    ldloca.s 1
    ldfld int64 TkvInt::lo
    ldloc.s 3
    xor
    and
    ldc.i8 0
    blt note_call_int1_slow
    ldloca.s 2
    ldloc.s 3
    stfld int64 TkvInt::lo
    ldloca.s 2
    ldnull
    stfld object TkvInt::big
    ldloc.s 2
    br note_call_int1_done
  note_call_int1_slow:
    ldloc.s 0
    ldloc.s 1
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  note_call_int1_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 Machine::'calls_done'
    ldarg.s 0
    ldfld int32 Machine::'calls_done'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'total_work'() cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldfld int32 Machine::'ops_done'
    ldarg.s 0
    ldfld int32 Machine::'calls_done'
    add.ovf
    ret
  }
  .method public hidebysig newslot virtual instance float64 'run'(class [mscorlib]System.Collections.Generic.List`1<string> 'code', class VarStore 'store', class NumStack 'stack') cil managed
  {
    .maxstack 11
    .locals init (int32 '__iterlist1_idx', string 'item', string 'tag', int32 '__slice2028387876928_start', int32 '__slice2028387876928_stop', int32 '__slice2028387876928_count', string 'body', int32 '__slice2028387822672_start', int32 '__slice2028387822672_stop', int32 '__slice2028387822672_count', float64 'a', float64 'b', int32 'arity', int32 '__strtmp2028382114880', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldc.i4.0
    stloc.s 0
  run_L1_start:
    ldloc.s 0
    ldarg.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge run_L1_end
    ldarg.s 1
    ldloc.s 0
    dup
    ldc.i4.0
    bge.s run_idx_pos_2
    ldarg.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s run_idx_end_2
  run_idx_pos_2:
  run_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 1
    ldc.i4 0
    dup
    ldc.i4.0
    bge.s run_slc_neg_3
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s run_slc_neg_3
    pop
    ldc.i4.0
  run_slc_neg_3:
    dup
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s run_slc_clamp_3
    pop
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
  run_slc_clamp_3:
    stloc.s 3
    ldc.i4 1
    dup
    ldc.i4.0
    bge.s run_slc_neg_4
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s run_slc_neg_4
    pop
    ldc.i4.0
  run_slc_neg_4:
    dup
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s run_slc_clamp_4
    pop
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
  run_slc_clamp_4:
    stloc.s 4
    ldloc.s 4
    ldloc.s 3
    sub
    dup
    ldc.i4.0
    bge.s run_slc_cnt_5
    pop
    ldc.i4.0
  run_slc_cnt_5:
    stloc.s 5
    ldloc.s 1
    ldloc.s 3
    ldloc.s 5
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 2
    ldc.i4 1
    dup
    ldc.i4.0
    bge.s run_slc_neg_6
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s run_slc_neg_6
    pop
    ldc.i4.0
  run_slc_neg_6:
    dup
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s run_slc_clamp_6
    pop
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
  run_slc_clamp_6:
    stloc.s 7
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    stloc.s 8
    ldloc.s 8
    ldloc.s 7
    sub
    dup
    ldc.i4.0
    bge.s run_slc_cnt_7
    pop
    ldc.i4.0
  run_slc_cnt_7:
    stloc.s 9
    ldloc.s 1
    ldloc.s 7
    ldloc.s 9
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 6
    ldloc.s 2
    ldstr "n"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse run_If8_else
    ldarg.s 3
    ldloc.s 6
    call float64 TkvStr::ParseF64(string)
    callvirt instance int32 NumStack::'push'(float64)
    pop
    br run_If8_end
  run_If8_else:
    ldloc.s 2
    ldstr "v"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse run_If9_else
    ldarg.s 3
    ldarg.s 2
    ldloc.s 6
    callvirt instance float64 VarStore::'lookup'(string)
    callvirt instance int32 NumStack::'push'(float64)
    pop
    br run_If9_end
  run_If9_else:
    ldloc.s 2
    ldstr "o"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse run_If10_else
    ldarg.s 0
    callvirt instance int32 Machine::'note_op'()
    pop
    ldloc.s 6
    ldstr "u-"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse run_If11_else
    ldarg.s 3
    callvirt instance float64 NumStack::'pop'()
    stloc.s 10
    ldarg.s 3
    ldloc.s 6
    ldloc.s 10
    call float64 TKVApp::'apply_unary'(string, float64)
    callvirt instance int32 NumStack::'push'(float64)
    pop
    br run_If11_end
  run_If11_else:
    ldarg.s 3
    callvirt instance float64 NumStack::'pop'()
    stloc.s 11
    ldarg.s 3
    callvirt instance float64 NumStack::'pop'()
    stloc.s 10
    ldarg.s 3
    ldloc.s 6
    ldloc.s 10
    ldloc.s 11
    call float64 TKVApp::'apply_binary'(string, float64, float64)
    callvirt instance int32 NumStack::'push'(float64)
    pop
  run_If11_end:
    br run_If10_end
  run_If10_else:
    ldloc.s 2
    ldstr "f"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse run_If12_else
    ldarg.s 0
    callvirt instance int32 Machine::'note_call'()
    pop
    ldloc.s 6
    call int32 TKVApp::'func_arity'(string)
    stloc.s 12
    ldloc.s 12
    ldc.i4 1
    ceq
    brfalse run_If13_else
    ldarg.s 3
    callvirt instance float64 NumStack::'pop'()
    stloc.s 10
    ldarg.s 3
    ldloc.s 6
    ldloc.s 10
    call float64 TKVApp::'apply_func1'(string, float64)
    callvirt instance int32 NumStack::'push'(float64)
    pop
    br run_If13_end
  run_If13_else:
    ldloc.s 12
    ldc.i4 2
    ceq
    brfalse run_If14_else
    ldarg.s 3
    callvirt instance float64 NumStack::'pop'()
    stloc.s 11
    ldarg.s 3
    callvirt instance float64 NumStack::'pop'()
    stloc.s 10
    ldarg.s 3
    ldloc.s 6
    ldloc.s 10
    ldloc.s 11
    call float64 TKVApp::'apply_func2'(string, float64, float64)
    callvirt instance int32 NumStack::'push'(float64)
    pop
    br run_If14_end
  run_If14_else:
    ldstr "ham la '"
    ldloc.s 6
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "'"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class EvalError::.ctor(string)
    throw
  run_If14_end:
  run_If13_end:
    br run_If12_end
  run_If12_else:
    ldstr "ky hieu hau to la '"
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "'"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class EvalError::.ctor(string)
    throw
  run_If12_end:
  run_If10_end:
  run_If9_end:
  run_If8_end:
  run_L1_cont:
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    br run_L1_start
  run_L1_end:
    ldarg.s 3
    callvirt instance int32 NumStack::'depth'()
    ldc.i4 1
    ceq
    ldc.i4.0
    ceq
    brfalse run_If15_else
    ldstr "bieu thuc khong can bang (con "
    ldarg.s 3
    callvirt instance int32 NumStack::'depth'()
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " gia tri)"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class EvalError::.ctor(string)
    throw
  run_If15_else:
    ldarg.s 3
    callvirt instance float64 NumStack::'top'()
    ret
  }
}
.class public auto ansi Stats extends [mscorlib]System.Object
{
  .field public int32 'stmts'
  .field public int32 'toks'
  .field public int32 'ops'
  .field public int32 'calls'
  .field public int32 'peak_stack'
  .field public int32 'max_depth'
  .method public hidebysig specialname rtspecialname instance void .ctor(int32 'stmts', int32 'toks', int32 'ops', int32 'calls', int32 'peak_stack', int32 'max_depth') cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.s 1
    stfld int32 Stats::'stmts'
    ldarg.0
    ldarg.s 2
    stfld int32 Stats::'toks'
    ldarg.0
    ldarg.s 3
    stfld int32 Stats::'ops'
    ldarg.0
    ldarg.s 4
    stfld int32 Stats::'calls'
    ldarg.0
    ldarg.s 5
    stfld int32 Stats::'peak_stack'
    ldarg.0
    ldarg.s 6
    stfld int32 Stats::'max_depth'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'absorb_shunter'(class Shunter 'sh') cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldarg.s 0
    ldfld int32 Stats::'toks'
    ldarg.s 1
    ldfld int32 Shunter::'consumed'
    add.ovf
    stfld int32 Stats::'toks'
    ldarg.s 1
    ldfld int32 Shunter::'max_depth'
    ldarg.s 0
    ldfld int32 Stats::'max_depth'
    cgt
    brfalse absorb_shunter_If1_else
    ldarg.s 0
    ldarg.s 1
    ldfld int32 Shunter::'max_depth'
    stfld int32 Stats::'max_depth'
  absorb_shunter_If1_else:
    ldarg.s 0
    ldfld int32 Stats::'toks'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'absorb_machine'(class Machine 'm') cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldarg.s 0
    ldfld int32 Stats::'ops'
    ldarg.s 1
    ldfld int32 Machine::'ops_done'
    add.ovf
    stfld int32 Stats::'ops'
    ldarg.s 0
    ldarg.s 0
    ldfld int32 Stats::'calls'
    ldarg.s 1
    ldfld int32 Machine::'calls_done'
    add.ovf
    stfld int32 Stats::'calls'
    ldarg.s 0
    ldfld int32 Stats::'ops'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'absorb_stack'(class NumStack 'st') cil managed
  {
    .maxstack 8
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 1
    ldfld int32 NumStack::'peak'
    ldarg.s 0
    ldfld int32 Stats::'peak_stack'
    cgt
    brfalse absorb_stack_If1_else
    ldarg.s 0
    ldarg.s 1
    ldfld int32 NumStack::'peak'
    stfld int32 Stats::'peak_stack'
  absorb_stack_If1_else:
    ldarg.s 0
    ldfld int32 Stats::'peak_stack'
    ret
  }
  .method public hidebysig newslot virtual instance string 'render'() cil managed
  {
    .maxstack 10
    .locals init (int32 '__strtmp2028382077120', int32 '__strtmp2028382076992', int32 '__strtmp2028381982656', int32 '__strtmp2028381984320', int32 '__strtmp2028381984256', int32 '__strtmp2028381983296', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "cau lenh="
    ldarg.s 0
    ldfld int32 Stats::'stmts'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " the="
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld int32 Stats::'toks'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " phep="
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld int32 Stats::'ops'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " goi ham="
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld int32 Stats::'calls'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " dinh ngan xep="
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld int32 Stats::'peak_stack'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " ngoac sau nhat="
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldfld int32 Stats::'max_depth'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
}
.class public auto ansi Session extends [mscorlib]System.Object
{
  .field public int32 'last_ok'
  .field public int32 'stmt_count'
  .method public hidebysig specialname rtspecialname instance void .ctor(int32 'last_ok', int32 'stmt_count') cil managed
  {
    .maxstack 8
    ldarg.0
    call instance void [mscorlib]System.Object::.ctor()
    ldarg.0
    ldarg.s 1
    stfld int32 Session::'last_ok'
    ldarg.0
    ldarg.s 2
    stfld int32 Session::'stmt_count'
    ret
  }
  .method public hidebysig newslot virtual instance int32 'note_stmt'() cil managed
  {
    .maxstack 10
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldarg.s 0
    ldfld int32 Session::'stmt_count'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 1
    stloc.s 0
    ldloca.s 0
    ldfld object TkvInt::big
    brtrue note_stmt_int1_slow
    ldloca.s 1
    ldfld object TkvInt::big
    brtrue note_stmt_int1_slow
    ldloca.s 0
    ldfld int64 TkvInt::lo
    ldloca.s 1
    ldfld int64 TkvInt::lo
    add
    stloc.s 3
    ldloca.s 0
    ldfld int64 TkvInt::lo
    ldloc.s 3
    xor
    ldloca.s 1
    ldfld int64 TkvInt::lo
    ldloc.s 3
    xor
    and
    ldc.i8 0
    blt note_stmt_int1_slow
    ldloca.s 2
    ldloc.s 3
    stfld int64 TkvInt::lo
    ldloca.s 2
    ldnull
    stfld object TkvInt::big
    ldloc.s 2
    br note_stmt_int1_done
  note_stmt_int1_slow:
    ldloc.s 0
    ldloc.s 1
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  note_stmt_int1_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 Session::'stmt_count'
    ldarg.s 0
    ldfld int32 Session::'stmt_count'
    ret
  }
  .method public hidebysig newslot virtual instance string 'describe'() cil managed
  {
    .maxstack 10
    .locals init (int32 '__strtmp2028381766976', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldstr "phien: "
    ldarg.s 0
    ldfld int32 Session::'stmt_count'
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " cau lenh"
    call string [mscorlib]System.String::Concat(string, string)
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
  .method public static class OpInfo 'op_info'(string 'sym') cil managed
  {
    .maxstack 12
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldstr "=="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse op_info_If1_else
    ldarg.s 0
    ldc.i4 1
    ldc.i4 0
    ldc.i4 2
    newobj instance void OpInfo::.ctor(string, int32, int32, int32)
    ret
  op_info_If1_else:
    ldarg.s 0
    ldstr "!="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse op_info_If2_else
    ldarg.s 0
    ldc.i4 1
    ldc.i4 0
    ldc.i4 2
    newobj instance void OpInfo::.ctor(string, int32, int32, int32)
    ret
  op_info_If2_else:
    ldarg.s 0
    ldstr "<"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse op_info_If3_else
    ldarg.s 0
    ldc.i4 2
    ldc.i4 0
    ldc.i4 2
    newobj instance void OpInfo::.ctor(string, int32, int32, int32)
    ret
  op_info_If3_else:
    ldarg.s 0
    ldstr "<="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse op_info_If4_else
    ldarg.s 0
    ldc.i4 2
    ldc.i4 0
    ldc.i4 2
    newobj instance void OpInfo::.ctor(string, int32, int32, int32)
    ret
  op_info_If4_else:
    ldarg.s 0
    ldstr ">"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse op_info_If5_else
    ldarg.s 0
    ldc.i4 2
    ldc.i4 0
    ldc.i4 2
    newobj instance void OpInfo::.ctor(string, int32, int32, int32)
    ret
  op_info_If5_else:
    ldarg.s 0
    ldstr ">="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse op_info_If6_else
    ldarg.s 0
    ldc.i4 2
    ldc.i4 0
    ldc.i4 2
    newobj instance void OpInfo::.ctor(string, int32, int32, int32)
    ret
  op_info_If6_else:
    ldarg.s 0
    ldstr "+"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse op_info_If7_else
    ldarg.s 0
    ldc.i4 3
    ldc.i4 0
    ldc.i4 2
    newobj instance void OpInfo::.ctor(string, int32, int32, int32)
    ret
  op_info_If7_else:
    ldarg.s 0
    ldstr "-"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse op_info_If8_else
    ldarg.s 0
    ldc.i4 3
    ldc.i4 0
    ldc.i4 2
    newobj instance void OpInfo::.ctor(string, int32, int32, int32)
    ret
  op_info_If8_else:
    ldarg.s 0
    ldstr "*"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse op_info_If9_else
    ldarg.s 0
    ldc.i4 4
    ldc.i4 0
    ldc.i4 2
    newobj instance void OpInfo::.ctor(string, int32, int32, int32)
    ret
  op_info_If9_else:
    ldarg.s 0
    ldstr "/"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse op_info_If10_else
    ldarg.s 0
    ldc.i4 4
    ldc.i4 0
    ldc.i4 2
    newobj instance void OpInfo::.ctor(string, int32, int32, int32)
    ret
  op_info_If10_else:
    ldarg.s 0
    ldstr "//"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse op_info_If11_else
    ldarg.s 0
    ldc.i4 4
    ldc.i4 0
    ldc.i4 2
    newobj instance void OpInfo::.ctor(string, int32, int32, int32)
    ret
  op_info_If11_else:
    ldarg.s 0
    ldstr "%"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse op_info_If12_else
    ldarg.s 0
    ldc.i4 4
    ldc.i4 0
    ldc.i4 2
    newobj instance void OpInfo::.ctor(string, int32, int32, int32)
    ret
  op_info_If12_else:
    ldarg.s 0
    ldstr "u-"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse op_info_If13_else
    ldarg.s 0
    ldc.i4 6
    ldc.i4 1
    ldc.i4 1
    newobj instance void OpInfo::.ctor(string, int32, int32, int32)
    ret
  op_info_If13_else:
    ldarg.s 0
    ldstr "^"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse op_info_If14_else
    ldarg.s 0
    ldc.i4 7
    ldc.i4 1
    ldc.i4 2
    newobj instance void OpInfo::.ctor(string, int32, int32, int32)
    ret
  op_info_If14_else:
    ldstr "toan tu la '"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "'"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class ParseError::.ctor(string)
    throw
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
  .method public static int32 'prec_of'(string 'sym') cil managed
  {
    .maxstack 9
    .locals init (class OpInfo 'info', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    call class OpInfo TKVApp::'op_info'(string)
    stloc.s 0
    ldloc.s 0
    ldfld int32 OpInfo::'prec'
    ret
  }
  .method public static int32 'should_pop'(string 'top', string 'cur') cil managed
  {
    .maxstack 10
    .locals init (class OpInfo 'top_info', class OpInfo 'cur_info', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse should_pop_If1_else
    ldc.i4 0
    ret
  should_pop_If1_else:
    ldarg.s 0
    call class OpInfo TKVApp::'op_info'(string)
    stloc.s 0
    ldarg.s 1
    call class OpInfo TKVApp::'op_info'(string)
    stloc.s 1
    ldloc.s 0
    ldfld int32 OpInfo::'prec'
    ldloc.s 1
    ldfld int32 OpInfo::'prec'
    cgt
    brfalse should_pop_If2_else
    ldc.i4 1
    ret
  should_pop_If2_else:
    ldloc.s 0
    ldfld int32 OpInfo::'prec'
    ldloc.s 1
    ldfld int32 OpInfo::'prec'
    clt
    brfalse should_pop_If3_else
    ldc.i4 0
    ret
  should_pop_If3_else:
    ldloc.s 1
    callvirt instance int32 OpInfo::'is_right'()
    ldc.i4 1
    ceq
    brfalse should_pop_If4_else
    ldc.i4 0
    ret
  should_pop_If4_else:
    ldc.i4 1
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'to_postfix'(class [mscorlib]System.Collections.Generic.List`1<class Tok> 'toks', class TokCursor 'cur', class Shunter 'sh') cil managed
  {
    .maxstack 11
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'output', class [mscorlib]System.Collections.Generic.List`1<string> 'ops', valuetype TkvInt 'depth', string 'prev_kind', valuetype TkvInt 'guard', class Tok 't', int32 'arity', int32 'popped', int32 '__strtmp2028387824432', int32 'closed', int32 '__strtmp2028387823392', string 'sym', int32 '__strtmp2028387876928', int32 '__strtmp2028387826752', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 1
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 2
    ldstr "start"
    stloc.s 3
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
  to_postfix_W1_start:
    ldarg.s 1
    ldarg.s 0
    callvirt instance int32 TokCursor::'at_end'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    ldc.i4 0
    ceq
    brfalse to_postfix_W1_end
    ldarg.s 1
    ldarg.s 0
    callvirt instance class Tok TokCursor::'peek'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    stloc.s 5
    ldloc.s 5
    ldfld string Tok::'kind'
    ldstr "SEMI"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse to_postfix_If2_else
    br to_postfix_W1_end
  to_postfix_If2_else:
    ldloc.s 4
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 15
    stloc.s 14
    ldloca.s 14
    ldfld object TkvInt::big
    brtrue to_postfix_int3_slow
    ldloca.s 15
    ldfld object TkvInt::big
    brtrue to_postfix_int3_slow
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloca.s 15
    ldfld int64 TkvInt::lo
    add
    stloc.s 17
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    ldloca.s 15
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    and
    ldc.i8 0
    blt to_postfix_int3_slow
    ldloca.s 16
    ldloc.s 17
    stfld int64 TkvInt::lo
    ldloca.s 16
    ldnull
    stfld object TkvInt::big
    ldloc.s 16
    br to_postfix_int3_done
  to_postfix_int3_slow:
    ldloc.s 14
    ldloc.s 15
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  to_postfix_int3_done:
    stloc.s 4
    ldloc.s 4
    ldc.i8 8192
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    cgt
    brfalse to_postfix_If4_else
    ldstr "bieu thuc qua phuc tap"
    newobj instance void class ParseError::.ctor(string)
    throw
  to_postfix_If4_else:
    ldarg.s 1
    callvirt instance int32 TokCursor::'skip'()
    pop
    ldarg.s 2
    ldarg.s 2
    ldfld int32 Shunter::'consumed'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 15
    stloc.s 14
    ldloca.s 14
    ldfld object TkvInt::big
    brtrue to_postfix_int5_slow
    ldloca.s 15
    ldfld object TkvInt::big
    brtrue to_postfix_int5_slow
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloca.s 15
    ldfld int64 TkvInt::lo
    add
    stloc.s 17
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    ldloca.s 15
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    and
    ldc.i8 0
    blt to_postfix_int5_slow
    ldloca.s 16
    ldloc.s 17
    stfld int64 TkvInt::lo
    ldloca.s 16
    ldnull
    stfld object TkvInt::big
    ldloc.s 16
    br to_postfix_int5_done
  to_postfix_int5_slow:
    ldloc.s 14
    ldloc.s 15
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  to_postfix_int5_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 Shunter::'consumed'
    ldloc.s 5
    ldfld string Tok::'kind'
    ldstr "NUM"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse to_postfix_If6_else
    ldloc.s 0
    ldstr "n"
    ldloc.s 5
    ldfld string Tok::'text'
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldstr "value"
    stloc.s 3
    br to_postfix_If6_end
  to_postfix_If6_else:
    ldloc.s 5
    ldfld string Tok::'kind'
    ldstr "NAME"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse to_postfix_If7_else
    ldloc.s 5
    ldfld string Tok::'text'
    call int32 TKVApp::'func_arity'(string)
    stloc.s 6
    ldloc.s 6
    ldc.i4 0
    cgt
    brfalse to_postfix_If8_else
    ldloc.s 1
    ldstr "f"
    ldloc.s 5
    ldfld string Tok::'text'
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br to_postfix_If8_end
  to_postfix_If8_else:
    ldloc.s 0
    ldstr "v"
    ldloc.s 5
    ldfld string Tok::'text'
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  to_postfix_If8_end:
    ldstr "value"
    stloc.s 3
    br to_postfix_If7_end
  to_postfix_If7_else:
    ldloc.s 5
    ldfld string Tok::'kind'
    ldstr "COMMA"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse to_postfix_If9_else
    ldloc.s 1
    ldloc.s 0
    call int32 TKVApp::'pop_until_lparen'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 7
    ldloc.s 7
    ldc.i4 0
    ceq
    brfalse to_postfix_If10_else
    ldstr "dau phay ngoai loi goi ham tai cot "
    ldloc.s 5
    ldfld int32 Tok::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 15
    stloc.s 14
    ldloca.s 14
    ldfld object TkvInt::big
    brtrue to_postfix_int11_slow
    ldloca.s 15
    ldfld object TkvInt::big
    brtrue to_postfix_int11_slow
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloca.s 15
    ldfld int64 TkvInt::lo
    add
    stloc.s 17
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    ldloca.s 15
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    and
    ldc.i8 0
    blt to_postfix_int11_slow
    ldloca.s 16
    ldloc.s 17
    stfld int64 TkvInt::lo
    ldloca.s 16
    ldnull
    stfld object TkvInt::big
    ldloc.s 16
    br to_postfix_int11_done
  to_postfix_int11_slow:
    ldloc.s 14
    ldloc.s 15
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  to_postfix_int11_done:
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class ParseError::.ctor(string)
    throw
  to_postfix_If10_else:
    ldstr "comma"
    stloc.s 3
    br to_postfix_If9_end
  to_postfix_If9_else:
    ldloc.s 5
    ldfld string Tok::'kind'
    ldstr "LPAREN"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse to_postfix_If12_else
    ldloc.s 1
    ldstr "("
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 2
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 15
    stloc.s 14
    ldloca.s 14
    ldfld object TkvInt::big
    brtrue to_postfix_int13_slow
    ldloca.s 15
    ldfld object TkvInt::big
    brtrue to_postfix_int13_slow
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloca.s 15
    ldfld int64 TkvInt::lo
    add
    stloc.s 17
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    ldloca.s 15
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    and
    ldc.i8 0
    blt to_postfix_int13_slow
    ldloca.s 16
    ldloc.s 17
    stfld int64 TkvInt::lo
    ldloca.s 16
    ldnull
    stfld object TkvInt::big
    ldloc.s 16
    br to_postfix_int13_done
  to_postfix_int13_slow:
    ldloc.s 14
    ldloc.s 15
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  to_postfix_int13_done:
    stloc.s 2
    ldarg.s 2
    ldloc.s 2
    call int32 TkvInt::ToI32(valuetype TkvInt)
    callvirt instance int32 Shunter::'note_depth'(int32)
    pop
    ldstr "open"
    stloc.s 3
    br to_postfix_If12_end
  to_postfix_If12_else:
    ldloc.s 5
    ldfld string Tok::'kind'
    ldstr "RPAREN"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse to_postfix_If14_else
    ldloc.s 1
    ldloc.s 0
    call int32 TKVApp::'close_paren'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 9
    ldloc.s 9
    ldc.i4 0
    ceq
    brfalse to_postfix_If15_else
    ldstr "thua dau ')' tai cot "
    ldloc.s 5
    ldfld int32 Tok::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 15
    stloc.s 14
    ldloca.s 14
    ldfld object TkvInt::big
    brtrue to_postfix_int16_slow
    ldloca.s 15
    ldfld object TkvInt::big
    brtrue to_postfix_int16_slow
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloca.s 15
    ldfld int64 TkvInt::lo
    add
    stloc.s 17
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    ldloca.s 15
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    and
    ldc.i8 0
    blt to_postfix_int16_slow
    ldloca.s 16
    ldloc.s 17
    stfld int64 TkvInt::lo
    ldloca.s 16
    ldnull
    stfld object TkvInt::big
    ldloc.s 16
    br to_postfix_int16_done
  to_postfix_int16_slow:
    ldloc.s 14
    ldloc.s 15
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  to_postfix_int16_done:
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class ParseError::.ctor(string)
    throw
  to_postfix_If15_else:
    ldloc.s 2
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 15
    stloc.s 14
    ldloca.s 14
    ldfld object TkvInt::big
    brtrue to_postfix_int17_slow
    ldloca.s 15
    ldfld object TkvInt::big
    brtrue to_postfix_int17_slow
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloca.s 15
    ldfld int64 TkvInt::lo
    sub
    stloc.s 17
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloca.s 15
    ldfld int64 TkvInt::lo
    xor
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    and
    ldc.i8 0
    blt to_postfix_int17_slow
    ldloca.s 16
    ldloc.s 17
    stfld int64 TkvInt::lo
    ldloca.s 16
    ldnull
    stfld object TkvInt::big
    ldloc.s 16
    br to_postfix_int17_done
  to_postfix_int17_slow:
    ldloc.s 14
    ldloc.s 15
    call valuetype TkvInt TkvInt::SubSlow(valuetype TkvInt, valuetype TkvInt)
  to_postfix_int17_done:
    stloc.s 2
    ldstr "value"
    stloc.s 3
    br to_postfix_If14_end
  to_postfix_If14_else:
    ldloc.s 5
    ldfld string Tok::'kind'
    ldstr "OP"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse to_postfix_If18_else
    ldloc.s 5
    ldfld string Tok::'text'
    stloc.s 11
    ldloc.s 11
    ldstr "-"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse to_postfix_If19_else
    ldloc.s 3
    ldstr "value"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse to_postfix_If20_else
    ldstr "u-"
    stloc.s 11
  to_postfix_If20_else:
  to_postfix_If19_else:
    ldloc.s 11
    ldstr "+"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse to_postfix_If21_else
    ldloc.s 3
    ldstr "value"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse to_postfix_If22_else
    ldstr "u+"
    stloc.s 11
  to_postfix_If22_else:
  to_postfix_If21_else:
    ldloc.s 11
    ldstr "u+"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse to_postfix_If23_else
    ldstr "op"
    stloc.s 3
    br to_postfix_If23_end
  to_postfix_If23_else:
    ldloc.s 1
    ldloc.s 0
    ldloc.s 11
    call int32 TKVApp::'push_operator'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<string>, string)
    pop
    ldstr "op"
    stloc.s 3
  to_postfix_If23_end:
    br to_postfix_If18_end
  to_postfix_If18_else:
    ldloc.s 5
    ldfld string Tok::'kind'
    ldstr "ASSIGN"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse to_postfix_If24_else
    ldstr "phep gan chi dat o dau cau lenh (cot "
    ldloc.s 5
    ldfld int32 Tok::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 15
    stloc.s 14
    ldloca.s 14
    ldfld object TkvInt::big
    brtrue to_postfix_int25_slow
    ldloca.s 15
    ldfld object TkvInt::big
    brtrue to_postfix_int25_slow
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloca.s 15
    ldfld int64 TkvInt::lo
    add
    stloc.s 17
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    ldloca.s 15
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    and
    ldc.i8 0
    blt to_postfix_int25_slow
    ldloca.s 16
    ldloc.s 17
    stfld int64 TkvInt::lo
    ldloca.s 16
    ldnull
    stfld object TkvInt::big
    ldloc.s 16
    br to_postfix_int25_done
  to_postfix_int25_slow:
    ldloc.s 14
    ldloc.s 15
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  to_postfix_int25_done:
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ")"
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class ParseError::.ctor(string)
    throw
    br to_postfix_If24_end
  to_postfix_If24_else:
    ldstr "the la '"
    ldloc.s 5
    ldfld string Tok::'text'
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' tai cot "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 5
    ldfld int32 Tok::'pos'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 15
    stloc.s 14
    ldloca.s 14
    ldfld object TkvInt::big
    brtrue to_postfix_int26_slow
    ldloca.s 15
    ldfld object TkvInt::big
    brtrue to_postfix_int26_slow
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloca.s 15
    ldfld int64 TkvInt::lo
    add
    stloc.s 17
    ldloca.s 14
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    ldloca.s 15
    ldfld int64 TkvInt::lo
    ldloc.s 17
    xor
    and
    ldc.i8 0
    blt to_postfix_int26_slow
    ldloca.s 16
    ldloc.s 17
    stfld int64 TkvInt::lo
    ldloca.s 16
    ldnull
    stfld object TkvInt::big
    ldloc.s 16
    br to_postfix_int26_done
  to_postfix_int26_slow:
    ldloc.s 14
    ldloc.s 15
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  to_postfix_int26_done:
    call string TkvInt::Str(valuetype TkvInt)
    call string [mscorlib]System.String::Concat(string, string)
    newobj instance void class ParseError::.ctor(string)
    throw
  to_postfix_If24_end:
  to_postfix_If18_end:
  to_postfix_If14_end:
  to_postfix_If12_end:
  to_postfix_If9_end:
  to_postfix_If7_end:
  to_postfix_If6_end:
    br to_postfix_W1_start
  to_postfix_W1_end:
    ldloc.s 1
    ldloc.s 0
    call int32 TKVApp::'flush_operators'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<string>)
    pop
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 0
    ceq
    brfalse to_postfix_If27_else
    ldstr "bieu thuc rong"
    newobj instance void class ParseError::.ctor(string)
    throw
  to_postfix_If27_else:
    ldloc.s 0
    ret
  }
  .method public static int32 'push_operator'(class [mscorlib]System.Collections.Generic.List`1<string> 'ops', class [mscorlib]System.Collections.Generic.List`1<string> 'output', string 'sym') cil managed
  {
    .maxstack 11
    .locals init (int32 '__slice2028381449456_start', int32 '__slice2028381449456_stop', int32 '__slice2028381449456_count', string 'top', int32 '__slice2028387890528_start', int32 '__slice2028387890528_stop', int32 '__slice2028387890528_count', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldc.i4 0
    dup
    ldc.i4.0
    bge.s push_operator_slc_neg_2
    ldarg.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s push_operator_slc_neg_2
    pop
    ldc.i4.0
  push_operator_slc_neg_2:
    dup
    ldarg.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s push_operator_slc_clamp_2
    pop
    ldarg.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
  push_operator_slc_clamp_2:
    stloc.s 0
    ldc.i4 1
    dup
    ldc.i4.0
    bge.s push_operator_slc_neg_3
    ldarg.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s push_operator_slc_neg_3
    pop
    ldc.i4.0
  push_operator_slc_neg_3:
    dup
    ldarg.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s push_operator_slc_clamp_3
    pop
    ldarg.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
  push_operator_slc_clamp_3:
    stloc.s 1
    ldloc.s 1
    ldloc.s 0
    sub
    dup
    ldc.i4.0
    bge.s push_operator_slc_cnt_4
    pop
    ldc.i4.0
  push_operator_slc_cnt_4:
    stloc.s 2
    ldarg.s 2
    ldloc.s 0
    ldloc.s 2
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    ldstr "u"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse push_operator_If1_else
    ldarg.s 0
    ldarg.s 2
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ret
  push_operator_If1_else:
  push_operator_W5_start:
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 0
    cgt
    brfalse push_operator_W5_end
    ldarg.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 1
    sub.ovf
    dup
    ldc.i4.0
    bge.s push_operator_idx_pos_6
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s push_operator_idx_end_6
  push_operator_idx_pos_6:
  push_operator_idx_end_6:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 3
    ldloc.s 3
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse push_operator_If7_else
    br push_operator_W5_end
  push_operator_If7_else:
    ldc.i4 0
    dup
    ldc.i4.0
    bge.s push_operator_slc_neg_9
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s push_operator_slc_neg_9
    pop
    ldc.i4.0
  push_operator_slc_neg_9:
    dup
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s push_operator_slc_clamp_9
    pop
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
  push_operator_slc_clamp_9:
    stloc.s 4
    ldc.i4 1
    dup
    ldc.i4.0
    bge.s push_operator_slc_neg_10
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s push_operator_slc_neg_10
    pop
    ldc.i4.0
  push_operator_slc_neg_10:
    dup
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s push_operator_slc_clamp_10
    pop
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
  push_operator_slc_clamp_10:
    stloc.s 5
    ldloc.s 5
    ldloc.s 4
    sub
    dup
    ldc.i4.0
    bge.s push_operator_slc_cnt_11
    pop
    ldc.i4.0
  push_operator_slc_cnt_11:
    stloc.s 6
    ldloc.s 3
    ldloc.s 4
    ldloc.s 6
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    ldstr "f"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse push_operator_If8_else
    br push_operator_W5_end
  push_operator_If8_else:
    ldloc.s 3
    ldarg.s 2
    call int32 TKVApp::'should_pop'(string, string)
    ldc.i4 0
    ceq
    brfalse push_operator_If12_else
    br push_operator_W5_end
  push_operator_If12_else:
    ldarg.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4.1
    sub
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldarg.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4.1
    sub
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::RemoveAt(int32)
    pop
    ldarg.s 1
    ldstr "o"
    ldloc.s 3
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br push_operator_W5_start
  push_operator_W5_end:
    ldarg.s 0
    ldarg.s 2
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ret
  }
  .method public static int32 'pop_until_lparen'(class [mscorlib]System.Collections.Generic.List`1<string> 'ops', class [mscorlib]System.Collections.Generic.List`1<string> 'output') cil managed
  {
    .maxstack 10
    .locals init (string 'top', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
  pop_until_lparen_W1_start:
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 0
    cgt
    brfalse pop_until_lparen_W1_end
    ldarg.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 1
    sub.ovf
    dup
    ldc.i4.0
    bge.s pop_until_lparen_idx_pos_2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s pop_until_lparen_idx_end_2
  pop_until_lparen_idx_pos_2:
  pop_until_lparen_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 0
    ldloc.s 0
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse pop_until_lparen_If3_else
    ldc.i4 1
    ret
  pop_until_lparen_If3_else:
    ldarg.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4.1
    sub
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldarg.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4.1
    sub
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::RemoveAt(int32)
    pop
    ldarg.s 1
    ldstr "o"
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br pop_until_lparen_W1_start
  pop_until_lparen_W1_end:
    ldc.i4 0
    ret
  }
  .method public static int32 'close_paren'(class [mscorlib]System.Collections.Generic.List`1<string> 'ops', class [mscorlib]System.Collections.Generic.List`1<string> 'output') cil managed
  {
    .maxstack 11
    .locals init (int32 'found', string 'top', int32 '__slice2028382135424_start', int32 '__slice2028382135424_stop', int32 '__slice2028382135424_count', int32 '__slice2028382135664_start', int32 '__slice2028382135664_stop', int32 '__slice2028382135664_count', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    ldarg.s 1
    call int32 TKVApp::'pop_until_lparen'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    ceq
    brfalse close_paren_If1_else
    ldc.i4 0
    ret
  close_paren_If1_else:
    ldarg.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4.1
    sub
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldarg.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4.1
    sub
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::RemoveAt(int32)
    pop
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 0
    cgt
    brfalse close_paren_If2_else
    ldarg.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 1
    sub.ovf
    dup
    ldc.i4.0
    bge.s close_paren_idx_pos_3
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s close_paren_idx_end_3
  close_paren_idx_pos_3:
  close_paren_idx_end_3:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 1
    ldc.i4 0
    dup
    ldc.i4.0
    bge.s close_paren_slc_neg_5
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s close_paren_slc_neg_5
    pop
    ldc.i4.0
  close_paren_slc_neg_5:
    dup
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s close_paren_slc_clamp_5
    pop
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
  close_paren_slc_clamp_5:
    stloc.s 2
    ldc.i4 1
    dup
    ldc.i4.0
    bge.s close_paren_slc_neg_6
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s close_paren_slc_neg_6
    pop
    ldc.i4.0
  close_paren_slc_neg_6:
    dup
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s close_paren_slc_clamp_6
    pop
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
  close_paren_slc_clamp_6:
    stloc.s 3
    ldloc.s 3
    ldloc.s 2
    sub
    dup
    ldc.i4.0
    bge.s close_paren_slc_cnt_7
    pop
    ldc.i4.0
  close_paren_slc_cnt_7:
    stloc.s 4
    ldloc.s 1
    ldloc.s 2
    ldloc.s 4
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    ldstr "f"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse close_paren_If4_else
    ldarg.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4.1
    sub
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldarg.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4.1
    sub
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::RemoveAt(int32)
    pop
    ldarg.s 1
    ldstr "f"
    ldc.i4 1
    dup
    ldc.i4.0
    bge.s close_paren_slc_neg_8
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s close_paren_slc_neg_8
    pop
    ldc.i4.0
  close_paren_slc_neg_8:
    dup
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s close_paren_slc_clamp_8
    pop
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
  close_paren_slc_clamp_8:
    stloc.s 5
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    stloc.s 6
    ldloc.s 6
    ldloc.s 5
    sub
    dup
    ldc.i4.0
    bge.s close_paren_slc_cnt_9
    pop
    ldc.i4.0
  close_paren_slc_cnt_9:
    stloc.s 7
    ldloc.s 1
    ldloc.s 5
    ldloc.s 7
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  close_paren_If4_else:
  close_paren_If2_else:
    ldc.i4 1
    ret
  }
  .method public static int32 'flush_operators'(class [mscorlib]System.Collections.Generic.List`1<string> 'ops', class [mscorlib]System.Collections.Generic.List`1<string> 'output') cil managed
  {
    .maxstack 11
    .locals init (string 'top', int32 '__slice2028382140224_start', int32 '__slice2028382140224_stop', int32 '__slice2028382140224_count', int32 '__slice2028382140384_start', int32 '__slice2028382140384_stop', int32 '__slice2028382140384_count', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
  flush_operators_W1_start:
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 0
    cgt
    brfalse flush_operators_W1_end
    ldarg.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 1
    sub.ovf
    dup
    ldc.i4.0
    bge.s flush_operators_idx_pos_2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    add
    br.s flush_operators_idx_end_2
  flush_operators_idx_pos_2:
  flush_operators_idx_end_2:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 0
    ldloc.s 0
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse flush_operators_If3_else
    ldstr "thieu dau ')'"
    newobj instance void class ParseError::.ctor(string)
    throw
  flush_operators_If3_else:
    ldarg.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4.1
    sub
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldarg.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4.1
    sub
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::RemoveAt(int32)
    pop
    ldc.i4 0
    dup
    ldc.i4.0
    bge.s flush_operators_slc_neg_5
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s flush_operators_slc_neg_5
    pop
    ldc.i4.0
  flush_operators_slc_neg_5:
    dup
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s flush_operators_slc_clamp_5
    pop
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
  flush_operators_slc_clamp_5:
    stloc.s 1
    ldc.i4 1
    dup
    ldc.i4.0
    bge.s flush_operators_slc_neg_6
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s flush_operators_slc_neg_6
    pop
    ldc.i4.0
  flush_operators_slc_neg_6:
    dup
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s flush_operators_slc_clamp_6
    pop
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
  flush_operators_slc_clamp_6:
    stloc.s 2
    ldloc.s 2
    ldloc.s 1
    sub
    dup
    ldc.i4.0
    bge.s flush_operators_slc_cnt_7
    pop
    ldc.i4.0
  flush_operators_slc_cnt_7:
    stloc.s 3
    ldloc.s 0
    ldloc.s 1
    ldloc.s 3
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    ldstr "f"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse flush_operators_If4_else
    ldarg.s 1
    ldstr "f"
    ldc.i4 1
    dup
    ldc.i4.0
    bge.s flush_operators_slc_neg_8
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    dup
    ldc.i4.0
    bge.s flush_operators_slc_neg_8
    pop
    ldc.i4.0
  flush_operators_slc_neg_8:
    dup
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ble.s flush_operators_slc_clamp_8
    pop
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
  flush_operators_slc_clamp_8:
    stloc.s 4
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    stloc.s 5
    ldloc.s 5
    ldloc.s 4
    sub
    dup
    ldc.i4.0
    bge.s flush_operators_slc_cnt_9
    pop
    ldc.i4.0
  flush_operators_slc_cnt_9:
    stloc.s 6
    ldloc.s 0
    ldloc.s 4
    ldloc.s 6
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br flush_operators_If4_end
  flush_operators_If4_else:
    ldarg.s 1
    ldstr "o"
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  flush_operators_If4_end:
    br flush_operators_W1_start
  flush_operators_W1_end:
    ldarg.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
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
    .locals init (int32 'r', int32 '__strtmp2028381600832', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
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
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 4
    stloc.s 3
    ldloca.s 3
    ldfld object TkvInt::big
    brtrue read_assign_name_int4_slow
    ldloca.s 4
    ldfld object TkvInt::big
    brtrue read_assign_name_int4_slow
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
    blt read_assign_name_int4_slow
    ldloca.s 5
    ldloc.s 6
    stfld int64 TkvInt::lo
    ldloca.s 5
    ldnull
    stfld object TkvInt::big
    ldloc.s 5
    br read_assign_name_int4_done
  read_assign_name_int4_slow:
    ldloc.s 3
    ldloc.s 4
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  read_assign_name_int4_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stloc.s 1
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class Tok>::get_Count()
    clt
    ldc.i4.0
    ceq
    brfalse read_assign_name_If5_else
    ldstr ""
    ret
  read_assign_name_If5_else:
    ldarg.s 0
    ldloc.s 1
    dup
    ldc.i4.0
    bge.s read_assign_name_idx_pos_6
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class Tok>::get_Count()
    add
    br.s read_assign_name_idx_end_6
  read_assign_name_idx_pos_6:
  read_assign_name_idx_end_6:
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class Tok>::get_Item(int32)
    stloc.s 2
    ldloc.s 2
    ldfld string Tok::'kind'
    ldstr "ASSIGN"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse read_assign_name_If7_else
    ldstr ""
    ret
  read_assign_name_If7_else:
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
  .method public static string 'run_source'(string 'src', int32 'want_stats') cil managed
  {
    .maxstack 14
    .locals init (class [mscorlib]System.Collections.Generic.List`1<class Tok> 'toks', class TokCursor 'cur', class VarStore 'store', class Session 'session', class Stats 'stats', float64 'result', valuetype TkvInt 'produced', valuetype TkvInt 'guard', class Tok 'head', string 'target', class Shunter 'sh', class [mscorlib]System.Collections.Generic.List`1<string> 'code', class NumStack 'stack', class Machine 'machine', float64 'value', string 'line', int32 '__strtmp2028387823712', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    call class [mscorlib]System.Collections.Generic.List`1<class Tok> TKVApp::'tokenize'(string)
    stloc.s 0
    ldc.i4 0
    newobj instance void TokCursor::.ctor(int32)
    stloc.s 1
    ldc.i4 0
    ldc.i4 0
    newobj instance void VarStore::.ctor(int32, int32)
    stloc.s 2
    ldc.i4 0
    ldc.i4 0
    newobj instance void Session::.ctor(int32, int32)
    stloc.s 3
    ldc.i4 0
    ldc.i4 0
    ldc.i4 0
    ldc.i4 0
    ldc.i4 0
    ldc.i4 0
    newobj instance void Stats::.ctor(int32, int32, int32, int32, int32, int32)
    stloc.s 4
    ldc.r8 0.0
    stloc.s 5
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 7
  run_source_W1_start:
    ldloc.s 1
    ldloc.s 0
    callvirt instance int32 TokCursor::'at_end'(class [mscorlib]System.Collections.Generic.List`1<class Tok>)
    ldc.i4 0
    ceq
    brfalse run_source_W1_end
    ldloc.s 7
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 18
    stloc.s 17
    ldloca.s 17
    ldfld object TkvInt::big
    brtrue run_source_int2_slow
    ldloca.s 18
    ldfld object TkvInt::big
    brtrue run_source_int2_slow
    ldloca.s 17
    ldfld int64 TkvInt::lo
    ldloca.s 18
    ldfld int64 TkvInt::lo
    add
    stloc.s 20
    ldloca.s 17
    ldfld int64 TkvInt::lo
    ldloc.s 20
    xor
    ldloca.s 18
    ldfld int64 TkvInt::lo
    ldloc.s 20
    xor
    and
    ldc.i8 0
    blt run_source_int2_slow
    ldloca.s 19
    ldloc.s 20
    stfld int64 TkvInt::lo
    ldloca.s 19
    ldnull
    stfld object TkvInt::big
    ldloc.s 19
    br run_source_int2_done
  run_source_int2_slow:
    ldloc.s 17
    ldloc.s 18
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_source_int2_done:
    stloc.s 7
    ldloc.s 7
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
    stloc.s 8
    ldloc.s 8
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
    stloc.s 9
    ldc.i4 0
    ldc.i4 0
    newobj instance void Shunter::.ctor(int32, int32)
    stloc.s 10
    ldloc.s 0
    ldloc.s 1
    ldloc.s 10
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'to_postfix'(class [mscorlib]System.Collections.Generic.List`1<class Tok>, class TokCursor, class Shunter)
    stloc.s 11
    ldc.i4 0
    newobj instance void NumStack::.ctor(int32)
    stloc.s 12
    ldc.i4 0
    ldc.i4 0
    newobj instance void Machine::.ctor(int32, int32)
    stloc.s 13
    ldloc.s 13
    ldloc.s 11
    ldloc.s 2
    ldloc.s 12
    callvirt instance float64 Machine::'run'(class [mscorlib]System.Collections.Generic.List`1<string>, class VarStore, class NumStack)
    stloc.s 14
    ldloc.s 9
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse run_source_If5_else
    ldloc.s 2
    ldloc.s 9
    ldloc.s 14
    callvirt instance int32 VarStore::'assign'(string, float64)
    pop
  run_source_If5_else:
    ldloc.s 14
    stloc.s 5
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 6
    ldloc.s 3
    callvirt instance int32 Session::'note_stmt'()
    pop
    ldloc.s 4
    ldloc.s 4
    ldfld int32 Stats::'stmts'
    conv.i8
    call valuetype TkvInt TkvInt::FromI64(int64)
    ldc.i8 1
    call valuetype TkvInt TkvInt::FromI64(int64)
    stloc.s 18
    stloc.s 17
    ldloca.s 17
    ldfld object TkvInt::big
    brtrue run_source_int6_slow
    ldloca.s 18
    ldfld object TkvInt::big
    brtrue run_source_int6_slow
    ldloca.s 17
    ldfld int64 TkvInt::lo
    ldloca.s 18
    ldfld int64 TkvInt::lo
    add
    stloc.s 20
    ldloca.s 17
    ldfld int64 TkvInt::lo
    ldloc.s 20
    xor
    ldloca.s 18
    ldfld int64 TkvInt::lo
    ldloc.s 20
    xor
    and
    ldc.i8 0
    blt run_source_int6_slow
    ldloca.s 19
    ldloc.s 20
    stfld int64 TkvInt::lo
    ldloca.s 19
    ldnull
    stfld object TkvInt::big
    ldloc.s 19
    br run_source_int6_done
  run_source_int6_slow:
    ldloc.s 17
    ldloc.s 18
    call valuetype TkvInt TkvInt::AddSlow(valuetype TkvInt, valuetype TkvInt)
  run_source_int6_done:
    call int32 TkvInt::ToI32(valuetype TkvInt)
    stfld int32 Stats::'stmts'
    ldloc.s 4
    ldloc.s 10
    callvirt instance int32 Stats::'absorb_shunter'(class Shunter)
    pop
    ldloc.s 4
    ldloc.s 13
    callvirt instance int32 Stats::'absorb_machine'(class Machine)
    pop
    ldloc.s 4
    ldloc.s 12
    callvirt instance int32 Stats::'absorb_stack'(class NumStack)
    pop
    br run_source_W1_start
  run_source_W1_end:
    ldloc.s 6
    ldc.i8 0
    call valuetype TkvInt TkvInt::FromI64(int64)
    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)
    ldc.i4.0
    ceq
    brfalse run_source_If7_else
    ldstr "khong co cau lenh nao"
    newobj instance void class ParseError::.ctor(string)
    throw
  run_source_If7_else:
    ldloc.s 5
    call string TKVApp::'fmt_value'(float64)
    stloc.s 15
    ldarg.s 1
    ldc.i4 1
    ceq
    brfalse run_source_If8_else
    ldloc.s 15
    ldstr " | "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 4
    callvirt instance string Stats::'render'()
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " | bien="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 2
    callvirt instance int32 VarStore::'count'()
    call string TkvStr::I32(int32)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 15
  run_source_If8_else:
    ldloc.s 15
    ret
  }
  .method public static string 'render_vars'(class VarStore 'store') cil managed
  {
    .maxstack 9
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance string VarStore::'render'()
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
  .method public static string 'describe_postfix'(string 'src') cil managed
  {
    .maxstack 11
    .locals init (class [mscorlib]System.Collections.Generic.List`1<class Tok> 'toks', class TokCursor 'cur', string 'target', class Shunter 'sh', class [mscorlib]System.Collections.Generic.List`1<string> 'code', string 'body', valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    call class [mscorlib]System.Collections.Generic.List`1<class Tok> TKVApp::'tokenize'(string)
    stloc.s 0
    ldc.i4 0
    newobj instance void TokCursor::.ctor(int32)
    stloc.s 1
    ldloc.s 0
    ldloc.s 1
    call string TKVApp::'read_assign_name'(class [mscorlib]System.Collections.Generic.List`1<class Tok>, class TokCursor)
    stloc.s 2
    ldc.i4 0
    ldc.i4 0
    newobj instance void Shunter::.ctor(int32, int32)
    stloc.s 3
    ldloc.s 0
    ldloc.s 1
    ldloc.s 3
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'to_postfix'(class [mscorlib]System.Collections.Generic.List`1<class Tok>, class TokCursor, class Shunter)
    stloc.s 4
    ldstr " "
    ldloc.s 4
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    stloc.s 5
    ldloc.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse describe_postfix_If1_else
    ldloc.s 2
    ldstr " := "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 5
    call string [mscorlib]System.String::Concat(string, string)
    ret
  describe_postfix_If1_else:
    ldloc.s 5
    ret
  }
  .method public static string 'classify_error'(class CalcError 'e') cil managed
  {
    .maxstack 9
    .locals init (valuetype TkvInt '__tkvint_a', valuetype TkvInt '__tkvint_b', valuetype TkvInt '__tkvint_r', int64 '__tkvint_x')
    ldarg.s 0
    callvirt instance string CalcError::'render'()
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
    ldarg.s 1
    ldstr "postfix"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse evaluate_If3_else
    ldarg.s 0
    call string TKVApp::'describe_postfix'(string)
    stloc.s 1
    leave evaluate_epilogue
  evaluate_If3_else:
    ldarg.s 1
    ldstr "stats"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse evaluate_If4_else
    ldarg.s 0
    ldc.i4 1
    call string TKVApp::'run_source'(string, int32)
    stloc.s 1
    leave evaluate_epilogue
  evaluate_If4_else:
    ldarg.s 0
    ldc.i4 0
    call string TKVApp::'run_source'(string, int32)
    stloc.s 1
    leave evaluate_epilogue
    }
    catch class LexError
    {
      stloc.s 0
    ldloc.s 0
    call string TKVApp::'classify_error'(class CalcError)
    stloc.s 1
    leave evaluate_epilogue
    }
    catch class ParseError
    {
      stloc.s 0
    ldloc.s 0
    call string TKVApp::'classify_error'(class CalcError)
    stloc.s 1
    leave evaluate_epilogue
    }
    catch class EvalError
    {
      stloc.s 0
    ldloc.s 0
    call string TKVApp::'classify_error'(class CalcError)
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
    ldarg.0
    ldc.i4 1
    ldelem.ref
    call string TKVApp::'main'(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ret
  }
}
