#grant your user permission to run Docker commands without sudo, which is required for Minikube to function properly with the Docker driver.
sudo usermod -aG docker $USER && newgrp docker
sudo usermod -aG docker $USER && newgrp docker
# Download and install Minikube
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
# Start Minikube with Docker driver
#minikube start --driver=docker

#install kubectl
sudo snap install kubectl --classic