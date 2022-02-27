FROM archlinux:base-20220220.0.48372 AS a

RUN pacman -Sy && pacman -S --noconfirm git

RUN useradd crema -m


FROM a AS c

RUN pacman -S --noconfirm go

USER crema
WORKDIR /home/crema/

ARG cremav=v2.9.2
RUN git clone https://gitlab.com/mipimipi/crema
WORKDIR crema
RUN git checkout ${cremav}
RUN go get -d -v ./...
RUN go build -o /home/crema/out/ -v ./...

ARG ofeliav=v0.3.6
RUN git clone https://github.com/mcuadros/ofelia
WORKDIR ofelia
RUN git checkout ${ofeliav}
RUN go get -d -v ./...
RUN go build -o /home/crema/out/ -v ./...


FROM a

WORKDIR /home/crema/

COPY --from=c /home/crema/out/cmd /usr/local/bin/crema
COPY --from=c /home/crema/out/ofelia /usr/local/bin/

RUN pacman -S --noconfirm \
    binutils \
    devtools \
    sudo

ENV container=docker
RUN systemd-machine-id-setup
RUN echo "Set disable_coredump false" >> /etc/sudo.conf
RUN echo "crema ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER crema

COPY wrappers/* /usr/local/bin/
COPY --chown=crema:crema repos.conf .config/crema/
COPY --chown=crema:crema ofelia.ini .

RUN sed 's/\.zst/\.xz/g' /usr/share/devtools/makepkg-x86_64.conf > /home/crema/.config/crema/makepkg.conf
RUN cp /usr/share/devtools/pacman-multilib.conf /home/crema/.config/crema/pacman.conf
RUN mkdir repo/

VOLUME /home/crema/repo/

COPY crema-ofelia-entrypoint.sh /usr/local/bin/

CMD ["crema-ofelia-entrypoint.sh"]
