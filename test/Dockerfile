FROM alpine:latest

RUN apk update && \
    apk add --no-cache git curl gnupg go ripgrep && \
    rm -rf /var/cache/apk/*

RUN go install github.com/charmbracelet/gum@latest
ENV PATH=$PATH:/root/go/bin

# COPY git/ /root/dotfiles/git/

CMD ["sh"]