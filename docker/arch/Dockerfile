# Use the latest Arch Linux image
FROM archlinux:latest

# Set the working directory
WORKDIR /ir-unbound

# Install git
RUN pacman -Sy --noconfirm git && pacman -Scc --noconfirm

# Copy the configuration file and script into the container
COPY ../b-domains.conf .
COPY ../iran-unbound.sh .

# Make the script executable
RUN chmod +x iran-unbound.sh

# Specify the command to run the script
CMD ["./iran-unbound.sh"]
