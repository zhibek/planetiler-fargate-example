FROM ghcr.io/onthegomap/planetiler:latest

# Setup workdir
WORKDIR /workspace

# Copy local code to the container image.
COPY run.sh .

# Ensure the script is executable
RUN chmod +x ./run.sh

# Run the script
ENTRYPOINT ["./run.sh"]
