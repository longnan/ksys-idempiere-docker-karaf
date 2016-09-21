#
# iDempiere-KSYS Dockerfile of Running iDempiere in Karaf OSGi
#
# https://github.com/longnan/ksys-idempiere-docker-karaf
#

### Pull base image.
FROM phusion/baseimage:0.9.19
MAINTAINER Ken Longnan <ken.longnan@gmail.com>

### Make default locale
RUN locale-gen en_US.UTF-8 && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale

### Setup fast apt in China
RUN echo "deb http://mirrors.163.com/ubuntu/ xenial main restricted universe multiverse \n" \
		 "deb http://mirrors.163.com/ubuntu/ xenial-security main restricted universe multiverse \n" \
	     "deb http://mirrors.163.com/ubuntu/ xenial-updates main restricted universe multiverse \n" \
		 "deb http://mirrors.163.com/ubuntu/ xenial-proposed main restricted universe multiverse \n" \
         "deb http://mirrors.163.com/ubuntu/ xenial-backports main restricted universe multiverse \n" \
		 "deb-src http://mirrors.163.com/ubuntu/ xenial main restricted universe multiverse \n" \
		 "deb-src http://mirrors.163.com/ubuntu/ xenial-security main restricted universe multiverse \n" \
		 "deb-src http://mirrors.163.com/ubuntu/ xenial-updates main restricted universe multiverse \n" \
		 "deb-src http://mirrors.163.com/ubuntu/ xenial-proposed main restricted universe multiverse \n" \
		 "deb-src http://mirrors.163.com/ubuntu/ xenial-backports main restricted universe multiverse \n" > /etc/apt/sources.list

### Update
RUN apt-get update

### Add ksys folder
ADD ksys /tmp/ksys
RUN mkdir /opt/idempiere-ksys;

### Default ENV
ENV IDEMPIERE_VERSION 4.0.0
ENV JDK8_FILE jdk-8u102-linux-x64.tar.gz
ENV KARAF_VERSION 4.0.6
ENV KARAF_FILE apache-karaf-${KARAF_VERSION}.tar.gz

### Setup IDEMPIERE_HOME (karaf_home)
ENV IDEMPIERE_HOME /opt/idempiere-ksys/
ENV KARAF_HOME ${IDEMPIERE_HOME}


### Install oracle JDK 8 (online model)
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
#RUN add-apt-repository -y ppa:webupd8team/java
#RUN apt-get update
#RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y oracle-java8-installer
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y oracle-java8-set-default

### Install oracle JDK 8 (offline model)
RUN mkdir -p /usr/lib/jvm/jdk1.8.0/;
RUN tar --strip-components=1 -C /usr/lib/jvm/jdk1.8.0 -xzvf /tmp/ksys/${JDK8_FILE};
RUN update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/jdk1.8.0/bin/java" 1
RUN update-alternatives --install "/usr/bin/javac" "javac" "/usr/lib/jvm/jdk1.8.0/bin/javac" 1
RUN update-alternatives --install "/usr/bin/javaws" "javaws" "/usr/lib/jvm/jdk1.8.0/bin/javaws" 1
#RUN java -version
RUN rm /tmp/ksys/${JDK8_FILE};

### Setup JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/jdk1.8.0/
ENV PATH $JAVA_HOME/bin:$PATH
ENV JAVA_MIN_MEM 512M
ENV JAVA_MAX_MEM 1024M

### Enabling SSH
RUN rm -f /etc/service/sshd/down
### Enabling the insecure key permanently. In production environments, you should use your own keys.
RUN /usr/sbin/enable_insecure_key

### Install needed tools & packages
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget unzip pwgen expect

### Install Apache Karaf (online model)
#ENV KARAF_VERSION 4.0.1
#RUN wget http://archive.apache.org/dist/karaf/${KARAF_VERSION}/apache-karaf-${KARAF_VERSION}.tar.gz -O /tmp/karaf.tar.gz
#RUN tar --strip-components=1 -C /opt/idempiere-ksys -xzvf /tmp/karaf.tar.gz
#RUN rm /tmp/karaf.tar.gz

### Install Apache Karaf (offline model)
RUN tar --strip-components=1 -C /opt/idempiere-ksys -xzvf /tmp/ksys/${KARAF_FILE}
RUN rm /tmp/ksys/${KARAF_FILE}

### Setup and configure Karaf to support SSL + http2, add features for iDempiere-KSYS
RUN mv /tmp/ksys/etc/custom.properties ${KARAF_HOME}/etc;
RUN mv /tmp/ksys/etc/karaf_maven_settings.xml ${KARAF_HOME}/etc;
RUN mv /tmp/ksys/etc/org.ops4j.pax.url.mvn.cfg ${KARAF_HOME}/etc;
RUN mv /tmp/ksys/etc/org.ops4j.pax.web.cfg ${KARAF_HOME}/etc;
RUN mv /tmp/ksys/etc/jetty.xml /${KARAF_HOME}/etc;
#RUN mv /tmp/ksys/etc/org.apache.karaf.features.cfg ${KARAF_HOME}/etc;

### Add SSL Keystore
RUN mv /tmp/ksys/etc/ksys-demo-keystore ${KARAF_HOME}/etc;
#RUN mv /tmp/ksys/etc/users.properties ${KARAF_HOME}/etc;

### Add iDempiere-KSYS rebranding
RUN mv /tmp/ksys/etc/branding.properties ${KARAF_HOME}/etc;
#RUN mv /tmp/ksys/com.kylinsystems.idempiere.karaf.branding-${IDEMPIERE_VERSION}.jar ${KARAF_HOME}/lib/;

#ENV KARAF_OPTS "-Djava.net.preferIPv4Stack=true"
#ENV KARAF_OPTS -javaagent:/$KARAF_HOME/jolokia-agent.jar=host=0.0.0.0,port=8778,authMode=jaas,realm=karaf,user=admin,password=admin,agentId=$HOSTNAME
ENV PATH $PATH:${KARAF_HOME}/bin

### Add default iDempiere-KSYS properties files
RUN mv /tmp/ksys/idempiere.properties ${IDEMPIERE_HOME};
RUN mv /tmp/ksys/home.properties ${IDEMPIERE_HOME};

### Copy whole idempiere-server package, only folder plugins/* will be needed for karaf
RUN unzip -d ${IDEMPIERE_HOME} /tmp/ksys/idempiereServer.gtk.linux.x86_64.zip
RUN rm /tmp/ksys/idempiereServer.gtk.linux.x86_64.zip

### Copy ksys-repository to karaf, this folder will be added as defaultRepositories for karaf
RUN unzip -d ${IDEMPIERE_HOME} /tmp/ksys/ksys-repository-${IDEMPIERE_VERSION}-on-karaf-${KARAF_VERSION}.zip
RUN rm /tmp/ksys/ksys-repository-${IDEMPIERE_VERSION}-on-karaf-${KARAF_VERSION}.zip

### Apply ZK-Patch
RUN mv /tmp/ksys/zk-patch/zk_8.0.1.1.jar ${IDEMPIERE_HOME}/idempiere.gtk.linux.x86_64/idempiere-server/plugins;

### Clean tmp/ksys
RUN rm -rf /tmp/ksys

EXPOSE 1099 8181 8443 8101 44444

### Add daemon to be run by runit.
#RUN chmod +x ${KARAF_HOME}/bin/karaf
RUN mkdir /etc/service/ksys-idempiere-karaf-server
RUN ln -s ${KARAF_HOME}/bin/karaf /etc/service/ksys-idempiere-karaf-server/run

### Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

### Start iDempiere-KSYS Karaf
#ENTRYPOINT ["/opt/idempiere-ksys/bin/karaf"]
