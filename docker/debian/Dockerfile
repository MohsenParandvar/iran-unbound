# Use the latest Debian image
FROM debian:latest

# Set the working directory
WORKDIR /ir-unbound

# Install git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Copy the configuration file and script into the container
COPY ../b-domains.conf .
COPY ../iran-unbound.sh .

# Make the script executable
RUN chmod +x iran-unbound.sh

# Specify the command to run the script
CMD ["./iran-unbound.sh"]
