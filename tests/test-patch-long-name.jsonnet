local kube = import 'lib/kube.libjsonnet';
local p = import 'lib/patch-operator.libsonnet';

p.Patch(
  kube.ClusterRoleBinding('system:build-strategy-docker-binding'),
  {
    annotations: {
      'rbac.authorization.kubernetes.io/autoupdate': 'false',
    },
  }
)
