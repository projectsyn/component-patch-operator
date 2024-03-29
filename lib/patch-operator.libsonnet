/**
 * \file Library with public methods provided by component patch-operator.
 */

local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local inv = kap.inventory();
local patch_operator_params = inv.parameters.patch_operator;
local namespace = patch_operator_params.namespace;
local instance = inv.parameters._instance;

local apiVersion = 'redhatcop.redhat.io/v1alpha1';

local obj_data(obj) =
  local apigrp = std.split(obj.apiVersion, '/')[0];
  {
    apiVersion: obj.apiVersion,
    apigroup:: if apigrp == 'v1' then '' else apigrp,
    kind: obj.kind,
    name: obj.metadata.name,
    namespace: if std.objectHas(obj.metadata, 'namespace') then obj.metadata.namespace,
  };

local replaceColon(str) =
  std.strReplace(str, ':', '-');

// Generate name for the Patch object based on the patch's target object
// We use some bytes of the md5 hash to avoid most collisions for
// cluster-scoped objects with the same name and kind but different apiGroups.
// Note that we don't add apigroup to the plain-text part of the generated
// name, since the apigroups can be quite long for custom resources.
local obj_name(objdata) =
  // Some objects like ClusterRoleBinding can contain colons.
  local name = replaceColon(objdata.name);
  local unhashed = '%s-%s-%s-%s-%s' % [ instance, objdata.kind, objdata.apigroup, objdata.namespace, name ];
  // Take 15 characters of the md5 hash, to leave room for a human-readable
  // prefix. We've not observed any hash collisions with the 15 byte prefix of
  // the md5 hash so far.
  local hashed = std.substr(std.md5(unhashed), 0, 15);

  local prefix =
    local p =
      if objdata.namespace != null then
        // for namespaced objects, use `<ns>-<name>` as the prefix
        '%s-%s' % [ std.asciiLower(objdata.namespace), name ]
      else
        // for cluster-scoped objects, use `<kind>-<name>` as the prefix
        // We could also add `<apigroup>` in the prefix, but we don't
        // need to do this, since the apigroup is part of the hashed string.
        '%s-%s' % [ std.asciiLower(objdata.kind), name ];
    // Trim the prefix if it's too long, make sure the kind/namespace part of
    // the prefix remains.
    if std.length(p) > 47 then
      std.substr(p, 0, 47)
    else
      p;

  local n = '%s-%s' % [ prefix, hashed ];

  assert
    std.length(n) <= 63 :
    "name generated by obj_name() is longer than 63 characters, this shouldn't happen";
  n;

local render_patch(patch, rl_version, patch_id='patch1') =
  std.trace(
    'Parameter `rl_version` of `render_patch` is deprecated and no longer used, it will be removed in a future version.',
    { [patch_id]: patch }
  );


local patch(name, saName, targetobjref, patchtemplate, patchtype='application/strategic-merge-patch+json') =
  kube._Object(apiVersion, 'Patch', name) {
    metadata+: {
      namespace: namespace,
      annotations+: {
        'argocd.argoproj.io/sync-options': 'SkipDryRunOnMissingResource=true',
      },
    },
    spec+: {
      serviceAccountRef: {
        name: saName,
      },
      patches: {
        [name + '-patch']: {
          targetObjectRef: targetobjref,
          patchTemplate: std.manifestYamlDoc(patchtemplate),
          patchType: patchtype,
        },
      },
    },
  };

local Patch(targetobj, patchtemplate, patchstrategy='application/strategic-merge-patch+json') =
  local objdata = obj_data(targetobj);
  local name = obj_name(objdata);
  [
    patch(
      name,
      patch_operator_params.patch_serviceaccount.name,
      std.prune(objdata),
      patchtemplate,
      patchstrategy
    ),
  ];

{
  apiVersion: apiVersion,
  Patch: Patch,
  renderPatch: render_patch,
}
