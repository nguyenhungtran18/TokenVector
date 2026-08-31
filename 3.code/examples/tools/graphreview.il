.assembly extern mscorlib {}
.assembly extern System.Core { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly extern System { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly TKVApp {}
.module TKVApp.exe

.class public auto ansi TKVApp extends [mscorlib]System.Object
{
  .method public static int32 'max_listed'() cil managed
  {
    .maxstack 8
    ldc.i4 40
    ret
  }
  .method public static string 'valid_edge_types'() cil managed
  {
    .maxstack 8
    ldstr "|imports|contains|calls|inherits|"
    ret
  }
  .method public static string 'valid_prefixes'() cil managed
  {
    .maxstack 8
    ldstr "|file|function|class|"
    ret
  }
  .method public static string 'str_field'(string 'line', string 'key') cil managed
  {
    .maxstack 8
    .locals init (string 'pat', int32 'at', string 'rest', int32 '__slice2133124782560_start')
    ldstr "\""
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\":\""
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
    ldarg.s 0
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 1
    ldloc.s 1
    ldc.i4 0
    clt
    brfalse str_field_If1_else
    ldstr ""
    ret
  str_field_If1_else:
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
    ldstr "\""
    call string TKVApp::'cut_at'(string, string)
    ret
  }
  .method public static string 'num_field'(string 'line', string 'key') cil managed
  {
    .maxstack 8
    .locals init (string 'pat', int32 'at', string 'rest', int32 '__slice2133124783600_start')
    ldstr "\""
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\":"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
    ldarg.s 0
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 1
    ldloc.s 1
    ldc.i4 0
    clt
    brfalse num_field_If1_else
    ldstr ""
    ret
  num_field_If1_else:
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
    ldstr ",}"
    call string TKVApp::'cut_at'(string, string)
    ret
  }
  .method public static string 'id_prefix'(string 'node') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr ":"
    call string TKVApp::'cut_at'(string, string)
    ret
  }
  .method public static string 'id_file'(string 'node') cil managed
  {
    .maxstack 8
    .locals init (string 'pre', string 'rest', int32 '__slice2133124784480_start')
    ldarg.s 0
    call string TKVApp::'id_prefix'(string)
    stloc.s 0
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 1
    add
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    cgt
    brfalse id_file_If1_else
    ldstr ""
    ret
  id_file_If1_else:
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
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
    ldstr ":"
    call string TKVApp::'cut_at'(string, string)
    ret
  }
  .method public static int32 'in_enum'(string 'enum_blob', string 'name') cil managed
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
    brfalse in_enum_If1_else
    ldc.i4 1
    ret
  in_enum_If1_else:
    ldc.i4 0
    ret
  }
  .method public static string 'check_edge'(string 'line', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'files') cil managed
  {
    .maxstack 8
    .locals init (string 'src', string 'tgt', string 'etype', string 'wtxt', string 'spre', string 'tpre', string 'sfile', string 'tfile', float64 'w')
    ldarg.s 0
    ldstr "source"
    call string TKVApp::'str_field'(string, string)
    stloc.s 0
    ldarg.s 0
    ldstr "target"
    call string TKVApp::'str_field'(string, string)
    stloc.s 1
    ldarg.s 0
    ldstr "type"
    call string TKVApp::'str_field'(string, string)
    stloc.s 2
    ldarg.s 0
    ldstr "weight"
    call string TKVApp::'num_field'(string, string)
    stloc.s 3
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse check_edge_If1_else
    ldstr "canh thieu truong 'source': "
    ldarg.s 0
    callvirt instance string [mscorlib]System.String::Trim()
    call string [mscorlib]System.String::Concat(string, string)
    ret
  check_edge_If1_else:
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse check_edge_If2_else
    ldstr "canh thieu truong 'target': "
    ldarg.s 0
    callvirt instance string [mscorlib]System.String::Trim()
    call string [mscorlib]System.String::Concat(string, string)
    ret
  check_edge_If2_else:
    call string TKVApp::'valid_edge_types'()
    ldloc.s 2
    call int32 TKVApp::'in_enum'(string, string)
    ldc.i4 0
    ceq
    brfalse check_edge_If3_else
    ldstr "loai canh khong hop le '"
    ldloc.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' tai "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ret
  check_edge_If3_else:
    ldloc.s 0
    call string TKVApp::'id_prefix'(string)
    stloc.s 4
    ldloc.s 1
    call string TKVApp::'id_prefix'(string)
    stloc.s 5
    call string TKVApp::'valid_prefixes'()
    ldloc.s 4
    call int32 TKVApp::'in_enum'(string, string)
    ldc.i4 0
    ceq
    brfalse check_edge_If4_else
    ldstr "tien to id nguon khong hop le: "
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ret
  check_edge_If4_else:
    call string TKVApp::'valid_prefixes'()
    ldloc.s 5
    call int32 TKVApp::'in_enum'(string, string)
    ldc.i4 0
    ceq
    brfalse check_edge_If5_else
    ldstr "tien to id dich khong hop le: "
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ret
  check_edge_If5_else:
    ldloc.s 2
    ldloc.s 4
    ldloc.s 5
    call int32 TKVApp::'endpoints_ok'(string, string, string)
    ldc.i4 0
    ceq
    brfalse check_edge_If6_else
    ldstr "canh '"
    ldloc.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' noi sai loai nut: "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " -> "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ret
  check_edge_If6_else:
    ldloc.s 0
    call string TKVApp::'id_file'(string)
    stloc.s 6
    ldloc.s 1
    call string TKVApp::'id_file'(string)
    stloc.s 7
    ldarg.s 1
    ldloc.s 6
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse check_edge_dget8_miss
    ldarg.s 1
    ldloc.s 6
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br check_edge_dget8_end
  check_edge_dget8_miss:
    ldstr ""
  check_edge_dget8_end:
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse check_edge_If7_else
    ldstr "nguon tro toi file khong co trong manifest: "
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ret
  check_edge_If7_else:
    ldarg.s 1
    ldloc.s 7
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse check_edge_dget10_miss
    ldarg.s 1
    ldloc.s 7
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br check_edge_dget10_end
  check_edge_dget10_miss:
    ldstr ""
  check_edge_dget10_end:
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse check_edge_If9_else
    ldstr "dich tro toi file khong co trong manifest: "
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ret
  check_edge_If9_else:
    ldloc.s 2
    ldstr "contains"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse check_edge_If11_else
    ldloc.s 6
    ldloc.s 7
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse check_edge_If12_else
    ldstr "canh contains bac cau sang file khac: "
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " -> "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ret
  check_edge_If12_else:
  check_edge_If11_else:
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse check_edge_If13_else
    ldstr "canh thieu 'weight': "
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " -> "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ret
  check_edge_If13_else:
    ldloc.s 3
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call float64 [mscorlib]System.Double::Parse(string, class [mscorlib]System.IFormatProvider)
    stloc.s 8
    ldloc.s 8
    ldc.r8 0.0
    clt
    brfalse check_edge_If14_else
    ldstr "weight ngoai [0,1]: "
    ldloc.s 3
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " tai "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ret
  check_edge_If14_else:
    ldloc.s 8
    ldc.r8 1.0
    cgt
    brfalse check_edge_If15_else
    ldstr "weight ngoai [0,1]: "
    ldloc.s 3
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " tai "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ret
  check_edge_If15_else:
    ldstr ""
    ret
  }
  .method public static int32 'endpoints_ok'(string 'etype', string 'spre', string 'tpre') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr "imports"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse endpoints_ok_If1_else
    ldarg.s 1
    ldstr "file"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse endpoints_ok_If2_else
    ldarg.s 2
    ldstr "file"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse endpoints_ok_If3_else
    ldc.i4 1
    ret
  endpoints_ok_If3_else:
  endpoints_ok_If2_else:
    ldc.i4 0
    ret
  endpoints_ok_If1_else:
    ldarg.s 0
    ldstr "contains"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse endpoints_ok_If4_else
    ldarg.s 1
    ldstr "file"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse endpoints_ok_If5_else
    ldc.i4 1
    ret
  endpoints_ok_If5_else:
    ldc.i4 0
    ret
  endpoints_ok_If4_else:
    ldarg.s 0
    ldstr "calls"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse endpoints_ok_If6_else
    ldarg.s 1
    ldstr "function"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse endpoints_ok_If7_else
    ldarg.s 2
    ldstr "function"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse endpoints_ok_If8_else
    ldc.i4 1
    ret
  endpoints_ok_If8_else:
    ldarg.s 2
    ldstr "class"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse endpoints_ok_If9_else
    ldc.i4 1
    ret
  endpoints_ok_If9_else:
  endpoints_ok_If7_else:
    ldc.i4 0
    ret
  endpoints_ok_If6_else:
    ldarg.s 0
    ldstr "inherits"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse endpoints_ok_If10_else
    ldarg.s 1
    ldstr "class"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse endpoints_ok_If11_else
    ldarg.s 2
    ldstr "class"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse endpoints_ok_If12_else
    ldc.i4 1
    ret
  endpoints_ok_If12_else:
  endpoints_ok_If11_else:
    ldc.i4 0
    ret
  endpoints_ok_If10_else:
    ldc.i4 0
    ret
  }
  .method public static int32 'is_edge_line'(string 'line') cil managed
  {
    .maxstack 8
    .locals init (string 'body')
    ldarg.s 0
    callvirt instance string [mscorlib]System.String::Trim()
    stloc.s 0
    ldloc.s 0
    ldstr "{\"source\""
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    brfalse is_edge_line_If1_else
    ldc.i4 1
    ret
  is_edge_line_If1_else:
    ldc.i4 0
    ret
  }
  .method public static int32 'scan_doc'(string 'text', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'files', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'seen', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'touched', class [mscorlib]System.Collections.Generic.List`1<string> 'issues', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'counts') cil managed
  {
    .maxstack 8
    .locals init (int32 'n', class [mscorlib]System.Collections.Generic.List`1<string> 'lines', int32 '__iterlist0_idx', string 'ln', string 'msg', string 'src', string 'tgt', string 'etype', string 'key', int32 '__strtmp2133125105360')
    ldc.i4 0
    stloc.s 0
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
    stloc.s 1
    ldc.i4.0
    stloc.s 2
  scan_doc_L1_start:
    ldloc.s 2
    ldloc.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge scan_doc_L1_end
    ldloc.s 1
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 3
    ldloc.s 3
    call int32 TKVApp::'is_edge_line'(string)
    ldc.i4 0
    ceq
    brfalse scan_doc_If2_else
    br scan_doc_L1_cont
  scan_doc_If2_else:
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    ldloc.s 3
    ldarg.s 1
    call string TKVApp::'check_edge'(string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 4
    ldloc.s 4
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse scan_doc_If3_else
    ldarg.s 4
    ldloc.s 4
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br scan_doc_L1_cont
  scan_doc_If3_else:
    ldloc.s 3
    ldstr "source"
    call string TKVApp::'str_field'(string, string)
    stloc.s 5
    ldloc.s 3
    ldstr "target"
    call string TKVApp::'str_field'(string, string)
    stloc.s 6
    ldloc.s 3
    ldstr "type"
    call string TKVApp::'str_field'(string, string)
    stloc.s 7
    ldloc.s 5
    ldstr ">"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 6
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ">"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 7
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 8
    ldarg.s 2
    ldloc.s 8
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse scan_doc_If4_else
    ldarg.s 4
    ldstr "canh trung lap: "
    ldloc.s 8
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br scan_doc_L1_cont
  scan_doc_If4_else:
    ldarg.s 2
    ldloc.s 8
    ldstr "1"
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    ldarg.s 5
    ldloc.s 7
    ldarg.s 5
    ldloc.s 7
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse scan_doc_dget5_miss
    ldarg.s 5
    ldloc.s 7
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br scan_doc_dget5_end
  scan_doc_dget5_miss:
    ldstr "0"
  scan_doc_dget5_end:
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call int32 [mscorlib]System.Int32::Parse(string, class [mscorlib]System.IFormatProvider)
    ldc.i4 1
    add
    stloc.s 9
    ldloca.s 9
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    ldarg.s 3
    ldloc.s 5
    call string TKVApp::'id_file'(string)
    ldstr "1"
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    ldarg.s 3
    ldloc.s 6
    call string TKVApp::'id_file'(string)
    ldstr "1"
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  scan_doc_L1_cont:
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    br scan_doc_L1_start
  scan_doc_L1_end:
    ldloc.s 0
    ret
  }
  .method public static string 'esc'(string 's') cil managed
  {
    .maxstack 8
    .locals init (string 'step')
    ldarg.s 0
    ldstr "\\"
    ldstr "\\\\"
    callvirt instance string [mscorlib]System.String::Replace(string, string)
    stloc.s 0
    ldloc.s 0
    ldstr "\""
    ldstr "\\\""
    callvirt instance string [mscorlib]System.String::Replace(string, string)
    ret
  }
  .method public static string 'json_list'(class [mscorlib]System.Collections.Generic.List`1<string> 'items', int32 'limit') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'pieces', int32 'i', int32 '__strtmp2133125104320')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldc.i4 0
    stloc.s 1
  json_list_W1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse json_list_W1_end
    ldloc.s 1
    ldarg.s 1
    clt
    ldc.i4.0
    ceq
    brfalse json_list_If2_else
    ldloc.s 0
    ldstr "  \"... con "
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldarg.s 1
    sub
    stloc.s 2
    ldloca.s 2
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " muc nua (da cat, khong giau)\""
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldstr ",\n"
    ldloc.s 0
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    ret
  json_list_If2_else:
    ldloc.s 0
    ldstr "  \""
    ldarg.s 0
    ldloc.s 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call string TKVApp::'esc'(string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\""
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br json_list_W1_start
  json_list_W1_end:
    ldstr ",\n"
    ldloc.s 0
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    ret
  }
  .method public static string 'count_json'(class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'counts') cil managed
  {
    .maxstack 8
    .locals init (string 'out', class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>> 'items_list', int32 '__iterkv0_idx', valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string> '__iterkv0_pair', string 'k', string 'v')
    ldstr ""
    stloc.s 0
    ldarg.s 0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
    stloc.s 1
    ldc.i4.0
    stloc.s 2
  count_json_L1_start:
    ldloc.s 2
    ldloc.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge count_json_L1_end
    ldloc.s 1
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>>::get_Item(int32)
    stloc.s 3
    ldloca.s 3
    call instance !0 valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>::get_Key()
    stloc.s 4
    ldloca.s 3
    call instance !1 valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>::get_Value()
    stloc.s 5
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse count_json_If2_else
    ldloc.s 0
    ldstr ","
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
  count_json_If2_else:
    ldloc.s 0
    ldstr "\""
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 4
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 5
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
  count_json_L1_cont:
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    br count_json_L1_start
  count_json_L1_end:
    ldloc.s 0
    ret
  }
  .method public static string 'line_node_path'(string 'line') cil managed
  {
    .maxstack 8
    .locals init (int32 'at', string 'tail', int32 '__slice2133125109440_start')
    ldarg.s 0
    ldstr "\"file:"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    clt
    brfalse line_node_path_If1_else
    ldstr ""
    ret
  line_node_path_If1_else:
    ldloc.s 0
    ldc.i4 6
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
    ldstr "\""
    call string TKVApp::'cut_at'(string, string)
    ret
  }
  .method public static int32 'check_layers'(string 'text', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'files', class [mscorlib]System.Collections.Generic.List`1<string> 'issues', class [mscorlib]System.Collections.Generic.List`1<string> 'warnings') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'seen', int32 'total', string 'cur', int32 'n_cur', class [mscorlib]System.Collections.Generic.List`1<string> 'lines', int32 '__iterlist1_idx', string 'ln', string 'path', string 'known', string 'old', int32 'n_miss')
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 0
    ldc.i4 0
    stloc.s 1
    ldstr ""
    stloc.s 2
    ldc.i4 0
    stloc.s 3
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
    stloc.s 4
    ldc.i4.0
    stloc.s 5
  check_layers_L1_start:
    ldloc.s 5
    ldloc.s 4
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge check_layers_L1_end
    ldloc.s 4
    ldloc.s 5
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 6
    ldloc.s 6
    ldstr "\"nodeIds\""
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse check_layers_If2_else
    ldloc.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse check_layers_If3_else
    ldloc.s 3
    ldc.i4 0
    ceq
    brfalse check_layers_If4_else
    ldarg.s 3
    ldstr "tang '"
    ldloc.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' rong"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  check_layers_If4_else:
  check_layers_If3_else:
    ldloc.s 6
    ldstr "name"
    call string TKVApp::'str_field'(string, string)
    stloc.s 2
    ldc.i4 0
    stloc.s 3
  check_layers_If2_else:
    ldloc.s 6
    call string TKVApp::'line_node_path'(string)
    stloc.s 7
    ldloc.s 7
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse check_layers_If5_else
    br check_layers_L1_cont
  check_layers_If5_else:
    ldloc.s 6
    ldstr "\"fi"
    call int32 TKVApp::'count_marker'(string, string)
    ldc.i4 1
    cgt
    brfalse check_layers_If6_else
    ldarg.s 2
    ldstr "dinh dang phan tang sai: nhieu id tren mot dong ("
    ldloc.s 7
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " ...)"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br check_layers_L1_cont
  check_layers_If6_else:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    ldloc.s 3
    ldc.i4 1
    add
    stloc.s 3
    ldarg.s 1
    ldloc.s 7
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse check_layers_dget7_miss
    ldarg.s 1
    ldloc.s 7
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br check_layers_dget7_end
  check_layers_dget7_miss:
    ldstr ""
  check_layers_dget7_end:
    stloc.s 8
    ldloc.s 8
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse check_layers_If8_else
    ldarg.s 2
    ldstr "tang '"
    ldloc.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' chua file khong co trong manifest: "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 7
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br check_layers_L1_cont
  check_layers_If8_else:
    ldloc.s 0
    ldloc.s 7
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse check_layers_dget9_miss
    ldloc.s 0
    ldloc.s 7
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br check_layers_dget9_end
  check_layers_dget9_miss:
    ldstr ""
  check_layers_dget9_end:
    stloc.s 9
    ldloc.s 9
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse check_layers_If10_else
    ldarg.s 2
    ldstr "file thuoc NHIEU tang: "
    ldloc.s 7
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " ("
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 9
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " va "
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ")"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br check_layers_L1_cont
  check_layers_If10_else:
    ldloc.s 0
    ldloc.s 7
    ldloc.s 2
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  check_layers_L1_cont:
    ldloc.s 5
    ldc.i4 1
    add
    stloc.s 5
    br check_layers_L1_start
  check_layers_L1_end:
    ldloc.s 2
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse check_layers_If11_else
    ldloc.s 3
    ldc.i4 0
    ceq
    brfalse check_layers_If12_else
    ldarg.s 3
    ldstr "tang '"
    ldloc.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "' rong"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  check_layers_If12_else:
  check_layers_If11_else:
    ldarg.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Count()
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Count()
    sub
    stloc.s 10
    ldloc.s 10
    ldc.i4 0
    cgt
    brfalse check_layers_If13_else
    ldarg.s 2
    ldstr "co "
    ldloca.s 10
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " file khong thuoc tang nao"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  check_layers_If13_else:
    ldloc.s 1
    ret
  }
  .method public static int32 'check_tour'(string 'text', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'files', class [mscorlib]System.Collections.Generic.List`1<string> 'issues', class [mscorlib]System.Collections.Generic.List`1<string> 'warnings') cil managed
  {
    .maxstack 8
    .locals init (int32 'n_steps', int32 'n_nodes', int32 'n_cur', class [mscorlib]System.Collections.Generic.List`1<string> 'lines', int32 '__iterlist2_idx', string 'ln', string 'want', string 'path', string 'known')
    ldc.i4 0
    stloc.s 0
    ldc.i4 0
    stloc.s 1
    ldc.i4 0
    stloc.s 2
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
    stloc.s 3
    ldc.i4.0
    stloc.s 4
  check_tour_L1_start:
    ldloc.s 4
    ldloc.s 3
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge check_tour_L1_end
    ldloc.s 3
    ldloc.s 4
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 5
    ldloc.s 5
    ldstr "\"order\":"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse check_tour_If2_else
    ldloc.s 0
    ldc.i4 0
    cgt
    brfalse check_tour_If3_else
    ldloc.s 2
    ldc.i4 0
    ceq
    brfalse check_tour_If4_else
    ldarg.s 2
    ldstr "buoc "
    ldloca.s 0
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " khong co file nao"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  check_tour_If4_else:
  check_tour_If3_else:
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
    ldc.i4 0
    stloc.s 2
    ldstr "\"order\":"
    ldloca.s 0
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 6
    ldloc.s 5
    ldloc.s 6
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    brfalse check_tour_If5_else
    ldarg.s 2
    ldstr "order khong lien tuc, mong doi "
    ldloc.s 6
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  check_tour_If5_else:
    ldloc.s 5
    ldstr "\"title\":\"\""
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse check_tour_If6_else
    ldarg.s 3
    ldstr "buoc "
    ldloca.s 0
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " khong co tieu de"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  check_tour_If6_else:
  check_tour_If2_else:
    ldloc.s 5
    call string TKVApp::'line_node_path'(string)
    stloc.s 7
    ldloc.s 7
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse check_tour_If7_else
    br check_tour_L1_cont
  check_tour_If7_else:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    ldarg.s 1
    ldloc.s 7
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse check_tour_dget8_miss
    ldarg.s 1
    ldloc.s 7
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br check_tour_dget8_end
  check_tour_dget8_miss:
    ldstr ""
  check_tour_dget8_end:
    stloc.s 8
    ldloc.s 8
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse check_tour_If9_else
    ldarg.s 2
    ldstr "lo trinh tro toi file khong co trong manifest: "
    ldloc.s 7
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  check_tour_If9_else:
  check_tour_L1_cont:
    ldloc.s 4
    ldc.i4 1
    add
    stloc.s 4
    br check_tour_L1_start
  check_tour_L1_end:
    ldloc.s 0
    ldc.i4 0
    cgt
    brfalse check_tour_If10_else
    ldloc.s 2
    ldc.i4 0
    ceq
    brfalse check_tour_If11_else
    ldarg.s 2
    ldstr "buoc "
    ldloca.s 0
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " khong co file nao"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  check_tour_If11_else:
  check_tour_If10_else:
    ldloc.s 0
    ldc.i4 5
    clt
    brfalse check_tour_If12_else
    ldarg.s 3
    ldstr "lo trinh chi co "
    ldloca.s 0
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " buoc (nen 5-15)"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  check_tour_If12_else:
    ldloc.s 0
    ldc.i4 15
    cgt
    brfalse check_tour_If13_else
    ldarg.s 3
    ldstr "lo trinh co "
    ldloca.s 0
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " buoc (nen 5-15)"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  check_tour_If13_else:
    ldloc.s 1
    ret
  }
  .method public static string 'run'(string 'manifest', string 'imports_path', string 'calls_path', string 'report_path', string 'layers_path', string 'tour_path') cil managed
  {
    .maxstack 8
    .locals init (string 'raw', class [mscorlib]System.Collections.Generic.List`1<string> 'rows', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'files', int32 '__iterlist3_idx', string 'r', string 'p', class [mscorlib]System.Collections.Generic.List`1<string> 'issues', class [mscorlib]System.Collections.Generic.List`1<string> 'warnings', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'seen', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'touched', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'counts', int32 'n1', int32 'n2', int32 'total', int32 'n_layered', string 'layer_doc', int32 'n_tour', string 'tour_doc', int32 'orphans', class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>> 'items_list', int32 '__iterkv1_idx', valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string> '__iterkv1_pair', string 'v', string 'approved', string 'doc', int32 '__strtmp2133129557568', int32 '__strtmp2133129557632', int32 '__strtmp2133129557248', int32 '__strtmp2133129557952', string 'verdict', int32 '__strtmp2133124881152', int32 '__strtmp2133124880128', int32 '__strtmp2133124699584')
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
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
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
    ldstr "1"
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  run_If2_else:
  run_L1_cont:
    ldloc.s 3
    ldc.i4 1
    add
    stloc.s 3
    br run_L1_start
  run_L1_end:
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 6
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 7
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 8
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 9
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 10
    ldarg.s 1
    call string [mscorlib]System.IO.File::ReadAllText(string)
    ldloc.s 2
    ldloc.s 8
    ldloc.s 9
    ldloc.s 6
    ldloc.s 10
    call int32 TKVApp::'scan_doc'(string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 11
    ldarg.s 2
    call string [mscorlib]System.IO.File::ReadAllText(string)
    ldloc.s 2
    ldloc.s 8
    ldloc.s 9
    ldloc.s 6
    ldloc.s 10
    call int32 TKVApp::'scan_doc'(string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 12
    ldloc.s 11
    ldloc.s 12
    add
    stloc.s 13
    ldloc.s 13
    ldc.i4 0
    ceq
    brfalse run_If3_else
    ldloc.s 6
    ldstr "graph rong: khong co canh nao"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  run_If3_else:
    ldc.i4 0
    stloc.s 14
    ldarg.s 4
    call bool [mscorlib]System.IO.File::Exists(string)
    brfalse run_If4_else
    ldarg.s 4
    call string [mscorlib]System.IO.File::ReadAllText(string)
    stloc.s 15
    ldloc.s 15
    ldloc.s 2
    ldloc.s 6
    ldloc.s 7
    call int32 TKVApp::'check_layers'(string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 14
    br run_If4_end
  run_If4_else:
    ldloc.s 7
    ldstr "khong co file phan tang ("
    ldarg.s 4
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ") - bo qua check vung phu tang"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  run_If4_end:
    ldc.i4 0
    stloc.s 16
    ldarg.s 5
    call bool [mscorlib]System.IO.File::Exists(string)
    brfalse run_If5_else
    ldarg.s 5
    call string [mscorlib]System.IO.File::ReadAllText(string)
    stloc.s 17
    ldloc.s 17
    ldloc.s 2
    ldloc.s 6
    ldloc.s 7
    call int32 TKVApp::'check_tour'(string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 16
    br run_If5_end
  run_If5_else:
    ldloc.s 7
    ldstr "khong co file lo trinh ("
    ldarg.s 5
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ") - bo qua check lo trinh"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  run_If5_end:
    ldc.i4 0
    stloc.s 18
    ldloc.s 2
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
    stloc.s 19
    ldc.i4.0
    stloc.s 20
  run_L6_start:
    ldloc.s 20
    ldloc.s 19
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge run_L6_end
    ldloc.s 19
    ldloc.s 20
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>>::get_Item(int32)
    stloc.s 21
    ldloca.s 21
    call instance !0 valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>::get_Key()
    stloc.s 5
    ldloca.s 21
    call instance !1 valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>::get_Value()
    stloc.s 22
    ldloc.s 9
    ldloc.s 5
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse run_dget8_miss
    ldloc.s 9
    ldloc.s 5
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br run_dget8_end
  run_dget8_miss:
    ldstr ""
  run_dget8_end:
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse run_If7_else
    ldloc.s 18
    ldc.i4 1
    add
    stloc.s 18
  run_If7_else:
  run_L6_cont:
    ldloc.s 20
    ldc.i4 1
    add
    stloc.s 20
    br run_L6_start
  run_L6_end:
    ldloc.s 18
    ldc.i4 0
    cgt
    brfalse run_If9_else
    ldloc.s 7
    ldstr "co "
    ldloca.s 18
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " file khong dinh vao canh nao (mo coi)"
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  run_If9_else:
    ldstr "true"
    stloc.s 23
    ldloc.s 6
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 0
    cgt
    brfalse run_If10_else
    ldstr "false"
    stloc.s 23
  run_If10_else:
    ldstr "{\n \"approved\": "
    ldloc.s 23
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ",\n"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 24
    ldloc.s 24
    ldstr " \"issues\": [\n"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 6
    call int32 TKVApp::'max_listed'()
    call string TKVApp::'json_list'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\n ],\n"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 24
    ldloc.s 24
    ldstr " \"warnings\": [\n"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 7
    call int32 TKVApp::'max_listed'()
    call string TKVApp::'json_list'(class [mscorlib]System.Collections.Generic.List`1<string>, int32)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\n ],\n"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 24
    ldloc.s 24
    ldstr " \"stats\": {\"files\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Count()
    stloc.s 25
    ldloca.s 25
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 24
    ldloc.s 24
    ldstr ",\"edges_read\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 13
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 24
    ldloc.s 24
    ldstr ",\"edges_valid\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 8
    callvirt instance int32 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Count()
    stloc.s 26
    ldloca.s 26
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 24
    ldloc.s 24
    ldstr ",\"issues\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 6
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 27
    ldloca.s 27
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 24
    ldloc.s 24
    ldstr ",\"warnings\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 7
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 28
    ldloca.s 28
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 24
    ldloc.s 24
    ldstr ",\"orphan_files\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 18
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 24
    ldloc.s 24
    ldstr ",\"nodes_in_layers\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 14
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 24
    ldloc.s 24
    ldstr ",\"nodes_in_tour\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 16
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 24
    ldloc.s 24
    ldstr ",\"by_type\":{"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 10
    call string TKVApp::'count_json'(class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "}}\n}\n"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 24
    ldarg.s 3
    ldloc.s 24
    call void [mscorlib]System.IO.File::WriteAllText(string, string)
    ldstr "DUYET"
    stloc.s 29
    ldloc.s 6
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 0
    cgt
    brfalse run_If11_else
    ldstr "TU CHOI"
    stloc.s 29
  run_If11_else:
    ldloc.s 29
    ldstr " | edges="
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 13
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " valid="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 8
    callvirt instance int32 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Count()
    stloc.s 30
    ldloca.s 30
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " issues="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 6
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 31
    ldloca.s 31
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " warnings="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 7
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 32
    ldloca.s 32
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " orphan_files="
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 18
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
    .locals init (int32 'cut', int32 'i', int32 '__slice2133125056928_start')
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
    .locals init (string 'body', int32 '__slice2133125056608_start', int32 '__slice2133125110160_start', string 'out', int32 'i', string 'ch')
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
    .locals init (int32 'cut', int32 'i', int32 '__slice2133119113536_start')
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
    .locals init (int32 'cut', int32 'i', int32 '__slice2133124783440_start')
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
    .locals init (string 'body', string 'rest', int32 '__slice2133124782160_start', int32 '__slice2133124786080_start')
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
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', string 'body', string 'mod', string 'rest', int32 '__slice2133125115360_start', class [mscorlib]System.Collections.Generic.List`1<string> 'parts', int32 '__iterlist4_idx', string 'part', string 'piece')
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
    .locals init (int32 'n', int32 'i', int32 '__slice2133125115680_start')
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
    .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', int32 '__iterlist5_idx', string 'rel', string 'dotted')
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
    .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', int32 '__iterlist6_idx', string 'rel', string 'dotted', string 'base')
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
    .locals init (int32 'lvl', string 'tail', int32 '__slice2133125116560_start', string 'base', int32 'up', string 'pkg', string 'full', string 'probe', string 'hit')
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
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', string 'text', class [mscorlib]System.Collections.Generic.List`1<string> 'lines', int32 'in_doc', int32 '__iterlist7_idx', string 'ln', int32 'tri', int32 'was_doc', int32 '__idiv2133124791760_a', int32 '__idiv2133124791760_b', int32 '__idiv2133124791760_q', int32 '__idiv2133124791760_r', class [mscorlib]System.Collections.Generic.List`1<string> 'mods', int32 '__iterlist8_idx', string 'mod', string 'hit')
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
    .locals init (string 'raw', class [mscorlib]System.Collections.Generic.List`1<string> 'rows', class [mscorlib]System.Collections.Generic.List`1<string> 'paths', int32 '__iterlist9_idx', string 'r', string 'p', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'base_idx', int32 'n_total', int32 'n_int', int32 'n_ext', int32 'n_amb', int32 'n_self', int32 'n_dup', class [mscorlib]System.Collections.Generic.List`1<string> 'edges', class [System.Core]System.Collections.Generic.HashSet`1<string> 'seen', int32 '__iterlist10_idx', string 'rel', class [mscorlib]System.Collections.Generic.List`1<string> 'results', int32 '__iterlist11_idx', string 'res', string 'kind', string 'target', int32 '__slice2133125115680_start', string 'key', class [mscorlib]System.Collections.Generic.List`1<string> 'pieces', int32 'i', string 'body', string 'doc', int32 '__strtmp2133124875776', int32 '__strtmp2133129558080', int32 '__strtmp2133129557632', int32 '__strtmp2133129557696')
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
    ldarg.0
    ldc.i4 2
    ldelem.ref
    ldarg.0
    ldc.i4 3
    ldelem.ref
    ldarg.0
    ldc.i4 4
    ldelem.ref
    ldarg.0
    ldc.i4 5
    ldelem.ref
    call string TKVApp::'run'(string, string, string, string, string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ret
  }
}
