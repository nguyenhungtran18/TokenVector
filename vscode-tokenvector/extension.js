"use strict";

const vscode = require("vscode");
const cp = require("child_process");
const fs = require("fs");
const path = require("path");

let output;

function compilerCandidates(document) {
  const candidates = [];
  const cfg = vscode.workspace.getConfiguration("tokenvector");
  const configured = (cfg.get("compilerPath") || "").trim();
  if (configured) {
    candidates.push(configured);
  }

  const folders = vscode.workspace.workspaceFolders || [];
  for (const folder of folders) {
    const root = folder.uri.fsPath;
    candidates.push(
      path.join(root, "Release", "dist", "tkvc-tv.exe"),
      path.join(root, "dist", "tkvc-tv.exe"),
      path.join(root, "tkvc-tv.exe")
    );
  }

  if (document && document.uri.scheme === "file") {
    const docDir = path.dirname(document.uri.fsPath);
    candidates.push(
      path.join(docDir, "tkvc-tv.exe"),
      path.join(docDir, "..", "dist", "tkvc-tv.exe")
    );
  }

  candidates.push("tkvc-tv.exe");
  return candidates;
}

function resolveCompiler(document) {
  for (const candidate of compilerCandidates(document)) {
    if (!candidate) {
      continue;
    }
    if (candidate === "tkvc-tv.exe") {
      return candidate;
    }
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return "tkvc-tv.exe";
}

function outputPathFor(document) {
  const file = document.uri.fsPath;
  const parsed = path.parse(file);
  if (parsed.ext.toLowerCase() === ".tkv") {
    return path.join(parsed.dir, parsed.name + ".exe");
  }
  return file + ".exe";
}

function parseExtraArgs(raw) {
  if (!raw) {
    return [];
  }
  const re = /"([^"]*)"|'([^']*)'|(\S+)/g;
  const out = [];
  let match;
  while ((match = re.exec(raw)) !== null) {
    out.push(match[1] !== undefined ? match[1] : match[2] !== undefined ? match[2] : match[3]);
  }
  return out;
}

function getOutput() {
  if (!output) {
    output = vscode.window.createOutputChannel("TokenVector");
  }
  return output;
}

function runCompiler(compiler, args, cwd) {
  return new Promise((resolve) => {
    const channel = getOutput();
    channel.show(true);
    const printable = [compiler, ...args]
      .map((arg) => (/\s/.test(arg) ? `"${arg}"` : arg))
      .join(" ");
    channel.appendLine(`> ${printable}`);

    let child;
    try {
      child = cp.spawn(compiler, args, { cwd, windowsHide: true });
    } catch (err) {
      channel.appendLine(String(err));
      resolve(1);
      return;
    }

    child.stdout.on("data", (data) => channel.append(data.toString()));
    child.stderr.on("data", (data) => channel.append(data.toString()));
    child.on("error", (err) => {
      channel.appendLine(`[spawn error] ${err.message}`);
      resolve(1);
    });
    child.on("close", (code) => {
      channel.appendLine(`[exit ${code === null ? "?" : code}]`);
      resolve(code === null ? 1 : code);
    });
  });
}

async function activeTkvDocument() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showErrorMessage("TokenVector: no active editor.");
    return undefined;
  }

  const document = editor.document;
  const isTkv =
    document.languageId === "tokenvector" ||
    document.fileName.toLowerCase().endsWith(".tkv");
  if (!isTkv) {
    vscode.window.showErrorMessage("TokenVector: the active file is not a .tkv file.");
    return undefined;
  }

  if (document.isUntitled || document.uri.scheme !== "file") {
    vscode.window.showErrorMessage("TokenVector: save the file to disk before building.");
    return undefined;
  }

  return { editor, document };
}

async function build(runAfter) {
  const active = await activeTkvDocument();
  if (!active) {
    return;
  }

  const { document } = active;
  const cfg = vscode.workspace.getConfiguration("tokenvector");

  if (cfg.get("saveBeforeBuild") && document.isDirty) {
    const saved = await document.save();
    if (!saved) {
      vscode.window.showErrorMessage("TokenVector: could not save the file.");
      return;
    }
  }

  const compiler = resolveCompiler(document);
  const source = document.uri.fsPath;
  const target = outputPathFor(document);
  const args = [source, target, ...parseExtraArgs(cfg.get("extraArgs") || "")];

  const code = await vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Notification,
      title: "TokenVector: building..."
    },
    () => runCompiler(compiler, args, path.dirname(source))
  );

  if (code !== 0) {
    vscode.window.showErrorMessage(
      "TokenVector: build failed. See the TokenVector output panel."
    );
    return;
  }

  if (!fs.existsSync(target)) {
    vscode.window.showErrorMessage(
      `TokenVector: build exited 0 but no output was produced at ${target}.`
    );
    return;
  }

  if (runAfter) {
    const terminal = vscode.window.createTerminal({
      name: "TokenVector",
      cwd: path.dirname(target)
    });
    terminal.show();
    terminal.sendText(`"${target}"`, true);
  } else {
    vscode.window.showInformationMessage(
      `TokenVector: built ${path.basename(target)}.`
    );
  }
}

function activate(context) {
  context.subscriptions.push(getOutput());
  context.subscriptions.push(
    vscode.commands.registerCommand("tokenvector.build", () => build(false))
  );
  context.subscriptions.push(
    vscode.commands.registerCommand("tokenvector.run", () => build(true))
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
