// main template for patch-operator
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.patch_operator;

local ocp4 = inv.parameters.facts.distribution == 'openshift4';

local patch_sa = kube.ServiceAccount(params.patch_serviceaccount.name) {
  metadata+: {
    namespace: params.namespace,
  },
};

local patch_crb = kube.ClusterRoleBinding('syn:patch-operator:patch-cluster-admin') {
  roleRef: {
    apiGroup: 'rbac.authorization.k8s.io',
    kind: 'ClusterRole',
    name: params.patch_serviceaccount.role_name,
  },
  subjects_: [ patch_sa ],
};

local patch_rbac = [
  patch_sa,
  patch_crb,
];

// Define outputs below
{
  '00_namespace': kube.Namespace(params.namespace) {
    metadata+: {
      labels+: {
        [if ocp4 then 'openshift.io/cluster-monitoring']: 'true',
      },
    },
  },
  '10_rbac': patch_rbac,
}
