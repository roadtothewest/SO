#!/usr/bin/env python3
import http.server
import socketserver
import json
import csv
import sys
import getopt
import datetime
import statistics

CSV_FILE = None
PORT = None
DATA = []


# --- Cargar CSV ---
def load_csv(path):
    global DATA
    try:
        with open(path, newline='', encoding="utf-8") as f:
            reader = csv.DictReader(f)
            DATA = [row for row in reader]
        print(f"[{datetime.datetime.now()}] CSV cargado: {path}, {len(DATA)} registros")
    except Exception as e:
        print(f"Error cargando CSV: {e}")
        sys.exit(1)


# --- Calcular estadísticas ---
def calc_stats(campo):
    try:
        valores = [float(row[campo]) for row in DATA if row[campo].strip().isdigit()]
        if not valores:
            return {}
        return {
            "promedio": statistics.mean(valores),
            "media": statistics.median(valores),
            "sd": statistics.pstdev(valores),
            "min": min(valores),
            "max": max(valores)
        }
    except Exception as e:
        return {"error": str(e)}


def transmision_stats():
    mec = sum(1 for row in DATA if row.get("transmision", "").lower() == "mecanica")
    auto = sum(1 for row in DATA if row.get("transmision", "").lower() == "automatica")
    return {"mecanica": mec, "automatica": auto}


# --- Request Handler ---
class MyHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        print(f"[{datetime.datetime.now()}] host {self.client_address[0]} \"GET {self.path}\"")

        if self.path == "/permisos_stats":
            resp = calc_stats("permisos")
        elif self.path == "/tasacion_stats":
            resp = calc_stats("tasacion")
        elif self.path == "/transmision":
            resp = transmision_stats()
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not Found")
            return

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(resp, indent=2).encode("utf-8"))


# --- Main ---
def main(argv):
    global CSV_FILE, PORT
    csv_path = None
    port = None

    try:
        opts, _ = getopt.getopt(argv, "c:p:", ["csv=", "port="])
    except getopt.GetoptError:
        print("Uso: weblib2019.py --csv archivo --port puerto")
        sys.exit(2)

    for opt, arg in opts:
        if opt in ("-c", "--csv"):
            csv_path = arg
        elif opt in ("-p", "--port"):
            port = int(arg)

    if not csv_path or not port:
        print("Uso: weblib2019.py --csv archivo --port puerto")
        sys.exit(2)

    CSV_FILE, PORT = csv_path, port
    load_csv(CSV_FILE)

    with socketserver.TCPServer(("", PORT), MyHandler) as httpd:
        print(f"[{datetime.datetime.now()}] Se inicia microservicio en puerto {PORT}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServidor web terminado")
            httpd.shutdown()


if __name__ == "__main__":
    main(sys.argv[1:])
