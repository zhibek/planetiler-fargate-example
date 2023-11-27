#!/bin/bash

# Stop on any error
set -e

# Use env vars or defaults for input variables
AREA="${AREA:=}"
BUCKET="${BUCKET:=}"

# Validate input variables are set
[ -z "${AREA}" ] && echo "ERROR: AREA env var must be set!" && exit 1;
[ -z "${BUCKET}" ] && echo "ERROR: BUCKET env var must be set!" && exit 1;

# Execute Planetiler
echo "** Running Planetiler..."
java -Xmx6g \
  -cp @/app/jib-classpath-file com.onthegomap.planetiler.Main \
  --download \
  --area=${AREA} \
  --output=${AREA}.pmtiles
echo "** Planetiler complete!"

echo "** Checking data files..."
ls -alh ./${AREA}.pmtiles

echo "** Save PMTiles to S3 bucket"
aws s3 cp \
  ./${AREA}.pmtiles \
  s3://${BUCKET}