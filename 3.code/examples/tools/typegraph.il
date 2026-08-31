.assembly extern mscorlib {}
.assembly extern System.Core { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly extern System { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly TKVApp {}
.module TKVApp.exe

.class public auto ansi TKVApp extends [mscorlib]System.Object
{
  .method public static string 'kw_blob'() cil managed
  {
    .maxstack 8
    ldstr "|if|for|while|return|and|or|not|in|is|None|True|False|print|len|str|int|float|list|dict|set|tuple|range|super|type|isinstance|open|sorted|enumerate|zip|map|filter|sum|min|max|abs|any|all|repr|getattr|setattr|hasattr|format|"
    ret
  }
  .method public static int32 'is_keyword'(string 'name') cil managed
  {
    .maxstack 8
    .locals init (string 'blob')
    call string TKVApp::'kw_blob'()
    stloc.s 0
    ldloc.s 0
    ldstr "|"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse is_keyword_If1_else
    ldc.i4 1
    ret
  is_keyword_If1_else:
    ldc.i4 0
    ret
  }
  .method public static string 'node_id'(string 'kind', string 'rel', string 'name') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static string 'method_id'(string 'rel', string 'owner', string 'name') cil managed
  {
    .maxstack 8
    ldarg.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse method_id_If1_else
    ldstr "function"
    ldarg.s 0
    ldarg.s 2
    call string TKVApp::'node_id'(string, string, string)
    ret
  method_id_If1_else:
    ldstr "function"
    ldarg.s 0
    ldarg.s 1
    ldstr "."
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 2
    call string [mscorlib]System.String::Concat(string, string)
    call string TKVApp::'node_id'(string, string, string)
    ret
  }
  .method public static string 'owner_of'(string 'rel', string 'name', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'tab') cil managed
  {
    .maxstack 8
    ldarg.s 2
    ldstr "O#"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse owner_of_dget1_miss
    ldarg.s 2
    ldstr "O#"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br owner_of_dget1_end
  owner_of_dget1_miss:
    ldstr ""
  owner_of_dget1_end:
    ret
  }
  .method public static string 'typed_edge'(string 'src', string 'dst', string 'kind', string 'w') cil managed
  {
    .maxstack 8
    ldstr "{\"source\":\""
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\",\"target\":\""
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\",\"type\":\""
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\",\"weight\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 3
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "}"
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static int32 'has_def'(string 'defs_blob', string 'name') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr "|"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse has_def_If1_else
    ldc.i4 1
    ret
  has_def_If1_else:
    ldc.i4 0
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'scope_files'(string 'rel', string 'imports_blob') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', class [mscorlib]System.Collections.Generic.List`1<string> 'parts', int32 '__iterlist0_idx', string 'p')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldloc.s 0
    ldarg.s 0
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldarg.s 1
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
    stloc.s 1
    ldc.i4.0
    stloc.s 2
  scope_files_L1_start:
    ldloc.s 2
    ldloc.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge scope_files_L1_end
    ldloc.s 1
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 3
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse scope_files_If2_else
    ldloc.s 0
    ldloc.s 3
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  scope_files_If2_else:
  scope_files_L1_cont:
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    br scope_files_L1_start
  scope_files_L1_end:
    ldloc.s 0
    ret
  }
  .method public static string 'resolve_name'(string 'name', class [mscorlib]System.Collections.Generic.List`1<string> 'scope', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'tab') cil managed
  {
    .maxstack 8
    .locals init (int32 'hits', string 'found', int32 '__iterlist1_idx', string 'f', string 'blob')
    ldc.i4 0
    stloc.s 0
    ldstr ""
    stloc.s 1
    ldc.i4.0
    stloc.s 2
  resolve_name_L1_start:
    ldloc.s 2
    ldarg.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge resolve_name_L1_end
    ldarg.s 1
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 3
    ldarg.s 2
    ldstr "D#"
    ldloc.s 3
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse resolve_name_dget2_miss
    ldarg.s 2
    ldstr "D#"
    ldloc.s 3
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br resolve_name_dget2_end
  resolve_name_dget2_miss:
    ldstr ""
  resolve_name_dget2_end:
    stloc.s 4
    ldloc.s 4
    ldarg.s 0
    call int32 TKVApp::'has_def'(string, string)
    ldc.i4 1
    ceq
    brfalse resolve_name_If3_else
    ldloc.s 3
    ldloc.s 1
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse resolve_name_If4_else
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    ldloc.s 3
    stloc.s 1
  resolve_name_If4_else:
  resolve_name_If3_else:
  resolve_name_L1_cont:
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    br resolve_name_L1_start
  resolve_name_L1_end:
    ldloc.s 0
    ldc.i4 0
    ceq
    brfalse resolve_name_If5_else
    ldstr ""
    ret
  resolve_name_If5_else:
    ldloc.s 0
    ldc.i4 1
    cgt
    brfalse resolve_name_If6_else
    call string TKVApp::'ambig_mark'()
    ret
  resolve_name_If6_else:
    ldloc.s 1
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'build_imports'(class [mscorlib]System.Collections.Generic.List`1<string> 'paths', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'base_idx') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'out', int32 '__iterlist2_idx', string 'rel', string 'acc', class [mscorlib]System.Collections.Generic.List`1<string> 'results', int32 '__iterlist3_idx', string 'res', string 'kind', string 'target', int32 '__slice2642320851408_start')
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 0
    ldc.i4.0
    stloc.s 1
  build_imports_L1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge build_imports_L1_end
    ldarg.s 0
    ldloc.s 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 2
    ldstr ""
    stloc.s 3
    ldloc.s 2
    ldarg.s 1
    ldarg.s 2
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'scan_file'(string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 4
    ldc.i4.0
    stloc.s 5
  build_imports_L2_start:
    ldloc.s 5
    ldloc.s 4
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge build_imports_L2_end
    ldloc.s 4
    ldloc.s 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 6
    ldloc.s 6
    ldstr "|"
    call string TKVApp::'cut_at'(string, string)
    stloc.s 7
    ldloc.s 7
    ldstr "internal"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse build_imports_If3_else
    ldloc.s 7
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 1
    add
    stloc.s 9
    ldloc.s 6
    ldloc.s 9
    ldloc.s 6
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 9
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 8
    ldloc.s 3
    ldstr "|"
    ldloc.s 8
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    brfalse build_imports_If4_else
    ldloc.s 3
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 8
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 3
  build_imports_If4_else:
  build_imports_If3_else:
  build_imports_L2_cont:
    ldloc.s 5
    ldc.i4 1
    add
    stloc.s 5
    br build_imports_L2_start
  build_imports_L2_end:
    ldloc.s 0
    ldloc.s 2
    ldloc.s 3
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  build_imports_L1_cont:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br build_imports_L1_start
  build_imports_L1_end:
    ldloc.s 0
    ret
  }
  .method public static string 'join_edges'(class [mscorlib]System.Collections.Generic.List`1<string> 'edges') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'pieces', int32 'i')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldc.i4 0
    stloc.s 1
  join_edges_W1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse join_edges_W1_end
    ldloc.s 0
    ldstr "  "
    ldarg.s 0
    ldloc.s 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br join_edges_W1_start
  join_edges_W1_end:
    ldstr ",\n"
    ldloc.s 0
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    ret
  }
  .method public static string 'tok_kind'(string 'row') cil managed
  {
    .maxstack 8
    .locals init (string 'rest', int32 '__slice2642320854288_start')
    ldarg.s 0
    ldstr "\t"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 1
    add
    stloc.s 1
    ldarg.s 0
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 1
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 0
    ldloc.s 0
    ldstr "\t"
    call string TKVApp::'cut_at'(string, string)
    ret
  }
  .method public static string 'tok_text'(string 'row') cil managed
  {
    .maxstack 8
    .locals init (int32 'at', string 'rest', int32 '__slice2642320716992_start', int32 'at2', int32 '__slice2642320851968_start')
    ldarg.s 0
    ldstr "\t"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 0
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 2
    ldarg.s 0
    ldloc.s 2
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 2
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 1
    ldloc.s 1
    ldstr "\t"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 3
    ldloc.s 3
    ldc.i4 0
    clt
    brfalse tok_text_If1_else
    ldstr ""
    ret
  tok_text_If1_else:
    ldloc.s 3
    ldc.i4 1
    add
    stloc.s 4
    ldloc.s 1
    ldloc.s 4
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 4
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    ret
  }
  .method public static int32 'tok_indent'(string 'row') cil managed
  {
    .maxstack 8
    ldarg.s 0
    call string TKVApp::'tok_text'(string)
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call int32 [mscorlib]System.Int32::Parse(string, class [mscorlib]System.IFormatProvider)
    ret
  }
  .method public static int32 'tok_line'(string 'row') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr "\t"
    call string TKVApp::'cut_at'(string, string)
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call int32 [mscorlib]System.Int32::Parse(string, class [mscorlib]System.IFormatProvider)
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'file_tokens'(string 'rel') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', string 'src')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldarg.s 0
    call string [mscorlib]System.IO.File::ReadAllText(string)
    stloc.s 1
    ldloc.s 1
    ldloc.s 0
    call int32 TKVApp::'tokenize'(string, class [mscorlib]System.Collections.Generic.List`1<string>)
    pop
    ldloc.s 0
    ret
  }
  .method public static string 'name_at'(class [mscorlib]System.Collections.Generic.List`1<string> 'rows', int32 'i') cil managed
  {
    .maxstack 8
    .locals init (string 'k')
    ldarg.s 1
    ldc.i4 0
    clt
    brfalse name_at_If1_else
    ldstr ""
    ret
  name_at_If1_else:
    ldarg.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    ldc.i4.0
    ceq
    brfalse name_at_If2_else
    ldstr ""
    ret
  name_at_If2_else:
    ldarg.s 0
    ldarg.s 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_kind'(string)
    stloc.s 0
    ldloc.s 0
    ldstr "NAME"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse name_at_If3_else
    ldstr ""
    ret
  name_at_If3_else:
    ldarg.s 0
    ldarg.s 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_text'(string)
    ret
  }
  .method public static string 'op_at'(class [mscorlib]System.Collections.Generic.List`1<string> 'rows', int32 'i') cil managed
  {
    .maxstack 8
    .locals init (string 'k')
    ldarg.s 1
    ldc.i4 0
    clt
    brfalse op_at_If1_else
    ldstr ""
    ret
  op_at_If1_else:
    ldarg.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    ldc.i4.0
    ceq
    brfalse op_at_If2_else
    ldstr ""
    ret
  op_at_If2_else:
    ldarg.s 0
    ldarg.s 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_kind'(string)
    stloc.s 0
    ldloc.s 0
    ldstr "OP"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse op_at_If3_else
    ldstr ""
    ret
  op_at_If3_else:
    ldarg.s 0
    ldarg.s 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_text'(string)
    ret
  }
  .method public static string 'blob_add'(string 'blob', string 'key', string 'val') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr "|"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "="
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse blob_add_If1_else
    ldarg.s 0
    ret
  blob_add_If1_else:
    ldarg.s 0
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "="
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static string 'blob_get'(string 'blob', string 'key') cil managed
  {
    .maxstack 8
    .locals init (string 'pat', int32 'at', string 'rest', int32 '__slice2642320716192_start')
    ldstr "|"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "="
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
    ldarg.s 0
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 1
    ldloc.s 1
    ldc.i4 0
    clt
    brfalse blob_get_If1_else
    ldstr ""
    ret
  blob_get_If1_else:
    ldloc.s 1
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    add
    stloc.s 3
    ldarg.s 0
    ldloc.s 3
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 3
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 2
    ldloc.s 2
    ldstr "|"
    call string TKVApp::'cut_at'(string, string)
    ret
  }
  .method public static string 'collect_defs_tok'(class [mscorlib]System.Collections.Generic.List`1<string> 'rows') cil managed
  {
    .maxstack 8
    .locals init (string 'acc', int32 'i', string 'w', int32 'keep', string 'nm')
    ldstr "|"
    stloc.s 0
    ldc.i4 0
    stloc.s 1
  collect_defs_tok_W1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse collect_defs_tok_W1_end
    ldarg.s 0
    ldloc.s 1
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 2
    ldc.i4 0
    stloc.s 3
    ldloc.s 2
    ldstr "def"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse collect_defs_tok_If2_else
    ldc.i4 1
    stloc.s 3
  collect_defs_tok_If2_else:
    ldloc.s 2
    ldstr "class"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse collect_defs_tok_If3_else
    ldc.i4 1
    stloc.s 3
  collect_defs_tok_If3_else:
    ldloc.s 3
    ldc.i4 1
    ceq
    brfalse collect_defs_tok_If4_else
    ldarg.s 0
    ldloc.s 1
    ldc.i4 1
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 4
    ldloc.s 4
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse collect_defs_tok_If5_else
    ldloc.s 0
    ldstr "|"
    ldloc.s 4
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    brfalse collect_defs_tok_If6_else
    ldloc.s 0
    ldloc.s 4
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
  collect_defs_tok_If6_else:
  collect_defs_tok_If5_else:
  collect_defs_tok_If4_else:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br collect_defs_tok_W1_start
  collect_defs_tok_W1_end:
    ldloc.s 0
    ret
  }
  .method public static int32 'class_methods_tab'(class [mscorlib]System.Collections.Generic.List`1<string> 'rows', string 'rel', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'out') cil managed
  {
    .maxstack 8
    .locals init (int32 'n', string 'cur', class [mscorlib]System.Collections.Generic.List`1<string> 'cls_names', class [mscorlib]System.Collections.Generic.List`1<int32> 'cls_inds', int32 'cdepth', int32 'i', string 'kk', int32 'ind', string 'w', string 'nm', string 'opc2', string 'par2', string 'blob')
    ldc.i4 0
    stloc.s 0
    ldstr ""
    stloc.s 1
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 2
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<int32>::.ctor()
    stloc.s 3
    ldc.i4 0
    stloc.s 4
    ldc.i4 0
    stloc.s 5
  class_methods_tab_W1_start:
    ldloc.s 5
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse class_methods_tab_W1_end
    ldarg.s 0
    ldloc.s 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_kind'(string)
    stloc.s 6
    ldloc.s 6
    ldstr "BOL"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse class_methods_tab_If2_else
    ldarg.s 0
    ldloc.s 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call int32 TKVApp::'tok_indent'(string)
    stloc.s 7
    ldarg.s 0
    ldloc.s 5
    ldc.i4 1
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 8
    ldloc.s 3
    ldloc.s 4
    ldloc.s 7
    call int32 TKVApp::'stack_pop_to'(class [mscorlib]System.Collections.Generic.List`1<int32>, int32, int32)
    stloc.s 4
    ldloc.s 2
    ldloc.s 4
    call string TKVApp::'stack_top'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 1
    ldloc.s 8
    ldstr "class"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse class_methods_tab_If3_else
    ldarg.s 0
    ldloc.s 5
    ldc.i4 2
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 9
    ldloc.s 9
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse class_methods_tab_If4_else
    ldloc.s 9
    stloc.s 1
    ldloc.s 2
    ldloc.s 3
    ldloc.s 4
    ldloc.s 9
    ldloc.s 7
    call int32 TKVApp::'stack_push'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<int32>, int32, string, int32)
    stloc.s 4
    ldarg.s 2
    ldstr "M#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 9
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse class_methods_tab_dget6_miss
    ldarg.s 2
    ldstr "M#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 9
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br class_methods_tab_dget6_end
  class_methods_tab_dget6_miss:
    ldstr ""
  class_methods_tab_dget6_end:
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse class_methods_tab_If5_else
    ldarg.s 2
    ldstr "M#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 9
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "|"
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
  class_methods_tab_If5_else:
    ldarg.s 0
    ldloc.s 5
    ldc.i4 3
    add
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 10
    ldloc.s 10
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse class_methods_tab_If7_else
    ldarg.s 0
    ldloc.s 5
    ldc.i4 4
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 11
    ldloc.s 11
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse class_methods_tab_If8_else
    ldarg.s 2
    ldstr "P#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 9
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 11
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  class_methods_tab_If8_else:
  class_methods_tab_If7_else:
  class_methods_tab_If4_else:
    br class_methods_tab_If3_end
  class_methods_tab_If3_else:
    ldloc.s 8
    ldstr "def"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse class_methods_tab_If9_else
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse class_methods_tab_If10_else
    ldarg.s 0
    ldloc.s 5
    ldc.i4 2
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 9
    ldloc.s 9
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse class_methods_tab_If11_else
    ldarg.s 2
    ldstr "M#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse class_methods_tab_dget12_miss
    ldarg.s 2
    ldstr "M#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br class_methods_tab_dget12_end
  class_methods_tab_dget12_miss:
    ldstr "|"
  class_methods_tab_dget12_end:
    stloc.s 12
    ldloc.s 12
    ldstr "|"
    ldloc.s 9
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    brfalse class_methods_tab_If13_else
    ldarg.s 2
    ldstr "M#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    ldloc.s 9
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  class_methods_tab_If13_else:
    ldarg.s 2
    ldstr "O#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 9
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse class_methods_tab_dget15_miss
    ldarg.s 2
    ldstr "O#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 9
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br class_methods_tab_dget15_end
  class_methods_tab_dget15_miss:
    ldstr ""
  class_methods_tab_dget15_end:
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse class_methods_tab_If14_else
    ldarg.s 2
    ldstr "O#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 9
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  class_methods_tab_If14_else:
  class_methods_tab_If11_else:
  class_methods_tab_If10_else:
  class_methods_tab_If9_else:
  class_methods_tab_If3_end:
  class_methods_tab_If2_else:
    ldloc.s 5
    ldc.i4 1
    add
    stloc.s 5
    br class_methods_tab_W1_start
  class_methods_tab_W1_end:
    ldloc.s 0
    ret
  }
  .method public static int32 'stack_pop_to'(class [mscorlib]System.Collections.Generic.List`1<int32> 'inds', int32 'depth', int32 'ind') cil managed
  {
    .maxstack 8
    .locals init (int32 'd', int32 'go')
    ldarg.s 1
    stloc.s 0
    ldc.i4 1
    stloc.s 1
  stack_pop_to_W1_start:
    ldloc.s 1
    ldc.i4 1
    ceq
    brfalse stack_pop_to_W1_end
    ldc.i4 0
    stloc.s 1
    ldloc.s 0
    ldc.i4 0
    cgt
    brfalse stack_pop_to_If2_else
    ldarg.s 0
    ldloc.s 0
    ldc.i4 1
    sub
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldarg.s 2
    clt
    ldc.i4.0
    ceq
    brfalse stack_pop_to_If3_else
    ldloc.s 0
    ldc.i4 1
    sub
    stloc.s 0
    ldc.i4 1
    stloc.s 1
  stack_pop_to_If3_else:
  stack_pop_to_If2_else:
    br stack_pop_to_W1_start
  stack_pop_to_W1_end:
    ldloc.s 0
    ret
  }
  .method public static string 'stack_top'(class [mscorlib]System.Collections.Generic.List`1<string> 'names', int32 'depth') cil managed
  {
    .maxstack 8
    ldarg.s 1
    ldc.i4 0
    ceq
    brfalse stack_top_If1_else
    ldstr ""
    ret
  stack_top_If1_else:
    ldarg.s 0
    ldarg.s 1
    ldc.i4 1
    sub
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ret
  }
  .method public static int32 'stack_push'(class [mscorlib]System.Collections.Generic.List`1<string> 'names', class [mscorlib]System.Collections.Generic.List`1<int32> 'inds', int32 'depth', string 'nm', int32 'ind') cil managed
  {
    .maxstack 8
    ldarg.s 2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse stack_push_If1_else
    ldarg.s 0
    ldarg.s 2
    ldarg.s 3
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::set_Item(int32, !0)
    ldarg.s 1
    ldarg.s 2
    ldarg.s 4
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldarg.s 2
    ldc.i4 1
    add
    ret
  stack_push_If1_else:
    ldarg.s 0
    ldarg.s 3
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldarg.s 1
    ldarg.s 4
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::Add(!0)
    ldarg.s 2
    ldc.i4 1
    add
    ret
  }
  .method public static int32 'local_types_tab'(class [mscorlib]System.Collections.Generic.List`1<string> 'rows', string 'rel', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'out') cil managed
  {
    .maxstack 8
    .locals init (string 'fn', string 'cls', class [mscorlib]System.Collections.Generic.List`1<string> 'fn_names', class [mscorlib]System.Collections.Generic.List`1<int32> 'fn_inds', int32 'depth', class [mscorlib]System.Collections.Generic.List`1<string> 'cls_names', class [mscorlib]System.Collections.Generic.List`1<int32> 'cls_inds', int32 'cdepth', int32 'i', string 'kind', int32 'ind', string 'w', int32 'j', string 'kj', string 'pn', string 'tn', string 'op1', string 'cn', string 'op3', string 'var', string 'opm', string 'nm2')
    ldstr ""
    stloc.s 0
    ldstr ""
    stloc.s 1
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 2
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<int32>::.ctor()
    stloc.s 3
    ldc.i4 0
    stloc.s 4
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 5
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<int32>::.ctor()
    stloc.s 6
    ldc.i4 0
    stloc.s 7
    ldc.i4 0
    stloc.s 8
  local_types_tab_W1_start:
    ldloc.s 8
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse local_types_tab_W1_end
    ldarg.s 0
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_kind'(string)
    stloc.s 9
    ldloc.s 9
    ldstr "BOL"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse local_types_tab_If2_else
    ldarg.s 0
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call int32 TKVApp::'tok_indent'(string)
    stloc.s 10
    ldarg.s 0
    ldloc.s 8
    ldc.i4 1
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 11
    ldloc.s 3
    ldloc.s 4
    ldloc.s 10
    call int32 TKVApp::'stack_pop_to'(class [mscorlib]System.Collections.Generic.List`1<int32>, int32, int32)
    stloc.s 4
    ldloc.s 2
    ldloc.s 4
    call string TKVApp::'stack_top'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 0
    ldloc.s 6
    ldloc.s 7
    ldloc.s 10
    call int32 TKVApp::'stack_pop_to'(class [mscorlib]System.Collections.Generic.List`1<int32>, int32, int32)
    stloc.s 7
    ldloc.s 5
    ldloc.s 7
    call string TKVApp::'stack_top'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 1
    ldloc.s 11
    ldstr "class"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse local_types_tab_If3_else
    ldarg.s 0
    ldloc.s 8
    ldc.i4 2
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 1
    ldloc.s 5
    ldloc.s 6
    ldloc.s 7
    ldloc.s 1
    ldloc.s 10
    call int32 TKVApp::'stack_push'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<int32>, int32, string, int32)
    stloc.s 7
    br local_types_tab_If3_end
  local_types_tab_If3_else:
    ldloc.s 11
    ldstr "def"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse local_types_tab_If4_else
    ldarg.s 0
    ldloc.s 8
    ldc.i4 2
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 0
    ldloc.s 2
    ldloc.s 3
    ldloc.s 4
    ldloc.s 0
    ldloc.s 10
    call int32 TKVApp::'stack_push'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<int32>, int32, string, int32)
    stloc.s 4
    ldloc.s 8
    ldc.i4 3
    add
    stloc.s 12
  local_types_tab_W5_start:
    ldloc.s 12
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse local_types_tab_W5_end
    ldarg.s 0
    ldloc.s 12
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_kind'(string)
    stloc.s 13
    ldloc.s 13
    ldstr "BOL"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse local_types_tab_If6_else
    br local_types_tab_W5_end
  local_types_tab_If6_else:
    ldarg.s 0
    ldloc.s 12
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    ldstr ":"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse local_types_tab_If7_else
    ldarg.s 0
    ldloc.s 12
    ldc.i4 1
    sub
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 14
    ldarg.s 0
    ldloc.s 12
    ldc.i4 1
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 15
    ldloc.s 14
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    dup
    brfalse local_types_tab_sc9_end
    pop
    ldloc.s 15
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
  local_types_tab_sc9_end:
    brfalse local_types_tab_If8_else
    ldloc.s 15
    call int32 TKVApp::'is_keyword'(string)
    ldc.i4 0
    ceq
    brfalse local_types_tab_If10_else
    ldarg.s 2
    ldstr "L#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 14
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 15
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  local_types_tab_If10_else:
  local_types_tab_If8_else:
  local_types_tab_If7_else:
    ldloc.s 12
    ldc.i4 1
    add
    stloc.s 12
    br local_types_tab_W5_start
  local_types_tab_W5_end:
  local_types_tab_If4_else:
  local_types_tab_If3_end:
  local_types_tab_If2_else:
    ldloc.s 9
    ldstr "NAME"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse local_types_tab_If11_else
    ldarg.s 0
    ldloc.s 8
    ldc.i4 1
    add
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 16
    ldloc.s 16
    ldstr "="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse local_types_tab_If12_else
    ldarg.s 0
    ldloc.s 8
    ldc.i4 2
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 17
    ldloc.s 17
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse local_types_tab_If13_else
    ldarg.s 0
    ldloc.s 8
    ldc.i4 3
    add
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 18
    ldloc.s 18
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse local_types_tab_If14_else
    ldloc.s 17
    call int32 TKVApp::'is_keyword'(string)
    ldc.i4 0
    ceq
    brfalse local_types_tab_If15_else
    ldarg.s 0
    ldloc.s 8
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_text'(string)
    stloc.s 19
    ldloc.s 19
    ldstr "self"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse local_types_tab_If16_else
    ldstr ""
    stloc.s 19
  local_types_tab_If16_else:
    ldloc.s 19
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse local_types_tab_If17_else
    ldarg.s 0
    ldloc.s 8
    ldc.i4 1
    sub
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 20
    ldloc.s 20
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse local_types_tab_If18_else
    ldarg.s 0
    ldloc.s 8
    ldc.i4 2
    sub
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 21
    ldloc.s 21
    ldstr "self"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse local_types_tab_If19_else
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse local_types_tab_If20_else
    ldarg.s 2
    ldstr "L#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 19
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 17
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  local_types_tab_If20_else:
  local_types_tab_If19_else:
    br local_types_tab_If18_end
  local_types_tab_If18_else:
    ldarg.s 2
    ldstr "L#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 19
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 17
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  local_types_tab_If18_end:
  local_types_tab_If17_else:
  local_types_tab_If15_else:
  local_types_tab_If14_else:
  local_types_tab_If13_else:
  local_types_tab_If12_else:
  local_types_tab_If11_else:
    ldloc.s 8
    ldc.i4 1
    add
    stloc.s 8
    br local_types_tab_W1_start
  local_types_tab_W1_end:
    ldc.i4 0
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'from_names'(string 'line') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', int32 'at', string 'rest', int32 '__slice2642320715392_start', class [mscorlib]System.Collections.Generic.List`1<string> 'parts', int32 '__iterlist4_idx', string 'p', string 'nm', string 'nm2')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldarg.s 0
    ldstr " import "
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 1
    ldloc.s 1
    ldc.i4 0
    clt
    brfalse from_names_If1_else
    ldloc.s 0
    ret
  from_names_If1_else:
    ldloc.s 1
    ldc.i4 8
    add
    stloc.s 3
    ldarg.s 0
    ldloc.s 3
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 3
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 2
    ldloc.s 2
    ldc.i4.1
    newarr [mscorlib]System.Char
    dup
    ldc.i4.0
    ldstr ","
    ldc.i4.0
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    stelem.i2
    callvirt instance string[] [mscorlib]System.String::Split(char[])
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
    stloc.s 4
    ldc.i4.0
    stloc.s 5
  from_names_L2_start:
    ldloc.s 5
    ldloc.s 4
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge from_names_L2_end
    ldloc.s 4
    ldloc.s 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 6
    ldloc.s 6
    callvirt instance string [mscorlib]System.String::Trim()
    stloc.s 7
    ldloc.s 7
    ldstr " "
    call string TKVApp::'cut_at'(string, string)
    stloc.s 8
    ldloc.s 8
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse from_names_If3_else
    ldloc.s 0
    ldloc.s 8
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  from_names_If3_else:
  from_names_L2_cont:
    ldloc.s 5
    ldc.i4 1
    add
    stloc.s 5
    br from_names_L2_start
  from_names_L2_end:
    ldloc.s 0
    ret
  }
  .method public static string 'from_module'(string 'line') cil managed
  {
    .maxstack 8
    .locals init (string 'rest', int32 '__slice2642320715152_start')
    ldarg.s 0
    ldstr "from "
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    ldc.i4.0
    ceq
    brfalse from_module_If1_else
    ldstr ""
    ret
  from_module_If1_else:
    ldc.i4 5
    stloc.s 1
    ldarg.s 0
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 1
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 0
    ldloc.s 0
    ldstr " "
    call string TKVApp::'cut_at'(string, string)
    ret
  }
  .method public static int32 'module_alias_tab'(class [mscorlib]System.Collections.Generic.List`1<string> 'rows', string 'rel', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'base_idx', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'out') cil managed
  {
    .maxstack 8
    .locals init (int32 'i', string 'kk', string 'w', int32 'imp', class [mscorlib]System.Collections.Generic.List`1<string> 'parts', int32 'j', string 'kj', string 'k2', string 'line', class [mscorlib]System.Collections.Generic.List`1<string> 'mods', int32 '__iterlist5_idx', string 'm', string 'hit', string 'fm', class [mscorlib]System.Collections.Generic.List`1<string> 'names', int32 '__iterlist6_idx', string 'nm', string 'cand', string 'hit2')
    ldc.i4 0
    stloc.s 0
  module_alias_tab_W1_start:
    ldloc.s 0
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse module_alias_tab_W1_end
    ldarg.s 0
    ldloc.s 0
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_kind'(string)
    stloc.s 1
    ldloc.s 1
    ldstr "BOL"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse module_alias_tab_If2_else
    ldarg.s 0
    ldloc.s 0
    ldc.i4 1
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 2
    ldc.i4 0
    stloc.s 3
    ldloc.s 2
    ldstr "import"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse module_alias_tab_If3_else
    ldc.i4 1
    stloc.s 3
  module_alias_tab_If3_else:
    ldloc.s 2
    ldstr "from"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse module_alias_tab_If4_else
    ldc.i4 1
    stloc.s 3
  module_alias_tab_If4_else:
    ldloc.s 3
    ldc.i4 1
    ceq
    brfalse module_alias_tab_If5_else
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 4
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 5
  module_alias_tab_W6_start:
    ldloc.s 5
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse module_alias_tab_W6_end
    ldarg.s 0
    ldloc.s 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_kind'(string)
    stloc.s 6
    ldloc.s 6
    ldstr "BOL"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse module_alias_tab_If7_else
    br module_alias_tab_W6_end
  module_alias_tab_If7_else:
    ldarg.s 0
    ldloc.s 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_kind'(string)
    stloc.s 7
    ldloc.s 7
    ldstr "NAME"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse module_alias_tab_If8_else
    ldloc.s 4
    ldarg.s 0
    ldloc.s 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_text'(string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br module_alias_tab_If8_end
  module_alias_tab_If8_else:
    ldloc.s 7
    ldstr "OP"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse module_alias_tab_If9_else
    ldloc.s 4
    ldarg.s 0
    ldloc.s 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_text'(string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  module_alias_tab_If9_else:
  module_alias_tab_If8_end:
    ldloc.s 5
    ldc.i4 1
    add
    stloc.s 5
    br module_alias_tab_W6_start
  module_alias_tab_W6_end:
    ldstr " "
    ldloc.s 4
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    stloc.s 8
    ldloc.s 8
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'imported_modules'(string)
    stloc.s 9
    ldc.i4.0
    stloc.s 10
  module_alias_tab_L10_start:
    ldloc.s 10
    ldloc.s 9
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge module_alias_tab_L10_end
    ldloc.s 9
    ldloc.s 10
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 11
    ldstr ""
    stloc.s 12
    ldloc.s 11
    call int32 TKVApp::'leading_dots'(string)
    ldc.i4 0
    cgt
    brfalse module_alias_tab_If11_else
    ldloc.s 11
    ldarg.s 1
    ldarg.s 2
    call string TKVApp::'resolve_rel'(string, string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 12
    br module_alias_tab_If11_end
  module_alias_tab_If11_else:
    ldloc.s 11
    ldarg.s 2
    ldarg.s 3
    call string TKVApp::'resolve_abs'(string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 12
  module_alias_tab_If11_end:
    ldloc.s 12
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse module_alias_tab_If12_else
    ldloc.s 12
    call string TKVApp::'ambig_mark'()
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse module_alias_tab_If13_else
    ldarg.s 4
    ldstr "A#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 11
    call string TKVApp::'last_seg'(string)
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  module_alias_tab_If13_else:
  module_alias_tab_If12_else:
  module_alias_tab_L10_cont:
    ldloc.s 10
    ldc.i4 1
    add
    stloc.s 10
    br module_alias_tab_L10_start
  module_alias_tab_L10_end:
    ldloc.s 8
    call string TKVApp::'from_module'(string)
    stloc.s 13
    ldloc.s 13
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse module_alias_tab_If14_else
    ldloc.s 8
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'from_names'(string)
    stloc.s 14
    ldc.i4.0
    stloc.s 15
  module_alias_tab_L15_start:
    ldloc.s 15
    ldloc.s 14
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge module_alias_tab_L15_end
    ldloc.s 14
    ldloc.s 15
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 16
    ldloc.s 13
    ldstr "."
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 16
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 17
    ldstr ""
    stloc.s 18
    ldloc.s 13
    call int32 TKVApp::'leading_dots'(string)
    ldc.i4 0
    cgt
    brfalse module_alias_tab_If16_else
    ldloc.s 17
    ldarg.s 1
    ldarg.s 2
    call string TKVApp::'resolve_rel'(string, string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 18
    br module_alias_tab_If16_end
  module_alias_tab_If16_else:
    ldloc.s 17
    ldarg.s 2
    ldarg.s 3
    call string TKVApp::'resolve_abs'(string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 18
  module_alias_tab_If16_end:
    ldloc.s 18
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse module_alias_tab_If17_else
    ldloc.s 18
    call string TKVApp::'ambig_mark'()
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse module_alias_tab_If18_else
    ldarg.s 4
    ldstr "A#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 16
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 18
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  module_alias_tab_If18_else:
  module_alias_tab_If17_else:
  module_alias_tab_L15_cont:
    ldloc.s 15
    ldc.i4 1
    add
    stloc.s 15
    br module_alias_tab_L15_start
  module_alias_tab_L15_end:
  module_alias_tab_If14_else:
    ldloc.s 5
    stloc.s 0
    br module_alias_tab_W1_start
  module_alias_tab_If5_else:
  module_alias_tab_If2_else:
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    br module_alias_tab_W1_start
  module_alias_tab_W1_end:
    ldc.i4 0
    ret
  }
  .method public static string 'find_class_file'(string 'cname', class [mscorlib]System.Collections.Generic.List`1<string> 'scope', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'tab') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldarg.s 1
    ldarg.s 2
    call string TKVApp::'resolve_name'(string, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    ret
  }
  .method public static int32 'has_method'(string 'rel', string 'cname', string 'meth', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'tab') cil managed
  {
    .maxstack 8
    .locals init (string 'blob')
    ldarg.s 3
    ldstr "M#"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse has_method_dget1_miss
    ldarg.s 3
    ldstr "M#"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br has_method_dget1_end
  has_method_dget1_miss:
    ldstr ""
  has_method_dget1_end:
    stloc.s 0
    ldloc.s 0
    ldstr "|"
    ldarg.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse has_method_If2_else
    ldc.i4 1
    ret
  has_method_If2_else:
    ldc.i4 0
    ret
  }
  .method public static string 'self_owner'(string 'rel', string 'cls', string 'called', class [mscorlib]System.Collections.Generic.List`1<string> 'scope', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'tab') cil managed
  {
    .maxstack 8
    .locals init (string 'cur_rel', string 'cur_cls', int32 'hop', string 'par', string 'pf')
    ldarg.s 0
    ldarg.s 1
    ldarg.s 2
    ldarg.s 4
    call int32 TKVApp::'has_method'(string, string, string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    ldc.i4 1
    ceq
    brfalse self_owner_If1_else
    ldarg.s 0
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ret
  self_owner_If1_else:
    ldarg.s 0
    stloc.s 0
    ldarg.s 1
    stloc.s 1
    ldc.i4 0
    stloc.s 2
  self_owner_W2_start:
    ldloc.s 2
    ldc.i4 3
    clt
    brfalse self_owner_W2_end
    ldarg.s 4
    ldstr "P#"
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse self_owner_dget3_miss
    ldarg.s 4
    ldstr "P#"
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br self_owner_dget3_end
  self_owner_dget3_miss:
    ldstr ""
  self_owner_dget3_end:
    stloc.s 3
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse self_owner_If4_else
    ldstr ""
    ret
  self_owner_If4_else:
    ldloc.s 3
    ldarg.s 3
    ldarg.s 4
    call string TKVApp::'resolve_name'(string, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 4
    ldloc.s 4
    call string TKVApp::'ambig_mark'()
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse self_owner_If5_else
    ldstr ""
    ret
  self_owner_If5_else:
    ldloc.s 4
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse self_owner_If6_else
    ldstr ""
    ret
  self_owner_If6_else:
    ldloc.s 4
    ldloc.s 3
    ldarg.s 2
    ldarg.s 4
    call int32 TKVApp::'has_method'(string, string, string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    ldc.i4 1
    ceq
    brfalse self_owner_If7_else
    ldloc.s 4
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 3
    call string [mscorlib]System.String::Concat(string, string)
    ret
  self_owner_If7_else:
    ldloc.s 4
    stloc.s 0
    ldloc.s 3
    stloc.s 1
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    br self_owner_W2_start
  self_owner_W2_end:
    ldstr ""
    ret
  }
  .method public static string 'pair_file'(string 'pair') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr "#"
    call string TKVApp::'cut_at'(string, string)
    ret
  }
  .method public static string 'pair_cls'(string 'pair') cil managed
  {
    .maxstack 8
    .locals init (int32 'at', int32 '__slice2642321073040_start')
    ldarg.s 0
    ldstr "#"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    clt
    brfalse pair_cls_If1_else
    ldstr ""
    ret
  pair_cls_If1_else:
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 1
    ldarg.s 0
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 1
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    ret
  }
  .method public static string 'recv_type'(class [mscorlib]System.Collections.Generic.List`1<string> 'rows', int32 'i', string 'fn', string 'cls', string 'rel', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'tab') cil managed
  {
    .maxstack 8
    .locals init (string 'base', string 'opb', string 'opc', string 'nm3', string 't')
    ldarg.s 0
    ldarg.s 1
    ldc.i4 1
    sub
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 0
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse recv_type_If1_else
    ldstr ""
    ret
  recv_type_If1_else:
    ldloc.s 0
    ldstr "self"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse recv_type_If2_else
    ldarg.s 0
    ldarg.s 1
    ldc.i4 2
    sub
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 1
    ldloc.s 1
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse recv_type_If3_else
    ldstr ""
    ret
  recv_type_If3_else:
    ldstr "self"
    ret
  recv_type_If2_else:
    ldarg.s 0
    ldarg.s 1
    ldc.i4 2
    sub
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 2
    ldloc.s 2
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse recv_type_If4_else
    ldarg.s 0
    ldarg.s 1
    ldc.i4 3
    sub
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 3
    ldloc.s 3
    ldstr "self"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse recv_type_If5_else
    ldarg.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse recv_type_If6_else
    ldarg.s 5
    ldstr "L#"
    ldarg.s 4
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 3
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse recv_type_dget7_miss
    ldarg.s 5
    ldstr "L#"
    ldarg.s 4
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 3
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br recv_type_dget7_end
  recv_type_dget7_miss:
    ldstr ""
  recv_type_dget7_end:
    ret
  recv_type_If6_else:
  recv_type_If5_else:
    ldstr ""
    ret
  recv_type_If4_else:
    ldarg.s 5
    ldstr "L#"
    ldarg.s 4
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse recv_type_dget8_miss
    ldarg.s 5
    ldstr "L#"
    ldarg.s 4
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br recv_type_dget8_end
  recv_type_dget8_miss:
    ldstr ""
  recv_type_dget8_end:
    stloc.s 4
    ldloc.s 4
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse recv_type_If9_else
    ldloc.s 4
    ret
  recv_type_If9_else:
    ldloc.s 0
    ret
  }
  .method public static string 'plain_edge'(string 'rel', string 'fn', string 'cls', string 'called', class [mscorlib]System.Collections.Generic.List`1<string> 'scope', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'tab', class [mscorlib]System.Collections.Generic.List`1<int32> 'stats') cil managed
  {
    .maxstack 8
    .locals init (int32 'kwq', string 'hit', string 'ctor', string 'tgt_owner')
    ldarg.s 6
    ldc.i4 6
    ldarg.s 6
    ldc.i4 6
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldarg.s 3
    call int32 TKVApp::'is_keyword'(string)
    stloc.s 0
    ldloc.s 0
    ldc.i4 1
    ceq
    brfalse plain_edge_If1_else
    ldarg.s 6
    ldc.i4 7
    ldarg.s 6
    ldc.i4 7
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldstr ""
    ret
  plain_edge_If1_else:
    ldarg.s 3
    ldarg.s 4
    ldarg.s 5
    call string TKVApp::'resolve_name'(string, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 1
    ldloc.s 1
    call string TKVApp::'ambig_mark'()
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse plain_edge_If2_else
    ldarg.s 6
    ldc.i4 0
    ldarg.s 6
    ldc.i4 0
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldstr ""
    ret
  plain_edge_If2_else:
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse plain_edge_If3_else
    ldstr ""
    ret
  plain_edge_If3_else:
    ldarg.s 5
    ldstr "M#"
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 3
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse plain_edge_dget4_miss
    ldarg.s 5
    ldstr "M#"
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 3
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br plain_edge_dget4_end
  plain_edge_dget4_miss:
    ldstr ""
  plain_edge_dget4_end:
    stloc.s 2
    ldloc.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse plain_edge_If5_else
    ldarg.s 6
    ldc.i4 5
    ldarg.s 6
    ldc.i4 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldarg.s 0
    ldarg.s 2
    ldarg.s 1
    call string TKVApp::'method_id'(string, string, string)
    ldstr "class"
    ldloc.s 1
    ldarg.s 3
    call string TKVApp::'node_id'(string, string, string)
    ldstr "calls"
    ldstr "0.8"
    call string TKVApp::'typed_edge'(string, string, string, string)
    ret
  plain_edge_If5_else:
    ldarg.s 6
    ldc.i4 5
    ldarg.s 6
    ldc.i4 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldloc.s 1
    ldarg.s 3
    ldarg.s 5
    call string TKVApp::'owner_of'(string, string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 3
    ldarg.s 0
    ldarg.s 2
    ldarg.s 1
    call string TKVApp::'method_id'(string, string, string)
    ldloc.s 1
    ldloc.s 3
    ldarg.s 3
    call string TKVApp::'method_id'(string, string, string)
    ldstr "calls"
    ldstr "0.8"
    call string TKVApp::'typed_edge'(string, string, string, string)
    ret
  }
  .method public static string 'dotted_edge'(class [mscorlib]System.Collections.Generic.List`1<string> 'rows', int32 'i', string 'rel', string 'fn', string 'cls', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'tab', class [mscorlib]System.Collections.Generic.List`1<string> 'scope', class [mscorlib]System.Collections.Generic.List`1<int32> 'stats') cil managed
  {
    .maxstack 8
    .locals init (string 'called', string 't', string 'owner', string 'target', string 'mod_owner', string 'cf', string 'owner2')
    ldarg.s 0
    ldarg.s 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_text'(string)
    stloc.s 0
    ldarg.s 0
    ldarg.s 1
    ldc.i4 1
    sub
    ldarg.s 3
    ldarg.s 4
    ldarg.s 2
    ldarg.s 5
    call string TKVApp::'recv_type'(class [mscorlib]System.Collections.Generic.List`1<string>, int32, string, string, string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 1
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse dotted_edge_If1_else
    ldarg.s 7
    ldc.i4 1
    ldarg.s 7
    ldc.i4 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldstr ""
    ret
  dotted_edge_If1_else:
    ldloc.s 1
    ldstr "self"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse dotted_edge_If2_else
    ldarg.s 4
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse dotted_edge_If3_else
    ldstr ""
    ret
  dotted_edge_If3_else:
    ldarg.s 2
    ldarg.s 4
    ldloc.s 0
    ldarg.s 6
    ldarg.s 5
    call string TKVApp::'self_owner'(string, string, string, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 2
    ldloc.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse dotted_edge_If4_else
    ldstr ""
    ret
  dotted_edge_If4_else:
    ldarg.s 7
    ldc.i4 2
    ldarg.s 7
    ldc.i4 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldarg.s 2
    ldarg.s 4
    ldarg.s 3
    call string TKVApp::'method_id'(string, string, string)
    ldloc.s 2
    call string TKVApp::'pair_file'(string)
    ldloc.s 2
    call string TKVApp::'pair_cls'(string)
    ldloc.s 0
    call string TKVApp::'method_id'(string, string, string)
    ldstr "calls"
    ldstr "0.8"
    call string TKVApp::'typed_edge'(string, string, string, string)
    ret
  dotted_edge_If2_else:
    ldarg.s 5
    ldstr "A#"
    ldarg.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse dotted_edge_dget5_miss
    ldarg.s 5
    ldstr "A#"
    ldarg.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br dotted_edge_dget5_end
  dotted_edge_dget5_miss:
    ldstr ""
  dotted_edge_dget5_end:
    stloc.s 3
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse dotted_edge_If6_else
    ldarg.s 5
    ldstr "D#"
    ldloc.s 3
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse dotted_edge_dget8_miss
    ldarg.s 5
    ldstr "D#"
    ldloc.s 3
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br dotted_edge_dget8_end
  dotted_edge_dget8_miss:
    ldstr ""
  dotted_edge_dget8_end:
    ldloc.s 0
    call int32 TKVApp::'has_def'(string, string)
    ldc.i4 0
    ceq
    brfalse dotted_edge_If7_else
    ldstr ""
    ret
  dotted_edge_If7_else:
    ldarg.s 7
    ldc.i4 3
    ldarg.s 7
    ldc.i4 3
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldloc.s 3
    ldloc.s 0
    ldarg.s 5
    call string TKVApp::'owner_of'(string, string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 4
    ldarg.s 2
    ldarg.s 4
    ldarg.s 3
    call string TKVApp::'method_id'(string, string, string)
    ldloc.s 3
    ldloc.s 4
    ldloc.s 0
    call string TKVApp::'method_id'(string, string, string)
    ldstr "calls"
    ldstr "0.8"
    call string TKVApp::'typed_edge'(string, string, string, string)
    ret
  dotted_edge_If6_else:
    ldloc.s 1
    ldarg.s 6
    ldarg.s 5
    call string TKVApp::'find_class_file'(string, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 5
    ldloc.s 5
    call string TKVApp::'ambig_mark'()
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse dotted_edge_If9_else
    ldarg.s 7
    ldc.i4 0
    ldarg.s 7
    ldc.i4 0
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldstr ""
    ret
  dotted_edge_If9_else:
    ldloc.s 5
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse dotted_edge_If10_else
    ldarg.s 7
    ldc.i4 1
    ldarg.s 7
    ldc.i4 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldstr ""
    ret
  dotted_edge_If10_else:
    ldloc.s 5
    ldloc.s 1
    ldloc.s 0
    ldarg.s 6
    ldarg.s 5
    call string TKVApp::'self_owner'(string, string, string, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 6
    ldloc.s 6
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse dotted_edge_If11_else
    ldarg.s 7
    ldc.i4 1
    ldarg.s 7
    ldc.i4 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldstr ""
    ret
  dotted_edge_If11_else:
    ldarg.s 7
    ldc.i4 4
    ldarg.s 7
    ldc.i4 4
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldarg.s 2
    ldarg.s 4
    ldarg.s 3
    call string TKVApp::'method_id'(string, string, string)
    ldloc.s 6
    call string TKVApp::'pair_file'(string)
    ldloc.s 6
    call string TKVApp::'pair_cls'(string)
    ldloc.s 0
    call string TKVApp::'method_id'(string, string, string)
    ldstr "calls"
    ldstr "0.8"
    call string TKVApp::'typed_edge'(string, string, string, string)
    ret
  }
  .method public static int32 'bound_names_tab'(class [mscorlib]System.Collections.Generic.List`1<string> 'rows', string 'rel', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'out') cil managed
  {
    .maxstack 8
    .locals init (string 'fn', class [mscorlib]System.Collections.Generic.List`1<string> 'fn_names', class [mscorlib]System.Collections.Generic.List`1<int32> 'fn_inds', int32 'depth', int32 'i', string 'kind', int32 'ind', string 'w', string 'nm', int32 'j', string 'pb', int32 'hit', string 'nm2', string 'nm3', string 'opn', string 'pb2', string 'pb3')
    ldstr ""
    stloc.s 0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 1
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<int32>::.ctor()
    stloc.s 2
    ldc.i4 0
    stloc.s 3
    ldc.i4 0
    stloc.s 4
  bound_names_tab_W1_start:
    ldloc.s 4
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse bound_names_tab_W1_end
    ldarg.s 0
    ldloc.s 4
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_kind'(string)
    stloc.s 5
    ldloc.s 5
    ldstr "BOL"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bound_names_tab_If2_else
    ldarg.s 0
    ldloc.s 4
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call int32 TKVApp::'tok_indent'(string)
    stloc.s 6
    ldarg.s 0
    ldloc.s 4
    ldc.i4 1
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 7
    ldloc.s 2
    ldloc.s 3
    ldloc.s 6
    call int32 TKVApp::'stack_pop_to'(class [mscorlib]System.Collections.Generic.List`1<int32>, int32, int32)
    stloc.s 3
    ldloc.s 1
    ldloc.s 3
    call string TKVApp::'stack_top'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 0
    ldloc.s 7
    ldstr "def"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bound_names_tab_If3_else
    ldarg.s 0
    ldloc.s 4
    ldc.i4 2
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 8
    ldloc.s 8
    stloc.s 0
    ldloc.s 1
    ldloc.s 2
    ldloc.s 3
    ldloc.s 8
    ldloc.s 6
    call int32 TKVApp::'stack_push'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<int32>, int32, string, int32)
    stloc.s 3
    ldloc.s 4
    ldc.i4 3
    add
    stloc.s 9
  bound_names_tab_W4_start:
    ldloc.s 9
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse bound_names_tab_W4_end
    ldarg.s 0
    ldloc.s 9
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_kind'(string)
    ldstr "BOL"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bound_names_tab_If5_else
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 9
  bound_names_tab_If5_else:
    ldloc.s 9
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse bound_names_tab_If6_else
    ldarg.s 0
    ldloc.s 9
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_kind'(string)
    ldstr "NAME"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bound_names_tab_If7_else
    ldarg.s 0
    ldloc.s 9
    ldc.i4 1
    sub
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 10
    ldc.i4 0
    stloc.s 11
    ldloc.s 10
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bound_names_tab_If8_else
    ldc.i4 1
    stloc.s 11
  bound_names_tab_If8_else:
    ldloc.s 10
    ldstr ","
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bound_names_tab_If9_else
    ldc.i4 1
    stloc.s 11
  bound_names_tab_If9_else:
    ldloc.s 11
    ldc.i4 1
    ceq
    brfalse bound_names_tab_If10_else
    ldarg.s 2
    ldstr "B#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    ldloc.s 9
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_text'(string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "1"
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  bound_names_tab_If10_else:
  bound_names_tab_If7_else:
    ldloc.s 9
    ldc.i4 1
    add
    stloc.s 9
  bound_names_tab_If6_else:
    br bound_names_tab_W4_start
  bound_names_tab_W4_end:
  bound_names_tab_If3_else:
    ldloc.s 7
    ldstr "for"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bound_names_tab_If11_else
    ldarg.s 0
    ldloc.s 4
    ldc.i4 2
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 12
    ldloc.s 12
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse bound_names_tab_If12_else
    ldarg.s 2
    ldstr "B#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "1"
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  bound_names_tab_If12_else:
  bound_names_tab_If11_else:
  bound_names_tab_If2_else:
    ldloc.s 5
    ldstr "NAME"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bound_names_tab_If13_else
    ldarg.s 0
    ldloc.s 4
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_text'(string)
    stloc.s 13
    ldarg.s 0
    ldloc.s 4
    ldc.i4 1
    add
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 14
    ldloc.s 14
    ldstr "="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bound_names_tab_If14_else
    ldarg.s 0
    ldloc.s 4
    ldc.i4 1
    sub
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 15
    ldloc.s 15
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse bound_names_tab_If15_else
    ldarg.s 2
    ldstr "B#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 13
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "1"
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  bound_names_tab_If15_else:
  bound_names_tab_If14_else:
    ldarg.s 0
    ldloc.s 4
    ldc.i4 1
    sub
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 16
    ldloc.s 16
    ldstr "as"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bound_names_tab_If16_else
    ldarg.s 2
    ldstr "B#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 13
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "1"
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  bound_names_tab_If16_else:
    ldloc.s 16
    ldstr "for"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse bound_names_tab_If17_else
    ldarg.s 2
    ldstr "B#"
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 13
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "1"
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  bound_names_tab_If17_else:
  bound_names_tab_If13_else:
    ldloc.s 4
    ldc.i4 1
    add
    stloc.s 4
    br bound_names_tab_W1_start
  bound_names_tab_W1_end:
    ldc.i4 0
    ret
  }
  .method public static int32 'is_arg_slot'(string 'op_before') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_arg_slot_If1_else
    ldc.i4 1
    ret
  is_arg_slot_If1_else:
    ldarg.s 0
    ldstr ","
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_arg_slot_If2_else
    ldc.i4 1
    ret
  is_arg_slot_If2_else:
    ldarg.s 0
    ldstr "="
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_arg_slot_If3_else
    ldc.i4 1
    ret
  is_arg_slot_If3_else:
    ldc.i4 0
    ret
  }
  .method public static string 'ref_edge'(class [mscorlib]System.Collections.Generic.List`1<string> 'rows', int32 'i', string 'rel', string 'fn', string 'cls', class [mscorlib]System.Collections.Generic.List`1<string> 'scope', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'tab', class [mscorlib]System.Collections.Generic.List`1<int32> 'stats') cil managed
  {
    .maxstack 8
    .locals init (string 'name', string 'prev', string 'base', string 'owner', string 'hit', string 'ctor', string 'tgt_owner')
    ldarg.s 0
    ldarg.s 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_text'(string)
    stloc.s 0
    ldloc.s 0
    call int32 TKVApp::'is_keyword'(string)
    ldc.i4 1
    ceq
    brfalse ref_edge_If1_else
    ldstr ""
    ret
  ref_edge_If1_else:
    ldarg.s 0
    ldarg.s 1
    ldc.i4 1
    sub
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 1
    ldloc.s 1
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse ref_edge_If2_else
    ldarg.s 0
    ldarg.s 1
    ldc.i4 2
    sub
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 2
    ldloc.s 2
    ldstr "self"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse ref_edge_If3_else
    ldstr ""
    ret
  ref_edge_If3_else:
    ldarg.s 4
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse ref_edge_If4_else
    ldstr ""
    ret
  ref_edge_If4_else:
    ldarg.s 2
    ldarg.s 4
    ldloc.s 0
    ldarg.s 5
    ldarg.s 6
    call string TKVApp::'self_owner'(string, string, string, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 3
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse ref_edge_If5_else
    ldstr ""
    ret
  ref_edge_If5_else:
    ldarg.s 7
    ldc.i4 2
    ldarg.s 7
    ldc.i4 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldarg.s 2
    ldarg.s 4
    ldarg.s 3
    call string TKVApp::'method_id'(string, string, string)
    ldloc.s 3
    call string TKVApp::'pair_file'(string)
    ldloc.s 3
    call string TKVApp::'pair_cls'(string)
    ldloc.s 0
    call string TKVApp::'method_id'(string, string, string)
    ldstr "calls"
    ldstr "0.6"
    call string TKVApp::'typed_edge'(string, string, string, string)
    ret
  ref_edge_If2_else:
    ldarg.s 6
    ldstr "B#"
    ldarg.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 3
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse ref_edge_dget7_miss
    ldarg.s 6
    ldstr "B#"
    ldarg.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 3
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br ref_edge_dget7_end
  ref_edge_dget7_miss:
    ldstr ""
  ref_edge_dget7_end:
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse ref_edge_If6_else
    ldstr ""
    ret
  ref_edge_If6_else:
    ldloc.s 0
    ldarg.s 5
    ldarg.s 6
    call string TKVApp::'resolve_name'(string, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 4
    ldloc.s 4
    call string TKVApp::'ambig_mark'()
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse ref_edge_If8_else
    ldstr ""
    ret
  ref_edge_If8_else:
    ldloc.s 4
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse ref_edge_If9_else
    ldstr ""
    ret
  ref_edge_If9_else:
    ldarg.s 6
    ldstr "M#"
    ldloc.s 4
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse ref_edge_dget10_miss
    ldarg.s 6
    ldstr "M#"
    ldloc.s 4
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "#"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br ref_edge_dget10_end
  ref_edge_dget10_miss:
    ldstr ""
  ref_edge_dget10_end:
    stloc.s 5
    ldloc.s 5
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse ref_edge_If11_else
    ldstr ""
    ret
  ref_edge_If11_else:
    ldloc.s 4
    ldloc.s 0
    ldarg.s 6
    call string TKVApp::'owner_of'(string, string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 6
    ldarg.s 7
    ldc.i4 5
    ldarg.s 7
    ldc.i4 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    ldarg.s 2
    ldarg.s 4
    ldarg.s 3
    call string TKVApp::'method_id'(string, string, string)
    ldloc.s 4
    ldloc.s 6
    ldloc.s 0
    call string TKVApp::'method_id'(string, string, string)
    ldstr "calls"
    ldstr "0.6"
    call string TKVApp::'typed_edge'(string, string, string, string)
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'emit_file'(string 'rel', class [mscorlib]System.Collections.Generic.List`1<string> 'scope', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'tab', class [mscorlib]System.Collections.Generic.List`1<int32> 'stats') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', class [mscorlib]System.Collections.Generic.List`1<string> 'rows', class [mscorlib]System.Collections.Generic.List`1<string> 'here', string 'fn', string 'cls', class [mscorlib]System.Collections.Generic.List`1<string> 'fn_names', class [mscorlib]System.Collections.Generic.List`1<int32> 'fn_inds', int32 'depth', class [mscorlib]System.Collections.Generic.List`1<string> 'cls_names', class [mscorlib]System.Collections.Generic.List`1<int32> 'cls_inds', int32 'cdepth', int32 'i', string 'kind', int32 'ind', string 'w', string 'nm', string 'op3', string 'par', string 'hitp', string 'fowner', string 'fn_id', string 'opn', string 'called', string 'before', int32 'is_def', string 'prev', string 'edge', string 'edge2', string 'opb', int32 'slot', string 'nm_self', string 'opb2', string 'edge3')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldarg.s 0
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'file_tokens'(string)
    stloc.s 1
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 2
    ldloc.s 2
    ldarg.s 0
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldstr ""
    stloc.s 3
    ldstr ""
    stloc.s 4
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 5
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<int32>::.ctor()
    stloc.s 6
    ldc.i4 0
    stloc.s 7
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 8
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<int32>::.ctor()
    stloc.s 9
    ldc.i4 0
    stloc.s 10
    ldc.i4 0
    stloc.s 11
  emit_file_W1_start:
    ldloc.s 11
    ldloc.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse emit_file_W1_end
    ldloc.s 1
    ldloc.s 11
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_kind'(string)
    stloc.s 12
    ldloc.s 12
    ldstr "BOL"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse emit_file_If2_else
    ldloc.s 1
    ldloc.s 11
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call int32 TKVApp::'tok_indent'(string)
    stloc.s 13
    ldloc.s 1
    ldloc.s 11
    ldc.i4 1
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 14
    ldloc.s 6
    ldloc.s 7
    ldloc.s 13
    call int32 TKVApp::'stack_pop_to'(class [mscorlib]System.Collections.Generic.List`1<int32>, int32, int32)
    stloc.s 7
    ldloc.s 5
    ldloc.s 7
    call string TKVApp::'stack_top'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 3
    ldloc.s 9
    ldloc.s 10
    ldloc.s 13
    call int32 TKVApp::'stack_pop_to'(class [mscorlib]System.Collections.Generic.List`1<int32>, int32, int32)
    stloc.s 10
    ldloc.s 8
    ldloc.s 10
    call string TKVApp::'stack_top'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 4
    ldloc.s 14
    ldstr "class"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse emit_file_If3_else
    ldloc.s 1
    ldloc.s 11
    ldc.i4 2
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 15
    ldloc.s 15
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse emit_file_If4_else
    ldloc.s 15
    stloc.s 4
    ldloc.s 8
    ldloc.s 9
    ldloc.s 10
    ldloc.s 15
    ldloc.s 13
    call int32 TKVApp::'stack_push'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<int32>, int32, string, int32)
    stloc.s 10
    ldloc.s 0
    ldstr "file:"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "class"
    ldarg.s 0
    ldloc.s 15
    call string TKVApp::'node_id'(string, string, string)
    ldstr "contains"
    ldstr "1.0"
    call string TKVApp::'typed_edge'(string, string, string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 1
    ldloc.s 11
    ldc.i4 3
    add
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 16
    ldloc.s 16
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse emit_file_If5_else
    ldloc.s 1
    ldloc.s 11
    ldc.i4 4
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 17
    ldloc.s 17
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse emit_file_If6_else
    ldloc.s 17
    call int32 TKVApp::'is_keyword'(string)
    ldc.i4 0
    ceq
    brfalse emit_file_If7_else
    ldloc.s 17
    ldarg.s 1
    ldarg.s 2
    call string TKVApp::'find_class_file'(string, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 18
    ldloc.s 18
    call string TKVApp::'ambig_mark'()
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse emit_file_If8_else
    ldarg.s 3
    ldc.i4 0
    ldarg.s 3
    ldc.i4 0
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    ldc.i4 1
    add
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::set_Item(int32, !0)
    br emit_file_If8_end
  emit_file_If8_else:
    ldloc.s 18
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse emit_file_If9_else
    ldloc.s 0
    ldstr "class"
    ldarg.s 0
    ldloc.s 15
    call string TKVApp::'node_id'(string, string, string)
    ldstr "class"
    ldloc.s 18
    ldloc.s 17
    call string TKVApp::'node_id'(string, string, string)
    ldstr "inherits"
    ldstr "0.9"
    call string TKVApp::'typed_edge'(string, string, string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  emit_file_If9_else:
  emit_file_If8_end:
  emit_file_If7_else:
  emit_file_If6_else:
  emit_file_If5_else:
  emit_file_If4_else:
    br emit_file_If3_end
  emit_file_If3_else:
    ldloc.s 14
    ldstr "def"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse emit_file_If10_else
    ldloc.s 1
    ldloc.s 11
    ldc.i4 2
    add
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 15
    ldloc.s 15
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse emit_file_If11_else
    ldloc.s 15
    stloc.s 3
    ldloc.s 5
    ldloc.s 6
    ldloc.s 7
    ldloc.s 15
    ldloc.s 13
    call int32 TKVApp::'stack_push'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<int32>, int32, string, int32)
    stloc.s 7
    ldstr ""
    stloc.s 19
    ldloc.s 4
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse emit_file_If12_else
    ldloc.s 4
    stloc.s 19
  emit_file_If12_else:
    ldarg.s 0
    ldloc.s 19
    ldloc.s 15
    call string TKVApp::'method_id'(string, string, string)
    stloc.s 20
    ldloc.s 0
    ldstr "file:"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 20
    ldstr "contains"
    ldstr "1.0"
    call string TKVApp::'typed_edge'(string, string, string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  emit_file_If11_else:
  emit_file_If10_else:
  emit_file_If3_end:
  emit_file_If2_else:
    ldloc.s 12
    ldstr "NAME"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse emit_file_If13_else
    ldloc.s 1
    ldloc.s 11
    ldc.i4 1
    add
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 21
    ldloc.s 21
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse emit_file_If14_else
    ldloc.s 1
    ldloc.s 11
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'tok_text'(string)
    stloc.s 22
    ldloc.s 1
    ldloc.s 11
    ldc.i4 1
    sub
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 23
    ldc.i4 0
    stloc.s 24
    ldloc.s 23
    ldstr "def"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse emit_file_If15_else
    ldc.i4 1
    stloc.s 24
  emit_file_If15_else:
    ldloc.s 23
    ldstr "class"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse emit_file_If16_else
    ldc.i4 1
    stloc.s 24
  emit_file_If16_else:
    ldloc.s 24
    ldc.i4 1
    ceq
    brfalse emit_file_If17_else
    ldloc.s 11
    ldc.i4 1
    add
    stloc.s 11
    br emit_file_W1_start
  emit_file_If17_else:
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse emit_file_If18_else
    ldloc.s 1
    ldloc.s 11
    ldc.i4 1
    sub
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 25
    ldloc.s 25
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse emit_file_If19_else
    ldloc.s 1
    ldloc.s 11
    ldarg.s 0
    ldloc.s 3
    ldloc.s 4
    ldarg.s 2
    ldarg.s 1
    ldarg.s 3
    call string TKVApp::'dotted_edge'(class [mscorlib]System.Collections.Generic.List`1<string>, int32, string, string, string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<int32>)
    stloc.s 26
    ldloc.s 26
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse emit_file_If20_else
    ldloc.s 0
    ldloc.s 26
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  emit_file_If20_else:
  emit_file_If19_else:
    ldloc.s 25
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse emit_file_If21_else
    ldarg.s 0
    ldloc.s 3
    ldloc.s 4
    ldloc.s 22
    ldarg.s 1
    ldarg.s 2
    ldarg.s 3
    call string TKVApp::'plain_edge'(string, string, string, string, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.List`1<int32>)
    stloc.s 27
    ldloc.s 27
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse emit_file_If22_else
    ldloc.s 0
    ldloc.s 27
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  emit_file_If22_else:
  emit_file_If21_else:
  emit_file_If18_else:
  emit_file_If14_else:
    ldloc.s 21
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse emit_file_If23_else
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse emit_file_If24_else
    ldloc.s 1
    ldloc.s 11
    ldc.i4 1
    sub
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 28
    ldloc.s 28
    call int32 TKVApp::'is_arg_slot'(string)
    stloc.s 29
    ldloc.s 28
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse emit_file_If25_else
    ldloc.s 1
    ldloc.s 11
    ldc.i4 2
    sub
    call string TKVApp::'name_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 30
    ldloc.s 30
    ldstr "self"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse emit_file_If26_else
    ldloc.s 1
    ldloc.s 11
    ldc.i4 3
    sub
    call string TKVApp::'op_at'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    stloc.s 31
    ldloc.s 31
    call int32 TKVApp::'is_arg_slot'(string)
    stloc.s 29
  emit_file_If26_else:
  emit_file_If25_else:
    ldloc.s 29
    ldc.i4 1
    ceq
    brfalse emit_file_If27_else
    ldloc.s 21
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse emit_file_If28_else
    ldloc.s 1
    ldloc.s 11
    ldarg.s 0
    ldloc.s 3
    ldloc.s 4
    ldarg.s 1
    ldarg.s 2
    ldarg.s 3
    call string TKVApp::'ref_edge'(class [mscorlib]System.Collections.Generic.List`1<string>, int32, string, string, string, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.List`1<int32>)
    stloc.s 32
    ldloc.s 32
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse emit_file_If29_else
    ldloc.s 0
    ldloc.s 32
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  emit_file_If29_else:
  emit_file_If28_else:
  emit_file_If27_else:
  emit_file_If24_else:
  emit_file_If23_else:
  emit_file_If13_else:
    ldloc.s 11
    ldc.i4 1
    add
    stloc.s 11
    br emit_file_W1_start
  emit_file_W1_end:
    ldloc.s 0
    ret
  }
  .method public static string 'edge_key'(string 'e') cil managed
  {
    .maxstack 8
    .locals init (int32 'at', int32 '__slice2642320714432_start')
    ldarg.s 0
    ldstr ",\"weight\""
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    clt
    brfalse edge_key_If1_else
    ldarg.s 0
    ret
  edge_key_If1_else:
    ldc.i4 0
    stloc.s 1
    ldarg.s 0
    ldloc.s 1
    ldloc.s 0
    ldloc.s 1
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    ret
  }
  .method public static string 'run'(string 'manifest', string 'out_path') cil managed
  {
    .maxstack 8
    .locals init (string 'raw', class [mscorlib]System.Collections.Generic.List`1<string> 'rows', class [mscorlib]System.Collections.Generic.List`1<string> 'paths', int32 '__iterlist7_idx', string 'r', string 'p', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'base_idx', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'imps', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'tab', int32 '__iterlist8_idx', string 'rel', class [mscorlib]System.Collections.Generic.List`1<int32> 'stats', int32 'k', class [mscorlib]System.Collections.Generic.List`1<string> 'edges', class [System.Core]System.Collections.Generic.HashSet`1<string> 'seen', int32 'n_dup', int32 '__iterlist9_idx', class [mscorlib]System.Collections.Generic.List`1<string> 'scope', class [mscorlib]System.Collections.Generic.List`1<string> 'es', int32 '__iterlist10_idx', string 'e', string 'key', string 'doc', int32 '__strtmp2642320913344', int32 '__strtmp2642320904000', int32 '__strtmp2642320632256', int32 '__strtmp2642320632512', int32 '__strtmp2642320910528', int32 '__strtmp2642320909312', int32 '__strtmp2642320911360', int32 '__strtmp2642320905920', int32 '__strtmp2642325524992', int32 '__strtmp2642320618176', int32 '__strtmp2642326390016', int32 '__strtmp2642326397184', int32 '__strtmp2642320900288', int32 '__strtmp2642320908352', int32 '__strtmp2642320900160', int32 '__strtmp2642320812736', int32 '__strtmp2642320813760')
    ldarg.s 0
    call string [mscorlib]System.IO.File::ReadAllText(string)
    stloc.s 0
    ldloc.s 0
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
    stloc.s 1
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 2
    ldc.i4.0
    stloc.s 3
  run_L1_start:
    ldloc.s 3
    ldloc.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge run_L1_end
    ldloc.s 1
    ldloc.s 3
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 4
    ldloc.s 4
    callvirt instance string [mscorlib]System.String::Trim()
    call string TKVApp::'norm_slashes'(string)
    stloc.s 5
    ldloc.s 5
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse run_If2_else
    ldloc.s 2
    ldloc.s 5
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  run_If2_else:
  run_L1_cont:
    ldloc.s 3
    ldc.i4 1
    add
    stloc.s 3
    br run_L1_start
  run_L1_end:
    ldloc.s 2
    call class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> TKVApp::'build_index'(class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 6
    ldloc.s 2
    call class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> TKVApp::'build_base_index'(class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 7
    ldloc.s 2
    ldloc.s 6
    ldloc.s 7
    call class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> TKVApp::'build_imports'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 8
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 9
    ldc.i4.0
    stloc.s 10
  run_L3_start:
    ldloc.s 10
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge run_L3_end
    ldloc.s 2
    ldloc.s 10
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 11
    ldloc.s 11
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'file_tokens'(string)
    stloc.s 1
    ldloc.s 9
    ldstr "D#"
    ldloc.s 11
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    call string TKVApp::'collect_defs_tok'(class [mscorlib]System.Collections.Generic.List`1<string>)
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    ldloc.s 1
    ldloc.s 11
    ldloc.s 9
    call int32 TKVApp::'class_methods_tab'(class [mscorlib]System.Collections.Generic.List`1<string>, string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    pop
    ldloc.s 1
    ldloc.s 11
    ldloc.s 9
    call int32 TKVApp::'local_types_tab'(class [mscorlib]System.Collections.Generic.List`1<string>, string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    pop
    ldloc.s 1
    ldloc.s 11
    ldloc.s 6
    ldloc.s 7
    ldloc.s 9
    call int32 TKVApp::'module_alias_tab'(class [mscorlib]System.Collections.Generic.List`1<string>, string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    pop
    ldloc.s 1
    ldloc.s 11
    ldloc.s 9
    call int32 TKVApp::'bound_names_tab'(class [mscorlib]System.Collections.Generic.List`1<string>, string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    pop
  run_L3_cont:
    ldloc.s 10
    ldc.i4 1
    add
    stloc.s 10
    br run_L3_start
  run_L3_end:
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<int32>::.ctor()
    stloc.s 12
    ldc.i4 0
    stloc.s 13
  run_W4_start:
    ldloc.s 13
    ldc.i4 8
    clt
    brfalse run_W4_end
    ldloc.s 12
    ldc.i4 0
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<int32>::Add(!0)
    ldloc.s 13
    ldc.i4 1
    add
    stloc.s 13
    br run_W4_start
  run_W4_end:
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 14
    newobj instance void class [System.Core]System.Collections.Generic.HashSet`1<string>::.ctor()
    stloc.s 15
    ldc.i4 0
    stloc.s 16
    ldc.i4.0
    stloc.s 17
  run_L5_start:
    ldloc.s 17
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge run_L5_end
    ldloc.s 2
    ldloc.s 17
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 11
    ldloc.s 11
    ldloc.s 8
    ldloc.s 11
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse run_dget6_miss
    ldloc.s 8
    ldloc.s 11
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br run_dget6_end
  run_dget6_miss:
    ldstr ""
  run_dget6_end:
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'scope_files'(string, string)
    stloc.s 18
    ldloc.s 11
    ldloc.s 18
    ldloc.s 9
    ldloc.s 12
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'emit_file'(string, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.List`1<int32>)
    stloc.s 19
    ldc.i4.0
    stloc.s 20
  run_L7_start:
    ldloc.s 20
    ldloc.s 19
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge run_L7_end
    ldloc.s 19
    ldloc.s 20
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 21
    ldloc.s 21
    call string TKVApp::'edge_key'(string)
    stloc.s 22
    ldloc.s 15
    ldloc.s 22
    callvirt instance bool class [System.Core]System.Collections.Generic.HashSet`1<string>::Contains(!0)
    brfalse run_If8_else
    ldloc.s 16
    ldc.i4 1
    add
    stloc.s 16
    br run_L7_cont
  run_If8_else:
    ldloc.s 15
    ldloc.s 22
    callvirt instance bool class [System.Core]System.Collections.Generic.HashSet`1<string>::Add(!0)
    pop
    ldloc.s 14
    ldloc.s 21
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  run_L7_cont:
    ldloc.s 20
    ldc.i4 1
    add
    stloc.s 20
    br run_L7_start
  run_L7_end:
  run_L5_cont:
    ldloc.s 17
    ldc.i4 1
    add
    stloc.s 17
    br run_L5_start
  run_L5_end:
    ldstr "{\n \"edges\": [\n"
    ldloc.s 14
    call string TKVApp::'join_edges'(class [mscorlib]System.Collections.Generic.List`1<string>)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\n ],\n \"stats\": {"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 23
    ldloc.s 23
    ldstr "\"files\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 24
    ldloca.s 24
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 23
    ldloc.s 23
    ldstr ",\"edges\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 14
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 25
    ldloca.s 25
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 23
    ldloc.s 23
    ldstr ",\"ambiguous\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    ldc.i4 0
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 26
    ldloca.s 26
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 23
    ldloc.s 23
    ldstr ",\"khong_suy_duoc_kieu\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    ldc.i4 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 27
    ldloca.s 27
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 23
    ldloc.s 23
    ldstr ",\"qua_self\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    ldc.i4 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 28
    ldloca.s 28
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 23
    ldloc.s 23
    ldstr ",\"qua_module\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    ldc.i4 3
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 29
    ldloca.s 29
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 23
    ldloc.s 23
    ldstr ",\"qua_lop\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    ldc.i4 4
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 30
    ldloca.s 30
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 23
    ldloc.s 23
    ldstr ",\"ham_tran\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    ldc.i4 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 31
    ldloca.s 31
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 23
    ldloc.s 23
    ldstr ",\"plain_vao\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    ldc.i4 6
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 32
    ldloca.s 32
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 23
    ldloc.s 23
    ldstr ",\"plain_la_tu_khoa\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    ldc.i4 7
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 33
    ldloca.s 33
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 23
    ldloc.s 23
    ldstr ",\"dup_dropped\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 16
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 23
    ldloc.s 23
    ldstr "}\n}\n"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 23
    ldarg.s 1
    ldloc.s 23
    call void [mscorlib]System.IO.File::WriteAllText(string, string)
    ldstr "files="
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 34
    ldloca.s 34
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " edges="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 14
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 35
    ldloca.s 35
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " self="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    ldc.i4 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 36
    ldloca.s 36
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " module="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    ldc.i4 3
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 37
    ldloca.s 37
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " lop="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    ldc.i4 4
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 38
    ldloca.s 38
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " ham_tran="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    ldc.i4 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 39
    ldloca.s 39
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " ngoai_tam="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 12
    ldc.i4 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<int32>::get_Item(int32)
    stloc.s 40
    ldloca.s 40
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static string 'ambig_mark'() cil managed
  {
    .maxstack 8
    ldstr "?"
    ret
  }
  .method public static string 'norm_slashes'(string 's') cil managed
  {
    .maxstack 8
    .locals init (string 'out', int32 'i', string 'ch')
    ldstr ""
    stloc.s 0
    ldc.i4 0
    stloc.s 1
  norm_slashes_W1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse norm_slashes_W1_end
    ldarg.s 0
    ldloc.s 1
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    stloc.s 2
    ldloc.s 2
    ldstr "\\"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse norm_slashes_If2_else
    ldloc.s 0
    ldstr "/"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
    br norm_slashes_If2_end
  norm_slashes_If2_else:
    ldloc.s 0
    ldloc.s 2
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
  norm_slashes_If2_end:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br norm_slashes_W1_start
  norm_slashes_W1_end:
    ldloc.s 0
    ret
  }
  .method public static string 'dir_of_rel'(string 'rel') cil managed
  {
    .maxstack 8
    .locals init (int32 'cut', int32 'i', int32 '__slice2642320716272_start')
    ldc.i4 1
    neg
    stloc.s 0
    ldc.i4 0
    stloc.s 1
  dir_of_rel_W1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse dir_of_rel_W1_end
    ldarg.s 0
    ldloc.s 1
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ldstr "/"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse dir_of_rel_If2_else
    ldloc.s 1
    stloc.s 0
  dir_of_rel_If2_else:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br dir_of_rel_W1_start
  dir_of_rel_W1_end:
    ldloc.s 0
    ldc.i4 0
    clt
    brfalse dir_of_rel_If3_else
    ldstr ""
    ret
  dir_of_rel_If3_else:
    ldc.i4 0
    stloc.s 2
    ldarg.s 0
    ldloc.s 2
    ldloc.s 0
    ldloc.s 2
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    ret
  }
  .method public static string 'dotted_from_rel'(string 'rel') cil managed
  {
    .maxstack 8
    .locals init (string 'body', int32 '__slice2642320717552_start', int32 '__slice2642320717712_start', string 'out', int32 'i', string 'ch')
    ldarg.s 0
    stloc.s 0
    ldloc.s 0
    ldstr ".py"
    callvirt instance bool [mscorlib]System.String::EndsWith(string)
    brfalse dotted_from_rel_If1_else
    ldc.i4 0
    stloc.s 1
    ldloc.s 0
    ldloc.s 1
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 3
    sub
    ldloc.s 1
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 0
  dotted_from_rel_If1_else:
    ldloc.s 0
    ldstr "/__init__"
    callvirt instance bool [mscorlib]System.String::EndsWith(string)
    brfalse dotted_from_rel_If2_else
    ldc.i4 0
    stloc.s 2
    ldloc.s 0
    ldloc.s 2
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 9
    sub
    ldloc.s 2
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 0
    br dotted_from_rel_If2_end
  dotted_from_rel_If2_else:
    ldloc.s 0
    ldstr "__init__"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse dotted_from_rel_If3_else
    ldstr ""
    ret
  dotted_from_rel_If3_else:
  dotted_from_rel_If2_end:
    ldstr ""
    stloc.s 3
    ldc.i4 0
    stloc.s 4
  dotted_from_rel_W4_start:
    ldloc.s 4
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse dotted_from_rel_W4_end
    ldloc.s 0
    ldloc.s 4
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    stloc.s 5
    ldloc.s 5
    ldstr "/"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse dotted_from_rel_If5_else
    ldloc.s 3
    ldstr "."
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 3
    br dotted_from_rel_If5_end
  dotted_from_rel_If5_else:
    ldloc.s 3
    ldloc.s 5
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 3
  dotted_from_rel_If5_end:
    ldloc.s 4
    ldc.i4 1
    add
    stloc.s 4
    br dotted_from_rel_W4_start
  dotted_from_rel_W4_end:
    ldloc.s 3
    ret
  }
  .method public static string 'last_seg'(string 'dotted') cil managed
  {
    .maxstack 8
    .locals init (int32 'cut', int32 'i', int32 '__slice2642321073360_start')
    ldc.i4 1
    neg
    stloc.s 0
    ldc.i4 0
    stloc.s 1
  last_seg_W1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse last_seg_W1_end
    ldarg.s 0
    ldloc.s 1
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse last_seg_If2_else
    ldloc.s 1
    stloc.s 0
  last_seg_If2_else:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br last_seg_W1_start
  last_seg_W1_end:
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 2
    ldarg.s 0
    ldloc.s 2
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 2
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    ret
  }
  .method public static string 'drop_last_seg'(string 'dotted') cil managed
  {
    .maxstack 8
    .locals init (int32 'cut', int32 'i', int32 '__slice2642321067840_start')
    ldc.i4 1
    neg
    stloc.s 0
    ldc.i4 0
    stloc.s 1
  drop_last_seg_W1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse drop_last_seg_W1_end
    ldarg.s 0
    ldloc.s 1
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse drop_last_seg_If2_else
    ldloc.s 1
    stloc.s 0
  drop_last_seg_If2_else:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br drop_last_seg_W1_start
  drop_last_seg_W1_end:
    ldloc.s 0
    ldc.i4 0
    clt
    brfalse drop_last_seg_If3_else
    ldstr ""
    ret
  drop_last_seg_If3_else:
    ldc.i4 0
    stloc.s 2
    ldarg.s 0
    ldloc.s 2
    ldloc.s 0
    ldloc.s 2
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    ret
  }
  .method public static int32 'leading_dots'(string 's') cil managed
  {
    .maxstack 8
    .locals init (int32 'n')
    ldc.i4 0
    stloc.s 0
  leading_dots_W1_start:
    ldloc.s 0
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse leading_dots_W1_end
    ldarg.s 0
    ldloc.s 0
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse leading_dots_If2_else
    ldloc.s 0
    ret
  leading_dots_If2_else:
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    br leading_dots_W1_start
  leading_dots_W1_end:
    ldloc.s 0
    ret
  }
  .method public static string 'cut_at'(string 's', string 'stops') cil managed
  {
    .maxstack 8
    .locals init (string 'out', int32 'i', string 'ch', int32 'j')
    ldstr ""
    stloc.s 0
    ldc.i4 0
    stloc.s 1
  cut_at_W1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse cut_at_W1_end
    ldarg.s 0
    ldloc.s 1
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    stloc.s 2
    ldc.i4 0
    stloc.s 3
  cut_at_W2_start:
    ldloc.s 3
    ldarg.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse cut_at_W2_end
    ldloc.s 2
    ldarg.s 1
    ldloc.s 3
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse cut_at_If3_else
    ldloc.s 0
    ret
  cut_at_If3_else:
    ldloc.s 3
    ldc.i4 1
    add
    stloc.s 3
    br cut_at_W2_start
  cut_at_W2_end:
    ldloc.s 0
    ldloc.s 2
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br cut_at_W1_start
  cut_at_W1_end:
    ldloc.s 0
    ret
  }
  .method public static string 'imported_module'(string 'line') cil managed
  {
    .maxstack 8
    .locals init (string 'body', string 'rest', int32 '__slice2642321073360_start', int32 '__slice2642320717872_start')
    ldarg.s 0
    callvirt instance string [mscorlib]System.String::Trim()
    stloc.s 0
    ldloc.s 0
    ldstr "import "
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    brfalse imported_module_If1_else
    ldc.i4 7
    stloc.s 2
    ldloc.s 0
    ldloc.s 2
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 2
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    callvirt instance string [mscorlib]System.String::Trim()
    stloc.s 1
    ldloc.s 1
    ldstr " ,;#"
    call string TKVApp::'cut_at'(string, string)
    ret
  imported_module_If1_else:
    ldloc.s 0
    ldstr "from "
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    brfalse imported_module_If2_else
    ldc.i4 5
    stloc.s 3
    ldloc.s 0
    ldloc.s 3
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 3
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    callvirt instance string [mscorlib]System.String::Trim()
    stloc.s 1
    ldloc.s 1
    ldstr " ,;#"
    call string TKVApp::'cut_at'(string, string)
    ret
  imported_module_If2_else:
    ldstr ""
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'imported_modules'(string 'line') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', string 'body', string 'mod', string 'rest', int32 '__slice2642320717952_start', class [mscorlib]System.Collections.Generic.List`1<string> 'parts', int32 '__iterlist11_idx', string 'part', string 'piece')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldarg.s 0
    callvirt instance string [mscorlib]System.String::Trim()
    stloc.s 1
    ldloc.s 1
    ldstr "import "
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    ldc.i4.0
    ceq
    brfalse imported_modules_If1_else
    ldarg.s 0
    call string TKVApp::'imported_module'(string)
    stloc.s 2
    ldloc.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse imported_modules_If2_else
    ldloc.s 0
    ldloc.s 2
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  imported_modules_If2_else:
    ldloc.s 0
    ret
  imported_modules_If1_else:
    ldc.i4 7
    stloc.s 4
    ldloc.s 1
    ldloc.s 4
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 4
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    ldstr "#;"
    call string TKVApp::'cut_at'(string, string)
    stloc.s 3
    ldloc.s 3
    ldc.i4.1
    newarr [mscorlib]System.Char
    dup
    ldc.i4.0
    ldstr ","
    ldc.i4.0
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    stelem.i2
    callvirt instance string[] [mscorlib]System.String::Split(char[])
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
    stloc.s 5
    ldc.i4.0
    stloc.s 6
  imported_modules_L3_start:
    ldloc.s 6
    ldloc.s 5
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge imported_modules_L3_end
    ldloc.s 5
    ldloc.s 6
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 7
    ldloc.s 7
    callvirt instance string [mscorlib]System.String::Trim()
    stloc.s 8
    ldloc.s 8
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse imported_modules_If4_else
    br imported_modules_L3_cont
  imported_modules_If4_else:
    ldloc.s 0
    ldloc.s 8
    ldstr " "
    call string TKVApp::'cut_at'(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  imported_modules_L3_cont:
    ldloc.s 6
    ldc.i4 1
    add
    stloc.s 6
    br imported_modules_L3_start
  imported_modules_L3_end:
    ldloc.s 0
    ret
  }
  .method public static int32 'count_marker'(string 'line', string 'mark') cil managed
  {
    .maxstack 8
    .locals init (int32 'n', int32 'i', int32 '__slice2642320716352_start')
    ldc.i4 0
    stloc.s 0
    ldc.i4 0
    stloc.s 1
  count_marker_W1_start:
    ldloc.s 1
    ldc.i4 3
    add
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    cgt
    ldc.i4.0
    ceq
    brfalse count_marker_W1_end
    ldloc.s 1
    stloc.s 2
    ldarg.s 0
    ldloc.s 2
    ldloc.s 1
    ldc.i4 3
    add
    ldloc.s 2
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    ldarg.s 1
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse count_marker_If2_else
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    ldloc.s 1
    ldc.i4 3
    add
    stloc.s 1
    br count_marker_If2_end
  count_marker_If2_else:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
  count_marker_If2_end:
    br count_marker_W1_start
  count_marker_W1_end:
    ldloc.s 0
    ret
  }
  .method public static int32 'count_triple'(string 'line') cil managed
  {
    .maxstack 8
    .locals init (int32 'a', int32 'b')
    ldarg.s 0
    ldstr "\"\"\""
    call int32 TKVApp::'count_marker'(string, string)
    stloc.s 0
    ldarg.s 0
    ldstr "'''"
    call int32 TKVApp::'count_marker'(string, string)
    stloc.s 1
    ldloc.s 0
    ldloc.s 1
    add
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'build_index'(class [mscorlib]System.Collections.Generic.List`1<string> 'paths') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', int32 '__iterlist12_idx', string 'rel', string 'dotted')
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 0
    ldc.i4.0
    stloc.s 1
  build_index_L1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge build_index_L1_end
    ldarg.s 0
    ldloc.s 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 2
    ldloc.s 2
    call string TKVApp::'dotted_from_rel'(string)
    stloc.s 3
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse build_index_If2_else
    br build_index_L1_cont
  build_index_If2_else:
    ldloc.s 0
    ldloc.s 3
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse build_index_If3_else
    ldloc.s 0
    ldloc.s 3
    call string TKVApp::'ambig_mark'()
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    br build_index_If3_end
  build_index_If3_else:
    ldloc.s 0
    ldloc.s 3
    ldloc.s 2
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  build_index_If3_end:
  build_index_L1_cont:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br build_index_L1_start
  build_index_L1_end:
    ldloc.s 0
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'build_base_index'(class [mscorlib]System.Collections.Generic.List`1<string> 'paths') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', int32 '__iterlist13_idx', string 'rel', string 'dotted', string 'base')
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 0
    ldc.i4.0
    stloc.s 1
  build_base_index_L1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge build_base_index_L1_end
    ldarg.s 0
    ldloc.s 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 2
    ldloc.s 2
    call string TKVApp::'dotted_from_rel'(string)
    stloc.s 3
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse build_base_index_If2_else
    br build_base_index_L1_cont
  build_base_index_If2_else:
    ldloc.s 3
    call string TKVApp::'last_seg'(string)
    stloc.s 4
    ldloc.s 0
    ldloc.s 4
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse build_base_index_If3_else
    ldloc.s 0
    ldloc.s 4
    call string TKVApp::'ambig_mark'()
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    br build_base_index_If3_end
  build_base_index_If3_else:
    ldloc.s 0
    ldloc.s 4
    ldloc.s 2
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  build_base_index_If3_end:
  build_base_index_L1_cont:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br build_base_index_L1_start
  build_base_index_L1_end:
    ldloc.s 0
    ret
  }
  .method public static string 'resolve_abs'(string 'mod', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'base_idx') cil managed
  {
    .maxstack 8
    .locals init (string 'probe', string 'hit', string 'base', string 'hit2')
    ldarg.s 0
    stloc.s 0
  resolve_abs_W1_start:
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse resolve_abs_W1_end
    ldarg.s 1
    ldloc.s 0
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse resolve_abs_dget2_miss
    ldarg.s 1
    ldloc.s 0
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br resolve_abs_dget2_end
  resolve_abs_dget2_miss:
    ldstr ""
  resolve_abs_dget2_end:
    stloc.s 1
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse resolve_abs_If3_else
    ldloc.s 1
    ret
  resolve_abs_If3_else:
    ldloc.s 0
    call string TKVApp::'drop_last_seg'(string)
    stloc.s 0
    br resolve_abs_W1_start
  resolve_abs_W1_end:
    ldarg.s 0
    call string TKVApp::'last_seg'(string)
    stloc.s 2
    ldarg.s 2
    ldloc.s 2
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse resolve_abs_dget4_miss
    ldarg.s 2
    ldloc.s 2
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br resolve_abs_dget4_end
  resolve_abs_dget4_miss:
    ldstr ""
  resolve_abs_dget4_end:
    stloc.s 3
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse resolve_abs_If5_else
    ldloc.s 3
    ret
  resolve_abs_If5_else:
    ldstr ""
    ret
  }
  .method public static string 'resolve_rel'(string 'mod', string 'src_rel', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx') cil managed
  {
    .maxstack 8
    .locals init (int32 'lvl', string 'tail', int32 '__slice2642320857968_start', string 'base', int32 'up', string 'pkg', string 'full', string 'probe', string 'hit')
    ldarg.s 0
    call int32 TKVApp::'leading_dots'(string)
    stloc.s 0
    ldloc.s 0
    stloc.s 2
    ldarg.s 0
    ldloc.s 2
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 2
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 1
    ldarg.s 1
    call string TKVApp::'dir_of_rel'(string)
    stloc.s 3
    ldloc.s 0
    ldc.i4 1
    sub
    stloc.s 4
  resolve_rel_W1_start:
    ldloc.s 4
    ldc.i4 0
    cgt
    brfalse resolve_rel_W1_end
    ldloc.s 3
    call string TKVApp::'dir_of_rel'(string)
    stloc.s 3
    ldloc.s 4
    ldc.i4 1
    sub
    stloc.s 4
    br resolve_rel_W1_start
  resolve_rel_W1_end:
    ldstr ""
    stloc.s 5
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse resolve_rel_If2_else
    ldloc.s 3
    ldstr "/x.py"
    call string [mscorlib]System.String::Concat(string, string)
    call string TKVApp::'dotted_from_rel'(string)
    stloc.s 5
    ldloc.s 5
    call string TKVApp::'drop_last_seg'(string)
    stloc.s 5
  resolve_rel_If2_else:
    ldloc.s 5
    stloc.s 6
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse resolve_rel_If3_else
    ldloc.s 6
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse resolve_rel_If4_else
    ldloc.s 6
    ldstr "."
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 6
    br resolve_rel_If4_end
  resolve_rel_If4_else:
    ldloc.s 1
    stloc.s 6
  resolve_rel_If4_end:
  resolve_rel_If3_else:
    ldloc.s 6
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse resolve_rel_If5_else
    ldstr ""
    ret
  resolve_rel_If5_else:
    ldloc.s 6
    stloc.s 7
  resolve_rel_W6_start:
    ldloc.s 7
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse resolve_rel_W6_end
    ldarg.s 2
    ldloc.s 7
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse resolve_rel_dget7_miss
    ldarg.s 2
    ldloc.s 7
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br resolve_rel_dget7_end
  resolve_rel_dget7_miss:
    ldstr ""
  resolve_rel_dget7_end:
    stloc.s 8
    ldloc.s 8
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse resolve_rel_If8_else
    ldloc.s 8
    ret
  resolve_rel_If8_else:
    ldloc.s 7
    call string TKVApp::'drop_last_seg'(string)
    stloc.s 7
    br resolve_rel_W6_start
  resolve_rel_W6_end:
    ldstr ""
    ret
  }
  .method public static string 'edge_json'(string 'src', string 'dst') cil managed
  {
    .maxstack 8
    ldstr "{\"source\":\"file:"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\",\"target\":\"file:"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\",\"type\":\"imports\",\"weight\":0.7}"
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'scan_file'(string 'rel', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'base_idx') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', string 'text', class [mscorlib]System.Collections.Generic.List`1<string> 'lines', int32 'in_doc', int32 '__iterlist14_idx', string 'ln', int32 'tri', int32 'was_doc', int32 '__idiv2642320853808_a', int32 '__idiv2642320853808_b', int32 '__idiv2642320853808_q', int32 '__idiv2642320853808_r', class [mscorlib]System.Collections.Generic.List`1<string> 'mods', int32 '__iterlist15_idx', string 'mod', string 'hit')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldarg.s 0
    call string [mscorlib]System.IO.File::ReadAllText(string)
    stloc.s 1
    ldloc.s 1
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
    stloc.s 2
    ldc.i4 0
    stloc.s 3
    ldc.i4.0
    stloc.s 4
  scan_file_L1_start:
    ldloc.s 4
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge scan_file_L1_end
    ldloc.s 2
    ldloc.s 4
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 5
    ldloc.s 5
    call int32 TKVApp::'count_triple'(string)
    stloc.s 6
    ldloc.s 3
    stloc.s 7
    ldloc.s 6
    ldc.i4 0
    cgt
    brfalse scan_file_If2_else
    ldloc.s 6
    stloc.s 8
    ldc.i4 2
    stloc.s 9
    ldloc.s 8
    ldloc.s 9
    div
    stloc.s 10
    ldloc.s 8
    ldloc.s 9
    rem
    stloc.s 11
    ldloc.s 11
    ldc.i4.0
    beq scan_file_idiv4_done
    ldloc.s 11
    ldloc.s 9
    xor
    ldc.i4.0
    bge scan_file_idiv4_done
    ldloc.s 11
    ldloc.s 9
    add
    stloc.s 11
  scan_file_idiv4_done:
    ldloc.s 11
    ldc.i4 1
    ceq
    brfalse scan_file_If3_else
    ldc.i4 1
    ldloc.s 3
    sub
    stloc.s 3
  scan_file_If3_else:
  scan_file_If2_else:
    ldloc.s 7
    ldc.i4 1
    ceq
    brfalse scan_file_If5_else
    br scan_file_L1_cont
  scan_file_If5_else:
    ldloc.s 6
    ldc.i4 0
    cgt
    dup
    brfalse scan_file_sc7_end
    pop
    ldloc.s 3
    ldc.i4 1
    ceq
  scan_file_sc7_end:
    brfalse scan_file_If6_else
    br scan_file_L1_cont
  scan_file_If6_else:
    ldloc.s 5
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'imported_modules'(string)
    stloc.s 12
    ldc.i4.0
    stloc.s 13
  scan_file_L8_start:
    ldloc.s 13
    ldloc.s 12
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge scan_file_L8_end
    ldloc.s 12
    ldloc.s 13
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 14
    ldloc.s 14
    ldstr "."
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    brfalse scan_file_If9_else
    ldloc.s 14
    ldarg.s 0
    ldarg.s 1
    call string TKVApp::'resolve_rel'(string, string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 15
    br scan_file_If9_end
  scan_file_If9_else:
    ldloc.s 14
    ldarg.s 1
    ldarg.s 2
    call string TKVApp::'resolve_abs'(string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 15
  scan_file_If9_end:
    ldloc.s 15
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse scan_file_If10_else
    ldloc.s 0
    ldstr "external|"
    ldloc.s 14
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br scan_file_If10_end
  scan_file_If10_else:
    ldloc.s 15
    call string TKVApp::'ambig_mark'()
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse scan_file_If11_else
    ldloc.s 0
    ldstr "ambiguous|"
    ldloc.s 14
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br scan_file_If11_end
  scan_file_If11_else:
    ldloc.s 15
    ldarg.s 0
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse scan_file_If12_else
    ldloc.s 0
    ldstr "self|"
    ldloc.s 14
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br scan_file_If12_end
  scan_file_If12_else:
    ldloc.s 0
    ldstr "internal|"
    ldloc.s 15
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  scan_file_If12_end:
  scan_file_If11_end:
  scan_file_If10_end:
  scan_file_L8_cont:
    ldloc.s 13
    ldc.i4 1
    add
    stloc.s 13
    br scan_file_L8_start
  scan_file_L8_end:
  scan_file_L1_cont:
    ldloc.s 4
    ldc.i4 1
    add
    stloc.s 4
    br scan_file_L1_start
  scan_file_L1_end:
    ldloc.s 0
    ret
  }
  .method public static string 'main'(string 'manifest', string 'out_path') cil managed
  {
    .maxstack 8
    .locals init (string 'raw', class [mscorlib]System.Collections.Generic.List`1<string> 'rows', class [mscorlib]System.Collections.Generic.List`1<string> 'paths', int32 '__iterlist16_idx', string 'r', string 'p', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'base_idx', int32 'n_total', int32 'n_int', int32 'n_ext', int32 'n_amb', int32 'n_self', int32 'n_dup', class [mscorlib]System.Collections.Generic.List`1<string> 'edges', class [System.Core]System.Collections.Generic.HashSet`1<string> 'seen', int32 '__iterlist17_idx', string 'rel', class [mscorlib]System.Collections.Generic.List`1<string> 'results', int32 '__iterlist18_idx', string 'res', string 'kind', string 'target', int32 '__slice2642320851728_start', string 'key', class [mscorlib]System.Collections.Generic.List`1<string> 'pieces', int32 'i', string 'body', string 'doc', int32 '__strtmp2642320809792', int32 '__strtmp2642320609792', int32 '__strtmp2642320737152', int32 '__strtmp2642320645376')
    ldarg.s 0
    call string [mscorlib]System.IO.File::ReadAllText(string)
    stloc.s 0
    ldloc.s 0
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
    stloc.s 1
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 2
    ldc.i4.0
    stloc.s 3
  main_L1_start:
    ldloc.s 3
    ldloc.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge main_L1_end
    ldloc.s 1
    ldloc.s 3
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 4
    ldloc.s 4
    callvirt instance string [mscorlib]System.String::Trim()
    call string TKVApp::'norm_slashes'(string)
    stloc.s 5
    ldloc.s 5
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse main_If2_else
    ldloc.s 2
    ldloc.s 5
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  main_If2_else:
  main_L1_cont:
    ldloc.s 3
    ldc.i4 1
    add
    stloc.s 3
    br main_L1_start
  main_L1_end:
    ldloc.s 2
    call class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> TKVApp::'build_index'(class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 6
    ldloc.s 2
    call class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> TKVApp::'build_base_index'(class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 7
    ldc.i4 0
    stloc.s 8
    ldc.i4 0
    stloc.s 9
    ldc.i4 0
    stloc.s 10
    ldc.i4 0
    stloc.s 11
    ldc.i4 0
    stloc.s 12
    ldc.i4 0
    stloc.s 13
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 14
    newobj instance void class [System.Core]System.Collections.Generic.HashSet`1<string>::.ctor()
    stloc.s 15
    ldc.i4.0
    stloc.s 16
  main_L3_start:
    ldloc.s 16
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge main_L3_end
    ldloc.s 2
    ldloc.s 16
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 17
    ldloc.s 17
    ldloc.s 6
    ldloc.s 7
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'scan_file'(string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 18
    ldc.i4.0
    stloc.s 19
  main_L4_start:
    ldloc.s 19
    ldloc.s 18
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge main_L4_end
    ldloc.s 18
    ldloc.s 19
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 20
    ldloc.s 8
    ldc.i4 1
    add
    stloc.s 8
    ldloc.s 20
    ldstr "|"
    call string TKVApp::'cut_at'(string, string)
    stloc.s 21
    ldloc.s 21
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 1
    add
    stloc.s 23
    ldloc.s 20
    ldloc.s 23
    ldloc.s 20
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 23
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 22
    ldloc.s 21
    ldstr "internal"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse main_If5_else
    ldloc.s 9
    ldc.i4 1
    add
    stloc.s 9
    ldloc.s 17
    ldstr ">"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 22
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 24
    ldloc.s 15
    ldloc.s 24
    callvirt instance bool class [System.Core]System.Collections.Generic.HashSet`1<string>::Contains(!0)
    brfalse main_If6_else
    ldloc.s 13
    ldc.i4 1
    add
    stloc.s 13
    br main_L4_cont
  main_If6_else:
    ldloc.s 15
    ldloc.s 24
    callvirt instance bool class [System.Core]System.Collections.Generic.HashSet`1<string>::Add(!0)
    pop
    ldloc.s 14
    ldloc.s 17
    ldloc.s 22
    call string TKVApp::'edge_json'(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br main_If5_end
  main_If5_else:
    ldloc.s 21
    ldstr "external"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse main_If7_else
    ldloc.s 10
    ldc.i4 1
    add
    stloc.s 10
    br main_If7_end
  main_If7_else:
    ldloc.s 21
    ldstr "ambiguous"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse main_If8_else
    ldloc.s 11
    ldc.i4 1
    add
    stloc.s 11
    br main_If8_end
  main_If8_else:
    ldloc.s 12
    ldc.i4 1
    add
    stloc.s 12
  main_If8_end:
  main_If7_end:
  main_If5_end:
  main_L4_cont:
    ldloc.s 19
    ldc.i4 1
    add
    stloc.s 19
    br main_L4_start
  main_L4_end:
  main_L3_cont:
    ldloc.s 16
    ldc.i4 1
    add
    stloc.s 16
    br main_L3_start
  main_L3_end:
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 25
    ldc.i4 0
    stloc.s 26
  main_W9_start:
    ldloc.s 26
    ldloc.s 14
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse main_W9_end
    ldloc.s 25
    ldstr "  "
    ldloc.s 14
    ldloc.s 26
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 26
    ldc.i4 1
    add
    stloc.s 26
    br main_W9_start
  main_W9_end:
    ldstr ",\n"
    ldloc.s 25
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    stloc.s 27
    ldstr "{\n \"edges\": [\n"
    ldloc.s 27
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\n ],\n \"stats\": {"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 28
    ldloc.s 28
    ldstr "\"files\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 29
    ldloca.s 29
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 28
    ldloc.s 28
    ldstr ",\"imports\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 8
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 28
    ldloc.s 28
    ldstr ",\"internal\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 9
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 28
    ldloc.s 28
    ldstr ",\"external\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 10
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 28
    ldloc.s 28
    ldstr ",\"ambiguous\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 11
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 28
    ldloc.s 28
    ldstr ",\"self\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 12
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 28
    ldloc.s 28
    ldstr ",\"dup_dropped\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 13
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 28
    ldloc.s 28
    ldstr ",\"edges\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 14
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 30
    ldloca.s 30
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 28
    ldloc.s 28
    ldstr "}\n}\n"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 28
    ldarg.s 1
    ldloc.s 28
    call void [mscorlib]System.IO.File::WriteAllText(string, string)
    ldstr "files="
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 31
    ldloca.s 31
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " imports="
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 8
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " internal="
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 9
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " external="
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 10
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " ambiguous="
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 11
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " self="
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 12
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " dup="
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 13
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " edges="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 14
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 32
    ldloca.s 32
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static int32 'is_digit'(string 'ch') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr "0"
    call int32 [mscorlib]System.String::CompareOrdinal(string, string)
    ldc.i4.0
    clt
    ldc.i4.0
    ceq
    brfalse is_digit_If1_else
    ldarg.s 0
    ldstr "9"
    call int32 [mscorlib]System.String::CompareOrdinal(string, string)
    ldc.i4.0
    cgt
    ldc.i4.0
    ceq
    brfalse is_digit_If2_else
    ldc.i4 1
    ret
  is_digit_If2_else:
  is_digit_If1_else:
    ldc.i4 0
    ret
  }
  .method public static int32 'is_name_start'(string 'ch') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr "_"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_name_start_If1_else
    ldc.i4 1
    ret
  is_name_start_If1_else:
    ldarg.s 0
    ldstr "a"
    call int32 [mscorlib]System.String::CompareOrdinal(string, string)
    ldc.i4.0
    clt
    ldc.i4.0
    ceq
    brfalse is_name_start_If2_else
    ldarg.s 0
    ldstr "z"
    call int32 [mscorlib]System.String::CompareOrdinal(string, string)
    ldc.i4.0
    cgt
    ldc.i4.0
    ceq
    brfalse is_name_start_If3_else
    ldc.i4 1
    ret
  is_name_start_If3_else:
  is_name_start_If2_else:
    ldarg.s 0
    ldstr "A"
    call int32 [mscorlib]System.String::CompareOrdinal(string, string)
    ldc.i4.0
    clt
    ldc.i4.0
    ceq
    brfalse is_name_start_If4_else
    ldarg.s 0
    ldstr "Z"
    call int32 [mscorlib]System.String::CompareOrdinal(string, string)
    ldc.i4.0
    cgt
    ldc.i4.0
    ceq
    brfalse is_name_start_If5_else
    ldc.i4 1
    ret
  is_name_start_If5_else:
  is_name_start_If4_else:
    ldarg.s 0
    ldstr "~"
    call int32 [mscorlib]System.String::CompareOrdinal(string, string)
    ldc.i4.0
    cgt
    brfalse is_name_start_If6_else
    ldc.i4 1
    ret
  is_name_start_If6_else:
    ldc.i4 0
    ret
  }
  .method public static int32 'is_name_char'(string 'ch') cil managed
  {
    .maxstack 8
    ldarg.s 0
    call int32 TKVApp::'is_name_start'(string)
    ldc.i4 1
    ceq
    brfalse is_name_char_If1_else
    ldc.i4 1
    ret
  is_name_char_If1_else:
    ldarg.s 0
    call int32 TKVApp::'is_digit'(string)
    ret
  }
  .method public static int32 'is_quote'(string 'ch') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr "\""
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_quote_If1_else
    ldc.i4 1
    ret
  is_quote_If1_else:
    ldarg.s 0
    ldstr "'"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_quote_If2_else
    ldc.i4 1
    ret
  is_quote_If2_else:
    ldc.i4 0
    ret
  }
  .method public static int32 'is_space'(string 'ch') cil managed
  {
    .maxstack 8
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
    ldc.i4 0
    ret
  }
  .method public static int32 'is_bracket_open'(string 'ch') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr "("
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_bracket_open_If1_else
    ldc.i4 1
    ret
  is_bracket_open_If1_else:
    ldarg.s 0
    ldstr "["
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_bracket_open_If2_else
    ldc.i4 1
    ret
  is_bracket_open_If2_else:
    ldarg.s 0
    ldstr "{"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_bracket_open_If3_else
    ldc.i4 1
    ret
  is_bracket_open_If3_else:
    ldc.i4 0
    ret
  }
  .method public static int32 'is_bracket_close'(string 'ch') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr ")"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_bracket_close_If1_else
    ldc.i4 1
    ret
  is_bracket_close_If1_else:
    ldarg.s 0
    ldstr "]"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_bracket_close_If2_else
    ldc.i4 1
    ret
  is_bracket_close_If2_else:
    ldarg.s 0
    ldstr "}"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse is_bracket_close_If3_else
    ldc.i4 1
    ret
  is_bracket_close_If3_else:
    ldc.i4 0
    ret
  }
  .method public static string 'triple_at'(string 'src', int32 'i') cil managed
  {
    .maxstack 8
    .locals init (string 'three', int32 '__slice2642320714832_start')
    ldarg.s 1
    ldc.i4 3
    add
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    cgt
    brfalse triple_at_If1_else
    ldstr ""
    ret
  triple_at_If1_else:
    ldarg.s 1
    stloc.s 1
    ldarg.s 0
    ldloc.s 1
    ldarg.s 1
    ldc.i4 3
    add
    ldloc.s 1
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 0
    ldloc.s 0
    ldstr "\"\"\""
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse triple_at_If2_else
    ldloc.s 0
    ret
  triple_at_If2_else:
    ldloc.s 0
    ldstr "'''"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse triple_at_If3_else
    ldloc.s 0
    ret
  triple_at_If3_else:
    ldstr ""
    ret
  }
  .method public static int32 'skip_string'(string 'src', int32 'i') cil managed
  {
    .maxstack 8
    .locals init (string 'tri', int32 'j', string 'q', string 'ch')
    ldarg.s 0
    ldarg.s 1
    call string TKVApp::'triple_at'(string, int32)
    stloc.s 0
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse skip_string_If1_else
    ldarg.s 1
    ldc.i4 3
    add
    stloc.s 1
  skip_string_W2_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse skip_string_W2_end
    ldarg.s 0
    ldloc.s 1
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ldstr "\\"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse skip_string_If3_else
    ldloc.s 1
    ldc.i4 2
    add
    stloc.s 1
    br skip_string_W2_start
  skip_string_If3_else:
    ldarg.s 0
    ldloc.s 1
    call string TKVApp::'triple_at'(string, int32)
    ldloc.s 0
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse skip_string_If4_else
    ldloc.s 1
    ldc.i4 3
    add
    ret
  skip_string_If4_else:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br skip_string_W2_start
  skip_string_W2_end:
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ret
  skip_string_If1_else:
    ldarg.s 0
    ldarg.s 1
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    stloc.s 2
    ldarg.s 1
    ldc.i4 1
    add
    stloc.s 1
  skip_string_W5_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse skip_string_W5_end
    ldarg.s 0
    ldloc.s 1
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    stloc.s 3
    ldloc.s 3
    ldstr "\\"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse skip_string_If6_else
    ldloc.s 1
    ldc.i4 2
    add
    stloc.s 1
    br skip_string_W5_start
  skip_string_If6_else:
    ldloc.s 3
    ldloc.s 2
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse skip_string_If7_else
    ldloc.s 1
    ldc.i4 1
    add
    ret
  skip_string_If7_else:
    ldloc.s 3
    ldstr "\n"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse skip_string_If8_else
    ldloc.s 1
    ret
  skip_string_If8_else:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br skip_string_W5_start
  skip_string_W5_end:
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ret
  }
  .method public static int32 'indent_width'(string 'src', int32 'i') cil managed
  {
    .maxstack 8
    .locals init (int32 'n', int32 'j', string 'ch')
    ldc.i4 0
    stloc.s 0
    ldarg.s 1
    stloc.s 1
  indent_width_W1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse indent_width_W1_end
    ldarg.s 0
    ldloc.s 1
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    stloc.s 2
    ldloc.s 2
    ldstr " "
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse indent_width_If2_else
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    br indent_width_If2_end
  indent_width_If2_else:
    ldloc.s 2
    ldstr "\t"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse indent_width_If3_else
    ldloc.s 0
    ldc.i4 4
    add
    stloc.s 0
    br indent_width_If3_end
  indent_width_If3_else:
    ldloc.s 0
    ret
  indent_width_If3_end:
  indent_width_If2_end:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br indent_width_W1_start
  indent_width_W1_end:
    ldloc.s 0
    ret
  }
  .method public static int32 'is_str_prefix'(string 'word') cil managed
  {
    .maxstack 8
    .locals init (string 'low', int32 'i', string 'ch')
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse is_str_prefix_If1_else
    ldc.i4 0
    ret
  is_str_prefix_If1_else:
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 2
    cgt
    brfalse is_str_prefix_If2_else
    ldc.i4 0
    ret
  is_str_prefix_If2_else:
    ldarg.s 0
    callvirt instance string [mscorlib]System.String::ToLower()
    stloc.s 0
    ldc.i4 0
    stloc.s 1
  is_str_prefix_W3_start:
    ldloc.s 1
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse is_str_prefix_W3_end
    ldloc.s 0
    ldloc.s 1
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    stloc.s 2
    ldloc.s 2
    ldstr "r"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse is_str_prefix_If4_else
    ldloc.s 2
    ldstr "b"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse is_str_prefix_If5_else
    ldloc.s 2
    ldstr "u"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse is_str_prefix_If6_else
    ldloc.s 2
    ldstr "f"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse is_str_prefix_If7_else
    ldc.i4 0
    ret
  is_str_prefix_If7_else:
  is_str_prefix_If6_else:
  is_str_prefix_If5_else:
  is_str_prefix_If4_else:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br is_str_prefix_W3_start
  is_str_prefix_W3_end:
    ldc.i4 1
    ret
  }
  .method public static int32 'has_f'(string 'word') cil managed
  {
    .maxstack 8
    .locals init (string 'low')
    ldarg.s 0
    callvirt instance string [mscorlib]System.String::ToLower()
    stloc.s 0
    ldloc.s 0
    ldstr "f"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse has_f_If1_else
    ldc.i4 1
    ret
  has_f_If1_else:
    ldc.i4 0
    ret
  }
  .method public static int32 'inner_exprs'(string 'seg', class [mscorlib]System.Collections.Generic.List`1<string> 'out') cil managed
  {
    .maxstack 8
    .locals init (int32 'i', int32 'n', string 'ch', int32 'depth', int32 'j', int32 'start', string 'c2', int32 '__slice2642320714272_start')
    ldc.i4 0
    stloc.s 0
    ldc.i4 0
    stloc.s 1
  inner_exprs_W1_start:
    ldloc.s 0
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse inner_exprs_W1_end
    ldarg.s 0
    ldloc.s 0
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    stloc.s 2
    ldloc.s 2
    ldstr "{"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse inner_exprs_If2_else
    ldloc.s 0
    ldc.i4 1
    add
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse inner_exprs_If3_else
    ldarg.s 0
    ldloc.s 0
    ldc.i4 1
    add
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ldstr "{"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse inner_exprs_If4_else
    ldloc.s 0
    ldc.i4 2
    add
    stloc.s 0
    br inner_exprs_W1_start
  inner_exprs_If4_else:
  inner_exprs_If3_else:
    ldc.i4 1
    stloc.s 3
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 4
    ldloc.s 4
    stloc.s 5
  inner_exprs_W5_start:
    ldloc.s 4
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse inner_exprs_W5_end
    ldarg.s 0
    ldloc.s 4
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    stloc.s 6
    ldloc.s 6
    ldstr "{"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse inner_exprs_If6_else
    ldloc.s 3
    ldc.i4 1
    add
    stloc.s 3
    br inner_exprs_If6_end
  inner_exprs_If6_else:
    ldloc.s 6
    ldstr "}"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse inner_exprs_If7_else
    ldloc.s 3
    ldc.i4 1
    sub
    stloc.s 3
    ldloc.s 3
    ldc.i4 0
    ceq
    brfalse inner_exprs_If8_else
    br inner_exprs_W5_end
  inner_exprs_If8_else:
  inner_exprs_If7_else:
  inner_exprs_If6_end:
    ldloc.s 4
    ldc.i4 1
    add
    stloc.s 4
    br inner_exprs_W5_start
  inner_exprs_W5_end:
    ldarg.s 1
    ldloc.s 5
    stloc.s 7
    ldarg.s 0
    ldloc.s 7
    ldloc.s 4
    ldloc.s 7
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    ldloc.s 4
    ldc.i4 1
    add
    stloc.s 0
    br inner_exprs_W1_start
  inner_exprs_If2_else:
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    br inner_exprs_W1_start
  inner_exprs_W1_end:
    ldloc.s 1
    ret
  }
  .method public static int32 'row_is_bol'(string 'row') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr "	BOL	"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse row_is_bol_If1_else
    ldc.i4 1
    ret
  row_is_bol_If1_else:
    ldc.i4 0
    ret
  }
  .method public static string 'row_rest'(string 'row') cil managed
  {
    .maxstack 8
    .locals init (int32 'at', int32 '__slice2642321073040_start')
    ldarg.s 0
    ldstr "	"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 0
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 1
    ldarg.s 0
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 1
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    ret
  }
  .method public static int32 'emit_inner'(string 'seg', int32 'fs_line', class [mscorlib]System.Collections.Generic.List`1<string> 'out') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'tmp', int32 'n', int32 '__iterlist19_idx', string 'row')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldarg.s 0
    ldloc.s 0
    call int32 TKVApp::'tokenize'(string, class [mscorlib]System.Collections.Generic.List`1<string>)
    pop
    ldc.i4 0
    stloc.s 1
    ldc.i4.0
    stloc.s 2
  emit_inner_L1_start:
    ldloc.s 2
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge emit_inner_L1_end
    ldloc.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 3
    ldloc.s 3
    call int32 TKVApp::'row_is_bol'(string)
    ldc.i4 0
    ceq
    brfalse emit_inner_If2_else
    ldarg.s 2
    ldarga.s 1
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    ldstr "	"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 3
    call string TKVApp::'row_rest'(string)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
  emit_inner_If2_else:
  emit_inner_L1_cont:
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    br emit_inner_L1_start
  emit_inner_L1_end:
    ldloc.s 1
    ret
  }
  .method public static int32 'indent_before'(string 'src', int32 'i') cil managed
  {
    .maxstack 8
    .locals init (int32 'j', int32 'n', string 'ch')
    ldarg.s 1
    ldc.i4 1
    sub
    stloc.s 0
    ldc.i4 0
    stloc.s 1
  indent_before_W1_start:
    ldloc.s 0
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse indent_before_W1_end
    ldarg.s 0
    ldloc.s 0
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    stloc.s 2
    ldloc.s 2
    ldstr "\n"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse indent_before_If2_else
    ldloc.s 1
    ret
  indent_before_If2_else:
    ldloc.s 2
    ldstr " "
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse indent_before_If3_else
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br indent_before_If3_end
  indent_before_If3_else:
    ldloc.s 2
    ldstr "\t"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse indent_before_If4_else
    ldloc.s 1
    ldc.i4 4
    add
    stloc.s 1
    br indent_before_If4_end
  indent_before_If4_else:
    ldloc.s 1
    ret
  indent_before_If4_end:
  indent_before_If3_end:
    ldloc.s 0
    ldc.i4 1
    sub
    stloc.s 0
    br indent_before_W1_start
  indent_before_W1_end:
    ldloc.s 1
    ret
  }
  .method public static int32 'blank_or_comment'(string 'src', int32 'i') cil managed
  {
    .maxstack 8
    .locals init (int32 'j', string 'ch')
    ldarg.s 1
    stloc.s 0
  blank_or_comment_W1_start:
    ldloc.s 0
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse blank_or_comment_W1_end
    ldarg.s 0
    ldloc.s 0
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    stloc.s 1
    ldloc.s 1
    ldstr "\n"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse blank_or_comment_If2_else
    ldc.i4 1
    ret
  blank_or_comment_If2_else:
    ldloc.s 1
    ldstr "#"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse blank_or_comment_If3_else
    ldc.i4 1
    ret
  blank_or_comment_If3_else:
    ldloc.s 1
    call int32 TKVApp::'is_space'(string)
    ldc.i4 0
    ceq
    brfalse blank_or_comment_If4_else
    ldc.i4 0
    ret
  blank_or_comment_If4_else:
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    br blank_or_comment_W1_start
  blank_or_comment_W1_end:
    ldc.i4 1
    ret
  }
  .method public static int32 'emit'(class [mscorlib]System.Collections.Generic.List`1<string> 'out', int32 'line', string 'kind', string 'text') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldarga.s 1
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    ldstr "\t"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\t"
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 3
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldc.i4 1
    ret
  }
  .method public static int32 'tokenize'(string 'src', class [mscorlib]System.Collections.Generic.List`1<string> 'out') cil managed
  {
    .maxstack 8
    .locals init (int32 'i', int32 'line', int32 'depth', int32 'at_bol', int32 'logical', int32 'cont', string 'ch', int32 'j', int32 '__strtmp2642320908032', int32 'start_line', int32 'nxt', string 'seg', int32 '__slice2642320851168_start', int32 'k', string 'word', int32 '__slice2642320716192_start', int32 'fs_line', int32 'nxt2', string 'seg2', int32 '__slice2642320716352_start', int32 'k2', class [mscorlib]System.Collections.Generic.List`1<string> 'parts', int32 '__iterlist20_idx', string 'p', int32 '__slice2642315029424_start')
    ldc.i4 0
    stloc.s 0
    ldc.i4 1
    stloc.s 1
    ldc.i4 0
    stloc.s 2
    ldc.i4 1
    stloc.s 3
    ldc.i4 0
    stloc.s 4
    ldc.i4 0
    stloc.s 5
  tokenize_W1_start:
    ldloc.s 0
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse tokenize_W1_end
    ldarg.s 0
    ldloc.s 0
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    stloc.s 6
    ldloc.s 6
    ldstr "\n"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse tokenize_If2_else
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    ldloc.s 2
    ldc.i4 0
    ceq
    brfalse tokenize_If3_else
    ldloc.s 5
    ldc.i4 0
    ceq
    brfalse tokenize_If4_else
    ldc.i4 1
    stloc.s 3
  tokenize_If4_else:
  tokenize_If3_else:
    ldc.i4 0
    stloc.s 5
    br tokenize_W1_start
  tokenize_If2_else:
    ldloc.s 3
    ldc.i4 1
    ceq
    brfalse tokenize_If5_else
    ldloc.s 6
    call int32 TKVApp::'is_space'(string)
    ldc.i4 1
    ceq
    brfalse tokenize_If6_else
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    br tokenize_W1_start
  tokenize_If6_else:
    ldarg.s 0
    ldloc.s 0
    call int32 TKVApp::'blank_or_comment'(string, int32)
    ldc.i4 1
    ceq
    brfalse tokenize_If7_else
    ldloc.s 6
    ldstr "#"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse tokenize_If8_else
    ldloc.s 0
    stloc.s 7
  tokenize_W9_start:
    ldloc.s 7
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse tokenize_W9_end
    ldarg.s 0
    ldloc.s 7
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ldstr "\n"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse tokenize_If10_else
    br tokenize_W9_end
  tokenize_If10_else:
    ldloc.s 7
    ldc.i4 1
    add
    stloc.s 7
    br tokenize_W9_start
  tokenize_W9_end:
    ldarg.s 1
    ldloc.s 1
    ldstr "CMT"
    ldstr ""
    call int32 TKVApp::'emit'(class [mscorlib]System.Collections.Generic.List`1<string>, int32, string, string)
    pop
    ldloc.s 7
    stloc.s 0
    br tokenize_W1_start
  tokenize_If8_else:
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    br tokenize_W1_start
  tokenize_If7_else:
    ldarg.s 1
    ldloc.s 1
    ldstr "BOL"
    ldarg.s 0
    ldloc.s 0
    call int32 TKVApp::'indent_before'(string, int32)
    stloc.s 8
    ldloca.s 8
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call int32 TKVApp::'emit'(class [mscorlib]System.Collections.Generic.List`1<string>, int32, string, string)
    pop
    ldloc.s 4
    ldc.i4 1
    add
    stloc.s 4
    ldc.i4 0
    stloc.s 3
  tokenize_If5_else:
    ldloc.s 6
    call int32 TKVApp::'is_space'(string)
    ldc.i4 1
    ceq
    brfalse tokenize_If11_else
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    br tokenize_W1_start
  tokenize_If11_else:
    ldloc.s 6
    ldstr "#"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse tokenize_If12_else
    ldloc.s 0
    stloc.s 7
  tokenize_W13_start:
    ldloc.s 7
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse tokenize_W13_end
    ldarg.s 0
    ldloc.s 7
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ldstr "\n"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse tokenize_If14_else
    br tokenize_W13_end
  tokenize_If14_else:
    ldloc.s 7
    ldc.i4 1
    add
    stloc.s 7
    br tokenize_W13_start
  tokenize_W13_end:
    ldarg.s 1
    ldloc.s 1
    ldstr "CMT"
    ldstr ""
    call int32 TKVApp::'emit'(class [mscorlib]System.Collections.Generic.List`1<string>, int32, string, string)
    pop
    ldloc.s 7
    stloc.s 0
    br tokenize_W1_start
  tokenize_If12_else:
    ldloc.s 6
    ldstr "\\"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse tokenize_If15_else
    ldc.i4 1
    stloc.s 5
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    br tokenize_W1_start
  tokenize_If15_else:
    ldloc.s 6
    call int32 TKVApp::'is_quote'(string)
    ldc.i4 1
    ceq
    brfalse tokenize_If16_else
    ldloc.s 1
    stloc.s 9
    ldarg.s 0
    ldloc.s 0
    call int32 TKVApp::'skip_string'(string, int32)
    stloc.s 10
    ldloc.s 0
    stloc.s 12
    ldarg.s 0
    ldloc.s 12
    ldloc.s 10
    ldloc.s 12
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 11
    ldc.i4 0
    stloc.s 13
  tokenize_W17_start:
    ldloc.s 13
    ldloc.s 11
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse tokenize_W17_end
    ldloc.s 11
    ldloc.s 13
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ldstr "\n"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse tokenize_If18_else
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
  tokenize_If18_else:
    ldloc.s 13
    ldc.i4 1
    add
    stloc.s 13
    br tokenize_W17_start
  tokenize_W17_end:
    ldarg.s 1
    ldloc.s 9
    ldstr "STR"
    ldstr ""
    call int32 TKVApp::'emit'(class [mscorlib]System.Collections.Generic.List`1<string>, int32, string, string)
    pop
    ldloc.s 10
    stloc.s 0
    br tokenize_W1_start
  tokenize_If16_else:
    ldloc.s 6
    call int32 TKVApp::'is_name_start'(string)
    ldc.i4 1
    ceq
    brfalse tokenize_If19_else
    ldloc.s 0
    stloc.s 7
  tokenize_W20_start:
    ldloc.s 7
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse tokenize_W20_end
    ldarg.s 0
    ldloc.s 7
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    call int32 TKVApp::'is_name_char'(string)
    ldc.i4 0
    ceq
    brfalse tokenize_If21_else
    br tokenize_W20_end
  tokenize_If21_else:
    ldloc.s 7
    ldc.i4 1
    add
    stloc.s 7
    br tokenize_W20_start
  tokenize_W20_end:
    ldloc.s 0
    stloc.s 15
    ldarg.s 0
    ldloc.s 15
    ldloc.s 7
    ldloc.s 15
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 14
    ldloc.s 7
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse tokenize_If22_else
    ldarg.s 0
    ldloc.s 7
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    call int32 TKVApp::'is_quote'(string)
    ldc.i4 1
    ceq
    brfalse tokenize_If23_else
    ldloc.s 14
    call int32 TKVApp::'is_str_prefix'(string)
    ldc.i4 1
    ceq
    brfalse tokenize_If24_else
    ldloc.s 1
    stloc.s 16
    ldarg.s 0
    ldloc.s 7
    call int32 TKVApp::'skip_string'(string, int32)
    stloc.s 17
    ldloc.s 7
    stloc.s 19
    ldarg.s 0
    ldloc.s 19
    ldloc.s 17
    ldloc.s 19
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 18
    ldc.i4 0
    stloc.s 20
  tokenize_W25_start:
    ldloc.s 20
    ldloc.s 18
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse tokenize_W25_end
    ldloc.s 18
    ldloc.s 20
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ldstr "\n"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse tokenize_If26_else
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
  tokenize_If26_else:
    ldloc.s 20
    ldc.i4 1
    add
    stloc.s 20
    br tokenize_W25_start
  tokenize_W25_end:
    ldarg.s 1
    ldloc.s 16
    ldstr "STR"
    ldstr ""
    call int32 TKVApp::'emit'(class [mscorlib]System.Collections.Generic.List`1<string>, int32, string, string)
    pop
    ldloc.s 14
    call int32 TKVApp::'has_f'(string)
    ldc.i4 1
    ceq
    brfalse tokenize_If27_else
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 21
    ldloc.s 18
    ldloc.s 21
    call int32 TKVApp::'inner_exprs'(string, class [mscorlib]System.Collections.Generic.List`1<string>)
    pop
    ldc.i4.0
    stloc.s 22
  tokenize_L28_start:
    ldloc.s 22
    ldloc.s 21
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge tokenize_L28_end
    ldloc.s 21
    ldloc.s 22
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 23
    ldloc.s 23
    ldloc.s 16
    ldarg.s 1
    call int32 TKVApp::'emit_inner'(string, int32, class [mscorlib]System.Collections.Generic.List`1<string>)
    pop
  tokenize_L28_cont:
    ldloc.s 22
    ldc.i4 1
    add
    stloc.s 22
    br tokenize_L28_start
  tokenize_L28_end:
  tokenize_If27_else:
    ldloc.s 17
    stloc.s 0
    br tokenize_W1_start
  tokenize_If24_else:
  tokenize_If23_else:
  tokenize_If22_else:
    ldarg.s 1
    ldloc.s 1
    ldstr "NAME"
    ldloc.s 14
    call int32 TKVApp::'emit'(class [mscorlib]System.Collections.Generic.List`1<string>, int32, string, string)
    pop
    ldloc.s 7
    stloc.s 0
    br tokenize_W1_start
  tokenize_If19_else:
    ldloc.s 6
    call int32 TKVApp::'is_digit'(string)
    ldc.i4 1
    ceq
    brfalse tokenize_If29_else
    ldloc.s 0
    stloc.s 7
  tokenize_W30_start:
    ldloc.s 7
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse tokenize_W30_end
    ldarg.s 0
    ldloc.s 7
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    call int32 TKVApp::'is_name_char'(string)
    ldc.i4 0
    ceq
    brfalse tokenize_If31_else
    ldarg.s 0
    ldloc.s 7
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ldstr "."
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse tokenize_If32_else
    br tokenize_W30_end
  tokenize_If32_else:
  tokenize_If31_else:
    ldloc.s 7
    ldc.i4 1
    add
    stloc.s 7
    br tokenize_W30_start
  tokenize_W30_end:
    ldarg.s 1
    ldloc.s 1
    ldstr "NUM"
    ldloc.s 0
    stloc.s 24
    ldarg.s 0
    ldloc.s 24
    ldloc.s 7
    ldloc.s 24
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    call int32 TKVApp::'emit'(class [mscorlib]System.Collections.Generic.List`1<string>, int32, string, string)
    pop
    ldloc.s 7
    stloc.s 0
    br tokenize_W1_start
  tokenize_If29_else:
    ldloc.s 6
    call int32 TKVApp::'is_bracket_open'(string)
    ldc.i4 1
    ceq
    brfalse tokenize_If33_else
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
  tokenize_If33_else:
    ldloc.s 6
    call int32 TKVApp::'is_bracket_close'(string)
    ldc.i4 1
    ceq
    brfalse tokenize_If34_else
    ldloc.s 2
    ldc.i4 0
    cgt
    brfalse tokenize_If35_else
    ldloc.s 2
    ldc.i4 1
    sub
    stloc.s 2
  tokenize_If35_else:
  tokenize_If34_else:
    ldarg.s 1
    ldloc.s 1
    ldstr "OP"
    ldloc.s 6
    call int32 TKVApp::'emit'(class [mscorlib]System.Collections.Generic.List`1<string>, int32, string, string)
    pop
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    br tokenize_W1_start
  tokenize_W1_end:
    ldloc.s 4
    ret
  }
  .method public static string 'tok_run'(string 'src_path', string 'out_path') cil managed
  {
    .maxstack 8
    .locals init (string 'src', class [mscorlib]System.Collections.Generic.List`1<string> 'out', int32 'logical', string 'body', int32 '__strtmp2642320900160')
    ldarg.s 0
    call string [mscorlib]System.IO.File::ReadAllText(string)
    stloc.s 0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 1
    ldloc.s 0
    ldloc.s 1
    call int32 TKVApp::'tokenize'(string, class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 2
    ldstr "\n"
    ldloc.s 1
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    stloc.s 3
    ldarg.s 1
    ldloc.s 3
    call void [mscorlib]System.IO.File::WriteAllText(string, string)
    ldstr "tokens="
    ldloc.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 4
    ldloca.s 4
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " dong_logic="
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 2
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
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
    call string TKVApp::'run'(string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ret
  }
}
