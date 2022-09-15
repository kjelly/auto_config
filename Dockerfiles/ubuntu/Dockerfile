FROM ubuntu:20.04

RUN apt-get update && apt-get install -y git python3-dev libyaml-dev python3-pip unzip vim curl sudo && pip3 install ansible

RUN curl https://raw.githubusercontent.com/kjelly/auto_config/master/scripts/init_nvim_nightly.sh | bash && \
    curl https://raw.githubusercontent.com/kjelly/auto_config/master/scripts/init_nvim.sh | bash && \
    curl https://raw.githubusercontent.com/kjelly/auto_config/master/scripts/init_nvimrc.sh | bash; echo good

CMD "/bin/bash"
