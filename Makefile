ANSIBLE_DIR := ansible

.PHONY: provision check lint status bootstrap

provision:
	cd $(ANSIBLE_DIR) && ansible-playbook site.yml

check:
	cd $(ANSIBLE_DIR) && ansible-playbook site.yml --check --diff

lint:
	yamllint .
	cd $(ANSIBLE_DIR) && ansible-lint

status:
	kubectl get nodes -o wide
	kubectl get pods -A

bootstrap:
	cd terraform && terraform init -input=false && terraform apply -auto-approve -input=false

plan:
	cd terraform && terraform init -input=false && terraform plan
