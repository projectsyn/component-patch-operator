local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local inv = kap.inventory();
local params = inv.parameters.patch_operator;

local external_certs = params.external_certificates;

local cm_enabled = params.helm_values.enableCertManager;
local emit_external_certs =
  if std.length(external_certs) > 0 then (
    if cm_enabled then
      std.trace(
        'Not emitting configured external certificates, ' +
        'since cert-manager integration is enabled. Please set ' +
        '`helm_values.enableCertManager=false` to use external certificates.',
        false
      )
    else
      true
  ) else
    false;

local tls_secret(name, data) = kube.Secret(name) {
  data:: {},
  stringData:
    data +
    if !std.objectHas(data, 'ca.crt') then {
      'ca.crt': super['tls.crt'],
    } else {},
  type: 'kubernetes.io/tls',
};

// XXX(sg): the names are copied from the Helm chart. If the names in the
// chart change, we'll have to update this file.
local cert_secrets = [
  tls_secret('patch-operator-certs', external_certs.metrics),
  tls_secret('webhook-server-cert', external_certs.webhook),
];

{
  [if emit_external_certs then '20_external_certificates']:
    cert_secrets,
}
