build:
	docker build -t voronenko/cdci-tf-ansible:latest .
push:
	docker push voronenko/cdci-tf-ansible:latest
