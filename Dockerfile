# --- Backend Stage ---
FROM python:3.12-alpine AS backend

WORKDIR /app/backend

# Install bash for compatibility with the start.sh scripts
RUN apk add --no-cache bash

# Copy backend files and its start script
COPY backend /app/backend
COPY backend/start.sh /app/backend/start.sh
RUN chmod +x /app/backend/start.sh

# Copy requirements and use start.sh for production setup
COPY requirements.txt /app/requirements.txt
RUN /app/backend/start.sh setup-prod

# --- Frontend Stage ---
FROM node:20-alpine AS frontend

WORKDIR /app/frontend

# Install bash for compatibility with the start.sh scripts
RUN apk add --no-cache bash

# Copy frontend files and its start script
COPY frontend /app/frontend
COPY frontend/start.sh /app/frontend/start.sh
RUN chmod +x /app/frontend/start.sh

# Use start.sh to prepare the frontend for production
RUN /app/frontend/start.sh setup-prod

# --- Final Stage ---
FROM python:3.12-alpine AS final

WORKDIR /app

# Install Node.js and bash for compatibility with the scripts
RUN apk add --no-cache nodejs npm bash nginx openssl

# Copy backend from the backend stage
COPY --from=backend /app/backend /app/backend
COPY --from=backend /opt/venv /opt/venv

# Copy frontend build artifacts
COPY --from=frontend /app/frontend /app/frontend

# Configure NGINX
COPY nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /var/lib/nginx /run/nginx

# ssl
#COPY ssl/certificate.crt /etc/ssl/certs/certificate.crt
#COPY ssl/certificate.key /etc/ssl/private/certificate.key


# Expose ports using environment variables with defaults
ENV BACKEND_PORT=2568
ENV FRONTEND_PORT=3000
ENV HTTP_PORT=80
ENV HTTPS_PORT=443

# Copy the main start script to the root
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Expose the ports
EXPOSE ${HTTP_PORT} ${HTTPS_PORT}

# Default command to run the app in production mode
CMD ["/app/start.sh", "prod"]
