FROM braughtg/vnc-novnc-base:1.1.0

USER root
RUN \
  curl -sL https://deb.nodesource.com/setup_18.x -o /tmp/nodesource_setup.sh \
 && bash /tmp/nodesource_setup.sh \
 && apt install nodejs \
 && rm /tmp/nodesource_setup.sh \
 && npm install -g create-vue

ARG USERNAME=student

USER $USERNAME
WORKDIR /home/$USERNAME

 # Install some useful VSCodium extensions
RUN codium --install-extension vue.volar \
 && codium --install-extension streetsidesoftware.code-spell-checker \
 && codium --install-extension dbaeumer.vscode-eslint \
 && codium --install-extension esbenp.prettier-vscode \
 && codium --install-extension bierner.markdown-preview-github-styles

# Edit out recommended extension??

