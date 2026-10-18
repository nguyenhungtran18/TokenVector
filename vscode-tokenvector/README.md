# TokenVector Language Support

<img src="logo.png" width="128" alt="TokenVector logo">

Language support for **TokenVector** (`.tkv`, `.tv`) — a Python-like, ahead-of-time compiler that emits .NET CIL and runs as a native Windows executable.

## Features

- **Syntax highlighting** for the full `.tkv` grammar: keywords, primitive and container type annotations (`"i32"`, `"list[f64]"`), strings, f-strings, numbers, decorators, dunder names and native builtins.
- **Smart editing**: auto-indent after `:` blocks, outdent on `elif` / `else` / `except` / `finally` / `case`, bracket and quote pairing, `#` line comments.
- **Snippets** for `def`, `class`, `record`, `if`, `for`, `while`, `try`, `with`, `print`, list comprehensions, typed variables, `__tkv_extern_assembly__` and `simd_gemm`.
- **Build and Run** commands with a dedicated output channel.

## Requirements

The build commands need the TokenVector compiler, `tkvc-tv.exe`. The extension looks for it in this order:

1. The `tokenvector.compilerPath` setting.
2. `<workspace>/Release/dist/tkvc-tv.exe`.
3. `<workspace>/dist/tkvc-tv.exe`.
4. `tkvc-tv.exe` on your `PATH`.

Syntax highlighting and snippets work without the compiler.

## Usage

Open any `.tkv` file and use the Command Palette (`Ctrl+Shift+P`):

- `TokenVector: Build Current File` — compiles `file.tkv` to `file.exe` next to the source.
- `TokenVector: Build and Run Current File` — compiles, then runs the executable in an integrated terminal.

Both commands are also available in the editor context menu.

```tkv
def main() -> "i32":
    print("hello from TokenVector")
    return 0
```

## Extension Settings

| Setting | Default | Description |
| --- | --- | --- |
| `tokenvector.compilerPath` | `""` | Explicit path to `tkvc-tv.exe`. |
| `tokenvector.extraArgs` | `""` | Extra arguments appended to the compiler command. |
| `tokenvector.saveBeforeBuild` | `true` | Save the file before building. |

## Links

- [Repository](https://github.com/nguyenhungtran18/TokenVector)
- [Documentation](https://nguyenhungtran18.github.io/TokenVector/)
- [Issue tracker](https://github.com/nguyenhungtran18/TokenVector/issues)

## License

MIT — Copyright (c) 2026 Nguyen Hung Tran.
