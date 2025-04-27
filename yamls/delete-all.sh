kustomize build common/cert-manager/kubeflow-issuer/base | kubectl delete -f -
kustomize build common/istio-1-9/istio-crds/base | kubectl delete -f -
kustomize build common/istio-1-9/istio-namespace/base | kubectl delete -f -
kubectl get po -n istio-system
k delete -f istio.yaml
kustomize build common/dex/overlays/istio | kubectl delete  -f -
kustomize build common/oidc-authservice/base | kubectl delete -f -
kustomize build common/kubeflow-namespace/base | kubectl delete -f -
kustomize build common/kubeflow-roles/base | kubectl delete -f -
kustomize build common/istio-1-9/kubeflow-istio-resources/base | kubectl delete -f -
kustomize build apps/pipeline/upstream/env/platform-agnostic-multi-user | kubectl delete -f -
--- 디버깅 중