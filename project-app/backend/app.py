import os
import json
import requests
import mimetypes

from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

from PyPDF2 import PdfReader
from docx import Document

# =====================================================
# CONFIGURAZIONE INIZIALE
# =====================================================

# Carica variabili d'ambiente dal file .env
load_dotenv()

# Inizializza Flask
app = Flask(__name__)

# Abilita CORS (per SvelteKit o altri frontend)
CORS(app)

# Configurazione Ollama
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3")

# =====================================================
# FUNZIONI DI SUPPORTO
# =====================================================

def normalize_text(text: str, max_chars: int = 12000) -> str:
    """
    Pulisce e limita il testo da inviare a Ollama
    """
    text = text.strip()
    return text[:max_chars]


def extract_text_from_txt(file) -> str:
    """
    Estrae testo da file di testo semplice
    """
    return file.read().decode("utf-8", errors="ignore")


def extract_text_from_pdf(file) -> str:
    """
    Estrae testo da PDF
    """
    reader = PdfReader(file)
    pages = []
    for page in reader.pages:
        pages.append(page.extract_text() or "")
    return "\n".join(pages)


def extract_text_from_docx(file) -> str:
    """
    Estrae testo da file Word (.docx)
    """
    doc = Document(file)
    return "\n".join(p.text for p in doc.paragraphs)


def extract_text_from_any(file) -> str:
    """
    Determina il tipo di file e usa l'estrattore corretto
    """
    filename = file.filename.lower()

    if filename.endswith(".pdf"):
        return extract_text_from_pdf(file)
    elif filename.endswith(".docx"):
        return extract_text_from_docx(file)
    else:
        return extract_text_from_txt(file)


def call_ollama(text: str) -> dict:
    """
    Chiama Ollama e forza una risposta JSON strutturata,
    con particolare attenzione agli importi economici
    """

    prompt = f"""
    Analizza il seguente documento.

    Estrai SOLO se presenti le seguenti informazioni:

    - tipo_documento (fattura, contratto, lettera, ricevuta, altro)
    - data_documento
    - data_scadenza
    - soggetti_coinvolti (persone o aziende)
    - descrizione_breve

    IMPORTI:
    Se nel documento sono presenti valori economici, restituisci
    un oggetto JSON strutturato nel seguente formato:

    "importi": {{
    "totale": numero o null,
    "imponibile": numero o null,
    "iva": numero o null,
    "altri": [
        {{
        "descrizione": stringa,
        "valore": numero,
        "valuta": stringa
        }}
    ]
    }}

    - Usa SOLO numeri (niente simboli € nei valori)
    - Se un campo non è presente usa null
    - NON inventare valori

    Rispondi ESCLUSIVAMENTE con JSON valido.
    Nessun testo extra.

    Documento:
    ```
    {text}
    ```
    """

    payload = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "format": "json",
        "stream": False
    }

    response = requests.post(
        f"{OLLAMA_BASE_URL}/api/generate",
        json=payload,
        timeout=120
    )

    response.raise_for_status()

    data = response.json()

    # Ollama restituisce JSON come stringa
    return json.loads(data.get("response", "{}"))


# =====================================================
# API PRINCIPALE
# =====================================================

@app.route("/api/analyze", methods=["POST"])
def analyze_file():
    """
    Endpoint API:
    POST /api/analyze
    Content-Type: multipart/form-data
    Campo: file
    """

    # 1. Verifica presenza file
    file = request.files.get("file")
    if not file:
        return jsonify({"error": "File mancante"}), 400

    # 2. Estrai testo dal file
    try:
        raw_text = extract_text_from_any(file)
    except Exception as e:
        return jsonify({"error": f"Errore estrazione testo: {str(e)}"}), 500

    # 3. Normalizza testo
    text = normalize_text(raw_text)

    if not text:
        return jsonify({"error": "Testo vuoto o non leggibile"}), 400

    # 4. Invia a Ollama
    try:
        extracted_data = call_ollama(text)
    except Exception as e:
        return jsonify({"error": f"Errore Ollama: {str(e)}"}), 500

    # 5. Risposta finale
    return jsonify({
        "filename": file.filename,
        "extracted_data": extracted_data
    })


# =====================================================
# AVVIO SERVER
# =====================================================

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)
