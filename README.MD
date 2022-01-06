docker build -t powervs-vm-delete .
  
docker run -e API_KEY="YOUR_IBM_CLOUD_API_KEY" \
    -e POWERVS_CRN="YOUR_TARGET_POWERVS_CRN" \
    -e VM_ID="YOUR_VM_ID" \
    powervs-vm-delete:latest