[Kubeflow 개론 및 Ubuntu 환경에서의 설치](https://zerohertz.github.io/kubeflow/)

[ML Automation](https://summer-carpenter-efa.notion.site/Kubeflow-Automation-09682266dacd471dbf97ccb937297675?pvs=4)

[Kubeflow 띄(우려고하)기](https://proud-passbook-808.notion.site/Kubeflow-a9b3de53975146019545ff17bc7140cf?pvs=4)

미니쿠베 시작

```bash
minikube start --cpus 4 --memory 16384  \
    --network-plugin=cni \
    --enable-default-cni \
    --container-runtime=containerd \
    --bootstrapper=kubeadm
```

네임스페이스 생성

```bash
k create ns kubeflow
k create ns istio-system
k create ns auth
```

kubeflow에 다음 레이블을 추가해줍니다.

```bash
k label ns kubeflow istio-injection=enabled
```

local storage class 수정을 해줍니다.

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.20/deploy/local-path-storage.yaml
kubectl patch storageclass local-path  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
# storage class 수정해주기
k edit sc standard
```

standard storage class에서 default storage class를 제거해줍니다. `storageclass.kubernetes.io/is-default-class` 이 내용을 false로 변경해줍니다.

```yaml
 1 # Please edit the object below. Lines beginning with a '#' will be ignored,
  2 # and an empty file will abort the edit. If an error occurs while saving this file will be
  3 # reopened with the relevant failures.
  4 #
  5 apiVersion: storage.k8s.io/v1
  6 kind: StorageClass
  7 metadata:
  8   annotations:
  9     kubectl.kubernetes.io/last-applied-configuration: |
 10       {"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"},"labels":{"addonmanager.kubernetes.io/mode":"Ens    ureExists"},"name":"standard"},"provisioner":"k8s.io/minikube-hostpath"}
 11     storageclass.kubernetes.io/is-default-class: "false"
 12   creationTimestamp: "2023-08-06T06:40:30Z"
 13   labels:
 14     addonmanager.kubernetes.io/mode: EnsureExists
 15   name: standard
 16   resourceVersion: "269"
 17   uid: d2a18770-95b2-4462-b942-b1239ea76436
 18 provisioner: k8s.io/minikube-hostpath
 19 reclaimPolicy: Delete
 20 volumeBindingMode: Immediate
```

아래값 처럼 local-path에만 default가 되도록해줍니다.

```bash
k get sc
NAME                   PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path      Delete          WaitForFirstConsumer   false                  106s
standard               k8s.io/minikube-hostpath   Delete          Immediate              false                  9m40s
```

이제 파일을 순서대로 실행해줍니다.

```bash
cd run
k apply -f cert-manager.yaml
k apply -f cluster-issuer.yaml
k apply -f istio-crds.yaml
k apply -f istio-install.yaml
k apply -f dex.yaml
k apply -f oidc-authservice.yaml
k apply -f kubeflow-roles.yaml
k apply -f kubeflow-istio-resources.yaml
k apply -f mtls.yaml
k apply -f pipeline-platform-agnostic-multi-user.yaml
k apply -f katib-with-kubeflow.yaml
k apply -f centraldashboard.yaml
k apply -f admission-wenhook.yaml
k apply -f notebook-controller.yaml
k apply -f profiles.yaml
k apply -f volumes-web-app.yaml
k apply -f tensorboard-web-app.yaml
k apply -f tensorboard-controller.yaml
k apply -f training-operator.yaml
k apply -f user-namespace.yaml
```

port forwarding으로 다음 명령어를 입력해줍니다.

```bash
k port-forward svc/istio-ingressgateway -n istio-system 8080:80
```

크롬 시크릿창이나 safari로 접속해줍니다. 일반 크롬창에서는 계속 대기중에 있는데 이 문제는 해결하지 못했습니다.
