import 'package:flutter/material.dart';

typedef OnInterceptor = Function(bool isInterceptor);

/// @desc 导航管理
/// @time 2019-05-29 09:51
/// @author Cheney
class NavigatorManager {
  ///所有路由栈，包括弹窗与页面
  List<Route> _history;

  static final NavigatorManager _instance = NavigatorManager._internal();

  factory NavigatorManager() => _instance;

  NavigatorManager _bus;

  NavigatorManager._internal() {
    if (_bus == null) {
      _history = List<Route>();
    }
  }

  ///通过拦截器增加 push router
  void addRouter(Route route) {
    _history.add(route);
  }

  ///通过拦截器移动 push router
  void removeRouter(Route route) {
    _history.remove(route);
  }

  ///通过拦截器移动 push router
  void replaceRouter(Route newRoute, Route oldRoute) {
    _history.remove(oldRoute);
    _history.add(newRoute);
  }

  List<Route> get history => _history;

  ///是否顶层路由为页面，或者还未显示，正在压入栈
  bool isTopRouter(String routerName) {
    if (_history.isEmpty) {
      return false;
    }
    int i = _history.length - 1;
    Route route = _history[i];
    while (route.settings == null && i >= 0) {
      i--;
      route = _history[i];
    }
    return route.settings.name != null && route.settings.name == routerName;
  }

  ///是否顶层路由为弹窗(包括showBottomSheet)，或者还未显示，正在压入栈
  bool isTopDialog() {
    if (_history.isEmpty) {
      return false;
    }
    return _history[_history.length - 1].settings.name == null;
  }
}
