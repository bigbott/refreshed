// ignore_for_file: cascade_invocations

import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:refreshed/get_navigation/src/dialog/dialog_route.dart";
import "package:refreshed/get_navigation/src/root/get_root.dart";
import "package:refreshed/refreshed.dart";

/// It replaces the Flutter Navigator, but needs no context.
/// You can to use navigator.push(YourRoute()) rather
/// Navigator.push(context, YourRoute());
NavigatorState? get navigator => NavigationExtension(Get).key.currentState;

extension PopupUtilsExtension on GetInterface {
  Future<T?> bottomSheet<T>(
    Widget bottomsheet, {
    Color? backgroundColor,
    double? elevation,
    bool isPersistent = false,
    ShapeBorder? shape,
    Clip? clipBehavior,
    Color? barrierColor,
    bool? ignoreSafeArea,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    RouteSettings? settings,
    Duration? enterBottomSheetDuration,
    Duration? exitBottomSheetDuration,
    Curve? curve,
    BoxConstraints? contraints,
    bool? showDragHandle = true,
    Color? dragHandleColor,
    Size? dragHandleSize,
    BottomSheetDragEndHandler? onDragEnd,
    BottomSheetDragStartHandler? onDragStart,
    Color? shadowColor,
  }) =>
      Navigator.of(overlayContext!, rootNavigator: useRootNavigator).push(
        GetModalBottomSheetRoute<T>(
          builder: (_) => bottomsheet,
          isPersistent: isPersistent,
          theme: Theme.of(key.currentContext!),
          isScrollControlled: isScrollControlled,
          barrierLabel: MaterialLocalizations.of(key.currentContext!)
              .modalBarrierDismissLabel,
          backgroundColor: backgroundColor,
          elevation: elevation,
          shape: shape,
          removeTop: ignoreSafeArea ?? true,
          clipBehavior: clipBehavior,
          isDismissible: isDismissible,
          modalBarrierColor: barrierColor,
          settings: settings,
          enableDrag: enableDrag,
          enterBottomSheetDuration:
              enterBottomSheetDuration ?? const Duration(milliseconds: 250),
          exitBottomSheetDuration:
              exitBottomSheetDuration ?? const Duration(milliseconds: 200),
          curve: curve,
          constraints: contraints,
          showDragHandle: showDragHandle,
          dragHandleColor: dragHandleColor,
          dragHandleSize: dragHandleSize,
          onDragEnd: onDragEnd,
          onDragStart: onDragStart,
          shadowColor: shadowColor,
        ),
      );

  /// Show a dialog.
  /// You can pass a [transitionDuration] and/or [transitionCurve],
  /// overriding the defaults when the dialog shows up and closes.
  /// When the dialog closes, uses those animations in reverse.
  Future<T?> dialog<T>(
    Widget widget, {
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useSafeArea = true,
    GlobalKey<NavigatorState>? navigatorKey,
    Object? arguments,
    Duration? transitionDuration,
    Curve? transitionCurve,
    String? name,
    RouteSettings? routeSettings,
    String? id,
  }) {
    assert(debugCheckHasMaterialLocalizations(context!));

    final ThemeData theme = Theme.of(context!);
    return generalDialog<T>(
      pageBuilder: (
        BuildContext buildContext,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        final Widget pageChild = widget;
        Widget dialog = Builder(
          builder: (BuildContext context) =>
              Theme(data: theme, child: pageChild),
        );
        if (useSafeArea) {
          dialog = SafeArea(child: dialog);
        }
        return dialog;
      },
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context!).modalBarrierDismissLabel,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: transitionDuration ?? defaultDialogTransitionDuration,
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) =>
          FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: transitionCurve ?? defaultDialogTransitionCurve,
        ),
        child: child,
      ),
      navigatorKey: navigatorKey,
      routeSettings:
          routeSettings ?? RouteSettings(arguments: arguments, name: name),
      id: id,
    );
  }

  /// Api from showGeneralDialog with no context
  Future<T?> generalDialog<T>({
    required RoutePageBuilder pageBuilder,
    bool barrierDismissible = false,
    String? barrierLabel,
    Color barrierColor = const Color(0x80000000),
    Duration transitionDuration = const Duration(milliseconds: 200),
    RouteTransitionsBuilder? transitionBuilder,
    GlobalKey<NavigatorState>? navigatorKey,
    RouteSettings? routeSettings,
    String? id,
  }) {
    assert(!barrierDismissible || barrierLabel != null);
    final GlobalKey<NavigatorState>? key =
        navigatorKey ?? Get.nestedKey(id)?.navigatorKey;
    final NavigatorState nav = key?.currentState ??
        Navigator.of(
          overlayContext!,
          rootNavigator: true,
        ); //overlay context will always return the root navigator
    return nav.push<T>(
      GetDialogRoute<T>(
        pageBuilder: pageBuilder,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        barrierColor: barrierColor,
        transitionDuration: transitionDuration,
        transitionBuilder: transitionBuilder,
        settings: routeSettings,
      ),
    );
  }

  /// Custom UI Dialog.
  Future<T?> defaultDialog<T>({
    String title = "Alert",
    EdgeInsetsGeometry? titlePadding,
    TextStyle? titleStyle,
    Widget? content,
    String? id,
    EdgeInsetsGeometry? contentPadding,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    VoidCallback? onCustom,
    Color? cancelTextColor,
    Color? confirmTextColor,
    String? textConfirm,
    String? textCancel,
    String? textCustom,
    Widget? confirm,
    Widget? cancel,
    Widget? custom,
    Color? backgroundColor,
    bool barrierDismissible = true,
    Color? buttonColor,
    String middleText = "\n",
    TextStyle? middleTextStyle,
    double radius = 20.0,
    //   ThemeData themeData,
    List<Widget>? actions,

    // onWillPop Scope
    PopInvokedCallback? onWillPop,

    // the navigator used to push the dialog
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    final bool leanCancel = onCancel != null || textCancel != null;
    final bool leanConfirm = onConfirm != null || textConfirm != null;
    actions ??= <Widget>[];

    if (cancel != null) {
      actions.add(cancel);
    } else {
      if (leanCancel) {
        actions.add(
          TextButton(
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: buttonColor ?? theme.colorScheme.secondary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            onPressed: () {
              if (onCancel == null) {
                closeAllDialogs();
              } else {
                onCancel.call();
              }
            },
            child: Text(
              textCancel ?? "Cancel",
              style: TextStyle(
                color: cancelTextColor ?? theme.colorScheme.secondary,
              ),
            ),
          ),
        );
      }
    }
    if (confirm != null) {
      actions.add(confirm);
    } else {
      if (leanConfirm) {
        actions.add(
          TextButton(
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: buttonColor ?? theme.colorScheme.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: Text(
              textConfirm ?? "Ok",
              style: TextStyle(
                color: confirmTextColor ?? theme.colorScheme.surface,
              ),
            ),
            onPressed: () {
              onConfirm?.call();
            },
          ),
        );
      }
    }

    final Widget baseAlertDialog = AlertDialog(
      titlePadding: titlePadding ?? const EdgeInsets.all(8),
      contentPadding: contentPadding ?? const EdgeInsets.all(8),
      backgroundColor: backgroundColor ?? theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(radius),
        ),
      ),
      title: Text(title, textAlign: TextAlign.center, style: titleStyle),
      content: custom ??
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              content ??
                  Text(
                    middleText,
                    textAlign: TextAlign.center,
                    style: middleTextStyle,
                  ),
              const SizedBox(height: 16),
              ButtonTheme(
                minWidth: 78,
                height: 34,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                ),
              ),
            ],
          ),
      buttonPadding: EdgeInsets.zero,
    );

    return dialog<T>(
      onWillPop != null
          ? PopScope(
              onPopInvoked: onWillPop,
              child: baseAlertDialog,
            )
          : baseAlertDialog,
      barrierDismissible: barrierDismissible,
      navigatorKey: navigatorKey,
      id: id,
    );
  }

  SnackbarController rawSnackbar({
    String? title,
    String? message,
    Widget? titleText,
    Widget? messageText,
    Widget? icon,
    bool instantInit = true,
    bool shouldIconPulse = true,
    double? maxWidth,
    EdgeInsets margin = EdgeInsets.zero,
    EdgeInsets padding = const EdgeInsets.all(16),
    double borderRadius = 0.0,
    Color? borderColor,
    double borderWidth = 1.0,
    Color backgroundColor = const Color(0xFF303030),
    Color? leftBarIndicatorColor,
    List<BoxShadow>? boxShadows,
    Gradient? backgroundGradient,
    Widget? mainButton,
    OnTap? onTap,
    Duration? duration = const Duration(seconds: 3),
    bool isDismissible = true,
    DismissDirection? dismissDirection,
    bool showProgressIndicator = false,
    AnimationController? progressIndicatorController,
    Color? progressIndicatorBackgroundColor,
    Animation<Color>? progressIndicatorValueColor,
    SnackPosition snackPosition = SnackPosition.bottom,
    SnackStyle snackStyle = SnackStyle.floating,
    Curve forwardAnimationCurve = Curves.easeOutCirc,
    Curve reverseAnimationCurve = Curves.easeOutCirc,
    Duration animationDuration = const Duration(seconds: 1),
    SnackbarStatusCallback? snackbarStatus,
    double barBlur = 0.0,
    double overlayBlur = 0.0,
    Color? overlayColor,
    Form? userInputForm,
  }) {
    final GetSnackBar getSnackBar = GetSnackBar(
      snackbarStatus: snackbarStatus,
      title: title,
      message: message,
      titleText: titleText,
      messageText: messageText,
      snackPosition: snackPosition,
      borderRadius: borderRadius,
      margin: margin,
      duration: duration,
      barBlur: barBlur,
      backgroundColor: backgroundColor,
      icon: icon,
      shouldIconPulse: shouldIconPulse,
      maxWidth: maxWidth,
      padding: padding,
      borderColor: borderColor,
      borderWidth: borderWidth,
      leftBarIndicatorColor: leftBarIndicatorColor,
      boxShadows: boxShadows,
      backgroundGradient: backgroundGradient,
      mainButton: mainButton,
      onTap: onTap,
      isDismissible: isDismissible,
      dismissDirection: dismissDirection,
      showProgressIndicator: showProgressIndicator,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
      progressIndicatorValueColor: progressIndicatorValueColor,
      snackStyle: snackStyle,
      forwardAnimationCurve: forwardAnimationCurve,
      reverseAnimationCurve: reverseAnimationCurve,
      animationDuration: animationDuration,
      overlayBlur: overlayBlur,
      overlayColor: overlayColor,
      userInputForm: userInputForm,
    );

    final SnackbarController controller = SnackbarController(getSnackBar);

    if (instantInit) {
      controller.show();
    } else {
      ambiguate(Engine.instance)!.addPostFrameCallback((_) {
        controller.show();
      });
    }
    return controller;
  }

  SnackbarController showSnackbar(GetSnackBar snackbar) {
    final SnackbarController controller = SnackbarController(snackbar);
    controller.show();
    return controller;
  }

  SnackbarController snackbar(
    String title,
    String message, {
    Color? colorText,
    Duration? duration = const Duration(seconds: 3),
    bool instantInit = true,
    SnackPosition? snackPosition,
    Widget? titleText,
    Widget? messageText,
    Widget? icon,
    bool? shouldIconPulse,
    double? maxWidth,
    EdgeInsets? margin,
    EdgeInsets? padding,
    double? borderRadius,
    Color? borderColor,
    double? borderWidth,
    Color? backgroundColor,
    Color? leftBarIndicatorColor,
    List<BoxShadow>? boxShadows,
    Gradient? backgroundGradient,
    TextButton? mainButton,
    OnTap? onTap,
    OnHover? onHover,
    bool? isDismissible,
    bool? showProgressIndicator,
    DismissDirection? dismissDirection,
    AnimationController? progressIndicatorController,
    Color? progressIndicatorBackgroundColor,
    Animation<Color>? progressIndicatorValueColor,
    SnackStyle? snackStyle,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    Duration? animationDuration,
    double? barBlur,
    double? overlayBlur,
    SnackbarStatusCallback? snackbarStatus,
    Color? overlayColor,
    Form? userInputForm,
  }) {
    final GetSnackBar getSnackBar = GetSnackBar(
      snackbarStatus: snackbarStatus,
      titleText: titleText ??
          Text(
            title,
            style: TextStyle(
              color: colorText ?? iconColor ?? Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
      messageText: messageText ??
          Text(
            message,
            style: TextStyle(
              color: colorText ?? iconColor ?? Colors.black,
              fontWeight: FontWeight.w300,
              fontSize: 14,
            ),
          ),
      snackPosition: snackPosition ?? SnackPosition.top,
      borderRadius: borderRadius ?? 15,
      margin: margin ?? const EdgeInsets.all(12),
      duration: duration,
      barBlur: barBlur ?? 7.0,
      backgroundColor: backgroundColor ?? Colors.grey.withOpacity(0.2),
      icon: icon,
      shouldIconPulse: shouldIconPulse ?? true,
      maxWidth: maxWidth,
      padding: padding ?? const EdgeInsets.all(16),
      borderColor: borderColor,
      borderWidth: borderWidth,
      leftBarIndicatorColor: leftBarIndicatorColor,
      boxShadows: boxShadows,
      backgroundGradient: backgroundGradient,
      mainButton: mainButton,
      onTap: onTap,
      onHover: onHover,
      isDismissible: isDismissible ?? true,
      dismissDirection: dismissDirection,
      showProgressIndicator: showProgressIndicator ?? false,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
      progressIndicatorValueColor: progressIndicatorValueColor,
      snackStyle: snackStyle ?? SnackStyle.floating,
      forwardAnimationCurve: forwardAnimationCurve ?? Curves.easeOutCirc,
      reverseAnimationCurve: reverseAnimationCurve ?? Curves.easeOutCirc,
      animationDuration: animationDuration ?? const Duration(seconds: 1),
      overlayBlur: overlayBlur ?? 0.0,
      overlayColor: overlayColor ?? Colors.transparent,
      userInputForm: userInputForm,
    );

    final SnackbarController controller = SnackbarController(getSnackBar);

    if (instantInit) {
      controller.show();
    } else {
      //routing.isSnackbar = true;
      ambiguate(Engine.instance)!.addPostFrameCallback((_) {
        controller.show();
      });
    }
    return controller;
  }

  Future<T> showOverlay<T>({
    required Future<T> Function() asyncFunction,
    Color opacityColor = Colors.black,
    Widget? loadingWidget,
    double opacity = .5,
  }) async {
    final NavigatorState navigatorState = Navigator.of(Get.overlayContext!);
    final OverlayState overlayState = navigatorState.overlay!;

    final OverlayEntry overlayEntryOpacity = OverlayEntry(
      builder: (BuildContext context) => Opacity(
        opacity: opacity,
        child: Container(
          color: opacityColor,
        ),
      ),
    );
    final OverlayEntry overlayEntryLoader = OverlayEntry(
      builder: (BuildContext context) =>
          loadingWidget ??
          const Center(
            child: SizedBox(
              height: 90,
              width: 90,
              child: Text("Loading..."),
            ),
          ),
    );
    overlayState
      ..insert(overlayEntryOpacity)
      ..insert(overlayEntryLoader);

    T data;

    try {
      data = await asyncFunction();
    } on Exception catch (_) {
      overlayEntryLoader.remove();
      overlayEntryOpacity.remove();
      rethrow;
    }

    overlayEntryLoader.remove();
    overlayEntryOpacity.remove();
    return data;
  }
}

/// Extension providing navigation functionalities
extension NavigationExtension<T> on GetInterface {
  /// **Navigation.push()** shortcut.<br><br>
  ///
  /// Pushes a new `page` to the stack
  ///
  /// It has the advantage of not needing context,
  /// so you can call from your business logic
  ///
  /// You can set a custom [transition], and a transition [duration].
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// Just like native routing in Flutter, you can push a route
  /// as a [fullscreenDialog],
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// If you want the same behavior of ios that pops a route when the user drag,
  /// you can set [popGesture] to true
  ///
  /// If you're using the [BindingsInterface] api, you must define it here
  ///
  /// By default, Refreshed will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  Future<T?>? to(
    Widget Function() page, {
    bool? opaque,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    String? id,
    String? routeName,
    bool fullscreenDialog = false,
    T? arguments,
    List<BindingsInterface> bindings = const <BindingsInterface>[],
    bool preventDuplicates = true,
    bool? popGesture,
    bool showCupertinoParallax = true,
    double Function(BuildContext context)? gestureWidth,
    bool rebuildStack = true,
    PreventDuplicateHandlingMode preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.reorderRoutes,
  }) =>
      searchDelegate(id).to(
        page,
        opaque: opaque,
        transition: transition,
        curve: curve,
        duration: duration,
        id: id,
        routeName: routeName,
        fullscreenDialog: fullscreenDialog,
        arguments: arguments,
        bindings: bindings,
        preventDuplicates: preventDuplicates,
        popGesture: popGesture,
        showCupertinoParallax: showCupertinoParallax,
        gestureWidth: gestureWidth,
        rebuildStack: rebuildStack,
        preventDuplicateHandlingMode: preventDuplicateHandlingMode,
      );

  /// **Navigation.pushNamed()** shortcut.<br><br>
  ///
  /// Pushes a new named `page` to the stack.
  ///
  /// It has the advantage of not needing context, so you can call
  /// from your business logic.
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// By default, Refreshed will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  ///
  /// Note: Always put a slash on the route ('/page1'), to avoid unexpected errors
  Future<T?>? toNamed(
    String page, {
    T? arguments,
    String? id,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final Uri uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }

    return searchDelegate(id).toNamed(
      page,
      arguments: arguments,
      id: id,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
    );
  }

  /// **Navigation.pushReplacementNamed()** shortcut.<br><br>
  ///
  /// Pop the current named `page` in the stack and push a new one in its place
  ///
  /// It has the advantage of not needing context, so you can call
  /// from your business logic.
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// By default, Refreshed will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  ///
  /// Note: Always put a slash on the route ('/page1'), to avoid unexpected errors
  Future<T?>? offNamed(
    String page, {
    T? arguments,
    String? id,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final Uri uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    return searchDelegate(id).offNamed(
      page,
      arguments: arguments,
      id: id,
      parameters: parameters,
    );
  }

  /// **Navigation.popUntil()** shortcut.<br><br>
  ///
  /// Calls pop several times in the stack until [predicate] returns true
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// [predicate] can be used like this:
  /// `Get.until((route) => Get.currentRoute == '/home')`so when you get to home page,
  ///
  /// or also like this:
  /// `Get.until((route) => !Get.isDialogOpen())`, to make sure the
  /// dialog is closed
  void until(bool Function(GetPage<dynamic>) predicate, {String? id}) {
    // if (key.currentState.mounted) // add this if appear problems on future with route navigate
    // when widget don't mounted
    return searchDelegate(id).backUntil(predicate);
  }

  /// **Navigation.pushNamedAndRemoveUntil()** shortcut.<br><br>
  ///
  /// Push the given named `page`, and then pop several pages in the stack
  /// until [predicate] returns true
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// [predicate] can be used like this:
  /// `Get.offNamedUntil(page, ModalRoute.withName('/home'))`
  /// to pop routes in stack until home,
  /// or like this:
  /// `Get.offNamedUntil((route) => !Get.isDialogOpen())`,
  /// to make sure the dialog is closed
  ///
  /// Note: Always put a slash on the route name ('/page1'), to avoid unexpected errors
  Future<T?>? offNamedUntil(
    String page,
    bool Function(GetPage<dynamic>)? predicate, {
    String? id,
    T? arguments,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final Uri uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }

    return searchDelegate(id).offNamedUntil(
      page,
      predicate: predicate,
      id: id,
      arguments: arguments,
      parameters: parameters,
    );
  }

  /// **Navigation.popAndPushNamed()** shortcut.<br><br>
  ///
  /// Pop the current named page and pushes a new `page` to the stack
  /// in its place
  ///
  /// You can send any type of value to the other route in the [arguments].
  /// It is very similar to `offNamed()` but use a different approach
  ///
  /// The `offNamed()` pop a page, and goes to the next. The
  /// `offAndToNamed()` goes to the next page, and removes the previous one.
  /// The route transition animation is different.
  Future<T?>? offAndToNamed(
    String page, {
    T? arguments,
    String? id,
    T? result,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final Uri uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    return searchDelegate(id).backAndtoNamed(
      page,
      arguments: arguments,
      result: result,
    );
  }

  /// **Navigation.removeRoute()** shortcut.<br><br>
  ///
  /// Remove a specific [route] from the stack
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  void removeRoute(String name, {String? id}) =>
      searchDelegate(id).removeRoute(name);

  /// **Navigation.pushNamedAndRemoveUntil()** shortcut.<br><br>
  ///
  /// Push a named `page` and pop several pages in the stack
  /// until [predicate] returns true. [predicate] is optional
  ///
  /// It has the advantage of not needing context, so you can
  /// call from your business logic.
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [predicate] can be used like this:
  /// `Get.until((route) => Get.currentRoute == '/home')`so when you get to home page,
  /// or also like
  /// `Get.until((route) => !Get.isDialogOpen())`, to make sure the dialog
  /// is closed
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// Note: Always put a slash on the route ('/page1'), to avoid unexpected errors
  Future<T?>? offAllNamed(
    String newRouteName, {
    T? arguments,
    String? id,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final Uri uri = Uri(path: newRouteName, queryParameters: parameters);
      newRouteName = uri.toString();
    }

    return searchDelegate(id).offAllNamed(
      newRouteName,
      arguments: arguments,
      id: id,
      parameters: parameters,
    );
  }

  /// Returns true if a Snackbar, Dialog or BottomSheet is currently OPEN
  bool get isOverlaysOpen =>
      isSnackbarOpen || isDialogOpen! || isBottomSheetOpen!;

  /// Returns true if there is no Snackbar, Dialog or BottomSheet open
  bool get isOverlaysClosed =>
      !isSnackbarOpen && !isDialogOpen! && !isBottomSheetOpen!;

  /// **Navigation.popUntil()** shortcut.<br><br>
  ///
  /// Pop the current page in the stack
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// It has the advantage of not needing context, so you can call
  /// from your business logic.
  void back({
    T? result,
    bool canPop = true,
    int times = 1,
    String? id,
  }) {
    if (times < 1) {
      times = 1;
    }

    if (times > 1) {
      int count = 0;
      return searchDelegate(id).backUntil((GetPage route) => count++ == times);
    } else {
      if (canPop) {
        if (searchDelegate(id).canBack) {
          return searchDelegate(id).back(result);
        }
      } else {
        return searchDelegate(id).back(result);
      }
    }
  }

  /// Pop the current page, snackbar, dialog or bottomsheet in the stack
  ///
  /// if your set [closeOverlays] to true, Get.back() will close the
  /// currently open snackbar/dialog/bottomsheet AND the current page
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// It has the advantage of not needing context, so you can call
  /// from your business logic.
  Future<void> backLegacy({
    T? result,
    bool closeOverlays = false,
    bool canPop = true,
    int times = 1,
    String? id,
  }) async {
    if (closeOverlays) {
      await closeAllOverlays();
    }

    if (times < 1) {
      times = 1;
    }

    if (times > 1) {
      int count = 0;
      return searchDelegate(id)
          .navigatorKey
          .currentState
          ?.popUntil((Route route) => count++ == times);
    } else {
      if (canPop) {
        if (searchDelegate(id).navigatorKey.currentState?.canPop() == true) {
          return searchDelegate(id).navigatorKey.currentState?.pop<T>(result);
        }
      } else {
        return searchDelegate(id).navigatorKey.currentState?.pop<T>(result);
      }
    }
  }

  /// Closes all open dialogs and bottom sheets.
  ///
  /// Parameters:
  /// - [id]: The key associated with the delegate to use for closing overlays. If null, the root delegate will be used.
  void closeAllDialogsAndBottomSheets(String? id) {
    // It can not be divided, because dialogs and bottomsheets can not be consecutive
    while (isDialogOpen! && isBottomSheetOpen!) {
      closeOverlay(id: id);
    }
  }

  /// Closes all open dialogs.
  ///
  /// Parameters:
  /// - [id]: The key associated with the delegate to use for closing dialogs. If null, the root delegate will be used.
  void closeAllDialogs({
    String? id,
  }) {
    while (isDialogOpen!) {
      closeOverlay(id: id);
    }
  }

  /// Closes the topmost overlay (dialog or bottom sheet) using the given delegate key.
  ///
  /// Parameters:
  /// - [id]: The key associated with the delegate to use for closing the overlay. If null, the root delegate will be used.
  void closeOverlay({String? id}) {
    searchDelegate(id).navigatorKey.currentState?.pop();
  }

  /// Closes all open bottom sheets.
  ///
  /// Parameters:
  /// - [id]: The key associated with the delegate to use for closing bottom sheets. If null, the root delegate will be used.
  void closeAllBottomSheets({String? id}) {
    while (isBottomSheetOpen!) {
      searchDelegate(id).navigatorKey.currentState?.pop();
    }
  }

  /// Closes all open overlays (dialogs, bottom sheets, and snackbars).
  Future<void> closeAllOverlays() async {
    closeAllDialogsAndBottomSheets(null);
    await closeAllSnackbars();
  }

  /// **Navigation.popUntil()** (with predicate) shortcut .<br><br>
  ///
  /// Close as many routes as defined by [times]
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  void close({
    bool closeAll = true,
    bool closeSnackbar = true,
    bool closeDialog = true,
    bool closeBottomSheet = true,
    String? id,
    T? result,
  }) {
    void handleClose(
      bool closeCondition,
      Function closeAllFunction,
      Function closeSingleFunction, [
      bool? isOpenCondition,
    ]) {
      if (closeCondition) {
        if (closeAll) {
          closeAllFunction();
        } else if (isOpenCondition == true) {
          closeSingleFunction();
        }
      }
    }

    handleClose(closeSnackbar, closeAllSnackbars, closeCurrentSnackbar);
    handleClose(closeDialog, closeAllDialogs, closeOverlay, isDialogOpen);
    handleClose(
      closeBottomSheet,
      closeAllBottomSheets,
      closeOverlay,
      isBottomSheetOpen,
    );
  }

  /// **Navigation.pushReplacement()** shortcut .<br><br>
  ///
  /// Pop the current page and pushes a new `page` to the stack
  ///
  /// It has the advantage of not needing context,
  /// so you can call from your business logic
  ///
  /// You can set a custom [transition], define a Tween [curve],
  /// and a transition [duration].
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// Just like native routing in Flutter, you can push a route
  /// as a [fullscreenDialog],
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// If you want the same behavior of ios that pops a route when the user drag,
  /// you can set [popGesture] to true
  ///
  /// If you're using the [BindingsInterface] api, you must define it here
  ///
  /// By default, Refreshed will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  Future<T?>? off(
    Widget Function() page, {
    bool? opaque,
    Transition? transition,
    Curve? curve,
    bool? popGesture,
    String? id,
    String? routeName,
    T? arguments,
    List<BindingsInterface> bindings = const <BindingsInterface>[],
    bool fullscreenDialog = false,
    bool preventDuplicates = true,
    Duration? duration,
    double Function(BuildContext context)? gestureWidth,
  }) {
    routeName ??= "/${page.runtimeType}";
    routeName = cleanRouteName(routeName);
    if (preventDuplicates && routeName == currentRoute) {
      return null;
    }
    return searchDelegate(id).off(
      page,
      opaque: opaque ?? true,
      transition: transition,
      curve: curve,
      popGesture: popGesture,
      id: id,
      routeName: routeName,
      arguments: arguments,
      bindings: bindings,
      fullscreenDialog: fullscreenDialog,
      preventDuplicates: preventDuplicates,
      duration: duration,
      gestureWidth: gestureWidth,
    );
  }

  /// Navigates off until a page that satisfies the given predicate is found.
  ///
  /// This method searches for a page in the navigation stack starting from the current one
  /// and navigates backward until it finds a page that satisfies the given predicate.
  /// Once the predicate condition is met, it stops navigation and returns the result.
  Future<T?> offUntil(
    Widget Function() page,
    bool Function(GetPage) predicate, [
    Object? arguments,
    String? id,
  ])
      // Delegate the navigation operation to the appropriate delegate based on the provided ID
      =>
      searchDelegate(id).offUntil(
        page,
        predicate,
        arguments,
      );

  ///
  /// Push a `page` and pop several pages in the stack
  /// until [predicate] returns true. [predicate] is optional
  ///
  /// It has the advantage of not needing context,
  /// so you can call from your business logic
  ///
  /// You can set a custom [transition], a [curve] and a transition [duration].
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// Just like native routing in Flutter, you can push a route
  /// as a [fullscreenDialog],
  ///
  /// [predicate] can be used like this:
  /// `Get.until((route) => Get.currentRoute == '/home')`so when you get to home page,
  /// or also like
  /// `Get.until((route) => !Get.isDialogOpen())`, to make sure the dialog
  /// is closed
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// If you want the same behavior of ios that pops a route when the user drag,
  /// you can set [popGesture] to true
  ///
  /// If you're using the [BindingsInterface] api, you must define it here
  ///
  /// By default, Refreshed will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  Future<T?>? offAll(
    Widget Function() page, {
    bool Function(GetPage<dynamic>)? predicate,
    bool? opaque,
    bool? popGesture,
    String? id,
    String? routeName,
    T? arguments,
    List<BindingsInterface> bindings = const <BindingsInterface>[],
    bool fullscreenDialog = false,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    double Function(BuildContext context)? gestureWidth,
  }) {
    routeName ??= "/${page.runtimeType}";
    routeName = cleanRouteName(routeName);
    return searchDelegate(id).offAll(
      page,
      predicate: predicate,
      opaque: opaque ?? true,
      popGesture: popGesture,
      id: id,
      //  routeName routeName,
      arguments: arguments,
      bindings: bindings,
      fullscreenDialog: fullscreenDialog,
      transition: transition,
      curve: curve,
      duration: duration,
      gestureWidth: gestureWidth,
    );
  }

  /// Asynchronously updates the application locale and forces an update.
  Future<void> updateLocale(Locale l) async {
    // Set the new locale for the application
    Get.locale = l;
    // Force an update to ensure that the locale change takes effect immediately
    await forceAppUpdate();
  }

  /// As a rule, Flutter knows which widget to update,
  /// so this command is rarely needed. We can mention situations
  /// where you use const so that widgets are not updated with setState,
  /// but you want it to be forcefully updated when an event like
  /// language change happens. using context to make the widget dirty
  /// for performRebuild() is a viable solution.
  /// However, in situations where this is not possible, or at least,
  /// is not desired by the developer, the only solution for updating
  /// widgets that Flutter does not want to update is to use reassemble
  /// to forcibly rebuild all widgets. Attention: calling this function will
  /// reconstruct the application from the sketch, use this with caution.
  /// Your entire application will be rebuilt, and touch events will not
  /// work until the end of rendering.
  Future<void> forceAppUpdate() async {
    await engine.performReassemble();
  }

  /// Function to trigger an application update.
  void appUpdate() => rootController.update();

  /// Function to change the theme of the application.
  ///
  /// Parameters:
  /// - [theme]: The new theme to apply.
  void changeTheme(ThemeData theme) {
    rootController.setTheme(theme);
  }

  /// Function to change the theme mode of the application.
  ///
  /// Parameters:
  /// - [themeMode]: The new theme mode to apply.
  void changeThemeMode(ThemeMode themeMode) {
    rootController.setThemeMode(themeMode);
  }

  /// Function to add a new navigator key to the application.
  ///
  /// Parameters:
  /// - [newKey]: The new navigator key to add.
  ///
  /// Returns:
  /// The added navigator key.
  GlobalKey<NavigatorState>? addKey(GlobalKey<NavigatorState> newKey) =>
      rootController.addKey(newKey);

  /// Function to retrieve a nested delegate by its key.
  ///
  /// Parameters:
  /// - [key]: The key of the nested delegate to retrieve.
  ///
  /// Returns:
  /// The nested delegate associated with the given key, if found.
  /// If no key is provided, returns the root delegate.
  GetDelegate<T>? nestedKey(String? key) => rootController.nestedKey(key);

  /// Function to search for a delegate by its route id.
  ///
  /// Parameters:
  /// - [k]: The route id to search for.
  ///
  /// Returns:
  /// The delegate associated with the given route id.
  ///
  /// Throws:
  /// - If the provided route id is not found in the keys map.
  GetDelegate<T> searchDelegate(String? k) {
    GetDelegate<T> key;
    if (k == null) {
      key = Get.rootController.rootDelegate as GetDelegate<T>;
    } else {
      if (!keys.containsKey(k)) {
        throw Exception("Route id ($k) not found");
      }
      key = keys[k]! as GetDelegate<T>;
    }

    // Missing return statement for 'key' here in the original code
    return key;
  }

  /// give current arguments
  //dynamic get arguments => routing.args;
  dynamic get arguments => rootController.rootDelegate.arguments();

  /// give name from current route
  String get currentRoute => routing.current;

  /// give name from previous route
  String get previousRoute => routing.previous;

  /// check if snackbar is open
  bool get isSnackbarOpen =>
      SnackbarController.isSnackbarBeingShown; //routing.isSnackbar;

  /// A function to close all active snackbars.
  Future<void> closeAllSnackbars() async {
    await SnackbarController.cancelAllSnackbars();
  }

  /// A function to close the currently displayed snackbar, if any.
  ///
  /// Waits for the snackbar to close before returning.
  Future<void> closeCurrentSnackbar() async {
    await SnackbarController.closeCurrentSnackbar();
  }

  /// check if dialog is open
  bool? get isDialogOpen => routing.isDialog;

  /// check if bottomsheet is open
  bool? get isBottomSheetOpen => routing.isBottomSheet;

  /// check a raw current route
  Route<dynamic>? get rawRoute => routing.route;

  /// check if popGesture is enable
  bool get isPopGestureEnable => defaultPopGesture;

  /// check if default opaque route is enable
  bool get isOpaqueRouteDefault => defaultOpaqueRoute;

  /// give access to currentContext
  BuildContext? get context => key.currentContext;

  /// give access to current Overlay Context
  BuildContext? get overlayContext {
    BuildContext? overlay;
    key.currentState?.overlay?.context.visitChildElements((Element element) {
      overlay = element;
    });
    return overlay;
  }

  /// give access to Theme.of(context)
  ThemeData get theme {
    ThemeData theme = ThemeData.fallback();
    if (context != null) {
      theme = Theme.of(context!);
    }
    return theme;
  }

  /// The current null safe [WidgetsBinding]
  WidgetsBinding get engine => WidgetsFlutterBinding.ensureInitialized();

  /// The window to which this binding is bound.
  ui.PlatformDispatcher get window => engine.platformDispatcher;

  /// Retrieves the locale of the device.
  Locale? get deviceLocale => window.locale;

  ///The number of device pixels for each logical pixel.
  double get pixelRatio => window.implicitView!.devicePixelRatio;

  /// Retrieves the size of the application window.
  ///
  /// Returns the size of the application window adjusted by the pixel ratio.
  Size get size => window.implicitView!.physicalSize / pixelRatio;

  ///The horizontal extent of this size.
  double get width => size.width;

  ///The vertical extent of this size
  double get height => size.height;

  ///The distance from the top edge to the first unpadded pixel,
  ///in physical pixels.
  double get statusBarHeight => window.implicitView!.padding.top;

  ///The distance from the bottom edge to the first unpadded pixel,
  ///in physical pixels.
  double get bottomBarHeight => window.implicitView!.padding.bottom;

  ///The system-reported text scale.
  double get textScaleFactor => window.textScaleFactor;

  /// give access to TextTheme.of(context)
  TextTheme get textTheme => theme.textTheme;

  /// give access to Mediaquery.of(context)
  MediaQueryData get mediaQuery => MediaQuery.of(context!);

  /// Check if dark mode theme is enable
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Check if dark mode theme is enable on platform on android Q+
  bool get isPlatformDarkMode =>
      ui.PlatformDispatcher.instance.platformBrightness == Brightness.dark;

  /// give access to Theme.of(context).iconTheme.color
  Color? get iconColor => theme.iconTheme.color;

  /// give access to FocusScope.of(context)
  FocusNode? get focusScope => FocusManager.instance.primaryFocus;

  /// Retrieves the global key for accessing the navigator state.
  GlobalKey<NavigatorState> get key => rootController.key;

  /// Retrieves a map of keys associated with Refreshed delegates.
  Map<String, GetDelegate> get keys => rootController.keys;

  /// Retrieves the root controller state.
  GetRootState<T> get rootController =>
      GetRootState.controller as GetRootState<T>;

  ConfigData<T> get _getxController =>
      GetRootState.controller.config as ConfigData<T>;

  /// Retrieves the default setting for enabling the back gesture.
  bool get defaultPopGesture => _getxController.defaultPopGesture;

  /// Retrieves the default setting for using opaque routes.
  bool get defaultOpaqueRoute => _getxController.defaultOpaqueRoute;

  /// Retrieves the default transition setting.
  Transition? get defaultTransition => _getxController.defaultTransition;

  /// Retrieves the default duration for transitions.
  Duration get defaultTransitionDuration =>
      _getxController.defaultTransitionDuration;

  /// Retrieves the default curve for transitions.
  Curve get defaultTransitionCurve => _getxController.defaultTransitionCurve;

  /// Retrieves the default curve for dialog transitions.
  Curve get defaultDialogTransitionCurve =>
      _getxController.defaultDialogTransitionCurve;

  /// Retrieves the default duration for dialog transitions.
  Duration get defaultDialogTransitionDuration =>
      _getxController.defaultDialogTransitionDuration;

  /// Retrieves the current routing configuration.
  Routing get routing => _getxController.routing;

  /// Sets the parameters for navigation.
  set parameters(Map<String, String?> newParameters) =>
      rootController.parameters = newParameters;

  /// Sets the test mode for the application.
  set testMode(bool isTest) => rootController.testMode = isTest;

  /// Retrieves the current test mode status.
  bool get testMode => _getxController.testMode;

  /// Retrieves the parameters associated with the current route.
  Map<String, String?> get parameters => rootController.rootDelegate.parameters;

  /// Casts the stored router delegate to a desired type
  TDelegate? delegate<TDelegate extends RouterDelegate<TPage>, TPage>() =>
      _getxController.routerDelegate as TDelegate?;
}
