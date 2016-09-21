ksys-idempiere-docker-karaf
=======================

Base docker image to run iDempiere-KSYS (v4.0 dev) inside Apache Karaf

Usage
-----

To create the image `longnan/ksys-idempiere-docker-karaf`, execute the following command on the ksys-idempiere-docker-karaf folder:

	docker build --rm --force-rm -t longnan/ksys-idempiere-docker-karaf:4.0.0.yyyymmdd .

To save/load image:

	# save image to tarball
	$ sudo docker save longnan/ksys-idempiere-docker-karaf:4.0.0.yyyymmdd | gzip > ksys-idempiere-docker-karaf-4.0.0.yyyymmdd.tar.gz

	# load it back
	$ sudo gzcat ksys-idempiere-docker-karaf-4.0.0.yyyymmdd.tar.gz | docker load

Download prepared images from:

	https://sourceforge.net/projects/idempiereksys/files/idempiere-ksys-docker-image/4.0/

To run the image:

	# run ksys-idempiere-pgsql
	docker volume rm ksys-idempiere-pgsql-datastore
	docker volume create --name ksys-idempiere-pgsql-datastore
	docker volume inspect ksys-idempiere-pgsql-datastore
	docker run -d --name="ksys-idempiere-pgsql" -v ksys-idempiere-pgsql-datastore:/data -p 5432:5432 -e PASS="postgres" longnan/ksys-idempiere-docker-pgsql:3.1.0.yyyymmdd
	docker logs -f ksys-idempiere-pgsql

	# run ksys-idempiere-karaf
	docker run -d -t --link ksys-idempiere-pgsql:idempiere-db --name="ksys-idempiere-karaf" -p 80:8181 -p 443:8443 longnan/ksys-idempiere-docker-karaf:4.0.0.yyyymmdd
	docker logs -f ksys-idempiere-karaf

To check the container log:

	docker logs ksys-idempiere-karaf
	docker logs -f ksys-idempiere-karaf

To re-start the container from last stop:

	docker start ksys-idempiere-pgsql
	docker start ksys-idempiere-karaf

To access idempiere web-ui:

	# iDempiere WebUI:
	http://docker-host-ip

	# iDempiere WebService/ADInterface:
	http://docker-host-ip/ADInterface/services/

	# iDempiere Server Management:
	http://docker-host-ip/server

	# Hawtio Console:
	http://docker-host-ip/hawtio/
	https://localhost:8443/hawtio

	# Karaf Webconsole
	http://docker-host-ip/system/console

	# ActiveMQ Web Console:
	http://docker-host-ip/activemqweb/

To SSH container:

	# Download the insecure private key
	curl -o insecure_key -fSL https://github.com/phusion/baseimage-docker/raw/master/image/services/sshd/keys/insecure_key
	chmod 600 insecure_key

	# Login to the container
	ssh -i insecure_key root@$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" ksys-idempiere-karaf)

	# Install iDempiere-KSYS feature manually in Karaf:
	karaf@root()> feature:repo-add mvn:com.kylinsystems.idempiere.karaf/com.kylinsystems.idempiere.karaf.feature/4.0.0/xml/features
	karaf@root()> feature:install -v com.kylinsystems.idempiere.karaf.base
	karaf@root()> feature:install -v com.kylinsystems.idempiere.karaf.app

Other Packages
----
The following packages are needed to build docker image, but too big to be committed to github

	jdk-8uxxx-linux-x64.tar.gz
	idempiereServer.gtk.linux.x86_64.zip
	apache-karaf-4.0.x.tar.gz
	ksys-repository-4.0.0-on-karaf-4.0.x.zip

Please download them from:

	https://sourceforge.net/projects/idempiereksys/files/idempiere-ksys/


Pending Issues
----
1. Remove web-fragment.xml from zk.jar (hacked zk.jar included)
	https://bugs.eclipse.org/bugs/show_bug.cgi?id=442488
	Multiple servlets map to path: /zkau/*: auEngine,DHtmlUpdateServlet

2. Replace MANIFEST.MF in idempiere zk ui due to atmosphere-runtime issue

3. override-web.xml not working in Karaf Jetty

4. https://ops4j1.jira.com/browse/PAXWEB-959

SSL for Karaf Jetty
----
	$openssl genrsa -aes128 -out ksys-server-demo.key 1024

P@ssw0rd

	$openssl req -new -key ksys-server-demo.key -out ksys-server-demo.csr

-----
Country Name (2 letter code) [AU]:CN
State or Province Name (full name) [Some-State]:Shanghai
Locality Name (eg, city) []:Shanghai
Organization Name (eg, company) [Internet Widgits Pty Ltd]:KSYS
Organizational Unit Name (eg, section) []:iDempiere
Common Name (e.g. server FQDN or YOUR name) []:demo.idempiere.ksys
Email Address []:

	$openssl x509 -req -days 3650 -in ksys-server-demo.csr -signkey ksys-server-demo.key -out ksys-server-demo.crt
	$openssl pkcs12 -inkey ksys-server-demo.key -in ksys-server-demo.crt -export -out ksys-server-demo.pkcs12
	$keytool -importkeystore -srckeystore ksys-server-demo.pkcs12 -srcstoretype PKCS12 -destkeystore ksys-demo-keystore
	$keytool -list -v -keystore ksys-demo-keystore
