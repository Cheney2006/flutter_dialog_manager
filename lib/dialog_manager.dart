import 'package:flutter/material.dart';
import 'package:flutter_common_utils/log_util.dart';

import 'dialog_bean.dart';
import 'navigator_manager.dart';

/// @desc 统一弹窗（包含 showDialog、showModalBottomSheet）
/// @time 2019-11-06 09:16
/// @author Cheney
class DialogManager {
  // 工厂模式 : 单例公开访问点
  factory DialogManager() => _getInstance();

//  static DialogManager get instance => _getInstance();

  // 静态私有成员，没有初始化
  static DialogManager _instance;

  ///弹窗数据（待显示）
  List<DialogBean> _dialogList;

//  ///当前正在显示的弹窗
//  DialogBean showDialogBean;

  ///已显示过或正在显示的弹窗数据，还未被回调清除
  ///已经显示过的弹窗，不能用一个DialogBean
  ///(因为showDialogBean在对话 pop 是会赋为空，一个正要显示，一个取消的回调过来又重新给设为空了。)
  List<DialogBean> _hasShowDialogList;

  ///是否有系统弹窗正在显示,例如系统权限申请弹窗
  bool isSystemDialogShowing;

  // 私有构造函数
  DialogManager._internal() {
    // 初始化
    _dialogList = List<DialogBean>();
    _hasShowDialogList = List<DialogBean>();
    isSystemDialogShowing = false;
  }

  // 静态、同步、私有访问点
  static DialogManager _getInstance() {
    if (_instance == null) {
      _instance = DialogManager._internal();
    }
    return _instance;
  }

  ///高优先级，回收取消正在显示的弹窗
  static const String popRecycle = "popRecycle";

  ///其它地方触发取消正在显示的调窗,且不自动显示下一个
  static const String popRecycleAndNotNext = "popRecycleAndNotNext";

  ///取消弹窗，但不自动显示下一个
  static const String popNotNext = "popNotNext";

  ///增加弹窗
  void add(DialogBean bean) {
    LogUtil.v("dialog add ${bean.dialogId}");
    //对于 highClear 和 highClearAll则加入时要清掉其它低优先级弹窗,必须放在 show 前。假如在 add中，可能低优先级的在后台添加的
    switch (bean.dialogPriority) {
      case DialogPriority.highClear:
      case DialogPriority.highClearAll:
        //移除其它低优先级弹窗数据,(不清除正显示的。在 show 里面再清除&& !hasShow(item.dialogId),也可以在后台处理)
        _dialogList.removeWhere((item) => item.priority < bean.priority);
        break;
      default:
        break;
    }
    //去掉重复弹窗（待显示的与顶层正在显示的弹窗）

    bool hasDialog = _getAllDialogBean()
        .any((dialogBean) => bean.dialogId == dialogBean.dialogId);

    //没有重复的，且栈中没有 highClear 等优先级的弹窗,或者 clearBean小于等于bean.priority
    if (!hasDialog) {
      DialogBean clearBean = _getHighClearDialogBean();
      if (clearBean == null || bean.priority >= clearBean.priority) {
        _dialogList.add(bean);
      }
    }
    //根据优先级进行排序:降序
    _dialogList.sort((a, b) => b.priority.compareTo(a.priority));
  }

  ///显示弹窗,不能返回 Future，不然在同时 show两次时重叠 DialogManager()..add()..show;DialogManager()..add()..show;
  void show(BuildContext context) {
    LogUtil.v("dialog show $_dialogList");
    //如果有系统弹窗正在显示，则不显示
    if (isSystemDialogShowing) {
      return;
    }

    //如果待显示数组为空
    if (_dialogList.isEmpty) {
      return;
    }

    //对于 highClean 和 highCleanAll则加入时要清掉其它低优先级弹窗,必须放在 show 前。假如在 add中，可能低优先级的在后台添加的
//    if (bean != null) {
//      //移除其它低优先级弹窗数据
//      _dialogList.removeWhere((item) => item.priority < bean.priority);
//    }

    //已经有正在显示的弹窗且是在栈顶层显示(showDialogBean != null && 不能加入此判断，在显示强升时碰到的，因为showDialogBean在对话 pop 是会赋为空。所以导致这里不准，一个正在显示，一个取消的回调过来又重新给设为空了。)
    if (NavigatorManager().isTopDialog() && _hasShowDialogList.isNotEmpty) {
      DialogBean hasShowDialogBean = getShowingDialog();
      LogUtil.v("当前有正在显示的弹窗$hasShowDialogBean");
      DialogBean bean;
      //已有显示的弹窗，且high 弹窗在当前页显示，且已显示的弹窗优先级低于high级弹窗
      //highClear 和 highClearAll 不用管显示页面 所以不要这个判断,这里_getHighClearDialogBean取所有的（包括正在显示的）
      if ((bean = _getHighClearDialogBean(beans: _dialogList)) != null &&
          _canShow(bean) &&
          hasShowDialogBean.priority < bean.priority) {
        //如果当前加入的弹窗是 highClear,则清掉所有弹窗(包括当前正在显示的，以及未显示的)
        LogUtil.v("清除正在显示的弹窗${bean.dialogPriority}");
        Navigator.pop(context);
      } else if ((bean = _getDialogBeanByPriority(DialogPriority.high,
                  beans: _dialogList)) !=
              null && //已有显示的弹窗，且high 弹窗在当前页显示，且已显示的弹窗优先级低于high级弹窗
          _canShow(bean) &&
          hasShowDialogBean.priority < bean.priority) {
        //如果当前加入的弹窗是 high,则回收当前正在显示的弹窗。
        LogUtil.v("回收正在显示的弹窗${bean.dialogPriority}");
        Navigator.pop(context, popRecycle);
        //不能在这里把弹窗直接回收，因为在使用 pop 会调用whenComplete会清掉当前显示的弹窗。所以要到whenComplete 中去处理
      }
      return;
    }
    //查找当前页面可显示的弹窗数据
    DialogBean showDialogBean =
        _dialogList.firstWhere((bean) => _canShow(bean), orElse: () => null);
    //没有找到可显示的弹窗
    if (showDialogBean == null) {
      return;
    }
    _hasShowDialogList.add(showDialogBean);
    //新从数组中移动，因为回调中再移动可能会出现提交成功后显示一个提示框，导致一直显示提交框，不会消失
    _dialogList.remove(showDialogBean);
    LogUtil.v("显示的dialog =$showDialogBean");
    switch (showDialogBean.dialogType) {
      case DialogType.dialog:
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return showDialogBean.createDialogWidget();
          },
        ).then((obj) {
          _handlePopResult(context, obj);
        });
        break;
      case DialogType.bottomSheet:
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return showDialogBean.createDialogWidget();
          },
        ).then((obj) {
          _handlePopResult(context, obj);
        });
        break;
    }
  }

  void _handlePopResult(BuildContext context, dynamic obj) {
    //取消第一个
    DialogBean dismissBean = _hasShowDialogList[0];
    LogUtil.v("消失的dialog =$dismissBean,接收回调结果:$obj");
    //取消第一个
    _hasShowDialogList.remove(dismissBean);
    //如果是从 high 弹窗回收或外部手动 pop的话，则重新添加回数组
    if (obj == popRecycle || obj == popRecycleAndNotNext) {
      _dialogList.add(dismissBean);
    }
    // widget 中可能会先 pop ，再 push,这里显示下一个时，通过顶层路由来判断,不能通过当前显示的页面来判断。
    if (obj != popRecycleAndNotNext && obj != popNotNext) {
      show(context);
    }
  }

  ///弹窗是否正在显示
  bool isShowing(String dialogId) {
    DialogBean dialogBean = getShowingDialog();
    if (dialogBean != null && dialogId == dialogBean.dialogId) {
      return true;
    }
    return false;
  }

  ///取得在正显示的弹窗
  DialogBean getShowingDialog() {
    if (_hasShowDialogList.isNotEmpty && NavigatorManager().isTopDialog()) {
      return _hasShowDialogList[_hasShowDialogList.length - 1];
    }
    return null;
  }

  ///显示系统弹窗，必须与  dismiss 成对使用
  void showSystemDialog(BuildContext context) {
    //回收正在显示的弹窗
    pop(context, result: popRecycleAndNotNext);
    //正在显示系统弹窗
    isSystemDialogShowing = true;
  }

  ///隐藏系统弹窗，必须与 show 成对使用
  void dismissSystemDialog(BuildContext context) {
    //正在显示系统弹窗
    isSystemDialogShowing = false;
    //系统弹窗消失，续续显示其它弹窗
    show(context);
  }

  ///弹窗栈中是否此弹窗
  bool hasShow(String dialogId) {
    return _dialogList.any((bean) => dialogId == bean.dialogId);
  }

  ///清除已经显示的弹窗，系统权限弹窗时回收到其它弹窗
  ///[result] 默认回收弹窗，不显示下一个
  void pop(BuildContext context, {String result}) {
    if (_hasShowDialogList.isNotEmpty && NavigatorManager().isTopDialog()) {
      Navigator.pop(context, result);
    }
  }

  ///清除已经显示的弹窗，系统权限弹窗时回收到其它弹窗
  ///[result] 默认回收弹窗，不显示下一个
  void popByDialogId(BuildContext context, String dialogId, {String result}) {
    if (isShowing(dialogId)) {
      Navigator.pop(context, result);
    }
  }

  ///清除已经显示的弹窗或待显示的弹窗，例如登录超时打开登录时、或者退出登录
  void popAndClear(BuildContext context) {
    //如果没有 highClear或 highClearAll.
    DialogBean dialogBean = _getHighClearDialogBean();
    if (dialogBean == null) {
      _dialogList.clear();
      pop(context, result: popNotNext);
    }
  }

  ///是否可显示，未指定页面，或者指定的页面在顶层
  bool _canShow(DialogBean dialogBean) {
    if (dialogBean == null) {
      return false;
    }
    String pageRouter = dialogBean.pageRouter;
    //指定的页面在顶层
    return isEmpty(pageRouter) || NavigatorManager().isTopRouter(pageRouter);
  }

  ///按取得 clear 其它弹窗优先级的弹窗 bean
  DialogBean _getHighClearDialogBean({List<DialogBean> beans}) {
    DialogBean bean =
        _getDialogBeanByPriority(DialogPriority.highClearAll, beans: beans);
    if (bean != null) {
      return bean;
    }
    bean = _getDialogBeanByPriority(DialogPriority.highClear, beans: beans);
    if (bean != null) {
      return bean;
    }
    return null;
  }

  ///按弹窗优先级获取弹窗(默认包括待显示的及正在显示的)
  DialogBean _getDialogBeanByPriority(DialogPriority priority,
      {List<DialogBean> beans}) {
    return (beans ?? _getAllDialogBean()).firstWhere(
      (bean) => priority == bean.dialogPriority,
      orElse: () => null,
    );
  }

  ///取得所有弹窗，包括待显示及正在显示的弹窗
  List<DialogBean> _getAllDialogBean() {
    List<DialogBean> all = List<DialogBean>();
    DialogBean showingDialogBean = getShowingDialog();
    if (getShowingDialog() != null) {
      all.add(showingDialogBean);
    }
    all.addAll(_dialogList);
    return all;
  }

  bool isEmpty(String s) {
    return s == null || s.isEmpty;
  }
}
