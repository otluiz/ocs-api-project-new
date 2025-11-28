# client/Dockerfile
# Use uma imagem base Node.js
FROM node:20-alpine

# Instalar Python 3 e pip (necessário para rodar scripts Python)
RUN apk add --no-cache python3 py3-pip

# Defina o diretório de trabalho
WORKDIR /app

# Copie e instale as dependências do Python
# 1. Copia o arquivo requirements.txt para o container
COPY requirements.txt .
# 2. Instala as dependências listadas
RUN pip3 install -r requirements.txt --break-system-packages

# Copie os arquivos de package e instale as dependências
COPY package*.json ./
RUN npm install

# Copie o restante do código
COPY . .

# Exponha a porta padrão do Vite
EXPOSE 5173

# Comando para iniciar o servidor de desenvolvimento
CMD ["npm", "run", "dev"]
