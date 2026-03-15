# 🍽️ RU Connect - University Restaurant Management System - on Progress 🔄

![Ruby on Rails](https://img.shields.io/badge/Rails-8.1.0-red?style=for-the-badge&logo=ruby-on-rails)
![Docker](https://img.shields.io/badge/Docker-24.0-blue?style=for-the-badge&logo=docker)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14-blue?style=for-the-badge&logo=postgresql)
![Ruby](https://img.shields.io/badge/Ruby-3.4.6-cc342d?style=for-the-badge&logo=ruby)

**RU Connect** is a robust management platform designed to streamline meal workflows, menu planning, and access control in University Restaurants. The system is built for performance, security, and effortless deployment using a fully containerized architecture.



---

## 🚀 Tech Stack

| Tool | Purpose |
| :--- | :--- |
| **Ruby on Rails 8.1.0** | Main web framework utilizing the latest conventions. |
| **Docker & Compose** | Container orchestration for a seamless dev-to-prod pipeline. |
| **PostgreSQL 14** | Relational database for secure and scalable data persistence. |
| **Devise** | Comprehensive authentication and session management. |
| **YJIT & Prism** | Enabled for maximum execution speed on Ruby 3.4. |

---

## 🛠️ Core Features

* **Role-Based Access Control (RBAC):** Managed permissions for Admins, Students, Visitors, and Staff.
* **Meal & Access Tracking:** Real-time logging of restaurant entries linked to specific meal periods.
* **Dynamic Menus:** Scheduling and display of daily university menus.
* **User Management:** Unified registration for students and external visitors.
* **High-Volume Seeding:** Built-in scripts to generate thousands of records for stress testing.

---

## 📊 Database Schema

The system architecture is designed to handle complex relationships between users, their roles, and their meal access logs.

* **Users:** Linked to a specific **Role**.
* **Access Logs:** Track every entry, associated with a **User** and a **Meal**.
* **Daily Menus:** Define the food offerings for specific dates and meal types.

---

## 📦 Getting Started (Docker)

This project is fully containerized. You don't need Ruby or Postgres installed on your host machine—only Docker.

### 1. Prerequisites
* **Docker** (v24.0+)
* **Docker Compose**

### 2. Installation
```bash
# Clone the repository
git clone [https://github.com/your-username/ru_connect.git](https://github.com/your-username/ru_connect.git)
cd ru_connect

# Build the images (using --no-cache to ensure integrity)
docker compose build --no-cache

# Start the services
docker compose up
```

### 3. Accessing the App

Once the logs indicate the server is running, visit: [http://localhost:3000](http://localhost:3000)

---

### 🔑 Authentication Configuration

The system uses a customized **Devise** implementation. When signing up, the following additional fields are required:

* **Username:** A unique identifier for the user.
* **Role:** Defines the user's access level (Admin, Student, etc.).

> [!TIP]
> You can run `rails db:seed` to populate the database with test users and other initial data, making it easier to start using the system right away.

---
