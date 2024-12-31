PHONY: all init plan apply destroy estimate help

# Default target that shows available commands
help:
	@echo "Available variables:"
	@echo "  ENV                    - AWS Customer Environment, example: ENV=prod"
	@echo "  CUSTOMER_NAME          - Customer name to build infra for, example: CUSTOMER_NAME=o2-example"
	@echo "  AWS_PROFILE            - AWS sso configured profile: AWS_PROFILE=cs-sso"
	@echo "  API_KEY                - Infracose API key to calculate EKS pricing: API_KEY=DVJBAVKEDJNVKVCDENJK (FAKE)"
	@echo " "
	@echo "Available commands:"
	@echo "  make all               - Runs the plan, estimate, and apply commands in sequence"
	@echo "  make init              - Initializes Terraform in the specified environment and customer directory"
	@echo "  make plan              - Generates and shows the Terraform plan for the specified environment and customer"
	@echo "  make apply             - Applies the Terraform plan and makes infrastructure changes"
	@echo "  make destroy           - Destroys the infrastructure for the specified environment and customer"
	@echo "  make estimate          - Estimates the cost of the Terraform infrastructure using Infracost"
	@echo "  make o2_pre_setup      - Installs and configures required namespaces and other resources for O2"
	@echo "  make o2_deployment     - Deploys O2 in EKS via helm"
	@echo "  make o2_post_setup     - Fetches NLB from EKS and configured DNS in Route53"
	@echo " "
	@echo "Example commands usage: API_KEY is required only when you use estimate"
	@echo "make plan ENV=prod CUSTOMER_NAME=o2-example AWS_PROFILE=terraform-test-customer1"
	@echo "make estimate API_KEY=infra_cost_api_key ENV=prod CUSTOMER_NAME=o2-example AWS_PROFILE=terraform-test-customer1"


# all is under testing
all: plan estimate apply o2_setup

init:
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && export AWS_PROFILE=$(AWS_PROFILE) && terraform init 
plan:
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && export AWS_PROFILE=$(AWS_PROFILE) && terraform plan
apply:
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && export AWS_PROFILE=$(AWS_PROFILE) && terraform apply
destroy:
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && export AWS_PROFILE=$(AWS_PROFILE) && terraform destroy
estimate:
	export INFRACOST_API_KEY=$(API_KEY)
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && export AWS_PROFILE=$(AWS_PROFILE) && terraform plan -out tfplan-$(ENV)-$(CUSTOMER_NAME)-infra.binary
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && export AWS_PROFILE=$(AWS_PROFILE) && terraform show -json tfplan-$(ENV)-$(CUSTOMER_NAME)-infra.binary > tfplan-$(ENV)-$(CUSTOMER_NAME)-infra.json
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && infracost breakdown --path tfplan-$(ENV)-$(CUSTOMER_NAME)-infra.json
output:
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && export AWS_PROFILE=$(AWS_PROFILE) && terraform output
o2_pre_setup:
	@echo "Setting up Ingress, Cert Manager, and Helm chart for OpenObserve..."
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/aws/deploy.yaml
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && helm repo add openobserve https://charts.openobserve.ai
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && helm repo update
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && kubectl create ns openobserve || true  # avoiding error if namespace already exists, we can find alternatives
	-cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && bash o2-eks/secrets.sh
	sleep 60
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && kubectl apply -f o2-eks/secret-store.yaml
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && kubectl apply -f o2-eks/external-secrets.yaml
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && kubectl apply -f o2-eks/gp3_storage_class.yaml
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.1/cert-manager.yaml
	sleep 60
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && kubectl apply -f o2-eks/issuer.yaml
	
o2_deployment: #move this as last step
	cd ./iaas/terraform/live/env/$(ENV)/customer/$(CUSTOMER_NAME) && helm --namespace openobserve -f o2-eks/values.yaml install o2 openobserve/openobserve

o2_post_setup: #second pre step and this is currently WIP
	NLB_DNS_NAME=$$(kubectl get svc -n ingress-nginx -o jsonpath='{.items[?(@.metadata.name=="ingress-nginx-controller")].status.loadBalancer.ingress[0].hostname}')
	echo "NLB DNS Name: $$NLB_DNS_NAME"

	@echo "Creating Route 53 record with alias for the NLB..."
	CHANGE_BATCH=$$(jq -n \
            --arg dns_name "$$NLB_DNS_NAME" \
            '{Changes: [{Action: "UPSERT", ResourceRecordSet: {Name: "o.openobserve.ai", Type: "A", AliasTarget: {HostedZoneId: "[]", DNSName: $dns_name, EvaluateTargetHealth: false}}}}]')
	export AWS_PROFILE=prod && aws route53 change-resource-record-sets \
	--hosted-zone-id [] \
	--change-batch "$$CHANGE_BATCH"
	@echo "Route 53 record created successfully."