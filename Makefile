PACKER_VERSION := 1.7.4
UNAME := $(shell uname -s)
ifeq (${UNAME},Linux)
	PACKER_URL="https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip"
endif
ifeq (${UNAME},Darwin)
	PACKER_URL="https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_darwin_amd64.zip"
endif

packer:
	curl ${PACKER_URL} -o ./packer.zip
	unzip ./packer.zip
	rm ./packer.zip

release.auto.pkrvars.hcl:
	echo "Missing configuration file: release.auto.pkrvars.hcl."
	exit 1

.PHONY: check-region
check-region:
	@bash -c "if [ -z ${REGION} ]; then echo 'ERROR: REGION variable must be set. Example: \"REGION=us-west-2 make al2\"'; exit 1; fi"

.PHONY: fmt
fmt: packer
	./packer fmt .

.PHONY: init
init: check-region packer
	./packer init -var "region=${REGION}" .

.PHONY: validate
validate: check-region packer
	./packer validate -var "region=${REGION}" .

.PHONY: al1
al1: check-region init validate release.auto.pkrvars.hcl
	./packer build -only="amazon-ebs.al1" -var "region=${REGION}" .

.PHONY: al2
al2: check-region init validate release.auto.pkrvars.hcl
	./packer build -only="amazon-ebs.al2" -var "region=${REGION}" .

.PHONY: al2arm
al2arm: check-region init validate release.auto.pkrvars.hcl
	./packer build -only="amazon-ebs.al2arm" -var "region=${REGION}" .

.PHONY: al2gpu
al2gpu: check-region init validate release.auto.pkrvars.hcl
	./packer build -only="amazon-ebs.al2gpu" -var "region=${REGION}" .

.PHONY: al2inf
al2inf: check-region init validate release.auto.pkrvars.hcl
	./packer build -only="amazon-ebs.al2inf" -var "region=${REGION}" .

.PHONY: clean
clean:
	-rm manifest.json
