# 🏗️ Architecture: Automated Data Catalog Hosting on AWS S3

## 📌 Overview

In a modern Data Engineering stack, code is only as valuable as its discoverability. This project leverages dbt (data build tool) to generate a comprehensive data catalog and AWS S3 to host it as a serverless, highly available static website. This ensures that stakeholders, analysts, and engineers have a "Single Source of Truth" for data lineage and business logic.

## ❓ Why dbt Docs Matter

Data documentation often suffers from "documentation rot"—where the docs and the code drift apart. dbt solves this by treating documentation as code.

### Automated Lineage (DAG)

Visualizes the flow from RAW S3 landing to Snowflake Marts, making impact analysis trivial.
Data Quality Transparency: Directly exposes dbt test results (Unique, Not Null, Relationships) to the end-user, building trust in the data.

### Business Logic Centralization

Captures column descriptions and SQL logic in a searchable interface, reducing "Slack-based" metadata requests.

## ☁️ Why AWS S3 Static Hosting?

Choosing S3 for documentation hosting over traditional servers or local viewing aligns with AWS Well-Architected principles:

### Cost Optimization

Hosting a static site on S3 costs pennies per month, far cheaper than maintaining a dedicated web server or container.

### Scalability & Availability

S3 provides 99.99% availability and scales automatically to any number of internal users.

### Security & Governance

Access can be tightly controlled via IAM Policies or S3 Bucket Policies. In a production enterprise scenario, this would be fronted by Amazon CloudFront with AWS WAF for OIDC-based authentication.

### Decoupling

The documentation is decoupled from the transformation engine (Snowflake), allowing users to browse metadata even if the warehouse is suspended.

## 🔄 The Regeneration Workflow (CI/CD Pattern)

The documentation is designed to be "Living Documentation." The lifecycle follows a standard DevOps pattern:

- Compile: dbt docs generate parses the project and queries the Snowflake Information Schema to produce manifest.json and catalog.json.
- Build: The command bundles these JSON files with a standalone index.html and static assets.
- Deploy: The artifacts are synchronized to the S3 bucket using the AWS CLI:
aws s3 sync target/ s3://cxm-medtech-dbt-docs-ssen27/ --delete
- Automate (Future State): This process is triggered via GitHub Actions every time code is merged into the main branch, ensuring the catalog is never out of date.

## 🚀 Access the Catalog

The live data catalog and lineage graph can be accessed here:
👉 [\S3 WEBSITE URL HERE\]](https://cxm-medtech-dbt-docs-ssen27.s3.us-east-1.amazonaws.com/index.html)
