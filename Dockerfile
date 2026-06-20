FROM node:20-alpine3.21

RUN apk upgrade --no-cache

WORKDIR /usr/src/app

COPY app/package*.json ./
RUN npm install --production

COPY app/ ./
COPY requirements.txt ./

RUN apk add --no-cache python3 py3-pip \
  && python3 -m pip install --no-cache-dir --break-system-packages -r requirements.txt

EXPOSE 3000
CMD ["node", "index.js"]
