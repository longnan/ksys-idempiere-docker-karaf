#
# iDempiere-KSYS Dockerfile of Running iDempiere in Karaf OSGi
#
# https://github.com/longnan/ksys-idempiere-docker-karaf
#

# Pull base image.
FROM phusion/baseimage:0.9.18
MAINTAINER Ken Longnan <ken.longnan@gmail.com>

# Make default locale
RUN locale-gen en_US.UTF-8 && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale

# Setup proxy if needed
#ENV http_proxy http://10.0.0.12:8087/
#ENV https_proxy http://10.0.0.12:8087/
#RUN export http_proxy=$http_proxy
#RUN export https_proxy=$https_proxy

# Setup fast apt in China
RUN echo "deb http://mirrors.163.com/ubuntu/ trusty main restricted universe multiverse \n" \
		 "deb http://mirrors.163.com/ubuntu/ trusty-security main restricted universe multiverse \n" \
	     "deb http://mirrors.163.com/ubuntu/ trusty-updates main restricted universe multiverse \n" \
		 "deb http://mirrors.163.com/ubuntu/ trusty-proposed main restricted universe multiverse \n" \
         "deb http://mirrors.163.com/ubuntu/ trusty-backports main restricted universe multiverse \n" \
		 "deb-src http://mirrors.163.com/ubuntu/ trusty main restricted universe multiverse \n" \
		 "deb-src http://mirrors.163.com/ubuntu/ trusty-security main restricted universe multiverse \n" \
		 "deb-src http://mirrors.163.com/ubuntu/ trusty-updates main restricted universe multiverse \n" \
		 "deb-src http://mirrors.163.com/ubuntu/ trusty-proposed main restricted universe multiverse \n" \
		 "deb-src http://mirrors.163.com/ubuntu/ trusty-backports main restricted universe multiverse \n" > /etc/apt/sources.list		 

# Update
RUN apt-get update		 

# Add ksys folder
ADD ksys /tmp/ksys
RUN mkdir /opt/idempiere-ksys;

# Default ENV 
ENV IDEMPIERE_VERSION 4.0.0
ENV JDK8_FILE jdk-8u92-linux-x64.tar.gz
ENV KARAF_VERSION 4.0.5
ENV KARAF_FILE apache-karaf-${KARAF_VERSION}.tar.gz
		 
# Install openJDK 7
#RUN apt-get install -q -y openjdk-7-jre-headless openjdk-7-jdk

# Install oracle JDK 8 (online model)
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
#RUN add-apt-repository -y ppa:webupd8team/java
#RUN apt-get update
#RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y oracle-java8-installer
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y oracle-java8-set-default

# Install oracle JDK 8 (offline model)
RUN mkdir -p /usr/lib/jvm/jdk1.8.0/;
RUN tar --strip-components=1 -C /usr/lib/jvm/jdk1.8.0 -xzvf /tmp/ksys/${JDK8_FILE};
RUN update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/jdk1.8.0/bin/java" 1
RUN update-alternatives --install "/usr/bin/javac" "javac" "/usr/lib/jvm/jdk1.8.0/bin/javac" 1
RUN update-alternatives --install "/usr/bin/javaws" "javaws" "/usr/lib/jvm/jdk1.8.0/bin/javaws" 1
RUN java -version
RUN rm /tmp/ksys/${JDK8_FILE};

# Setup JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/jdk1.8.0/
ENV PATH $JAVA_HOME/bin:$PATH
# Minimum memory for the JVM
ENV JAVA_MIN_MEM 256M
# Maximum memory for the JVM
ENV JAVA_MAX_MEM 1024M

# Enabling SSH
RUN rm -f /etc/service/sshd/down
# Enabling the insecure key permanently. In production environments, you should use your own keys.
RUN /usr/sbin/enable_insecure_key

# Install needed tools & postgresql-client (optional)
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget unzip pwgen expect
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes postgresql-client-9.3

# Install Apache Karaf (online model)
#ENV KARAF_VERSION 4.0.1
#RUN wget http://archive.apache.org/dist/karaf/${KARAF_VERSION}/apache-karaf-${KARAF_VERSION}.tar.gz -O /tmp/karaf.tar.gz
#RUN tar --strip-components=1 -C /opt/idempiere-ksys -xzvf /tmp/karaf.tar.gz
#RUN rm /tmp/karaf.tar.gz

# Install Apache Karaf (offline model)
RUN tar --strip-components=1 -C /opt/idempiere-ksys -xzvf /tmp/ksys/${KARAF_FILE}
RUN rm /tmp/ksys/${KARAF_FILE}

# Update karaf etc configuration
RUN mv /tmp/ksys/etc/custom.properties /opt/idempiere-ksys/etc;
RUN mv /tmp/ksys/etc/karaf_maven_settings.xml /opt/idempiere-ksys/etc;
RUN mv /tmp/ksys/etc/org.ops4j.pax.url.mvn.cfg /opt/idempiere-ksys/etc;
#RUN mv /tmp/ksys/etc/org.apache.karaf.features.cfg /opt/idempiere-ksys/etc;

# Add karaf rebranding jar 
# Customization for ksys-idempiere rebranding
RUN mv /tmp/ksys/com.kylinsystems.idempiere.karaf.branding-${IDEMPIERE_VERSION}.jar /opt/idempiere-ksys/lib/;

# Add idempiere-ksys properties file as default
RUN mv /tmp/ksys/idempiere.properties /opt/idempiere-ksys/;

# Copy idempiere-server package, only plugins/* will be needed for karaf
RUN unzip -d /opt/idempiere-ksys /tmp/ksys/idempiereServer.gtk.linux.x86_64.zip
RUN rm /tmp/ksys/idempiereServer.gtk.linux.x86_64.zip

# Copy ksys-repository to karaf, this folder will be added as defaultRepositories for karaf
RUN unzip -d /opt/idempiere-ksys /tmp/ksys/ksys-repository-${IDEMPIERE_VERSION}-on-karaf-${KARAF_VERSION}.zip
RUN rm /tmp/ksys/ksys-repository-${IDEMPIERE_VERSION}-on-karaf-${KARAF_VERSION}.zip

# Setup IDEMPIERE_HOME (karaf_home)
ENV IDEMPIERE_HOME /opt/idempiere-ksys/

# Clean tmp/ksys
RUN rm -rf /tmp/ksys

EXPOSE 1099 8181 8101 44444

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Start iDempiere-KSYS Karaf
#ENTRYPOINT ["/opt/idempiere-ksys/bin/karaf"]