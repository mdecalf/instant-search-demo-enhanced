.PHONY: start

dependency:
	npm install

start: dependency
	npm start

image:
	docker buildx build --push --platform linux/amd64,linux/arm64 -t "$(DOCKER_REPO)/$(IMAGE):$(TAG)" -f Dockerfile .