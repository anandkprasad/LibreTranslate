# Use slim Python image
FROM python:3.11.11-slim-bullseye

WORKDIR /app

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
    pkg-config gcc g++ git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv venv
ENV PATH="/app/venv/bin:$PATH"

# Upgrade pip
RUN pip install --upgrade pip

# Copy repo files
COPY . .

# Install dependencies, compile locales, and install models
RUN pip install --no-cache-dir Babel==2.12.1 \
    && python scripts/compile_locales.py \
    && pip install torch==2.2.0 --extra-index-url https://download.pytorch.org/whl/cpu \
    && pip install "numpy<2" \
    && pip install . \
    && pip install --no-cache-dir \
    && python scripts/install_models.py --load_only_lang_codes "en,hi,mr,te,ta,gu,bn,pa,kn,ml,or,as"

# Expose Render port
EXPOSE 5000

# Start LibreTranslate using Render's PORT environment variable
ENTRYPOINT ["libretranslate", "--host", "0.0.0.0", "--port", "${PORT}"]
