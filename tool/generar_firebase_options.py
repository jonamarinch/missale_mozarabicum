"""Genera lib/firebase_options.dart a partir del .env (Android e iOS) y de la configuración web de Firebase.

El archivo generado no se sube a Git (.gitignore). Para regenerarlo:
  firebase apps:sdkconfig WEB <id-app-web> --project missalemozarabicum --out sdkweb.json
  py tool/generar_firebase_options.py sdkweb.json
"""
import json
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent


def leer_env():
    valores = {}
    for linea in (RAIZ / ".env").read_text(encoding="utf-8").splitlines():
        linea = linea.strip()
        if linea and not linea.startswith("#") and "=" in linea:
            clave, valor = linea.split("=", 1)
            valores[clave.strip()] = valor.strip().strip('"')
    return valores


def opciones(nombre, campos):
    cuerpo = "\n".join(f"    {k}: '{v}'," for k, v in campos.items() if v)
    return f"  static const FirebaseOptions {nombre} = FirebaseOptions(\n{cuerpo}\n  );\n"


def main():
    env = leer_env()
    web = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    movil = lambda p: {
        "apiKey": env[f"API_KEY_{p}"], "appId": env[f"APP_ID_{p}"],
        "messagingSenderId": env[f"SENDER_ID_{p}"], "projectId": env[f"PROJECT_ID_{p}"],
    }
    salida = (
        "// Generado por tool/generar_firebase_options.py. No se sube a Git.\n"
        "import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;\n"
        "import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;\n\n"
        "class DefaultFirebaseOptions {\n"
        "  static FirebaseOptions get currentPlatform {\n"
        "    if (kIsWeb) return web;\n"
        "    return defaultTargetPlatform == TargetPlatform.iOS ? ios : android;\n"
        "  }\n\n"
        + opciones("android", movil("ANDROID")) + "\n"
        + opciones("ios", movil("IOS")) + "\n"
        + opciones("web", {k: web.get(k) for k in ("apiKey", "appId", "messagingSenderId", "projectId", "authDomain", "storageBucket", "measurementId")})
        + "}\n"
    )
    (RAIZ / "lib" / "firebase_options.dart").write_text(salida, encoding="utf-8")
    print("Generado lib/firebase_options.dart")


if __name__ == "__main__":
    main()
