#!/usr/bin/env bash
# Build some test docs in a container using the theme updates 

# create env file to pass PATH and variables to container
env | grep -E "^(PATH=)" > .env_travis
env | grep -E "^(AWS_)" >> .env_travis

set -e

: ${DOC_IMG:=f5devcentral/containthedocs:eflores1}

RUN_ARGS=( \
  --rm
  -i
  -v $PWD:$PWD
  --workdir $PWD
  ${DOCKER_RUN_ARGS}
  -e "LOCAL_USER_ID=$(id -u)"
  -e TRAVIS=$TRAVIS
  --env-file=.env_travis
)

printf "Starting Docker container..."

# Run the container using the provided args
# DO NOT SET -x BEFORE THIS TO KEEP THE CREDENTIALS OUT OF THE LOGS
docker run "${RUN_ARGS[@]}" ${DOC_IMG} /bin/bash -s <<EOF
set -x
set -e

# Install theme project requirements
pip install --user --upgrade .

# build some test docs
cd test && make html

# deploy test docs to S3
set +x

printf "Deploying test documentation to: ${S3_DIST_URL}/${UPLOAD_DIR}/index.html"

aws s3 sync docs/_build/html s3://${AWS_S3_BUCKET}/${UPLOAD_DIR}

# create and upload indices
#s3-index-generator -b $AWS_S3_BUCKET -t $BRANCH_DIR -r ${DIST_REPO} -i 'index.html'


# clean up
rm -rf .env_travis
EOF