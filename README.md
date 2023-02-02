# che-quarkus-workspace
Demo for Quarkus Dev Mode in Eclipse Che

```bash
cat < EOV | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: quarkus-dev-services
rules:
- apiGroups:
  - batch
  resources:
  - jobs
  - jobs/status
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - pods/portforward
  verbs:
  - get
  - list
  - watch
  - create
  - delete
  - deletecollection
  - patch
  - update
EOF
```

```bash
oc policy add-role-to-user quarkus-dev-services developer -n developer-che
```

kubedock server --port-forward

export TESTCONTAINERS_RYUK_DISABLED=true
export TESTCONTAINERS_CHECKS_DISABLE=true
export DOCKER_HOST=tcp://127.0.0.1:2475
mvn test
