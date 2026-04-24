from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        'message': 'Hello from Lab #3 CI/CD Application!',
        'version': os.getenv('APP_VERSION', '1.0.0'),
        'status': 'running'
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'}), 200

@app.route('/api/info')
def info():
    return jsonify({
        'app': 'Lab #3 CI/CD Demo',
        'endpoints': ['/', '/health', '/api/info']
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
