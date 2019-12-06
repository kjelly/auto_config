FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y apt-transport-https wget gnupg && \
    sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -' && \
    sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list' && \
    apt-get update && \
    apt-get install -y dart

RUN apt-get update &&  \
    apt-get install -y git python3-dev libyaml-dev python3-pip unzip vim curl wget sudo && \
    apt-get install -y silversearcher-ag && \
    pip3 install ansible fish

RUN git clone https://github.com/kjelly/auto_config ~/a


RUN apt install -y python-dev python-pip ;pip2 install ansible pynvim

RUN cd ~/a ; \
    echo '{}'|./nrun.py -r developer-packages -a deploy; \
    echo '{}'|./nrun.py -r fish bash -a deploy; \
    ls

RUN curl https://raw.githubusercontent.com/kjelly/auto_config/master/scripts/init_nvimrc.sh | bash ; \
    curl https://raw.githubusercontent.com/kjelly/auto_config/master/scripts/init_nvim_nightly.sh | bash ; \
    curl https://raw.githubusercontent.com/kjelly/auto_config/master/scripts/init_nvim.sh | bash ; \
    nvim +PlugInstall +qall!; pip3 install pynvim;ls

CMD sleep infinity
