python_version  = 3.7.11
pip_version     = 21.2.4
poetry_version  = 1.1.8

.PHONY: build-tensorflow
build-tensorflow:
# disable buildkit as it limits the log lines: [output clipped, log limit 1MiB reached]
	@DOCKER_BUILDKIT=0 docker build -t signal-tensorflow \
		--build-arg PYTHON_VERSION=$(python_version) \
		--build-arg OVERRIDE_PIP_VERSION=$(pip_version) \
		--cpuset-cpus="0-$$(($$(nproc) - 1))" \
		--progress plain \
		--file dev/tensorflow/Dockerfile.tensorflow \
		dev/tensorflow
	export id=$$(docker create signal-tensorflow-tensorflow) \
	&& docker cp $$id:/tmp/tensorflow_pkg dev/tensorflow/tensorflow_pkg \
	&& docker rm $$id
