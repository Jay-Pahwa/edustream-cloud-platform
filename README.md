# 🎬 EduStream — Cloud-Native Video Streaming Platform

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=for-the-badge&logo=jenkins&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)

An end-to-end cloud-native video streaming and educational platform engineered with **Python microservices**, automated **Jenkins CI/CD pipelines**, and **Infrastructure as Code (IaC)** deployed across a multi-AZ AWS environment using **Terraform**.

---

## 🌟 Key Features

- **Microservices Architecture**: Decoupled user-facing streaming and backend video ingestion into independent containerized services.
- **High Availability & Fault Tolerance**: Multi-Availability Zone deployment on AWS utilizing public, web, and data subnets.
- **Automated CI/CD Delivery**: Declarative Jenkins pipeline automating container builds, Docker image tagging, AWS ECR publishing, and deployment.
- **Infrastructure as Code (IaC)**: Modular Terraform configurations managing VPCs, subnets, route tables, internet/NAT gateways, and compute instances.
- **Responsive Video Streaming Portal**: Dynamic HTML5 video player with course catalog, user authentication (signup/login), and S3 asset delivery.

---

## 🏗️ System Architecture

```text
                                  +------------------------------------+
                                  |            Internet                |
                                  +-----------------+------------------+
                                                    |
                                                    v
                                      +-------------+------------+
                                      |     Internet Gateway     |
                                      +-------------+------------+
                                                    |
                     +------------------------------+------------------------------+
                     |                                                             |
        [ Public Subnet A (AZ-1) ]                                    [ Public Subnet B (AZ-2) ]
        +------------------------+                                    +------------------------+
        |     NAT Gateway A      |                                    |     NAT Gateway B      |
        | Application Load Bal.  |                                    |                        |
        +------------+-----------+                                    +------------+-----------+
                     |                                                             |
                     +------------------------------+------------------------------+
                                                    |
                     +------------------------------+------------------------------+
                     |                                                             |
        [ Web Subnet A (AZ-1) ]                                       [ Web Subnet B (AZ-2) ]
        +------------------------+                                    +------------------------+
        |  Docker: User-Service  |                                    | Docker: Uploader-Svc   |
        |       (Port 8082)      |                                    |       (Port 8081)      |
        +------------+-----------+                                    +------------+-----------+
                     |                                                             |
                     +------------------------------+------------------------------+
                                                    |
                                      [ Data Subnets (Private) ]
                                      +------------------------+
                                      | Amazon RDS MySQL & S3  |
                                      +------------------------+
```

---

## 📂 Repository Structure

```text
├── edustream-master/
│   ├── Jenkinsfile                # Automated Declarative CI/CD pipeline
│   ├── user-service/              # Streaming portal & user management
│   │   ├── app.py                 # Flask server & route handlers
│   │   ├── Dockerfile             # Container configuration (Port 8082)
│   │   ├── requirements.txt       # Dependencies (Flask, SQLAlchemy, Boto3)
│   │   ├── templates/             # Jinja2 HTML templates (video player, auth, catalog)
│   │   ├── static/                # CSS styling and frontend scripts
│   │   └── videos/                # Video storage mount
│   └── uploader-service/          # Video ingestion microservice
│       ├── app.py                 # File upload processing & S3 integration
│       ├── Dockerfile             # Container configuration (Port 8081)
│       └── requirements.txt       # Dependencies
│
├── edustream-project/             # Infrastructure as Code (Terraform)
│   ├── main.tf                    # VPC, 6 Subnets (2 AZs), Gateways, Route Tables
│   ├── variables.tf               # Region, CIDRs, instance definitions
│   ├── outputs.tf                 # VPC IDs and Subnet output mappings
│   └── terraform.tfvars.example   # Sample variable definitions
│
├── .gitignore                     # Prevents committing tfstate, caches & large media
└── README.md
```

---

## ⚙️ CI/CD Pipeline Flow (Jenkins)

The included `Jenkinsfile` orchestrates the complete lifecycle:
1. **Checkout Code**: Pulls the latest commits from the repository.
2. **Build Microservices**: Builds isolated Docker container images for `user-service` and `uploader-service`.
3. **ECR Authentication**: Logs in to Amazon Elastic Container Registry (ECR).
4. **Push Images**: Tags and pushes production images to AWS ECR.
5. **Continuous Deployment**: Pulls updated images onto application hosts and restarts containers with zero downtime.

---

## 🚀 Getting Started

### Option A: Run Services Locally via Docker

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Jay-Pahwa/edustream-cloud-platform.git
   cd edustream-cloud-platform
   ```

2. **Build and launch User Service:**
   ```bash
   cd edustream-master/user-service
   docker build -t edustream-user .
   docker run -d -p 8082:8082 --name user-service edustream-user
   ```

3. **Build and launch Uploader Service:**
   ```bash
   cd ../uploader-service
   docker build -t edustream-uploader .
   docker run -d -p 8081:8081 --name uploader-service edustream-uploader
   ```

4. **Access the portal:**
   Open [http://localhost:8082](http://localhost:8082) in your browser.

---

### Option B: Deploy Cloud Infrastructure via Terraform

1. **Navigate to the Terraform directory:**
   ```bash
   cd edustream-project
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Review execution plan:**
   ```bash
   terraform plan
   ```

4. **Provision infrastructure:**
   ```bash
   terraform apply
   ```

---

## 🛡️ Security & Best Practices

- **Zero Credentials in Code**: Database passwords, AWS access keys, and IAM credentials are dynamically injected via environment variables and IAM instance profiles.
- **Isolated Network Layers**: Application containers and RDS databases reside inside private subnets without direct public internet exposure.
- **State Management**: Terraform state files (`*.tfstate`) and sensitive caches are strictly excluded via `.gitignore`.
