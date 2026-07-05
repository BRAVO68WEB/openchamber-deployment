FROM oven/bun:1.3.14

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    g++ \
    git \
    less \
    make \
    openssh-client \
    python3 \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN userdel bun 2>/dev/null || true \
    && groupadd -g 1000 openchamber \
    && useradd -u 1000 -g 1000 -m -s /bin/bash openchamber \
    && usermod -aG sudo openchamber \
    && echo 'openchamber ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/openchamber \
    && chmod 0440 /etc/sudoers.d/openchamber \
    && chown -R openchamber:openchamber /home/openchamber

USER openchamber
WORKDIR /home/openchamber

# ── Install nvm + Node.js 22 (for opencode-ai) ──
ENV NVM_DIR=/home/openchamber/.nvm

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && source "$NVM_DIR/nvm.sh" \
    && nvm install 22 \
    && nvm alias default 22 \
    && nvm use default

# ── Install opencode-ai via nvm's npm ──
RUN source "$NVM_DIR/nvm.sh" \
    && mkdir -p /home/openchamber/.local /home/openchamber/.config /home/openchamber/.ssh \
    && npm install -g opencode-ai

# ── Install OpenChamber via npm ──
RUN source "$NVM_DIR/nvm.sh" \
    && npm install -g @openchamber/web

# ── Create config dirs with proper ownership (for volume mounts) ──
RUN mkdir -p /home/openchamber/.config/openchamber \
    && mkdir -p /home/openchamber/.config/opencode \
    && mkdir -p /home/openchamber/.local/share/opencode

COPY docker-entrypoint.sh /home/openchamber/openchamber-entrypoint.sh

ENV NODE_ENV=production
EXPOSE 3000

ENTRYPOINT ["bash", "/home/openchamber/openchamber-entrypoint.sh"]
