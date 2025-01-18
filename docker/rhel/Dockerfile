# Use the latest Fedora image
FROM fedora:latest

# Set the working directory
WORKDIR /ir-unbound

# Install git
RUN dnf install -y git && dnf clean all

# Copy the configuration file and script into the container
COPY ../b-domains.conf .
COPY ../iran-unbound.sh .

# Make the script executable
RUN chmod +x iran-unbound.sh

# Specify the command to run the script
CMD ["./iran-unbound.sh"]
