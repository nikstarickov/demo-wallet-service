# ============================================
# BUILD STAGE (Microsoft JDK)
# ============================================
FROM mcr.microsoft.com/openjdk/jdk:17-mariner AS builder

# Устанавливаем Maven (Mariner использует tdnf вместо apt)
RUN tdnf install -y maven curl ca-certificates && \
    tdnf clean all

WORKDIR /app
COPY pom.xml .
COPY src ./src

RUN mvn dependency:go-offline -B
RUN mvn clean package -DskipTests -DskipITs

# ============================================
# DEVELOPMENT STAGE (Microsoft JDK для разработки)
# ============================================
FROM mcr.microsoft.com/openjdk/jdk:17-mariner AS dev

# Устанавливаем dev-утилиты
RUN tdnf install -y \
    curl \
    git \
    procps-ng \
    vim \
    && tdnf clean all

# Настройка пользователя (важно для прав файлов)
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g ${GROUP_ID} spring && \
    useradd -u ${USER_ID} -g spring -m -s /bin/bash spring

USER spring:spring
WORKDIR /app

# Копируем JAR
COPY --from=builder --chown=spring:spring /app/target/*.jar app.jar

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080 5005 35729

ENTRYPOINT ["java", \
    "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005", \
    "-Dspring.devtools.restart.enabled=true", \
    "-Dspring.devtools.livereload.enabled=true", \
    "-Dspring.devtools.restart.trigger-file=.trigger", \
    "-jar", "/app/app.jar"]

# Или для Maven-based hot reload (альтернатива):
# CMD ["mvn", "spring-boot:run", \
#      "-Dspring-boot.run.arguments=--spring.profiles.active=dev", \
#      "-Dspring-boot.run.jvmArguments=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"]

# ============================================
# PRODUCTION STAGE (JRE только для production)
# ============================================
FROM mcr.microsoft.com/openjdk/jre:17-mariner AS runner

# Создаем пользователя для безопасности
RUN groupadd -r spring && useradd -r -g spring spring
USER spring:spring

WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC"
ENTRYPOINT exec java ${JAVA_OPTS} -jar /app/app.jar