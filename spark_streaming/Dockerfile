FROM spark:3.5.3-scala2.12-java17-ubuntu

USER root

# Cài đặt Python và pip
RUN set -ex; \
    apt-get update; \
    apt-get install -y python3 python3-pip; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Cho phép quyền ghi cho thư mục /app
RUN chmod -R 777 /app

# Copy mã nguồn và cài đặt các thư viện
COPY . .

RUN pip3 install --no-cache-dir -r requirements.txt
