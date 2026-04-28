#!/bin/bash

mkdir -p data output

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
