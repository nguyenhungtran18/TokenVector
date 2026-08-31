.assembly extern mscorlib {}
.assembly extern System.Core { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly extern System { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly TKVApp {}
.module TKVApp.exe

.class public auto ansi TKVApp extends [mscorlib]System.Object
{
  .method public static string 'norm_eol'(string 's') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'parts')
    ldarg.s 0
    ldc.i4.1
    newarr [mscorlib]System.Char
    dup
    ldc.i4.0
    ldstr "\r"
    ldc.i4.0
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    stelem.i2
    callvirt instance string[] [mscorlib]System.String::Split(char[])
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
    stloc.s 0
    ldstr ""
    ldloc.s 0
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    ret
  }
  .method public static string 'hash_of'(string 'rel') cil managed
  {
    .maxstack 8
    call class [mscorlib]System.Security.Cryptography.SHA256 [mscorlib]System.Security.Cryptography.SHA256::Create()
    call class [mscorlib]System.Text.Encoding [mscorlib]System.Text.Encoding::get_UTF8()
    ldarg.s 0
    call string [mscorlib]System.IO.File::ReadAllText(string)
    call string TKVApp::'norm_eol'(string)
    callvirt instance uint8[] [mscorlib]System.Text.Encoding::GetBytes(string)
    callvirt instance uint8[] [mscorlib]System.Security.Cryptography.HashAlgorithm::ComputeHash(uint8[])
    call string [mscorlib]System.BitConverter::ToString(uint8[])
    ldstr "-"
    ldstr ""
    callvirt instance string [mscorlib]System.String::Replace(string, string)
    callvirt instance string [mscorlib]System.String::ToLower()
    ret
  }
  .method public static string 'fp_line'(string 'rel') cil managed
  {
    .maxstack 8
    ldarg.s 0
    call string TKVApp::'hash_of'(string)
    ldstr " "
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static string 'build_fingerprint'(class [mscorlib]System.Collections.Generic.List`1<string> 'paths') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'acc', int32 '__iterlist0_idx', string 'rel')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldc.i4.0
    stloc.s 1
  build_fingerprint_L1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge build_fingerprint_L1_end
    ldarg.s 0
    ldloc.s 1
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 2
    ldloc.s 0
    ldloc.s 2
    call string TKVApp::'fp_line'(string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  build_fingerprint_L1_cont:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br build_fingerprint_L1_start
  build_fingerprint_L1_end:
    ldstr "\n"
    ldloc.s 0
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    ret
  }
  .method public static int32 'parse_fp'(string 'text', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'into') cil managed
  {
    .maxstack 8
    .locals init (int32 'n', class [mscorlib]System.Collections.Generic.List`1<string> 'rows', int32 '__iterlist1_idx', string 'r', string 'line', string 'h', string 'rel', int32 '__slice2497798961360_start')
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
  parse_fp_L1_start:
    ldloc.s 2
    ldloc.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge parse_fp_L1_end
    ldloc.s 1
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 3
    ldloc.s 3
    callvirt instance string [mscorlib]System.String::Trim()
    stloc.s 4
    ldloc.s 4
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse parse_fp_If2_else
    br parse_fp_L1_cont
  parse_fp_If2_else:
    ldloc.s 4
    ldstr " "
    call string TKVApp::'cut_at'(string, string)
    stloc.s 5
    ldloc.s 5
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 1
    add
    ldloc.s 4
    callvirt instance int32 [mscorlib]System.String::get_Length()
    cgt
    brfalse parse_fp_If3_else
    br parse_fp_L1_cont
  parse_fp_If3_else:
    ldloc.s 5
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 1
    add
    stloc.s 7
    ldloc.s 4
    ldloc.s 7
    ldloc.s 4
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 7
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 6
    ldarg.s 1
    ldloc.s 6
    ldloc.s 5
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
  parse_fp_L1_cont:
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    br parse_fp_L1_start
  parse_fp_L1_end:
    ldloc.s 0
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'read_manifest'(string 'manifest') cil managed
  {
    .maxstack 8
    .locals init (string 'raw', class [mscorlib]System.Collections.Generic.List`1<string> 'rows', class [mscorlib]System.Collections.Generic.List`1<string> 'paths', int32 '__iterlist2_idx', string 'r', string 'p')
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
  read_manifest_L1_start:
    ldloc.s 3
    ldloc.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge read_manifest_L1_end
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
    brfalse read_manifest_If2_else
    ldloc.s 2
    ldloc.s 5
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  read_manifest_If2_else:
  read_manifest_L1_cont:
    ldloc.s 3
    ldc.i4 1
    add
    stloc.s 3
    br read_manifest_L1_start
  read_manifest_L1_end:
    ldloc.s 2
    ret
  }
  .method public static string 'diff_report'(class [mscorlib]System.Collections.Generic.List`1<string> 'paths', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'old', class [mscorlib]System.Collections.Generic.List`1<string> 'lines') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'now', int32 'n_mod', int32 'n_add', int32 'n_del', int32 '__iterlist3_idx', string 'rel', string 'h', string 'prev', class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>> 'items_list', int32 '__iterkv0_idx', valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string> '__iterkv0_pair')
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 0
    ldc.i4 0
    stloc.s 1
    ldc.i4 0
    stloc.s 2
    ldc.i4 0
    stloc.s 3
    ldc.i4.0
    stloc.s 4
  diff_report_L1_start:
    ldloc.s 4
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge diff_report_L1_end
    ldarg.s 0
    ldloc.s 4
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 5
    ldloc.s 5
    call string TKVApp::'hash_of'(string)
    stloc.s 6
    ldloc.s 0
    ldloc.s 5
    ldloc.s 6
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    ldarg.s 1
    ldloc.s 5
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse diff_report_dget2_miss
    ldarg.s 1
    ldloc.s 5
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br diff_report_dget2_end
  diff_report_dget2_miss:
    ldstr ""
  diff_report_dget2_end:
    stloc.s 7
    ldloc.s 7
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse diff_report_If3_else
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    ldarg.s 2
    ldstr "THEM "
    ldloc.s 5
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br diff_report_If3_end
  diff_report_If3_else:
    ldloc.s 7
    ldloc.s 6
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse diff_report_If4_else
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    ldarg.s 2
    ldstr "SUA "
    ldloc.s 5
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  diff_report_If4_else:
  diff_report_If3_end:
  diff_report_L1_cont:
    ldloc.s 4
    ldc.i4 1
    add
    stloc.s 4
    br diff_report_L1_start
  diff_report_L1_end:
    ldarg.s 1
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
    stloc.s 8
    ldc.i4.0
    stloc.s 9
  diff_report_L5_start:
    ldloc.s 9
    ldloc.s 8
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge diff_report_L5_end
    ldloc.s 8
    ldloc.s 9
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>>::get_Item(int32)
    stloc.s 10
    ldloca.s 10
    call instance !0 valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>::get_Key()
    stloc.s 5
    ldloca.s 10
    call instance !1 valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>::get_Value()
    stloc.s 6
    ldloc.s 0
    ldloc.s 5
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse diff_report_dget7_miss
    ldloc.s 0
    ldloc.s 5
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br diff_report_dget7_end
  diff_report_dget7_miss:
    ldstr ""
  diff_report_dget7_end:
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse diff_report_If6_else
    ldloc.s 3
    ldc.i4 1
    add
    stloc.s 3
    ldarg.s 2
    ldstr "XOA "
    ldloc.s 5
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  diff_report_If6_else:
  diff_report_L5_cont:
    ldloc.s 9
    ldc.i4 1
    add
    stloc.s 9
    br diff_report_L5_start
  diff_report_L5_end:
    ldloca.s 1
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    ldstr ","
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 2
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ","
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 3
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static string 'run'(string 'manifest', string 'fp_path', string 'mode', string 'changed_out') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'paths', int32 '__strtmp2497794337920', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'old', int32 'n_old', class [mscorlib]System.Collections.Generic.List`1<string> 'lines', string 'counts', string 'verdict', int32 '__strtmp2497798902016')
    ldarg.s 0
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'read_manifest'(string)
    stloc.s 0
    ldarg.s 2
    ldstr "save"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse run_If1_else
    ldarg.s 1
    ldloc.s 0
    call string TKVApp::'build_fingerprint'(class [mscorlib]System.Collections.Generic.List`1<string>)
    call void [mscorlib]System.IO.File::WriteAllText(string, string)
    ldstr "SAVE | files="
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 1
    ldloca.s 1
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " -> "
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ret
  run_If1_else:
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 2
    ldarg.s 1
    call bool [mscorlib]System.IO.File::Exists(string)
    brfalse run_If2_else
    ldarg.s 1
    call string [mscorlib]System.IO.File::ReadAllText(string)
    ldloc.s 2
    call int32 TKVApp::'parse_fp'(string, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 3
    br run_If2_end
  run_If2_else:
    ldc.i4 0
    stloc.s 3
  run_If2_end:
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 4
    ldloc.s 0
    ldloc.s 2
    ldloc.s 4
    call string TKVApp::'diff_report'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.List`1<string>)
    stloc.s 5
    ldarg.s 3
    ldstr "\n"
    ldloc.s 4
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    call void [mscorlib]System.IO.File::WriteAllText(string, string)
    ldstr "CON DUNG"
    stloc.s 6
    ldloc.s 4
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 0
    cgt
    brfalse run_If3_else
    ldstr "DA CU"
    stloc.s 6
  run_If3_else:
    ldloc.s 6
    ldstr " | van_tay_cu="
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 3
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " files="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 7
    ldloca.s 7
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " sua,them,xoa="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 5
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " -> "
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 3
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
    .locals init (int32 'cut', int32 'i', int32 '__slice2497794625664_start')
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
    .locals init (string 'body', int32 '__slice2497794627024_start', int32 '__slice2497794627264_start', string 'out', int32 'i', string 'ch')
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
    .locals init (int32 'cut', int32 'i', int32 '__slice2497794628704_start')
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
    .locals init (int32 'cut', int32 'i', int32 '__slice2497794630944_start')
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
    .locals init (string 'body', string 'rest', int32 '__slice2497794634544_start', int32 '__slice2497794634784_start')
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
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', string 'body', string 'mod', string 'rest', int32 '__slice2497794634464_start', class [mscorlib]System.Collections.Generic.List`1<string> 'parts', int32 '__iterlist4_idx', string 'part', string 'piece')
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
    .locals init (int32 'n', int32 'i', int32 '__slice2497794633024_start')
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
    .locals init (int32 'lvl', string 'tail', int32 '__slice2497794626544_start', string 'base', int32 'up', string 'pkg', string 'full', string 'probe', string 'hit')
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
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', string 'text', class [mscorlib]System.Collections.Generic.List`1<string> 'lines', int32 'in_doc', int32 '__iterlist7_idx', string 'ln', int32 'tri', int32 'was_doc', int32 '__idiv2497794625584_a', int32 '__idiv2497794625584_b', int32 '__idiv2497794625584_q', int32 '__idiv2497794625584_r', class [mscorlib]System.Collections.Generic.List`1<string> 'mods', int32 '__iterlist8_idx', string 'mod', string 'hit')
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
    .locals init (string 'raw', class [mscorlib]System.Collections.Generic.List`1<string> 'rows', class [mscorlib]System.Collections.Generic.List`1<string> 'paths', int32 '__iterlist9_idx', string 'r', string 'p', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'base_idx', int32 'n_total', int32 'n_int', int32 'n_ext', int32 'n_amb', int32 'n_self', int32 'n_dup', class [mscorlib]System.Collections.Generic.List`1<string> 'edges', class [System.Core]System.Collections.Generic.HashSet`1<string> 'seen', int32 '__iterlist10_idx', string 'rel', class [mscorlib]System.Collections.Generic.List`1<string> 'results', int32 '__iterlist11_idx', string 'res', string 'kind', string 'target', int32 '__slice2497798961120_start', string 'key', class [mscorlib]System.Collections.Generic.List`1<string> 'pieces', int32 'i', string 'body', string 'doc', int32 '__strtmp2497798899520', int32 '__strtmp2497794231040', int32 '__strtmp2497798902016', int32 '__strtmp2497798898880')
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
    call string TKVApp::'run'(string, string, string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ret
  }
}
