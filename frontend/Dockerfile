# Stage 1: Build the React application
FROM node:20-slim AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install --legacy-peer-deps --no-audit --no-fund

# Copy the rest of the application code
COPY . .

# Build the application
RUN npm run build

# Stage 2: Serve the application with Nginx (Note: the actual serving will be handled by the main nginx, this is just to create a container that can serve statically if needed, or we just map volumes. For cleaner separation, let's use a lightweight nginx here, and the main nginx acts as API gateway)
FROM nginx:alpine

# Copy the built assets from the builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy a default simple nginx config for the frontend container
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose the frontend port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
