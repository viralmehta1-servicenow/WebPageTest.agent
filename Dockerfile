### IMPORTANT DOCKER COMMANDS ###

###     docker images                               - List images available
###     docker build <GITHUB-REPO-LINK> -t TAGNAME  - Builds the Dockerfile from the github repo
###     docker ps                                   - List running images
###     docker stop <IMAGE ID || IMAGE NAME>        - Stops running image with either --name <IMAGE NAME> || IMAGE ID>
###     docker run -it -d TAGNAME /bin/bash         - Runs bash
###     docker exec -it <IMAGE ID> /bin/bash        - Connects to bash for terminal execution (Needs to be running first)

### EXAMPLE DOCKER COMMANDS FOR RUNNING SERVER & AGENT

###     docker run -d -p 4000:80 <IMAGE ID || <IMAGE TAG>
###     docker run -d -p 4001:80 --network="host" -e "SERVER_URL=http://localhost:4000/work/" -e "LOCATION=Test" -e "-v" <IMAGE ID || <IMAGE TAG>

### INSTALLING METHOD ###

###     Recommend to install with "docker build <GITHUB-REPO-LINK> -t TAGNAME",
###     grabs the latest copy of WPT and build time on average takes 10 minutes. 

FROM --platform=linux/amd64 ubuntu:22.04 as base

### PREVENTs INTERACTIVE PROMPTS WHILE INSTALLING ###
ARG DEBIAN_FRONTEND=noninteractive


### UPDATE ###
RUN apt-get update 

### INSTALL APT-GET LIBS ###
RUN apt-get install -y \
    python3 python3-pip python3-ujson \
    sudo curl xvfb imagemagick dbus-x11 traceroute software-properties-common psmisc libnss3-tools iproute2 net-tools openvpn \
    libtiff5-dev libjpeg-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python3-tk \
    python3-dev libavutil-dev libmp3lame-dev libx264-dev yasm autoconf automake build-essential libass-dev libfreetype6-dev libtheora-dev \
    libtool libvorbis-dev pkg-config texi2html libtext-unidecode-perl python3-numpy python3-scipy perl \
    adb ethtool cmake git-core libsdl2-dev libva-dev libvdpau-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev texinfo wget \
    ttf-mscorefonts-installer fonts-noto fonts-roboto fonts-open-sans ffmpeg npm

RUN apt remove nodejs-doc -y && \
    apt remove nodejs -y && \
    sudo apt autoremove -y

RUN apt-get update && \
    apt-get install -y ca-certificates curl gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

RUN NODE_MAJOR=20 && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

RUN apt-get update && \
    apt-get install nodejs -y

### INSTALLING LIGHTHOUSE FROM NPM ###
#RUN npm install -g lighthouse


### BETTER INSTALLING CHROME BROWSER METHOD ###
###     Better Installing method but would like to change this to something less complex.
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
RUN apt-get update && apt-get -y install google-chrome-stable ; exit 0
RUN apt-get update --fix-missing -y
RUN apt-get install -f -y

# Set repos
RUN add-apt-repository -y ppa:ubuntu-mozilla-daily/ppa && \
# Install browsers
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq \
  firefox-trunk

RUN wget https://ftp.mozilla.org/pub/firefox/releases/114.0/linux-x86_64/en-US/firefox-114.0.tar.bz2 && \
    tar -xvjf firefox-114.0.tar.bz2 && \
    cp -r firefox/* /usr/bin/


RUN wget https://github.com/mozilla/geckodriver/releases/download/v0.31.0/geckodriver-v0.31.0-linux64.tar.gz && \
    gunzip -f geckodriver-v0.31.0-linux64.tar.gz  && \
    tar -xvf geckodriver-v0.31.0-linux64.tar && \
    mv geckodriver /usr/bin/ 


### Update the font cache
RUN fc-cache -f -v


RUN mkdir -p /wptagent/.github/workflows/

COPY /.github/workflows/requirements.txt /wptagent/.github/workflows/requirements.txt
RUN mkdir /python_modules

ENV PYTHONUSERBASE=/python_modules/
ENV PYTHONPATH="${PYTHONUSERBASE}"
ENV PATH="${PATH}:${PYTHONPATH}/bin"

### UPGRADING PIP AND INSTALLING REQUIRED PACKAGES ###
RUN python3 -m pip install --upgrade --user pip && \
    python3 -m pip install --user -r /wptagent/.github/workflows/requirements.txt 


RUN ln -sf /bin/bash /bin/sh


FROM base AS source
COPY / /wptagent
WORKDIR /wptagent


FROM source as debugger
RUN pip install debugpy

#ENTRYPOINT [ "python","-m","debugpy","--listen","0.0.0.0:5678", "--wait-for-client", "-m","--server", "http://localhost:81/work/", "--location", "Test" ,"--har" ,"--healthcheckport=8887", "--name", "OOB_WPT_Agent", "--shaper", "chrome", "--xvfb", "--dockerized", "-vvvvv", "wptagent.py" ]
#ENTRYPOINT [ "python","-m","debugpy","--listen","0.0.0.0:5678", "--wait-for-client", "-m" ]
CMD ["tail", "-f","/dev/null"]

FROM source as primary
### /bin/bash LOCATION OF COMMAND EXECUTION ###
#CMD ["/bin/bash", "/wptagent/docker/linux-headless/entrypoint.sh"]
CMD ["tail", "-f","/dev/null"]
