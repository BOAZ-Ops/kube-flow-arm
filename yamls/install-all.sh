kustomize build common/cert-manager/cert-manager/base | kubectl apply -f -
kubectl get po -n cert-manager
kustomize build common/cert-manager/kubeflow-issuer/base | kubectl apply -f -
kustomize build common/istio-1-16/istio-crds/base | kubectl apply -f -
kustomize build common/istio-1-16/istio-namespace/base | kubectl apply -f -
kustomize build common/istio-1-16/istio-install/base | kubectl apply -f -
kubectl get po -n istio-system
kustomize build common/dex/overlays/istio | kubectl apply -f -
kubectl get po -n auth
kustomize build common/oidc-authservice/base | kubectl apply -f -
kubectl get po -n istio-system -w
kustomize build common/kubeflow-namespace/base | kubectl apply -f -
kubectl get ns kubeflow
kustomize build common/kubeflow-roles/base | kubectl apply -f -
kubectl get clusterrole | grep kubeflow
kustomize build common/istio-1-16/kubeflow-istio-resources/base | kubectl apply -f -
kubectl get clusterrole | grep kubeflow-istio
kubectl get gateway -n kubeflow
kustomize build apps/pipeline/upstream/env/platform-agnostic-multi-user | kubectl apply -f -
kubectl get po -n kubeflow
kustomize build apps/katib/upstream/installs/katib-with-kubeflow | kubectl apply -f -
kubectl get po -n kubeflow | grep katib
kustomize build apps/centraldashboard/upstream/overlays/istio | kubectl apply -f -
kubectl get po -n kubeflow | grep centraldashboard
kustomize build apps/admission-webhook/upstream/overlays/cert-manager | kubectl apply -f -
kubectl get po -n kubeflow | grep admission-webhook
kustomize build apps/jupyter/notebook-controller/upstream/overlays/kubeflow | kubectl apply -f -
kubectl get po -n kubeflow | grep notebook-controller
kustomize build apps/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl apply -f -
kubectl get po -n kubeflow | grep jupyter-web-app
kustomize build apps/profiles/upstream/overlays/kubeflow | kubectl apply -f -
kubectl get po -n kubeflow | grep profiles-deployment
kustomize build apps/volumes-web-app/upstream/overlays/istio | kubectl apply -f -
kubectl get po -n kubeflow | grep volumes-web-app
kustomize build apps/tensorboard/tensorboards-web-app/upstream/overlays/istio | kubectl apply -f -
kubectl get po -n kubeflow | grep tensorboards-web-app
kustomize build apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow | kubectl apply -f -
kubectl get po -n kubeflow | grep tensorboard-controller
kustomize build apps/training-operator/upstream/overlays/kubeflow | kubectl apply -f -
kubectl get po -n kubeflow | grep training-operator
kustomize build common/user-namespace/base | kubectl apply -f -
kubectl get profile

# Forwarding
kubectl port-forward --address 0.0.0.0 svc/ml-pipeline-ui -n kubeflow 8888:80             # http://${IP}:8888/#/pipelines
kubectl port-forward --address 0.0.0.0 svc/katib-ui -n kubeflow 8081:80                   # http://${IP}:8081/katib/
kubectl port-forward --address 0.0.0.0 svc/centraldashboard -n kubeflow 8082:80           # http://${IP}:8082/
kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 8080:80   # http://${IP}:8080/dex/auth/local/login?back=&state=rxl67iq5lvggjjh2675lxdraq
