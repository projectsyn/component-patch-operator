// main template for patch-operator
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.patch_operator;

local ocp4 = inv.parameters.facts.distribution == 'openshift4';

// Define outputs below
{
  '00_namespace': kube.Namespace(params.namespace) {
    metadata+: {
      labels+: {
        [if ocp4 then 'openshift.io/cluster-monitoring']: 'true',
      },
    },
  },
}
