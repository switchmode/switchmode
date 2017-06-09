FROM node:argon

# Accept EULA for Microsoft fonts
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
RUN echo deb http://httpredir.debian.org/debian jessie main contrib non-free > /etc/apt/sources.list

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y make unoconv ttf-mscorefonts-installer
RUN fc-cache -f

WORKDIR /workdir

COPY package.json /workdir/package.json
COPY package-lock.json /workdir/package-lock.json
RUN npm install

COPY . /workdir

CMD /usr/bin/unoconv --listener && make
