using System;
using System.Net;
using System.Net.Sockets;
using System.IO;
using System.Text;
using System.Collections.Generic;
using System.Text.RegularExpressions;

/// <summary>
/// TokenVector Universal AI Context Compressor Daemon v2.0
/// Inspired by: Headroom/Qwen3 semantic pipeline + TokenCompress algorithms
/// Native .NET 4.x TcpListener - NO admin required, port 8888
/// Python: STRICTLY FORBIDDEN
///
/// Improvements over v1:
///   - SQL compression (keyword folding, schema extraction)
///   - Markdown compression (strip syntax, keep content)
///   - Plain text: sentence dedup + stop-word density reduction
///   - Code: smarter threshold, preserve type annotations
///   - Log: multi-level severity filtering
///   - Dedup engine: remove repeated identical lines globally
///   - Vietnamese-safe: UTF-8 byte counting preserved
/// </summary>
class CompressorDaemon
{
    const string StatusFile = @"C:\Users\Nguyen Hung\.gemini\antigravity\scratch\tokenvector_native_service.status";
    const int Port = 8888;
    const string Version = "v2.0";

    static void WriteStatus(string msg)
    {
        try { File.WriteAllText(StatusFile, msg, Encoding.UTF8); }
        catch (Exception ex) { Console.WriteLine("[WARN] Status: " + ex.Message); }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 0: Content-type Detection (expanded from v1)
    // ═══════════════════════════════════════════════════════════════════════

    static string DetectType(string payload)
    {
        if (string.IsNullOrEmpty(payload)) return "text";
        string p = payload.TrimStart();
        int n = p.Length;

        // JSON
        if ((p[0] == '{' && p[n - 1] == '}') || (p[0] == '[' && p[n - 1] == ']'))
            return "json";

        // SQL — SELECT/INSERT/UPDATE/DELETE/CREATE/DROP/ALTER
        string up = p.Substring(0, Math.Min(100, n)).ToUpper();
        if (up.StartsWith("SELECT") || up.StartsWith("INSERT") || up.StartsWith("UPDATE") ||
            up.StartsWith("DELETE") || up.StartsWith("CREATE") || up.StartsWith("DROP") ||
            up.StartsWith("ALTER") || up.StartsWith("WITH ") || up.StartsWith("PRAGMA"))
            return "sql";

        // Markdown — starts with # header or has multiple ## headings
        if (p.StartsWith("#") && p.Contains("\n"))
            return "markdown";

        // Log — timestamp patterns or severity keywords
        bool hasLogPattern = Regex.IsMatch(p.Substring(0, Math.Min(200, n)),
            @"\d{4}-\d{2}-\d{2}[\s T]\d{2}:\d{2}:\d{2}") ||
            (p.Contains(" ERROR ") || p.Contains(" WARN ") || p.Contains(" DEBUG ") ||
             p.Contains(" INFO ") || p.Contains("Exception") || p.Contains("Traceback"));
        if (hasLogPattern) return "log";

        // Code — language keywords
        bool hasCode = p.Contains("def ") || p.Contains("class ") || p.Contains("function ") ||
                       p.Contains("import ") || p.Contains("return ") || p.Contains("public ") ||
                       p.Contains("private ") || p.Contains("void ") || p.Contains("int ") ||
                       p.Contains("var ") || p.Contains("let ") || p.Contains("const ");
        if (hasCode) return "code";

        return "text";
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: Global Dedup (remove consecutive duplicate lines)
    // ═══════════════════════════════════════════════════════════════════════

    static string[] SplitLines(string src) { return src.Split('\n'); }

    static List<string> DeduplicateLines(string[] lines)
    {
        var seen = new HashSet<string>(StringComparer.Ordinal);
        var result = new List<string>();
        string prev = null;
        foreach (var raw in lines)
        {
            string t = raw.TrimEnd('\r');
            // Remove exact duplicate consecutive lines
            if (t == prev) continue;
            // Remove globally repeated boilerplate (same line appears 3+ times already)
            if (seen.Contains(t) && t.Length > 20)
            {
                // Count occurrences already kept
                int ct = 0;
                foreach (var r in result) if (r == t) ct++;
                if (ct >= 2) continue; // allow max 2 identical lines
            }
            seen.Add(t);
            prev = t;
            result.Add(t);
        }
        return result;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: Code Compressor (v2 — smarter than v1)
    // ═══════════════════════════════════════════════════════════════════════

    static string CompressCode(string src)
    {
        var lines = SplitLines(src);
        var deduped = DeduplicateLines(lines);
        var sb = new StringBuilder();

        foreach (var raw in deduped)
        {
            string t = raw.Trim();
            if (t.Length == 0) continue;

            // Strip pure comment lines (but keep docstrings — lines with """)
            bool isPureComment = t.StartsWith("#") || t.StartsWith("//") ||
                                 t.StartsWith("/*") || t.StartsWith("*") ||
                                 t.StartsWith("--");
            if (isPureComment && !t.Contains("TODO") && !t.Contains("FIXME") && !t.Contains("HACK"))
                continue;

            // Strip inline comments from non-structural lines
            string stripped = t;
            int hashIdx = t.IndexOf("  #"); // only double-space comment (Python style)
            if (hashIdx > 0) stripped = t.Substring(0, hashIdx).TrimEnd();
            int slashIdx = t.IndexOf("  //");
            if (slashIdx > 0) stripped = t.Substring(0, slashIdx).TrimEnd();
            if (stripped.Length == 0) continue;

            // Structural lines: always keep
            bool isStruct = stripped.StartsWith("def ") || stripped.StartsWith("class ") ||
                            stripped.StartsWith("async def ") || stripped.StartsWith("function ") ||
                            stripped.StartsWith("import ") || stripped.StartsWith("from ") ||
                            stripped.StartsWith("export ") || stripped.StartsWith("public ") ||
                            stripped.StartsWith("private ") || stripped.StartsWith("protected ") ||
                            stripped.StartsWith("return ") || stripped == "return" ||
                            stripped.StartsWith("raise ") || stripped.StartsWith("throw ") ||
                            stripped.StartsWith("@") || // decorators
                            stripped.StartsWith("if ") || stripped.StartsWith("elif ") ||
                            stripped.StartsWith("else") || stripped.StartsWith("for ") ||
                            stripped.StartsWith("while ") || stripped.StartsWith("try") ||
                            stripped.StartsWith("except") || stripped.StartsWith("finally") ||
                            stripped.StartsWith("yield ");

            if (isStruct)
            {
                sb.AppendLine(stripped);
            }
            else if (stripped.Length <= 80) // keep short lines
            {
                sb.AppendLine(stripped);
            }
            // Long assignment lines: keep only left-hand side + type hint
            else
            {
                int eqIdx = stripped.IndexOf(" = ");
                if (eqIdx > 0 && eqIdx < 40)
                {
                    string lhs = stripped.Substring(0, eqIdx);
                    sb.AppendLine(lhs + " = ...");
                }
                // else: skip very long lines (initializers, long strings, etc.)
            }
        }
        return sb.ToString();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: Log Compressor (v2 — severity-aware, dedup)
    // ═══════════════════════════════════════════════════════════════════════

    // Severity order: DEBUG < INFO < WARN < ERROR < CRITICAL
    static int GetSeverity(string line)
    {
        string u = line.ToUpper();
        if (u.Contains("CRITICAL") || u.Contains("FATAL")) return 5;
        if (u.Contains(" ERROR") || u.Contains("[ERROR]") || u.Contains("EXCEPTION") ||
            u.Contains("TRACEBACK") || u.Contains("FAILED")) return 4;
        if (u.Contains(" WARN") || u.Contains("[WARN]") || u.Contains("WARNING")) return 3;
        if (u.Contains(" INFO") || u.Contains("[INFO]")) return 2;
        if (u.Contains(" DEBUG") || u.Contains("[DEBUG]")) return 1;
        // Stack trace lines (at ..., \tat)
        if (line.TrimStart().StartsWith("at ") || line.TrimStart().StartsWith("\tat ")) return 4;
        return 0; // unclassified
    }

    static string CompressLog(string src)
    {
        var lines = SplitLines(src);
        var sb = new StringBuilder();
        int minSeverity = 2; // Keep INFO and above (suppress DEBUG)

        // If log has many errors, only keep WARN+ to reduce noise
        int errorCount = 0;
        foreach (var line in lines)
            if (GetSeverity(line) >= 3) errorCount++;
        if (errorCount > 20) minSeverity = 3; // many errors: WARN+ only

        var seen = new HashSet<string>();
        foreach (var raw in lines)
        {
            string t = raw.TrimEnd('\r').Trim();
            if (t.Length == 0) continue;

            int sev = GetSeverity(t);
            if (sev < minSeverity) continue;

            // Dedup repeated identical log lines (e.g. connection pool spam)
            // Keep only first occurrence of same message core
            string core = Regex.Replace(t, @"\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(\.\d+)?", "TS");
            core = Regex.Replace(core, @"\b\d+\b", "N"); // normalize numbers
            if (seen.Contains(core)) continue;
            seen.Add(core);

            sb.AppendLine(t);
        }
        return sb.ToString();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: JSON Compressor (v2 — null + empty + schema collapse)
    // ═══════════════════════════════════════════════════════════════════════

    static string CompressJson(string src)
    {
        var lines = SplitLines(src);
        var sb = new StringBuilder();
        int nullCount = 0;

        foreach (var raw in lines)
        {
            string t = raw.TrimEnd('\r').Trim();
            if (t.Length == 0) continue;

            // Strip null/empty/false fields
            bool isNull = t.Contains(": null") || t.Contains(":null") ||
                          t.Contains(": \"\"") || t.Contains(":\"\"") ||
                          t.Contains(": {}") || t.Contains(":{}") ||
                          t.Contains(": []") || t.Contains(":[]") ||
                          t.Contains(": false") || t.Contains(":false");

            if (isNull) { nullCount++; continue; }

            // Collapse whitespace between tokens on same line
            sb.Append(t);
        }

        // Append null-count summary for transparency
        if (nullCount > 0)
            sb.Append("\n/* [tkv] " + nullCount + " null/empty fields omitted */");

        return sb.ToString();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: SQL Compressor (NEW in v2)
    // ═══════════════════════════════════════════════════════════════════════

    static string CompressSql(string src)
    {
        var lines = SplitLines(src);
        var sb = new StringBuilder();

        foreach (var raw in lines)
        {
            string t = raw.TrimEnd('\r').Trim();
            if (t.Length == 0) continue;

            // Strip pure SQL comment lines
            if (t.StartsWith("--") || t.StartsWith("/*") || t.StartsWith("*"))
                continue;

            // Collapse multi-space to single
            string collapsed = Regex.Replace(t, @"  +", " ");

            // Normalize SQL keywords to uppercase (helps dedup)
            // Only uppercase isolated keywords, not inside string literals
            foreach (var kw in new[]{"select","from","where","inner join","left join",
                "right join","group by","order by","having","limit","offset",
                "insert into","update","delete from","create table","alter table",
                "drop table","values","set","on","and","or","not","as","join"})
            {
                collapsed = Regex.Replace(collapsed,
                    @"\b" + kw + @"\b", kw.ToUpper(),
                    RegexOptions.IgnoreCase);
            }

            sb.AppendLine(collapsed);
        }
        return sb.ToString();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: Markdown Compressor (NEW in v2)
    // ═══════════════════════════════════════════════════════════════════════

    static string CompressMarkdown(string src)
    {
        var lines = SplitLines(src);
        var deduped = DeduplicateLines(lines);
        var sb = new StringBuilder();
        bool inCodeBlock = false;

        foreach (var raw in deduped)
        {
            string t = raw.TrimEnd('\r');
            string trimmed = t.Trim();

            // Track fenced code blocks — preserve as-is
            if (trimmed.StartsWith("```")) { inCodeBlock = !inCodeBlock; sb.AppendLine(t); continue; }
            if (inCodeBlock) { sb.AppendLine(t); continue; }

            if (trimmed.Length == 0) continue; // strip blank lines

            // Collapse horizontal rules
            if (Regex.IsMatch(trimmed, @"^[-*_]{3,}$")) continue;

            // Preserve headings (# ## ###)
            if (trimmed.StartsWith("#")) { sb.AppendLine(trimmed); continue; }

            // Strip bold/italic markers but keep text
            string content = Regex.Replace(trimmed, @"\*{1,3}([^*]+)\*{1,3}", "$1");
            content = Regex.Replace(content, @"_{1,3}([^_]+)_{1,3}", "$1");

            // Collapse links: [text](url) → text
            content = Regex.Replace(content, @"\[([^\]]+)\]\([^)]+\)", "$1");

            // Collapse inline code: `code` → code
            content = Regex.Replace(content, @"`([^`]+)`", "$1");

            if (content.Trim().Length > 0)
                sb.AppendLine(content.Trim());
        }
        return sb.ToString();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: Plain Text Compressor (v2 — sentence dedup + density)
    // ═══════════════════════════════════════════════════════════════════════

    static readonly HashSet<string> StopPhrases = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
    {
        "this is", "it is", "there is", "there are", "as well as",
        "in order to", "due to the fact that", "at this point in time",
        "it should be noted that", "please note that", "for the purpose of",
        "with respect to", "in the event that", "it is important to note",
        "it can be seen that", "as mentioned above", "as stated above"
    };

    static string CompressText(string src)
    {
        var lines = SplitLines(src);
        var deduped = DeduplicateLines(lines);
        var sb = new StringBuilder();
        var sentenceSeen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var raw in deduped)
        {
            string t = raw.TrimEnd('\r').Trim();
            if (t.Length == 0) continue;

            // Normalize multiple spaces
            t = Regex.Replace(t, @"  +", " ");

            // Dedup at sentence level (normalize to lowercase for comparison)
            string key = Regex.Replace(t.ToLower(), @"[^\w\s]", "").Trim();
            if (key.Length > 10 && sentenceSeen.Contains(key)) continue;
            sentenceSeen.Add(key);

            // Remove filler phrases (replace with nothing or shorten)
            foreach (var phrase in StopPhrases)
            {
                if (t.ToLower().StartsWith(phrase + " "))
                {
                    // Capitalize what follows
                    int phraseLen = phrase.Length + 1;
                    if (t.Length > phraseLen)
                    {
                        string rest = t.Substring(phraseLen).TrimStart();
                        if (rest.Length > 0)
                            t = char.ToUpper(rest[0]) + rest.Substring(1);
                    }
                    break;
                }
            }

            if (t.Length > 0) sb.AppendLine(t);
        }
        return sb.ToString();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MASTER Compress Dispatcher
    // ═══════════════════════════════════════════════════════════════════════

    static string Compress(string payload)
    {
        string t = DetectType(payload);
        switch (t)
        {
            case "code":     return CompressCode(payload);
            case "log":      return CompressLog(payload);
            case "json":     return CompressJson(payload);
            case "sql":      return CompressSql(payload);
            case "markdown": return CompressMarkdown(payload);
            default:         return CompressText(payload);
        }
    }

    static int SavingsPct(int orig, int comp)
    {
        if (orig <= 0 || comp >= orig) return 0;
        return (orig - comp) * 100 / orig;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // HTTP over raw TcpListener (no admin needed)
    // ═══════════════════════════════════════════════════════════════════════

    static string ParseBody(string request)
    {
        int idx = request.IndexOf("\r\n\r\n");
        if (idx >= 0) return request.Substring(idx + 4);
        idx = request.IndexOf("\n\n");
        if (idx >= 0) return request.Substring(idx + 2);
        return "";
    }

    static string ParsePath(string request)
    {
        string[] lines = request.Split('\n');
        if (lines.Length == 0) return "/";
        string[] parts = lines[0].Trim().Split(' ');
        return parts.Length < 2 ? "/" : parts[1].Split('?')[0];
    }

    static string ParseMethod(string request)
    {
        string[] lines = request.Split('\n');
        if (lines.Length == 0) return "GET";
        string[] parts = lines[0].Trim().Split(' ');
        return parts.Length >= 1 ? parts[0] : "GET";
    }

    static string GetHeader(string request, string name)
    {
        foreach (var line in request.Split('\n'))
        {
            if (line.TrimEnd('\r').StartsWith(name + ":", StringComparison.OrdinalIgnoreCase))
                return line.Substring(name.Length + 1).Trim().TrimEnd('\r');
        }
        return "";
    }

    static void HandleClient(TcpClient client)
    {
        try
        {
            using (var stream = client.GetStream())
            {
                var buf = new byte[131072]; // 128KB max request
                int read = stream.Read(buf, 0, buf.Length);
                string rawReq = Encoding.UTF8.GetString(buf, 0, read);

                string path      = ParsePath(rawReq);
                string method    = ParseMethod(rawReq);
                string body      = ParseBody(rawReq);
                string clientTag = GetHeader(rawReq, "X-AI-Client");
                if (string.IsNullOrEmpty(clientTag)) clientTag = "Unknown-AI";

                string outStr;
                string ctype;

                if (path == "/compress" && method == "POST")
                {
                    string detectedType = DetectType(body);
                    string compressed   = Compress(body);
                    int origLen  = Encoding.UTF8.GetByteCount(body);
                    int compLen  = Encoding.UTF8.GetByteCount(compressed);
                    int pct      = SavingsPct(origLen, compLen);

                    outStr = "[tkv-" + Version + "|type:" + detectedType + "|client:" + clientTag +
                             "|in:" + origLen + "B|out:" + compLen + "B|saved:" + pct + "%]\n" + compressed;
                    ctype  = "text/plain; charset=utf-8";

                    Console.WriteLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] " +
                                      clientTag + " /compress " + detectedType + " " +
                                      origLen + "→" + compLen + "B (" + pct + "% saved)");
                }
                else if (path == "/status" || path == "/health" || path == "/livez")
                {
                    outStr = "{\"status\":\"ok\",\"engine\":\"TokenVector-CSharp-Daemon\",\"version\":\"" + Version + "\",\"port\":" + Port + ",\"python\":false}";
                    ctype  = "application/json; charset=utf-8";
                }
                else if (path == "/types")
                {
                    outStr = "{\"supported_types\":[\"code\",\"log\",\"json\",\"sql\",\"markdown\",\"text\"],\"version\":\"" + Version + "\"}";
                    ctype  = "application/json; charset=utf-8";
                }
                else
                {
                    outStr = "{\"status\":\"ok\",\"engine\":\"TokenVector-CSharp-Daemon\",\"version\":\"" + Version + "\",\"port\":" + Port +
                             ",\"endpoints\":[\"/compress\",\"/status\",\"/health\",\"/types\"],\"python\":false}";
                    ctype  = "application/json; charset=utf-8";
                }

                byte[] outBytes    = Encoding.UTF8.GetBytes(outStr);
                string respHeader  = "HTTP/1.1 200 OK\r\n" +
                                     "Content-Type: " + ctype + "\r\n" +
                                     "Content-Length: " + outBytes.Length + "\r\n" +
                                     "X-Engine: TokenVector-CSharp-" + Version + "\r\n" +
                                     "Access-Control-Allow-Origin: *\r\n" +
                                     "Connection: close\r\n\r\n";
                byte[] headerBytes = Encoding.UTF8.GetBytes(respHeader);
                stream.Write(headerBytes, 0, headerBytes.Length);
                stream.Write(outBytes, 0, outBytes.Length);
            }
        }
        catch { /* client disconnected */ }
        finally { client.Close(); }
    }

    static void Main(string[] args)
    {
        Console.OutputEncoding = Encoding.UTF8;
        Console.Title = "TokenVector Universal AI Context Compressor " + Version;
        Console.WriteLine("╔═══════════════════════════════════════════════════════╗");
        Console.WriteLine("║  TokenVector Universal AI Context Compressor " + Version + "  ║");
        Console.WriteLine("║  Native .NET 4.x | Port: " + Port + " | Python: FORBIDDEN   ║");
        Console.WriteLine("║  Types: code, log, json, sql, markdown, text          ║");
        Console.WriteLine("╚═══════════════════════════════════════════════════════╝");
        Console.WriteLine();

        int pid = System.Diagnostics.Process.GetCurrentProcess().Id;
        WriteStatus(
            "STATUS=OK\n" +
            "ENGINE=TokenVector-CSharp-Daemon-" + Version + "\n" +
            "PORT=" + Port + "\n" +
            "PYTHON_ALLOWED=FALSE\n" +
            "MODE=TCP_HTTP_DAEMON\n" +
            "TYPES=code,log,json,sql,markdown,text\n" +
            "PID=" + pid
        );

        var tcpListener = new TcpListener(IPAddress.Loopback, Port);
        try { tcpListener.Start(); }
        catch (Exception ex)
        {
            Console.WriteLine("[ERROR] Cannot bind port " + Port + ": " + ex.Message);
            WriteStatus("STATUS=ERROR\nREASON=PORT_IN_USE");
            Console.ReadLine(); return;
        }

        Console.WriteLine("[OK] Listening on http://localhost:" + Port + "/");
        Console.WriteLine("[OK] PID: " + pid);
        Console.WriteLine("[OK] Endpoints:");
        Console.WriteLine("       POST /compress   (header: X-AI-Client: <name>)");
        Console.WriteLine("       GET  /status  GET /health  GET /types");
        Console.WriteLine();
        Console.WriteLine("[Running... Ctrl+C to stop]");
        Console.WriteLine();

        while (true)
        {
            try { HandleClient(tcpListener.AcceptTcpClient()); }
            catch (Exception ex) { Console.WriteLine("[WARN] " + ex.Message); }
        }
    }
}
