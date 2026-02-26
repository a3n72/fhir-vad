#!/usr/bin/env python3
"""
依 ig-config.js 的 IG 清單自動組出並執行 validator 啟動指令。
用法：
  python start_validator.py              # 預設 port 8080，直接啟動
  python start_validator.py --dry-run    # 只印出指令不執行
  python start_validator.py --port 8099
  python start_validator.py -tx na       # 關閉術語驗證
  python start_validator.py --txCache ./fhir-tx-cache
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional


def read_ig_packages(config_path: Path) -> list[str]:
    """從 ig-config.js 讀取所有 igPackage 值（依出現順序）。"""
    text = config_path.read_text(encoding="utf-8")
    # 匹配 igPackage: "xxx" 或 igPackage: 'xxx'
    pattern = re.compile(r'igPackage:\s*["\']([^"\']+)["\']', re.IGNORECASE)
    return pattern.findall(text)


def build_command(
    jar_path: Path,
    port: int,
    ig_packages: list[str],
    tx: Optional[str] = None,
    tx_cache: Optional[str] = None,
    java_bin: str = "java",
) -> list[str]:
    cmd = [
        java_bin,
        "-jar",
        str(jar_path),
        "server",
        str(port),
    ]
    for pkg in ig_packages:
        cmd.extend(["-ig", pkg])
    if tx:
        cmd.extend(["-tx", tx])
    if tx_cache:
        cmd.extend(["-txCache", tx_cache])
    return cmd


def main() -> int:
    script_dir = Path(__file__).resolve().parent
    config_path = script_dir / "ig-config.js"
    jar_path = script_dir / "validator_cli.jar"

    if not config_path.exists():
        print(f"找不到設定檔: {config_path}", file=sys.stderr)
        return 1
    if not jar_path.exists():
        print(f"找不到 validator: {jar_path}", file=sys.stderr)
        return 1

    parser = argparse.ArgumentParser(
        description="依 ig-config.js 自動啟動 FHIR Validator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--port", "-p",
        type=int,
        default=8080,
        help="Validator 監聽埠 (預設 8080)",
    )
    parser.add_argument(
        "--dry-run", "-n",
        action="store_true",
        help="只印出指令，不執行",
    )
    parser.add_argument(
        "-tx",
        metavar="URL_OR_NA",
        default=None,
        help="術語伺服器，例如 https://tx.fhir.org/r4 或 na（關閉）",
    )
    parser.add_argument(
        "--txCache",
        metavar="DIR",
        default=None,
        help="術語快取目錄，例如 ./fhir-tx-cache",
    )
    parser.add_argument(
        "--java",
        default="java",
        help="Java 執行檔路徑 (預設 java)",
    )
    args = parser.parse_args()

    ig_packages = read_ig_packages(config_path)
    if not ig_packages:
        print("ig-config.js 中未找到任何 igPackage", file=sys.stderr)
        return 1

    cmd = build_command(
        jar_path=jar_path,
        port=args.port,
        ig_packages=ig_packages,
        tx=args.tx,
        tx_cache=args.txCache,
        java_bin=args.java,
    )

    one_line = " ".join(cmd)
    print("IG 清單:", ", ".join(ig_packages))
    print("指令:", one_line)

    if args.dry_run:
        return 0

    print("啟動 Validator… (Ctrl+C 結束)")
    try:
        subprocess.run(cmd, cwd=script_dir)
    except KeyboardInterrupt:
        print("\n已結束")
    except FileNotFoundError as e:
        print(f"執行失敗: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
