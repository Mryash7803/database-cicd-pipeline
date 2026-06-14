# Database CI/CD Pipeline using PostgreSQL, Flyway, Docker and GitHub Actions

## Project Overview

This project demonstrates a Database-as-Code approach where database schema changes are managed through version-controlled SQL migration scripts and automatically deployed using a CI/CD pipeline.

Instead of manually executing SQL scripts on database servers, all schema changes are stored in Git and applied automatically using Flyway.

## Objectives

* Manage database changes as code
* Track schema versions using Flyway
* Automate database deployments using GitHub Actions
* Deploy changes to staging automatically
* Deploy changes to production after manual approval
* Eliminate manual database changes in production

---

## Technology Stack

* PostgreSQL
* Flyway
* Docker
* GitHub Actions
* Git

---

## Project Structure

database-cicd-pipeline/

├── migrations/

│   ├── V1__create_users_table.sql

│   ├── V2__add_email_column.sql

│   └── V3__create_products_table.sql

├── docker-compose.yml

├── flyway.conf

└── .github/

```
└── workflows/

    └── db-migration.yml
```

---

## Step 1: Create Project Directory

```bash
mkdir database-cicd-pipeline
cd database-cicd-pipeline
```

---

## Step 2: Deploy PostgreSQL using Docker

Create docker-compose.yml

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:16
    container_name: dev-postgres
    environment:
      POSTGRES_USER: devops
      POSTGRES_PASSWORD: devops123
      POSTGRES_DB: appdb
    ports:
      - "5432:5432"
```

Start PostgreSQL:

```bash
docker compose up -d
```

Verify container:

```bash
docker ps
```

Access database:

```bash
docker exec -it dev-postgres psql -U devops -d appdb
```

---

## Step 3: Create Migration Scripts

Create migration directory:

```bash
mkdir migrations
```

### Migration 1

Create file:

```bash
vi migrations/V1__create_users_table.sql
```

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Migration 2

```bash
vi migrations/V2__add_email_column.sql
```

```sql
ALTER TABLE users
ADD COLUMN email VARCHAR(100);
```

### Migration 3

```bash
vi migrations/V3__create_products_table.sql
```

```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## Step 4: Configure Flyway

Create flyway.conf

```properties
flyway.url=jdbc:postgresql://localhost:5432/appdb
flyway.user=devops
flyway.password=devops123
flyway.locations=filesystem:migrations
```

---

## Step 5: Execute Flyway Migrations

Run Flyway using Docker:

```bash
docker run --rm \
  --network host \
  -v $(pwd)/migrations:/flyway/sql \
  flyway/flyway \
  -url=jdbc:postgresql://localhost:5432/appdb \
  -user=devops \
  -password=devops123 \
  migrate
```

Verify tables:

```bash
docker exec -it dev-postgres psql -U devops -d appdb
```

Inside PostgreSQL:

```sql
\dt

SELECT * FROM flyway_schema_history;
```

Flyway automatically creates:

```sql
flyway_schema_history
```

This table stores information about executed migrations.

---

## Step 6: Create GitHub Actions Pipeline

Create workflow file:

```bash
mkdir -p .github/workflows
```

Create:

```bash
vi .github/workflows/db-migration.yml
```

```yaml
name: Database CI/CD Pipeline

on:
  push:
    branches:
      - main

jobs:
  migrate-staging:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: devops
          POSTGRES_PASSWORD: devops123
          POSTGRES_DB: stagingdb
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4

      - name: Run Flyway migrations
        run: |
          docker run --rm \
            --network host \
            -v ${{ github.workspace }}/migrations:/flyway/sql \
            flyway/flyway \
            -url=jdbc:postgresql://localhost:5432/stagingdb \
            -user=devops \
            -password=devops123 \
            migrate

  migrate-production:
    needs: migrate-staging
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v4

      - name: Production Deployment
        run: echo "Waiting for approval"
```

---

## Step 7: Configure Production Environment

GitHub Repository

Settings → Environments → New Environment

Create:

```text
production
```

Add:

```text
Required Reviewers
```

Select yourself as reviewer.

This introduces a manual approval gate before production deployment.

---

## Step 8: Configure Production Secrets

Repository

Settings → Secrets and Variables → Actions

Create:

```text
PROD_DB_URL
PROD_DB_USER
PROD_DB_PASSWORD
```

Example Flyway production deployment:

```yaml
- name: Run Flyway migrations on production
  run: |
    docker run --rm \
      -v ${{ github.workspace }}/migrations:/flyway/sql \
      flyway/flyway \
      -url=${{ secrets.PROD_DB_URL }} \
      -user=${{ secrets.PROD_DB_USER }} \
      -password=${{ secrets.PROD_DB_PASSWORD }} \
      migrate
```

---

## Testing

Create a new migration:

```sql
V4__add_phone_column.sql
```

```sql
ALTER TABLE users
ADD COLUMN phone VARCHAR(20);
```

Push changes:

```bash
git add .
git commit -m "Add phone column"
git push
```

Verify:

* GitHub Actions starts automatically
* Staging migration succeeds
* Production waits for approval
* Flyway executes only V4
* Previous migrations are skipped

---

## Key Flyway Concepts

### Versioned Migrations

Examples:

```text
V1__create_users_table.sql
V2__add_email_column.sql
V3__create_products_table.sql
```

### Flyway Schema History

Flyway maintains:

```sql
flyway_schema_history
```

This table tracks:

* Migration Version
* Description
* Execution Time
* Success Status

### Incremental Deployment

If V1, V2 and V3 already ran:

```text
V1 ✔
V2 ✔
V3 ✔
```

and V4 is added:

```text
V4
```

Flyway executes only V4.

---

## Benefits

* Database-as-Code
* Version Control
* Automated Deployments
* Rollout Consistency
* Reduced Human Error
* Production Approval Workflow
* Auditability
* Repeatable Database Changes

---

## Learning Outcomes

Through this project I learned:

* PostgreSQL administration basics
* Database migration management using Flyway
* Dockerized database deployment
* GitHub Actions CI/CD workflows
* Database-as-Code practices
* Staging and Production deployment strategies
* Manual approval gates for production releases
