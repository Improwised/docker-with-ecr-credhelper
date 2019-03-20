FROM docker:latest

ENV APP_REPO=github.com/awslabs/amazon-ecr-credential-helper
ENV APP_VERSION=v0.3.0
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:$PATH

RUN set -ex \
  && apk add --no-cache --virtual .build-deps \
    gcc g++ musl-dev go git \
  && apk add --no-cache --virtual .run-deps \
    # Miscellaneous packages
    bash ca-certificates curl jq openssl python py-pip \
  && pip install awscli \
  # Setup Go Build Environment
  && export GOPATH=/go \
    && mkdir $GOPATH \
    && git clone https://$APP_REPO $GOPATH/src/$APP_REPO \
    && cd $GOPATH/src/$APP_REPO \
    && git checkout $APP_VERSION \
    && GOOS=linux CGO_ENABLED=1 go build -installsuffix cgo \
       -a -ldflags '-s -w' -o /usr/bin/docker-credential-ecr-login \
       ./ecr-login/cli/docker-credential-ecr-login \
  # Install AWS IAM Authenticator
  && curl -L -o /usr/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator \
    && chmod +x /usr/bin/aws-iam-authenticator \
  # Install Helm
  && export DESIRED_VERSION=v2.12.2 \
  && curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash \
  # Cleanup
  && apk del --purge -r .build-deps \
  && rm -rf $GOPATH
