FROM openjdk:8-oraclelinux8

RUN microdnf install -y procps-ng findutils && microdnf update -y && microdnf clean all

ADD scripts /scripts
ADD jarFile /jarFile

WORKDIR /scripts
