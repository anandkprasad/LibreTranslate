FROM python:3.11.11-slim-bullseye AS builder

WORKDIR /app

RUN apt-get update -qq && apt-get install -y pkg-config gcc g++ git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN python -m venv venv && ./venv/bin/pip install --upgrade pip

COPY . .

# Install dependencies and compile locales
RUN ./venv/bin/pip install --no-cache-dir Babel==2.12.1 \
    && ./venv/bin/python scripts/compile_locales.py \
    && ./venv/bin/pip install torch==2.2.0 --extra-index-url https://download.pytorch.org/whl/cpu \
    && ./venv/bin/pip install "numpy<2" \
    && ./venv/bin/pip install . \
    && ./venv/bin/pip cache purge

FROM python:3.11.11-slim-bullseye

ARG with_models=true
ARG models="en,hi,mr,te,ta,gu,bn,pa,kn,ml,or,as"

RUN addgroup --system --gid 1032 libretranslate && adduser --system --uid 1032 libretranslate \
    && mkdir -p /home/libretranslate/.local && chown -R libretranslate:libretranslate /home/libretranslate/.local
USER libretranslate

COPY --from=builder --chown=1032:1032 /app /app
WORKDIR /app
COPY --from=builder --chown=1032:1032 /app/venv/bin/ltmanage /usr/bin/

# Install only the specified models
RUN if [ "$with_models" = "true" ]; then  \
        ./venv/bin/python scripts/install_models.py --load_only_lang_codes "$models"; \
    fi

EXPOSE 5000
ENTRYPOINT [ "./venv/bin/libretranslate", "--host", "0.0.0.0", "--port", "${PORT}" ]
