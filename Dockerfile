# Creates pseudo distributed hadoop 2.6.0 on Ubuntu 14.04
#
# docker build -t sequenceiq/hadoop-ubuntu:2.6.0 .

FROM ubuntu:15.04
MAINTAINER Randall Mason <randall@mason.ch>

RUN echo 'Acquire::http { Proxy "http://192.168.1.152:3142"; }; Acquire::ForceIPv4 "true"; APT::Install-Recommends "0"; APT::Install-Suggests "0";' >> /etc/apt/apt.conf
#RUN echo -e "debconf shared/accepted-oracle-license-v1-1 select true\ndebconf shared/accepted-oracle-license-v1-1 seen true" | /usr/bin/debconf-set-selections

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -q -y git curl build-essential ssh rsync tar default-jdk

# passwordless ssh, very insecure, anybody can decrypt all traffic because private keys are publicly known.
RUN rm -f /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_rsa_key /root/.ssh/id_rsa
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

ENV JAVA_HOME /usr/lib/jvm/default-java/
ENV PATH $PATH:$JAVA_HOME/bin
ENV HADOOP_VERSION 2.7.1

# hadoop
RUN curl -OLs https://dist.apache.org/repos/dist/release/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz.asc
RUN curl -Os $(curl -s http://www.apache.org/dyn/closer.cgi/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz | grep -A3 -i " suggest " | grep strong | sed -e 's/.*<strong>//g' -e 's/<\/strong>.*//g')
RUN gpg -k
RUN gpg --recv-keys "6AE7 0A2A 38F4 66A5 D683  F939 255A DF56 C36C 5F0F"
RUN gpg --no-options --no-auto-check-trustdb --verify hadoop-${HADOOP_VERSION}.tar.gz.asc || exit 1
RUN tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /usr/local/
RUN cd /usr/local && ln -s ./hadoop-${HADOOP_VERSION} hadoop

ENV HADOOP_PREFIX /usr/local/hadoop
RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/default-java\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
#RUN . $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

# pseudo distributed
ADD core-site.xml  $HADOOP_PREFIX/etc/hadoop/core-site.xml
ADD yarn-site.xml  $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
ADD hdfs-site.xml  $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
ADD mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml

RUN sed -i 's/NUMBEROFNODES/2/g' $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

RUN $HADOOP_PREFIX/bin/hdfs namenode -format

# fixing the libhadoop.so like a boss, insecure, transfer of files over http without verification leads to rootkits...  I prefer a little less performance than insecurity
#RUN rm  /usr/local/hadoop/lib/native/*
#RUN curl -Ls http://dl.bintray.com/sequenceiq/sequenceiq-bin/hadoop-native-64-2.6.0.tar|tar -x -C /usr/local/hadoop/lib/native/

ADD ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config

# # installing supervisord
# RUN yum install -y python-setuptools
# RUN easy_install pip
# RUN curl https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -o - | python
# RUN pip install supervisor
#
# ADD supervisord.conf /etc/supervisord.conf

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

ENV BOOTSTRAP /etc/bootstrap.sh

# workingaround docker.io build error
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh
RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "Port 2122" >> /etc/ssh/sshd_config


#RUN service ssh start && \
#    $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && \
#    $HADOOP_PREFIX/sbin/start-dfs.sh && \
#    $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/root && \
#    $HADOOP_PREFIX/bin/hdfs dfs -put $HADOOP_PREFIX/etc/hadoop/ input && \
#    $HADOOP_PREFIX/sbin/stop-dfs.sh

ENTRYPOINT ["/etc/bootstrap.sh"]
CMD ["ssh", "dfs", "yarn", "-d" ]

EXPOSE 50020 50090 50070 50010 50075 8031 8032 8033 8040 8042 49707 22 8088 8030
