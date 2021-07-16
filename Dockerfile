FROM archlinux:base-20210711.0.28748 AS a

RUN pacman -Sy && pacman -S --noconfirm \
    binutils \
    devtools \
    gettext \
    git \
    rsync \
    sudo

RUN useradd crema -m


FROM a AS c

ARG ofeliav=v0.3.4

RUN pacman -Sy && pacman -S --noconfirm \
    fakeroot \
    gcc \
    go \
    make \
    pandoc

USER crema

RUN curl -Lo - https://aur.archlinux.org/cgit/aur.git/snapshot/crema.tar.gz | tar xz -C /home/crema/
WORKDIR /home/crema/
RUN cd crema/ && makepkg

RUN git clone https://github.com/mcuadros/ofelia
WORKDIR ofelia
RUN git checkout ${ofeliav}
RUN go get -d -v ./...
RUN go build -o . -v ./...


FROM a

ARG cremav=2.3.1-1

WORKDIR /home/crema/

COPY --from=c /home/crema/crema/crema-${cremav}-any.pkg.tar.zst .
COPY --from=c /home/crema/ofelia/ofelia /usr/local/bin/

RUN pacman -U --noconfirm crema-${cremav}-any.pkg.tar.zst

RUN sed -i 's/\.zst/\.xz/g' /usr/share/devtools/makepkg-x86_64.conf
ENV container=docker
RUN systemd-machine-id-setup
RUN echo "Set disable_coredump false" >> /etc/sudo.conf
RUN echo "crema ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER crema

COPY wrappers/* /usr/local/bin/
COPY --chown=crema:crema repos.conf .config/crema/
COPY --chown=crema:crema ofelia.ini .
RUN mkdir repo/

VOLUME /home/crema/repo/

COPY crema-ofelia-entrypoint.sh /usr/local/bin/

CMD ["crema-ofelia-entrypoint.sh"]
