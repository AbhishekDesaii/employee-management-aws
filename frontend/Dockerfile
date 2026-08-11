# Frontend Dockerfile
#
# Single-stage build: Node 20 alpine image with the Express app.
# Listens on port 3000.
#
# Build:
#   docker build -t employee-frontend .  (from the frontend/ directory)

FROM node:20-alpine

WORKDIR /app

# Install npm dependencies (dev deps are not needed at runtime)
COPY package.json ./
RUN npm install --omit=dev

# Copy the Express server and view files
COPY . .

# Expose the port the Express server listens on
EXPOSE 3000

# Start the server
CMD ["node", "server.js"]
