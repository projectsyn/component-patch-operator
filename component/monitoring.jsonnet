local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local inv = kap.inventory();
local params = inv.parameters.patch_operator;

local alertlabels = {
  syn: 'true',
  syn_component: 'patch-operator',
};
local runbook_url(name) = 'https://hub.syn.tools/patch-operator/runbooks/%s.html' % [ name ];

local alerts = function(name, groupName, alerts)
  com.namespaced(params.namespace, kube._Object('monitoring.coreos.com/v1', 'PrometheusRule', name) {
    spec+: {
      groups+: [
        {
          name: groupName,
          rules:
            std.filterMap(
              function(field) alerts[field].enabled == true,
              function(field) alerts[field].rule {
                alert: field,
                labels+: alertlabels,
                annotations+: {
                  runbook_url: runbook_url(field),
                },
              },
              std.objectFields(alerts)
            ),
        },
      ],
    },
  });

[ alerts('patch-operator-prometheus-rule', 'patch.alerts', params.alerts) ]
