# Stage 1: Build Java Spring Boot với Maven
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

# Stage 2: Chạy ứng dụng Java
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/PRM393GenZ-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
