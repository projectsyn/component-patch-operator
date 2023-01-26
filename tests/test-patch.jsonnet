local kube = import 'lib/kube.libjsonnet';
local p = import 'lib/patch-operator.libsonnet';


p.Patch(
  kube.Deployment('test') {
    metadata+: {
      namespace: 'foo',
    },
  },
  {
    spec: {
      replicas: 5,
    },
  }
)
