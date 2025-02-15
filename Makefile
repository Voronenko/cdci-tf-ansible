TAG := $(shell date '+%Y%m%d')

build:
	echo "Building tag $(TAG)"
	docker build -t voronenko/cdci-tf-ansible:latest .

clean:
	docker image rm voronenko/cdci-tf-ansible:latest voronenko/cdci-tf-ansible:$(TAG) --force

push:
	docker tag voronenko/cdci-tf-ansible:latest voronenko/cdci-tf-ansible:$(TAG)
	docker push voronenko/cdci-tf-ansible:$(TAG)

push-latest:
	docker push voronenko/cdci-tf-ansible:latest
