FROM ubuntu:24.04

ARG GO_VERSION=1.24.3

# --- Install base utilities ---
RUN apt update -qq && \
    apt install -y \
    git curl unzip bash-completion build-essential \
    ca-certificates libssl-dev \
    gcc-x86-64-linux-gnu \
    docker.io \
    iproute2 tcpdump iperf3 \
    lsb-release gnupg && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# --- Install Rust ---
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH="/usr/local/cargo/bin:${PATH}"
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    rustup install nightly && \
    rustup component add --toolchain nightly rustfmt && \
    rustup component add clippy && \
    rustup default stable

# --- Install Rust tools ---
RUN curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash && \
    cargo binstall cargo-nextest && \
    cargo install bottom

# --- Install Go ---
ENV GO_VERSION=${GO_VERSION}
RUN curl -sSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:/root/go/bin:${PATH}"

# --- Go tools ---
ENV CGO_ENABLED=0
RUN go install golang.org/x/tools/gopls@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest && \
    go install github.com/fatih/gomodifytags@latest && \
    go install github.com/josharian/impl@latest && \
    go install github.com/cweill/gotests/...@latest && \
    go install github.com/uudashr/gopkgs/v2/cmd/gopkgs@latest

# --- Install golangci-lint ---
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.1.6

# --- Install gotest ---
RUN curl -sSL https://gotest-release.s3.amazonaws.com/gotest_linux -o /usr/local/bin/gotest && \
    chmod +x /usr/local/bin/gotest

# --- Install goreleaser ---
RUN echo 'deb [trusted=yes] https://repo.goreleaser.com/apt/ /' | tee /etc/apt/sources.list.d/goreleaser.list && \
    apt update -qq && \
    apt install -y goreleaser-pro && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# --- Install agave/solana tools ---
# https://github.com/anza-xyz/agave/issues/1734
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64) ARCH_TAG=x86_64 ;; \
        aarch64) ARCH_TAG=aarch64 ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    VERSION=$(curl -s https://api.github.com/repos/staratlasmeta/agave-dist/releases/latest | grep tag_name | cut -d '"' -f 4) && \
    URL="https://github.com/staratlasmeta/agave-dist/releases/download/${VERSION}/solana-release-${ARCH_TAG}-unknown-linux-gnu.tar.bz2" && \
    mkdir -p /opt/agave && \
    curl -sL "$URL" -o /tmp/agave.tar.bz2 && \
    tar -xjf /tmp/agave.tar.bz2 -C /opt/agave && \
    mkdir -p /opt/solana/bin && \
    cp -r /opt/agave/solana-release/bin/* /opt/solana/bin/ && \
    rm -rf /tmp/agave.tar.bz2
ENV PATH="/opt/solana/bin:${PATH}"

# --- Configure bash completion ---
RUN echo '[ -f /etc/bash_completion ] && . /etc/bash_completion' >> /root/.bashrc

# --- Install fd ---
RUN apt-get update -qq && \
    apt-get install -y fd-find && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# --- Install fzf ---
RUN git clone --depth 1 https://github.com/junegunn/fzf.git /opt/fzf && \
    /opt/fzf/install --bin && \
    mv /opt/fzf/bin/fzf /usr/local/bin/

# --- Install neovim ---
RUN ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
      amd64)  FILE=nvim-linux-x86_64.tar.gz ;; \
      arm64)  FILE=nvim-linux-arm64.tar.gz ;; \
      *)      echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    curl -LO https://github.com/neovim/neovim/releases/latest/download/$FILE && \
    tar -xzf $FILE && \
    mv nvim-*/ /opt/nvim && \
    ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim && \
    rm $FILE && \
    mkdir -p /root/.config/nvim
RUN ln -sf /usr/local/bin/nvim /usr/bin/vim && \
    ln -sf /usr/local/bin/nvim /usr/bin/vi

COPY ./nvim /root/.config/nvim
RUN nvim --headless "+Lazy sync" +qa
