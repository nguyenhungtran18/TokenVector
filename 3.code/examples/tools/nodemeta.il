.assembly extern mscorlib {}
.assembly extern System.Core { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly extern System { .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) .ver 4:0:0:0 }
.assembly TKVApp {}
.module TKVApp.exe

.class public auto ansi TKVApp extends [mscorlib]System.Object
{
  .method public static string 'base_of'(string 'rel') cil managed
  {
    .maxstack 8
    .locals init (int32 'cut', int32 'i', int32 '__slice2136717438752_start')
    ldc.i4 1
    neg
    stloc.s 0
    ldc.i4 0
    stloc.s 1
  base_of_W1_start:
    ldloc.s 1
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    clt
    brfalse base_of_W1_end
    ldarg.s 0
    ldloc.s 1
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    ldc.i4.1
    newobj instance void [mscorlib]System.String::.ctor(char, int32)
    ldstr "/"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse base_of_If2_else
    ldloc.s 1
    stloc.s 0
  base_of_If2_else:
    ldloc.s 1
    ldc.i4 1
    add
    stloc.s 1
    br base_of_W1_start
  base_of_W1_end:
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
  .method public static int32 'is_doc_open'(string 'body') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldstr "\"\"\""
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    brfalse is_doc_open_If1_else
    ldc.i4 1
    ret
  is_doc_open_If1_else:
    ldarg.s 0
    ldstr "'''"
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    brfalse is_doc_open_If2_else
    ldc.i4 1
    ret
  is_doc_open_If2_else:
    ldc.i4 0
    ret
  }
  .method public static int32 'skip_line'(string 'body') cil managed
  {
    .maxstack 8
    ldarg.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 0
    ceq
    brfalse skip_line_If1_else
    ldc.i4 1
    ret
  skip_line_If1_else:
    ldarg.s 0
    ldstr "#"
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    brfalse skip_line_If2_else
    ldc.i4 1
    ret
  skip_line_If2_else:
    ldc.i4 0
    ret
  }
  .method public static string 'module_doc'(string 'text') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'lines', int32 'started', class [mscorlib]System.Collections.Generic.List`1<string> 'acc', int32 'i', string 'body', string 'rest', int32 '__slice2136717986848_start', int32 'close_at', int32 '__slice2136717987248_start', string 'head')
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
    ldc.i4 0
    stloc.s 1
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 2
    ldc.i4 0
    stloc.s 3
  module_doc_W1_start:
    ldloc.s 3
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    clt
    brfalse module_doc_W1_end
    ldloc.s 0
    ldloc.s 3
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    callvirt instance string [mscorlib]System.String::Trim()
    stloc.s 4
    ldloc.s 1
    ldc.i4 0
    ceq
    brfalse module_doc_If2_else
    ldloc.s 4
    call int32 TKVApp::'skip_line'(string)
    ldc.i4 1
    ceq
    brfalse module_doc_If3_else
    ldloc.s 3
    ldc.i4 1
    add
    stloc.s 3
    br module_doc_W1_start
  module_doc_If3_else:
    ldloc.s 4
    call int32 TKVApp::'is_doc_open'(string)
    ldc.i4 0
    ceq
    brfalse module_doc_If4_else
    ldstr ""
    ret
  module_doc_If4_else:
    ldc.i4 1
    stloc.s 1
    ldc.i4 3
    stloc.s 6
    ldloc.s 4
    ldloc.s 6
    ldloc.s 4
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldloc.s 6
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 5
    ldloc.s 5
    ldstr "\"\"\""
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 7
    ldloc.s 7
    ldc.i4 0
    clt
    brfalse module_doc_If5_else
    ldloc.s 5
    ldstr "'''"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 7
  module_doc_If5_else:
    ldloc.s 7
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse module_doc_If6_else
    ldc.i4 0
    stloc.s 8
    ldloc.s 5
    ldloc.s 8
    ldloc.s 7
    ldloc.s 8
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    ret
  module_doc_If6_else:
    ldloc.s 2
    ldloc.s 5
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 3
    ldc.i4 1
    add
    stloc.s 3
    br module_doc_W1_start
  module_doc_If2_else:
    ldloc.s 0
    ldloc.s 3
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    call int32 TKVApp::'count_triple'(string)
    ldc.i4 0
    cgt
    brfalse module_doc_If7_else
    ldloc.s 4
    ldstr "\"'"
    call string TKVApp::'cut_at'(string, string)
    stloc.s 9
    ldloc.s 2
    ldloc.s 9
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldstr " "
    ldloc.s 2
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    ret
  module_doc_If7_else:
    ldloc.s 2
    ldloc.s 4
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 3
    ldc.i4 1
    add
    stloc.s 3
    br module_doc_W1_start
  module_doc_W1_end:
    ldstr ""
    ret
  }
  .method public static string 'first_sentence'(string 'doc') cil managed
  {
    .maxstack 8
    .locals init (string 'txt', int32 'stop', int32 '__slice2136717985808_start', int32 '__slice2136717985968_start')
    ldarg.s 0
    callvirt instance string [mscorlib]System.String::Trim()
    stloc.s 0
    ldloc.s 0
    ldstr ". "
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    stloc.s 1
    ldloc.s 1
    ldc.i4 0
    cgt
    brfalse first_sentence_If1_else
    ldc.i4 0
    stloc.s 2
    ldloc.s 0
    ldloc.s 2
    ldloc.s 1
    ldc.i4 1
    add
    ldloc.s 2
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 0
  first_sentence_If1_else:
    ldloc.s 0
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 200
    cgt
    brfalse first_sentence_If2_else
    ldc.i4 0
    stloc.s 3
    ldloc.s 0
    ldloc.s 3
    ldc.i4 200
    ldloc.s 3
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 0
  first_sentence_If2_else:
    ldloc.s 0
    callvirt instance string [mscorlib]System.String::Trim()
    ret
  }
  .method public static string 'json_escape'(string 's') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'parts', string 'step1', class [mscorlib]System.Collections.Generic.List`1<string> 'parts2')
    ldarg.s 0
    ldc.i4.1
    newarr [mscorlib]System.Char
    dup
    ldc.i4.0
    ldstr "\\"
    ldc.i4.0
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    stelem.i2
    callvirt instance string[] [mscorlib]System.String::Split(char[])
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
    stloc.s 0
    ldstr "\\\\"
    ldloc.s 0
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    stloc.s 1
    ldloc.s 1
    ldc.i4.1
    newarr [mscorlib]System.Char
    dup
    ldc.i4.0
    ldstr "\""
    ldc.i4.0
    callvirt instance char [mscorlib]System.String::get_Chars(int32)
    stelem.i2
    callvirt instance string[] [mscorlib]System.String::Split(char[])
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
    stloc.s 2
    ldstr "\\\""
    ldloc.s 2
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    ret
  }
  .method public static int32 'code_lines'(string 'text') cil managed
  {
    .maxstack 8
    .locals init (int32 'n', class [mscorlib]System.Collections.Generic.List`1<string> 'lines', int32 '__iterlist0_idx', string 'ln')
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
  code_lines_L1_start:
    ldloc.s 2
    ldloc.s 1
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge code_lines_L1_end
    ldloc.s 1
    ldloc.s 2
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 3
    ldloc.s 3
    callvirt instance string [mscorlib]System.String::Trim()
    call int32 TKVApp::'skip_line'(string)
    ldc.i4 0
    ceq
    brfalse code_lines_If2_else
    ldloc.s 0
    ldc.i4 1
    add
    stloc.s 0
  code_lines_If2_else:
  code_lines_L1_cont:
    ldloc.s 2
    ldc.i4 1
    add
    stloc.s 2
    br code_lines_L1_start
  code_lines_L1_end:
    ldloc.s 0
    ret
  }
  .method public static string 'complexity_of'(int32 'n') cil managed
  {
    .maxstack 8
    ldarg.s 0
    ldc.i4 50
    clt
    brfalse complexity_of_If1_else
    ldstr "simple"
    ret
  complexity_of_If1_else:
    ldarg.s 0
    ldc.i4 200
    clt
    brfalse complexity_of_If2_else
    ldstr "moderate"
    ret
  complexity_of_If2_else:
    ldstr "complex"
    ret
  }
  .method public static string 'tags_of'(string 'rel') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'acc', string 'name')
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 0
    ldarg.s 0
    call string TKVApp::'base_of'(string)
    stloc.s 1
    ldloc.s 0
    ldstr "python"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 1
    ldstr "test_"
    callvirt instance bool [mscorlib]System.String::StartsWith(string)
    brfalse tags_of_If1_else
    ldloc.s 0
    ldstr "test"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br tags_of_If1_end
  tags_of_If1_else:
    ldloc.s 1
    ldstr "_test.py"
    callvirt instance bool [mscorlib]System.String::EndsWith(string)
    brfalse tags_of_If2_else
    ldloc.s 0
    ldstr "test"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br tags_of_If2_end
  tags_of_If2_else:
    ldarg.s 0
    ldstr "/tests/"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse tags_of_If3_else
    ldloc.s 0
    ldstr "test"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  tags_of_If3_else:
  tags_of_If2_end:
  tags_of_If1_end:
    ldloc.s 1
    ldstr "__init__.py"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse tags_of_If4_else
    ldloc.s 0
    ldstr "entry-point"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    ldloc.s 0
    ldstr "barrel"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  tags_of_If4_else:
    ldloc.s 1
    ldstr "setup.py"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse tags_of_If5_else
    ldloc.s 0
    ldstr "build-system"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  tags_of_If5_else:
    ldloc.s 1
    ldstr "manage.py"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse tags_of_If6_else
    ldloc.s 0
    ldstr "entry-point"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  tags_of_If6_else:
    ldloc.s 1
    ldstr "__main__.py"
    call bool [mscorlib]System.String::Equals(string, string)
    brfalse tags_of_If7_else
    ldloc.s 0
    ldstr "entry-point"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  tags_of_If7_else:
    ldarg.s 0
    ldstr "/tools/"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse tags_of_If8_else
    ldloc.s 0
    ldstr "tooling"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  tags_of_If8_else:
    ldarg.s 0
    ldstr "/compiler/"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse tags_of_If9_else
    ldloc.s 0
    ldstr "compiler"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  tags_of_If9_else:
    ldarg.s 0
    ldstr "/benchmark"
    callvirt instance int32 [mscorlib]System.String::IndexOf(string)
    ldc.i4 0
    clt
    ldc.i4.0
    ceq
    brfalse tags_of_If10_else
    ldloc.s 0
    ldstr "benchmark"
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  tags_of_If10_else:
    ldstr "\",\""
    ldloc.s 0
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    ret
  }
  .method public static string 'node_json'(string 'rel', string 'summary', string 'tags', string 'cx', string 'src') cil managed
  {
    .maxstack 8
    .locals init (string 'out')
    ldstr "{\"id\":\"file:"
    ldarg.s 0
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\",\"type\":\"file\""
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
    ldloc.s 0
    ldstr ",\"summary\":\""
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 1
    call string TKVApp::'json_escape'(string)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\""
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
    ldloc.s 0
    ldstr ",\"tags\":[\""
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 2
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\"]"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
    ldloc.s 0
    ldstr ",\"complexity\":\""
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 3
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\""
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
    ldloc.s 0
    ldstr ",\"summary_source\":\""
    call string [mscorlib]System.String::Concat(string, string)
    ldarg.s 4
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\"}"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 0
    ldloc.s 0
    ret
  }
  .method public static string 'run'(string 'manifest', string 'nodes_out', string 'need_out') cil managed
  {
    .maxstack 8
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'paths', string 'raw', class [mscorlib]System.Collections.Generic.List`1<string> 'rows', int32 '__iterlist1_idx', string 'r', string 'p', class [mscorlib]System.Collections.Generic.List`1<string> 'nodes', class [mscorlib]System.Collections.Generic.List`1<string> 'need', int32 'n_doc', int32 '__iterlist2_idx', string 'rel', string 'text', string 'doc', string 'src', string 'summary', int32 '__slice2136717438592_start', string 'cx', string 'doc_out', int32 '__strtmp2136722293312', int32 '__strtmp2136717689472', int32 '__strtmp2136717619840', int32 '__strtmp2136717607104')
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
    ldc.i4.0
    stloc.s 3
  run_L1_start:
    ldloc.s 3
    ldloc.s 2
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge run_L1_end
    ldloc.s 2
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
    ldloc.s 0
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
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 6
    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
    stloc.s 7
    ldc.i4 0
    stloc.s 8
    ldc.i4.0
    stloc.s 9
  run_L3_start:
    ldloc.s 9
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    bge run_L3_end
    ldloc.s 0
    ldloc.s 9
    callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
    stloc.s 10
    ldloc.s 10
    call string [mscorlib]System.IO.File::ReadAllText(string)
    stloc.s 11
    ldloc.s 11
    call string TKVApp::'module_doc'(string)
    stloc.s 12
    ldstr "docstring"
    stloc.s 13
    ldstr ""
    stloc.s 14
    ldloc.s 12
    callvirt instance string [mscorlib]System.String::Trim()
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 16
    clt
    brfalse run_If4_else
    ldstr "missing"
    stloc.s 13
    ldloc.s 7
    ldloc.s 10
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    br run_If4_end
  run_If4_else:
    ldloc.s 12
    call string TKVApp::'first_sentence'(string)
    stloc.s 14
    ldloc.s 14
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 8
    clt
    brfalse run_If5_else
    ldloc.s 12
    callvirt instance string [mscorlib]System.String::Trim()
    stloc.s 14
    ldloc.s 14
    callvirt instance int32 [mscorlib]System.String::get_Length()
    ldc.i4 200
    cgt
    brfalse run_If6_else
    ldc.i4 0
    stloc.s 15
    ldloc.s 14
    ldloc.s 15
    ldc.i4 200
    ldloc.s 15
    sub
    callvirt instance string [mscorlib]System.String::Substring(int32, int32)
    stloc.s 14
  run_If6_else:
  run_If5_else:
    ldloc.s 8
    ldc.i4 1
    add
    stloc.s 8
  run_If4_end:
    ldloc.s 11
    call int32 TKVApp::'code_lines'(string)
    call string TKVApp::'complexity_of'(int32)
    stloc.s 16
    ldloc.s 6
    ldstr "  "
    ldloc.s 10
    ldloc.s 14
    ldloc.s 10
    call string TKVApp::'tags_of'(string)
    ldloc.s 16
    ldloc.s 13
    call string TKVApp::'node_json'(string, string, string, string, string)
    call string [mscorlib]System.String::Concat(string, string)
    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
  run_L3_cont:
    ldloc.s 9
    ldc.i4 1
    add
    stloc.s 9
    br run_L3_start
  run_L3_end:
    ldstr "{\n \"nodes\": [\n"
    ldstr ",\n"
    ldloc.s 6
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr "\n ],\n \"stats\": {"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 17
    ldloc.s 17
    ldstr "\"files\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 18
    ldloca.s 18
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 17
    ldloc.s 17
    ldstr ",\"summary_tu_docstring\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 8
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 17
    ldloc.s 17
    ldstr ",\"can_llm\":"
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 7
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 19
    ldloca.s 19
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 17
    ldloc.s 17
    ldstr "}\n}\n"
    call string [mscorlib]System.String::Concat(string, string)
    stloc.s 17
    ldarg.s 1
    ldloc.s 17
    call void [mscorlib]System.IO.File::WriteAllText(string, string)
    ldarg.s 2
    ldstr "\n"
    ldloc.s 7
    call string [mscorlib]System.String::Join(string, class [mscorlib]System.Collections.Generic.IEnumerable`1<string>)
    call void [mscorlib]System.IO.File::WriteAllText(string, string)
    ldstr "files="
    ldloc.s 0
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 20
    ldloca.s 20
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " summary_tu_docstring="
    call string [mscorlib]System.String::Concat(string, string)
    ldloca.s 8
    call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
    call instance string int32::ToString(class [mscorlib]System.IFormatProvider)
    call string [mscorlib]System.String::Concat(string, string)
    ldstr " can_llm="
    call string [mscorlib]System.String::Concat(string, string)
    ldloc.s 7
    callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
    stloc.s 21
    ldloca.s 21
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
    .locals init (int32 'cut', int32 'i', int32 '__slice2136717996848_start')
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
    .locals init (string 'body', int32 '__slice2136717998208_start', int32 '__slice2136717998448_start', string 'out', int32 'i', string 'ch')
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
    .locals init (int32 'cut', int32 'i', int32 '__slice2136717999888_start')
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
    .locals init (int32 'cut', int32 'i', int32 '__slice2136717789200_start')
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
    .locals init (string 'body', string 'rest', int32 '__slice2136717999888_start', int32 '__slice2136717998128_start')
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
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', string 'body', string 'mod', string 'rest', int32 '__slice2136717998368_start', class [mscorlib]System.Collections.Generic.List`1<string> 'parts', int32 '__iterlist3_idx', string 'part', string 'piece')
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
    .locals init (int32 'n', int32 'i', int32 '__slice2136717996688_start')
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
    .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', int32 '__iterlist4_idx', string 'rel', string 'dotted')
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
    .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', int32 '__iterlist5_idx', string 'rel', string 'dotted', string 'base')
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
    .locals init (int32 'lvl', string 'tail', int32 '__slice2136717438592_start', string 'base', int32 'up', string 'pkg', string 'full', string 'probe', string 'hit')
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
    .locals init (class [mscorlib]System.Collections.Generic.List`1<string> 'out', string 'text', class [mscorlib]System.Collections.Generic.List`1<string> 'lines', int32 'in_doc', int32 '__iterlist6_idx', string 'ln', int32 'tri', int32 'was_doc', int32 '__idiv2136717993568_a', int32 '__idiv2136717993568_b', int32 '__idiv2136717993568_q', int32 '__idiv2136717993568_r', class [mscorlib]System.Collections.Generic.List`1<string> 'mods', int32 '__iterlist7_idx', string 'mod', string 'hit')
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
    .locals init (string 'raw', class [mscorlib]System.Collections.Generic.List`1<string> 'rows', class [mscorlib]System.Collections.Generic.List`1<string> 'paths', int32 '__iterlist8_idx', string 'r', string 'p', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'idx', class [mscorlib]System.Collections.Generic.Dictionary`2<string, string> 'base_idx', int32 'n_total', int32 'n_int', int32 'n_ext', int32 'n_amb', int32 'n_self', int32 'n_dup', class [mscorlib]System.Collections.Generic.List`1<string> 'edges', class [System.Core]System.Collections.Generic.HashSet`1<string> 'seen', int32 '__iterlist9_idx', string 'rel', class [mscorlib]System.Collections.Generic.List`1<string> 'results', int32 '__iterlist10_idx', string 'res', string 'kind', string 'target', int32 '__slice2136717986288_start', string 'key', class [mscorlib]System.Collections.Generic.List`1<string> 'pieces', int32 'i', string 'body', string 'doc', int32 '__strtmp2136717894208', int32 '__strtmp2136717584192', int32 '__strtmp2136717583552', int32 '__strtmp2136722296832')
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
    call string TKVApp::'run'(string, string, string)
    call void [mscorlib]System.Console::WriteLine(string)
    ret
  }
}
