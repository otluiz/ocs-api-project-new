import requests
import os

# URL do endpoint (ajuste conforme necessário)
# O usuário mencionou 192.168.200.30:8000
API_URL = "http://192.168.200.30:8000/ocsinventory"

# Caminho para o arquivo XML de teste
XML_FILE_PATH = "inventario_teste.xml"

def test_xml_ingestion():
    if not os.path.exists(XML_FILE_PATH):
        print(f"Erro: Arquivo {XML_FILE_PATH} não encontrado. Certifique-se de que ele está no diretório correto.")
        return

    print(f"Lendo arquivo XML: {XML_FILE_PATH}")
    with open(XML_FILE_PATH, "r") as f:
        xml_payload = f.read()

    # Simular envio de XML não compactado
    headers = {
        "Content-Type": "application/xml",
        "User-Agent": "OCS-Test-Client/1.0"
    }

    print(f"Enviando requisição POST para {API_URL}...")
    try:
        response = requests.post(API_URL, data=xml_payload.encode('utf-8'), headers=headers)
        
        print("\n--- Resposta do Servidor ---")
        print(f"Status Code: {response.status_code}")
        print(f"Content-Type: {response.headers.get('Content-Type')}")
        print(f"Corpo da Resposta:\n{response.text}")

        if response.status_code == 200:
            print("\n✓ SUCESSO: Inventário enviado e processado com sucesso (XML não compactado).")
        else:
            print(f"\n✗ FALHA: O servidor retornou um erro.")
            
    except requests.exceptions.ConnectionError as e:
        print(f"\n✗ ERRO DE CONEXÃO: Não foi possível conectar ao servidor. Verifique se o IP e a porta estão corretos e se o servidor está rodando.")
        print(f"Detalhes do erro: {e}")
    except Exception as e:
        print(f"\n✗ ERRO INESPERADO: {e}")

if __name__ == "__main__":
    test_xml_ingestion()


