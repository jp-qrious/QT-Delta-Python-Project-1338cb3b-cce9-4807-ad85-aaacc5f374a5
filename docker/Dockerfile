FROM python:3.11 AS base
# base installs poetry and the default entrypoint

ENV LANG=C.UTF-8
ENV PYTHONIOENCODING=utf8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system level dependencies.
RUN apt-get update && \
    apt-get install -y \
        curl \
        unzip && \
    apt clean

WORKDIR /opt/project

# Install Poetry.
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="$PATH:/root/.local/bin"
RUN poetry config virtualenvs.create false

COPY docker/entrypoint.sh /opt/entrypoint.sh
COPY scripts /opt/scripts

# Install latest version of awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip -qq awscliv2.zip
RUN ./aws/install

ENTRYPOINT ["bash", "/opt/entrypoint.sh"]

FROM base AS dev
# dev sets up the venv for local development

RUN python -m venv "/opt/venv"

FROM base AS build
# build includes all files, and builds a virtualenv and a wheel

COPY ./ .

RUN python -m venv "/opt/venv" && \
    . /opt/venv/bin/activate && \
    poetry install --no-dev

RUN . /opt/venv/bin/activate && \
    poetry build

FROM build AS prod

ENTRYPOINT [&quot;bash&quot;, &quot;/entrypoint.sh&quot;]


