# STAGE 1 BUILD
FROM gradle:8.5.0-jdk17-alpine AS build
WORKDIR /usr/java-build/
COPY . /usr/java-build/
RUN gradle clean build --no-daemon

# STAGE 2 RUN
FROM eclipse-temurin:17-jre
WORKDIR /usr/java-app/
COPY --from=build /usr/java-build/build/libs/bootcamp-docker-java-mysql-project-1.0-SNAPSHOT.jar /usr/java-app/java-app.jar
ENTRYPOINT ["java", "-jar", "java-app.jar"]
