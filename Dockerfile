FROM quay.io/rpsene/ibmcloud-ops:powervs-base-image

LABEL authors="Rafael Sene - rpsene@br.ibm.com"

WORKDIR /vm-delete

ENV API_KEY=""
ENV POWERVS_CRN=""
ENV VM_ID=""

COPY ./delete-vm.sh .

RUN chmod +x ./delete-vm.sh

ENTRYPOINT ["/bin/bash", "-c", "./delete-vm.sh"]