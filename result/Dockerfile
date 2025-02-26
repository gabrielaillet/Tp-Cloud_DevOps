FROM node:18-slim
WORKDIR /usr/local/app
COPY package*.json ./
RUN npm install -g nodemon
RUN npm ci
RUN npm cache clean --force
RUN mv /usr/local/app/node_modules /node_modules
COPY . .
EXPOSE 4000
CMD ["node", "server.js"]