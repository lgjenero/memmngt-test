import 'dart:async';
import 'dart:convert';

import 'context.dart';
import 'future.dart';

enum ModelContextChangeType { add, remove, mergeInto, merged }

class ModelContextChange {
  final ModelContextChangeType type;
  final Set<Model> models;
  final ModelContext? context;

  ModelContextChange._(this.type, this.models, {this.context});

  ModelContextChange.add(Model model) : this._(ModelContextChangeType.add, {model});
  ModelContextChange.addAll(Set<Model> models) : this._(ModelContextChangeType.add, models);
  ModelContextChange.remove(Model model) : this._(ModelContextChangeType.remove, {model});
  ModelContextChange.removeAll(Set<Model> models) : this._(ModelContextChangeType.remove, models);
  ModelContextChange.mergedInto(Set<Model> models, ModelContext context)
      : this._(ModelContextChangeType.mergeInto, models, context: context);
  ModelContextChange.merged(Set<Model> models) : this._(ModelContextChangeType.merged, models);
}

class ModelContext extends OperationContext {
  // final Map<int, int> _indexes = {};
  final Map<int, Model> _modelMap = {};
  // final List<Model> _modelList = [];

  final _streamController = StreamController<ModelContextChange>.broadcast(sync: true);

  void add(Model model, {bool notify = true}) {
    // _indexes[model.hashCode] = _modelList.length;
    _modelMap[model.hashCode] = model;
    // _modelList.add(model);

    if (notify) {
      _streamController.add(ModelContextChange.add(model));
    }
  }

  void remove(Model model, {bool notify = true}) {
    // int? idx = _indexes.remove(model.hashCode);
    // if (idx == null) {
    //   throw Exception('model not in context');
    // }

    // print('removing model --> $model from $_modelMap');

    if (!_modelMap.containsKey(model.hashCode)) {
      throw Exception('model not in context --> $model');
    }
    _modelMap.remove(model.hashCode);
    // _modelList.removeAt(idx);

    // print('removing model --> $model from $_modelMap');

    if (notify) {
      _streamController.add(ModelContextChange.remove(model));
    }
  }

  void merge(ModelContext context) {
    final models = context.models;
    for (final model in models) {
      add(model, notify: false);
    }

    _streamController.add(ModelContextChange.merged(models));
  }

  void mergeInto(ModelContext context) {
    final models = context.models;
    _streamController.add(ModelContextChange.mergedInto(models, context));
  }

  // List<Model> before(Model model) {
  //   int? idx = _indexes[model.hashCode];
  //   if (idx == null) {
  //     throw Exception('model not in context');
  //   }
  //   return _modelList.sublist(0, idx);
  // }

  // List<Model> after(Model model) {
  //   int? idx = _indexes[model.hashCode];
  //   if (idx == null) {
  //     throw Exception('model not in context');
  //   }
  //   return _modelList.sublist(idx + 1);
  // }

  bool contains(Model model) => _modelMap.containsKey(model.hashCode);

  Stream<ModelContextChange> get changes => _streamController.stream;

  Set<Model> get models => _modelMap.values.toSet();

  ModelContext() : super(randomOperationId());

  @override
  String toString() {
    return 'ModelContext(id: $operationId)';
  }
}

class Model {
  Model(this.id, this.onInit, this.onDeInit);

  final String id;
  final FutureOr<void> Function() onInit;
  final FutureOr<void> Function() onDeInit;

  int _initCount = 0;
  int get initCount => _initCount;

  bool _canDeinit = true;

  final List<Model> _children = [];

  ModelContext? _context;
  final List<Model> _referencing = [];
  StreamSubscription? _streamSubscription;

  void addChildren(List<Model> children) {
    if (_initCount > 0) {
      for (final child in children) {
        _children.add(child);

        runInContext(_context!, () => child.init());
      }
    } else {
      _children.addAll(children);
    }
  }

  void removeChildren(List<Model> children) {
    if (_initCount > 0) {
    } else {
      _children.removeWhere((e) => children.contains(e));
    }
  }

  List<Model> get children => [..._children];

  FutureOr<void> init() {
    final currentContext = tryGetContext<ModelContext>();

    // content exists
    if (currentContext != null) {
      if (_context == null) {
        _setupContext(currentContext);
      } else if (_context!.operationId != currentContext.operationId) {
        currentContext.mergeInto(_context!);
        _context!.merge(currentContext);
      }

      final alreadyLoading = _context!.contains(this);
      if (!alreadyLoading) {
        currentContext.add(this);
      }

      return _onInit();
    }

    // content does not exist
    final newContext = ModelContext();
    newContext.add(this);
    if (_context == null) {
      _setupContext(newContext);
    } else {
      _context!.merge(newContext);
      newContext.mergeInto(_context!);
    }
    return runInContext(newContext, () => _onInit());
  }

  FutureOr<void> deInit() {
    _onDeinit();
  }

  bool references(Model model) => _children.contains(model);

  bool referencedBy(Model model) => _referencing.contains(model);

  List<Model> get referencing => [..._referencing];

  bool get canDeinit => _initCount <= _referencing.length;

  // Private

  FutureOr<void> _onInit() {
    if (_initCount++ == 0) {
      print('_onInit($id) --> $_initCount | $_referencing');
      List<FutureOr<void>> futureOrs = [];

      futureOrs.add(onInit.call());

      for (final child in _children) {
        futureOrs.add(child.init());
      }

      return FutureOrUtils.wait(futureOrs).then((_) => null);
    }
  }

  FutureOr<void> _onDeinit() {
    --_initCount;

    print('_onDeinit($id) --> $_initCount | $_referencing');

    if (_initCount == _referencing.length && _canDeinit) {
      if (_referencing.isNotEmpty) {
        // TODO: - there can be a loop - need to check this

        // best effort - check in the context list if there is some object where initCount > _referencing.length

        for (final model in _context!.models) {
          if (!model.canDeinit) {
            return null;
          }
        }
      }

      _canDeinit = false;
      _context!.remove(this);

      List<FutureOr<void>> futureOrs = [];

      for (final child in [..._children]) {
        futureOrs.add(child.deInit());
      }

      futureOrs.add(onDeInit.call());

      return FutureOrUtils.wait(futureOrs).then((_) => _streamSubscription?.cancel());
    }
  }

  void _setupContext(ModelContext context, {bool loadBefore = true}) {
    _context = context;

    if (loadBefore) {
      final models = context._modelMap.values.toList();
      for (final model in models) {
        if (model.references(this)) {
          _referencing.add(model);
        }
      }
    }

    _streamSubscription = context.changes.listen((change) {
      switch (change.type) {
        case ModelContextChangeType.add:
          for (final model in change.models) {
            if (model.references(this)) {
              _referencing.add(model);
            }
          }
          break;
        case ModelContextChangeType.remove:
          for (final model in change.models) {
            if (_referencing.contains(model)) {
              _referencing.remove(model);
            }
          }
          break;
        case ModelContextChangeType.mergeInto:
          if (!change.models.contains(this)) {
            for (final model in change.models) {
              if (model.references(this)) {
                _referencing.add(model);
              }
            }
          }
          _setupContext(change.context!, loadBefore: false);
          break;
        case ModelContextChangeType.merged:
          if (!change.models.contains(this)) {
            for (final model in change.models) {
              if (model.references(this)) {
                _referencing.add(model);
              }
            }
          }
          break;
      }
    });
  }

  @override
  String toString() {
    return 'Model(id: $id)';
  }
}
