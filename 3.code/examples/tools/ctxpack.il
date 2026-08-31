.assembly extern mscorlib {}
.assembly extern System.Core { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly extern System { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly TKVApp {}
.module TKVApp.exe

.class public auto ansi TKVApp extends [mscorlib]System.Object
{
  .method public static int32 'ring_limit'() cil managed
  {
    .maxstack 8
    ldc.i4 2
    ret
  }
  .method public static string 'json_str'(string 'line', string 'key') cil managed
  {
    .maxstack 8
    .locals init (string 'pat', int32 'at', string 'rest', int32 '__slice2583844804608_start')
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
    brfalse json_str_If1_else
    ldstr ""
    ret
  json_str_If1_else:
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
  .method public static string 'edge_type'(string 'line') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr "type"
    call string TKVApp::'json_str'(string, string)
    ret
  }
  .method public static string 'node_file'(string 'nid') cil managed
  {
    .maxstack 8
    .locals init (int32 'at', string 'rest', int32 '__slice2583844805488_start', int32 'cut', int32 'i', int32 '__slice2583844806048_start')
    ldarg.s 0
    ldstr "file:"
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    brfalse node_file_If1_else
    ldarg.s 0
    ret
  node_file_If1_else:
    ldarg.s 0
    ldstr ":"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 0
    ldloc.s 0
    ldc.i4 0
    clt
    brfalse node_file_If2_else
    ldstr ""
    ret
  node_file_If2_else:
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
    ldc.i4 1
    neg
    stloc.s 3
    ldc.i4 0
    stloc.s 4
  node_file_W3_start:
    ldloc.s 4
    ldloc.s 1
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse node_file_W3_end
    ldloc.s 1
    ldloc.s 4
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ldstr ":"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse node_file_If4_else
    ldloc.s 4
    stloc.s 3
  node_file_If4_else:
    ldloc.s 4
    ldc.i4 1
    add
    stloc.s 4
    br node_file_W3_start
  node_file_W3_end:
    ldloc.s 3
    ldc.i4 0
    clt
    brfalse node_file_If5_else
    ldstr "file:"
    ldloc.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ret
  node_file_If5_else:
    ldstr "file:"
    ldc.i4 0
    stloc.s 5
    ldloc.s 1
    ldloc.s 5
    ldloc.s 3
    ldloc.s 5
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static int32 'bump'(class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'd', string 'k') cil managed
  {
    .maxstack 8
    .locals init (string 'cur', int32 '__strtmp2583844804288')
    ldarg.s 0
    ldarg.s 1
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse bump_dget1_miss
    ldarg.s 0
    ldarg.s 1
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br bump_dget1_end
  bump_dget1_miss:
    ldstr "0"
  bump_dget1_end:
    stloc.s 0
    ldarg.s 0
    ldarg.s 1
    ldloc.s 0
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call int32 [mscorlib]System.Int32::Parse(string, class [mscorlib]System.IFormatProvider)
    ldc.i4 1
    add
    stloc.s 1
    ldloca.s 1
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    ldc.i4 1
    ret
  }
  .method public static int32 'num'(class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'd', string 'k') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldarg.s 1
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse num_dget1_miss
    ldarg.s 0
    ldarg.s 1
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br num_dget1_end
  num_dget1_miss:
    ldstr "0"
  num_dget1_end:
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call int32 [mscorlib]System.Int32::Parse(string, class [mscorlib]System.IFormatProvider)
    ret
  }
  .method public static string 'blob_add'(string 'blob', string 'val') cil managed
  {
    .maxstack 8
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse blob_add_If1_else
    ldstr "|"
    starg.s 0
  blob_add_If1_else:
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
    brfalse blob_add_If2_else
    ldarg.s 0
    ret
  blob_add_If2_else:
    ldarg.s 0
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "|"
    call string [mscorlib]System.String::Concat(string, string)
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'blob_items'(string 'blob') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', class [mscorlib]System.Collections.Generic.List`1<string> 'parts', int32 'i')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
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
    stloc.s 1
    ldc.i4 0
    stloc.s 2
  blob_items_W1_start:
    ldloc.s 2
    ldloc.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse blob_items_W1_end
    ldloc.s 1
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse blob_items_If2_else
    ldloc.s 0
    ldloc.s 1
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  blob_items_If2_else:
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    br blob_items_W1_start
  blob_items_W1_end:
    ldloc.s 0
    ret
  }
  .method public static int32 'link'(class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'adj', string 'a', string 'b') cil managed
  {
    .maxstack 8
    ldarg.s 1
    ldarg.s 2
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse link_If1_else
    ldc.i4 0
    ret
  link_If1_else:
    ldarg.s 0
    ldarg.s 1
    ldarg.s 0
    ldarg.s 1
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse link_dget2_miss
    ldarg.s 0
    ldarg.s 1
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br link_dget2_end
  link_dget2_miss:
    ldstr ""
  link_dget2_end:
    ldarg.s 2
    call string TKVApp::'blob_add'(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    ldarg.s 0
    ldarg.s 2
    ldarg.s 0
    ldarg.s 2
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse link_dget3_miss
    ldarg.s 0
    ldarg.s 2
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br link_dget3_end
  link_dget3_miss:
    ldstr ""
  link_dget3_end:
    ldarg.s 1
    call string TKVApp::'blob_add'(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    ldc.i4 1
    ret
  }
  .method public static int32 'seen_at'(class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'd', string 'k') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldarg.s 1
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse seen_at_dget2_miss
    ldarg.s 0
    ldarg.s 1
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br seen_at_dget2_end
  seen_at_dget2_miss:
    ldstr ""
  seen_at_dget2_end:
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse seen_at_If1_else
    ldc.i4 0
    ret
  seen_at_If1_else:
    ldc.i4 1
    ret
  }
  .method public static int32 'est_tokens'(string 'text') cil managed
  {
    .maxstack 8
    .locals init (int32 '__idiv2583844808288_a', int32 '__idiv2583844808288_b', int32 '__idiv2583844808288_q', int32 '__idiv2583844808288_r')
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    stloc.s 0
    ldc.i4 4
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
    beq est_tokens_idiv1_done
    ldloc.s 0
    ldloc.s 1
    xor
    ldc.i4.0
    bge est_tokens_idiv1_done
    ldloc.s 2
    ldc.i4.1
    sub
    stloc.s 2
  est_tokens_idiv1_done:
    ldloc.s 2
    ldc.i4 1
    add
    ret
  }
  .method public static string 'pick_hottest'(class [mscorlib]System.Collections.Generic.List`1<string> 'cands', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'cnt', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'used') cil managed
  {
    .maxstack 8
    .locals init (string 'best', int32 'best_n', int32 'i', string 'c', int32 'n')
    ldstr ""
    stloc.s 0
    ldc.i4 1
    neg
    stloc.s 1
    ldc.i4 0
    stloc.s 2
  pick_hottest_W1_start:
    ldloc.s 2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse pick_hottest_W1_end
    ldarg.s 0
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 3
    ldarg.s 2
    ldloc.s 3
    call int32 TKVApp::'seen_at'(class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, string)
    ldc.i4 0
    ceq
    brfalse pick_hottest_If2_else
    ldarg.s 1
    ldloc.s 3
    call int32 TKVApp::'num'(class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, string)
    stloc.s 4
    ldloc.s 4
    ldloc.s 1
    cgt
    brfalse pick_hottest_If3_else
    ldloc.s 3
    stloc.s 0
    ldloc.s 4
    stloc.s 1
  pick_hottest_If3_else:
  pick_hottest_If2_else:
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    br pick_hottest_W1_start
  pick_hottest_W1_end:
    ldloc.s 0
    ret
  }
  .method public static class [mscorlib]System.Collections.Generic.List`1<string> 'order_by_heat'(class [mscorlib]System.Collections.Generic.List`1<string> 'cands', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'cnt') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'used', class [mscorlib]System.Collections.Generic.List`1<string> 'out', int32 'i', string 'pick')
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 0
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 1
    ldc.i4 0
    stloc.s 2
  order_by_heat_W1_start:
    ldloc.s 2
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse order_by_heat_W1_end
    ldarg.s 0
    ldarg.s 1
    ldloc.s 0
    call string TKVApp::'pick_hottest'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 3
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse order_by_heat_If2_else
    ldarg.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 2
  order_by_heat_If2_else:
    ldloc.s 3
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse order_by_heat_If3_else
    ldloc.s 0
    ldloc.s 3
    ldstr "1"
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    ldloc.s 1
    ldloc.s 3
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
  order_by_heat_If3_else:
    br order_by_heat_W1_start
  order_by_heat_W1_end:
    ldloc.s 1
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
  .method public static string 'entry_json'(string 'fid', string 'mode', int32 'ring', int32 'tok', string 'summary') cil managed
  {
    .maxstack 8
    .locals init (string 'out')
    ldstr "  {\"file\":\""
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\",\"doc\":\""
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\""
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
    ldloc.s 0
    ldstr ",\"vong\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldarga.s 2
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
    ldloc.s 0
    ldstr ",\"token\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldarga.s 3
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
    ldloc.s 0
    ldstr ",\"summary\":\""
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 4
    call string TKVApp::'esc'(string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\"}"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
    ldloc.s 0
    ret
  }
  .method public static int32 'layer_bonus'(string 'layer') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr "foundation"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse layer_bonus_If1_else
    ldc.i4 3
    ret
  layer_bonus_If1_else:
    ldarg.s 0
    ldstr "core"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse layer_bonus_If2_else
    ldc.i4 3
    ret
  layer_bonus_If2_else:
    ldarg.s 0
    ldstr "entry"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse layer_bonus_If3_else
    ldc.i4 1
    ret
  layer_bonus_If3_else:
    ldc.i4 0
    ret
  }
  .method public static string 'run'(string 'nodes_path', string 'imports_path', string 'calls_path', string 'layers_path', string 'target', string 'budget', string 'out_path') cil managed
  {
    .maxstack 8
    .locals init (int32 'cap', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'summ', string 'ndoc', class [mscorlib]System.Collections.Generic.List`1<string> 'nrows', int32 '__iterlist0_idx', string 'ln', string 'nid', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'layer_of', string 'ldoc', class [mscorlib]System.Collections.Generic.List`1<string> 'lrows', string 'cur_layer', int32 '__iterlist1_idx', string 'lr', string 'nm', int32 'at', string 'rest', int32 '__slice2583844766560_start', string 'fid0', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'adj', string 'idoc', class [mscorlib]System.Collections.Generic.List`1<string> 'irows', int32 '__iterlist2_idx', string 'ln2', string 'a', string 'b', string 'cdoc', class [mscorlib]System.Collections.Generic.List`1<string> 'crows', int32 '__iterlist3_idx', string 'ln3', string 'kind', string 'a2', string 'b2', string 'seed', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'picked', class [mscorlib]System.Collections.Generic.List`1<string> 'order', class [mscorlib]System.Collections.Generic.List`1<string> 'rings', class [mscorlib]System.Collections.Generic.List`1<string> 'frontier', int32 'ring', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'heat', class [mscorlib]System.Collections.Generic.List`1<string> 'cands', int32 'i', class [mscorlib]System.Collections.Generic.List`1<string> 'nb', int32 'j', string 'f', int32 'z', string 'fz', int32 'score', class [mscorlib]System.Collections.Generic.List`1<string> 'ranked', int32 'k', class [mscorlib]System.Collections.Generic.List`1<string> 'entries', int32 'spent', int32 'n_full', int32 'n_sum', int32 'm', string 'fid', string 'rel', int32 '__slice2583844805488_start', string 'text', int32 'tok', string 's', int32 'r', string 'mode', int32 'cost', string 'doc', int32 '__strtmp2583849271232', int32 'over', int32 '__strtmp2583844659648')
    ldarg.s 5
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call int32 [mscorlib]System.Int32::Parse(string, class [mscorlib]System.IFormatProvider)
    stloc.s 0
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 1
    ldarg.s 0
    call string [mscorlib]System.IO.File::ReadAllText(string)
    stloc.s 2
    ldloc.s 2
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
  run_L1_start:
    ldloc.s 4
    ldloc.s 3
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge run_L1_end
    ldloc.s 3
    ldloc.s 4
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 5
    ldloc.s 5
    ldstr "id"
    call string TKVApp::'json_str'(string, string)
    stloc.s 6
    ldloc.s 6
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse run_If2_else
    br run_L1_cont
  run_If2_else:
    ldloc.s 6
    ldstr "file:"
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    brfalse run_If3_else
    ldloc.s 1
    ldloc.s 6
    ldloc.s 5
    ldstr "summary"
    call string TKVApp::'json_str'(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  run_If3_else:
  run_L1_cont:
    ldloc.s 4
    ldc.i4 1
    add
    stloc.s 4
    br run_L1_start
  run_L1_end:
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 7
    ldarg.s 3
    call string [mscorlib]System.IO.File::ReadAllText(string)
    stloc.s 8
    ldloc.s 8
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
    stloc.s 9
    ldstr ""
    stloc.s 10
    ldc.i4.0
    stloc.s 11
  run_L4_start:
    ldloc.s 11
    ldloc.s 9
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge run_L4_end
    ldloc.s 9
    ldloc.s 11
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 12
    ldloc.s 12
    ldstr "name"
    call string TKVApp::'json_str'(string, string)
    stloc.s 13
    ldloc.s 13
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse run_If5_else
    ldloc.s 13
    stloc.s 10
  run_If5_else:
    ldloc.s 12
    ldstr "\"file:"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 14
    ldloc.s 14
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse run_If6_else
    ldloc.s 14
    ldc.i4 1
    add
    stloc.s 16
    ldloc.s 12
    ldloc.s 16
    ldloc.s 12
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 16
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 15
    ldloc.s 15
    ldstr "\""
    call string TKVApp::'cut_at'(string, string)
    stloc.s 17
    ldloc.s 7
    ldloc.s 17
    ldloc.s 10
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
  run_If6_else:
  run_L4_cont:
    ldloc.s 11
    ldc.i4 1
    add
    stloc.s 11
    br run_L4_start
  run_L4_end:
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 18
    ldarg.s 1
    call string [mscorlib]System.IO.File::ReadAllText(string)
    stloc.s 19
    ldloc.s 19
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
    stloc.s 20
    ldc.i4.0
    stloc.s 21
  run_L7_start:
    ldloc.s 21
    ldloc.s 20
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge run_L7_end
    ldloc.s 20
    ldloc.s 21
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 22
    ldloc.s 22
    call string TKVApp::'edge_type'(string)
    ldstr "imports"
    call bool [mscorlib]System.String::Equals(string, string)
    ldc.i4.0
    ceq
    brfalse run_If8_else
    br run_L7_cont
  run_If8_else:
    ldloc.s 22
    ldstr "source"
    call string TKVApp::'json_str'(string, string)
    stloc.s 23
    ldloc.s 22
    ldstr "target"
    call string TKVApp::'json_str'(string, string)
    stloc.s 24
    ldloc.s 23
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse run_If9_else
    ldloc.s 18
    ldloc.s 23
    call string TKVApp::'node_file'(string)
    ldloc.s 24
    call string TKVApp::'node_file'(string)
    call int32 TKVApp::'link'(class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, string, string)
    pop
  run_If9_else:
  run_L7_cont:
    ldloc.s 21
    ldc.i4 1
    add
    stloc.s 21
    br run_L7_start
  run_L7_end:
    ldarg.s 2
    call string [mscorlib]System.IO.File::ReadAllText(string)
    stloc.s 25
    ldloc.s 25
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
    stloc.s 26
    ldc.i4.0
    stloc.s 27
  run_L10_start:
    ldloc.s 27
    ldloc.s 26
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge run_L10_end
    ldloc.s 26
    ldloc.s 27
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 28
    ldloc.s 28
    call string TKVApp::'edge_type'(string)
    stloc.s 29
    ldloc.s 29
    ldstr "contains"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse run_If11_else
    br run_L10_cont
  run_If11_else:
    ldloc.s 29
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse run_If12_else
    br run_L10_cont
  run_If12_else:
    ldloc.s 28
    ldstr "source"
    call string TKVApp::'json_str'(string, string)
    stloc.s 30
    ldloc.s 28
    ldstr "target"
    call string TKVApp::'json_str'(string, string)
    stloc.s 31
    ldloc.s 30
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    cgt
    brfalse run_If13_else
    ldloc.s 18
    ldloc.s 30
    call string TKVApp::'node_file'(string)
    ldloc.s 31
    call string TKVApp::'node_file'(string)
    call int32 TKVApp::'link'(class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, string, string)
    pop
  run_If13_else:
  run_L10_cont:
    ldloc.s 27
    ldc.i4 1
    add
    stloc.s 27
    br run_L10_start
  run_L10_end:
    ldarg.s 4
    call string TKVApp::'node_file'(string)
    stloc.s 32
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 33
    ldloc.s 33
    ldloc.s 32
    ldstr "0"
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 34
    ldloc.s 34
    ldloc.s 32
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 35
    ldloc.s 35
    ldloc.s 32
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 36
    ldloc.s 36
    ldloc.s 32
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldc.i4 1
    stloc.s 37
  run_W14_start:
    ldloc.s 37
    call int32 TKVApp::'ring_limit'()
    cgt
    ldc.i4.0
    ceq
    brfalse run_W14_end
    newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::.ctor()
    stloc.s 38
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 39
    ldc.i4 0
    stloc.s 40
  run_W15_start:
    ldloc.s 40
    ldloc.s 36
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse run_W15_end
    ldloc.s 18
    ldloc.s 36
    ldloc.s 40
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse run_dget16_miss
    ldloc.s 18
    ldloc.s 36
    ldloc.s 40
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br run_dget16_end
  run_dget16_miss:
    ldstr ""
  run_dget16_end:
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'blob_items'(string)
    stloc.s 41
    ldc.i4 0
    stloc.s 42
  run_W17_start:
    ldloc.s 42
    ldloc.s 41
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse run_W17_end
    ldloc.s 41
    ldloc.s 42
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 43
    ldloc.s 33
    ldloc.s 43
    call int32 TKVApp::'seen_at'(class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, string)
    ldc.i4 0
    ceq
    brfalse run_If18_else
    ldloc.s 38
    ldloc.s 43
    call int32 TKVApp::'bump'(class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, string)
    pop
    ldloc.s 38
    ldloc.s 43
    call int32 TKVApp::'num'(class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, string)
    ldc.i4 1
    ceq
    brfalse run_If19_else
    ldloc.s 39
    ldloc.s 43
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  run_If19_else:
  run_If18_else:
    ldloc.s 42
    ldc.i4 1
    add
    stloc.s 42
    br run_W17_start
  run_W17_end:
    ldloc.s 40
    ldc.i4 1
    add
    stloc.s 40
    br run_W15_start
  run_W15_end:
    ldc.i4 0
    stloc.s 44
  run_W20_start:
    ldloc.s 44
    ldloc.s 39
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse run_W20_end
    ldloc.s 39
    ldloc.s 44
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 45
    ldloc.s 38
    ldloc.s 45
    call int32 TKVApp::'num'(class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>, string)
    ldc.i4 10
    mul
    ldloc.s 7
    ldloc.s 45
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse run_dget21_miss
    ldloc.s 7
    ldloc.s 45
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br run_dget21_end
  run_dget21_miss:
    ldstr ""
  run_dget21_end:
    call int32 TKVApp::'layer_bonus'(string)
    add
    stloc.s 46
    ldloc.s 38
    ldloc.s 45
    ldloca.s 46
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    ldloc.s 44
    ldc.i4 1
    add
    stloc.s 44
    br run_W20_start
  run_W20_end:
    ldloc.s 39
    ldloc.s 38
    call class [mscorlib]System.Collections.Generic.List`1<string> TKVApp::'order_by_heat'(class [mscorlib]System.Collections.Generic.List`1<string>, class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>)
    stloc.s 47
    ldc.i4 0
    stloc.s 48
  run_W22_start:
    ldloc.s 48
    ldloc.s 47
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse run_W22_end
    ldloc.s 33
    ldloc.s 47
    ldloc.s 48
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    ldloca.s 37
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::set_Item(!0, !1)
    ldloc.s 34
    ldloc.s 47
    ldloc.s 48
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 48
    ldc.i4 1
    add
    stloc.s 48
    br run_W22_start
  run_W22_end:
    ldloc.s 47
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    ldc.i4 0
    ceq
    brfalse run_If23_else
    call int32 TKVApp::'ring_limit'()
    stloc.s 37
  run_If23_else:
    ldloc.s 47
    stloc.s 36
    ldloc.s 37
    ldc.i4 1
    add
    stloc.s 37
    br run_W14_start
  run_W14_end:
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 49
    ldc.i4 0
    stloc.s 50
    ldc.i4 0
    stloc.s 51
    ldc.i4 0
    stloc.s 52
    ldc.i4 0
    stloc.s 53
  run_W24_start:
    ldloc.s 53
    ldloc.s 34
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse run_W24_end
    ldloc.s 34
    ldloc.s 53
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 54
    ldc.i4 5
    stloc.s 56
    ldloc.s 54
    ldloc.s 56
    ldloc.s 54
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 56
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 55
    ldloc.s 55
    call string [mscorlib]System.IO.File::ReadAllText(string)
    stloc.s 57
    ldloc.s 57
    call int32 TKVApp::'est_tokens'(string)
    stloc.s 58
    ldloc.s 1
    ldloc.s 54
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse run_dget25_miss
    ldloc.s 1
    ldloc.s 54
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br run_dget25_end
  run_dget25_miss:
    ldstr ""
  run_dget25_end:
    stloc.s 59
    ldloc.s 33
    ldloc.s 54
    callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::ContainsKey(!0)
    brfalse run_dget26_miss
    ldloc.s 33
    ldloc.s 54
    callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>::get_Item(!0)
    br run_dget26_end
  run_dget26_miss:
    ldstr "9"
  run_dget26_end:
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call int32 [mscorlib]System.Int32::Parse(string, class [mscorlib]System.IFormatProvider)
    stloc.s 60
    ldstr "tom-tat"
    stloc.s 61
    ldc.i4 0
    stloc.s 62
    ldloc.s 54
    ldloc.s 32
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse run_If27_else
    ldstr "day-du"
    stloc.s 61
    ldloc.s 58
    stloc.s 62
    ldloc.s 50
    ldloc.s 58
    add
    stloc.s 50
    ldloc.s 51
    ldc.i4 1
    add
    stloc.s 51
  run_If27_else:
    ldloc.s 50
    ldloc.s 58
    add
    ldloc.s 0
    cgt
    ldc.i4.0
    ceq
    brfalse run_If28_else
    ldloc.s 61
    ldstr "tom-tat"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse run_If29_else
    ldstr "day-du"
    stloc.s 61
    ldloc.s 58
    stloc.s 62
    ldloc.s 50
    ldloc.s 58
    add
    stloc.s 50
    ldloc.s 51
    ldc.i4 1
    add
    stloc.s 51
  run_If29_else:
  run_If28_else:
    ldloc.s 61
    ldstr "tom-tat"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse run_If30_else
    ldloc.s 52
    ldc.i4 1
    add
    stloc.s 52
  run_If30_else:
    ldloc.s 49
    ldloc.s 54
    ldloc.s 61
    ldloc.s 60
    ldloc.s 62
    ldloc.s 59
    call string TKVApp::'entry_json'(string, string, int32, int32, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 53
    ldc.i4 1
    add
    stloc.s 53
    br run_W24_start
  run_W24_end:
    ldstr "{\n \"target\": \""
    ldarg.s 4
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\",\n \"budget\": "
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 0
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 63
    ldloc.s 63
    ldstr ",\n \"used\": "
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 50
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 63
    ldloc.s 63
    ldstr ",\n \"files\": [\n"
    call string [mscorlib]System.String::Concat(string, string)
    ldstr ",\n"
    ldloc.s 49
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\n ],\n"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 63
    ldloc.s 63
    ldstr " \"stats\": {\"tong\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 34
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 64
    ldloca.s 64
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 63
    ldloc.s 63
    ldstr ",\"doc_day_du\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 51
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 63
    ldloc.s 63
    ldstr ",\"chi_tom_tat\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 52
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 63
    ldc.i4 0
    stloc.s 65
    ldloc.s 50
    ldloc.s 0
    cgt
    brfalse run_If31_else
    ldc.i4 1
    stloc.s 65
  run_If31_else:
    ldloc.s 63
    ldstr ",\"token\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 50
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 63
    ldloc.s 63
    ldstr ",\"vuot_han_muc\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 65
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "}\n}\n"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 63
    ldarg.s 6
    ldloc.s 63
    call void [mscorlib]System.IO.File::WriteAllText(string, string)
    ldstr "file="
    ldloc.s 34
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 66
    ldloca.s 66
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " day_du="
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 51
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " tom_tat="
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 52
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " token="
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 50
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "/"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 0
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
    .locals init (int32 'cut', int32 'i', int32 '__slice2583844813648_start')
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
    .locals init (string 'body', int32 '__slice2583844812048_start', int32 '__slice2583844765840_start', string 'out', int32 'i', string 'ch')
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
    .locals init (int32 'cut', int32 'i', int32 '__slice2583844765840_start')
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
    .locals init (int32 'cut', int32 'i', int32 '__slice2583844776640_start')
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
    .locals init (string 'body', string 'rest', int32 '__slice2583844812208_start', int32 '__slice2583844766080_start')
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
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', string 'body', string 'mod', string 'rest', int32 '__slice2583844766480_start', class [mscorlib]System.Collections.Generic.List`1<string> 'parts', int32 '__iterlist4_idx', string 'part', string 'piece')
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
    .locals init (int32 'n', int32 'i', int32 '__slice2583844767040_start')
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
    .locals init (int32 'lvl', string 'tail', int32 '__slice2583844806048_start', string 'base', int32 'up', string 'pkg', string 'full', string 'probe', string 'hit')
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
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', string 'text', class [mscorlib]System.Collections.Generic.List`1<string> 'lines', int32 'in_doc', int32 '__iterlist7_idx', string 'ln', int32 'tri', int32 'was_doc', int32 '__idiv2583844805408_a', int32 '__idiv2583844805408_b', int32 '__idiv2583844805408_q', int32 '__idiv2583844805408_r', class [mscorlib]System.Collections.Generic.List`1<string> 'mods', int32 '__iterlist8_idx', string 'mod', string 'hit')
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
    .locals init (string 'raw', class [mscorlib]System.Collections.Generic.List`1<string> 'rows', class [mscorlib]System.Collections.Generic.List`1<string> 'paths', int32 '__iterlist9_idx', string 'r', string 'p', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'base_idx', int32 'n_total', int32 'n_int', int32 'n_ext', int32 'n_amb', int32 'n_self', int32 'n_dup', class [mscorlib]System.Collections.Generic.List`1<string> 'edges', class [System.Core]System.Collections.Generic.HashSet`1<string> 'seen', int32 '__iterlist10_idx', string 'rel', class [mscorlib]System.Collections.Generic.List`1<string> 'results', int32 '__iterlist11_idx', string 'res', string 'kind', string 'target', int32 '__slice2583844805248_start', string 'key', class [mscorlib]System.Collections.Generic.List`1<string> 'pieces', int32 'i', string 'body', string 'doc', int32 '__strtmp2583844549056', int32 '__strtmp2583844656512', int32 '__strtmp2583844548224', int32 '__strtmp2583844542848')
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
    ldarg.0
    ldc.i4 6
    ldelem.ref
    call string TKVApp::'run'(string, string, string, string, string, string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ret
  }
}
