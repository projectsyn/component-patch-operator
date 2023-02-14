local p = std.trace(
  'importing resource-locker.libjsonnet is deprecated, ' +
  "please switch to `import 'patch-operator.libsonnet'`. " +
  'See https://hub.syn.tools/patch-operator/how-tos/migrate-from-resource-locker.html for more details.',
  import 'lib/patch-operator.libsonnet'
);

local Resource(obj) =
  error "patch-operator doesn't support kind `Resource`, please manage full resources directly in your component";

p {
  Resource: Resource,
}
