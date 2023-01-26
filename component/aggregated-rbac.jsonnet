local kube = import 'lib/kube.libjsonnet';
local p = import 'lib/patch-operator.libsonnet';

local cluster_reader =
  kube.ClusterRole('syn:patch-operator:cluster-reader') {
    metadata+: {
      labels+: {
        'rbac.authorization.k8s.io/aggregate-to-cluster-reader': 'true',
      },
    },
    rules: [
      {
        apiGroups: [ std.split(p.apiVersion, '/')[0] ],
        resources: [ 'patches' ],
        verbs: [ 'get', 'list', 'watch' ],
      },
    ],
  };

{
  '10_aggregated_rbac': [
    cluster_reader,
  ],
}
