FROM maven:3.9.5 AS build

# Setup workdir
WORKDIR /workspace

# Copy local maven config to the container image
COPY ./pom.xml .

# Cache app dependencies
RUN --mount=type=cache,target=/root/.m2 mvn dependency:go-offline

# Copy local code to the container image
COPY ./src ./src

# Build app
RUN --mount=type=cache,target=/root/.m2 mvn package

###############################################################################

FROM maven:3.9.5-eclipse-temurin-21-alpine

# Setup workdir
WORKDIR /workspace

# Install AWS cli
RUN apk update \
&& apk add --no-cache aws-cli \
&& aws --version

# Copy app build to container image
COPY --from=build /workspace/target /workspace/target

# Check app is functioning
RUN java -jar ./target/*-with-deps.jar --check

# Copy local script to container image
COPY ./run.sh .

# Ensure the script is executable
RUN chmod +x ./run.sh

# Run the script
ENTRYPOINT ["./run.sh"]
