FROM dorowu/ubuntu-desktop-lxde-vnc:bionic

RUN apt-get update && \
    apt-get install -y apt-transport-https wget gnupg && \
    sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -' && \
    sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list' && \
    apt-get update && \
    apt-get install -y dart

RUN apt-get update &&  \
    apt-get install -y git python3-dev libyaml-dev python3-pip unzip vim curl wget sudo && \
    apt-get install -y silversearcher-ag fish tmux gnome-terminal tzdata&& \
    pip3 install ansible fish

RUN apt install -y python-dev python-pip terminator;pip2 install ansible pynvim
RUN curl https://raw.githubusercontent.com/kjelly/auto_config/master/scripts/init_nvimrc.sh | bash ; \
    curl https://raw.githubusercontent.com/kjelly/auto_config/master/scripts/init_nvim_nightly.sh | bash ;

RUN echo "ubuntu ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu


ENTRYPOINT ["/startup.sh"]
