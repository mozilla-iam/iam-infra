default:
	@echo "Provide a valid make target: tf-apply-all, tf-destroy-all"

tf-apply-all:
	cd vpc && terraform apply
	cd kubernetes && terraform apply
	cd services/sso-dashboard terraform apply
	cd services/graylog && terraform apply

tf-destroy-all:
	cd services/graylog && terraform destroy
	cd services/sso-dashboard && terraform destroy
	cd kubernetes && terraform destroy
	cd vpc && terraform destroy
