var Builder, Kind, Maybe, NamedFunction, Type, assertType, define, i, j, len, len1, ref, ref1, ref2, setKind, setType, type;

ref = require("type-utils"), Kind = ref.Kind, Maybe = ref.Maybe, setType = ref.setType, setKind = ref.setKind, assertType = ref.assertType;

NamedFunction = require("NamedFunction");

Builder = require("builder");

define = require("define");

module.exports = Type = NamedFunction("Type", function(name, func) {
  var self;
  self = Type.Builder(name, func);
  self._phases.initType.push(function(type) {
    return Type.augment(type);
  });
  return self;
});

setKind(Type, Function);

define(Type, {
  Builder: require("./TypeBuilder"),
  augment: function(type, inheritable) {
    type.Maybe = Maybe(type);
    if (inheritable !== false) {
      type.Kind = Kind(type);
    }
    return setType(type, Type);
  }
});

ref1 = [Number, String, Boolean, Symbol, Array, Date, RegExp];
for (i = 0, len = ref1.length; i < len; i++) {
  type = ref1[i];
  Type.augment(type, false);
}

ref2 = [Object, Function, Error, Type, Type.Builder, Builder];
for (j = 0, len1 = ref2.length; j < len1; j++) {
  type = ref2[j];
  Type.augment(type);
}

//# sourceMappingURL=../../map/src/Type.map
