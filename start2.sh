#!/bin/bash

# Generate a random runner name suffix
RUNNER_SUFFIX=$(tr -dc 'a-z0-9' < /dev/urandom | head -c 5)
RUNNER_NAME="dockerNode-${RUNNER_SUFFIX}"

# Get registration token for the organization
REG_TOKEN=$(curl -sX POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GH_TOKEN}" \
https://api.github.com/orgs/${GH_OWNER}/actions/runners/registration-token | jq .token --raw-output)

# Check if registration token was successfully retrieved
if [ -z "$REG_TOKEN" ]; then
    echo "Error: Failed to retrieve registration token"
    exit 1
fi

# Check if actions-runner directory exists
if [ ! -d "/home/docker/actions-runner" ]; then
    echo "Error: /home/docker/actions-runner directory not found."
    exit 1
fi

# Change directory to actions-runner
cd /home/docker/actions-runner

# Configure the runner with the docker label
echo "Configuring runner ${RUNNER_NAME} for organization ${GH_OWNER}..."
./config.sh --unattended --url https://github.com/${GH_OWNER} --token ${REG_TOKEN} --name ${RUNNER_NAME} --labels "docker"

# Define cleanup function
cleanup() {
    echo "Removing runner ${RUNNER_NAME}..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
    echo "Cleanup completed."
}

# Trap signals and run cleanup
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
trap 'cleanup' EXIT

# Run the runner and wait for exit
./run.sh & wait $!
