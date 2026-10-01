# DANH MUC HAM CUA COMPILER

> **Tu sinh** tu ma nguon boi `tools/gen_builtin_ref.py` - KHONG sua tay.
> Sinh lai sau khi them/bot ham: `python tools\gen_builtin_ref.py`

**Dung muc dich:** truoc khi THEM MOT HAM, doi MOT KIUE hay tao file
mo trong `compiler/il_features/`, kiem danh muc nay va kiem tra file
da ton tai chua. Da co mot lan: tao `bytes_type.tkv` de bo sung ham
`bytes()` nhung file do DA TON TAI va la module that cua compiler -
ghi de lam hong ca buoc bien dich.

## DANG CAU LENH (MACRO CAP DONG) (37)

`attr_assign` `break` `bytearray_append` `bytes_append_blocked` `call_stmt` `container_clear` `continue` `del_stmt`
`f32buf_free_stmt` `for` `for_in_dict_items` `for_in_generator` `for_in_iter` `for_tuple_pairs` `if` `list_append`
`list_extend` `list_insert` `list_remove` `list_reverse` `list_sort` `match` `multi_assign` `nested_def`
`pass` `raise` `return` `set_add` `set_discard` `set_remove` `try` `tuple_assign`
`while` `with_ctx` `with_open` `yield_from_stmt` `yield_stmt`

## DANG PHAI PHAI CUA PHE GAN (25)

`base64_decode` `base64_encode` `bytearray_new` `bytes_literal` `bytes_new` `datetime` `dict_literal` `dict_new`
`f32buf_new` `frozenset_new` `list_count` `list_literal` `list_repeat` `list_slice` `md5_hex` `os_getenv`
`os_list_files` `os_mkdir` `repeat_str` `set_literal` `set_new` `sha256_hex` `shutil_rmtree` `tuple_literal`
`win_gui` 

## HAM BUILTIN (GOI DUOC TRUC TIEP) (174)

`all` `alloc_bytes` `any` `asyncio_get_ticks` `asyncio_sleep_ms` `atan2` `base64_decode` `base64_encode`
`bin` `bool` `bstr_alloc` `bstr_free` `bstr_read` `bytes_from_string` `c_puts` `chain`
`choice` `chr` `cjson_delete` `cjson_get_obj` `cjson_get_str` `cjson_parse` `combinations` `complex`
`csv_join_row` `csv_parse_line` `csv_read_lines` `csv_write_lines` `ctypes_call` `ctypes_cdll` `datetime` `datetime_add`
`datetime_diff` `datetime_strptime` `datetime_sub` `datetime_ticks` `db_close` `db_exec` `db_open` `db_query_int`
`db_query_text` `deque_clear` `deque_reverse` `divmod` `enumerate` `eval_arith` `eval_code` `eval_expr`
`exec_code` `f32x4` `factorial` `file_exists` `filter` `float` `fmt_float` `fmt_num`
`free_bytes` `functools_clamp_f64` `functools_clamp_i32` `getattr` `hasattr` `hex` `http_delete` `http_get`
`http_post` `http_post_type` `http_put` `http_request` `http_server_generate` `hypot` `input` `int`
`int64` `isinstance` `issubclass` `json_dumps` `json_get_str` `json_loads` `launch_media_player_gui` `launch_tms_db_manager`
`launch_tms_gui` `launch_tms_web` `map` `math_e` `math_gcd` `math_pi` `max` `md5_hex`
`media_player_gui_window` `min` `most_common` `multiprocessing_cpu_count` `oct` `ord` `os_getenv` `os_list_files`
`os_mkdir` `path_abspath` `path_basename` `path_dirname` `path_exists` `path_isdir` `path_isfile` `path_join`
`path_name` `path_normpath` `path_parent` `path_read_text` `path_splitext` `path_stem` `path_suffix` `path_write_text`
`pow` `process_get_pid` `product` `py_dict_new` `py_tuple_new` `randint` `random` `random_randint`
`randrange` `re_findall` `re_fullmatch` `re_match` `re_replace` `re_search` `re_split` `re_sub`
`read_ansi` `read_f32` `read_file` `read_i32` `read_i64` `read_u8` `reduce` `repr`
`reserve` `reversed` `sample` `sha256_hex` `socket_resolve_host` `sorted` `str` `string_from_bytes`
`struct_f64_to_hex` `struct_i32_to_hex` `sum` `sys_argv` `thread_join` `thread_sleep` `thread_spawn` `type`
`uniform` `v_add8` `v_fill8` `v_hsum` `v_hsum4` `v_lane` `v_load4` `v_load8`
`v_mul8` `v_mul8_add8` `v_store4` `v_store8` `v_sub8` `vtable_cell` `write_f32` `write_i32`
`write_i64` `write_u8` `xml_encode_name` `zip` `zip_create` `zip_extract`

## KIEU CAU LENH (SINH IL) (63)

`assign_base64_decode` `assign_base64_encode` `assign_bytearray_new` `assign_bytes_literal` `assign_bytes_new` `assign_datetime_now` `assign_dict_literal` `assign_dict_new`
`assign_f32buf_new` `assign_frozenset_new` `assign_list_count` `assign_list_literal` `assign_list_new` `assign_list_repeat` `assign_list_slice` `assign_md5_hex`
`assign_multi_target` `assign_os_getenv` `assign_os_list_files` `assign_os_mkdir` `assign_repeat_str` `assign_set_literal` `assign_set_new` `assign_sha256_hex`
`assign_shutil_rmtree` `assign_tuple_literal` `assign_win_gui` `attr_assign` `break` `bytearray_append` `call_stmt` `container_clear`
`continue` `del_stmt` `f32buf_free_stmt` `for` `for_in_call_list` `for_in_dict_items` `for_in_generator` `for_in_iter`
`for_tuple_pairs` `if` `list_append` `list_extend` `list_insert` `list_remove` `list_reverse` `list_sort`
`nested_def` `raise` `return` `return_tuple` `sb_append` `set_add` `set_discard` `set_remove`
`try` `tuple_assign` `while` `with_ctx` `with_open` `yield_from_stmt` `yield_stmt`

## MACRO VIET TAY (25)

`apply` `argmax` `assert` `binop_macro` `compound_attr` `compound_index` `compound_var` `dense`
`dict_or_set_comp` `dict_update` `expr_hoist` `for_chain` `for_enumerate` `for_in_kvlist` `for_in_list` `for_zip`
`fstring` `is_none` `list_comp` `matvec` `minmax_2arg` `normalize` `scale` `string_format`
`string_percent_format` 

## METHOD THEO KHU VUC (14)

`center` `copy` `count` `items` `join` `keys` `ljust` `rjust`
`split` `strftime` `title` `to_list` `values` `zfill`

**Tong so ten da dang ky: 338**

## File trong `compiler/il_features/`

| File | Kich thuoc |
|---|---|
| `__init__.tkv` | 0 |
| `async_await.tkv` | 1.603 |
| `bytearray_type.tkv` | 5.451 |
| `bytes_type.tkv` | 13.025 |
| `call_star_args.tkv` | 14.917 |
| `chr_builtin.tkv` | 1.661 |
| `closures.tkv` | 15.795 |
| `complex_type.tkv` | 5.606 |
| `comprehension.tkv` | 6.711 |
| `control_flow.tkv` | 111.624 |
| `counter_type.tkv` | 17.988 |
| `datetime_type.tkv` | 9.835 |
| `defaultdict_type.tkv` | 5.437 |
| `del_stmt.tkv` | 4.666 |
| `dict_get.tkv` | 2.078 |
| `dict_items_list.tkv` | 3.612 |
| `dict_keys_values.tkv` | 3.663 |
| `dict_pop.tkv` | 4.170 |
| `dict_setdefault.tkv` | 2.323 |
| `dict_type.tkv` | 42.361 |
| `divmod_builtin.tkv` | 4.251 |
| `duck_typing.tkv` | 26.440 |
| `dynamic_exec.tkv` | 2.685 |
| `expr_hoist.tkv` | 6.808 |
| `f32buf_type.tkv` | 10.760 |
| `ffi_feature.tkv` | 2.589 |
| `file_io.tkv` | 10.921 |
| `float_builtin.tkv` | 2.839 |
| `for_in_kvlist.tkv` | 2.185 |
| `fstring.tkv` | 6.453 |
| `generator_feature.tkv` | 1.436 |
| `generator_lazy.tkv` | 25.056 |
| `int_builtin.tkv` | 16.848 |
| `int_narrow.tkv` | 11.347 |
| `int_type.tkv` | 35.952 |
| `kwarg_resolve.tkv` | 3.482 |
| `list_copy.tkv` | 1.540 |
| `list_count_index.tkv` | 7.278 |
| `list_methods_batch2.tkv` | 15.204 |
| `list_methods_batch3.tkv` | 2.141 |
| `list_pop.tkv` | 7.956 |
| `list_type.tkv` | 65.261 |
| `logging_feature.tkv` | 3.417 |
| `media_player_gui_window.tkv` | 139.437 |
| `metaprogramming.tkv` | 3.183 |
| `multi_assign.tkv` | 3.145 |
| `nativebuf.tkv` | 11.904 |
| `nested_array_extern.tkv` | 6.408 |
| `operators.tkv` | 47.494 |
| `ord_builtin.tkv` | 1.167 |
| `pickle_feature.tkv` | 3.600 |
| `print_feature.tkv` | 4.226 |
| `pycapi_shim.tkv` | 1.837 |
| `record_feature.tkv` | 35.518 |
| `set_methods_batch2.tkv` | 7.110 |
| `set_to_list.tkv` | 2.754 |
| `set_type.tkv` | 26.289 |
| `slicing.tkv` | 12.201 |
| `stdlib_aggregates.tkv` | 19.200 |
| `stdlib_asyncio.tkv` | 1.324 |
| `stdlib_base64.tkv` | 3.066 |
| `stdlib_bcl.tkv` | 2.127 |
| `stdlib_cjson.tkv` | 4.095 |
| `stdlib_csv.tkv` | 3.549 |
| `stdlib_deque.tkv` | 1.306 |
| `stdlib_eval.tkv` | 10.506 |
| `stdlib_functional.tkv` | 16.919 |
| `stdlib_functools.tkv` | 1.678 |
| `stdlib_hashlib.tkv` | 4.009 |
| `stdlib_http.tkv` | 19.227 |
| `stdlib_http_full.tkv` | 14.746 |
| `stdlib_input.tkv` | 1.255 |
| `stdlib_io.tkv` | 1.704 |
| `stdlib_itertools.tkv` | 8.098 |
| `stdlib_itertools_expr.tkv` | 9.424 |
| `stdlib_itertools_real.tkv` | 16.250 |
| `stdlib_json.tkv` | 33.931 |
| `stdlib_json_get.tkv` | 4.151 |
| `stdlib_math.tkv` | 17.318 |
| `stdlib_math_trig.tkv` | 913 |
| `stdlib_multiprocessing.tkv` | 1.199 |
| `stdlib_os.tkv` | 4.728 |
| `stdlib_path.tkv` | 17.655 |
| `stdlib_pathlib.tkv` | 3.295 |
| `stdlib_random.tkv` | 18.445 |
| `stdlib_re.tkv` | 8.397 |
| `stdlib_repeat.tkv` | 5.688 |
| `stdlib_shutil.tkv` | 1.329 |
| `stdlib_socket.tkv` | 865 |
| `stdlib_sqlite.tkv` | 11.590 |
| `stdlib_string_count.tkv` | 4.232 |
| `stdlib_string_zfill.tkv` | 4.964 |
| `stdlib_struct.tkv` | 1.665 |
| `stdlib_sys.tkv` | 2.641 |
| `stdlib_xml.tkv` | 1.122 |
| `stdlib_zipfile.tkv` | 3.533 |
| `str_accum.tkv` | 9.312 |
| `string_builtin.tkv` | 28.369 |
| `string_feature.tkv` | 10.282 |
| `string_format.tkv` | 7.807 |
| `string_join.tkv` | 7.712 |
| `string_methods_batch2.tkv` | 5.228 |
| `string_methods_batch3.tkv` | 7.717 |
| `string_methods_batch4.tkv` | 2.770 |
| `string_methods_batch5.tkv` | 8.686 |
| `string_percent_format.tkv` | 6.041 |
| `string_split.tkv` | 6.624 |
| `string_title.tkv` | 5.889 |
| `threading_feature.tkv` | 7.639 |
| `tkvstr.tkv` | 23.500 |
| `tms_db_manager.tkv` | 35.209 |
| `tms_gui_window.tkv` | 196.363 |
| `tms_web_launcher.tkv` | 26.391 |
| `tuple_type.tkv` | 31.677 |
| `typecheck.tkv` | 3.762 |
| `vector4_type.tkv` | 9.584 |
| `vector_block.tkv` | 14.088 |
| `win32_gui_window.tkv` | 1.512 |

