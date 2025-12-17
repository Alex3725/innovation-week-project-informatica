
from flask import Flask, request, jsonify
import os
import ollama
from werkzeug.utils import secure_filename
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# Configuration for file uploads
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/extract', methods=['POST'])
def extract_features():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        if not os.path.exists(UPLOAD_FOLDER):
            os.makedirs(UPLOAD_FOLDER)
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(file_path)

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            return jsonify({"error": f"Error reading file: {e}"}), 500

        prompt = f"""
        Extract the following features from the text below:
        - date
        - name
        - file-type

        Text: {content}

        Provide the output in JSON format.
        """

        try:
            client = ollama.Client(host=os.getenv("OLLAMA_API_URL"))
            response = client.chat(model='llama2', messages=[
                {
                    'role': 'user',
                    'content': prompt,
                },
            ])
            
            # Assuming the model returns a JSON string in the content
            extracted_data = response['message']['content']
            
            return jsonify({"extracted_features": extracted_data}), 200
        except Exception as e:
            return jsonify({"error": f"Error with Ollama API: {e}"}), 500
        finally:
            os.remove(file_path)
    else:
        return jsonify({"error": "File type not allowed"}), 400

if __name__ == '__main__':
    app.run(debug=True)
