# Society App Backend

Django + DRF + PostgreSQL REST API for the Society Management Application.

## Quick Start

```bash
cd backend

# Install dependencies
pip install -r requirements.txt

# Copy env file
cp .env.example .env

# Create PostgreSQL DB and user
sudo -u postgres psql -c "CREATE DATABASE society_app;"
sudo -u postgres psql -c "CREATE USER society_app WITH PASSWORD 'postgres';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE society_app TO society_app;"

# Run migrations
python3 manage.py migrate

# Create superuser (optional)
echo "from apps.accounts.models import User; User.objects.create_superuser(phone='9999999999', name='Admin', password='admin123')" | python3 manage.py shell

# Seed test data
DJANGO_SETTINGS_MODULE=config.settings.dev python3 scripts/seed_data.py

# Start server
python3 manage.py runserver 0.0.0.0:8000
```

## API Endpoints

| Endpoint | Method | Description | Auth |
|---|---|---|---|
| `/health/` | GET | Liveness probe | None |
| `/health/ready/` | GET | Readiness probe (DB, Redis, Celery) | None |
| `/api/v1/auth/otp/send/` | POST | Send OTP to phone | None |
| `/api/v1/auth/otp/verify/` | POST | Verify OTP, get JWT | None |
| `/api/v1/auth/token/refresh/` | POST | Refresh access token | None |
| `/api/v1/auth/me/` | GET | Current user profile | JWT |
| `/api/v1/societies/` | GET/POST | List/Create societies | Admin |
| `/api/v1/residents/` | GET | List residents | Admin |
| `/api/v1/residents/<id>/roles/` | PATCH | Update resident roles | Admin |
| `/api/v1/guards/` | GET/POST | List/Create guards | Admin |
| `/api/v1/guards/<id>/access/` | PATCH | Update guard permissions | Admin |
| `/api/v1/guards/<id>/toggle/` | POST | Activate/Deactivate guard | Admin |
| `/api/v1/workflow-items/` | GET/POST | List/Create workflow items | Maker+ |
| `/api/v1/workflow-items/<id>/actions/` | POST | submit/check/approve/reject | Role-based |
| `/api/v1/audit-logs/` | GET | List audit logs | Auth |
| `/api/v1/visitors/` | GET/POST | List/Create visitors | Auth |
| `/api/v1/visitors/<id>/enter/` | POST | Mark visitor entered | Auth |
| `/api/v1/visitors/<id>/exit/` | POST | Mark visitor exited | Auth |
| `/api/v1/visitors/inside/` | GET | List visitors currently inside | Auth |
| `/api/v1/visitors/gate-logs/` | GET | List gate entry/exit logs | Auth |
| `/api/docs/` | GET | Swagger UI (dev only) | None |
| `/api/schema/` | GET | OpenAPI 3 JSON schema | None |

## Test Credentials (after seed)

| Phone | Role | Password |
|---|---|---|
| `9999999999` | Superuser | `admin123` |
| `9999999991` | Secretary/Admin | OTP mock |
| `9999999992` | Treasurer/Admin | OTP mock |
| `8888888881` | Security Guard | OTP mock |
| `8888888882` | Security Guard | OTP mock |
| `98xxxxxxxx` | Resident | OTP mock |

## Architecture

- **Django 5.1** + **DRF 3.15**
- **PostgreSQL** — shared DB multi-tenancy via `society_id`
- **JWT** auth via `djangorestframework-simplejwt`
- **OTP** — mock mode (prints to console); swap to Twilio via `OTP_PROVIDER=twilio`
- **Cursor pagination** on all list endpoints for O(1) deep-page performance
- **Audit logging** — Django signals auto-log every workflow transition

## Environment Variables

See `.env.example` for all options.

## Celery (Async Tasks)

Requires Redis running locally.

```bash
# Start Redis (if not already running)
sudo systemctl start redis-server

# Start Celery worker
celery -A config.celery worker -l info

# Start Celery beat scheduler (periodic tasks)
celery -A config.celery beat -l info
```

### Registered Tasks

| Task | Purpose | Schedule |
|---|---|---|
| `send_otp_async` | Send OTP via SMS asynchronously | On-demand |
| `generate_society_report` | Generate financial report PDF/CSV | On-demand |
| `notify_approvers` | Email/push approvers when item pending | On-demand |
| `health_check_task` | Periodic DB connectivity check | Every 5 minutes |
| `clear_expired_cache` | Cleanup expired Redis keys | Daily |

## Metrics

| Endpoint | Description |
|---|---|
| `/health/metrics/` | System metrics: user counts, visitor stats, workflow counts, DB connections |

Example response:
```json
{
  "timestamp": "2026-07-06T15:58:03Z",
  "users_total": 25,
  "users_active": 25,
  "societies_total": 1,
  "visitors_expected": 4,
  "visitors_inside": 2,
  "workflow_items_total": 8,
  "workflow_items_approved": 3,
  "workflow_items_pending": 2,
  "db_connections": 1
}
```
