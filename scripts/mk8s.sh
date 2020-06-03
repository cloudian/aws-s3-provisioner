#!/bin/bash -e

sudo snap remove --purge microk8s
sudo snap install microk8s --classic
sudo microk8s status --wait-ready
sudo microk8s enable dns dashboard registry
