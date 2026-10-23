import '../../components/expressive_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import '../../components/cards/message_first_card.dart';
import '../../components/cards/message_header_card.dart';
import '../../components/cards/message_second_card.dart';
import '../../components/cards/message_third_card.dart';
import '../../components/expressive_list_section.dart';
import '../../pages/message/message_controller.dart';
import '../../pages/noitfication/notification_page.dart';
import '../../utils/extensions.dart';
import '../../utils/global_data.dart';
import '../../logic/announcements/app_announcements.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _titleList = ['@我的动态', '@我的评论', '我收到的赞', '好友关注', '私信与信息'];
  final _iconList = [
    Icons.alternate_email,
    Icons.message_outlined,
    Icons.thumb_up_alt_outlined,
    Icons.person_add_outlined,
    Icons.mail_outline,
  ];
  late final MessageController _messageController =
      Get.put(MessageController());

  @override
  void dispose() {
    Get.delete<MessageController>();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (GlobalData().isLogin) {
      _onRefresh();
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted || !GlobalData().isLogin) return;
    final generation = GlobalData().sessionGeneration;
    await _messageController.getProfile();
    if (!mounted || generation != GlobalData().sessionGeneration) return;
    await _messageController.checkCount();
  }

  Widget _shortcuts(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (GlobalData().isLogin) ...[
            Obx(() =>
                messageFirstCard(true, context, _messageController.firstList)),
            const SizedBox(height: 10),
          ],
          messageSeconfCard(GlobalData().isLogin, context),
        ],
      );

  Widget _messages(BuildContext context) {
    final announcements = AppAnnouncements.service;
    Widget list() => ExpressiveListSection(
          padding: EdgeInsets.zero,
          children: [
            for (var index = 0; index < _titleList.length; index++)
              Obx(() => messageThirdCard(
                    context,
                    _iconList[index],
                    _titleList[index],
                    (_messageController.thirdList.getOrNull(index) ?? 0) +
                        (index == 4 ? announcements?.unreadCount ?? 0 : 0),
                    () {
                      if (!GlobalData().isLogin && index != 4) return;
                      Get.toNamed('/notification', arguments: {
                        'type': NotificationType.values[index],
                        if (index == 4)
                          'notificationCount':
                              _messageController.notificationCount.value,
                        if (index == 4)
                          'onNotificationsRead': () =>
                              _messageController.notificationCount.value = null,
                      });
                      final count =
                          _messageController.thirdList.getOrNull(index);
                      if (count != null && count > 0) {
                        _messageController.thirdList[index] = null;
                      }
                    },
                  )),
          ],
        );
    return announcements == null
        ? list()
        : AnimatedBuilder(animation: announcements, builder: (_, __) => list());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('我的'), actions: [
        IconButton(
            onPressed: () => Get.toNamed('/accounts'),
            icon: const Icon(Icons.switch_account_outlined),
            tooltip: '账号管理'),
        IconButton(
            onPressed: () => Get.toNamed('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置'),
      ]),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Obx(
                  () => MessageHeaderCard(
                    userInfo: _messageController.userInfo.value,
                    onLogin: () => Get.toNamed('/login'),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                Expanded(
                  child: ExpressiveRefreshIndicator(
                    onRefresh: () async {
                      if (GlobalData().isLogin) {
                        await _onRefresh();
                      } else {
                        return Future.value();
                      }
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(10),
                          sliver: SliverToBoxAdapter(child: LayoutBuilder(
                            builder: (context, constraints) {
                              final scale =
                                  (MediaQuery.textScalerOf(context).scale(16) /
                                          16)
                                      .clamp(1.0, 1.5);
                              if (constraints.maxWidth >= 820 * scale) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _shortcuts(context)),
                                    const SizedBox(width: 20),
                                    Expanded(child: _messages(context)),
                                  ],
                                );
                              }
                              return Column(children: [
                                _shortcuts(context),
                                const SizedBox(height: 10),
                                _messages(context),
                              ]);
                            },
                          )),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
