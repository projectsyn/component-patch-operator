local com = import 'lib/commodore.libjsonnet';
local inv = com.inventory();
local params = inv.parameters.patch_operator;

local manifests_dir = std.extVar('output_path');

local external_certs = params.external_certificates;
local emit_external_certs =
  !params.helm_values.enableCertManager &&
  std.length(external_certs) > 0;

local fixupFn(obj) =
  if obj.kind == 'Service' then
    local secretName =
      obj.metadata.annotations['service.alpha.openshift.io/serving-cert-secret-name'];
    obj {
      metadata+: {
        annotations+: {
          'service.alpha.openshift.io/serving-cert-secret-name': 'ocp-%s' % [ secretName ],
        },
      },
    }
  else if
    emit_external_certs &&
    std.member([
      'MutatingWebhookConfiguration',
      'ValidatingWebhookConfiguration',
    ], obj.kind) then
    obj {
      webhooks: [
        w {
          clientConfig+: {
            // use ca.crt if specified, and assume self-signed cert otherwise.
            caBundle: std.get(
              external_certs.webhook,
              'ca.crt',
              external_certs.webhook['tls.crt']
            ),
          },
        }
        for w in super.webhooks
      ],
    }
  else
    obj;

com.fixupDir(manifests_dir, fixupFn)
