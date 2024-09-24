.PHONY: all deploy destroy

all:
	@echo "Available commands:"
	@echo "  make deploy  - Initialize, format, and apply Terraform configuration"
	@echo "  make destroy - Destroy provisioned resources"

deploy:
	terraform init
	terraform fmt
	terraform apply --auto-approve

destroy:
	terraform destroy --auto-approve