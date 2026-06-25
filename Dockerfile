FROM node:18-alpine AS backend-base
WORKDIR /app/backend
COPY backend/package*.json backend/.npmrc* ./
RUN npm install

FROM backend-base AS backend-dev
COPY backend/ ./
CMD ["npm", "run", "dev"]


FROM backend-base AS backend-test
COPY backend/ ./
RUN npm test
RUN touch /test-passed.txt

FROM node:18-alpine AS frontend-dev
WORKDIR /app/client
COPY client/package*.json ./
RUN npm install
COPY client/ ./
CMD ["npm", "run", "dev"]


FROM frontend-dev AS frontend-build
COPY client/ ./
RUN npm run build

FROM node:18-alpine AS final
RUN mkdir -p /app/client/dist

WORKDIR /app/backend
COPY --from=backend-test /test-passed.txt /tmp/
COPY backend/package*.json backend/.npmrc* ./
RUN npm install --omit=dev
COPY backend/ ./

COPY --from=frontend-build /app/client/dist /app/client/dist

COPY --from=frontend-build /app/client/dist ./public
COPY --from=frontend-build /app/client/dist ./static
COPY --from=frontend-build /app/client/dist ./src/static

EXPOSE 3000

CMD ["node", "src/index.js"]