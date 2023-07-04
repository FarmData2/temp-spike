FROM braughtg/vnc-novnc-base:1.2.0

USER root
RUN curl -sL https://deb.nodesource.com/setup_18.x -o /tmp/nodesource_setup.sh \
  && bash /tmp/nodesource_setup.sh \
  && apt install nodejs \
  && rm /tmp/nodesource_setup.sh \
  && npm install -g create-vue

# Install extensions into firefox.
# Add: JsonView, Hoppscotch and Vue.JS Devtools
RUN cd /usr/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384} \
  && wget https://addons.mozilla.org/firefox/downloads/file/4115735/jsonview-2.4.2.xpi \
  && mv jsonview-2.4.2.xpi jsonview@brh.numbera.com.xpi \
  && wget https://addons.mozilla.org/firefox/downloads/file/3991522/hoppscotch-0.25.xpi \
  && mv hoppscotch-0.25.xpi postwoman-firefox@postwoman.io.xpi \
  && wget https://addons.mozilla.org/firefox/downloads/file/4059290/vue_js_devtools-6.5.0.xpi \
  && mv vue_js_devtools-6.5.0.xpi {5caff8cc-3d2e-4110-a88a-003cc85b3858}.xpi

ARG USERNAME=student
USER $USERNAME
WORKDIR /home/$USERNAME

# Install some useful VSCodium extensions
RUN codium --install-extension vue.volar \
  && codium --install-extension dbaeumer.vscode-eslint \
  && codium --install-extension esbenp.prettier-vscode \
  && codium --install-extension timonwong.shellcheck
