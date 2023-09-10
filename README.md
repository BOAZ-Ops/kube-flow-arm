# Apple Silicon에서 kubeflow 시작하기 (with minikube)

## 최소 사양

- 맥북 m 시리즈
- 최소 Ram 16GB 이상 필요

## 시작하기

1. 아래 명령어를 통해 minikube를 실행해줍니다.

```bash
minikube start --cpus 4 --memory 16384 \
    --network-plugin=cni \
    --enable-default-cni \
    --container-runtime=containerd \
    --bootstrapper=kubeadm
```

다음과 같은 결과를 얻을 수 있습니다.

```bash
😄  Darwin 13.5.2 (arm64) 의 minikube v1.28.0
🎉  minikube 1.31.2 이 사용가능합니다! 다음 경로에서 다운받으세요: https://github.com/kubernetes/minikube/releases/tag/v1.31.2
💡  해당 알림을 비활성화하려면 다음 명령어를 실행하세요. 'minikube config set WantUpdateNotification false'
✨  기존 프로필에 기반하여 docker 드라이버를 사용하는 중
E0910 10:49:34.823281   54880 start_flags.go:455] Found deprecated --enable-default-cni flag, setting --cni=bridge
👍  minikube 클러스터의 minikube 컨트롤 플레인 노드를 시작하는 중
🚜  베이스 이미지를 다운받는 중 ...
🤷  docker "minikube" container is missing, will recreate.
🔥  Creating docker container (CPUs=4, Memory=16384MB) ...
📦  쿠버네티스 v1.25.3 을 containerd 1.6.9 런타임으로 설치하는 중
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Kubernetes 구성 요소를 확인...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  애드온 활성화 : default-storageclass, storage-provisioner
🏄  끝났습니다! kubectl이 "minikube" 클러스터와 "default" 네임스페이스를 기본적으로 사용하도록 구성되었습니다.
```

2. 실행이 완료되었다면 namespace를 생성해줍니다.

```bash
k create ns kubeflow
k create ns istio-system
k create ns auth
```

namespace 생성 시, 다음과 같이 나옵니다.

```bash
namespace/kubeflow created
namespace/istio-system created
namespace/auth created
```

추후에 사용할 istio를 위해서 namespace label을 추가해줍니다.

```bash
k label ns kubeflow istio-injection=enabled
```

3. local storage를 pvc로 활용하기 위해 다음과 같이 설치해줍니다.

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.20/deploy/local-path-storage.yaml

kubectl patch storageclass local-path  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

결과 화면은 다음과 같습니다.

```bash
> kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.20/deploy/local-path-storage.yaml
namespace/local-path-storage created
serviceaccount/local-path-provisioner-service-account created
clusterrole.rbac.authorization.k8s.io/local-path-provisioner-role created
clusterrolebinding.rbac.authorization.k8s.io/local-path-provisioner-bind created
deployment.apps/local-path-provisioner created
storageclass.storage.k8s.io/local-path created
configmap/local-path-config created

> kubectl patch storageclass local-path  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

storageclass.storage.k8s.io/local-path patched
```

4. 기존에 설치되어 있는 standard storage class에서 아래처럼 default 옵션을 빼줍니다.

```bash
> kubectl patch storageclass standard  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
storageclass.storage.k8s.io/standard patched
```

5.  local-path에만 default가 된것을 확인할 수 있습니다.

```bash
>  k get sc
NAME                   PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path      Delete          WaitForFirstConsumer   false                  5m9s
standard               k8s.io/minikube-hostpath   Delete          Immediate              false                  13d
```

6. cert 인증을 위해서 cert-manager를 설치해줍니다.

```bash
> k apply -f cert-manager.yaml
namespace/cert-manager created
customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/challenges.acme.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/clusterissuers.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/issuers.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/orders.acme.cert-manager.io created
serviceaccount/cert-manager-cainjector created
serviceaccount/cert-manager created
serviceaccount/cert-manager-webhook created
configmap/cert-manager-webhook created
clusterrole.rbac.authorization.k8s.io/cert-manager-cainjector created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-issuers created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificates created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-orders created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-challenges created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim created
clusterrole.rbac.authorization.k8s.io/cert-manager-view created
clusterrole.rbac.authorization.k8s.io/cert-manager-edit created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-approve:cert-manager-io created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificatesigningrequests created
clusterrole.rbac.authorization.k8s.io/cert-manager-webhook:subjectaccessreviews created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-cainjector created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-issuers created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificates created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-orders created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-challenges created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-approve:cert-manager-io created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificatesigningrequests created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-webhook:subjectaccessreviews created
role.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection created
role.rbac.authorization.k8s.io/cert-manager:leaderelection created
role.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving created
rolebinding.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection created
rolebinding.rbac.authorization.k8s.io/cert-manager:leaderelection created
rolebinding.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving created
service/cert-manager created
service/cert-manager-webhook created
deployment.apps/cert-manager-cainjector created
deployment.apps/cert-manager created
deployment.apps/cert-manager-webhook created
mutatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook created
validatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook created
```

7. kubeflow self signed를 하기 위해서 cluster issuer를 생성해줍니다.

```bash
> k apply -f cluster-issuer.yaml
clusterissuer.cert-manager.io/kubeflow-self-signing-issuer created
```

8. kubeflow에서 istio 설치하기

```bash
> k apply -f istio-crds.yaml
customresourcedefinition.apiextensions.k8s.io/authorizationpolicies.security.istio.io created
customresourcedefinition.apiextensions.k8s.io/destinationrules.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/envoyfilters.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/gateways.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/istiooperators.install.istio.io created
customresourcedefinition.apiextensions.k8s.io/peerauthentications.security.istio.io created
customresourcedefinition.apiextensions.k8s.io/proxyconfigs.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/requestauthentications.security.istio.io created
customresourcedefinition.apiextensions.k8s.io/serviceentries.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/sidecars.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/telemetries.telemetry.istio.io created
customresourcedefinition.apiextensions.k8s.io/virtualservices.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/wasmplugins.extensions.istio.io created
customresourcedefinition.apiextensions.k8s.io/workloadentries.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/workloadgroups.networking.istio.io created
```

9. istio를 install 해줍니다.

```bash
> k apply -f istio-install.yaml
serviceaccount/istio-ingressgateway-service-account created
serviceaccount/istio-reader-service-account created
serviceaccount/istiod created
serviceaccount/istiod-service-account created
role.rbac.authorization.k8s.io/istio-ingressgateway-sds created
role.rbac.authorization.k8s.io/istiod created
role.rbac.authorization.k8s.io/istiod-istio-system created
clusterrole.rbac.authorization.k8s.io/istio-reader-clusterrole-istio-system created
clusterrole.rbac.authorization.k8s.io/istio-reader-istio-system created
clusterrole.rbac.authorization.k8s.io/istiod-clusterrole-istio-system created
clusterrole.rbac.authorization.k8s.io/istiod-gateway-controller-istio-system created
clusterrole.rbac.authorization.k8s.io/istiod-istio-system created
rolebinding.rbac.authorization.k8s.io/istio-ingressgateway-sds created
rolebinding.rbac.authorization.k8s.io/istiod created
rolebinding.rbac.authorization.k8s.io/istiod-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istio-reader-clusterrole-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istio-reader-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istiod-clusterrole-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istiod-gateway-controller-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istiod-istio-system created
configmap/istio created
configmap/istio-sidecar-injector created
service/istio-ingressgateway created
service/istiod created
deployment.apps/istio-ingressgateway created
deployment.apps/istiod created
horizontalpodautoscaler.autoscaling/istio-ingressgateway created
horizontalpodautoscaler.autoscaling/istiod created
envoyfilter.networking.istio.io/stats-filter-1.13 created
envoyfilter.networking.istio.io/stats-filter-1.14 created
envoyfilter.networking.istio.io/stats-filter-1.15 created
envoyfilter.networking.istio.io/stats-filter-1.16 created
envoyfilter.networking.istio.io/stats-filter-1.17 created
envoyfilter.networking.istio.io/tcp-stats-filter-1.13 created
envoyfilter.networking.istio.io/tcp-stats-filter-1.14 created
envoyfilter.networking.istio.io/tcp-stats-filter-1.15 created
envoyfilter.networking.istio.io/tcp-stats-filter-1.16 created
envoyfilter.networking.istio.io/tcp-stats-filter-1.17 created
envoyfilter.networking.istio.io/x-forwarded-host created
gateway.networking.istio.io/istio-ingressgateway created
authorizationpolicy.security.istio.io/global-deny-all created
authorizationpolicy.security.istio.io/istio-ingressgateway created
mutatingwebhookconfiguration.admissionregistration.k8s.io/istio-sidecar-injector created
validatingwebhookconfiguration.admissionregistration.k8s.io/istio-validator-istio-system created
```

10. dex를 설치해줍니다.

```bash
> k apply -f dex.yaml
namespace/auth configured
customresourcedefinition.apiextensions.k8s.io/authcodes.dex.coreos.com created
serviceaccount/dex created
clusterrole.rbac.authorization.k8s.io/dex created
clusterrolebinding.rbac.authorization.k8s.io/dex created
configmap/dex created
secret/dex-oidc-client created
service/dex created
deployment.apps/dex created
virtualservice.networking.istio.io/dex created
```

11. oidc 인증을 하기 위해 다음과 같이 해줍니다.

```bash
> k apply -f oidc-authservice.yaml
serviceaccount/authservice created
clusterrole.rbac.authorization.k8s.io/authn-delegator created
clusterrolebinding.rbac.authorization.k8s.io/authn-delegators created
configmap/oidc-authservice-parameters created
secret/oidc-authservice-client created
service/authservice created
persistentvolumeclaim/authservice-pvc created
statefulset.apps/authservice created
envoyfilter.networking.istio.io/authn-filter created
```

12. mtls를 설치해줍니다.

```bash
> k apply -f mtls.yaml
peerauthentication.security.istio.io/default created
```

13. k apply -f kubeflow-istio-resources.yaml

```bash
customresourcedefinition.apiextensions.k8s.io/clusterworkflowtemplates.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/compositecontrollers.metacontroller.k8s.io created
customresourcedefinition.apiextensions.k8s.io/controllerrevisions.metacontroller.k8s.io created
customresourcedefinition.apiextensions.k8s.io/cronworkflows.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/decoratorcontrollers.metacontroller.k8s.io created
customresourcedefinition.apiextensions.k8s.io/scheduledworkflows.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/viewers.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/workfloweventbindings.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/workflows.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/workflowtaskresults.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/workflowtasksets.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/workflowtemplates.argoproj.io created
serviceaccount/argo created
serviceaccount/kubeflow-pipelines-cache created
serviceaccount/kubeflow-pipelines-cache-deployer-sa created
serviceaccount/kubeflow-pipelines-container-builder created
serviceaccount/kubeflow-pipelines-metadata-writer created
serviceaccount/kubeflow-pipelines-viewer created
serviceaccount/meta-controller-service created
serviceaccount/metadata-grpc-server created
serviceaccount/ml-pipeline created
serviceaccount/ml-pipeline-persistenceagent created
serviceaccount/ml-pipeline-scheduledworkflow created
serviceaccount/ml-pipeline-ui created
serviceaccount/ml-pipeline-viewer-crd-service-account created
serviceaccount/ml-pipeline-visualizationserver created
serviceaccount/mysql created
serviceaccount/pipeline-runner created
role.rbac.authorization.k8s.io/argo-role created
role.rbac.authorization.k8s.io/kubeflow-pipelines-cache-deployer-role created
role.rbac.authorization.k8s.io/kubeflow-pipelines-cache-role created
role.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-role created
role.rbac.authorization.k8s.io/ml-pipeline created
role.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-role created
role.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-role created
role.rbac.authorization.k8s.io/ml-pipeline-ui created
role.rbac.authorization.k8s.io/ml-pipeline-viewer-controller-role created
role.rbac.authorization.k8s.io/pipeline-runner created
clusterrole.rbac.authorization.k8s.io/aggregate-to-kubeflow-pipelines-edit created
clusterrole.rbac.authorization.k8s.io/aggregate-to-kubeflow-pipelines-view created
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-admin created
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-edit created
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-view created
clusterrole.rbac.authorization.k8s.io/argo-cluster-role created
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-cache-deployer-clusterrole created
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-cache-role created
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-edit created
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-role created
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-view created
clusterrole.rbac.authorization.k8s.io/ml-pipeline created
clusterrole.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-role created
clusterrole.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-role created
clusterrole.rbac.authorization.k8s.io/ml-pipeline-ui created
clusterrole.rbac.authorization.k8s.io/ml-pipeline-viewer-controller-role created
rolebinding.rbac.authorization.k8s.io/argo-binding created
rolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-cache-binding created
rolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-cache-deployer-rolebinding created
rolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-binding created
rolebinding.rbac.authorization.k8s.io/ml-pipeline created
rolebinding.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-binding created
rolebinding.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-binding created
rolebinding.rbac.authorization.k8s.io/ml-pipeline-ui created
rolebinding.rbac.authorization.k8s.io/ml-pipeline-viewer-crd-binding created
rolebinding.rbac.authorization.k8s.io/pipeline-runner-binding created
clusterrolebinding.rbac.authorization.k8s.io/argo-binding created
clusterrolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-cache-binding created
clusterrolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-cache-deployer-clusterrolebinding created
clusterrolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-binding created
clusterrolebinding.rbac.authorization.k8s.io/meta-controller-cluster-role-binding created
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline created
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-binding created
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-binding created
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-ui created
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-viewer-crd-binding created
configmap/kfp-launcher created
configmap/kubeflow-pipelines-profile-controller-code-hdk828hd6c created
configmap/kubeflow-pipelines-profile-controller-env-5252m69c4c created
configmap/metadata-grpc-configmap created
configmap/ml-pipeline-ui-configmap created
configmap/persistenceagent-config-hkgkmd64bh created
configmap/pipeline-api-server-config-dc9hkg52h6 created
configmap/pipeline-install-config created
configmap/workflow-controller-configmap created
secret/mlpipeline-minio-artifact created
secret/mysql-secret created
service/cache-server created
service/kubeflow-pipelines-profile-controller created
service/metadata-envoy-service created
service/metadata-grpc-service created
service/minio-service created
service/ml-pipeline created
service/ml-pipeline-ui created
service/ml-pipeline-visualizationserver created
service/mysql created
service/workflow-controller-metrics created
priorityclass.scheduling.k8s.io/workflow-controller created
persistentvolumeclaim/minio-pvc created
persistentvolumeclaim/mysql-pv-claim created
deployment.apps/cache-deployer-deployment created
deployment.apps/cache-server created
deployment.apps/kubeflow-pipelines-profile-controller created
deployment.apps/metadata-envoy-deployment created
deployment.apps/metadata-grpc-deployment created
deployment.apps/metadata-writer created
deployment.apps/minio created
deployment.apps/ml-pipeline created
deployment.apps/ml-pipeline-persistenceagent created
deployment.apps/ml-pipeline-scheduledworkflow created
deployment.apps/ml-pipeline-ui created
deployment.apps/ml-pipeline-viewer-crd created
deployment.apps/ml-pipeline-visualizationserver created
deployment.apps/mysql created
deployment.apps/workflow-controller created
statefulset.apps/metacontroller created
destinationrule.networking.istio.io/metadata-grpc-service created
destinationrule.networking.istio.io/ml-pipeline created
destinationrule.networking.istio.io/ml-pipeline-minio created
destinationrule.networking.istio.io/ml-pipeline-mysql created
destinationrule.networking.istio.io/ml-pipeline-ui created
destinationrule.networking.istio.io/ml-pipeline-visualizationserver created
virtualservice.networking.istio.io/metadata-grpc created
virtualservice.networking.istio.io/ml-pipeline-ui created
authorizationpolicy.security.istio.io/metadata-grpc-service created
authorizationpolicy.security.istio.io/minio-service created
authorizationpolicy.security.istio.io/ml-pipeline created
authorizationpolicy.security.istio.io/ml-pipeline-ui created
authorizationpolicy.security.istio.io/ml-pipeline-visualizationserver created
authorizationpolicy.security.istio.io/mysql created
authorizationpolicy.security.istio.io/service-cache-server created
error: resource mapping not found for name: "kubeflow-pipelines-profile-controller" namespace: "kubeflow" from "pipeline-platform-agnostic-multi-user.yaml": no matches for kind "CompositeController" in version "metacontroller.k8s.io/v1alpha1"
ensure CRDs are installed first
```

아래와 같은 오류가 발생할 경우 다시 apply를 해주면 정상적으로 결과를 얻을 수 있습니다.

```bash
error: resource mapping not found for name: "kubeflow-pipelines-profile-controller" namespace: "kubeflow" from "pipeline-platform-agnostic-multi-user.yaml": no matches for kind "CompositeController" in version "metacontroller.k8s.io/v1alpha1"
ensure CRDs are installed first
```

katib를 설치해줍니다.

```bash
> k apply -f katib-with-kubeflow.yaml
customresourcedefinition.apiextensions.k8s.io/experiments.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/suggestions.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/trials.kubeflow.org unchanged
serviceaccount/katib-controller unchanged
serviceaccount/katib-ui unchanged
clusterrole.rbac.authorization.k8s.io/katib-controller unchanged
clusterrole.rbac.authorization.k8s.io/katib-ui unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-katib-admin configured
clusterrole.rbac.authorization.k8s.io/kubeflow-katib-edit unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-katib-view unchanged
clusterrolebinding.rbac.authorization.k8s.io/katib-controller unchanged
clusterrolebinding.rbac.authorization.k8s.io/katib-ui unchanged
configmap/katib-config unchanged
configmap/trial-templates unchanged
secret/katib-mysql-secrets unchanged
service/katib-controller unchanged
service/katib-db-manager unchanged
service/katib-mysql unchanged
service/katib-ui unchanged
persistentvolumeclaim/katib-mysql unchanged
deployment.apps/katib-controller unchanged
deployment.apps/katib-db-manager unchanged
deployment.apps/katib-mysql unchanged
deployment.apps/katib-ui unchanged
certificate.cert-manager.io/katib-webhook-cert unchanged
issuer.cert-manager.io/katib-selfsigned-issuer unchanged
virtualservice.networking.istio.io/katib-ui unchanged
authorizationpolicy.security.istio.io/katib-ui unchanged
mutatingwebhookconfiguration.admissionregistration.k8s.io/katib.kubeflow.org configured
validatingwebhookconfiguration.admissionregistration.k8s.io/katib.kubeflow.org configured
```

kubeflow centralboard를 생성해줍니다

```bash
serviceaccount/centraldashboard created
role.rbac.authorization.k8s.io/centraldashboard created
clusterrole.rbac.authorization.k8s.io/centraldashboard created
rolebinding.rbac.authorization.k8s.io/centraldashboard created
clusterrolebinding.rbac.authorization.k8s.io/centraldashboard created
configmap/centraldashboard-config created
configmap/centraldashboard-parameters created
service/centraldashboard created
deployment.apps/centraldashboard created
virtualservice.networking.istio.io/centraldashboard created
authorizationpolicy.security.istio.io/central-dashboard created
```

admission webhook을 등록해줍니다.

```bash
> k apply -f admission-wenhook.yaml
customresourcedefinition.apiextensions.k8s.io/poddefaults.kubeflow.org created
serviceaccount/admission-webhook-service-account created
clusterrole.rbac.authorization.k8s.io/admission-webhook-cluster-role created
clusterrole.rbac.authorization.k8s.io/admission-webhook-kubeflow-poddefaults-admin created
clusterrole.rbac.authorization.k8s.io/admission-webhook-kubeflow-poddefaults-edit created
clusterrole.rbac.authorization.k8s.io/admission-webhook-kubeflow-poddefaults-view created
clusterrolebinding.rbac.authorization.k8s.io/admission-webhook-cluster-role-binding created
service/admission-webhook-service created
deployment.apps/admission-webhook-deployment created
certificate.cert-manager.io/admission-webhook-cert created
issuer.cert-manager.io/admission-webhook-selfsigned-issuer created
mutatingwebhookconfiguration.admissionregistration.k8s.io/admission-webhook-mutating-webhook-configuration created
```

note book controller 생성해줍니다.

```bash
> k apply -f notebook-controller.yaml
customresourcedefinition.apiextensions.k8s.io/notebooks.kubeflow.org created
serviceaccount/notebook-controller-service-account created
role.rbac.authorization.k8s.io/notebook-controller-leader-election-role created
clusterrole.rbac.authorization.k8s.io/notebook-controller-kubeflow-notebooks-admin created
clusterrole.rbac.authorization.k8s.io/notebook-controller-kubeflow-notebooks-edit created
clusterrole.rbac.authorization.k8s.io/notebook-controller-kubeflow-notebooks-view created
clusterrole.rbac.authorization.k8s.io/notebook-controller-role created
rolebinding.rbac.authorization.k8s.io/notebook-controller-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/notebook-controller-role-binding created
configmap/notebook-controller-config-dm5b6dd458 created
service/notebook-controller-service created
deployment.apps/notebook-controller-deployment created
```

프로파일을 등록해줍니다.

```bash
> k apply -f profiles.yaml
customresourcedefinition.apiextensions.k8s.io/profiles.kubeflow.org created
serviceaccount/profiles-controller-service-account created
role.rbac.authorization.k8s.io/profiles-leader-election-role created
rolebinding.rbac.authorization.k8s.io/profiles-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/profiles-cluster-rolebinding created
configmap/namespace-labels-data-4df5t8mdgf created
configmap/profiles-config-46c7tgh6fd created
service/profiles-kfam created
deployment.apps/profiles-deployment created
virtualservice.networking.istio.io/profiles-kfam created
authorizationpolicy.security.istio.io/profiles-kfam created
```

volume-web-app을 생성해줍니다.

```bash
> k apply -f volumes-web-app.yaml
serviceaccount/volumes-web-app-service-account created
clusterrole.rbac.authorization.k8s.io/volumes-web-app-cluster-role created
clusterrole.rbac.authorization.k8s.io/volumes-web-app-kubeflow-volume-ui-admin created
clusterrole.rbac.authorization.k8s.io/volumes-web-app-kubeflow-volume-ui-edit created
clusterrole.rbac.authorization.k8s.io/volumes-web-app-kubeflow-volume-ui-view created
clusterrolebinding.rbac.authorization.k8s.io/volumes-web-app-cluster-role-binding created
configmap/volumes-web-app-parameters-57h65c44mg created
service/volumes-web-app-service created
deployment.apps/volumes-web-app-deployment created
destinationrule.networking.istio.io/volumes-web-app created
virtualservice.networking.istio.io/volumes-web-app-volumes-web-app created
authorizationpolicy.security.istio.io/volumes-web-app created
```

tensorboard-web-app을 생성해줍니다.

```bash
serviceaccount/tensorboards-web-app-service-account created
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-cluster-role created
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-kubeflow-tensorboard-ui-admin created
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-kubeflow-tensorboard-ui-edit created
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-kubeflow-tensorboard-ui-view created
clusterrolebinding.rbac.authorization.k8s.io/tensorboards-web-app-cluster-role-binding created
configmap/tensorboards-web-app-parameters-642bbg7t66 created
service/tensorboards-web-app-service created
deployment.apps/tensorboards-web-app-deployment created
destinationrule.networking.istio.io/tensorboards-web-app created
virtualservice.networking.istio.io/tensorboards-web-app-tensorboards-web-app created
authorizationpolicy.security.istio.io/tensorboards-web-app created
```

tensorboard-controller를 생성해줍니다.

```bash
> k apply -f tensorboard-controller.yaml
customresourcedefinition.apiextensions.k8s.io/tensorboards.tensorboard.kubeflow.org created
serviceaccount/tensorboard-controller-controller-manager created
role.rbac.authorization.k8s.io/tensorboard-controller-leader-election-role created
clusterrole.rbac.authorization.k8s.io/tensorboard-controller-manager-role created
clusterrole.rbac.authorization.k8s.io/tensorboard-controller-metrics-reader created
clusterrole.rbac.authorization.k8s.io/tensorboard-controller-proxy-role created
rolebinding.rbac.authorization.k8s.io/tensorboard-controller-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/tensorboard-controller-manager-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/tensorboard-controller-proxy-rolebinding created
configmap/tensorboard-controller-config-mm64f92kbt created
service/tensorboard-controller-controller-manager-metrics-service created
deployment.apps/tensorboard-controller-deployment created
```

training-operator를 설치해줍니다.

```bash
> k apply -f training-operator.yaml
customresourcedefinition.apiextensions.k8s.io/mpijobs.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/mxjobs.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/paddlejobs.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/pytorchjobs.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/tfjobs.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/xgboostjobs.kubeflow.org created
serviceaccount/training-operator created
clusterrole.rbac.authorization.k8s.io/kubeflow-training-admin created
clusterrole.rbac.authorization.k8s.io/kubeflow-training-edit created
clusterrole.rbac.authorization.k8s.io/kubeflow-training-view created
clusterrole.rbac.authorization.k8s.io/training-operator created
clusterrolebinding.rbac.authorization.k8s.io/training-operator created
service/training-operator created
deployment.apps/training-operator created
```

user-namesapce를 생성해줍니다.

```bash
> k apply -f user-namespace.yaml
configmap/default-install-config-9h2h2b6hbk created
profile.kubeflow.org/kubeflow-user-example-com created
```

jupyter noteboot web app을 설치해줍니다.

```bash
> k apply -f jupyter-web-app.yaml
serviceaccount/jupyter-web-app-service-account created
role.rbac.authorization.k8s.io/jupyter-web-app-jupyter-notebook-role created
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-cluster-role created
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-kubeflow-notebook-ui-admin created
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-kubeflow-notebook-ui-edit created
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-kubeflow-notebook-ui-view created
rolebinding.rbac.authorization.k8s.io/jupyter-web-app-jupyter-notebook-role-binding created
clusterrolebinding.rbac.authorization.k8s.io/jupyter-web-app-cluster-role-binding created
configmap/jupyter-web-app-config-92bgck72t2 created
configmap/jupyter-web-app-logos created
configmap/jupyter-web-app-parameters-42k97gcbmb created
service/jupyter-web-app-service created
deployment.apps/jupyter-web-app-deployment created
destinationrule.networking.istio.io/jupyter-web-app created
virtualservice.networking.istio.io/jupyter-web-app-jupyter-web-app created
authorizationpolicy.security.istio.io/jupyter-web-app created
```

설치 완료 후, service를 다음과 같이 포트 포워딩해서 서버에 접근합니다.

```bash
k port-forward svc/istio-ingressgateway -n istio-system 8080:80
```
