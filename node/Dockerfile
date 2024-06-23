FROM alpine:latest
RUN apk add --update nodejs npm
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["node", "index.js"]
