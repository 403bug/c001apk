import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

import '../../logic/network/captcha_challenge.dart';
import '../../utils/storage_util.dart';

Future<String?> verifyCaptcha(CaptchaChallenge challenge) async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    SmartDialog.showToast('当前平台暂不支持应用内人机验证，请在手机端完成');
    return null;
  }
  if (Get.context == null) return null;
  // Verification must remain visible while a publish/loading overlay is active.
  await SmartDialog.dismiss(status: SmartStatus.loading);
  return Get.to<String>(() => CaptchaPage(challenge: challenge));
}

class CaptchaPage extends StatefulWidget {
  const CaptchaPage({super.key, required this.challenge});
  final CaptchaChallenge challenge;

  @override
  State<CaptchaPage> createState() => _CaptchaPageState();
}

class _CaptchaPageState extends State<CaptchaPage> {
  InAppWebViewController? _controller;
  bool _finished = false;

  // SDK callbacks yield the validate proof to Dart; the proof never enters
  // storage, logs, navigation parameters or an external browser URL.
  String get _html => '''<!doctype html><html lang="zh-CN"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<style>body{font:16px sans-serif;margin:24px;color:#263238}#captcha{margin-top:24px}p{line-height:1.6}</style>
</head><body><p id="status">正在加载验证组件…</p><div id="captcha"></div>
<script>
function statusText(text){document.getElementById('status').textContent=text;}
function startCaptcha(){
  var timeout=setTimeout(function(){statusText('验证组件加载超时，请点击右上角重新加载');},15000);
  var script=document.createElement('script');
  script.src='https://cstaticdun.126.net/load.min.js';
  script.onerror=function(){clearTimeout(timeout);statusText('验证组件加载失败，请检查网络后重新加载');};
  script.onload=function(){
    if(typeof initNECaptcha!=='function'){clearTimeout(timeout);statusText('验证组件不可用，请重新加载');return;}
    initNECaptcha({captchaId:'${widget.challenge.captchaId}',element:'#captcha',
      mode:'embed',apiVersion:2,width:Math.min(320,window.innerWidth-48)+'px',lang:'zh-CN',
      onVerify:function(err,data){
        if(!err && data && data.validate){window.flutter_inappwebview.callHandler('captchaVerified',data.validate);}
        else{statusText('验证未通过，请按提示重试');}
      }
    },function(){clearTimeout(timeout);statusText('请按下方提示完成人机验证');},
      function(){clearTimeout(timeout);statusText('无法初始化验证，请检查网络后重新加载');});
  };
  document.head.appendChild(script);
}
window.addEventListener('flutterInAppWebViewPlatformReady',startCaptcha);
</script></body></html>''';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('人机验证'), actions: [
          IconButton(
              tooltip: '重新加载',
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller?.loadData(
                  data: _html,
                  baseUrl: WebUri('https://captcha.c001apk.invalid/'))),
        ]),
        body: InAppWebView(
          initialSettings: InAppWebViewSettings(
            userAgent: GStorage.userAgent,
            useShouldOverrideUrlLoading: true,
            javaScriptCanOpenWindowsAutomatically: false,
          ),
          initialData: InAppWebViewInitialData(
              data: _html, baseUrl: WebUri('https://captcha.c001apk.invalid/')),
          onWebViewCreated: (controller) {
            _controller = controller;
            controller.addJavaScriptHandler(
                handlerName: 'captchaVerified',
                callback: (args) {
                  if (!mounted || _finished || args.length != 1) return null;
                  final proof = widget.challenge.proof(args.single);
                  if (proof != null) {
                    _finished = true;
                    Get.back(result: proof);
                  }
                  return null;
                });
          },
          shouldOverrideUrlLoading: (_, action) async =>
              action.isForMainFrame == true
                  ? NavigationActionPolicy.CANCEL
                  : NavigationActionPolicy.ALLOW,
        ),
      );
}
