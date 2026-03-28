# Plone on AWS

Throughout my career I have primarily worked with Plone, a Python-based CMS.
This got me thinking about how deploying Plone on AWS might benefit a team or company,
this project is my attempt to explore at least a simplified answer to that question.

## Considerations

Plone can be run in several ways:

- Bare metal
- Dockerized (official images are provided)

There are also several approaches to data storage with Plone:

- **Standalone instances** – CMS instances interact directly with ZopeDB on the filesystem
- **Zeo mode** – Zeo acts as a database server for ZopeDB, enabling multiple CMS instances to connect to a shared
  database
- **RelStorage** – Allows Plone to use relational databases in place of the Zope object database

## Architecture decisions

I chose to deploy a Dockerized version of Plone to reduce management overhead
and to take advantage of Fargate, which minimizes the need to manually manage instances.

The storage decision was less straightforward. An official Docker image exists for Zeo server,
which would have kept things simple, but RelStorage opened the possibility to using managed RDS instances,
something I had not tried before. That, combined with the appeal of leveraging managed services,
made RelStorage with RDS the more compelling choice.

For blob storage (images, PDFs, etc.), EFS was the natural fit, as it is a filesystem with native Linux and ECS support.

Fargate tasks run in private subnets with no public internet access.
VPC endpoints for ECR and S3 allow container image pulls without routing traffic through
the public internet or requiring a (costly) NAT gateway.

| Requirement        | Choice                          |
|--------------------|---------------------------------|
| Plone              | Dockerized on ECS Fargate       |
| Database           | RelStorage + AWS RDS PostgreSQL |
| Blob storage       | AWS EFS                         |
| Networking         | VPC with public/private subnets |
| Container registry | AWS ECR (via VPC endpoints)     |
| Secrets            | AWS SSM Parameter Store         |

## Deployment

> [!CAUTION]
> This is a learning project and is not hardened for production. Notable gaps include: no HTTPS on the ALB, no RDS
> multi-AZ and no backups. Use at your own risk.

> [!NOTE]
> This guide assumes you are deploying to `eu-central-1`

**1. Initialise Terraform and create the ECR repository**

```bash
terraform init
terraform apply -target=aws_ecr_repository.plone
```

**2. Build and push the Plone image to ECR**

```bash
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin \
  $(aws sts get-caller-identity --query Account --output text).dkr.ecr.eu-central-1.amazonaws.com

docker pull --platform linux/amd64 plone/plone-backend:latest
docker tag plone/plone-backend:latest $(terraform output -raw ecr_repository_url):latest
docker push $(terraform output -raw ecr_repository_url):latest
```

**3. Apply the remaining infrastructure**
Please verify that everything is correct here.

```bash
terraform apply
```

Note the `alb_dns` output — you'll need it in the next step.

**4. Access Plone**

Navigate to `http://<alb_dns>` in your browser. On first run, Plone will need a moment to initialise the database.

## Teardown

To destroy all resources:

```bash
terraform destroy
```

> [!WARNING]
> This will permanently delete the RDS database and EFS filesystem including all data. Make sure to take snapshots if
> you want to keep the data