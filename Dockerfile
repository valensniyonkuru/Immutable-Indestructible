FROM node:20-alpine3.21

RUN apk upgrade --no-cache

WORKDIR /usr/src/app

COPY app/package*.json ./

ARG CA_NPM_ENDPOINT
ARG CA_TOKEN
RUN npm config set registry "$CA_NPM_ENDPOINT" \
    && npm config set "${CA_NPM_ENDPOINT#https:}:_authToken" "$CA_TOKEN" \
    && npm install --production \
    && npm config delete registry \
    && npm config delete "${CA_NPM_ENDPOINT#https:}:_authToken"

COPY app/ ./
COPY requirements.txt ./

ARG CA_PYPI_INDEX_URL
RUN apk add --no-cache python3 py3-pip \
  && python3 -m pip install --no-cache-dir --break-system-packages \
     --index-url "$CA_PYPI_INDEX_URL" \
     -r requirements.txt

EXPOSE 3000
CMD ["node", "index.js"]
