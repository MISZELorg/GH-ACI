# Base image
FROM ubuntu:24.04

# Input GitHub runner version argument
ARG RUNNER_VERSION
ENV DEBIAN_FRONTEND=noninteractive

LABEL BaseImage="ubuntu:24.04"
LABEL RunnerVersion=${RUNNER_VERSION}

# Update packages and install necessary dependencies
RUN apt-get update -y && \
    apt-get upgrade -y && \
    useradd -m docker && \
    apt-get install -y --no-install-recommends \
    curl wget unzip git jq build-essential \
    libssl-dev libffi-dev libicu-dev python3 python3-venv python3-dev python3-pip dos2unix && \
    # Install Node.js from NodeSource
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create actions-runner directory
RUN mkdir -p /home/docker/actions-runner

# Download the GitHub Actions runner
RUN curl -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    -o /home/docker/actions-runner/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Extract the downloaded file and clean up
RUN tar xzf /home/docker/actions-runner/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -C /home/docker/actions-runner && \
    rm /home/docker/actions-runner/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Install additional dependencies from the runner's script
RUN chown -R docker /home/docker && \
    /home/docker/actions-runner/bin/installdependencies.sh

# Ensure the scripts directory exists and copy the start2.sh script
COPY ./scripts/start2.sh /home/docker/start2.sh

# Convert line endings of start.sh and make it executable
RUN dos2unix /home/docker/start2.sh && \
    chmod +x /home/docker/start2.sh

# Set the user to "docker" for subsequent commands
USER docker

# Set the working directory and entrypoint
WORKDIR /home/docker
ENTRYPOINT ["./start2.sh"]
