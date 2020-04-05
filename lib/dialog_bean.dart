import 'package:flutter/material.dart';

typedef CreateDialogWidget = Widget Function();

/// @desc 弹窗数据类
/// @time 2019-11-06 09:42
/// @author Cheney
class DialogBean {
  ///dialog唯一标识，通过 DialogBean 数据内容生成 Md5生成
  String dialogId;

  ///当前 dialog，显示的视图。如果为空，则在顶层页面
  String pageRouter;

  ///当前 pageRouter 对应的子页面
  List<String> innerPageRouters;

  ///优先级、用于显示弹窗前排序，
  ///但对于加入的弹窗，已经显示的情况
  ///[highClear] 清除已显示的弹窗，直接显示当前弹窗，该属性慎用
  ///[high] 回收当前已显示的弹窗，再显示高优先级弹窗，该属性慎用
  DialogPriority dialogPriority;

  ///用于排序
  int priority;

  ///弹窗内部业务 widget,每次show 时动态创建。不能直接传创建好的 widget，因为在 high回收时，调用 pop 再 show 会出现 The following NoSuchMethodError was thrown building Builder(dirty):
  CreateDialogWidget createDialogWidget;

  ///弹窗类型
  DialogType dialogType;

  DialogBean({
    this.pageRouter,
    this.innerPageRouters,
    this.dialogPriority = DialogPriority.normal,
    this.dialogType = DialogType.dialog,
    @required this.createDialogWidget,
  }) : super() {
    assert(createDialogWidget().key != null);
    dialogId = (createDialogWidget().key as ValueKey).value;
    switch (dialogPriority) {
      case DialogPriority.highClearAll:
        priority = 30;
        pageRouter = null;
        break;
      case DialogPriority.highClear:
        priority = 20;
        pageRouter = null;
        break;
      case DialogPriority.high:
        priority = 10;
        break;
      case DialogPriority.normal:
        priority = 1;
        break;
    }
    //如果内页不空，则 pageRouter不能为空
    if (innerPageRouters != null) {
      assert(pageRouter != null);
    }
  }

  ///是否为高优先级，带清除功能的
  bool isHighClear() {
    return dialogPriority == DialogPriority.highClear ||
        dialogPriority == DialogPriority.highClearAll;
  }

  @override
  String toString() {
    return 'DialogBean{dialogId: $dialogId, pageRouter: $pageRouter, innerPageRouters: $innerPageRouters, priority: $priority, dialogType: $dialogType}';
  }
}

enum DialogType {
  ///弹窗
  dialog,

  ///底部弹窗
  bottomSheet,
}

enum DialogPriority {
  ///最高优先级，清除其它所有弹窗（例如强制升级弹窗）
  highClearAll,

  ///高优先级弹窗，清除其它弹窗不包括highClearAll（登录超时、多终端登录）
  highClear,

  ///高优先级弹窗，回收normal弹窗，优先显示（指纹引导弹窗、提交请求弹窗）
  high,

  ///默认弹窗，按顺序弹出
  normal,
}
