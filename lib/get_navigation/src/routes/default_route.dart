import 'package:flutter/cupertino.dart';

import '../../../refreshed.dart';
import '../router_report.dart';

/// A mixin that provides route lifecycle event reporting to a [RouterReportManager].
///
/// This mixin is intended to be used with [State] objects of [StatefulWidget]s
/// to report the initialization and disposal of routes to a [RouterReportManager].
///
/// Example:
///
/// ```dart
/// class MyRouteState extends State<MyRoute> with RouteReportMixin<MyRoute> {
///   // Implement widget state...
/// }
/// ```
@optionalTypeArgs
mixin RouteReportMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    RouterReportManager.instance.reportCurrentRoute(this);
  }

  @override
  void dispose() {
    super.dispose();
    RouterReportManager.instance.reportRouteDispose(this);
  }
}

/// A mixin that provides page route lifecycle event reporting to a [RouterReportManager].
///
/// This mixin is intended to be used with classes that extend [Route] to report
/// the installation and disposal of page routes to a [RouterReportManager].
///
/// Example:
///
/// ```dart
/// class MyPageRoute extends PageRoute<MyPage> with PageRouteReportMixin<MyPage> {
///   // Implement page route...
/// }
/// ```
mixin PageRouteReportMixin<T> on Route<T> {
  @override
  void install() {
    super.install();
    RouterReportManager.instance.reportCurrentRoute(this);
  }

  @override
  void dispose() {
    super.dispose();
    RouterReportManager.instance.reportRouteDispose(this);
  }
}

class GetPageRoute<T> extends PageRoute<T>
    with GetPageRouteTransitionMixin<T>, PageRouteReportMixin {
  /// Creates a page route for use in an iOS designed app.
  ///
  /// The [builder], [maintainState], and [fullscreenDialog] arguments must not
  /// be null.
  GetPageRoute({
    super.settings,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.opaque = true,
    this.parameter,
    this.gestureWidth,
    this.curve,
    this.alignment,
    this.transition,
    this.popGesture,
    this.customTransition,
    this.barrierDismissible = false,
    this.barrierColor,
    BindingsInterface? binding,
    List<BindingsInterface> bindings = const [],
    this.binds,
    this.routeName,
    this.page,
    this.title,
    this.showCupertinoParallax = true,
    this.barrierLabel,
    this.maintainState = true,
    super.fullscreenDialog,
    this.middlewares,
  }) : bindings = (binding == null) ? bindings : [...bindings, binding];

  @override
  final Duration transitionDuration;
  @override
  final Duration reverseTransitionDuration;

  final GetPageBuilder? page;
  final String? routeName;
  final CustomTransition? customTransition;
  final List<BindingsInterface> bindings;
  final Map<String, String>? parameter;
  final List<Bind>? binds;

  @override
  final bool showCupertinoParallax;

  @override
  final bool opaque;
  final bool? popGesture;

  @override
  final bool barrierDismissible;
  final Transition? transition;
  final Curve? curve;
  final Alignment? alignment;
  final List<GetMiddleware>? middlewares;

  @override
  final Color? barrierColor;

  @override
  final String? barrierLabel;

  @override
  final bool maintainState;

  @override
  void dispose() {
    super.dispose();
    final middlewareRunner = MiddlewareRunner(middlewares);
    middlewareRunner.runOnPageDispose();
    _child = null;
  }

  Widget? _child;

  Widget _getChild() {
    if (_child != null) return _child!;
    final middlewareRunner = MiddlewareRunner(middlewares);

    final localBinds = [if (binds != null) ...binds!];

    final bindingsToBind = middlewareRunner
        .runOnBindingsStart(bindings.isNotEmpty ? bindings : localBinds);

    final pageToBuild = middlewareRunner.runOnPageBuildStart(page)!;

    if (bindingsToBind != null && bindingsToBind.isNotEmpty) {
      if (bindingsToBind is List<BindingsInterface>) {
        for (final item in bindingsToBind) {
          final dep = item.dependencies();
          if (dep is List<Bind>) {
            _child = Binds(
              binds: dep,
              child: middlewareRunner.runOnPageBuilt(pageToBuild()),
            );
          }
        }
      } else if (bindingsToBind is List<Bind>) {
        _child = Binds(
          binds: bindingsToBind,
          child: middlewareRunner.runOnPageBuilt(pageToBuild()),
        );
      }
    }

    return _child ??= middlewareRunner.runOnPageBuilt(pageToBuild());
  }

  @override
  Widget buildContent(BuildContext context) {
    return _getChild();
  }

  @override
  final String? title;

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';

  @override
  final double Function(BuildContext context)? gestureWidth;
}
