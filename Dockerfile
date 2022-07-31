FROM python:3.10-buster

ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_DEFAULT_REGION

RUN pip install "poetry"

WORKDIR /src
COPY poetry.lock pyproject.toml /src/

# Project initialization:
RUN poetry config virtualenvs.create false \
  && poetry install --no-interaction --no-ansi

# Creating folders, and files for a project:
COPY . /src

# Run tweeter
CMD poetry run python src/main.py