# Build an image that can do training and inference in SageMaker
# This is a Python 3 image that uses the nginx, gunicorn, flask stack
# for serving inferences in a stable way.

FROM ubuntu:16.04

MAINTAINER Amazon AI <sage-learner@amazon.com>

RUN apt-get -y update && apt-get install -y --no-install-recommends \
         wget \
         python3 \
         nginx \
         ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Here we get all python packages.
# Pip leaves the install caches populated which uses a significant amount of space.
# This optimization save a fair amount of space in the image, which reduces start up time.
RUN wget https://bootstrap.pypa.io/get-pip.py && python3 get-pip.py && \
    pip install scipy scikit-learn pandas flask gevent gunicorn && rm -rf /root/.cache

# Set some environment variables. PYTHONUNBUFFERED keeps Python from buffering our standard
# output stream, which means that logs can be delivered to the user quickly. PYTHONDONTWRITEBYTECODE
# keeps Python from writing the .pyc files which are unnecessary in this case. We also update
# PATH so that the train and serve programs are found when the container is invoked.

ENV PYTHONUNBUFFERED=TRUE
ENV PYTHONDONTWRITEBYTECODE=TRUE
ENV PATH="/opt/program:${PATH}"

# Set up the program in the image
COPY deployment_utility /opt/program
COPY predictor.py /opt/program
WORKDIR /opt/program

# Run the program that serves predictions
ENTRYPOINT ["./serve"]
