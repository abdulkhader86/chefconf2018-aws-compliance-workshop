# Deploying the Workshop Environment

## Create a `terraform.tfvars` file:

```
cp terraform.tfvars.example terraform.tfvars
# Edit `terraform.tfvars` to match your info
```

## Run the following:

```
terraform init
terraform workspace new IAM_USERNAME
terraform apply # Use `--auto-approve` to skip prompt
```

# NOTES

## SSL Certificates

The auto generated SSL certificate is self-signed and likely won't be trusted by your browser. To bypass on Chromium type `thisisunsafe`.

