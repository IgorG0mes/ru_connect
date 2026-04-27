# 🍽️ RU Connect — University Restaurant Management System

![Ruby on Rails](https://img.shields.io/badge/Rails-8.1.0-red?style=for-the-badge&logo=ruby-on-rails)
![Docker](https://img.shields.io/badge/Docker-24.0-blue?style=for-the-badge&logo=docker)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14-blue?style=for-the-badge&logo=postgresql)
![Ruby](https://img.shields.io/badge/Ruby-3.4.6-cc342d?style=for-the-badge&logo=ruby)

**RU Connect** is a management platform designed to streamline meal workflows, menu planning, and access control in University Restaurants. The system is built for performance, security, and effortless deployment using a fully containerized architecture.

> The application UI and all user-facing content are in Brazilian Portuguese (pt-BR).

---

## 🚀 Tech Stack

| Tool | Purpose |
| :--- | :--- |
| **Ruby on Rails 8.1.0** | Main web framework |
| **Hotwire (Turbo + Stimulus)** | Real-time UI updates without full-page reloads |
| **PostgreSQL 14** | Relational database with `unaccent` for accent-insensitive search |
| **Devise** | Authentication and session management |
| **Docker & Compose** | Container orchestration for dev and production |
| **YJIT & Prism** | Enabled for maximum execution speed on Ruby 3.4 |

---

## 🛠️ Core Features

- **Public CPF Finder:** Unauthenticated page (`/finder`) where students and visitors can look up their enrollment status and available balance by CPF — no login required
- **Role-Based Access Control (RBAC):** Role-based permissions controlling access to routes and UI actions
- **Student & Visitor Registration:** QR Code generation for each registered person, with enrollment status (`active`, `inactive`, `suspended`, `graduated`) and wallet balance
- **Meal & Access Tracking:** Real-time logging of restaurant entries linked to specific meal periods, streamed via Turbo
- **Dynamic Daily Menus:** Schedule and display all daily menus for the day regardless of current time, highlighting the meal currently in service
- **QR Code Scanner:** Camera-based QR scanning on the identification screen
- **Accent-insensitive Search:** Searching students by name, registration number, or CPF
- **User Management:** Admin-only interface to create and manage system users

---

## 📊 Database Schema

- **Users** — system operators, linked to a **Role**
- **Students** — university students with CPF, registration number, course, QR Code, and `balance` (decimal, for Mercado Pago integration). Enrollment `status` is stored as an integer enum: `0 = active`, `1 = inactive`, `2 = suspended`, `3 = graduated`
- **Visitors** — external visitors with CPF, QR Code, and `balance`
- **Meals** — meal periods with name and time range (e.g. Almoço 11:00–14:00)
- **Daily Menus** — food offerings per date and meal type
- **Access Logs** — every entry attempt, linked to a student or visitor and a meal period

---

## 📦 Getting Started (Docker)

This project is fully containerized. You only need Docker installed on your machine.

### 1. Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (v24.0+)
- Docker Compose

### 2. Installation

```bash
# Clone the repository
git clone https://github.com/IgorG0mes/ru_connect.git
cd ru_connect

# Copy environment variables
cp .env.example .env

# Build and start the services
docker compose build
docker compose up
```

### 3. Database setup

In a separate terminal, run:

```bash
docker compose exec web rails db:create db:migrate db:seed
```

The seed script creates the `admin` and `balconist` roles and populates the database with sample students, visitors, meals, and daily menus.

### 4. Create the first admin user

```bash
docker compose exec web rails console
```

```ruby
admin_role = Role.find_by(name: "admin")
User.create!(username: "your_username", email: "your_email", password: "your_password", role: admin_role)
```

### 5. Access the app

Visit [http://localhost:3000](http://localhost:3000) — the root page is the public **CPF Finder**, accessible without authentication. Staff members can log in via the **"Área do funcionário"** button and will be redirected to the identification screen after sign-in.

---

## ⚙️ Environment Variables

Copy `.env.example` to `.env` and fill in the required values:

| Variable | Description |
| :--- | :--- |
| `DB_HOST` | PostgreSQL host (use `db` inside Docker) |
| `DB_USER` | PostgreSQL username |
| `DB_PASSWORD` | PostgreSQL password |
| `DATABASE_URL` | Full DB URL (used in production) |
| `RAILS_MASTER_KEY` | Rails credentials master key |
| `SECRET_KEY_BASE` | Rails secret key base (production) |
| `WEB_CONCURRENCY` | Number of Puma workers |

---