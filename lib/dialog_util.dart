import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import 'tips_confirm_dialog.dart';

/// @desc 弹窗 widget 统一创建类
/// @time 2019-11-06 09:42
/// @author Cheney
class DialogUtil {
  ///对话框提示显示
  ///[id] 同一对话框唯一标识
  static Widget createTipWidget(
    BuildContext context,
    String message, {
    String id,
    bool hasTips = true,
    bool canceled = true,
    String cancelText,
    String confirmText,
    OnCancelListener onCancelListener,
    OnConfirmListener onConfirmListener,
  }) {
    return WillPopScope(
        key: ValueKey(id ?? generateId("createTipWidget$message")),
        child: TipsConfirmDialog(
          message: message,
          hasTips: hasTips,
          cancelText: cancelText,
          confirmText: confirmText,
          hasCancelButton: canceled,
          onCancelListener: () {
            if (onCancelListener != null) {
              onCancelListener();
            } else {
              Navigator.pop(context);
            }
          },
          onConfirmListener: () {
            if (onConfirmListener != null) {
              onConfirmListener();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        onWillPop: () async => canceled);
  }

  ///生成对话框 id
  static String generateId(String txt) {
    assert(txt != null);
    return generateMd5(txt);
  }

  /// md5 加密
  static String generateMd5(String data) {
    var content = Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    // 这里其实就是 digest.toString()
    return hex.encode(digest.bytes);
  }
}
