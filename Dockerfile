FROM avinetworks/avitools-base:bionic

ARG tf_version="0.11.7"
ARG avi_sdk_version
ARG avi_version

RUN echo $HOME

RUN apt-get update
RUN apt-get install -y git python python-dev python-pip python-virtualenv \
python-cffi libssl-dev libffi-dev make wget vim unzip golang-1.9-go sshpass curl slowhttptest netcat dnsutils httpie apache2-utils tree jq nmap inetutils-ping iproute2 apt-transport-https
RUN git config --global http.sslverify false

RUN pip install -U ansible==2.6.0
RUN pip install pyvmomi pytest==3.2.5 pyyaml==3.12 requests==2.18.4 requests-toolbelt==0.8.0 pyparsing==2.2.0 paramiko==2.4.1 pycrypto==2.6.1 ecdsa==0.13 pyOpenssl==17.5.0 nose-html-reporting==0.2.3 nose-testconfig==0.10 ConfigParser==3.5.0 xlsxwriter jinja2==2.10 pandas==0.21.0 openpyxl==2.4.9 appdirs==1.4.3 pexpect==4.3.0 xlrd==1.1.0 unittest2==1.1.0 networkx==2.0 vcrpy==1.11.1 pytest-cov==2.5.1 pytest-xdist==1.22.0 flask==0.12.2 bigsuds f5-sdk netaddr jsondiff

RUN pip install avisdk==${avi_sdk_version} avimigrationtools==${avi_sdk_version}
RUN ansible-galaxy -c install avinetworks.aviconfig avinetworks.avicontroller avinetworks.avicontroller-azure avinetworks.avicontroller-csp avinetworks.avicontroller-vmware avinetworks.avisdk avinetworks.avise  avinetworks.avise-csp avinetworks.docker avinetworks.network_interface avinetworks.avimigrationtools
RUN curl https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_linux_amd64.zip -o terraform_${tf_version}_linux_amd64.zip
RUN unzip terraform_${tf_version}_linux_amd64.zip -d /usr/local/bin
RUN mkdir -p $HOME/src/github.com/avinetworks/

RUN wget https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-server-v3.11.0-0cbc58b-linux-64bit.tar.gz
RUN tar xsvf openshift-origin-server-v3.11.0-0cbc58b-linux-64bit.tar.gz
RUN cp ./openshift-origin-server-v3.11.0-0cbc58b-linux-64bit/oc /usr/local/bin
RUN chmod +x /usr/local/bin/oc

RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN touch /etc/apt/sources.list.d/kubernetes.list
RUN echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubectl
RUN cd $HOME/src/github.com/avinetworks/ && git clone https://github.com/avinetworks/sdk.git && cd sdk && git checkout $avi_version

RUN echo "export ANSIBLE_LIBRARY=$HOME/.ansible/roles/avinetworks.avisdk/library" >> /etc/bash.bashrc
RUN export GOROOT=/usr/lib/go-1.9
RUN echo "export GOROOT=/usr/lib/go-1.9" >> /etc/bash.bashrc
RUN echo "export GOPATH=$HOME" >> /etc/bash.bashrc
RUN echo "export GOBIN=$HOME/bin" >> /etc/bash.bashrc
RUN export PATH=$PATH:/usr/lib/go-1.9/bin:$HOME/bin
RUN echo "export PATH=$PATH:/usr/lib/go-1.9/bin:$HOME/bin" >> /etc/bash.bashrc

RUN mkdir -p $HOME/src/github.com/hashicorp/terraform-provider-avi/vendor/github.com/avinetworks
RUN cd $HOME/src/github.com/hashicorp/terraform-provider-avi/vendor/github.com/avinetworks && git clone https://github.com/avinetworks/terraform-provider-avi.git
RUN /usr/lib/go-1.9/bin/go get github.com/avinetworks/sdk/go/session
RUN export PATH=$PATH:/usr/lib/go-1.9/bin && cd $HOME/src/github.com/hashicorp/terraform-provider-avi/vendor/github.com/avinetworks/terraform-provider-avi  && export GOPATH=$HOME && export GOBIN=$HOME/bin && make build
RUN mkdir -p $HOME/.terraform.d/plugins/ && ln -s $HOME/bin/terraform-provider-avi ~/.terraform.d/plugins/
RUN mkdir -p /opt/terraform
RUN cp -r /usr/lib/go-1.9/bin/* /usr/local/bin/
RUN cp $HOME/bin/terraform-provider-avi /usr/local/bin/
RUN touch list
RUN echo "#!/bin/bash" >> avitools-list
RUN echo "echo "f5_converter.py"" >> avitools-list
RUN echo "echo "netscaler_converter.py"" >> avitools-list
RUN echo "echo "gss_convertor.py"" >> avitools-list
RUN echo "echo "f5_discovery.py"" >> avitools-list
RUN echo "echo "avi_config_to_ansible.py"" >> avitools-list
RUN echo "echo "ace_converter.py"" >> avitools-list
RUN echo "echo "virtualservice_examples_api.py"" >> avitools-list
RUN echo "echo "config_patch.py"" >> avitools-list
RUN echo "echo "vs_filter.py"" >> avitools-list
RUN echo "echo "terraform-provider-avi"" >> avitools-list
RUN chmod +x avitools-list
RUN cp avitools-list /bin/
RUN cp avitools-list /usr/local/bin/
RUN echo "alias avitools-list=/bin/avitools-list" >> ~/.bashrc
ENV cmd cmd_to_run
CMD eval $cmd
