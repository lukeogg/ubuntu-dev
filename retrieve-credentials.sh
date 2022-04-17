#!/bin/bash



#==================================== Default Variables ==========================================#
cert_path=$(cat inventory | ggrep -Po "(?<==).*\.pem")
# Get Host from inventory file
host=$(cat inventory | ggrep -Po "(.*)amazonaws\.com")




#==================================== Print Credentials ==========================================#
ssh -T -i $cert_path ubuntu@$host << HEREDOC
    echo "
            ===================== return credentials ========================
              

    "
    cd ~/kudo-kubeflow/
    export KUBECONFIG=\$(find ~/kudo-kubeflow -maxdepth 1 -name 'kaptain-*.conf' | awk -F/ '{ print }')
    export KAPTAIN_URL=\$(kubectl get svc kaptain-ingress --namespace kaptain-ingress -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
    
    echo "
Kaptain Credentials 


    URL: https://\$KAPTAIN_URL
    default users:  user1@d2iq.com and user2@d2iq.com
    default password: password
    "

    echo "
Kommander Credentials:"
    make kommander-credentials
    echo ""
HEREDOC