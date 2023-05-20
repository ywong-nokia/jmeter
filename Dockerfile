# inspired by https://github.com/hauptmedia/docker-jmeter  and
# https://github.com/hhcordero/docker-jmeter-server/blob/master/Dockerfile and
# https://github.com/justb4/docker-jmeter
FROM amazoncorretto:11-alpine3.17

ARG JMETER_VERSION="5.5"
ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}
ENV	JMETER_BIN	${JMETER_HOME}/bin
ENV	JMETER_DOWNLOAD_URL  https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz

# Install extra packages
# See https://github.com/gliderlabs/docker-alpine/issues/136#issuecomment-272703023
# Change TimeZone TODO: TZ still is not set!
ARG TZ="Europe/Amsterdam"
RUN    apk update \
	&& apk upgrade \
	&& apk add ca-certificates \
	&& update-ca-certificates \
	&& apk add --update openjdk11-jre tzdata curl unzip bash \
	&& apk add --no-cache nss \
	&& rm -rf /var/cache/apk/* \
	&& mkdir -p /tmp/dependencies  \
	&& curl -L --silent ${JMETER_DOWNLOAD_URL} >  /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz  \
	&& mkdir -p /opt  \
	&& tar -xzf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt  \
	&& rm -rf /tmp/dependencies

# TODO: plugins (later)
# && unzip -oq "/tmp/dependencies/JMeterPlugins-*.zip" -d $JMETER_HOME

# Set global PATH such that "jmeter" command is found
ENV PATH $PATH:$JMETER_BIN

# Download the lastest org.json jar (used in JSR223 processors to interact with json) to {JMETER_ROOT}/lib
RUN export DOWNLOAD_URL=$(wget -qO- https://github.com/stleary/JSON-java | grep -o 'href="[^"]*"' | sed 's/href="//' | grep '.*jar"' | sed 's/"$//' | head -n1) \
    && wget -O ${JMETER_HOME}/lib/$(basename $DOWNLOAD_URL) $DOWNLOAD_URL \
    && unset DOWNLOAD_URL

# Download amazon SDK and add the jar files from lib and third-party/lib to {JMETER_ROOT}/lib.
RUN curl -L -o /tmp/aws-java-sdk.zip "https://sdk-for-java.amazonwebservices.com/latest/aws-java-sdk.zip" \
    && unzip -qq /tmp/aws-java-sdk.zip -d /tmp/aws-sdk \
    && cp -R /tmp/aws-sdk/lib/*.jar ${JMETER_HOME}/lib \
    && rm -rf /tmp/aws-java-sdk.zip /tmp/aws-sdk

# Entrypoint has same signature as "jmeter" command
COPY entrypoint.sh /

WORKDIR	${JMETER_HOME}

ENTRYPOINT ["/entrypoint.sh"]
