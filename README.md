# **Soft Real-time Bank Transfer Fraud Detection Pipeline**

Dự án này là một đường ống phát hiện gian lận giao dịch chuyển khoản ngân hàng thời gian thực (1s) được triển khai trên k8s tự động bằng Terraform.  
Nó là một hệ thống giám sát giao dịch chuyển khoản trong ngân hàng, đưa ra cảnh báo cho đội ngũ giám sát hệ thống về giao dịch đáng ngờ, tăng khả năng ứng phó, xử lý nhanh với tình huống xấu và giảm thiểu lừa đảo.  
Nguồn phát dữ liệu là một Realtime API giả lập xuất ra dữ liệu giao dịch chuyển khoản của nhiều người dùng trong thời gian nhất định, mỗi 1s lại trả về một tập giao dịch, thu thập nó bằng Kafka, xử lý nhận diện giao dịch đáng ngờ bằng Spark Streaming, đẩy dữ liệu số giao dịch đáng ngờ lên Pushgateway để Prometheus thu thập, cảnh báo vượt ngưỡng giới hạn số giao dịch đáng ngờ bằng Alert Manager và gửi cảnh báo đến Email, trực quan hoá biểu đồ theo thời gian thực để theo dõi số giao dịch đáng ngờ, lưu dữ liệu vào Cassandra.  

## **Architecture**
![Pipeline Image](https://github.com/user-attachments/assets/1d9bc6df-e5cb-4a3d-9240-38752102421d)

## **Dashboard**

![recording-2025-04-04-20-43-13online-video-cutter com-ezgif com-crop](https://github.com/user-attachments/assets/8ec9cc5a-74cd-402e-ab61-b3ae97847f79)


## **Spark Performance - Processing Latency <1s (~800ms)**

![Screenshot 2025-04-04 204936](https://github.com/user-attachments/assets/5e63eade-e7d2-4a79-9a87-bd0698dca257)


## **Alert - Alert Email**

![image](https://github.com/user-attachments/assets/ce0422ed-39db-4b69-b39b-f3829f44d0b0)


## **Setup & Deployment**

### 1. Yêu cầu:
- Terraform
- Minikube (tối thiểu 6-cpu, 11g-memory)

### 2. Triển khai:
```bash
minikube start --cpus=6 --memory=11g
rm -rf .terraform
terraform init
terraform plan
terraform apply -auto-approve
terraform destroy -auto-approve  # (nếu cần gỡ cài đặt pipeline)

## **Potential Improvements**

1. Nâng cao thuật toán nhận diện. Đây mới là bản cơ sở của hệ thống nhận diện giao dịch đáng ngờ, mục tiêu của tôi vẫn là xây dựng một ml model trong tương lai phục vụ cho việc nhận diện. Đó là lí do tại sao tôi lại lưu dữ liệu ra Cassandra
2. CI/CD
3. Nâng cấp cấu hình hệ thống, mutil node -> nâng cao khả năng xử lý Spark với dữ liệu lớn
4. Tích hợp Apache Yunikorn -> nâng cao khả năng xử lý Spark với dữ liệu lớn
5. Cải thiện khả năng bảo mật
6. OOP các file python -> tăng khả năng mở rộng kế thừa cho các phần khác, dự án khác
7. Kết hợp thêm nhiều hệ thông giám sát khác
