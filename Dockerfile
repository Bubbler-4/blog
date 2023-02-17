FROM gitpod/workspace-full:latest

USER root
RUN apt-get update -y -q \
  && cd /tmp \
  && curl -fsSL -k https://github.com/gohugoio/hugo/releases/download/v0.102.3/hugo_0.102.3_Linux-64bit.deb -o hugo.deb \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends ./hugo.deb

RUN rm -rf /etc/localtime \
  && ln -s /usr/share/zoneinfo/Etc/GMT-9 /etc/localtime

USER gitpod
RUN echo 'alias gphugo="hugo server -b $(gp url 1313) --appendPort=false -D"' >> ~/.bashrc
