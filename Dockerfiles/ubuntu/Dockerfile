FROM ubuntu:18.04

RUN apt-get update && apt-get install -y git python-dev libyaml-dev python-pip unzip vim curl sudo && pip install ansible

RUN curl https://raw.githubusercontent.com/kjelly/auto_config/master/scripts/init_nvimrc.sh | bash && \
    curl https://raw.githubusercontent.com/kjelly/auto_config/master/scripts/init_nvim_nightly.sh | bash && \
    nvim.nightly +PlugInstall +qall!

CMD "/bin/bash"
