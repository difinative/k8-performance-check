#!/bin/bash

# fio_node=""
# iperf_server=""
# iperf_client=""

# Prompt the user for input and store it in the variables
read -p "Enter the FIO node name: " fio_node
sed -i "s/fio-node/$fio_node/g" ./fio/fio.yaml

# Apply the fio.yaml, fio-cm.yaml file
kubectl apply -f ./fio/fio-cm.yaml
kubectl apply -f ./fio/fio.yaml
echo -e

read -p "Enter the IPERF Server node name: " iperf_server
read -p "Enter the IPERF Client node name: " iperf_client

sed -i "s/iperf-server-node/$iperf_server/g" ./iperf/iperf-server.yaml
sed -i "s/iperf-client-node/$iperf_client/g" ./iperf/iperf-client.yaml

echo -e
echo "-------------------------"
# Apply the iperf-s.yaml file
kubectl apply -f ./iperf/iperf-server.yaml

# Wait for the iperf-s pod to be in the Running phase
kubectl wait --for=condition=Ready pod -l app=iperf-server

# Get the IP address of the iperf-s pod
server_ip=$(kubectl get pod -l app=iperf-server -o=jsonpath='{range .items[*]}{.status.podIP}{end}')
podname=$(kubectl get pod -l app=iperf-server -o=jsonpath='{range .items[*]}{.metadata.name}{end}')
echo -e
echo iperf server ip: $server_ip
echo podname: $podname
echo -e

# Replace the placeholder 'serverip' with the actual server IP in iperf-c.yaml
sed -i "s/server_ip/$server_ip/g" ./iperf/iperf-cm.yaml
sed -i "s/podname/$podname/g" ./iperf/iperf-cm.yaml

# # Apply the modified iperf-c.yaml file
kubectl apply -f ./iperf/iperf-cm.yaml
kubectl apply -f ./iperf/iperf-client.yaml
echo "-------------------------"

echo -e
echo "Waiting 3m(180 sec) to allow the performance tests to complete....."
sleep 180

echo "Collecting logs"
kubectl logs -l 'app=iperf-client' > ./logs/iperf
kubectl logs -l 'app=fio-disk-test' > ./logs/fio
echo -e
# # Clean up: Optionally, you can delete the iperf-s pod to release resources

echo "Deleting the pods"
kubectl delete pod -l task=performance-check
sed -i "s/$server_ip/server_ip/g" ./iperf/iperf-cm.yaml
sed -i "s/$podname/podname/g" ./iperf/iperf-cm.yaml


sed -i "s/$fio_node/fio-node/g" ./fio/fio.yaml
sed -i "s/$iperf_server/iperf-server-node/g" ./iperf/iperf-server.yaml
sed -i "s/$iperf_client/iperf-client-node/g" ./iperf/iperf-client.yaml
