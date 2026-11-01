# Fully LLM-generated
"""
Unique nginx visitors exporter.

nginx streams one JSON line per request over syslog (udp, loopback), and this
exporter keys each request by visitor = (ip or ipv6 /64) + user-agent, then
serves prometheus metrics:

  nginx_visits_total{vhost,kind}  visits (visitor unseen for --session seconds), persisted across restarts
  nginx_visitors{vhost,kind}      unique visitors seen in the last --window seconds

kind is "bot" or "human", guessed from the user-agent.
Non global ips (loopback, nebula, vpns, lan) and the blackbox exporter probes
coming from --blackbox-host addresses are ignored.
"""

import argparse
import ipaddress
import json
import os
import re
import signal
import socket
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

BOT_UA = re.compile(
    r"bot|crawl|spider|slurp|scan|curl|wget|python|go-http|java/|okhttp|libwww|"
    r"httpclient|headless|zgrab|masscan|nmap|nuclei|feed|preview|monitor|uptime",
    re.IGNORECASE,
)
BLACKBOX_UA = "Blackbox Exporter"
# server names that only drop unknown hosts (444) or serve internal endpoints
IGNORED_VHOSTS = {"", "_", "localhost"}


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--syslog-port", type=int, required=True)
    parser.add_argument("--metrics-port", type=int, required=True)
    parser.add_argument("--metrics-addr", default="0.0.0.0")
    parser.add_argument("--state-file", required=True)
    parser.add_argument("--session", type=int, default=1800)
    parser.add_argument("--window", type=int, default=60)
    parser.add_argument("--blackbox-host", action="append", default=[])
    return parser.parse_args()


class Visitors:
    def __init__(self, session, window, state_file):
        self.session = session
        self.window = window
        self.state_file = state_file
        self.lock = threading.Lock()
        # (vhost, kind, visitor) -> last seen timestamp
        self.last_seen = {}
        # (vhost, kind) -> visits
        self.visits = {}
        self.load()

    def load(self):
        try:
            with open(self.state_file) as f:
                for entry in json.load(f):
                    self.visits[(entry["vhost"], entry["kind"])] = int(entry["visits"])
        except (OSError, ValueError, KeyError, TypeError) as e:
            print(f"starting with empty state: {e}", file=sys.stderr)

    def save(self):
        with self.lock:
            state = [{"vhost": v, "kind": k, "visits": n} for (v, k), n in self.visits.items()]
        tmp = self.state_file + ".tmp"
        with open(tmp, "w") as f:
            json.dump(state, f)
        os.replace(tmp, self.state_file)

    def record(self, vhost, kind, visitor, now):
        key = (vhost, kind, visitor)
        with self.lock:
            previous = self.last_seen.get(key)
            if previous is None or now - previous > self.session:
                self.visits[(vhost, kind)] = self.visits.get((vhost, kind), 0) + 1
            self.last_seen[key] = now

    def snapshot(self, now):
        with self.lock:
            self.last_seen = {k: t for k, t in self.last_seen.items() if now - t <= self.session}
            active = {labels: 0 for labels in self.visits}
            for (vhost, kind, _), seen in self.last_seen.items():
                if now - seen <= self.window:
                    active[(vhost, kind)] += 1
            return dict(self.visits), active


class BlackboxAddresses:
    def __init__(self, hosts):
        self.hosts = hosts
        self.addresses = frozenset()

    def refresh(self):
        addresses = set()
        for host in self.hosts:
            try:
                addresses.update(info[4][0] for info in socket.getaddrinfo(host, None))
            except OSError as e:
                print(f"failed to resolve {host}: {e}", file=sys.stderr)
        # keep the previous addresses if dns is down
        if addresses:
            self.addresses = frozenset(addresses)


def visitor_key(ip, ua):
    # ipv6 privacy extensions rotate the host part, so a visitor is its /64
    if ip.version == 6:
        ip = ipaddress.ip_network(f"{ip}/64", strict=False)
    return f"{ip}|{ua}"


def listen(args, visitors, blackbox):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("127.0.0.1", args.syslog_port))
    while True:
        data = sock.recv(65535).decode("utf-8", errors="replace")
        try:
            # "<pri>timestamp tag: {json}"
            entry = json.loads(data[data.index("{") :])
            vhost, ua = entry["vhost"], entry["ua"]
            ip = ipaddress.ip_address(entry["ip"])
        except (ValueError, KeyError) as e:
            print(f"skipping malformed line: {e}", file=sys.stderr)
            continue

        if vhost in IGNORED_VHOSTS or not ip.is_global:
            continue
        if ua.startswith(BLACKBOX_UA) and str(ip) in blackbox.addresses:
            continue

        kind = "bot" if not ua or BOT_UA.search(ua) else "human"
        visitors.record(vhost, kind, visitor_key(ip, ua), time.time())


def escape(value):
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def render(visitors):
    visits, active = visitors.snapshot(time.time())
    lines = [
        f"# HELP nginx_visits_total Visits (ip + user-agent unseen for {visitors.session}s).",
        "# TYPE nginx_visits_total counter",
    ]
    lines += [f'nginx_visits_total{{vhost="{escape(v)}",kind="{k}"}} {n}' for (v, k), n in sorted(visits.items())]
    lines += [
        f"# HELP nginx_visitors Unique visitors (ip + user-agent) in the last {visitors.window}s.",
        "# TYPE nginx_visitors gauge",
    ]
    lines += [f'nginx_visitors{{vhost="{escape(v)}",kind="{k}"}} {n}' for (v, k), n in sorted(active.items())]
    return ("\n".join(lines) + "\n").encode()


def every(seconds, fn):
    def loop():
        while True:
            try:
                fn()
            except Exception as e:
                print(f"{fn.__name__} failed: {e}", file=sys.stderr)
            time.sleep(seconds)

    threading.Thread(target=loop, daemon=True).start()


def main():
    args = parse_args()
    visitors = Visitors(args.session, args.window, args.state_file)
    blackbox = BlackboxAddresses(args.blackbox_host)

    every(300, blackbox.refresh)
    every(60, visitors.save)
    threading.Thread(target=listen, args=(args, visitors, blackbox), daemon=True).start()

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path != "/metrics":
                self.send_error(404)
                return
            body = render(visitors)
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; version=0.0.4")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *_):
            pass

    def stop(*_):
        visitors.save()
        sys.exit(0)

    signal.signal(signal.SIGTERM, stop)
    ThreadingHTTPServer((args.metrics_addr, args.metrics_port), Handler).serve_forever()


if __name__ == "__main__":
    main()
