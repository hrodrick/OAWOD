FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    gpg \
    ca-certificates \
    build-essential \
    python3 \
    python3-pip \
    tmux \
    unzip \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && wget -nv -O /etc/apt/keyrings/githubcli-archive-keyring.gpg \
       https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs

# Bun
RUN curl -fsSL https://bun.sh/install | bash

ENV PATH="/root/.bun/bin:${PATH}"

# OpenCode
RUN npm install -g opencode-ai

# OmO Ultimate
RUN bunx oh-my-openagent install \
    --no-tui \
    --platform=opencode \
    --claude=no \
    --openai=no \
    --gemini=no \
    --copilot=no \
    --opencode-zen=no \
    --zai-coding-plan=no \
    --kimi-for-coding=no \
    --opencode-go=no \
    --bailian-coding-plan=no \
    --minimax-cn-coding-plan=no \
    --minimax-coding-plan=no \
    --vercel-ai-gateway=no \
    --skip-auth

WORKDIR /workspace

CMD ["bash"]