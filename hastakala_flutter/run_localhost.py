import subprocess
import sys
import time
import socket
import argparse
import webbrowser
from pathlib import Path

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

def main():
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')

    parser = argparse.ArgumentParser(description="Hastakala Local Host Launcher")
    parser.add_argument("--web-port", type=int, default=3000, help="Web UI port (e.g. 3000 or 3001)")
    parser.add_argument("--api-port", type=int, default=8000, help="Backend API port (e.g. 8000 or 8001)")
    parser.add_argument("--rebuild", action="store_true", help="Force rebuild Flutter Web")
    args = parser.parse_args()

    local_ip = get_local_ip()
    print("=" * 65)
    print(f"🚀 Hastakala Local Host Instance (Web: {args.web_port} | API: {args.api_port})")
    print("=" * 65)

    web_proc = None

    # 1. Start FastAPI Backend Server listening on 0.0.0.0:API_PORT
    print(f"\n[1/2] Starting FastAPI AI Backend on 0.0.0.0:{args.api_port} ...")
    backend_proc = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "hastakala_backend.main:app", "--host", "0.0.0.0", "--port", str(args.api_port)],
        cwd=str(Path(__file__).parent)
    )

    time.sleep(2)
    print("✅ Backend API running on:")
    print(f"   • PC Localhost:  http://localhost:{args.api_port}")
    print(f"   • Phone (Wi-Fi): http://{local_ip}:{args.api_port}")
    print(f"   • Swagger Docs:  http://{local_ip}:{args.api_port}/docs")

    # 2. Build Flutter Web if not built or --rebuild passed
    web_dir = Path(__file__).parent / "build" / "web"
    if args.rebuild or not web_dir.exists():
        print("\n🔨 Building Flutter Web output...")
        subprocess.run(["flutter", "build", "web"], cwd=str(Path(__file__).parent))

    if web_dir.exists():
        print(f"\n[2/2] Serving Hastakala Web UI on 0.0.0.0:{args.web_port} ...")
        web_proc = subprocess.Popen(
            [sys.executable, "-m", "http.server", str(args.web_port), "--bind", "0.0.0.0", "--directory", str(web_dir)]
        )
        print(f"✅ Flutter Web UI running on http://localhost:{args.web_port}")
        print(f"📱 Phone Link: http://{local_ip}:{args.web_port}\n")

    print("🎉 Server Instance is live!")
    print(" Opening browser at http://localhost:3000 ...")
    webbrowser.open(f"http://localhost:{args.web_port}")

    print(" Press Ctrl+C to stop.\n")

    try:
        backend_proc.wait()
    except KeyboardInterrupt:
        print("\nStopping servers...")
    finally:
        if backend_proc and backend_proc.poll() is None:
            backend_proc.terminate()
        if web_proc and web_proc.poll() is None:
            web_proc.terminate()

if __name__ == "__main__":
    main()
