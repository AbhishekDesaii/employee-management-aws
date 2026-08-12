# Employee Management API

Flask REST API for employee management.

## Setup

```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python app.py
```

## Docker

```bash
docker build -t employee-api .
docker run -p 5000:5000 employee-api
```

## Endpoints

| Method | Endpoint           | Description       |
|--------|--------------------|-------------------|
| GET    | /api/health        | Health check      |
| GET    | /api/employees     | List employees    |
| GET    | /api/employees/:id | Get employee      |
| POST   | /api/employees     | Create employee   |
| PUT    | /api/employees/:id | Update employee   |
| DELETE | /api/employees/:id | Delete employee   |
| GET    | /api/departments   | List departments  |
| GET    | /api/projects      | List projects     |
| GET    | /api/stats         | Dashboard stats   |