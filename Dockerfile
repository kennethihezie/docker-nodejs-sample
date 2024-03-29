# syntax=docker/dockerfile:1

# Rather than creating one Dockerfile for production, and another Dockerfile for development, 
# you can use one multi-stage Dockerfile for both
# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

ARG NODE_VERSION=18.17.1

FROM node:${NODE_VERSION}-alpine as base
WORKDIR /usr/src/app
# Expose the port that the application listens on.
EXPOSE 3000

FROM base as dev
# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.npm to speed up subsequent builds.
# Leverage a bind mounts to package.json and package-lock.json to avoid having to copy them into
# into this layer.
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

# Run the application as a non-root user.
USER node

# Copy the rest of the source files into the image.
COPY . .

CMD sudo npm install && \  npm run dev


FROM base as prod
# Use production node environment by default.
ENV NODE_ENV production
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

USER node


COPY . .
# Run the application.
CMD node src/index.js

# docker init: to initialize docker in an existing project
# docker compose up --build: to run your application using docker
# docker compose up --build -d: run the application detached from the terminal by adding the -d option
# docker compose down: to stop the application.
# docker compose rm: to remove your containers.
