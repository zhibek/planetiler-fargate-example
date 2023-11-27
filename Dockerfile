FROM maven:3.9.5

# Install AWS cli
RUN apt update \
&& apt install -y unzip \
&& cd /tmp \
&& curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
&& unzip awscliv2.zip \
&& ./aws/install \
&& aws --version \
&& cd -

# Setup workdir
WORKDIR /workspace

# Copy local code to the container image.
COPY . .

# Build app
RUN mvn clean package

# Ensure the script is executable
RUN chmod +x ./run.sh

# Run the script
ENTRYPOINT ["./run.sh"]
