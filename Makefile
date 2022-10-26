TAG := $(shell date '+%Y%m%d')

build:
	echo "Building tag $(TAG)"
	docker build -t voronenko/cdci-tf-ansible:latest .

push:
	docker tag voronenko/cdci-tf-ansible:latest voronenko/cdci-tf-ansible:$(TAG)
	docker push voronenko/cdci-tf-ansible:$(TAG)
	docker push voronenko/cdci-tf-ansible:latest
