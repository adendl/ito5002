# Community Power

Community Power is a team project for the Monash University ITO5002 course in 2024. This application aims to provide easier access to electric vehicle (EV) chargers through an online platform where users can book and reserve excess capacity. Our goal is to facilitate the use of EV chargers, making it more convenient for users to find and reserve charging spots.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Running Locally](#running-locally)
- [Building and Deploying with Docker](#building-and-deploying-with-docker)
- [CI/CD with Google Cloud](#cicd-with-google-cloud)

## Features

- User-friendly interface to find and book EV chargers
- Real-time availability and reservation system
- Integration with multiple EV charger networks
- Notifications for booking confirmations and reminders

## Installation

To set up the project locally, follow these steps:

1. **Clone the repository:**
   sh
   git clone https://github.com/yourusername/community-power.git
   cd community-power
2. **Install dependencies**:
npm install

## Running Locally
To run the application locally, you can use the development server provided by Vite:

npm run dev
Open your browser and navigate to http://localhost:3000 to see the application in action.

## Building and Deploying with Docker
To build and deploy the application using Docker, follow these steps:

Build the Docker image:

docker build -t sveltejs-app .

Run the Docker container:

docker run -p 4173:4173 sveltejs-app
Access the application:
Open your browser and navigate to http://localhost:3000 to see the application running inside the Docker container.

## CI/CD with Google Cloud
We use Google Cloud Build and Google Cloud Run for continuous integration and continuous deployment (CI/CD). Here's a high-level overview of how our CI/CD pipeline works:

Source Code Management:

Our codebase is hosted on GitHub.
Changes are committed to the main branch and merged via pull requests.
Triggering Builds:

Whenever changes are pushed to the main branch, a Cloud Build trigger is activated.
Cloud Build fetches the latest code from GitHub.
Building the Docker Image:

Cloud Build uses the cloudbuild.yaml configuration file to build the Docker image.
The image is tagged with the commit SHA and pushed to Google Artifact Registry.
Deploying to Google Cloud Run:

After the Docker image is successfully built and pushed, Cloud Build deploys the new image to Google Cloud Run.
The deployment is configured to ensure zero downtime by using rolling updates.
Monitoring and Logging:

Google Cloud Run provides built-in monitoring and logging capabilities.
Logs can be accessed via the Google Cloud Console to troubleshoot any issues.

cloudbuild.yaml Example
Here is an example of the cloudbuild.yaml used for our CI/CD pipeline:

steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'us-central1-docker.pkg.dev/my-project/community-power:$COMMIT_SHA', '.']
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'us-central1-docker.pkg.dev/my-project/community-power:$COMMIT_SHA']

images:
  - 'us-central1-docker.pkg.dev/my-project/community-power:$COMMIT_SHA'

options:
  logging: CLOUD_LOGGING_ONLY
