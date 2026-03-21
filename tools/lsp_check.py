"""
Godot GDScript LSP 経由でコンパイルエラーを取得するスクリプト。
Godotエディタが起動中（ポート6005でLSPが動いている状態）で実行する。

使い方:
    python tools/lsp_check.py
"""

import socket
import json
import os
import glob
import time

LSP_HOST = "127.0.0.1"
LSP_PORT = 6005
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def to_lsp_message(obj: dict) -> bytes:
    body = json.dumps(obj, ensure_ascii=False)
    header = f"Content-Length: {len(body.encode())}\r\n\r\n"
    return (header + body).encode()


def read_lsp_message(sock: socket.socket) -> dict | None:
    # ヘッダーを読む
    header = b""
    while b"\r\n\r\n" not in header:
        chunk = sock.recv(1)
        if not chunk:
            return None
        header += chunk

    content_length = 0
    for line in header.split(b"\r\n"):
        if line.lower().startswith(b"content-length:"):
            content_length = int(line.split(b":")[1].strip())

    body = b""
    while len(body) < content_length:
        body += sock.recv(content_length - len(body))

    return json.loads(body.decode())


def path_to_uri(path: str) -> str:
    path = path.replace("\\", "/")
    if not path.startswith("/"):
        path = "/" + path
    return "file://" + path


def collect_gd_files(root: str) -> list[str]:
    result = []
    for path in glob.glob(os.path.join(root, "**", "*.gd"), recursive=True):
        # addons と tools は除外
        rel = os.path.relpath(path, root)
        if rel.startswith("addons") or rel.startswith("."):
            continue
        result.append(path)
    return result


def main():
    print(f"Godot LSP に接続中 ({LSP_HOST}:{LSP_PORT})...")
    try:
        sock = socket.create_connection((LSP_HOST, LSP_PORT), timeout=5)
    except (ConnectionRefusedError, TimeoutError):
        print("接続失敗。Godotエディタが起動中か確認してください。")
        return

    sock.settimeout(2.0)
    print("接続成功。\n")

    msg_id = 0

    def send(obj):
        sock.sendall(to_lsp_message(obj))

    # initialize
    msg_id += 1
    send({
        "jsonrpc": "2.0", "id": msg_id, "method": "initialize",
        "params": {
            "processId": os.getpid(),
            "rootUri": path_to_uri(PROJECT_ROOT),
            "capabilities": {
                "textDocument": {
                    "publishDiagnostics": {"relatedInformation": True}
                }
            }
        }
    })

    # initialized 通知
    send({"jsonrpc": "2.0", "method": "initialized", "params": {}})

    # GDファイルを開いてdiagnosticsを受け取る
    gd_files = collect_gd_files(PROJECT_ROOT)
    print(f"{len(gd_files)} 個の .gd ファイルをチェックします...\n")

    for path in gd_files:
        try:
            with open(path, encoding="utf-8") as f:
                text = f.read()
        except Exception:
            continue

        uri = path_to_uri(path)
        send({
            "jsonrpc": "2.0", "method": "textDocument/didOpen",
            "params": {
                "textDocument": {
                    "uri": uri, "languageId": "gdscript",
                    "version": 1, "text": text
                }
            }
        })

    # diagnostics を受け取る
    diagnostics: dict[str, list] = {}
    deadline = time.time() + 5.0

    while time.time() < deadline:
        try:
            msg = read_lsp_message(sock)
        except (TimeoutError, socket.timeout):
            break
        if msg is None:
            break

        method = msg.get("method", "")
        if method == "textDocument/publishDiagnostics":
            params = msg.get("params", {})
            uri = params.get("uri", "")
            diags = params.get("diagnostics", [])
            if diags:
                rel_path = uri.replace("file:///", "").replace("/", os.sep)
                diagnostics[rel_path] = diags

    sock.close()

    # 結果表示
    if not diagnostics:
        print("エラー・警告は見つかりませんでした。")
        return

    error_count = 0
    warning_count = 0

    for path, diags in sorted(diagnostics.items()):
        for d in diags:
            severity = d.get("severity", 1)
            line = d.get("range", {}).get("start", {}).get("line", 0) + 1
            col = d.get("range", {}).get("start", {}).get("character", 0) + 1
            message = d.get("message", "")
            label = "ERROR  " if severity == 1 else "WARNING"
            if severity == 1:
                error_count += 1
            else:
                warning_count += 1
            print(f"[{label}] {path}:{line}:{col}")
            print(f"         {message}")

    print(f"\n合計: エラー {error_count} 件 / 警告 {warning_count} 件")


if __name__ == "__main__":
    main()
