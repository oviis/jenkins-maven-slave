FROM alpine:3.4
MAINTAINER ovidiu.isai@gmail.com

ENV JENKINS_HOME /home/jenkins
ENV JENKINS_REMOTNG_VERSION 2.7.1
ENV JAVA_VERSION 8u92
ENV JAVA_ALPINE_VERSION 8.92.14-r1
ENV MAVEN_VERSION 3.3.9

# Install requirements
RUN apk --update add \
    curl \
    bash \
    git \
    openssh

# compile and install jdk 8
# A few problems with compiling Java from source:
#  1. Oracle.  Licensing prevents us from redistributing the official JDK.
#  2. Compiling OpenJDK also requires the JDK to be installed, and it gets
#       really hairy.

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
        echo '#!/bin/sh'; \
        echo 'set -e'; \
        echo; \
        echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
    } > /usr/local/bin/docker-java-home \
    && chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin


RUN set -x \
    && apk add --no-cache \
        openjdk8="$JAVA_ALPINE_VERSION" \
&& [ "$JAVA_HOME" = "$(docker-java-home)" ] 

# Install maven 
RUN wget http://mirror2.shellbot.com/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    tar -zxf apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    mv apache-maven-${MAVEN_VERSION} /usr/local && \
    rm -f apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
ln -s /usr/local/apache-maven-${MAVEN_VERSION}/bin/mvn /usr/bin/mvn

ENV HOME /home/jenkins
# Add jenkins user
RUN adduser -D -h $JENKINS_HOME -s /bin/sh jenkins jenkins \
    && chmod a+rwx $JENKINS_HOME 

RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar http://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/2.52/remoting-2.52.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar

USER jenkins
COPY jenkins-slave /usr/local/bin/jenkins-slave
USER root
RUN chmod +x /usr/local/bin/jenkins-slave

VOLUME /home/jenkins
WORKDIR /home/jenkins
USER jenkins

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]

