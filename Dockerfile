# FHIR VAD: Validator + 網頁介面（多階段可選，此為單一映像）
FROM eclipse-temurin:17-jre-jammy

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 建置時下載 validator_cli.jar
ARG VALIDATOR_URL=https://github.com/hapifhir/org.hl7.fhir.core/releases/latest/download/validator_cli.jar
RUN curl -fSL -o validator_cli.jar "${VALIDATOR_URL}"

# 複製應用檔案
COPY ig-config.js index.html app.js styles.css README.md ./
COPY serve_with_proxy.py start_validator.py ./

EXPOSE 8080 5500

# 預設僅啟動 validator（docker-compose 會覆寫各服務的 command）
CMD ["python3", "start_validator.py", "--port", "8080"]
