local com = import 'lib/commodore.libjsonnet';
local inv = com.inventory();
// The hiera parameters for the component
local params = inv.parameters.patch_operator;

local priotityclassPatch = {
  spec+: {
    template+: {
      spec+: {
        priorityClassName: params.priority_class,
      },
    },
  },
};

local deployFile = com.yaml_load(std.extVar('output_path') + '/' + 'manager.yaml');

{
  manager: deployFile + priotityclassPatch,
}
